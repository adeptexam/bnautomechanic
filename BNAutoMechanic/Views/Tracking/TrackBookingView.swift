//
//  TrackBookingView.swift
//  BNAutoMechanic
//
//  Pixel-perfect replica of Android ActivityTrackBooking
//

import SwiftUI

struct TrackBookingView: View {
    @Environment(\.dismiss) var dismiss
    @State private var reference = ""
    @State private var phone = ""
    @State private var isSearching = false
    @State private var searchResult: BookingTrack?
    @State private var errorMessage = ""

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

                Text("Track Visit Status")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.textForeground)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider().background(Color.borderSubtle)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Search Card
                    VStack(alignment: .leading, spacing: 16) {
                        Text("LOOKUP WORKSHOP VISIT")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.primaryGold)
                            .tracking(0.6)

                        Text("Enter your booking reference code and the phone number provided at scheduling.")
                            .font(.system(size: 13))
                            .foregroundColor(.textMuted)

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Booking Reference")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.textForeground)
                            TextField("e.g. BN-2023-0814", text: $reference)
                                .textFieldStyle(DarkInputFieldStyle())
                                #if os(iOS)
                                .textInputAutocapitalization(.characters)
                                #endif
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Contact Phone Number")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.textForeground)
                            TextField("e.g. (609) 555-0199", text: $phone)
                                .textFieldStyle(DarkInputFieldStyle())
                                .keyboardType(.phonePad)
                        }

                        if !errorMessage.isEmpty {
                            Text(errorMessage)
                                .font(.system(size: 12))
                                .foregroundColor(.statusCancelled)
                        }

                        Button(action: performTrack) {
                            if isSearching {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .bgDark))
                            } else {
                                Text("Track Visit Status")
                            }
                        }
                        .buttonStyle(GoldButtonStyle(isEnabled: !reference.trimmingCharacters(in: .whitespaces).isEmpty && !phone.trimmingCharacters(in: .whitespaces).isEmpty && !isSearching))
                        .disabled(reference.trimmingCharacters(in: .whitespaces).isEmpty || phone.trimmingCharacters(in: .whitespaces).isEmpty || isSearching)
                    }
                    .padding(18)
                    .luxuryCard()

                    // Result Card (Matching activity_track_booking result layout)
                    if let track = searchResult {
                        VStack(alignment: .leading, spacing: 14) {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Ref: \(track.reference ?? "Unknown")")
                                        .font(.system(size: 15, weight: .bold))
                                        .foregroundColor(.textForeground)
                                    Text(track.vehicleSummary ?? "Customer Vehicle")
                                        .font(.system(size: 12))
                                        .foregroundColor(.textMuted)
                                }
                                Spacer()
                                StatusBadge(status: track.status ?? "PENDING")
                            }

                            Divider().background(Color.borderSubtle)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("CURRENT WORKSHOP PROGRESS")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.primaryGold)
                                    .tracking(0.5)

                                Text(statusDescription(for: track.status ?? "PENDING"))
                                    .font(.system(size: 13))
                                    .foregroundColor(.textForeground)
                                    .lineSpacing(4)
                            }

                            if let tech = track.technicianName {
                                HStack(spacing: 8) {
                                    Image(systemName: "person.badge.shield.checkmark.fill")
                                        .foregroundColor(.primaryGold)
                                    Text("Lead Mechanic: \(tech)")
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.textMuted)
                                }
                                .padding(.top, 4)
                            }
                        }
                        .padding(18)
                        .goldBorderCard()
                    }
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
    }

    private func performTrack() {
        let trimmedRef = reference.trimmingCharacters(in: .whitespaces)
        let trimmedPhone = phone.trimmingCharacters(in: .whitespaces)
        guard !trimmedRef.isEmpty && !trimmedPhone.isEmpty else { return }

        isSearching = true
        errorMessage = ""
        searchResult = nil

        Task {
            do {
                let response = try await APIService.shared.trackBooking(reference: trimmedRef, phone: trimmedPhone)
                await MainActor.run {
                    isSearching = false
                    if let data = response.data {
                        searchResult = data
                    } else {
                        errorMessage = response.message ?? "No active service record found for this reference and phone number."
                    }
                }
            } catch {
                await MainActor.run {
                    isSearching = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func statusDescription(for status: String) -> String {
        switch status.uppercased() {
        case "PENDING":
            return "Service appointment received. Advisor review and bay allocation pending."
        case "CONFIRMED":
            return "Appointment confirmed. Dedicated workshop bay reserved for your scheduled arrival."
        case "IN_PROGRESS", "IN_BAY":
            return "Vehicle actively in bay. Certified technicians are performing scheduled mechanical procedures and multi-point inspection."
        case "ESTIMATE_SENT":
            return "Inspection completed. An estimate quotation for necessary parts and labor is awaiting your approval."
        case "COMPLETED", "READY_FOR_PICKUP":
            return "All services and test drives successfully completed. Your vehicle is washed and ready for pick-up."
        case "CANCELLED":
            return "This appointment visit has been cancelled."
        default:
            return "Vehicle under master technician supervision."
        }
    }
}
