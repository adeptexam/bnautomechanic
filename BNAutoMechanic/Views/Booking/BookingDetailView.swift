//
//  BookingDetailView.swift
//  BNAutoMechanic
//
//  Pixel-perfect replica of Android BookingDetailActivity
//

import SwiftUI

struct BookingDetailView: View {
    let bookingId: Int
    var bookingRef: String? = nil
    @Environment(\.dismiss) var dismiss

    @State private var booking: Booking?
    @State private var isLoading = false
    @State private var showRescheduleSheet = false
    @State private var showCancelAlert = false
    @State private var showDeclineEstimateSheet = false
    @State private var declineReason = ""
    @State private var newScheduledDate = Date()
    @State private var newScheduledTime = "10:00 AM"
    @State private var actionMessage = ""

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

                VStack(alignment: .leading, spacing: 2) {
                    Text("Service Visit")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.textForeground)

                    Text(booking?.reference ?? bookingRef ?? "Ref: ...")
                        .font(.system(size: 11))
                        .foregroundColor(.primaryGold)
                }

                Spacer()

                if let b = booking {
                    StatusBadge(status: b.status)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider().background(Color.borderSubtle)

            if isLoading && booking == nil {
                Spacer()
                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .primaryGold))
                Spacer()
            } else if let b = booking {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        // Vehicle & Schedule Hero
                        heroCard(b)

                        // Services List
                        servicesCard(b)

                        // Estimate Section (if present)
                        if let est = b.estimate {
                            estimateCard(est, booking: b)
                        }

                        // Financial Billing Breakdown
                        billingCard(b)

                        // Action Buttons: Reschedule & Cancel
                        if b.canCancel() || b.canReschedule() {
                            actionsSection(b)
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 24)
                }
                .refreshable {
                    await loadDetails()
                }
            } else {
                Spacer()
                Text("Unable to load booking details.")
                    .foregroundColor(.textMuted)
                Spacer()
            }
        }
        .background(Color.bgDark.ignoresSafeArea())
        .navigationBarHidden(true)
        .task {
            await loadDetails()
        }
        .sheet(isPresented: $showRescheduleSheet) {
            rescheduleSheet
        }
        .sheet(isPresented: $showDeclineEstimateSheet) {
            declineEstimateSheet
        }
        .alert("Cancel Appointment", isPresented: $showCancelAlert) {
            Button("Cancel Appointment", role: .destructive) {
                cancelBooking()
            }
            Button("Keep Visit", role: .cancel) {}
        } message: {
            Text("Are you sure you want to cancel this service visit? Technicians scheduled will be released.")
        }
    }

    // MARK: - Hero Card
    private func heroCard(_ b: Booking) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("APPOINTMENT SCHEDULE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.primaryGold)
                    Text("\(b.scheduledDate) at \(b.scheduledTime)")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.textForeground)
                }
                Spacer()
                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 24))
                    .foregroundColor(.primaryGold)
            }

            Divider().background(Color.borderSubtle)

            HStack(spacing: 12) {
                Image(systemName: "car.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.primaryGold)

                VStack(alignment: .leading, spacing: 2) {
                    Text(b.vehicle?.displayName() ?? "Customer Vehicle")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.textForeground)
                    if let plate = b.vehicle?.registrationNumber, !plate.isEmpty {
                        Text("Plate: \(plate)")
                            .font(.system(size: 11))
                            .foregroundColor(.textMuted)
                    }
                }
                Spacer()
            }
        }
        .padding(16)
        .luxuryCard()
    }

    // MARK: - Services Card
    private func servicesCard(_ b: Booking) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("PROCEDURES & SERVICES")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.textSubtle)
                .tracking(0.5)

            let servicesList = b.services ?? []
            if servicesList.isEmpty {
                Text(b.servicesSummary())
                    .font(.system(size: 13))
                    .foregroundColor(.textForeground)
            } else {
                ForEach(servicesList) { s in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(s.serviceName)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.textForeground)
                            Text("\(s.durationMinutes ?? 45) mins standard labor")
                                .font(.system(size: 11))
                                .foregroundColor(.textMuted)
                        }
                        Spacer()
                        Text(String(format: "$%.2f", s.price ?? 49.00))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primaryGold)
                    }
                    if s.id != servicesList.last?.id {
                        Divider().background(Color.borderSubtle)
                    }
                }
            }
        }
        .padding(16)
        .luxuryCard()
    }

    // MARK: - Estimate Card
    private func estimateCard(_ est: Estimate, booking: Booking) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text("ESTIMATE QUOTATION")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.primaryGold)
                    Text("Parts & Diagnostic Quote")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.textForeground)
                }
                Spacer()
                Text(est.status ?? "PENDING")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(est.status == "PENDING" ? .statusPending : .statusCompleted)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.cardDarkElevated)
                    .cornerRadius(6)
            }

            if let notes = est.notes, !notes.isEmpty {
                Text(notes)
                    .font(.system(size: 12))
                    .foregroundColor(.textMuted)
                    .padding(10)
                    .background(Color.surfaceDark)
                    .cornerRadius(8)
            }

            HStack {
                Text("Quoted Estimate Total:")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.textForeground)
                Spacer()
                Text(String(format: "$%.2f", est.total ?? 0.0))
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(.primaryGold)
            }

            if (est.status ?? "") == "PENDING" || booking.status == "ESTIMATE_SENT" {
                HStack(spacing: 10) {
                    Button(action: { showDeclineEstimateSheet = true }) {
                        Text("Decline Quote")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.statusCancelled)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.statusCancelled, lineWidth: 1)
                            )
                    }

                    Button(action: approveEstimate) {
                        Text("Approve Estimate")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.bgDark)
                            .frame(maxWidth: .infinity)
                            .frame(height: 40)
                            .background(Color.primaryGold)
                            .cornerRadius(8)
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .goldBorderCard()
    }

    // MARK: - Billing Card
    private func billingCard(_ b: Booking) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("BILLING & PAYMENT SUMMARY")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.textSubtle)
                .tracking(0.5)

            HStack {
                Text("Total Service Amount")
                    .font(.system(size: 13))
                    .foregroundColor(.textMuted)
                Spacer()
                Text(String(format: "$%.2f", b.totalAmount ?? 0.0))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.textForeground)
            }

            HStack {
                Text("Amount Paid")
                    .font(.system(size: 13))
                    .foregroundColor(.textMuted)
                Spacer()
                Text(String(format: "$%.2f", b.amountPaid ?? 0.0))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.statusCompleted)
            }

            Divider().background(Color.borderSubtle)

            HStack {
                Text("Balance Due")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.textForeground)
                Spacer()
                Text(String(format: "$%.2f", b.balanceDue ?? (b.totalAmount ?? 0.0)))
                    .font(.system(size: 16, weight: .black))
                    .foregroundColor(.primaryGold)
            }
        }
        .padding(16)
        .luxuryCard()
    }

    // MARK: - Action Buttons
    private func actionsSection(_ b: Booking) -> some View {
        VStack(spacing: 10) {
            if b.canReschedule() {
                Button(action: { showRescheduleSheet = true }) {
                    Label("Reschedule Appointment", systemImage: "arrow.triangle.2.circlepath")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primaryGold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.primaryGold, lineWidth: 1)
                        )
                }
            }

            if b.canCancel() {
                Button(action: { showCancelAlert = true }) {
                    Label("Cancel Appointment", systemImage: "xmark.circle")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.statusCancelled)
                        .frame(maxWidth: .infinity)
                        .frame(height: 46)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.borderSubtle, lineWidth: 1)
                        )
                }
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Reschedule Sheet
    private var rescheduleSheet: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Reschedule Appointment")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.textForeground)
                    .padding(.top, 16)

                DatePicker("Select Date", selection: $newScheduledDate, in: Date()..., displayedComponents: .date)
                    .datePickerStyle(.graphical)
                    .accentColor(.primaryGold)
                    .padding(10)
                    .luxuryCard()
                    .padding(.horizontal, 16)

                // Time Slot
                HStack(spacing: 8) {
                    ForEach(["8:00 AM", "10:00 AM", "1:00 PM", "3:00 PM"], id: \.self) { slot in
                        Button(action: { newScheduledTime = slot }) {
                            Text(slot)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(newScheduledTime == slot ? .bgDark : .textForeground)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 8)
                                .background(newScheduledTime == slot ? Color.primaryGold : Color.cardDark)
                                .cornerRadius(6)
                        }
                    }
                }

                Spacer()

                Button(action: confirmReschedule) {
                    Text("Confirm Reschedule")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.bgDark)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.primaryGold)
                        .cornerRadius(10)
                }
                .padding(16)
            }
            .background(Color.bgDark.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showRescheduleSheet = false }
                        .foregroundColor(.textMuted)
                }
            }
        }
    }

    // MARK: - Decline Estimate Sheet
    private var declineEstimateSheet: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Decline Estimate Quote")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.textForeground)
                    .padding(.top, 16)

                Text("Please provide an optional reason for the service advisor:")
                    .font(.system(size: 13))
                    .foregroundColor(.textMuted)

                TextField("Reason for declining quote (optional)", text: $declineReason)
                    .textFieldStyle(DarkInputFieldStyle())

                Spacer()

                Button(action: confirmDeclineEstimate) {
                    Text("Decline Quote")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(Color.statusCancelled)
                        .cornerRadius(10)
                }
                .padding(.bottom, 16)
            }
            .padding(16)
            .background(Color.bgDark.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showDeclineEstimateSheet = false }
                        .foregroundColor(.textMuted)
                }
            }
        }
    }

    // MARK: - API Calls
    private func loadDetails() async {
        isLoading = true
        if let response = try? await APIService.shared.getBookingDetail(id: bookingId) {
            await MainActor.run {
                booking = response.data
                isLoading = false
            }
        } else {
            await MainActor.run { isLoading = false }
        }
    }

    private func approveEstimate() {
        Task {
            _ = try? await APIService.shared.approveEstimate(id: bookingId)
            await loadDetails()
        }
    }

    private func confirmDeclineEstimate() {
        showDeclineEstimateSheet = false
        Task {
            _ = try? await APIService.shared.rejectEstimate(id: bookingId, reason: declineReason)
            await loadDetails()
        }
    }

    private func confirmReschedule() {
        showRescheduleSheet = false
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateStr = formatter.string(from: newScheduledDate)

        Task {
            _ = try? await APIService.shared.rescheduleBooking(id: bookingId, date: dateStr, time: newScheduledTime)
            await loadDetails()
        }
    }

    private func cancelBooking() {
        Task {
            _ = try? await APIService.shared.cancelBooking(id: bookingId, reason: "Customer requested cancellation")
            await loadDetails()
        }
    }
}
