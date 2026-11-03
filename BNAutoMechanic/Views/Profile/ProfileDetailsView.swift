//
//  ProfileDetailsView.swift
//  BNAutoMechanic
//
//  Customer Account Profile Details & Self-Service Governance.
//  Includes live profile updates and App Store Guideline 5.1.1(v) compliant self-account deletion.
//

import SwiftUI

struct ProfileDetailsView: View {
    @EnvironmentObject var session: SessionManager
    @Environment(\.dismiss) var dismiss

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var address: String = ""
    @State private var city: String = ""
    @State private var state: String = ""
    @State private var postalCode: String = ""

    // States
    @State private var isSaving: Bool = false
    @State private var showSavedAlert: Bool = false
    @State private var errorMessage: String = ""
    @State private var showErrorAlert: Bool = false

    // Account Deletion States
    @State private var showDeleteConfirmSheet: Bool = false
    @State private var deletionPassword: String = ""
    @State private var deletionReason: String = ""
    @State private var isDeletingAccount: Bool = false
    @State private var deletionErrorMessage: String = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textForeground)
                        .frame(width: 38, height: 38)
                        .background(Color.cardDarkElevated)
                        .cornerRadius(10)
                }

                Text("Profile Details")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.textForeground)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider().background(Color.borderSubtle)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Avatar center
                    HStack {
                        Spacer()
                        VStack(spacing: 8) {
                            ZStack {
                                Circle()
                                    .fill(Color.primaryGoldTint)
                                    .frame(width: 72, height: 72)
                                    .overlay(
                                        Circle().stroke(Color.primaryGold, lineWidth: 2)
                                    )
                                Text(session.currentUser?.initials() ?? "BN")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.primaryGold)
                            }
                            Text(session.currentUser?.role ?? "CUSTOMER")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.primaryGold)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 3)
                                .background(Color.primaryGoldTint)
                                .cornerRadius(6)
                        }
                        Spacer()
                    }
                    .padding(.top, 16)

                    // Personal Information Section
                    VStack(alignment: .leading, spacing: 14) {
                        Text("PERSONAL DETAILS")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.primaryGold)
                            .tracking(0.6)

                        // Full Name
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Full Name *")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.textForeground)

                            TextField("Your full name", text: $name)
                                .textFieldStyle(DarkInputFieldStyle())
                        }

                        // Email (Read-only)
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Email Address")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.textForeground)

                            TextField("your.email@example.com", text: $email)
                                .textFieldStyle(DarkInputFieldStyle())
                                .disabled(true)
                                .opacity(0.7)
                        }

                        // Phone
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Phone Number")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.textForeground)

                            TextField("+1 (555) 000-0000", text: $phone)
                                .textFieldStyle(DarkInputFieldStyle())
                                .keyboardType(.phonePad)
                        }
                    }
                    .padding(16)
                    .luxuryCard()

                    // Address Information Section
                    VStack(alignment: .leading, spacing: 14) {
                        Text("SERVICE ADDRESS")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.primaryGold)
                            .tracking(0.6)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Street Address")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.textForeground)

                            TextField("e.g. 123 Main Street", text: $address)
                                .textFieldStyle(DarkInputFieldStyle())
                        }

                        HStack(spacing: 10) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("City")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.textForeground)

                                TextField("City", text: $city)
                                    .textFieldStyle(DarkInputFieldStyle())
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("State")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.textForeground)

                                TextField("State", text: $state)
                                    .textFieldStyle(DarkInputFieldStyle())
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("Postal Code")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(.textForeground)

                                TextField("ZIP", text: $postalCode)
                                    .textFieldStyle(DarkInputFieldStyle())
                            }
                        }
                    }
                    .padding(16)
                    .luxuryCard()

                    // Save Button
                    Button(action: saveProfile) {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .bgDark))
                        } else {
                            Text("Save Profile Changes")
                        }
                    }
                    .buttonStyle(GoldButtonStyle(isEnabled: !name.trimmingCharacters(in: .whitespaces).isEmpty && !isSaving))
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                    .padding(.top, 4)

                    // MARK: - Danger Zone / Account Deletion
                    VStack(alignment: .leading, spacing: 12) {
                        Text("ACCOUNT GOVERNANCE & PRIVACY")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.statusCancelled)
                            .tracking(0.6)

                        Text("You have the legal right to delete your account, vehicles, and all associated personal data from our systems at any time.")
                            .font(.system(size: 12))
                            .foregroundColor(.textMuted)
                            .lineSpacing(3)

                        Button(action: { showDeleteConfirmSheet = true }) {
                            HStack(spacing: 8) {
                                Image(systemName: "trash.fill")
                                    .font(.system(size: 13, weight: .bold))
                                Text("Delete My Account Permanently")
                                    .font(.system(size: 13, weight: .bold))
                            }
                            .foregroundColor(.statusCancelled)
                            .frame(maxWidth: .infinity)
                            .frame(height: 46)
                            .background(Color.statusCancelled.opacity(0.12))
                            .cornerRadius(10)
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.statusCancelled.opacity(0.4), lineWidth: 1)
                            )
                        }
                    }
                    .padding(16)
                    .luxuryCard()
                    .padding(.top, 10)
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 36)
            }
        }
        .background(Color.bgDark.ignoresSafeArea())
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .hideBottomDockOnPush()
        .onAppear {
            if let user = session.currentUser {
                name = user.name
                email = user.email
                phone = user.phone ?? ""
                address = user.address ?? ""
                city = user.city ?? ""
                state = user.state ?? ""
                postalCode = user.postalCode ?? ""
            }
        }
        .alert("Profile Updated", isPresented: $showSavedAlert) {
            Button("OK") {}
        } message: {
            Text("Your profile information has been synchronized with the workshop servers.")
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .sheet(isPresented: $showDeleteConfirmSheet) {
            accountDeletionSheet
        }
    }

    // MARK: - Account Deletion Modal (App Store Guideline 5.1.1(v))
    private var accountDeletionSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    HStack(spacing: 12) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.statusCancelled)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Delete Account")
                                .font(.system(size: 18, weight: .black))
                                .foregroundColor(.textForeground)
                            Text("This action is permanent and irreversible.")
                                .font(.system(size: 11))
                                .foregroundColor(.statusCancelled)
                        }
                    }
                    .padding(.top, 10)

                    Text("By deleting your account:\n• All registered vehicles will be removed from your garage.\n• Active service appointments and quote estimates will be cancelled.\n• Saved payment methods and personal data will be completely wiped.\n• Your security session tokens will be permanently revoked.")
                        .font(.system(size: 12))
                        .foregroundColor(.textMuted)
                        .lineSpacing(4)
                        .padding(14)
                        .background(Color.cardDarkElevated)
                        .cornerRadius(10)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.statusCancelled.opacity(0.3), lineWidth: 1))

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Current Password (Optional)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.textForeground)

                        SecureField("Enter password to confirm", text: $deletionPassword)
                            .textFieldStyle(DarkInputFieldStyle())
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Reason for Departure (Optional)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.textForeground)

                        TextField("Tell us why you are leaving...", text: $deletionReason)
                            .textFieldStyle(DarkInputFieldStyle())
                    }

                    if !deletionErrorMessage.isEmpty {
                        Text(deletionErrorMessage)
                            .font(.system(size: 12))
                            .foregroundColor(.statusCancelled)
                    }

                    Button(action: performDeleteAccount) {
                        if isDeletingAccount {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("I Understand, Delete My Account")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.white)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.statusCancelled)
                    .cornerRadius(10)
                    .disabled(isDeletingAccount)
                    .padding(.top, 10)
                }
                .padding(20)
            }
            .background(Color.bgDark.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showDeleteConfirmSheet = false
                    }
                    .foregroundColor(.textMuted)
                }
            }
        }
    }

    private func saveProfile() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        isSaving = true
        errorMessage = ""

        Task {
            do {
                let resp = try await APIService.shared.updateProfile(
                    name: trimmedName,
                    phone: phone.trimmingCharacters(in: .whitespaces).isEmpty ? nil : phone.trimmingCharacters(in: .whitespaces),
                    address: address.trimmingCharacters(in: .whitespaces).isEmpty ? nil : address.trimmingCharacters(in: .whitespaces),
                    city: city.trimmingCharacters(in: .whitespaces).isEmpty ? nil : city.trimmingCharacters(in: .whitespaces),
                    state: state.trimmingCharacters(in: .whitespaces).isEmpty ? nil : state.trimmingCharacters(in: .whitespaces),
                    postalCode: postalCode.trimmingCharacters(in: .whitespaces).isEmpty ? nil : postalCode.trimmingCharacters(in: .whitespaces)
                )

                await MainActor.run {
                    isSaving = false
                    if resp.success == true || resp.data != nil {
                        showSavedAlert = true
                    } else {
                        errorMessage = resp.message ?? "Failed to update profile."
                        showErrorAlert = true
                    }
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }

    private func performDeleteAccount() {
        isDeletingAccount = true
        deletionErrorMessage = ""

        Task {
            do {
                let password = deletionPassword.trimmingCharacters(in: .whitespaces).isEmpty ? nil : deletionPassword
                let reason = deletionReason.trimmingCharacters(in: .whitespaces).isEmpty ? nil : deletionReason
                _ = try await APIService.shared.deleteCustomerAccount(password: password, reason: reason)

                await MainActor.run {
                    isDeletingAccount = false
                    showDeleteConfirmSheet = false
                    dismiss()
                }
            } catch {
                await MainActor.run {
                    isDeletingAccount = false
                    deletionErrorMessage = error.localizedDescription
                }
            }
        }
    }
}
