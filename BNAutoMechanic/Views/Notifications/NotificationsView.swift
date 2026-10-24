//
//  NotificationsView.swift
//  BNAutoMechanic
//
//  Pixel-perfect replica of Android NotificationsActivity and item_notification
//

import SwiftUI

struct NotificationsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var notifications: [AppNotification] = []
    @State private var isLoading = false

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

                Text("Notifications")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.textForeground)

                Spacer()

                if notifications.contains(where: { !$0.read }) {
                    Button(action: markAllAsRead) {
                        Text("Mark all read")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.primaryGold)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider().background(Color.borderSubtle)

            if isLoading {
                Spacer()
                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .primaryGold))
                Spacer()
            } else if notifications.isEmpty {
                Spacer()
                VStack(spacing: 14) {
                    Image(systemName: "bell.slash")
                        .font(.system(size: 44))
                        .foregroundColor(.textSubtle)

                    Text("No notifications yet")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.textForeground)

                    Text("Status updates for bookings, estimates, chat messages, and deals will arrive here.")
                        .font(.system(size: 13))
                        .foregroundColor(.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(notifications) { notif in
                            Button(action: { markAsRead(notif) }) {
                                notificationCard(notif)
                            }
                        }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 36)
                }
                .refreshable {
                    await loadNotifications()
                }
            }
        }
        .background(Color.bgDark.ignoresSafeArea())
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .hideBottomDockOnPush()
        .task {
            await loadNotifications()
        }
    }

    // MARK: - Notification Card (Matching item_notification.xml)
    private func notificationCard(_ notif: AppNotification) -> some View {
        let isRead = notif.read
        return HStack(alignment: .top, spacing: 12) {
            // Icon
            ZStack {
                Circle()
                    .fill(isRead ? Color.cardDarkElevated : Color.primaryGoldTint)
                    .frame(width: 40, height: 40)
                Image(systemName: iconForType(notif.type))
                    .font(.system(size: 16))
                    .foregroundColor(isRead ? .textMuted : .primaryGold)
            }

            // Body
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(notif.title)
                        .font(.system(size: 14, weight: isRead ? .medium : .bold))
                        .foregroundColor(.textForeground)
                        .lineLimit(1)

                    Spacer()

                    if !isRead {
                        Circle()
                            .fill(Color.primaryGold)
                            .frame(width: 8, height: 8)
                    }
                }

                if !notif.message.isEmpty {
                    Text(notif.message)
                        .font(.system(size: 12))
                        .foregroundColor(.textMuted)
                        .lineLimit(3)
                        .multilineTextAlignment(.leading)
                }

                if let time = notif.createdAt {
                    Text(time)
                        .font(.system(size: 10))
                        .foregroundColor(.textSubtle)
                        .padding(.top, 2)
                }
            }
        }
        .padding(14)
        .background(isRead ? Color.cardDark : Color.cardDarkElevated)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(isRead ? Color.borderSubtle : Color.goldBorder, lineWidth: 1)
        )
    }

    private func iconForType(_ type: String?) -> String {
        guard let type = type?.uppercased() else { return "bell.fill" }
        if type.contains("BOOKING") { return "calendar" }
        if type.contains("ESTIMATE") { return "doc.text.fill" }
        if type.contains("CHAT") { return "bubble.left.fill" }
        if type.contains("TOWING") { return "truck.box.fill" }
        if type.contains("DEAL") { return "tag.fill" }
        return "bell.fill"
    }

    private func loadNotifications() async {
        isLoading = notifications.isEmpty
        if let response = try? await APIService.shared.getNotifications() {
            await MainActor.run {
                notifications = response.data?.items ?? []
                isLoading = false
            }
        } else {
            await MainActor.run { isLoading = false }
        }
    }

    private func markAsRead(_ notif: AppNotification) {
        if notif.read == true { return }
        if let idx = notifications.firstIndex(where: { $0.id == notif.id }) {
            notifications[idx].read = true
        }
        Task {
            _ = try? await APIService.shared.markNotificationRead(id: notif.id)
        }
    }

    private func markAllAsRead() {
        for idx in notifications.indices {
            notifications[idx].read = true
        }
        Task {
            _ = try? await APIService.shared.markAllNotificationsRead()
        }
    }
}
