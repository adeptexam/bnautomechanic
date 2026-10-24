//
//  MainTabView.swift
//  BNAutoMechanic
//
//  Role-Aware Executive Navigation & High-Visibility Floating Luxury Dock.
//  Tailored specifically for Superadmin, Admin, Technician, and Customer portals.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Navigation Tab Definition
struct RoleTabItem: Identifiable {
    let id: Int
    let title: String
    let icon: String
}

// MARK: - Main Tab View
struct MainTabView: View {
    @EnvironmentObject var session: SessionManager
    @State private var selectedTab = 0

    init() {
        #if os(iOS)
        // Completely hide the native UITabBar so our custom luxury floating dock takes over
        let appearance = UITabBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.shadowColor = .clear
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
        UITabBar.appearance().isHidden = true
        #endif
    }

    private var activeMode: PortalMode {
        session.activePortalMode
    }

    private var currentTabItems: [RoleTabItem] {
        switch activeMode {
        case .superadmin:
            return [
                RoleTabItem(id: 0, title: "Cockpit", icon: "shield.checkered"),
                RoleTabItem(id: 1, title: "Dispatcher", icon: "arrow.triangle.pull"),
                RoleTabItem(id: 2, title: "Bookings", icon: "calendar.badge.checkmark"),
                RoleTabItem(id: 3, title: "Catalog", icon: "wrench.and.screwdriver.fill"),
                RoleTabItem(id: 4, title: "Master Engine", icon: "gearshape.2.fill")
            ]
        case .admin:
            return [
                RoleTabItem(id: 0, title: "Dashboard", icon: "shield.fill"),
                RoleTabItem(id: 1, title: "Dispatcher", icon: "arrow.triangle.pull"),
                RoleTabItem(id: 2, title: "Bookings", icon: "calendar.badge.clock"),
                RoleTabItem(id: 3, title: "Operations", icon: "banknote.fill"),
                RoleTabItem(id: 4, title: "Account", icon: "person.crop.circle.fill")
            ]
        case .technician:
            return [
                RoleTabItem(id: 0, title: "My Bay", icon: "wrench.and.screwdriver.fill"),
                RoleTabItem(id: 1, title: "Messages", icon: "bubble.left.and.bubble.right.fill"),
                RoleTabItem(id: 2, title: "Account", icon: "person.crop.circle.fill")
            ]
        case .customer:
            return [
                RoleTabItem(id: 0, title: "Portal", icon: "square.grid.2x2.fill"),
                RoleTabItem(id: 1, title: "Services", icon: "wrench.and.screwdriver.fill"),
                RoleTabItem(id: 2, title: "Bookings", icon: "calendar.badge.clock"),
                RoleTabItem(id: 3, title: "Messages", icon: "bubble.left.and.bubble.right.fill"),
                RoleTabItem(id: 4, title: "Account", icon: "person.crop.circle.fill")
            ]
        }
    }

    var body: some View {
        ZStack(alignment: .top) {
            TabView(selection: $selectedTab) {
                switch activeMode {
                case .superadmin:
                    superAdminTabs
                case .admin:
                    adminTabs
                case .technician:
                    technicianTabs
                case .customer:
                    customerTabs
                }
            }
            #if os(iOS)
            .toolbar(.hidden, for: .tabBar)
            #endif
            .safeAreaInset(edge: .bottom) {
                if !session.isTabBarHidden {
                    customFloatingBottomBar
                        .transition(.asymmetric(
                            insertion: .move(edge: .bottom).combined(with: .opacity),
                            removal: .move(edge: .bottom).combined(with: .opacity)
                        ))
                }
            }
            .ignoresSafeArea(.keyboard, edges: .bottom)

            // Return to Executive View floating pill (when Superadmin/Admin is in customer preview)
            if (session.currentUser?.isSuperAdmin == true || session.currentUser?.isAdmin == true) && activeMode == .customer {
                previewReturnBanner
            }
        }
        .onChange(of: selectedTab) { _ in
            session.setTabBarHidden(false)
        }
        .onChange(of: session.activePortalMode) { _ in
            selectedTab = 0
            session.setTabBarHidden(false)
        }
    }

    // MARK: - Superadmin Tabs
    @ViewBuilder
    private var superAdminTabs: some View {
        NavigationStack {
            SuperadminDashboardView(selectedTab: $selectedTab)
        }
        .tag(0)

        NavigationStack {
            StaffDispatcherAdminView()
        }
        .tag(1)

        NavigationStack {
            AdminBookingsManagerView()
        }
        .tag(2)

        NavigationStack {
            AdminCatalogManagerView()
        }
        .tag(3)

        NavigationStack {
            MasterAdminControlsView()
        }
        .tag(4)
    }

    // MARK: - Admin Tabs
    @ViewBuilder
    private var adminTabs: some View {
        NavigationStack {
            SuperadminDashboardView(selectedTab: $selectedTab)
        }
        .tag(0)

        NavigationStack {
            StaffDispatcherAdminView()
        }
        .tag(1)

        NavigationStack {
            AdminBookingsManagerView()
        }
        .tag(2)

        NavigationStack {
            AdminFinancialsView()
        }
        .tag(3)

        NavigationStack {
            ProfileView(selectedTab: $selectedTab)
        }
        .tag(4)
    }

    // MARK: - Technician Tabs
    @ViewBuilder
    private var technicianTabs: some View {
        NavigationStack {
            MechanicPortalView()
        }
        .tag(0)

        NavigationStack {
            ChatListView()
        }
        .tag(1)

        NavigationStack {
            ProfileView(selectedTab: $selectedTab)
        }
        .tag(2)
    }

    // MARK: - Customer Tabs
    @ViewBuilder
    private var customerTabs: some View {
        NavigationStack {
            PortalView(selectedTab: $selectedTab)
        }
        .tag(0)

        NavigationStack {
            ServicesView(selectedTab: $selectedTab)
        }
        .tag(1)

        NavigationStack {
            BookingsView()
        }
        .tag(2)

        NavigationStack {
            ChatListView()
        }
        .tag(3)

        NavigationStack {
            ProfileView(selectedTab: $selectedTab)
        }
        .tag(4)
    }

    // MARK: - Preview Return Banner
    private var previewReturnBanner: some View {
        Button {
            triggerHaptic()
            session.syncPortalMode()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: "arrow.uturn.backward.circle.fill")
                    .foregroundColor(.bgDark)
                Text("Customer Preview Active • Tap to Return to Executive Center")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.bgDark)
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 8)
            .background(Color.primaryGold)
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.4), radius: 6, x: 0, y: 3)
        }
        .padding(.top, 48)
    }

    // MARK: - High-Visibility Floating Luxury Dock
    private var customFloatingBottomBar: some View {
        HStack(spacing: 0) {
            ForEach(currentTabItems) { tab in
                let isSelected = selectedTab == tab.id

                Button {
                    triggerHaptic()
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
                        selectedTab = tab.id
                    }
                } label: {
                    tabItemView(for: tab, isSelected: isSelected)
                }
                .buttonStyle(PlainButtonStyle())
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            ZStack {
                // Cockpit dark base
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .fill(Color(hex: "0C0E14").opacity(0.96))

                // High-visibility golden metallic perimeter rim
                RoundedRectangle(cornerRadius: 26, style: .continuous)
                    .strokeBorder(
                        LinearGradient(
                            colors: [
                                Color.primaryGold.opacity(0.65),
                                Color(hex: "2E3442"),
                                Color.primaryGold.opacity(0.45)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1.2
                    )
            }
        )
        // Layered elevation & ambient gold glow
        .shadow(color: Color.black.opacity(0.75), radius: 18, x: 0, y: 8)
        .shadow(color: Color.primaryGold.opacity(0.14), radius: 14, x: 0, y: 2)
        .padding(.horizontal, 16)
        .padding(.top, 4)
        .padding(.bottom, 6)
    }

    // MARK: - Tab Item View
    @ViewBuilder
    private func tabItemView(for tab: RoleTabItem, isSelected: Bool) -> some View {
        VStack(spacing: 3) {
            ZStack {
                if isSelected {
                    // Radiant pill backdrop for the active tab
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color.primaryGold.opacity(0.24),
                                    Color.primaryGold.opacity(0.10)
                                ],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                .stroke(Color.primaryGold.opacity(0.6), lineWidth: 1)
                        )
                        .frame(width: 52, height: 32)
                        .transition(.scale.combined(with: .opacity))
                }

                Image(systemName: tab.icon)
                    .font(.system(size: isSelected ? 18 : 17, weight: isSelected ? .bold : .medium))
                    .foregroundColor(isSelected ? .primaryGold : Color(hex: "E2E4E9"))
                    .scaleEffect(isSelected ? 1.08 : 1.0)
                    .frame(height: 24)
            }
            .frame(height: 32)

            Text(tab.title)
                .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .primaryGold : Color(hex: "9EA2AB"))
                .lineLimit(1)

            // Active indicator pip
            Circle()
                .fill(isSelected ? Color.primaryGold : Color.clear)
                .frame(width: 4, height: 4)
                .shadow(color: isSelected ? Color.primaryGold.opacity(0.8) : Color.clear, radius: 2)
        }
        .padding(.vertical, 2)
        .contentShape(Rectangle())
    }

    // MARK: - Haptic Feedback
    private func triggerHaptic() {
        #if os(iOS)
        let impact = UIImpactFeedbackGenerator(style: .light)
        impact.prepare()
        impact.impactOccurred()
        #endif
    }
}
