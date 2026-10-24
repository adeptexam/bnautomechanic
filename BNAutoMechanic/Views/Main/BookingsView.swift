//
//  BookingsView.swift
//  BNAutoMechanic
//

import SwiftUI

struct BookingsView: View {
    @State private var allBookings: [Booking] = []
    @State private var showActiveOnly = true
    @State private var isLoading = false

    private var displayedBookings: [Booking] {
        var list = showActiveOnly ? allBookings.filter { !$0.isClosed() } : allBookings
        // Fall back to all if active filter shows nothing
        if showActiveOnly && list.isEmpty && !allBookings.isEmpty {
            list = allBookings
        }
        return list
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("My Bookings")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.textForeground)
                Spacer()
                NavigationLink(destination: BookAppointmentView()) {
                    Label("New", systemImage: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.bgDark)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.primaryGold)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)

            // Filter Chips
            HStack(spacing: 8) {
                chipButton(label: "Active", isSelected: showActiveOnly) {
                    showActiveOnly = true
                }
                chipButton(label: "All Bookings", isSelected: !showActiveOnly) {
                    showActiveOnly = false
                }
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.bottom, 12)

            Divider().background(Color.borderSubtle)

            if isLoading {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .primaryGold))
                Spacer()
            } else if displayedBookings.isEmpty {
                Spacer()
                VStack(spacing: 14) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 40))
                        .foregroundColor(.textSubtle)
                    Text("No bookings yet")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.textMuted)
                    Text("Schedule your first service appointment")
                        .font(.system(size: 13))
                        .foregroundColor(.textSubtle)

                    NavigationLink(destination: BookAppointmentView()) {
                        Text("Book Now")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.bgDark)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Color.primaryGold)
                            .cornerRadius(10)
                    }
                    .padding(.top, 4)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(displayedBookings) { booking in
                            NavigationLink(destination: BookingDetailView(bookingId: booking.id, bookingRef: booking.reference)) {
                                BookingCardView(booking: booking)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .bottomDockClearance()
                }
                .refreshable {
                    await loadBookings()
                }
            }
        }
        .background(Color.bgDark.ignoresSafeArea())
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .task {
            await loadBookings()
        }
    }

    private func chipButton(label: String, isSelected: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Text(label)
                .font(.system(size: 12, weight: isSelected ? .bold : .medium))
                .foregroundColor(isSelected ? .bgDark : .textForeground)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(isSelected ? Color.primaryGold : Color.surfaceDark)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? Color.clear : Color.borderMedium, lineWidth: 1)
                )
        }
    }

    private func loadBookings() async {
        isLoading = allBookings.isEmpty
        if let response = try? await APIService.shared.getBookings(perPage: 50) {
            await MainActor.run {
                allBookings = response.data?.items ?? []
                isLoading = false
            }
        } else {
            await MainActor.run { isLoading = false }
        }
    }
}

// MARK: - Booking Card
struct BookingCardView: View {
    let booking: Booking

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Ref: \(booking.reference)")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.textMuted)
                Spacer()
                StatusBadge(status: booking.status)
            }

            Text(booking.servicesSummary())
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.textForeground)
                .lineLimit(2)

            HStack(spacing: 16) {
                Label(booking.vehicle?.displayName() ?? "Vehicle", systemImage: "car.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.textMuted)
                    .lineLimit(1)
            }

            HStack(spacing: 12) {
                Label(booking.scheduledDate, systemImage: "calendar")
                    .font(.system(size: 11))
                    .foregroundColor(.textMuted)

                Label(booking.scheduledTime, systemImage: "clock")
                    .font(.system(size: 11))
                    .foregroundColor(.textMuted)

                Spacer()

                if let amount = booking.totalAmount, amount > 0 {
                    Text("$\(String(format: "%.2f", amount))")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primaryGold)
                }
            }
        }
        .padding(14)
        .luxuryCard()
    }
}
