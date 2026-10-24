//
//  StaffDispatcherAdminView.swift
//  BNAutoMechanic
//
//  Workshop Staff Dispatcher & Bay Assignment Hub.
//  Enables Superadmin & Admin to dispatch mechanics, assign active bookings,
//  monitor technician bay workload, and manage technician profiles (Full CRUD).
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct StaffDispatcherAdminView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var session: SessionManager

    // Mechanics & Bookings Data
    @State private var mechanics: [Mechanic] = []
    @State private var unassignedBookings: [Booking] = []
    @State private var allBookings: [Booking] = []
    @State private var isLoading: Bool = false
    @State private var isActionRunning: Bool = false

    // Dispatch Action State
    @State private var selectedBookingForDispatch: Booking? = nil
    @State private var selectedMechanicId: Int? = nil
    @State private var showDispatchSheet: Bool = false

    // Mechanic CRUD State
    @State private var showAddMechanicSheet: Bool = false
    @State private var mechanicToEdit: Mechanic? = nil
    @State private var mechanicToDelete: Mechanic? = nil
    @State private var showDeleteConfirm: Bool = false

    // Alerts & Notifications
    @State private var toastMessage: String = ""
    @State private var showToast: Bool = false
    @State private var errorMessage: String = ""
    @State private var showErrorAlert: Bool = false

    // Tab Filter
    @State private var selectedTab: Int = 0 // 0: Dispatch Queue, 1: Mechanics Bay Roster

    var body: some View {
        VStack(spacing: 0) {
            // Header
            dispatcherHeader

            // Top Tab Selector
            tabSelector

            // Main Content Area
            if isLoading && mechanics.isEmpty && unassignedBookings.isEmpty {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .primaryGold))
                    .scaleEffect(1.2)
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        if selectedTab == 0 {
                            // Queue of Bookings waiting for Technician Dispatch
                            dispatchQueueSection
                        } else {
                            // Workshop Technicians Roster with Workloads & CRUD
                            mechanicsRosterSection
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 14)
                    .padding(.bottom, 28)
                }
                .refreshable {
                    await loadDispatcherData()
                }
            }
        }
        .background(Color.bgDark.ignoresSafeArea())
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .task {
            await loadDispatcherData()
        }
        .sheet(isPresented: $showDispatchSheet) {
            dispatchModalSheet
        }
        .sheet(isPresented: $showAddMechanicSheet) {
            AddOrEditMechanicSheet(mechanic: nil) {
                Task { await loadDispatcherData() }
            }
        }
        .sheet(item: $mechanicToEdit) { mech in
            AddOrEditMechanicSheet(mechanic: mech) {
                Task { await loadDispatcherData() }
            }
        }
        .alert("Delete Technician", isPresented: $showDeleteConfirm) {
            Button("Delete", role: .destructive) {
                if let m = mechanicToDelete {
                    Task { await deleteMechanic(id: m.id) }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to remove \(mechanicToDelete?.name ?? "this technician") from the workshop roster?")
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .overlay(alignment: .bottom) {
            if showToast {
                toastView
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .padding(.bottom, 20)
            }
        }
    }

    // MARK: - Header
    private var dispatcherHeader: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primaryGold)
                    .frame(width: 36, height: 36)
                    .background(Color.cardDarkElevated)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.borderSubtle, lineWidth: 1)
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 8) {
                    Text("STAFF DISPATCHER")
                        .font(.system(size: 18, weight: .black))
                        .foregroundColor(.primaryGold)
                        .tracking(1)

                    Text("LIVE")
                        .font(.system(size: 9, weight: .black))
                        .foregroundColor(.bgDark)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.statusConfirmed)
                        .cornerRadius(4)
                }
                Text("Technician Bay Allocation & Workload Manager")
                    .font(.system(size: 11))
                    .foregroundColor(.textMuted)
            }

            Spacer()

            Button {
                triggerHaptic()
                showAddMechanicSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 12, weight: .bold))
                    Text("Add Staff")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(.bgDark)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.primaryGold)
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
    }

    // MARK: - Tab Selector
    private var tabSelector: some View {
        HStack(spacing: 0) {
            Button {
                triggerHaptic()
                withAnimation { selectedTab = 0 }
            } label: {
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.triangle.pull")
                        Text("Dispatch Queue (\(unassignedBookings.count))")
                            .font(.system(size: 12, weight: selectedTab == 0 ? .bold : .medium))
                    }
                    .foregroundColor(selectedTab == 0 ? .primaryGold : .textMuted)

                    Rectangle()
                        .fill(selectedTab == 0 ? Color.primaryGold : Color.clear)
                        .frame(height: 2)
                }
            }

            Button {
                triggerHaptic()
                withAnimation { selectedTab = 1 }
            } label: {
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "wrench.and.screwdriver.fill")
                        Text("Technicians Roster (\(mechanics.count))")
                            .font(.system(size: 12, weight: selectedTab == 1 ? .bold : .medium))
                    }
                    .foregroundColor(selectedTab == 1 ? .primaryGold : .textMuted)

                    Rectangle()
                        .fill(selectedTab == 1 ? Color.primaryGold : Color.clear)
                        .frame(height: 2)
                }
            }
        }
        .padding(.horizontal, 16)
        .background(Color.bgDark)
    }

    // MARK: - Dispatch Queue Section
    private var dispatchQueueSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Visits Waiting for Technician")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.textForeground)
                Spacer()
                Text("\(unassignedBookings.count) Unassigned")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.primaryGold)
            }

            if unassignedBookings.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 36))
                        .foregroundColor(.statusConfirmed)
                    Text("All Appointments Dispatched")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.textForeground)
                    Text("Every active visit has been assigned to a workshop mechanic bay.")
                        .font(.system(size: 12))
                        .foregroundColor(.textMuted)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(28)
                .luxuryCard()
            } else {
                ForEach(unassignedBookings) { booking in
                    unassignedBookingCard(booking)
                }
            }

            // Also show active in-service visits for re-dispatch
            let activeAssigned = allBookings.filter { $0.mechanicId != nil && !$0.isClosed() }
            if !activeAssigned.isEmpty {
                HStack {
                    Text("Currently Assigned & In Bay")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.textForeground)
                    Spacer()
                    Text("\(activeAssigned.count) Visits")
                        .font(.system(size: 11))
                        .foregroundColor(.textMuted)
                }
                .padding(.top, 12)

                ForEach(activeAssigned) { booking in
                    assignedBookingCard(booking)
                }
            }
        }
    }

    // MARK: - Unassigned Booking Card
    private func unassignedBookingCard(_ b: Booking) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(b.reference)
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(.primaryGold)
                    Text(b.customerName ?? "Customer Visit")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.textForeground)
                }
                Spacer()
                StatusBadge(status: b.status)
            }

            Divider().background(Color.borderSubtle)

            HStack(spacing: 12) {
                Label(b.scheduledDate + " • " + b.scheduledTime, systemImage: "clock.fill")
                    .font(.system(size: 11))
                    .foregroundColor(.textMuted)

                if let vehicle = b.vehicle {
                    Label(vehicle.displayName(), systemImage: "car.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.textMuted)
                }
            }

            Text("Requested Services: \(b.servicesSummary())")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.textForeground)

            // Dispatch Button
            Button {
                triggerHaptic()
                selectedBookingForDispatch = b
                selectedMechanicId = nil
                showDispatchSheet = true
            } label: {
                HStack {
                    Image(systemName: "person.crop.circle.badge.plus")
                    Text("DISPATCH TECHNICIAN NOW")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.bgDark)
                .frame(maxWidth: .infinity)
                .frame(height: 38)
                .background(Color.primaryGold)
                .cornerRadius(8)
            }
            .padding(.top, 4)
        }
        .padding(14)
        .luxuryCard()
    }

    // MARK: - Assigned Booking Card
    private func assignedBookingCard(_ b: Booking) -> some View {
        let assignedMech = mechanics.first(where: { $0.id == b.mechanicId })

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(b.reference)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.textForeground)
                    Text(b.vehicle?.displayName() ?? "Vehicle")
                        .font(.system(size: 11))
                        .foregroundColor(.textMuted)
                }
                Spacer()
                StatusBadge(status: b.status)
            }

            HStack(spacing: 8) {
                Image(systemName: "wrench.and.screwdriver.fill")
                    .foregroundColor(.primaryGold)
                    .font(.system(size: 11))
                Text("Assigned to: ")
                    .font(.system(size: 11))
                    .foregroundColor(.textMuted)
                Text(assignedMech?.name ?? "Technician #\(b.mechanicId ?? 0)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.primaryGold)

                Spacer()

                Button("Reassign") {
                    triggerHaptic()
                    selectedBookingForDispatch = b
                    selectedMechanicId = b.mechanicId
                    showDispatchSheet = true
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.primaryGold)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .overlay(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(Color.primaryGold, lineWidth: 1)
                )
            }
        }
        .padding(12)
        .luxuryCard()
    }

    // MARK: - Mechanics Bay Roster Section
    private var mechanicsRosterSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Workshop Technicians & Bays")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.textForeground)
                Spacer()
                Text("\(mechanics.count) Active Staff")
                    .font(.system(size: 11))
                    .foregroundColor(.textMuted)
            }

            if mechanics.isEmpty {
                VStack(spacing: 10) {
                    Image(systemName: "person.2.slash")
                        .font(.system(size: 34))
                        .foregroundColor(.textSubtle)
                    Text("No mechanics registered")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.textForeground)
                    Button("Add First Technician") {
                        showAddMechanicSheet = true
                    }
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.bgDark)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.primaryGold)
                    .cornerRadius(8)
                }
                .frame(maxWidth: .infinity)
                .padding(24)
                .luxuryCard()
            } else {
                ForEach(mechanics) { mech in
                    mechanicRosterCard(mech)
                }
            }
        }
    }

    // MARK: - Mechanic Roster Card
    private func mechanicRosterCard(_ mech: Mechanic) -> some View {
        let activeJobsCount = allBookings.filter { $0.mechanicId == mech.id && !$0.isClosed() }.count
        let isAvailable = activeJobsCount == 0

        return VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(Color.primaryGold.opacity(0.15))
                        .frame(width: 46, height: 46)
                        .overlay(Circle().stroke(Color.primaryGold, lineWidth: 1.2))
                    Image(systemName: "wrench.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.primaryGold)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(mech.name)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.textForeground)

                        Spacer()

                        // Availability Badge
                        Text(isAvailable ? "AVAILABLE" : "\(activeJobsCount) IN BAY")
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(isAvailable ? .statusConfirmed : .primaryGold)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(isAvailable ? Color.statusConfirmed.opacity(0.14) : Color.primaryGold.opacity(0.14))
                            .cornerRadius(6)
                    }

                    Text(mech.specialization ?? "General Master Technician")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.primaryGold)

                    if let phone = mech.phone, !phone.isEmpty {
                        Label(phone, systemImage: "phone.fill")
                            .font(.system(size: 10))
                            .foregroundColor(.textMuted)
                    }
                }
            }

            Divider().background(Color.borderSubtle)

            // Hours & Experience
            HStack(spacing: 16) {
                Label("\(mech.experienceYears ?? 5)+ Years Experience", systemImage: "rosette")
                    .font(.system(size: 11))
                    .foregroundColor(.textMuted)

                Spacer()

                if let hours = mech.workingHours, !hours.isEmpty {
                    Label(hours, systemImage: "clock")
                        .font(.system(size: 11))
                        .foregroundColor(.textMuted)
                }
            }

            // Quick Actions: Edit, Delete
            HStack(spacing: 10) {
                Button {
                    triggerHaptic()
                    mechanicToEdit = mech
                } label: {
                    Label("Edit Profile", systemImage: "pencil")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.textForeground)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(Color.cardDarkElevated)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.borderSubtle, lineWidth: 1)
                        )
                }

                Button {
                    triggerHaptic()
                    mechanicToDelete = mech
                    showDeleteConfirm = true
                } label: {
                    Label("Remove", systemImage: "trash")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.statusCancelled)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(Color.statusCancelled.opacity(0.1))
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.statusCancelled.opacity(0.4), lineWidth: 1)
                        )
                }
            }
        }
        .padding(14)
        .luxuryCard()
    }

    // MARK: - Dispatch Modal Sheet
    private var dispatchModalSheet: some View {
        NavigationStack {
            VStack(spacing: 18) {
                if let b = selectedBookingForDispatch {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Dispatching Booking: \(b.reference)")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.textForeground)

                        Text("Customer: \(b.customerName ?? "Customer") • Vehicle: \(b.vehicle?.displayName() ?? "Registered Vehicle")")
                            .font(.system(size: 12))
                            .foregroundColor(.textMuted)

                        Text("Scheduled: \(b.scheduledDate) at \(b.scheduledTime)")
                            .font(.system(size: 12))
                            .foregroundColor(.primaryGold)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(14)
                    .luxuryCard()

                    Text("SELECT TECHNICIAN TO ASSIGN")
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.primaryGold)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    ScrollView {
                        VStack(spacing: 8) {
                            ForEach(mechanics) { mech in
                                let isSelected = selectedMechanicId == mech.id
                                let activeCount = allBookings.filter { $0.mechanicId == mech.id && !$0.isClosed() }.count

                                Button {
                                    triggerHaptic()
                                    selectedMechanicId = mech.id
                                } label: {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 3) {
                                            Text(mech.name)
                                                .font(.system(size: 14, weight: .bold))
                                                .foregroundColor(isSelected ? .primaryGold : .textForeground)
                                            Text(mech.specialization ?? "General Automotive")
                                                .font(.system(size: 11))
                                                .foregroundColor(.textMuted)
                                        }

                                        Spacer()

                                        Text(activeCount == 0 ? "AVAILABLE" : "\(activeCount) ACTIVE")
                                            .font(.system(size: 9, weight: .black))
                                            .foregroundColor(activeCount == 0 ? .statusConfirmed : .primaryGold)
                                            .padding(.horizontal, 6)
                                            .padding(.vertical, 2)
                                            .background(activeCount == 0 ? Color.statusConfirmed.opacity(0.15) : Color.primaryGold.opacity(0.15))
                                            .cornerRadius(4)

                                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                            .foregroundColor(isSelected ? .primaryGold : .textSubtle)
                                            .font(.system(size: 18))
                                    }
                                    .padding(12)
                                    .background(isSelected ? Color.primaryGold.opacity(0.1) : Color.cardDarkElevated)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(isSelected ? Color.primaryGold : Color.borderSubtle, lineWidth: 1.2)
                                    )
                                }
                            }
                        }
                    }

                    Button {
                        triggerHaptic()
                        Task { await executeDispatch() }
                    } label: {
                        HStack(spacing: 8) {
                            if isActionRunning {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .bgDark))
                            } else {
                                Image(systemName: "checkmark.circle.fill")
                            }
                            Text(isActionRunning ? "Dispatching..." : "CONFIRM ASSIGNMENT")
                                .font(.system(size: 13, weight: .black))
                        }
                        .foregroundColor(.bgDark)
                        .frame(maxWidth: .infinity)
                        .frame(height: 48)
                        .background(selectedMechanicId != nil ? Color.primaryGold : Color.borderMedium)
                        .cornerRadius(10)
                    }
                    .disabled(selectedMechanicId == nil || isActionRunning)
                }
            }
            .padding(16)
            .background(Color.bgDark.ignoresSafeArea())
            .navigationTitle("Staff Dispatch")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showDispatchSheet = false }
                        .foregroundColor(.primaryGold)
                }
            }
            #endif
        }
    }

    // MARK: - Toast View
    private var toastView: some View {
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
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(Color.primaryGold.opacity(0.5), lineWidth: 1)
        )
        .shadow(color: Color.black.opacity(0.6), radius: 10)
    }

    // MARK: - Backend Dispatch API
    private func loadDispatcherData() async {
        isLoading = true
        let api = APIService.shared

        // Fetch Mechanics
        if let resp = try? await api.getAdminMechanics() {
            await MainActor.run {
                mechanics = resp.data?.items ?? []
            }
        }

        // Fetch Bookings
        if let bResp = try? await api.getAdminBookings(perPage: 100) {
            let items = bResp.data?.items ?? []
            await MainActor.run {
                allBookings = items
                unassignedBookings = items.filter { ($0.mechanicId == nil || $0.mechanicId == 0) && !$0.isClosed() }
                isLoading = false
            }
        } else {
            await MainActor.run { isLoading = false }
        }
    }

    private func executeDispatch() async {
        guard let b = selectedBookingForDispatch, let mid = selectedMechanicId else { return }
        isActionRunning = true
        let api = APIService.shared

        do {
            _ = try await api.assignMechanicToBooking(id: b.id, mechanicId: mid)
            // Also update booking status to ASSIGNED/CONFIRMED if still PENDING
            if b.status.uppercased() == "PENDING" {
                _ = try? await api.updateAdminBookingStatus(id: b.id, status: "CONFIRMED")
            }

            await MainActor.run {
                isActionRunning = false
                showDispatchSheet = false
                toastMessage = "Visit \(b.reference) successfully dispatched!"
                withAnimation { showToast = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation { showToast = false }
                }
            }
            await loadDispatcherData()
        } catch {
            await MainActor.run {
                isActionRunning = false
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }

    private func deleteMechanic(id: Int) async {
        let api = APIService.shared
        do {
            _ = try await api.deleteAdminMechanic(id: id)
            await MainActor.run {
                toastMessage = "Technician removed from workshop."
                withAnimation { showToast = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation { showToast = false }
                }
            }
            await loadDispatcherData()
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

// MARK: - Add or Edit Mechanic Sheet
struct AddOrEditMechanicSheet: View {
    @Environment(\.dismiss) private var dismiss
    let mechanic: Mechanic?
    var onSaved: () -> Void

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var specialization: String = ""
    @State private var experienceYears: String = "5"
    @State private var workingHours: String = "8:00 AM - 5:00 PM"
    @State private var isSaving: Bool = false
    @State private var errorMessage: String = ""
    @State private var showErrorAlert: Bool = false

    var isEditMode: Bool { mechanic != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("TECHNICIAN DETAILS").foregroundColor(.primaryGold)) {
                    TextField("Full Name (e.g. Marcus Vance)", text: $name)
                    TextField("Email Address", text: $email)
                    TextField("Phone Number", text: $phone)
                }

                Section(header: Text("EXPERTISE & HOURS").foregroundColor(.primaryGold)) {
                    TextField("Specialization (e.g. Brake & Transmission)", text: $specialization)
                    TextField("Experience (Years)", text: $experienceYears)
                    TextField("Working Hours (e.g. Mon-Fri 8am-5pm)", text: $workingHours)
                }
            }
            .background(Color.bgDark)
            .scrollContentBackground(.hidden)
            .navigationTitle(isEditMode ? "Edit Technician" : "Add Technician")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.textMuted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving..." : "Save") {
                        Task { await saveMechanic() }
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primaryGold)
                    .disabled(name.isEmpty || isSaving)
                }
            }
            #endif
            .onAppear {
                if let m = mechanic {
                    name = m.name
                    email = m.email ?? ""
                    phone = m.phone ?? ""
                    specialization = m.specialization ?? ""
                    if let exp = m.experienceYears { experienceYears = "\(exp)" }
                    workingHours = m.workingHours ?? "8:00 AM - 5:00 PM"
                }
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func saveMechanic() async {
        isSaving = true
        let api = APIService.shared
        let expInt = Int(experienceYears) ?? 5

        do {
            if let m = mechanic {
                let dict: [String: Any] = [
                    "name": name,
                    "email": email,
                    "phone": phone,
                    "specialization": specialization,
                    "experience_years": expInt,
                    "working_hours": workingHours
                ]
                _ = try await api.updateAdminMechanic(id: m.id, data: dict)
            } else {
                let req = CreateMechanicRequest(
                    name: name,
                    email: email.isEmpty ? nil : email,
                    phone: phone.isEmpty ? nil : phone,
                    specialization: specialization.isEmpty ? nil : specialization,
                    experienceYears: expInt,
                    workingHours: workingHours,
                    status: "active"
                )
                _ = try await api.createAdminMechanic(req)
            }

            await MainActor.run {
                isSaving = false
                dismiss()
                onSaved()
            }
        } catch {
            await MainActor.run {
                isSaving = false
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
}
