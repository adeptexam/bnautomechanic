//
//  MainTabView.swift
//  BNAutoMechanic
//

import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    init() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(Color.bgDark.opacity(0.95))
        appearance.shadowColor = UIColor(Color.borderSubtle)

        let normalAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(Color.textMuted),
            .font: UIFont.systemFont(ofSize: 11)
        ]
        let selectedAttributes: [NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor(Color.primaryGold),
            .font: UIFont.boldSystemFont(ofSize: 11)
        ]

        appearance.stackedLayoutAppearance.normal.titleTextAttributes = normalAttributes
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = selectedAttributes
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(Color.textMuted)
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(Color.primaryGold)

        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                PortalView(selectedTab: $selectedTab)
            }
            .tabItem {
                Label("Portal", systemImage: "square.grid.2x2.fill")
            }
            .tag(0)

            NavigationStack {
                ServicesView(selectedTab: $selectedTab)
            }
            .tabItem {
                Label("Services", systemImage: "wrench.fill")
            }
            .tag(1)

            NavigationStack {
                BookingsView()
            }
            .tabItem {
                Label("Bookings", systemImage: "calendar")
            }
            .tag(2)

            NavigationStack {
                ChatListView()
            }
            .tabItem {
                Label("Chat", systemImage: "bubble.left.fill")
            }
            .tag(3)

            NavigationStack {
                ProfileView(selectedTab: $selectedTab)
            }
            .tabItem {
                Label("Account", systemImage: "person.fill")
            }
            .tag(4)
        }
        .accentColor(.primaryGold)
    }
}
