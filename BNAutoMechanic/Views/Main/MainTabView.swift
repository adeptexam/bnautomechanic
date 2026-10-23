//
//  MainTabView.swift
//  BNAutoMechanic
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

// MARK: - Navigation Tab Item Definition
enum MainTabItem: Int, CaseIterable, Identifiable {
    case portal = 0
    case services = 1
    case bookings = 2
    case chat = 3
    case account = 4

    var id: Int { rawValue }

    var title: String {
        switch self {
        case .portal: return "Portal"
        case .services: return "Services"
        case .bookings: return "Bookings"
        case .chat: return "Messages"
        case .account: return "Account"
        }
    }

    var icon: String {
        switch self {
        case .portal: return "square.grid.2x2.fill"
        case .services: return "wrench.and.screwdriver.fill"
        case .bookings: return "calendar.badge.clock"
        case .chat: return "bubble.left.and.bubble.right.fill"
        case .account: return "person.crop.circle.fill"
        }
    }
}

// MARK: - Main Tab View
struct MainTabView: View {
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

    var body: some View {
        TabView(selection: $selectedTab) {
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
        #if os(iOS)
        .toolbar(.hidden, for: .tabBar)
        #endif
        .safeAreaInset(edge: .bottom) {
            customFloatingBottomBar
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }

    // MARK: - High-Visibility Floating Luxury Dock
    private var customFloatingBottomBar: some View {
        HStack(spacing: 0) {
            ForEach(MainTabItem.allCases) { tab in
                let isSelected = selectedTab == tab.rawValue

                Button {
                    triggerHaptic()
                    withAnimation(.spring(response: 0.32, dampingFraction: 0.72)) {
                        selectedTab = tab.rawValue
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
                // Glassmorphic cockpit dark base
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
    private func tabItemView(for tab: MainTabItem, isSelected: Bool) -> some View {
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
