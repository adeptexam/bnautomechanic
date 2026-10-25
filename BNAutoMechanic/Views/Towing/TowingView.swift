//
//  TowingView.swift
//  BNAutoMechanic
//
//  Pixel-perfect replica of Android ActivityTowing & ActivityTowingStatus
//

import SwiftUI

struct TowingView: View {
    @Environment(\.dismiss) var dismiss
    @State private var showBookingSheet = false

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

                Text("Roadside Assistance")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.textForeground)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider().background(Color.borderSubtle)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Emergency Hero Banner
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            Image(systemName: "truck.box.fill")
                                .font(.system(size: 26))
                                .foregroundColor(.primaryGold)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("24/7 EMERGENCY TOWING")
                                    .font(.system(size: 15, weight: .black))
                                    .foregroundColor(.primaryGold)
                                    .tracking(0.5)

                                Text("Fast dispatch across Ewing & Mercer County")
                                    .font(.system(size: 12))
                                    .foregroundColor(.textMuted)
                            }
                        }

                        Text("Stranded with a flat tire, engine fault, or accident? Our certified tow trucks and roadside recovery fleet are on call 24 hours a day, 7 days a week.")
                            .font(.system(size: 13))
                            .foregroundColor(.textForeground)
                            .lineSpacing(4)
                            .padding(.top, 4)
                    }
                    .padding(18)
                    .goldBorderCard()

                    // Action: Call Emergency Dispatch
                    Button(action: callEmergency) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.primaryGold)
                                    .frame(width: 38, height: 38)
                                Image(systemName: "phone.fill")
                                    .foregroundColor(.bgDark)
                                    .font(.system(size: 16, weight: .bold))
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Call Emergency Dispatch")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.primaryGold)
                                Text("(609) 555-0199  •  Immediate Response")
                                    .font(.system(size: 11))
                                    .foregroundColor(.textMuted)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.primaryGold)
                                .font(.system(size: 14, weight: .bold))
                        }
                        .padding(16)
                        .luxuryCard()
                    }

                    // Action: Request Towing Online
                    Button(action: { showBookingSheet = true }) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.cardDarkElevated)
                                    .frame(width: 38, height: 38)
                                Image(systemName: "wrench.and.screwdriver.fill")
                                    .foregroundColor(.primaryGold)
                                    .font(.system(size: 16))
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Request Towing & Repair Online")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.textForeground)
                                Text("Book flatbed transport directly to our workshop")
                                    .font(.system(size: 11))
                                    .foregroundColor(.textMuted)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.textSubtle)
                                .font(.system(size: 12))
                        }
                        .padding(16)
                        .luxuryCard()
                    }

                    // Action: View Active Status
                    NavigationLink(destination: TowingStatusView()) {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.cardDarkElevated)
                                    .frame(width: 38, height: 38)
                                Image(systemName: "clock.arrow.circlepath")
                                    .foregroundColor(.primaryGold)
                                    .font(.system(size: 16))
                            }

                            VStack(alignment: .leading, spacing: 2) {
                                Text("Active Towing Status")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.textForeground)
                                Text("Track arrival and dispatch updates")
                                    .font(.system(size: 11))
                                    .foregroundColor(.textMuted)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.textSubtle)
                                .font(.system(size: 12))
                        }
                        .padding(16)
                        .luxuryCard()
                    }

                    // Services Offered Card
                    VStack(alignment: .leading, spacing: 10) {
                        Text("ROADSIDE SERVICES INCLUDED")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.textSubtle)
                            .tracking(0.6)

                        Text("• Flatbed Vehicle Towing & Transport\n• Dead Battery Jump Starts\n• Emergency Tire Change & Air Refill\n• Lockout Assistance\n• Fuel Delivery\n• Winch & Off-Road Recovery")
                            .font(.system(size: 13))
                            .foregroundColor(.textForeground)
                            .lineSpacing(6)
                    }
                    .padding(16)
                    .luxuryCard()
                }
                .padding(16)
                .padding(.bottom, 36)
            }
        }
        .background(Color.bgDark.ignoresSafeArea())
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .hideBottomDockOnPush()
        .sheet(isPresented: $showBookingSheet) {
            BookAppointmentView(preselectedServiceId: 4)
        }
    }

    private func callEmergency() {
        if let url = URL(string: "tel:+16095550199") {
            #if os(iOS)
            UIApplication.shared.open(url)
            #endif
        }
    }
}

// MARK: - Towing Status View (Matching ActivityTowingStatus)
struct TowingStatusView: View {
    @Environment(\.dismiss) var dismiss
    @State private var towingList: [Booking] = []
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

                Text("Active Towing Status")
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
            } else if towingList.isEmpty {
                Spacer()
                VStack(spacing: 14) {
                    Image(systemName: "truck.box")
                        .font(.system(size: 44))
                        .foregroundColor(.textSubtle)

                    Text("No active towing requests")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.textForeground)

                    Text("When you request emergency roadside assistance or towing, live dispatch progress will appear here.")
                        .font(.system(size: 13))
                        .foregroundColor(.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(towingList) { booking in
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
                    await loadTowing()
                }
            }
        }
        .background(Color.bgDark.ignoresSafeArea())
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .hideBottomDockOnPush()
        .task {
            await loadTowing()
        }
    }

    private func loadTowing() async {
        isLoading = towingList.isEmpty
        if let response = try? await APIService.shared.getBookings(perPage: 50) {
            let all = response.data?.items ?? []
            let filtered = all.filter {
                $0.towing != nil || $0.servicesSummary().localizedCaseInsensitiveContains("Towing")
            }
            await MainActor.run {
                towingList = filtered
                isLoading = false
            }
        } else {
            await MainActor.run { isLoading = false }
        }
    }
}
