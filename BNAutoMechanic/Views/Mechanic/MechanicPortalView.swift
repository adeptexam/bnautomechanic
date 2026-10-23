//
//  MechanicPortalView.swift
//  BNAutoMechanic
//
//  Dedicated Technician / Bay Mechanic Portal.
//  Provides technicians with their active assigned service bay jobs,
//  an open jobs board to claim available tasks, and inspection status updates.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct MechanicPortalView: View {
    @EnvironmentObject var session: SessionManager

    @State private var profile: MechanicMe? = nil
    @State private var myJobs: [MechanicJob] = []
    @State private var availableJobs: [MechanicJob] = []
    @State private var selectedTab: Int = 0 // 0: My Bay Jobs, 1: Claim Available Jobs
    @State private var isLoading: Bool = false

    // Action State
    @State private var isActionRunning: Bool = false
    @State private var toastMessage: String = ""
    @State private var showToast: Bool = false
    @State private var errorMessage: String = ""
    @State private var showErrorAlert: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            mechanicHeader

            // Bay Segment Tabs
            segmentPicker

            // Main List
            if isLoading && myJobs.isEmpty && availableJobs.isEmpty {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .primaryGold))
                    .scaleEffect(1.2)
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        if selectedTab == 0 {
                            myJobsSection
                        } else {
                            availableJobsSection
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
                .refreshable {
                    await loadMechanicData()
                }
            }
        }
        .background(Color.bgDark.ignoresSafeArea())
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .task {
            await loadMechanicData()
        }
        .alert("Notice", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .overlay(alignment: .bottom) {
            if showToast {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.statusConfirmed)
                    Text(toastMessage)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.textForeground)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.cardDarkElevated)
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.primaryGold.opacity(0.5), lineWidth: 1))
                .padding(.bottom, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - Header
    private var mechanicHeader: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.primaryGold.opacity(0.2))
                    .frame(width: 44, height: 44)
                    .overlay(Circle().stroke(Color.primaryGold, lineWidth: 1.2))
                Image(systemName: "wrench.and.screwdriver.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.primaryGold)
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text("TECHNICIAN SERVICE BAY")
                        .font(.system(size: 14, weight: .black))
                        .foregroundColor(.primaryGold)
                        .tracking(1)

                    Text("ACTIVE")
                        .font(.system(size: 8, weight: .black))
                        .foregroundColor(.bgDark)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color.statusConfirmed)
                        .cornerRadius(4)
                }

                Text(profile?.name ?? session.currentUser?.name ?? "Technician")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.textForeground)

                Text(profile?.specialty ?? "Automotive Diagnostics Specialist")
                    .font(.system(size: 10))
                    .foregroundColor(.textMuted)
            }

            Spacer()
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }

    // MARK: - Segment Picker
    private var segmentPicker: some View {
        HStack(spacing: 8) {
            Button {
                triggerHaptic()
                withAnimation { selectedTab = 0 }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "car.2.fill")
                    Text("My Bay Jobs (\(myJobs.count))")
                        .font(.system(size: 11, weight: selectedTab == 0 ? .bold : .medium))
                }
                .foregroundColor(selectedTab == 0 ? .bgDark : .textForeground)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(selectedTab == 0 ? Color.primaryGold : Color.cardDarkElevated)
                .cornerRadius(8)
            }

            Button {
                triggerHaptic()
                withAnimation { selectedTab = 1 }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "hand.raised.fill")
                    Text("Claim Available (\(availableJobs.count))")
                        .font(.system(size: 11, weight: selectedTab == 1 ? .bold : .medium))
                }
                .foregroundColor(selectedTab == 1 ? .bgDark : .textForeground)
                .frame(maxWidth: .infinity)
                .frame(height: 34)
                .background(selectedTab == 1 ? Color.primaryGold : Color.cardDarkElevated)
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }

    // MARK: - My Jobs Section
    private var myJobsSection: some View {
        VStack(spacing: 12) {
            if myJobs.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.statusConfirmed)
                    Text("Bay is Currently Clear")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.textForeground)
                    Text("No jobs are assigned to your bay right now. Switch to 'Claim Available' to pick up an open appointment.")
                        .font(.system(size: 12))
                        .foregroundColor(.textMuted)
                        .multilineTextAlignment(.center)
                }
                .padding(28)
                .luxuryCard()
            } else {
                ForEach(myJobs) { job in
                    myJobCard(job)
                }
            }
        }
    }

    private func myJobCard(_ job: MechanicJob) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(job.reference)
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(.primaryGold)
                    Text(job.vehicle?.displayName() ?? "Registered Vehicle")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.textForeground)
                }
                Spacer()
                StatusBadge(status: job.status)
            }

            Divider().background(Color.borderSubtle)

            HStack {
                Label("\(job.scheduledDate) • \(job.scheduledTime)", systemImage: "clock.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.textMuted)

                Spacer()

                if let client = job.customerFirstName {
                    Label("Customer: \(client)", systemImage: "person.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.textMuted)
                }
            }

            if let svcs = job.services, !svcs.isEmpty {
                Text("Services: \(svcs.joined(separator: ", "))")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.textForeground)
            }

            if let notes = job.notes, !notes.isEmpty {
                Text("Inspection Notes: \(notes)")
                    .font(.system(size: 11))
                    .foregroundColor(.textMuted)
            }

            // Status Actions for Mechanic
            HStack(spacing: 8) {
                if job.status.uppercased() != "IN_PROGRESS" && job.status.uppercased() != "COMPLETED" {
                    Button {
                        triggerHaptic()
                        Task { await updateStatus(id: job.id, status: "IN_PROGRESS") }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "play.fill")
                            Text("START SERVICE")
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.bgDark)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(Color.primaryGold)
                        .cornerRadius(6)
                    }
                }

                if job.status.uppercased() == "IN_PROGRESS" {
                    Button {
                        triggerHaptic()
                        Task { await updateStatus(id: job.id, status: "COMPLETED") }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("MARK COMPLETED")
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.bgDark)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(Color.statusConfirmed)
                        .cornerRadius(6)
                    }
                }
            }
            .padding(.top, 4)
        }
        .padding(14)
        .luxuryCard()
    }

    // MARK: - Available Jobs Section
    private var availableJobsSection: some View {
        VStack(spacing: 12) {
            if availableJobs.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "tray.fill")
                        .font(.system(size: 34))
                        .foregroundColor(.textSubtle)
                    Text("No Open Jobs Available")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.textForeground)
                    Text("All appointments are currently claimed or assigned.")
                        .font(.system(size: 11))
                        .foregroundColor(.textMuted)
                }
                .padding(24)
                .luxuryCard()
            } else {
                ForEach(availableJobs) { job in
                    VStack(alignment: .leading, spacing: 10) {
                        HStack {
                            Text(job.reference)
                                .font(.system(size: 13, weight: .black))
                                .foregroundColor(.primaryGold)
                            Spacer()
                            Text("OPEN FOR CLAIM")
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(.bgDark)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.statusConfirmed)
                                .cornerRadius(4)
                        }

                        Text(job.vehicle?.displayName() ?? "Vehicle")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.textForeground)

                        Text("Scheduled: \(job.scheduledDate) at \(job.scheduledTime)")
                            .font(.system(size: 11))
                            .foregroundColor(.textMuted)

                        if let svcs = job.services, !svcs.isEmpty {
                            Text("Services: \(svcs.joined(separator: ", "))")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.textForeground)
                        }

                        Button {
                            triggerHaptic()
                            Task { await claimJob(id: job.id) }
                        } label: {
                            HStack {
                                Image(systemName: "hand.raised.fill")
                                Text("CLAIM THIS JOB TO MY BAY")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundColor(.bgDark)
                            .frame(maxWidth: .infinity)
                            .frame(height: 36)
                            .background(Color.primaryGold)
                            .cornerRadius(6)
                        }
                    }
                    .padding(14)
                    .luxuryCard()
                }
            }
        }
    }

    // MARK: - API Calls
    private func loadMechanicData() async {
        isLoading = true
        let api = APIService.shared

        if let mResp = try? await api.getMechanicMe() {
            await MainActor.run { profile = mResp.data }
        }

        if let jResp = try? await api.getMechanicJobs() {
            await MainActor.run { myJobs = jResp.data ?? [] }
        }

        if let aResp = try? await api.getMechanicAvailableJobs() {
            await MainActor.run { availableJobs = aResp.data ?? [] }
        }

        await MainActor.run { isLoading = false }
    }

    private func claimJob(id: Int) async {
        let api = APIService.shared
        do {
            _ = try await api.claimMechanicJob(id: id)
            await MainActor.run {
                toastMessage = "Job claimed to your bay!"
                withAnimation { showToast = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation { showToast = false }
                }
            }
            await loadMechanicData()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }

    private func updateStatus(id: Int, status: String) async {
        let api = APIService.shared
        do {
            _ = try await api.updateMechanicJobStatus(id: id, status: status)
            await MainActor.run {
                toastMessage = "Status updated to \(status)!"
                withAnimation { showToast = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation { showToast = false }
                }
            }
            await loadMechanicData()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }

    private func triggerHaptic() {
        #if os(iOS)
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.prepare()
        impact.impactOccurred()
        #endif
    }
}
