//
//  ProfileView.swift
//  BNAutoMechanic
//
//  Pixel-perfect replica of Android FragmentProfile
//

import SwiftUI

struct ProfileView: View {
    @EnvironmentObject var session: SessionManager
    @Binding var selectedTab: Int
    @State private var showLogoutAlert = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header Title
                HStack {
                    Text("Account")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.textForeground)
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .padding(.bottom, 12)

                // User Info Card
                userCard
                    .padding(.horizontal, 16)
                    .padding(.top, 4)

                // Section 1: Workshop Management
                sectionHeader(title: "WORKSHOP MANAGEMENT")
                VStack(spacing: 0) {
                    NavigationLink(destination: VehiclesView()) {
                        profileMenuRow(icon: "car.fill", title: "My Vehicles & Garage")
                    }
                    menuDivider

                    Button(action: { selectedTab = 2 }) {
                        profileMenuRow(icon: "calendar", title: "My Bookings & Appointments")
                    }
                    menuDivider

                    NavigationLink(destination: ServiceHistoryView()) {
                        profileMenuRow(icon: "wrench.and.screwdriver.fill", title: "Vehicle Service History")
                    }
                    menuDivider

                    NavigationLink(destination: InvoicesView()) {
                        profileMenuRow(icon: "doc.text.fill", title: "Invoices & Payment Records")
                    }
                }
                .luxuryCard()
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Section 2: Roadside & Tracking
                sectionHeader(title: "ROADSIDE & TRACKING")
                VStack(spacing: 0) {
                    NavigationLink(destination: TowingView()) {
                        profileMenuRow(icon: "truck.box.fill", title: "Roadside Assistance & Towing")
                    }
                    menuDivider

                    NavigationLink(destination: TowingStatusView()) {
                        profileMenuRow(icon: "clock.fill", title: "Active Towing Status")
                    }
                    menuDivider

                    NavigationLink(destination: TrackBookingView()) {
                        profileMenuRow(icon: "magnifyingglass", title: "Track a Visit by Reference")
                    }
                }
                .luxuryCard()
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Section 3: Reviews & Discounts
                sectionHeader(title: "REVIEWS & DISCOUNTS")
                VStack(spacing: 0) {
                    NavigationLink(destination: ReviewsView()) {
                        profileMenuRow(icon: "star.fill", title: "Workshop Reviews & Ratings")
                    }
                    menuDivider

                    NavigationLink(destination: DealsView()) {
                        profileMenuRow(icon: "tag.fill", title: "Promotional Deals & Coupons")
                    }
                }
                .luxuryCard()
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Section 4: Workshop Info
                sectionHeader(title: "WORKSHOP INFO")
                VStack(spacing: 0) {
                    NavigationLink(destination: InfoPageView(pageType: .info)) {
                        profileMenuRow(icon: "info.circle.fill", title: "Workshop Information & Contacts")
                    }
                    menuDivider

                    NavigationLink(destination: InfoPageView(pageType: .terms)) {
                        profileMenuRow(icon: "shield.checkerboard", title: "Warranty & Terms of Service")
                    }
                }
                .luxuryCard()
                .padding(.horizontal, 16)
                .padding(.top, 8)

                // Logout Button
                Button(action: { showLogoutAlert = true }) {
                    HStack(spacing: 10) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.statusCancelled)

                        Text("Log Out")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.statusCancelled)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .luxuryCard()
                }
                .padding(.horizontal, 16)
                .padding(.top, 24)
                .padding(.bottom, 32)
            }
        }
        .background(Color.bgDark.ignoresSafeArea())
        .navigationBarHidden(true)
        .alert("Log Out", isPresented: $showLogoutAlert) {
            Button("Log Out", role: .destructive) {
                session.logout()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to sign out of your account?")
        }
    }

    // MARK: - User Card
    private var userCard: some View {
        NavigationLink(destination: ProfileDetailsView()) {
            HStack(spacing: 14) {
                // Large Avatar
                ZStack {
                    Circle()
                        .fill(Color.primaryGoldTint)
                        .frame(width: 56, height: 56)
                        .overlay(
                            Circle().stroke(Color.goldBorder, lineWidth: 1.5)
                        )
                    Text(session.currentUser?.initials() ?? "BN")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.primaryGold)
                }

                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text(session.currentUser?.name ?? "Customer")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.textForeground)
                        Image(systemName: "pencil.line")
                            .font(.system(size: 12))
                            .foregroundColor(.primaryGold)
                    }

                    Text(session.currentUser?.email ?? "service@bnautomechanic.net")
                        .font(.system(size: 12))
                        .foregroundColor(.textMuted)

                    let role = session.currentUser?.role ?? "CUSTOMER"
                    let roleTitle = (role == "ADMIN" || role == "SUPER_ADMIN") ? "WORKSHOP STAFF" : "CUSTOMER ACCOUNT"
                    Text(roleTitle)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.primaryGold)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(Color.primaryGoldTint)
                        .cornerRadius(4)
                        .padding(.top, 2)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.textSubtle)
            }
            .padding(16)
            .luxuryCard()
        }
    }

    // MARK: - Section Header
    private func sectionHeader(title: String) -> some View {
        HStack {
            Text(title)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.textSubtle)
                .tracking(0.6)
            Spacer()
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
    }

    // MARK: - Profile Menu Row
    private func profileMenuRow(icon: String, title: String) -> some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 15))
                .foregroundColor(.primaryGold)
                .frame(width: 24, height: 24)

            Text(title)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.textForeground)

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.textSubtle)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    private var menuDivider: some View {
        Divider()
            .background(Color.borderSubtle)
            .padding(.leading, 54)
    }
}
