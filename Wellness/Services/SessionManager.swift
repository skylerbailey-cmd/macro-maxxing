//
//  SessionManager.swift
//  Wellness
//
//  Single source of truth for Firebase auth state AND the current user's profile.
//  The auth listener is the ONLY place that reacts to login/logout; all other
//  code reads `authState` and `userProfile`.
//

import Foundation
import UIKit
import CryptoKit
import AuthenticationServices
import FirebaseAuth
import FirebaseFirestore
import FirebaseFunctions
import GoogleSignIn

@Observable @MainActor
final class SessionManager {

    // MARK: - Auth State

    enum AuthState: Equatable {
        case unknown            // resolving Firebase token on launch
        case unauthenticated
        case authenticated(uid: String)
    }

    var authState: AuthState = .unknown

    // MARK: - Profile

    /// Populated from Firestore after sign-in; never from UserDefaults.
    private(set) var userProfile: UserProfile? = nil

    // MARK: - UI State

    var isLoading      = false
    var errorMessage:   String? = nil
    var successMessage: String? = nil

    private(set) var isBypassSession  = false

    /// True immediately after a brand-new profile is created; cleared when the user
    /// finishes the onboarding flow.
    var needsOnboarding = false

    /// Set by OnboardingView right before flipping `needsOnboarding=false`.
    /// ContentView reads this on mount to present the AI subscription paywall
    /// before any tutorial overlays kick in. Cleared once the paywall is
    /// dismissed.
    var showPostOnboardPaywall = false

    /// Optional promo code captured during onboarding. Forwarded to the
    /// post-onboarding paywall via `prefilledPromoCode`. nil = user skipped.
    var pendingOnboardingPromoCode: String? = nil

    // MARK: - UserSettings wire-up

    /// Set by WellnessApp immediately after init.
    /// SessionManager calls populate/clearProfile on it as auth state changes.
    weak var userSettings: UserSettings?

    // MARK: - Computed

    var currentUID: String? { Auth.auth().currentUser?.uid }

    var isAuthenticated: Bool {
        if case .authenticated = authState { return true }
        return false
    }

    var needsEmailVerification: Bool {
        !isBypassSession && Auth.auth().currentUser?.isEmailVerified == false
    }

    // MARK: - Private

    nonisolated(unsafe) private var authStateHandle: AuthStateDidChangeListenerHandle?
    /// Stored during Apple sign-in so the raw nonce can be verified by Firebase.
    nonisolated(unsafe) private var currentAppleNonce: String = ""
    private var db: Firestore { FirebaseManager.shared.db }

    // MARK: - Lifecycle

    init() {
        // NOTE: Previous versions tried to detect reinstalls via a
        // `hasLaunchedBefore` UserDefaults flag and force-signed the user out
        // when it was missing. That was too aggressive — any user upgrading
        // from a build that didn't write the flag would be signed out on
        // first launch, which fired the auth listener with a nil user and
        // called clearProfile(), wiping their cached name/username/streaks.
        // Reinstalls now recover gracefully: Firestore is the source of
        // truth and populate(from:) restores everything on next fetch.

        authStateHandle = Auth.auth().addStateDidChangeListener { [weak self] _, user in
            guard let self else { return }
            Task { @MainActor in
                if let user {
                    self.authState = .authenticated(uid: user.uid)
                    // Enable Firestore network now that we have a valid auth session,
                    // then fetch the profile. This avoids blocking auth state resolution
                    // on a slow network — the UI can render while the profile loads.
                    await FirebaseManager.shared.enableNetwork()
                    await self.fetchAndApplyProfile(uid: user.uid)
                } else {
                    // A nil user here can mean either an explicit logout OR a
                    // transient token refresh failure. We ONLY clear local
                    // state on explicit logout (handled by logout() /
                    // deleteAccount() below), so a transient blip doesn't
                    // wipe the user's streaks and identity cache.
                    self.authState = .unauthenticated
                    self.userProfile = nil
                }
            }
        }
    }

    deinit {
        if let handle = authStateHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }

    // MARK: - Profile Fetch

    /// Re-fetches the user profile from Firestore and re-populates UserSettings.
    /// Call this when the app returns to the foreground to ensure fresh state.
    func refreshProfile() async {
        guard let uid = currentUID else { return }
        // The app deliberately launches Firestore in offline mode (see
        // FirebaseManager.init) so the UI can render instantly without
        // blocking on a backend connection. Before reading from Firestore
        // we must bring the network up — otherwise fetchProfile races
        // the auth listener's enableNetwork call and fails with
        // "client is offline" on a fresh install with no cache.
        // enableNetwork() is idempotent, so this is a cheap no-op on
        // warm foregroundings.
        await FirebaseManager.shared.enableNetwork()
        await fetchAndApplyProfile(uid: uid)
    }

    private func fetchAndApplyProfile(uid: String) async {
        // Firestore's `enableNetwork()` returns as soon as it flips its
        // internal online flag — it does NOT wait for an actual backend
        // connection to be established. On a cold launch with no cached
        // data, `getDocument()` then fails immediately with
        // "client is offline" because there's nothing to serve and
        // Firestore hasn't finished handshaking with the backend.
        //
        // Retry with exponential backoff (0.5s → 1s → 2s → 4s, ~7.5s
        // total) so the first few attempts give Firestore enough time
        // to bring the connection up. Without this, users on a fresh
        // install see a blank/stale profile until they background and
        // foreground the app.
        var lastError: Error? = nil
        let backoffs: [UInt64] = [
            500_000_000,   // 0.5s
            1_000_000_000, // 1.0s
            2_000_000_000, // 2.0s
            4_000_000_000, // 4.0s
        ]
        let maxAttempts = 4
        for attempt in 1...maxAttempts {
            do {
                let profile = try await UserProfileService.shared.fetchProfile(userID: uid)
                userProfile = profile
                userSettings?.populate(from: profile)
                await userSettings?.downloadProfileImageIfNeeded()
                // Onboarding gate: a profile is considered "onboarded" only if
                // the user has set their DOB AND height. These are collected
                // only in OnboardingView, so missing values mean the user never
                // completed the flow — either because they're brand-new or
                // because a social sign-in (Apple / Google) created a stub
                // profile and the app was closed mid-flow. In either case,
                // route them through onboarding on next launch.
                if profile.dateOfBirth.isEmpty || profile.heightInches == 0 {
                    needsOnboarding = true
                }
                return
            } catch {
                lastError = error
                AppLogger.log("[SessionManager] fetchProfile attempt \(attempt) failed: \(error.localizedDescription)")
                if attempt < maxAttempts {
                    try? await Task.sleep(nanoseconds: backoffs[attempt - 1])
                }
            }
        }
        AppLogger.log("[SessionManager] fetchProfile gave up for \(uid). Last error: \(lastError?.localizedDescription ?? "unknown")")

        // Ghost-user guard: if we can't load a profile for the currently
        // authed UID AND the previously-cached UserSettings belongs to a
        // DIFFERENT user, that stale cache is not safe to show. It would
        // render the previous user's name, photo, streaks, etc. on top of
        // the new user's auth session. Wipe the cache so the app routes
        // back to the auth / onboarding flow with a clean slate.
        //
        // We deliberately do NOT sign out here — the Auth session is still
        // valid, and the user may just need onboarding to create a profile.
        // needsOnboarding=true will route them there on next render.
        if let settings = userSettings, !settings.userID.isEmpty, settings.userID != uid {
            AppLogger.log("[SessionManager] Clearing stale UserSettings (cached uid=\(settings.userID) != current uid=\(uid))")
            settings.clearProfile()
            needsOnboarding = true
        }
    }

    // MARK: - Profile Update

    /// Merges `fields` into the Firestore document, then re-fetches and updates
    /// `userProfile` and `userSettings`.
    func updateProfile(fields: [String: Any]) async throws {
        guard let uid = currentUID else { return }
        try await UserProfileService.shared.updateProfile(userID: uid, fields: fields)
        await fetchAndApplyProfile(uid: uid)
    }

    /// Uploads a new profile photo, then re-fetches the profile.
    @discardableResult
    func updateProfilePhoto(image: UIImage) async throws -> String {
        guard let uid = currentUID else { return "" }
        let url = try await UserProfileService.shared.updateProfilePhoto(userID: uid, image: image)
        await fetchAndApplyProfile(uid: uid)
        return url
    }

    // MARK: - Sign Up (email/password)

    func signUp(email: String, password: String, username: String, name: String) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        guard username.count >= 4 else {
            errorMessage = "Username must be at least 4 characters."
            return
        }
        guard Self.isStrongPassword(password) else {
            errorMessage = "Password must be 8+ characters and include an uppercase letter, a number, and a special character."
            return
        }
        let taken = await UserProfileService.shared.isUsernameTaken(username, excludingUserID: "")
        if taken {
            errorMessage = "That username is already taken. Please choose a different one."
            return
        }

        do {
            let result = try await Auth.auth().createUser(withEmail: email, password: password)
            let uid = result.user.uid

            let changeRequest = result.user.createProfileChangeRequest()
            changeRequest.displayName = name.isEmpty ? username : name
            try? await changeRequest.commitChanges()

            do {
                try await result.user.sendEmailVerification()
            } catch {
                AppLogger.log("[SessionManager] sendEmailVerification failed: \(error.localizedDescription)")
            }

            try await UserProfileService.shared.createProfile(UserProfile(
                userID: uid, username: username, name: name,
                location: "", profilePhotoURL: "",
                auraPoints: 0, streakDays: 0, friendCount: 0,
                followingCount: 0, followerCount: 0,
                joinDate: Int(Date().timeIntervalSince1970)
            ))

            // Pre-populate UserSettings so onboarding can skip name/username pages
            userSettings?.userID   = uid
            userSettings?.username = username
            userSettings?.name     = name

            needsOnboarding = true
            successMessage = "Account created! A verification email was sent from noreply@macromaxxing.firebaseapp.com — check your spam folder if you don't see it."
        } catch {
            errorMessage = Self.friendlyMessage(for: error)
        }
    }

    // MARK: - Login (email/password)

    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        do {
            try await Auth.auth().signIn(withEmail: email, password: password)
        } catch {
            errorMessage = Self.friendlyMessage(for: error)
        }
    }

    // MARK: - Sign in with Apple

    /// Call this when building the Apple ID request to generate and store a nonce.
    /// Pass the returned hashed nonce to `ASAuthorizationAppleIDRequest.nonce`.
    func prepareAppleSignIn() -> String {
        let nonce = randomNonceString()
        currentAppleNonce = nonce
        return sha256(nonce)
    }

    func handleAppleSignIn(_ result: Result<ASAuthorization, Error>) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        switch result {
        case .failure(let error):
            // ASAuthorizationError.canceled (1001) means the user dismissed the sheet — not an error
            let code = (error as NSError).code
            if code != ASAuthorizationError.canceled.rawValue {
                errorMessage = Self.friendlyMessage(for: error)
            }

        case .success(let authorization):
            guard
                let appleCredential = authorization.credential as? ASAuthorizationAppleIDCredential,
                let tokenData = appleCredential.identityToken,
                let idToken = String(data: tokenData, encoding: .utf8)
            else {
                errorMessage = "Apple Sign In failed. Please try again."
                return
            }

            // Apple's short-lived authorization code — needed later to revoke
            // the refresh token server-side when the user deletes their account.
            // Apple requires revocation as part of the account deletion flow
            // (App Store guideline 5.1.1(v)).
            let authorizationCode = appleCredential.authorizationCode
                .flatMap { String(data: $0, encoding: .utf8) } ?? ""

            let firebaseCredential = OAuthProvider.appleCredential(
                withIDToken: idToken,
                rawNonce: currentAppleNonce,
                fullName: appleCredential.fullName
            )

            do {
                let authResult = try await Auth.auth().signIn(with: firebaseCredential)
                // Firestore is launched with `disableNetwork()` so the UI can
                // render instantly from cache. For a fresh sign-in we need the
                // live backend to check whether a profile already exists, so
                // bring the connection up *before* `createProfileIfNeeded`.
                // Without this, `profileExists` races the auth listener's
                // enableNetwork call and fails with "client is offline",
                // leaving the user in a ghost-user state.
                await FirebaseManager.shared.enableNetwork()
                let name = [appleCredential.fullName?.givenName,
                            appleCredential.fullName?.familyName]
                    .compactMap { $0 }.joined(separator: " ")
                await createProfileIfNeeded(
                    uid: authResult.user.uid,
                    name: name,
                    email: appleCredential.email ?? authResult.user.email ?? ""
                )
                // Exchange the short-lived Apple authorization code for a
                // long-lived refresh token via the exchangeAppleAuthCode
                // Cloud Function. The server stores the refresh token in
                // users/{uid}/private/appleAuth, which deleteAccount reads
                // at deletion time to revoke the grant with Apple.
                // MUST happen within 5 minutes of sign-in or Apple will
                // reject the authorization code.
                if !authorizationCode.isEmpty {
                    await exchangeAppleAuthorizationCode(authorizationCode)
                }
            } catch {
                errorMessage = Self.friendlyMessage(for: error)
            }
        }
    }

    /// Calls the `exchangeAppleAuthCode` Cloud Function which trades the
    /// authorization code for a refresh token server-side and persists it
    /// under the user's private subcollection.
    ///
    /// Non-fatal: failures are logged but don't surface an error to the
    /// user — sign-in still succeeds. The only consequence of failure is
    /// that Apple's token can't be revoked at deletion time, which falls
    /// back gracefully in `deleteAccount`.
    ///
    /// Performs a single retry on transient failures (network, unavailable,
    /// internal) because the authorization code is valid for 5 minutes and
    /// a brief App Check / network blip right after sign-in is common.
    private func exchangeAppleAuthorizationCode(_ code: String) async {
        let callable = Functions.functions().httpsCallable("exchangeAppleAuthCode")
        for attempt in 1...2 {
            do {
                _ = try await callable.call(["authorizationCode": code])
                AppLogger.log("[SessionManager] Apple authorization code exchanged (attempt \(attempt))")
                return
            } catch {
                let nsError = error as NSError
                AppLogger.log("[SessionManager] exchangeAppleAuthCode attempt \(attempt) failed — \(Self.describeFunctionsError(nsError))")
                // FIRFunctionsErrorDomain == "com.firebase.functions"
                // Codes: 4 = deadlineExceeded, 13 = internal, 14 = unavailable.
                // Retry only those — not invalid-argument, unauthenticated, etc.
                let isTransient = nsError.domain == "com.firebase.functions"
                    && (nsError.code == 4 || nsError.code == 13 || nsError.code == 14)
                if attempt == 2 || !isTransient { return }
                try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5s
            }
        }
    }

    /// Pretty-prints a Firebase Functions NSError so callable failures can
    /// be diagnosed. Without this, errors show up as bare "INTERNAL" in logs.
    private static func describeFunctionsError(_ error: NSError) -> String {
        var parts: [String] = [
            "domain=\(error.domain)",
            "code=\(error.code)",
            "localizedDescription=\(error.localizedDescription)",
        ]
        // "details" is the user-info key the Firebase Functions SDK uses to
        // expose the `details` argument passed to HttpsError on the server.
        if let details = error.userInfo["details"] {
            parts.append("details=\(details)")
        }
        return parts.joined(separator: " | ")
    }

    // MARK: - Sign in with Google

    func signInWithGoogle() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        guard
            let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
            let rootVC = windowScene.windows.first?.rootViewController
        else {
            errorMessage = "Unable to present Google Sign In."
            return
        }

        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Google Sign In failed. Please try again."
                return
            }
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: result.user.accessToken.tokenString
            )
            let authResult = try await Auth.auth().signIn(with: credential)
            // See handleAppleSignIn for the rationale — bring Firestore up
            // before checking profile existence so we don't race the auth
            // listener and hit "client is offline" on a fresh sign-in.
            await FirebaseManager.shared.enableNetwork()
            await createProfileIfNeeded(
                uid: authResult.user.uid,
                name: result.user.profile?.name ?? "",
                email: result.user.profile?.email ?? ""
            )
        } catch {
            let code = (error as NSError).code
            // GIDSignInError.canceled (–5) — user dismissed the sheet
            if code != -5 {
                errorMessage = Self.friendlyMessage(for: error)
            }
        }
    }

    // MARK: - Logout

    func logout() {
        errorMessage = nil
        successMessage = nil
        isBypassSession = false
        GIDSignIn.sharedInstance.signOut()
        // Clear local profile state explicitly here — the auth listener no
        // longer wipes UserSettings on nil-user events because those can
        // fire on transient token failures and wipe the cached data.
        userSettings?.clearProfile()
        try? Auth.auth().signOut()
        // The auth listener handles setting authState = .unauthenticated.
    }

    // MARK: - Email Verification

    func resendVerificationEmail() async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        guard let user = Auth.auth().currentUser else {
            errorMessage = "No signed-in user found."
            return
        }
        do {
            try await user.sendEmailVerification()
            successMessage = "Verification email sent from noreply@macromaxxing.firebaseapp.com — check your spam folder if you don't see it."
        } catch {
            errorMessage = Self.friendlyMessage(for: error)
        }
    }

    func refreshVerificationStatus() async {
        try? await Auth.auth().currentUser?.reload()
        if let user = Auth.auth().currentUser {
            authState = .authenticated(uid: user.uid)
        }
    }

    // MARK: - Password Reset

    func sendPasswordReset(to email: String) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        guard !email.isEmpty else {
            errorMessage = "Please enter your email address."
            return
        }
        do {
            try await Auth.auth().sendPasswordReset(withEmail: email)
            successMessage = "Password reset email sent. Check your inbox."
        } catch {
            errorMessage = Self.friendlyMessage(for: error)
        }
    }

    // MARK: - Change Email

    /// Sends a verification link to `newEmail`. Firebase updates the address
    /// only after the user clicks the link, so the change is safe and reversible.
    func changeEmail(to newEmail: String, password: String) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        guard let user = Auth.auth().currentUser, let currentEmail = user.email else {
            errorMessage = "No signed-in user found."
            return
        }
        guard !newEmail.isEmpty else {
            errorMessage = "Please enter a new email address."
            return
        }
        guard newEmail != currentEmail else {
            errorMessage = "That's already your current email."
            return
        }

        // Re-authenticate first so Firebase accepts the sensitive change
        let credential = EmailAuthProvider.credential(withEmail: currentEmail, password: password)
        do {
            try await user.reauthenticate(with: credential)
            try await user.sendEmailVerification(beforeUpdatingEmail: newEmail)
            successMessage = "Verification sent to \(newEmail). Click the link in that email to confirm the change."
        } catch {
            errorMessage = Self.friendlyMessage(for: error)
        }
    }

    // MARK: - Account Deletion

    func deleteAccount(userID: String) async {
        isLoading = true
        errorMessage = nil
        successMessage = nil
        defer { isLoading = false }

        guard Auth.auth().currentUser != nil else {
            errorMessage = "No signed-in user found."
            return
        }
        do {
            // Server-side cascading delete. The Cloud Function revokes the
            // Apple refresh token (if one was stored at sign-in) before
            // wiping Firestore data, Storage files, and the Auth user.
            let callable = Functions.functions().httpsCallable("deleteAccount")
            _ = try await callable.call()
            // Server deleted the Auth user, so clear local profile + sign out locally
            userSettings?.clearProfile()
            try? Auth.auth().signOut()
        } catch let nsError as NSError
            where nsError.domain == AuthErrorDomain &&
                  nsError.code == AuthErrorCode.requiresRecentLogin.rawValue {
            errorMessage = "For security, please sign out and sign in again before deleting your account."
        } catch {
            let nsError = error as NSError
            AppLogger.log("[SessionManager] deleteAccount failed — \(Self.describeFunctionsError(nsError))")
            let msg = error.localizedDescription
            if msg.uppercased().contains("INTERNAL") {
                errorMessage = "Something went wrong deleting your account. Please try again or contact support."
            } else {
                errorMessage = Self.friendlyMessage(for: error)
            }
        }
    }

    // MARK: - Developer Bypass

    #if DEBUG
    func bypassAuth() {
        let id = UserDefaults.standard.string(forKey: "devBypassUserID")?.isEmpty == false
            ? UserDefaults.standard.string(forKey: "devBypassUserID")!
            : UUID().uuidString
        UserDefaults.standard.set(id, forKey: "devBypassUserID")
        isBypassSession = true
        authState = .authenticated(uid: id)
    }
    #endif

    // MARK: - Helpers

    func clearError()   { errorMessage   = nil }
    func clearSuccess() { successMessage = nil }

    // MARK: - Profile creation for social sign-ins

    private func createProfileIfNeeded(uid: String, name: String, email: String) async {
        // Check document existence directly rather than via fetchProfile().
        // fetchProfile() returns nil on ANY error (network blip, missing field,
        // decode failure), which would falsely trigger profile creation and
        // overwrite the user's existing data with email-derived defaults.
        //
        // profileExists now throws on network/permission errors so we can
        // distinguish "does not exist" from "failed to check". On failure,
        // bail out rather than create a new profile that would merge over
        // the real one via setData(merge: true).
        do {
            let exists = try await UserProfileService.shared.profileExists(userID: uid)
            if exists { return }
        } catch {
            AppLogger.log("[SessionManager] profileExists failed for \(uid) — skipping createProfile to avoid overwriting: \(error.localizedDescription)")
            return
        }

        // Derive a best-effort username from email, falling back to a random suffix
        let base = email.components(separatedBy: "@").first ?? ""
        let cleaned = base.filter { $0.isLetter || $0.isNumber || $0 == "_" }
        let username = cleaned.count >= 4
            ? String(cleaned.prefix(20))
            : "user\(Int.random(in: 10000...99999))"

        try? await UserProfileService.shared.createProfile(UserProfile(
            userID: uid, username: username, name: name,
            location: "", profilePhotoURL: "",
            auraPoints: 0, streakDays: 0, friendCount: 0,
            followingCount: 0, followerCount: 0,
            joinDate: Int(Date().timeIntervalSince1970)
        ))
        needsOnboarding = true
    }

    // MARK: - Validation Helpers

    static func isStrongPassword(_ password: String) -> Bool {
        password.count >= 8 &&
        password.contains(where: \.isUppercase) &&
        password.contains(where: \.isLowercase) &&
        password.contains(where: \.isNumber) &&
        password.contains(where: { "!@#$%^&*()_+-=[]{}|;':\",./<>?".contains($0) })
    }

    // MARK: - Friendly Error Messages

    private static func friendlyMessage(for error: Error) -> String {
        guard let code = AuthErrorCode(rawValue: (error as NSError).code) else {
            return error.localizedDescription
        }
        switch code {
        case .invalidEmail:        return "That doesn't look like a valid email address."
        case .emailAlreadyInUse:   return "An account with that email already exists. Try signing in instead."
        case .weakPassword:        return "Your password must be at least 6 characters."
        case .wrongPassword:       return "Incorrect password. Please try again."
        case .userNotFound:        return "No account found with that email."
        case .userDisabled:        return "This account has been disabled. Contact support."
        case .networkError:        return "Network error. Check your connection and try again."
        case .tooManyRequests:     return "Too many attempts. Please wait a moment and try again."
        case .requiresRecentLogin: return "For security, please sign out and sign back in before making this change."
        case .invalidCredential:   return "Incorrect email or password."
        default:                   return error.localizedDescription
        }
    }

    // MARK: - Nonce Helpers (Sign in with Apple)

    private func randomNonceString(length: Int = 32) -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remaining = length
        while remaining > 0 {
            let randoms: [UInt8] = (0..<16).map { _ in
                var byte: UInt8 = 0
                SecRandomCopyBytes(kSecRandomDefault, 1, &byte)
                return byte
            }
            randoms.forEach { byte in
                guard remaining > 0 else { return }
                if byte < charset.count {
                    result.append(charset[Int(byte)])
                    remaining -= 1
                }
            }
        }
        return result
    }

    private func sha256(_ input: String) -> String {
        let digest = SHA256.hash(data: Data(input.utf8))
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}
