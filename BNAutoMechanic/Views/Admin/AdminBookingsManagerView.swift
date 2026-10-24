//
//  AdminBookingsManagerView.swift
//  BNAutoMechanic
//
//  Superadmin & Admin Bookings Management Hub:
//  Full CRUD: Create, Read, Update, Delete.
//  Approve bookings, Estimate price, Manage Extras, Assign Mechanics, and Update Status.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct AdminBookingsManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var session: SessionManager

    @State private var bookings: [Booking] = []
    @State private var isLoading: Bool = false
    @State private var selectedStatusFilter: String = "ALL"
    @State private var searchQuery: String = ""

    // Active Action Sheet
    @State private var selectedBookingForEdit: Booking? = nil
    @State private var showCreateBookingSheet: Bool = false
    @State private var bookingToDelete: Booking? = nil
    @State private var showDeleteConfirmAlert: Bool = false

    // Toast & Error Notifications
    @State private var toastMessage: String = ""
    @State private var showToast: Bool = false
    @State private var errorMessage: String = ""
    @State private var showErrorAlert: Bool = false

    private let statusTabs = ["ALL", "PENDING", "CONFIRMED", "IN_PROGRESS", "COMPLETED", "CANCELLED"]

    private var filteredBookings: [Booking] {
        var list = bookings
        if selectedStatusFilter != "ALL" {
            list = list.filter { $0.status.uppercased() == selectedStatusFilter }
        }
        if !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
            let q = searchQuery.lowercased()
            list = list.filter {
                $0.reference.lowercased().contains(q) ||
                ($0.customerName?.lowercased().contains(q) ?? false) ||
                ($0.customerPhone?.contains(q) ?? false) ||
                ($0.vehicle?.displayName().lowercased().contains(q) ?? false)
            }
        }
        return list
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            managerHeader

            // Search Bar
            searchBarView

            // Status Filter Chips
            statusChipsView

            // Content
            if isLoading && bookings.isEmpty {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .primaryGold))
                    .scaleEffect(1.2)
                Spacer()
            } else if filteredBookings.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "calendar.badge.exclamationmark")
                        .font(.system(size: 38))
                        .foregroundColor(.textSubtle)
                    Text("No bookings match your filter")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.textForeground)
                    Text("Try selecting a different status or creating a new appointment.")
                        .font(.system(size: 12))
                        .foregroundColor(.textMuted)
                }
                .padding(24)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(filteredBookings) { booking in
                            adminBookingCard(booking)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .bottomDockClearance()
                }
                .refreshable {
                    await loadAdminBookings()
                }
            }
        }
        .background(Color.bgDark.ignoresSafeArea())
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .task {
            await loadAdminBookings()
        }
        .sheet(item: $selectedBookingForEdit) { booking in
            AdminBookingDetailSheet(booking: booking) {
                Task { await loadAdminBookings() }
            }
        }
        .sheet(isPresented: $showCreateBookingSheet) {
            AdminCreateBookingSheet {
                Task { await loadAdminBookings() }
            }
        }
        .alert("Delete Booking", isPresented: $showDeleteConfirmAlert) {
            Button("Delete Permanently", role: .destructive) {
                if let b = bookingToDelete {
                    Task { await deleteBooking(id: b.id) }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete booking \(bookingToDelete?.reference ?? "")? This will remove all associated invoices and records.")
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

    // MARK: - Manager Header
    private var managerHeader: some View {
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
                Text("BOOKINGS MANAGEMENT")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(.primaryGold)
                    .tracking(1)
                Text("Full Administrative Approval & Estimate Control")
                    .font(.system(size: 11))
                    .foregroundColor(.textMuted)
            }

            Spacer()

            Button {
                triggerHaptic()
                showCreateBookingSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                    Text("New Booking")
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
        .padding(.bottom, 6)
    }

    // MARK: - Search Bar
    private var searchBarView: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.primaryGold)
                .font(.system(size: 14))

            TextField("Search by reference, customer, vehicle...", text: $searchQuery)
                .font(.system(size: 12))
                .foregroundColor(.textForeground)

            if !searchQuery.isEmpty {
                Button {
                    searchQuery = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.textMuted)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.cardDarkElevated)
        .cornerRadius(10)
        .overlay(RoundedRectangle(cornerRadius: 10).stroke(Color.borderSubtle, lineWidth: 1))
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }

    // MARK: - Status Filter Chips
    private var statusChipsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(statusTabs, id: \.self) { tab in
                    let isSelected = selectedStatusFilter == tab
                    Button {
                        triggerHaptic()
                        withAnimation { selectedStatusFilter = tab }
                    } label: {
                        Text(tab.replacingOccurrences(of: "_", with: " "))
                            .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                            .foregroundColor(isSelected ? .bgDark : .textForeground)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isSelected ? Color.primaryGold : Color.cardDarkElevated)
                            .cornerRadius(8)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isSelected ? Color.primaryGold : Color.borderSubtle, lineWidth: 1)
                            )
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
    }

    // MARK: - Admin Booking Card
    private func adminBookingCard(_ b: Booking) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            // Top row: Ref, customer, status badge
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(b.reference)
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(.primaryGold)
                    Text(b.customerName ?? "Customer Visit")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.textForeground)
                }

                Spacer()

                StatusBadge(status: b.status)
            }

            Divider().background(Color.borderSubtle)

            // Info Grid
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 4) {
                    Label("\(b.scheduledDate) • \(b.scheduledTime)", systemImage: "clock.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.textMuted)

                    Label(b.vehicle?.displayName() ?? "Unspecified Vehicle", systemImage: "car.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.textMuted)
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    let price = b.estimate?.effectiveTotal ?? b.totalAmount ?? 0.0
                    Text(String(format: "$%.2f", price))
                        .font(.system(size: 15, weight: .black))
                        .foregroundColor(.primaryGold)

                    Text(b.paymentStatus ?? "NOT_DUE")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.textMuted)
                }
            }

            Text("Services: \(b.servicesSummary())")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.textForeground)
                .lineLimit(2)

            // Administrative Action Bar
            HStack(spacing: 8) {
                // If PENDING: Quick Approve
                if b.status.uppercased() == "PENDING" {
                    Button {
                        triggerHaptic()
                        Task { await approveBooking(b) }
                    } label: {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                            Text("APPROVE")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundColor(.bgDark)
                        .frame(maxWidth: .infinity)
                        .frame(height: 34)
                        .background(Color.statusConfirmed)
                        .cornerRadius(6)
                    }
                }

                // Edit & Estimate details
                Button {
                    triggerHaptic()
                    selectedBookingForEdit = b
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "slider.horizontal.3")
                        Text("MANAGE & ESTIMATE")
                            .font(.system(size: 11, weight: .bold))
                    }
                    .foregroundColor(.primaryGold)
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
                    .background(Color.primaryGold.opacity(0.12))
                    .cornerRadius(6)
                    .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.primaryGold.opacity(0.6), lineWidth: 1))
                }

                // Delete Button (Superadmin)
                Button {
                    triggerHaptic()
                    bookingToDelete = b
                    showDeleteConfirmAlert = true
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                        .foregroundColor(.statusCancelled)
                        .frame(width: 34, height: 34)
                        .background(Color.statusCancelled.opacity(0.12))
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.statusCancelled.opacity(0.4), lineWidth: 1))
                }
            }
            .padding(.top, 4)
        }
        .padding(14)
        .luxuryCard()
    }

    // MARK: - Backend Actions
    private func loadAdminBookings() async {
        isLoading = true
        let api = APIService.shared
        if let resp = try? await api.getAdminBookings(perPage: 100) {
            await MainActor.run {
                bookings = resp.data?.items ?? []
                isLoading = false
            }
        } else {
            await MainActor.run { isLoading = false }
        }
    }

    private func approveBooking(_ b: Booking) async {
        let api = APIService.shared
        do {
            _ = try await api.updateAdminBookingStatus(id: b.id, status: "CONFIRMED")
            await MainActor.run {
                toastMessage = "Booking \(b.reference) confirmed & approved!"
                withAnimation { showToast = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation { showToast = false }
                }
            }
            await loadAdminBookings()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }

    private func deleteBooking(id: Int) async {
        let api = APIService.shared
        do {
            _ = try await api.deleteAdminBooking(id: id)
            await MainActor.run {
                toastMessage = "Booking deleted from system."
                withAnimation { showToast = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation { showToast = false }
                }
            }
            await loadAdminBookings()
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

// MARK: - Admin Comprehensive Booking Detail Sheet
struct AdminBookingDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let booking: Booking
    var onUpdated: () -> Void

    // Status & Dispatch
    @State private var currentStatus: String = "PENDING"
    @State private var mechanics: [Mechanic] = []
    @State private var selectedMechanicId: Int = 0

    // Estimate Editor
    @State private var estimateItems: [EstimateItem] = []
    @State private var newItemName: String = ""
    @State private var newItemPrice: String = ""
    @State private var newItemQty: String = "1"
    @State private var discountAmount: String = "0"
    @State private var taxRate: String = "8.25"
    @State private var estimateNotes: String = ""

    // Extras
    @State private var extraName: String = ""
    @State private var extraPrice: String = ""

    // Progress State
    @State private var isSaving: Bool = false
    @State private var toastText: String = ""
    @State private var showLocalToast: Bool = false
    @State private var errorMessage: String = ""
    @State private var showErrorAlert: Bool = false

    private let statusOptions = ["PENDING", "CONFIRMED", "IN_PROGRESS", "COMPLETED", "CANCELLED"]

    private var calculatedSubtotal: Double {
        var sum: Double = 0.0
        for item in estimateItems {
            sum += item.unitPrice * item.quantity
        }
        return sum
    }

    private var calculatedTax: Double {
        let rate = (Double(taxRate) ?? 0.0) / 100.0
        return calculatedSubtotal * rate
    }

    private var calculatedDiscount: Double {
        Double(discountAmount) ?? 0.0
    }

    private var calculatedTotal: Double {
        max(0, calculatedSubtotal + calculatedTax - calculatedDiscount)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    // Booking Header Overview
                    overviewSection

                    // Status Transition Section
                    statusTransitionSection

                    // Mechanic Dispatch Selector
                    mechanicDispatchSection

                    // Comprehensive Estimate Price Editor
                    estimateEditorSection

                    // Inspection Extras Discovered
                    extrasSection
                }
                .padding(16)
                .padding(.bottom, 24)
            }
            .background(Color.bgDark.ignoresSafeArea())
            .navigationTitle("Manage: \(booking.reference)")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                        .foregroundColor(.primaryGold)
                }
            }
            #endif
            .task {
                await loadMechanics()
                populateInitialData()
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
            .overlay(alignment: .bottom) {
                if showLocalToast {
                    Text(toastText)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.bgDark)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.primaryGold)
                        .cornerRadius(16)
                        .padding(.bottom, 16)
                }
            }
        }
    }

    // MARK: - Overview Section
    private var overviewSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("CUSTOMER & VEHICLE DETAILS")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.primaryGold)
                Spacer()
                StatusBadge(status: currentStatus)
            }

            Divider().background(Color.borderSubtle)

            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(booking.customerName ?? "Customer")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.textForeground)
                    if let phone = booking.customerPhone {
                        Label(phone, systemImage: "phone.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.textMuted)
                    }
                    if let email = booking.customerEmail {
                        Label(email, systemImage: "envelope.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.textMuted)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(booking.vehicle?.displayName() ?? "Vehicle")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.primaryGold)
                    Text("\(booking.scheduledDate) at \(booking.scheduledTime)")
                        .font(.system(size: 11))
                        .foregroundColor(.textMuted)
                }
            }
        }
        .padding(14)
        .luxuryCard()
    }

    // MARK: - Status Transition Section
    private var statusTransitionSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("UPDATE VISIT STATUS")
                .font(.system(size: 11, weight: .black))
                .foregroundColor(.primaryGold)

            HStack(spacing: 8) {
                ForEach(statusOptions, id: \.self) { st in
                    let isSelected = currentStatus.uppercased() == st
                    Button {
                        currentStatus = st
                        Task { await updateStatus(st) }
                    } label: {
                        Text(st.replacingOccurrences(of: "_", with: " "))
                            .font(.system(size: 9, weight: isSelected ? .bold : .medium))
                            .foregroundColor(isSelected ? .bgDark : .textForeground)
                            .frame(maxWidth: .infinity)
                            .frame(height: 32)
                            .background(isSelected ? Color.primaryGold : Color.cardDarkElevated)
                            .cornerRadius(6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(isSelected ? Color.primaryGold : Color.borderSubtle, lineWidth: 1))
                    }
                }
            }
        }
        .padding(14)
        .luxuryCard()
    }

    // MARK: - Mechanic Dispatch Section
    private var mechanicDispatchSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("ASSIGN MECHANIC BAY")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.primaryGold)
                Spacer()
            }

            Picker("Mechanic", selection: $selectedMechanicId) {
                Text("Unassigned (Waiting for dispatch)").tag(0)
                ForEach(mechanics) { m in
                    Text("\(m.name) (\(m.specialization ?? "General"))").tag(m.id)
                }
            }
            .pickerStyle(.menu)
            .padding(10)
            .background(Color.cardDarkElevated)
            .cornerRadius(8)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.borderSubtle, lineWidth: 1))

            Button {
                Task { await assignMechanic() }
            } label: {
                Text("DISPATCH SELECTED MECHANIC")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.bgDark)
                    .frame(maxWidth: .infinity)
                    .frame(height: 34)
                    .background(Color.primaryGold)
                    .cornerRadius(6)
            }
        }
        .padding(14)
        .luxuryCard()
    }

    // MARK: - Estimate Editor Section
    private var estimateEditorSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("ESTIMATE & PRICE BUILDER")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.primaryGold)
                Spacer()
                Text("Total: \(String(format: "$%.2f", calculatedTotal))")
                    .font(.system(size: 14, weight: .black))
                    .foregroundColor(.primaryGold)
            }

            Divider().background(Color.borderSubtle)

            // Existing line items
            if estimateItems.isEmpty {
                Text("No custom items in estimate yet.")
                    .font(.system(size: 11))
                    .foregroundColor(.textMuted)
            } else {
                ForEach(estimateItems) { item in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.textForeground)
                            Text("\(Int(item.quantity))x @ $\(String(format: "%.2f", item.unitPrice))")
                                .font(.system(size: 10))
                                .foregroundColor(.textMuted)
                        }
                        Spacer()
                        Text(String(format: "$%.2f", item.total))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.primaryGold)

                        Button {
                            estimateItems.removeAll(where: { $0.id == item.id })
                        } label: {
                            Image(systemName: "xmark.circle")
                                .foregroundColor(.statusCancelled)
                        }
                    }
                    .padding(8)
                    .background(Color.cardDarkElevated)
                    .cornerRadius(6)
                }
            }

            // Add new line item row
            HStack(spacing: 8) {
                TextField("Item / Part / Labor", text: $newItemName)
                    .font(.system(size: 12))
                    .padding(8)
                    .background(Color.cardDarkElevated)
                    .cornerRadius(6)

                TextField("Price", text: $newItemPrice)
                    .font(.system(size: 12))
                    .frame(width: 70)
                    .padding(8)
                    .background(Color.cardDarkElevated)
                    .cornerRadius(6)

                Button {
                    guard !newItemName.isEmpty, let p = Double(newItemPrice), p > 0 else { return }
                    let qty = Double(newItemQty) ?? 1.0
                    estimateItems.append(EstimateItem(name: newItemName, unitPrice: p, quantity: qty))
                    newItemName = ""
                    newItemPrice = ""
                } label: {
                    Image(systemName: "plus")
                        .foregroundColor(.bgDark)
                        .padding(8)
                        .background(Color.primaryGold)
                        .cornerRadius(6)
                }
            }

            // Discount & Tax rate
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Discount ($)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.textMuted)
                    TextField("0.00", text: $discountAmount)
                        .font(.system(size: 12))
                        .padding(8)
                        .background(Color.cardDarkElevated)
                        .cornerRadius(6)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Tax Rate (%)")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.textMuted)
                    TextField("8.25", text: $taxRate)
                        .font(.system(size: 12))
                        .padding(8)
                        .background(Color.cardDarkElevated)
                        .cornerRadius(6)
                }
            }

            // Estimate Actions
            HStack(spacing: 8) {
                Button {
                    Task { await saveEstimate() }
                } label: {
                    Text("SAVE ESTIMATE")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.bgDark)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(Color.primaryGold)
                        .cornerRadius(6)
                }

                Button {
                    Task { await sendEstimate() }
                } label: {
                    Text("SEND TO CLIENT")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.primaryGold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.primaryGold, lineWidth: 1))
                }

                Button {
                    Task { await approveEstimateOnBehalf() }
                } label: {
                    Text("APPROVE NOW")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.statusConfirmed)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.statusConfirmed, lineWidth: 1))
                }
            }
            .padding(.top, 4)
        }
        .padding(14)
        .luxuryCard()
    }

    // MARK: - Extras Section
    private var extrasSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("ADDITIONAL INSPECTION EXTRAS")
                .font(.system(size: 11, weight: .black))
                .foregroundColor(.primaryGold)

            if let extras = booking.extras, !extras.isEmpty {
                ForEach(extras) { extra in
                    HStack {
                        Text(extra.title)
                            .font(.system(size: 12))
                            .foregroundColor(.textForeground)
                        Spacer()
                        Text(String(format: "$%.2f", extra.cost ?? 0.0))
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.primaryGold)
                    }
                    .padding(8)
                    .background(Color.cardDarkElevated)
                    .cornerRadius(6)
                }
            }

            HStack(spacing: 8) {
                TextField("Extra Service / Part Found", text: $extraName)
                    .font(.system(size: 12))
                    .padding(8)
                    .background(Color.cardDarkElevated)
                    .cornerRadius(6)

                TextField("Cost", text: $extraPrice)
                    .font(.system(size: 12))
                    .frame(width: 70)
                    .padding(8)
                    .background(Color.cardDarkElevated)
                    .cornerRadius(6)

                Button("Add") {
                    Task { await addExtra() }
                }
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.bgDark)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.primaryGold)
                .cornerRadius(6)
                .disabled(extraName.isEmpty || extraPrice.isEmpty)
            }
        }
        .padding(14)
        .luxuryCard()
    }

    // MARK: - Logic & API Calls
    private func populateInitialData() {
        currentStatus = booking.status
        selectedMechanicId = booking.mechanicId ?? 0

        if let est = booking.estimate {
            if let items = est.items, !items.isEmpty {
                estimateItems = items
            } else {
                // Synthesize from services
                if let svcs = booking.services {
                    estimateItems = svcs.map {
                        EstimateItem(name: $0.serviceName, unitPrice: $0.price ?? 80.0, quantity: 1.0)
                    }
                }
            }
            if let disc = est.discount { discountAmount = "\(disc)" }
            if let tx = est.taxRate { taxRate = "\(tx)" }
            estimateNotes = est.notes ?? ""
        } else if let svcs = booking.services {
            estimateItems = svcs.map {
                EstimateItem(name: $0.serviceName, unitPrice: $0.price ?? 80.0, quantity: 1.0)
            }
        }
    }

    private func loadMechanics() async {
        let api = APIService.shared
        if let resp = try? await api.getAdminMechanics() {
            await MainActor.run {
                mechanics = resp.data?.items ?? []
            }
        }
    }

    private func updateStatus(_ st: String) async {
        let api = APIService.shared
        do {
            _ = try await api.updateAdminBookingStatus(id: booking.id, status: st)
            showToastMessage("Status changed to \(st)")
            onUpdated()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }

    private func assignMechanic() async {
        let api = APIService.shared
        let mid: Int? = selectedMechanicId > 0 ? selectedMechanicId : nil
        do {
            _ = try await api.assignMechanicToBooking(id: booking.id, mechanicId: mid)
            showToastMessage("Technician dispatched!")
            onUpdated()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }

    private func saveEstimate() async {
        let api = APIService.shared
        let rawItems: [[String: Any]] = estimateItems.map {
            [
                "name": $0.name,
                "unit_price": $0.unitPrice,
                "quantity": $0.quantity,
                "total": $0.total,
                "type": $0.type ?? "service"
            ]
        }
        let disc = Double(discountAmount) ?? 0.0
        let rate = Double(taxRate) ?? 8.25

        do {
            _ = try await api.saveAdminEstimate(id: booking.id, items: rawItems, discount: disc, taxRate: rate, notes: estimateNotes)
            showToastMessage("Estimate saved!")
            onUpdated()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }

    private func sendEstimate() async {
        let api = APIService.shared
        do {
            _ = try await api.sendAdminEstimate(id: booking.id)
            showToastMessage("Estimate sent to customer!")
            onUpdated()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }

    private func approveEstimateOnBehalf() async {
        let api = APIService.shared
        do {
            _ = try await api.approveAdminEstimateOnBehalf(id: booking.id)
            currentStatus = "CONFIRMED"
            showToastMessage("Estimate approved on behalf of customer!")
            onUpdated()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }

    private func addExtra() async {
        guard let p = Double(extraPrice) else { return }
        let api = APIService.shared
        do {
            _ = try await api.addBookingExtra(bookingId: booking.id, name: extraName, price: p)
            extraName = ""
            extraPrice = ""
            showToastMessage("Extra service added!")
            onUpdated()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }

    private func showToastMessage(_ text: String) {
        toastText = text
        withAnimation { showLocalToast = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation { showLocalToast = false }
        }
    }
}

// MARK: - Admin Create Booking Sheet
struct AdminCreateBookingSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onCreated: () -> Void

    @State private var customerName: String = ""
    @State private var customerEmail: String = ""
    @State private var customerPhone: String = ""
    @State private var vehicleMake: String = ""
    @State private var vehicleModel: String = ""
    @State private var vehicleYear: String = "2023"
    @State private var scheduledDate: Date = Date()
    @State private var scheduledTime: String = "10:00 AM"
    @State private var notes: String = ""
    @State private var services: [Service] = []
    @State private var selectedServiceIds: Set<Int> = []
    @State private var isSubmitting: Bool = false
    @State private var errorMessage: String = ""
    @State private var showErrorAlert: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("CUSTOMER INFO").foregroundColor(.primaryGold)) {
                    TextField("Full Name", text: $customerName)
                    TextField("Email Address", text: $customerEmail)
                    TextField("Phone Number", text: $customerPhone)
                }

                Section(header: Text("VEHICLE INFO").foregroundColor(.primaryGold)) {
                    TextField("Make (e.g. BMW, Toyota)", text: $vehicleMake)
                    TextField("Model (e.g. M3, Camry)", text: $vehicleModel)
                    TextField("Year", text: $vehicleYear)
                }

                Section(header: Text("APPOINTMENT SCHEDULE").foregroundColor(.primaryGold)) {
                    DatePicker("Visit Date", selection: $scheduledDate, displayedComponents: .date)
                    TextField("Time (e.g. 10:00 AM)", text: $scheduledTime)
                    TextField("Workshop Notes / Instructions", text: $notes)
                }

                Section(header: Text("SELECT SERVICES").foregroundColor(.primaryGold)) {
                    ForEach(services) { svc in
                        let isSelected = selectedServiceIds.contains(svc.id)
                        Button {
                            if isSelected { selectedServiceIds.remove(svc.id) }
                            else { selectedServiceIds.insert(svc.id) }
                        } label: {
                            HStack {
                                Text(svc.name)
                                    .foregroundColor(.textForeground)
                                Spacer()
                                Text(String(format: "$%.2f", svc.effectivePrice))
                                    .foregroundColor(.primaryGold)
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(isSelected ? .primaryGold : .textSubtle)
                            }
                        }
                    }
                }
            }
            .background(Color.bgDark)
            .scrollContentBackground(.hidden)
            .navigationTitle("Create Booking")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.textMuted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSubmitting ? "Creating..." : "Create") {
                        Task { await createBooking() }
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primaryGold)
                    .disabled(customerName.isEmpty || selectedServiceIds.isEmpty || isSubmitting)
                }
            }
            #endif
            .task {
                if let resp = try? await APIService.shared.getServices(perPage: 50) {
                    services = resp.data?.items ?? []
                }
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func createBooking() async {
        isSubmitting = true
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        let dateString = formatter.string(from: scheduledDate)

        let vehicleReq = CreateVehicleRequest(
            make: vehicleMake.isEmpty ? "Vehicle" : vehicleMake,
            model: vehicleModel.isEmpty ? "Standard" : vehicleModel,
            year: Int(vehicleYear) ?? 2023,
            vehicleType: "Sedan"
        )

        let req = CreateBookingRequest(
            serviceIds: Array(selectedServiceIds),
            vehicleId: nil,
            vehicle: vehicleReq,
            scheduledDate: dateString,
            scheduledTime: scheduledTime,
            notes: notes.isEmpty ? nil : notes,
            couponCode: nil
        )

        do {
            _ = try await APIService.shared.createBooking(req)
            await MainActor.run {
                isSubmitting = false
                dismiss()
                onCreated()
            }
        } catch {
            await MainActor.run {
                isSubmitting = false
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
}
