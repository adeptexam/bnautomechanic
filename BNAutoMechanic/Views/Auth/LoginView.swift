//
//  LoginView.swift
//  BNAutoMechanic
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var session: SessionManager
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @State private var showPassword = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                // Header
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 12) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                        Text("BN AUTO")
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(.primaryGold)
                            .tracking(1)
                    }
                    .padding(.bottom, 20)

                    Text("Welcome Back")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.textForeground)

                    Text("Sign in to manage your vehicle services and appointments")
                        .font(.system(size: 13))
                        .foregroundColor(.textMuted)
                        .padding(.top, 4)
                }
                .padding(.top, 20)

                // Email Field
                VStack(alignment: .leading, spacing: 6) {
                    Text("Email address")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.textForeground)

                    TextField("name@example.com", text: $email)
                        .textFieldStyle(DarkInputFieldStyle())
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                }
                .padding(.top, 24)

                // Password Field
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Password")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.textForeground)
                        Spacer()
                        NavigationLink(destination: ForgotPasswordView()) {
                            Text("Forgot password?")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.primaryGold)
                        }
                    }

                    ZStack(alignment: .trailing) {
                        Group {
                            if showPassword {
                                TextField("••••••••", text: $password)
                            } else {
                                SecureField("••••••••", text: $password)
                            }
                        }
                        .textFieldStyle(DarkInputFieldStyle())
                        .textContentType(.password)

                        Button(action: { showPassword.toggle() }) {
                            Image(systemName: showPassword ? "eye.slash" : "eye")
                                .foregroundColor(.textMuted)
                                .font(.system(size: 14))
                        }
                        .padding(.trailing, 16)
                    }
                }
                .padding(.top, 16)

                // Error
                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.system(size: 12))
                        .foregroundColor(.statusCancelled)
                        .padding(.top, 10)
                }

                // Sign In Button
                Button(action: performLogin) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .bgDark))
                    } else {
                        Text("Sign In")
                    }
                }
                .buttonStyle(GoldButtonStyle(isEnabled: !isLoading))
                .disabled(isLoading)
                .padding(.top, 24)

                Spacer(minLength: 40)

                // Sign Up Link
                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .font(.system(size: 13))
                        .foregroundColor(.textMuted)

                    NavigationLink(destination: RegisterView()) {
                        Text("Sign up")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.primaryGold)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 24)
        }
        .background(Color.bgDark.ignoresSafeArea())
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
    }

    private func performLogin() {
        let trimmedEmail = email.trimmingCharacters(in: .whitespaces)

        guard !trimmedEmail.isEmpty else {
            errorMessage = "Please enter your email address"
            return
        }
        guard !password.isEmpty else {
            errorMessage = "Please enter your password"
            return
        }

        errorMessage = ""
        isLoading = true

        Task {
            do {
                let response = try await APIService.shared.login(email: trimmedEmail, password: password)
                if let authData = response.data, let token = authData.effectiveToken() {
                    let user = authData.user ?? User(
                        id: 0, name: trimmedEmail.components(separatedBy: "@").first?.replacingOccurrences(of: ".", with: " ").capitalized ?? "User",
                        email: trimmedEmail, phone: nil, address: nil, city: nil,
                        role: "CUSTOMER", status: "ACTIVE", emailVerified: false, createdAt: nil
                    )
                    session.saveAuth(token: token, user: user)
                } else {
                    await MainActor.run {
                        errorMessage = response.message ?? "Invalid email or password"
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Register View
struct RegisterView: View {
    @EnvironmentObject var session: SessionManager
    @Environment(\.dismiss) var dismiss
    @State private var name = ""
    @State private var email = ""
    @State private var phone = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 12) {
                        Image("AppLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 48, height: 48)
                        Text("BN AUTO")
                            .font(.system(size: 20, weight: .black))
                            .foregroundColor(.primaryGold)
                            .tracking(1)
                    }
                    .padding(.bottom, 20)

                    Text("Create Account")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.textForeground)

                    Text("Join BN Auto Mechanic for premium vehicle care")
                        .font(.system(size: 13))
                        .foregroundColor(.textMuted)
                        .padding(.top, 4)
                }
                .padding(.top, 20)

                // Name
                VStack(alignment: .leading, spacing: 6) {
                    Text("Full name")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.textForeground)
                    TextField("John Doe", text: $name)
                        .textFieldStyle(DarkInputFieldStyle())
                        .textContentType(.name)
                }
                .padding(.top, 24)

                // Email
                VStack(alignment: .leading, spacing: 6) {
                    Text("Email address")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.textForeground)
                    TextField("name@example.com", text: $email)
                        .textFieldStyle(DarkInputFieldStyle())
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }
                .padding(.top, 16)

                // Phone
                VStack(alignment: .leading, spacing: 6) {
                    Text("Phone number (optional)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.textForeground)
                    TextField("+1 (555) 000-0000", text: $phone)
                        .textFieldStyle(DarkInputFieldStyle())
                        .textContentType(.telephoneNumber)
                        .keyboardType(.phonePad)
                }
                .padding(.top, 16)

                // Password
                VStack(alignment: .leading, spacing: 6) {
                    Text("Password")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.textForeground)
                    SecureField("Create a strong password", text: $password)
                        .textFieldStyle(DarkInputFieldStyle())
                        .textContentType(.newPassword)
                }
                .padding(.top, 16)

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.system(size: 12))
                        .foregroundColor(.statusCancelled)
                        .padding(.top, 10)
                }

                Button(action: performRegister) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .bgDark))
                    } else {
                        Text("Create Account")
                    }
                }
                .buttonStyle(GoldButtonStyle(isEnabled: !isLoading))
                .disabled(isLoading)
                .padding(.top, 24)

                Spacer(minLength: 40)

                HStack(spacing: 4) {
                    Text("Already have an account?")
                        .font(.system(size: 13))
                        .foregroundColor(.textMuted)
                    Button("Sign in") {
                        dismiss()
                    }
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.primaryGold)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, 16)
            }
            .padding(.horizontal, 24)
        }
        .background(Color.bgDark.ignoresSafeArea())
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
    }

    private func performRegister() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty,
              !email.trimmingCharacters(in: .whitespaces).isEmpty,
              !password.isEmpty else {
            errorMessage = "Please fill in all required fields"
            return
        }

        errorMessage = ""
        isLoading = true

        Task {
            do {
                let response = try await APIService.shared.register(
                    name: name.trimmingCharacters(in: .whitespaces),
                    email: email.trimmingCharacters(in: .whitespaces),
                    password: password,
                    phone: phone.isEmpty ? nil : phone
                )
                if let authData = response.data, let token = authData.effectiveToken() {
                    let user = authData.user ?? User(
                        id: 0, name: name, email: email, phone: phone.isEmpty ? nil : phone,
                        address: nil, city: nil, role: "CUSTOMER", status: "ACTIVE",
                        emailVerified: false, createdAt: nil
                    )
                    session.saveAuth(token: token, user: user)
                } else {
                    await MainActor.run {
                        errorMessage = response.message ?? "Registration failed. Please check your information."
                        isLoading = false
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isLoading = false
                }
            }
        }
    }
}

// MARK: - Forgot Password View
struct ForgotPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var message = ""
    @State private var isError = false
    @State private var isLoading = false
    @State private var sent = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Reset Password")
                        .font(.system(size: 26, weight: .bold))
                        .foregroundColor(.textForeground)

                    Text("Enter your email address and we'll send you a reset link")
                        .font(.system(size: 13))
                        .foregroundColor(.textMuted)
                        .padding(.top, 4)
                }
                .padding(.top, 20)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Email address")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.textForeground)
                    TextField("name@example.com", text: $email)
                        .textFieldStyle(DarkInputFieldStyle())
                        .textContentType(.emailAddress)
                        .keyboardType(.emailAddress)
                        .textInputAutocapitalization(.never)
                }
                .padding(.top, 24)

                if !message.isEmpty {
                    Text(message)
                        .font(.system(size: 12))
                        .foregroundColor(isError ? .statusCancelled : .statusCompleted)
                        .padding(.top, 10)
                }

                Button(action: sendReset) {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .bgDark))
                    } else {
                        Text(sent ? "Resend Link" : "Send Reset Link")
                    }
                }
                .buttonStyle(GoldButtonStyle(isEnabled: !isLoading))
                .disabled(isLoading)
                .padding(.top, 24)

                Button("Back to Sign In") {
                    dismiss()
                }
                .buttonStyle(OutlineButtonStyle())
                .padding(.top, 12)
            }
            .padding(.horizontal, 24)
        }
        .background(Color.bgDark.ignoresSafeArea())
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
    }

    private func sendReset() {
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty else {
            message = "Please enter your email"
            isError = true
            return
        }

        isLoading = true
        message = ""

        Task {
            do {
                let response = try await APIService.shared.forgotPassword(email: email.trimmingCharacters(in: .whitespaces))
                await MainActor.run {
                    message = response.message ?? "If an account exists, a password reset link has been sent."
                    isError = false
                    sent = true
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    message = error.localizedDescription
                    isError = true
                    isLoading = false
                }
            }
        }
    }
}
