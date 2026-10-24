//
//  SuperadminDashboardView.swift
//  BNAutoMechanic
//
//  Superadmin Master Command Center & Admin Workshop Overview.
//  Presents live workshop metrics, quick administrative dispatch controls,
//  Master Administrative Controls launcher, and role switcher.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct SuperadminDashboardView: View {
    @EnvironmentObject var session: SessionManager
    @Binding var selectedTab: Int

    @State private var stats: AdminStats? = nil
    @State private var settings: PublicSettings? = nil
    @State private var unassignedCount: Int = 0
    @State private var isLoading: Bool = false

    var isSuperAdmin: Bool {
        session.currentUser?.isSuperAdmin ?? true
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 18) {
                // Top Executive Cockpit Header
                executiveHeader

                // Maintenance Mode Warning Banner (if active)
                if settings?.maintenanceMode == true {
                    maintenanceActiveBanner
                }

                // Urgent Dispatch Alert (if unassigned visits exist)
                if unassignedCount > 0 {
                    urgentDispatchCard
                }

                // Live Workshop Key Metrics Grid
                metricsGridSection

                // Master Administrative Controls Hero Card
                masterControlsHeroCard

                // Core Management Hub
                managementHubSection

                // View Mode Switcher
                portalModeSwitcherCard
            }
            .padding(.horizontal, 16)
            .padding(.top, 10)
            .bottomDockClearance()
        }
        .background(Color.bgDark.ignoresSafeArea())
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .refreshable {
            await loadDashboardData()
        }
        .task {
            await loadDashboardData()
        }
    }

    // MARK: - Executive Cockpit Header
    private var executiveHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.primaryGold)
                    .frame(width: 48, height: 48)
                    .shadow(color: Color.primaryGold.opacity(0.3), radius: 8, x: 0, y: 3)
                Image(systemName: isSuperAdmin ? "crown.fill" : "shield.fill")
                    .font(.system(size: 22))
                    .foregroundColor(.bgDark)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(isSuperAdmin ? "SUPERADMIN PORTAL" : "ADMIN WORKSHOP PORTAL")
                        .font(.system(size: 15, weight: .black))
                        .foregroundColor(.primaryGold)
                        .tracking(1)

                    Circle()
                        .fill(Color.statusConfirmed)
                        .frame(width: 7, height: 7)
                }

                Text(session.currentUser?.name ?? "Administrator")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.textForeground)

                Text(isSuperAdmin ? "Master System Governance Active" : "Workshop Operations Active")
                    .font(.system(size: 10))
                    .foregroundColor(.textMuted)
            }

            Spacer()

            // Notification or Quick refresh
            NavigationLink(destination: NotificationsView()) {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.cardDarkElevated)
                        .frame(width: 40, height: 40)
                        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.borderSubtle, lineWidth: 1))
                    Image(systemName: "bell.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.primaryGold)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Maintenance Active Banner
    private var maintenanceActiveBanner: some View {
        HStack(spacing: 10) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundColor(.statusCancelled)
                .font(.system(size: 18))

            VStack(alignment: .leading, spacing: 2) {
                Text("MAINTENANCE LOCKDOWN ACTIVE")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.statusCancelled)
                Text(settings?.maintenanceMessage ?? "Customer portal bookings are currently disabled.")
                    .font(.system(size: 11))
                    .foregroundColor(.textMuted)
                    .lineLimit(1)
            }

            Spacer()

            NavigationLink(destination: MasterAdminControlsView()) {
                Text("Manage")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.bgDark)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.statusCancelled)
                    .cornerRadius(6)
            }
        }
        .padding(12)
        .background(Color.statusCancelled.opacity(0.12))
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.statusCancelled.opacity(0.4), lineWidth: 1))
    }

    // MARK: - Urgent Dispatch Card
    private var urgentDispatchCard: some View {
        NavigationLink(destination: StaffDispatcherAdminView()) {
            HStack(spacing: 12) {
                ZStack {
                    Circle()
                        .fill(Color.statusWarning.opacity(0.2))
                        .frame(width: 40, height: 40)
                    Image(systemName: "person.crop.circle.badge.exclamationmark")
                        .foregroundColor(.statusWarning)
                        .font(.system(size: 18))
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("\(unassignedCount) Visits Waiting for Dispatch")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.textForeground)
                    Text("Technicians need to be assigned to active vehicle bays")
                        .font(.system(size: 11))
                        .foregroundColor(.textMuted)
                }

                Spacer()

                Text("Dispatch →")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.primaryGold)
            }
            .padding(14)
            .background(Color.cardDarkElevated)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.primaryGold.opacity(0.5), lineWidth: 1)
            )
        }
    }

    // MARK: - Live Metrics Grid Section
    private var metricsGridSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("LIVE WORKSHOP FIGURES")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.primaryGold)
                    .tracking(0.8)
                Spacer()
                Text("Real-Time Database")
                    .font(.system(size: 10))
                    .foregroundColor(.textSubtle)
            }

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                metricCard(
                    title: "Total Revenue",
                    value: String(format: "$%.2f", stats?.revenueTotal ?? 0.0),
                    icon: "dollarsign.circle.fill",
                    color: .primaryGold
                )

                metricCard(
                    title: "Today's Bookings",
                    value: "\(stats?.bookingsToday ?? 0)",
                    icon: "calendar.badge.clock",
                    color: .primaryGold
                )

                metricCard(
                    title: "Pending Estimates",
                    value: "\(stats?.estimatesPending ?? 0)",
                    icon: "doc.text.badge.plus",
                    color: .statusWarning
                )

                metricCard(
                    title: "Approved Estimates",
                    value: "\(stats?.estimatesApproved ?? 0)",
                    icon: "checkmark.seal.fill",
                    color: .statusConfirmed
                )

                metricCard(
                    title: "Active In Bay",
                    value: "\(stats?.servicesCompleted ?? 0) Completed",
                    icon: "wrench.and.screwdriver.fill",
                    color: .primaryGold
                )

                metricCard(
                    title: "Total Customers",
                    value: "\(stats?.customersTotal ?? 0) Registered",
                    icon: "person.2.fill",
                    color: .textForeground
                )
            }
        }
    }

    private func metricCard(title: String, value: String, icon: String, color: Color) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(color)
                Spacer()
            }

            Text(value)
                .font(.system(size: 16, weight: .black))
                .foregroundColor(.textForeground)

            Text(title)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.textMuted)
                .lineLimit(1)
        }
        .padding(12)
        .luxuryCard()
    }

    // MARK: - Master Controls Hero Card
    private var masterControlsHeroCard: some View {
        NavigationLink(destination: MasterAdminControlsView()) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.primaryGold)
                            .frame(width: 44, height: 44)
                        Image(systemName: "gearshape.2.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.bgDark)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Master Administrative Controls")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.textForeground)
                        Text("Maintenance Lock, Square Gateways, Operating Hours")
                            .font(.system(size: 11))
                            .foregroundColor(.textMuted)
                            .lineLimit(1)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .foregroundColor(.primaryGold)
                }
            }
            .padding(14)
            .background(
                LinearGradient(
                    colors: [Color.primaryGold.opacity(0.16), Color.cardDarkElevated],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.primaryGold.opacity(0.5), lineWidth: 1.2))
        }
    }

    // MARK: - Management Hub Section
    private var managementHubSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ADMINISTRATIVE MODULES")
                .font(.system(size: 11, weight: .black))
                .foregroundColor(.primaryGold)
                .tracking(0.8)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 3), spacing: 10) {
                moduleCard(
                    title: "Dispatcher",
                    subtitle: "Bay Assignment",
                    icon: "arrow.triangle.pull",
                    destination: AnyView(StaffDispatcherAdminView())
                )

                moduleCard(
                    title: "Bookings",
                    subtitle: "Full CRUD & Estimates",
                    icon: "calendar.badge.checkmark",
                    destination: AnyView(AdminBookingsManagerView())
                )

                moduleCard(
                    title: "Catalog",
                    subtitle: "Services & Brands",
                    icon: "wrench.and.screwdriver.fill",
                    destination: AnyView(AdminCatalogManagerView())
                )

                moduleCard(
                    title: "Users & Roles",
                    subtitle: "Permissions & Staff",
                    icon: "person.3.fill",
                    destination: AnyView(AdminUsersRolesView())
                )

                moduleCard(
                    title: "Financials",
                    subtitle: "Invoices & Cash",
                    icon: "banknote.fill",
                    destination: AnyView(AdminFinancialsView())
                )

                moduleCard(
                    title: "Master Settings",
                    subtitle: "Platform Engine",
                    icon: "slider.horizontal.3",
                    destination: AnyView(MasterAdminControlsView())
                )
            }
        }
    }

    private func moduleCard(title: String, subtitle: String, icon: String, destination: AnyView) -> some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.primaryGold)

                Text(title)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.textForeground)

                Text(subtitle)
                    .font(.system(size: 9))
                    .foregroundColor(.textMuted)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .luxuryCard()
        }
    }

    // MARK: - Portal Mode Switcher Card
    private var portalModeSwitcherCard: some View {
        VStack(spacing: 8) {
            Text("VIEW PERSPECTIVE SWITCHER")
                .font(.system(size: 10, weight: .black))
                .foregroundColor(.textSubtle)

            HStack(spacing: 10) {
                Button {
                    triggerHaptic()
                    session.setPortalMode(.customer)
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "eye.fill")
                        Text("Preview Customer View")
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.textForeground)
                    .frame(maxWidth: .infinity)
                    .frame(height: 38)
                    .background(Color.cardDarkElevated)
                    .cornerRadius(8)
                    .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.borderSubtle, lineWidth: 1))
                }

                if isSuperAdmin {
                    Button {
                        triggerHaptic()
                        session.setPortalMode(.admin)
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "person.badge.shield.checkmark.fill")
                            Text("Switch to Admin")
                        }
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.primaryGold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 38)
                        .background(Color.primaryGold.opacity(0.12))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.primaryGold, lineWidth: 1))
                    }
                }
            }
        }
        .padding(14)
        .luxuryCard()
    }

    // MARK: - Load Dashboard Data
    private func loadDashboardData() async {
        isLoading = true
        let api = APIService.shared

        // Load Stats
        if let resp = try? await api.getAdminStats() {
            await MainActor.run { stats = resp.data }
        }

        // Load Settings
        if let sResp = try? await api.getSettings() {
            await MainActor.run { settings = sResp.data }
        }

        // Count unassigned bookings
        if let bResp = try? await api.getAdminBookings(perPage: 50) {
            let items = bResp.data?.items ?? []
            let unassigned = items.filter { ($0.mechanicId == nil || $0.mechanicId == 0) && !$0.isClosed() }
            await MainActor.run {
                unassignedCount = unassigned.count
            }
        }

        await MainActor.run { isLoading = false }
    }

    private func triggerHaptic() {
        #if os(iOS)
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.prepare()
        impact.impactOccurred()
        #endif
    }
}
