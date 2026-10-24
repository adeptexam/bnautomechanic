//
//  ProfileDetailsView.swift
//  BNAutoMechanic
//
//  Pixel-perfect replica of Android ActivityProfileDetails
//

import SwiftUI

struct ProfileDetailsView: View {
    @EnvironmentObject var session: SessionManager
    @Environment(\.dismiss) var dismiss

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var showSavedAlert = false

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

                    // Full Name
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Full Name")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.textForeground)

                        TextField("Your full name", text: $name)
                            .textFieldStyle(DarkInputFieldStyle())
                    }

                    // Email (Read-only or editable)
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Email Address")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.textForeground)

                        TextField("your.email@example.com", text: $email)
                            .textFieldStyle(DarkInputFieldStyle())
                            .disabled(true)
                            .opacity(0.7)
                    }

                    // Phone
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Phone Number")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.textForeground)

                        TextField("+1 (609) 555-0199", text: $phone)
                            .textFieldStyle(DarkInputFieldStyle())
                            .keyboardType(.phonePad)
                    }

                    // Save Button
                    Button(action: saveProfile) {
                        Text("Save Profile Changes")
                    }
                    .buttonStyle(GoldButtonStyle(isEnabled: !name.trimmingCharacters(in: .whitespaces).isEmpty))
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .padding(.top, 12)
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
            }
        }
        .alert("Profile Updated", isPresented: $showSavedAlert) {
            Button("OK") { dismiss() }
        } message: {
            Text("Your profile information has been saved successfully.")
        }
    }

    private func saveProfile() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        let current = session.currentUser
        let updatedUser = User(
            id: current?.id ?? 0,
            name: trimmedName,
            email: email,
            phone: phone.trimmingCharacters(in: .whitespaces),
            address: current?.address,
            city: current?.city,
            role: current?.role ?? "CUSTOMER",
            status: current?.status ?? "ACTIVE",
            emailVerified: current?.emailVerified ?? true,
            createdAt: current?.createdAt
        )

        session.saveAuth(token: session.getToken() ?? "auth_token", user: updatedUser)
        showSavedAlert = true
    }
}
