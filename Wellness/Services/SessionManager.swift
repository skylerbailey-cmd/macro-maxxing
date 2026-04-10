//
//  SessionManager.swift
//  Wellness
//
//  Single source of truth for Firebase auth state AND the current user's profile.
//  Replaces AuthViewModel. The auth listener is the ONLY place that reacts to
//  login/logout; all other code reads `authState` and `userProfile`.
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
        await fetchAndApplyProfile(uid: uid)
    }

    private func fetchAndApplyProfile(uid: String) async {
        // Retry once on failure with a short backoff. Without this, a single
        // transient network/Firestore error would leave UserSettings at its
        // cached-from-UserDefaults values forever (or blank on first login),
        // because no other code path triggers a re-fetch until the app is
        // backgrounded and foregrounded again.
        var lastError: Error? = nil
        for attempt in 1...2 {
            do {
                let profile = try await UserProfileService.shared.fetchProfile(userID: uid)
                userProfile = profile
                userSettings?.populate(from: profile)
                await userSettings?.downloadProfileImageIfNeeded()
                return
            } catch {
                lastError = error
                AppLogger.log("[SessionManager] fetchProfile attempt \(attempt) failed: \(error.localizedDescription)")
                if attempt < 2 {
                    try? await Task.sleep(nanoseconds: 1_500_000_000) // 1.5s
                }
            }
        }
        AppLogger.log("[SessionManager] fetchProfile gave up for \(uid); UserSettings will keep its cached identity fields. Last error: \(lastError?.localizedDescription ?? "unknown")")
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

            let firebaseCredential = OAuthProvider.appleCredential(
                withIDToken: idToken,
                rawNonce: currentAppleNonce,
                fullName: appleCredential.fullName
            )

            do {
                let authResult = try await Auth.auth().signIn(with: firebaseCredential)
                let name = [appleCredential.fullName?.givenName,
                            appleCredential.fullName?.familyName]
                    .compactMap { $0 }.joined(separator: " ")
                await createProfileIfNeeded(
                    uid: authResult.user.uid,
                    name: name,
                    email: appleCredential.email ?? authResult.user.email ?? ""
                )
            } catch {
                errorMessage = Self.friendlyMessage(for: error)
            }
        }
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
            // Call server-side cascading delete (Firestore data, Storage files, Auth user)
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
