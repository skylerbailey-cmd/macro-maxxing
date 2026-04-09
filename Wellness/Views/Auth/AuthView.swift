//
//  AuthView.swift
//  Wellness
//

import SwiftUI
import AuthenticationServices
import GoogleSignInSwift

// MARK: - Palette

private extension Color {
    static let authBg      = Color(red: 0.06, green: 0.04, blue: 0.12)
    static let authCard    = Color(red: 0.13, green: 0.09, blue: 0.24)
    static let purpleMid   = Color(red: 0.45, green: 0.25, blue: 0.85)
    static let gold        = Color(red: 1.00, green: 0.84, blue: 0.00)
}

// MARK: - AuthView

struct AuthView: View {

    @Environment(SessionManager.self) private var auth

    enum Mode { case login, signUp }
    @State private var mode: Mode = .login

    @State private var email    = ""
    @State private var password = ""
    @State private var username = ""
    @State private var name     = ""

    @State private var showPassword       = false
    @State private var showForgotPassword = false

    private enum UsernameState { case idle, checking, available, taken }
    @State private var usernameState:     UsernameState = .idle
    @State private var usernameCheckTask: Task<Void, Never>? = nil
    @State private var passwordFocused = false

    // MARK: - Body

    var body: some View {
        ZStack {
            background

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // top breathing room so content clears the orbs
                    Spacer().frame(height: 60)

                    header
                        .padding(.bottom, 32)

                    // banners
                    if let msg = auth.successMessage {
                        messageBanner(msg, color: .green).padding(.bottom, 12)
                    }
                    if let err = auth.errorMessage {
                        messageBanner(err, color: .red).padding(.bottom, 12)
                    }

                    socialButtons

                    orDivider.padding(.vertical, 20)

                    // form card
                    VStack(spacing: 16) {
                        fields
                    }
                    .padding(20)
                    .background(Color.authCard)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.purpleHi.opacity(0.25), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)

                    if mode == .login {
                        forgotPasswordButton.padding(.top, 10)
                    }

                    submitButton.padding(.top, 20)

                    modeSwitcher.padding(.top, 16)

                    Spacer().frame(height: 48)
                }
            }

            if auth.isLoading {
                Color.black.opacity(0.5).ignoresSafeArea()
                ProgressView()
                    .tint(.purpleHi)
                    .scaleEffect(1.6)
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showForgotPassword) {
            ForgotPasswordView().environment(auth)
        }
    }

    // MARK: - Background

    private var background: some View {
        ZStack {
            Color.authBg.ignoresSafeArea()

            // top-left glow orb
            Circle()
                .fill(Color.purpleMid.opacity(0.15))
                .frame(width: 250, height: 250)
                .blur(radius: 80)
                .offset(x: -80, y: -160)

            // bottom-right glow orb
            Circle()
                .fill(Color.purpleHi.opacity(0.10))
                .frame(width: 220, height: 220)
                .blur(radius: 80)
                .offset(x: 120, y: 420)

            // gold accent orb near top
            Circle()
                .fill(Color.gold.opacity(0.04))
                .frame(width: 150, height: 150)
                .blur(radius: 50)
                .offset(x: 100, y: -80)
        }
        .ignoresSafeArea()
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(Color.purpleHi.opacity(0.10))
                    .frame(width: 70, height: 70)
                    .blur(radius: 10)

                Image(systemName: "bolt.fill")
                    .font(.system(size: 40, weight: .bold))
                    .foregroundStyle(Color.gold)
            }

            Text("Macro Maxxing")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            Text(mode == .login ? "Welcome back" : "Create your account")
                .font(.subheadline)
                .foregroundStyle(Color.purpleHi.opacity(0.85))
        }
    }

    // MARK: - Fields

    private var fields: some View {
        VStack(spacing: 14) {
            if mode == .signUp {
                inputField("Name", text: $name, icon: "person.fill")
                usernameField
            }

            inputField("Email", text: $email, icon: "envelope.fill")
                .keyboardType(.emailAddress)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)

            passwordField
        }
    }

    @ViewBuilder
    private func inputField(_ placeholder: String, text: Binding<String>, icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundStyle(Color.purpleHi.opacity(0.7))
                .frame(width: 18)
            TextField(placeholder, text: text)
                .foregroundStyle(.white)
                .tint(Color.purpleHi)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.purpleHi.opacity(0.15), lineWidth: 1)
        )
    }

    private var usernameField: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                Image(systemName: "at")
                    .foregroundStyle(Color.purpleHi.opacity(0.7))
                    .frame(width: 18)
                TextField("Username", text: $username)
                    .foregroundStyle(.white)
                    .tint(Color.purpleHi)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.never)
                    .onChange(of: username) { _, v in
                        let stripped = v.replacingOccurrences(of: " ", with: "")
                        if stripped != v { username = stripped }
                        scheduleUsernameCheck(stripped)
                    }
                switch usernameState {
                case .checking: ProgressView().tint(.gray).scaleEffect(0.7)
                case .available: Image(systemName: "checkmark.circle.fill").foregroundStyle(.green)
                case .taken:    Image(systemName: "xmark.circle.fill").foregroundStyle(.red)
                case .idle:     EmptyView()
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.purpleHi.opacity(0.15), lineWidth: 1))

            if usernameState == .taken {
                hint("Username already taken", color: .red)
            } else if usernameState == .available {
                hint("Username available", color: .green)
            } else if !username.isEmpty && (username.count < 4 || !Self.isValidUsernameFormat(username)) {
                hint("4–20 characters, letters, numbers, and underscores only", color: .orange)
            }
        }
    }

    private var passwordField: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 12) {
                Image(systemName: "lock.fill")
                    .foregroundStyle(Color.purpleHi.opacity(0.7))
                    .frame(width: 18)
                Group {
                    if showPassword {
                        TextField("Password", text: $password)
                    } else {
                        SecureField("Password", text: $password)
                    }
                }
                .foregroundStyle(.white)
                .tint(Color.purpleHi)
                Button { showPassword.toggle() } label: {
                    Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                        .foregroundStyle(Color.purpleHi.opacity(0.6))
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.purpleHi.opacity(0.15), lineWidth: 1))

            if mode == .signUp && !password.isEmpty {
                passwordRequirements
            }
        }
    }

    private var passwordRequirements: some View {
        VStack(alignment: .leading, spacing: 4) {
            requirementRow("8+ characters",             met: password.count >= 8)
            requirementRow("Uppercase letter (A–Z)",    met: password.contains(where: \.isUppercase))
            requirementRow("Lowercase letter (a–z)",    met: password.contains(where: \.isLowercase))
            requirementRow("Number (0–9)",               met: password.contains(where: \.isNumber))
            requirementRow("Special character (!@#$…)", met: password.contains(where: { "!@#$%^&*()_+-=[]{}|;':\",./<>?".contains($0) }))
        }
        .padding(.leading, 4)
        .padding(.top, 2)
    }

    private func requirementRow(_ label: String, met: Bool) -> some View {
        HStack(spacing: 6) {
            Image(systemName: met ? "checkmark.circle.fill" : "circle")
                .font(.caption)
                .foregroundStyle(met ? .green : Color.white.opacity(0.3))
            Text(label)
                .font(.caption)
                .foregroundStyle(met ? .green : Color.white.opacity(0.4))
        }
    }

    private func hint(_ text: String, color: Color) -> some View {
        Text(text).font(.caption).foregroundStyle(color).padding(.leading, 4)
    }

    // MARK: - Forgot Password

    private var forgotPasswordButton: some View {
        HStack {
            Spacer()
            Button("Forgot password?") {
                auth.clearError()
                showForgotPassword = true
            }
            .font(.subheadline)
            .foregroundStyle(Color.purpleHi)
            .padding(.trailing, 24)
        }
    }

    // MARK: - Submit

    private var submitButton: some View {
        Button {
            Task { await submit() }
        } label: {
            Text(mode == .login ? "Sign In" : "Create Account")
                .font(.headline)
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(
                    LinearGradient(
                        colors: [Color.purpleMid, Color.purpleHi],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .shadow(color: Color.purpleHi.opacity(0.15), radius: 6, y: 3)
        }
        .padding(.horizontal, 24)
        .disabled(auth.isLoading || !formIsValid)
        .opacity((auth.isLoading || !formIsValid) ? 0.45 : 1)
    }

    // MARK: - Mode Switcher

    private var modeSwitcher: some View {
        Button {
            auth.clearError()
            auth.clearSuccess()
            withAnimation(.easeInOut(duration: 0.2)) {
                mode = mode == .login ? .signUp : .login
            }
        } label: {
            HStack(spacing: 4) {
                Text(mode == .login ? "Don't have an account?" : "Already have an account?")
                    .foregroundStyle(Color.white.opacity(0.5))
                Text(mode == .login ? "Sign Up" : "Sign In")
                    .foregroundStyle(Color.purpleHi)
                    .fontWeight(.semibold)
            }
            .font(.subheadline)
        }
    }

    // MARK: - Social Sign-In

    private var orDivider: some View {
        HStack(spacing: 12) {
            Rectangle().frame(height: 1).foregroundStyle(Color.white.opacity(0.08))
            Text("or continue with email").font(.caption).foregroundStyle(Color.white.opacity(0.35))
            Rectangle().frame(height: 1).foregroundStyle(Color.white.opacity(0.08))
        }
        .padding(.horizontal, 24)
    }

    private var socialButtons: some View {
        VStack(spacing: 12) {
            SignInWithAppleButton(mode == .login ? .signIn : .signUp) { request in
                request.requestedScopes = [.fullName, .email]
                request.nonce = auth.prepareAppleSignIn()
            } onCompletion: { result in
                Task { await auth.handleAppleSignIn(result) }
            }
            .signInWithAppleButtonStyle(.white)
            .frame(height: 50)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .padding(.horizontal, 24)

            Button {
                Task { await auth.signInWithGoogle() }
            } label: {
                HStack(spacing: 10) {
                    Image("google_logo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 20, height: 20)
                    Text(mode == .login ? "Sign in with Google" : "Sign up with Google")
                        .fontWeight(.medium)
                        .foregroundStyle(Color(red: 0.2, green: 0.2, blue: 0.2))
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(Color.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Banner

    private func messageBanner(_ text: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Image(systemName: color == .green ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                .foregroundStyle(color)
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.white)
                .multilineTextAlignment(.leading)
            Spacer()
        }
        .padding(14)
        .background(color.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(color.opacity(0.3), lineWidth: 1))
        .padding(.horizontal, 24)
    }

    // MARK: - Validation

    private var passwordMeetsRequirements: Bool {
        password.count >= 8 &&
        password.contains(where: \.isUppercase) &&
        password.contains(where: \.isLowercase) &&
        password.contains(where: \.isNumber) &&
        password.contains(where: { "!@#$%^&*()_+-=[]{}|;':\",./<>?".contains($0) })
    }

    private var formIsValid: Bool {
        if mode == .signUp {
            return !email.isEmpty &&
                   passwordMeetsRequirements &&
                   username.count >= 4 &&
                   Self.isValidUsernameFormat(username) &&
                   usernameState == .available
        }
        return !email.isEmpty && !password.isEmpty
    }

    private func submit() async {
        if mode == .login {
            await auth.login(email: email, password: password)
        } else {
            await auth.signUp(email: email, password: password, username: username, name: name)
        }
    }

    // MARK: - Username Helpers

    private func scheduleUsernameCheck(_ value: String) {
        usernameCheckTask?.cancel()
        guard value.count >= 4, Self.isValidUsernameFormat(value) else { usernameState = .idle; return }
        usernameState = .checking
        usernameCheckTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            let taken = await UserProfileService.shared.isUsernameTaken(value, excludingUserID: "")
            guard !Task.isCancelled else { return }
            usernameState = taken ? .taken : .available
        }
    }

    static func isValidUsernameFormat(_ value: String) -> Bool {
        let regex = #"^[a-zA-Z0-9][a-zA-Z0-9_]{2,18}[a-zA-Z0-9]$|^[a-zA-Z0-9]{4,20}$"#
        return value.range(of: regex, options: .regularExpression) != nil
    }
}

// MARK: - Email Verification Banner

struct EmailVerificationBannerView: View {
    @Environment(SessionManager.self) private var auth
    @State private var sent      = false
    @State private var dismissed = false

    var body: some View {
        if !dismissed {
            HStack(spacing: 12) {
                Image(systemName: "envelope.badge.fill")
                    .font(.title3)
                    .foregroundStyle(.black)

                VStack(alignment: .leading, spacing: 2) {
                    Text("Verify your email")
                        .font(.subheadline.bold())
                        .foregroundStyle(.black)
                    Text("Check your inbox or spam for an email from noreply@macromaxxing.firebaseapp.com")
                        .font(.caption)
                        .foregroundStyle(.black.opacity(0.7))
                }

                Spacer()

                Button(sent ? "Sent ✓" : "Resend") {
                    Task { await auth.resendVerificationEmail(); sent = true }
                }
                .font(.caption.bold())
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(Color.black.opacity(0.15))
                .clipShape(Capsule())
                .foregroundStyle(.black)
                .disabled(sent)

                Button { dismissed = true } label: {
                    Image(systemName: "xmark")
                        .font(.caption.bold())
                        .foregroundStyle(.black.opacity(0.6))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(red: 1, green: 0.84, blue: 0))
        }
    }
}

// MARK: - Forgot Password Sheet

private struct ForgotPasswordView: View {
    @Environment(SessionManager.self) private var auth
    @Environment(\.dismiss) private var dismiss
    @State private var email = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.04, blue: 0.12).ignoresSafeArea()

                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.65, green: 0.45, blue: 1.0).opacity(0.2))
                            .frame(width: 80, height: 80)
                            .blur(radius: 16)
                        Image(systemName: "lock.rotation")
                            .font(.system(size: 40))
                            .foregroundStyle(Color(red: 1, green: 0.84, blue: 0))
                    }
                    .padding(.top, 24)

                    VStack(spacing: 6) {
                        Text("Reset Password")
                            .font(.title2.bold()).foregroundStyle(.white)
                        Text("Enter your email and we'll send a reset link.")
                            .font(.subheadline).foregroundStyle(.gray)
                            .multilineTextAlignment(.center)
                    }

                    if let msg = auth.successMessage {
                        Text(msg).font(.subheadline).foregroundStyle(.green)
                            .multilineTextAlignment(.center).padding(.horizontal, 24)
                    }
                    if let err = auth.errorMessage {
                        Text(err).font(.subheadline).foregroundStyle(.red)
                            .multilineTextAlignment(.center).padding(.horizontal, 24)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "envelope.fill")
                            .foregroundStyle(Color(red: 0.65, green: 0.45, blue: 1.0).opacity(0.7))
                            .frame(width: 18)
                        TextField("Email", text: $email)
                            .foregroundStyle(.white)
                            .keyboardType(.emailAddress)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.never)
                    }
                    .padding(14)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .stroke(Color(red: 0.65, green: 0.45, blue: 1.0).opacity(0.2), lineWidth: 1))
                    .padding(.horizontal, 24)

                    Button {
                        Task { await auth.sendPasswordReset(to: email) }
                    } label: {
                        Text("Send Reset Email")
                            .font(.headline).foregroundStyle(.white)
                            .frame(maxWidth: .infinity).padding(.vertical, 16)
                            .background(LinearGradient(
                                colors: [Color(red: 0.45, green: 0.25, blue: 0.85),
                                         Color(red: 0.65, green: 0.45, blue: 1.0)],
                                startPoint: .leading, endPoint: .trailing))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 24)
                    .disabled(auth.isLoading || email.isEmpty)
                    .opacity((auth.isLoading || email.isEmpty) ? 0.45 : 1)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { auth.clearError(); auth.clearSuccess(); dismiss() }
                        .foregroundStyle(Color(red: 0.65, green: 0.45, blue: 1.0))
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Delete Account View

struct DeleteAccountView: View {
    @Environment(SessionManager.self) private var auth
    @Environment(UserSettings.self) private var userSettings
    @Environment(\.dismiss) private var dismiss
    @State private var confirmText = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.04, blue: 0.12).ignoresSafeArea()

                VStack(spacing: 24) {
                    Image(systemName: "person.crop.circle.badge.minus")
                        .font(.system(size: 48)).foregroundStyle(.red).padding(.top, 32)

                    VStack(spacing: 8) {
                        Text("Delete Account")
                            .font(.title2.bold()).foregroundStyle(.white)
                        Text("This permanently deletes your account and all data. This cannot be undone.")
                            .font(.subheadline).foregroundStyle(.gray)
                            .multilineTextAlignment(.center).padding(.horizontal, 24)
                    }

                    if let err = auth.errorMessage {
                        Text(err).font(.subheadline).foregroundStyle(.red)
                            .multilineTextAlignment(.center).padding(.horizontal, 24)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Type DELETE to confirm")
                            .font(.caption).foregroundStyle(.gray)
                        TextField("DELETE", text: $confirmText)
                            .foregroundStyle(.white)
                            .autocorrectionDisabled()
                            .textInputAutocapitalization(.characters)
                            .padding()
                            .background(Color.white.opacity(0.06))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .padding(.horizontal, 24)

                    Button(role: .destructive) {
                        Task { await auth.deleteAccount(userID: userSettings.userID) }
                    } label: {
                        Group {
                            if auth.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Delete My Account").fontWeight(.semibold)
                            }
                        }
                        .frame(maxWidth: .infinity).padding()
                        .background(confirmText == "DELETE" ? Color.red : Color.red.opacity(0.3))
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .padding(.horizontal, 24)
                    .disabled(confirmText != "DELETE" || auth.isLoading)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { auth.clearError(); dismiss() }
                        .foregroundStyle(Color(red: 0.65, green: 0.45, blue: 1.0))
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Change Email View

struct ChangeEmailView: View {
    @Environment(SessionManager.self) private var auth
    @Environment(\.dismiss) private var dismiss

    @State private var newEmail  = ""
    @State private var password  = ""
    @State private var showPassword = false

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.06, green: 0.04, blue: 0.12).ignoresSafeArea()

                VStack(spacing: 24) {
                    ZStack {
                        Circle()
                            .fill(Color(red: 0.65, green: 0.45, blue: 1.0).opacity(0.2))
                            .frame(width: 80, height: 80).blur(radius: 16)
                        Image(systemName: "envelope.badge.fill")
                            .font(.system(size: 36))
                            .foregroundStyle(Color(red: 1, green: 0.84, blue: 0))
                    }
                    .padding(.top, 24)

                    VStack(spacing: 6) {
                        Text("Change Email")
                            .font(.title2.bold()).foregroundStyle(.white)
                        Text("Enter your new email and current password to confirm.")
                            .font(.subheadline).foregroundStyle(.gray)
                            .multilineTextAlignment(.center).padding(.horizontal, 24)
                    }

                    if let msg = auth.successMessage {
                        Text(msg).font(.subheadline).foregroundStyle(.green)
                            .multilineTextAlignment(.center).padding(.horizontal, 24)
                    }
                    if let err = auth.errorMessage {
                        Text(err).font(.subheadline).foregroundStyle(.red)
                            .multilineTextAlignment(.center).padding(.horizontal, 24)
                    }

                    VStack(spacing: 14) {
                        // New email field
                        HStack(spacing: 12) {
                            Image(systemName: "envelope.fill")
                                .foregroundStyle(Color(red: 0.65, green: 0.45, blue: 1.0).opacity(0.7))
                                .frame(width: 18)
                            TextField("New email address", text: $newEmail)
                                .foregroundStyle(.white)
                                .keyboardType(.emailAddress)
                                .autocorrectionDisabled()
                                .textInputAutocapitalization(.never)
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 0.65, green: 0.45, blue: 1.0).opacity(0.2), lineWidth: 1))

                        // Current password field
                        HStack(spacing: 12) {
                            Image(systemName: "lock.fill")
                                .foregroundStyle(Color(red: 0.65, green: 0.45, blue: 1.0).opacity(0.7))
                                .frame(width: 18)
                            Group {
                                if showPassword {
                                    TextField("Current password", text: $password)
                                } else {
                                    SecureField("Current password", text: $password)
                                }
                            }
                            .foregroundStyle(.white)
                            Button { showPassword.toggle() } label: {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundStyle(Color(red: 0.65, green: 0.45, blue: 1.0).opacity(0.6))
                            }
                        }
                        .padding(14)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(red: 0.65, green: 0.45, blue: 1.0).opacity(0.2), lineWidth: 1))
                    }
                    .padding(.horizontal, 24)

                    Button {
                        Task { await auth.changeEmail(to: newEmail, password: password) }
                    } label: {
                        Group {
                            if auth.isLoading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Send Verification")
                                    .font(.headline).foregroundStyle(.white)
                            }
                        }
                        .frame(maxWidth: .infinity).padding(.vertical, 16)
                        .background(LinearGradient(
                            colors: [Color(red: 0.45, green: 0.25, blue: 0.85),
                                     Color(red: 0.65, green: 0.45, blue: 1.0)],
                            startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: Color(red: 0.65, green: 0.45, blue: 1.0).opacity(0.35), radius: 8, y: 4)
                    }
                    .padding(.horizontal, 24)
                    .disabled(auth.isLoading || newEmail.isEmpty || password.isEmpty)
                    .opacity((auth.isLoading || newEmail.isEmpty || password.isEmpty) ? 0.45 : 1)

                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") {
                        auth.clearError()
                        auth.clearSuccess()
                        dismiss()
                    }
                    .foregroundStyle(Color(red: 0.65, green: 0.45, blue: 1.0))
                }
            }
        }
        .preferredColorScheme(.dark)
    }
}

// MARK: - Previews

#Preview("Auth") {
    AuthView().environment(SessionManager())
}

#Preview("Delete Account") {
    DeleteAccountView()
        .environment(SessionManager())
        .environment(UserSettings())
}
