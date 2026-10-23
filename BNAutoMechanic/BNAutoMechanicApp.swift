//
//  BNAutoMechanicApp.swift
//  BNAutoMechanic
//

import SwiftUI

@main
struct BNAutoMechanicApp: App {
    @StateObject private var sessionManager = SessionManager.shared

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(sessionManager)
                .preferredColorScheme(.dark)
        }
    }
}

// MARK: - Root Navigation
struct RootView: View {
    @EnvironmentObject var session: SessionManager
    @State private var showSplash = true

    var body: some View {
        ZStack {
            Color.bgDark.ignoresSafeArea()

            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else if session.isLoggedIn {
                MainTabView()
                    .transition(.opacity)
            } else {
                NavigationStack {
                    LoginView()
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.4), value: showSplash)
        .animation(.easeInOut(duration: 0.3), value: session.isLoggedIn)
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
                withAnimation {
                    showSplash = false
                }
            }
        }
    }
}

// MARK: - Splash Screen
struct SplashView: View {
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0

    var body: some View {
        ZStack {
            Color.bgDark.ignoresSafeArea()

            VStack(spacing: 20) {
                Image("AppLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 130, height: 130)
                    .shadow(color: Color.primaryGold.opacity(0.35), radius: 20, x: 0, y: 8)

                Text("BN AUTO MECHANIC")
                    .font(.system(size: 22, weight: .black))
                    .foregroundColor(.textForeground)
                    .tracking(2)

                Text("Premium Automotive Care")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.textMuted)
                    .tracking(1)
            }
            .scaleEffect(scale)
            .opacity(opacity)
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
        }
    }
}
