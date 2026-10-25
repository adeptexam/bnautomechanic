//
//  ServiceHistoryView.swift
//  BNAutoMechanic
//
//  Pixel-perfect replica of Android ServiceHistoryActivity
//

import SwiftUI

struct ServiceHistoryView: View {
    @Environment(\.dismiss) var dismiss
    @State private var history: [Booking] = []
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

                Text("Service History")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.textForeground)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider().background(Color.borderSubtle)

            if isLoading {
                Spacer()
                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .primaryGold))
                Spacer()
            } else if history.isEmpty {
                Spacer()
                VStack(spacing: 14) {
                    Image(systemName: "clock.badge.checkmark")
                        .font(.system(size: 44))
                        .foregroundColor(.textSubtle)

                    Text("No past service records")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.textForeground)

                    Text("Completed maintenance, oil changes, and mechanical repairs will appear here with lifetime warranty details.")
                        .font(.system(size: 13))
                        .foregroundColor(.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(history) { booking in
                            NavigationLink(destination: BookingDetailView(bookingId: booking.id, bookingRef: booking.reference)) {
                                BookingCardView(booking: booking)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 36)
                }
                .refreshable {
                    await loadHistory()
                }
            }
        }
        .background(Color.bgDark.ignoresSafeArea())
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .hideBottomDockOnPush()
        .task {
            await loadHistory()
        }
    }

    private func loadHistory() async {
        isLoading = history.isEmpty
        if let response = try? await APIService.shared.getServiceHistory() {
            await MainActor.run {
                history = response.data?.items ?? []
                isLoading = false
            }
        } else {
            await MainActor.run { isLoading = false }
        }
    }
}
