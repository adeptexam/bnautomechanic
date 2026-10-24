//
//  AdminFinancialsView.swift
//  BNAutoMechanic
//
//  Superadmin & Admin Financial Operations Hub:
//  Invoices CRUD, Cash Drawer Reports, Payment Gateway Sync & Refunds,
//  Deals & Coupon Testing, Review Moderation, and Towing Dispatch.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct AdminFinancialsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var session: SessionManager

    @State private var selectedTab: Int = 0 // 0: Invoices & Cash, 1: Deals & Coupons, 2: Reviews, 3: Emergency Towing
    @State private var invoices: [Invoice] = []
    @State private var deals: [Deal] = []
    @State private var reviews: [Review] = []
    @State private var towingRequests: [TowingRequest] = []
    @State private var cashReport: CashReport? = nil

    @State private var isLoading: Bool = false

    // Sheets & Actions
    @State private var showCreateInvoiceSheet: Bool = false
    @State private var showCreateDealSheet: Bool = false
    @State private var invoiceToDelete: Invoice? = nil
    @State private var dealToDelete: Deal? = nil
    @State private var reviewToDelete: Review? = nil
    @State private var showDeleteConfirm: Bool = false
    @State private var deleteType: String = ""

    // Coupon Tester
    @State private var testCouponCode: String = ""
    @State private var testResultText: String = ""
    @State private var isTestingCoupon: Bool = false

    // Review Reply
    @State private var reviewToReply: Review? = nil
    @State private var replyText: String = ""
    @State private var showReplySheet: Bool = false

    // Toast & Alerts
    @State private var toastMessage: String = ""
    @State private var showToast: Bool = false
    @State private var errorMessage: String = ""
    @State private var showErrorAlert: Bool = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            financialHeader

            // Top Segment
            segmentBar

            // Main Content Area
            if isLoading && invoices.isEmpty && deals.isEmpty {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .primaryGold))
                    .scaleEffect(1.2)
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 14) {
                        switch selectedTab {
                        case 0:
                            invoicesAndCashSection
                        case 1:
                            dealsSection
                        case 2:
                            reviewsSection
                        case 3:
                            towingSection
                        default:
                            invoicesAndCashSection
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 32)
                }
                .refreshable {
                    await loadData()
                }
            }
        }
        .background(Color.bgDark.ignoresSafeArea())
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .task {
            await loadData()
        }
        .sheet(isPresented: $showCreateInvoiceSheet) {
            AdminCreateInvoiceSheet {
                Task { await loadData() }
            }
        }
        .sheet(isPresented: $showCreateDealSheet) {
            AdminCreateDealSheet {
                Task { await loadData() }
            }
        }
        .sheet(isPresented: $showReplySheet) {
            replyReviewSheet
        }
        .alert("Confirm Deletion", isPresented: $showDeleteConfirm) {
            Button("Delete Permanently", role: .destructive) {
                Task { await executePendingDelete() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this \(deleteType)? This action is permanent.")
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
    private var financialHeader: some View {
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
                Text("OPERATIONS & FINANCIALS")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(.primaryGold)
                    .tracking(1)
                Text("Invoicing, Cash Drawer, Promotions & Towing Dispatch")
                    .font(.system(size: 11))
                    .foregroundColor(.textMuted)
            }

            Spacer()

            if selectedTab == 0 {
                Button {
                    triggerHaptic()
                    showCreateInvoiceSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("New Invoice")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.bgDark)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.primaryGold)
                    .cornerRadius(8)
                }
            } else if selectedTab == 1 {
                Button {
                    triggerHaptic()
                    showCreateDealSheet = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "plus")
                        Text("New Deal")
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.bgDark)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.primaryGold)
                    .cornerRadius(8)
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }

    // MARK: - Segment Bar
    private var segmentBar: some View {
        HStack(spacing: 6) {
            tabButton("Invoices (\(invoices.count))", index: 0)
            tabButton("Deals (\(deals.count))", index: 1)
            tabButton("Reviews (\(reviews.count))", index: 2)
            tabButton("Towing (\(towingRequests.count))", index: 3)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 6)
    }

    private func tabButton(_ title: String, index: Int) -> some View {
        Button {
            triggerHaptic()
            withAnimation { selectedTab = index }
        } label: {
            Text(title)
                .font(.system(size: 10, weight: selectedTab == index ? .bold : .medium))
                .foregroundColor(selectedTab == index ? .bgDark : .textForeground)
                .frame(maxWidth: .infinity)
                .frame(height: 30)
                .background(selectedTab == index ? Color.primaryGold : Color.cardDarkElevated)
                .cornerRadius(6)
        }
    }

    // MARK: - Invoices & Cash Section
    private var invoicesAndCashSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Cash Drawer Card
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("CASH DRAWER TOTAL TODAY")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.primaryGold)
                    Text(String(format: "$%.2f", cashReport?.totalCash ?? 0.0))
                        .font(.system(size: 20, weight: .black))
                        .foregroundColor(.textForeground)
                }
                Spacer()
                Image(systemName: "banknote.fill")
                    .font(.system(size: 24))
                    .foregroundColor(.primaryGold)
            }
            .padding(14)
            .luxuryCard()

            // Invoices List
            Text("WORKSHOP INVOICES")
                .font(.system(size: 11, weight: .black))
                .foregroundColor(.primaryGold)

            if invoices.isEmpty {
                Text("No invoices generated yet.")
                    .font(.system(size: 12))
                    .foregroundColor(.textMuted)
                    .padding()
            } else {
                ForEach(invoices) { inv in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(inv.invoiceNumber)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.textForeground)
                            Spacer()
                            let statusText = (inv.status ?? "PENDING").uppercased()
                            Text(statusText)
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(statusText == "PAID" ? .statusConfirmed : .primaryGold)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(statusText == "PAID" ? Color.statusConfirmed.opacity(0.14) : Color.primaryGold.opacity(0.14))
                                .cornerRadius(4)
                        }

                        HStack {
                            Text(inv.issuedAt ?? inv.createdAt ?? "Issued")
                                .font(.system(size: 11))
                                .foregroundColor(.textMuted)
                            Spacer()
                            Text(String(format: "$%.2f", inv.total))
                                .font(.system(size: 15, weight: .black))
                                .foregroundColor(.primaryGold)
                        }

                        HStack {
                            Spacer()
                            Button {
                                triggerHaptic()
                                invoiceToDelete = inv
                                deleteType = "Invoice"
                                showDeleteConfirm = true
                            } label: {
                                Image(systemName: "trash")
                                    .foregroundColor(.statusCancelled)
                                    .padding(6)
                            }
                        }
                    }
                    .padding(12)
                    .luxuryCard()
                }
            }
        }
    }

    // MARK: - Deals Section
    private var dealsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Live Coupon Tester Tool
            VStack(alignment: .leading, spacing: 8) {
                Text("LIVE COUPON VALIDATION TESTER")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.primaryGold)

                HStack {
                    TextField("Enter Coupon Code (e.g. WELCOME20)", text: $testCouponCode)
                        .font(.system(size: 12))
                        .padding(8)
                        .background(Color.cardDarkElevated)
                        .cornerRadius(6)

                    Button {
                        Task { await testCoupon() }
                    } label: {
                        Text(isTestingCoupon ? "Testing..." : "TEST CODE")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.bgDark)
                            .padding(.horizontal, 12)
                            .frame(height: 36)
                            .background(Color.primaryGold)
                            .cornerRadius(6)
                    }
                    .disabled(testCouponCode.isEmpty || isTestingCoupon)
                }

                if !testResultText.isEmpty {
                    Text(testResultText)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.statusConfirmed)
                }
            }
            .padding(14)
            .luxuryCard()

            // Deals List
            Text("ACTIVE PROMOTIONS & DEALS")
                .font(.system(size: 11, weight: .black))
                .foregroundColor(.primaryGold)

            ForEach(deals) { deal in
                HStack {
                    VStack(alignment: .leading, spacing: 3) {
                        Text(deal.title)
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.textForeground)
                        if let code = deal.code {
                            Text("CODE: \(code)")
                                .font(.system(size: 11, weight: .black))
                                .foregroundColor(.primaryGold)
                        }
                    }
                    Spacer()
                    Text(deal.discountBadge())
                        .font(.system(size: 11, weight: .black))
                        .foregroundColor(.bgDark)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Color.primaryGold)
                        .cornerRadius(6)

                    Button {
                        triggerHaptic()
                        dealToDelete = deal
                        deleteType = "Deal"
                        showDeleteConfirm = true
                    } label: {
                        Image(systemName: "trash")
                            .foregroundColor(.statusCancelled)
                            .padding(6)
                    }
                }
                .padding(12)
                .luxuryCard()
            }
        }
    }

    // MARK: - Reviews Section
    private var reviewsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("WORKSHOP REVIEWS")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.primaryGold)
                Spacer()
                Button {
                    Task { await syncGoogleReviews() }
                } label: {
                    Label("Sync Google Reviews", systemImage: "arrow.triangle.2.circlepath")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.bgDark)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(Color.primaryGold)
                        .cornerRadius(6)
                }
            }

            ForEach(reviews) { rev in
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(rev.customerName ?? "Customer")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.textForeground)
                        Spacer()
                        HStack(spacing: 2) {
                            ForEach(1...5, id: \.self) { star in
                                Image(systemName: star <= rev.rating ? "star.fill" : "star")
                                    .font(.system(size: 11))
                                    .foregroundColor(.primaryGold)
                            }
                        }
                    }

                    if let comment = rev.comment {
                        Text(comment)
                            .font(.system(size: 12))
                            .foregroundColor(.textMuted)
                    }

                    if let resp = rev.response, !resp.isEmpty {
                        Text("Workshop Response: \(resp)")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.primaryGold)
                            .padding(6)
                            .background(Color.primaryGold.opacity(0.1))
                            .cornerRadius(4)
                    }

                    HStack {
                        Button("Reply") {
                            reviewToReply = rev
                            replyText = rev.response ?? ""
                            showReplySheet = true
                        }
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.primaryGold)

                        Spacer()

                        Button {
                            reviewToDelete = rev
                            deleteType = "Review"
                            showDeleteConfirm = true
                        } label: {
                            Image(systemName: "trash")
                                .foregroundColor(.statusCancelled)
                        }
                    }
                }
                .padding(12)
                .luxuryCard()
            }
        }
    }

    // MARK: - Towing Section
    private var towingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("EMERGENCY ROADSIDE TOWING REQUESTS")
                .font(.system(size: 11, weight: .black))
                .foregroundColor(.primaryGold)

            if towingRequests.isEmpty {
                Text("No active emergency towing requests.")
                    .font(.system(size: 12))
                    .foregroundColor(.textMuted)
                    .padding()
            } else {
                ForEach(towingRequests) { tow in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Pickup: \(tow.pickupLocation)")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.textForeground)
                            Spacer()
                            StatusBadge(status: tow.status)
                        }

                        Text("Destination: \(tow.destination)")
                            .font(.system(size: 11))
                            .foregroundColor(.textMuted)

                        if let v = tow.vehicleInfo {
                            Text("Vehicle: \(v)")
                                .font(.system(size: 11))
                                .foregroundColor(.primaryGold)
                        }

                        HStack(spacing: 8) {
                            Button("Dispatch Tow Truck") {
                                Task { await updateTowingStatus(id: tow.id, status: "DISPATCHED") }
                            }
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.bgDark)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(Color.primaryGold)
                            .cornerRadius(6)

                            Button("Mark Completed") {
                                Task { await updateTowingStatus(id: tow.id, status: "COMPLETED") }
                            }
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.statusConfirmed)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.statusConfirmed, lineWidth: 1))
                        }
                    }
                    .padding(12)
                    .luxuryCard()
                }
            }
        }
    }

    // MARK: - Reply Review Sheet
    private var replyReviewSheet: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextField("Type official workshop response...", text: $replyText)
                    .font(.system(size: 13))
                    .padding(12)
                    .background(Color.cardDarkElevated)
                    .cornerRadius(8)

                Button("Submit Response") {
                    if let r = reviewToReply {
                        Task { await submitReviewResponse(id: r.id) }
                    }
                }
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.bgDark)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(Color.primaryGold)
                .cornerRadius(8)

                Spacer()
            }
            .padding(16)
            .background(Color.bgDark.ignoresSafeArea())
            .navigationTitle("Reply to Review")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { showReplySheet = false }
                        .foregroundColor(.primaryGold)
                }
            }
            #endif
        }
    }

    // MARK: - API Calls
    private func loadData() async {
        isLoading = true
        let api = APIService.shared

        if let invResp = try? await api.getAdminInvoices(perPage: 50) {
            await MainActor.run { invoices = invResp.data?.items ?? [] }
        }

        if let dResp = try? await api.getDeals() {
            await MainActor.run { deals = dResp.data?.items ?? [] }
        }

        if let rResp = try? await api.getAdminReviews(perPage: 50) {
            await MainActor.run { reviews = rResp.data?.items ?? [] }
        }

        if let tResp = try? await api.getAdminTowing() {
            await MainActor.run { towingRequests = tResp.data?.items ?? [] }
        }

        if let cResp = try? await api.getCashReport() {
            await MainActor.run { cashReport = cResp.data }
        }

        await MainActor.run { isLoading = false }
    }

    private func testCoupon() async {
        isTestingCoupon = true
        let api = APIService.shared
        do {
            let resp = try await api.testDealCoupon(code: testCouponCode)
            await MainActor.run {
                isTestingCoupon = false
                if let c = resp.data {
                    testResultText = "Valid Coupon! Applies $\(String(format: "%.2f", c.discountAmount ?? 0.0)) discount: \(c.description ?? "")"
                } else {
                    testResultText = "Coupon applied successfully."
                }
            }
        } catch {
            await MainActor.run {
                isTestingCoupon = false
                testResultText = "Coupon invalid or expired."
            }
        }
    }

    private func syncGoogleReviews() async {
        let api = APIService.shared
        do {
            let resp = try await api.syncGoogleReviews()
            await MainActor.run {
                toastMessage = resp.data?.message ?? "Google reviews synchronized!"
                withAnimation { showToast = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation { showToast = false }
                }
            }
            await loadData()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }

    private func submitReviewResponse(id: Int) async {
        let api = APIService.shared
        do {
            _ = try await api.replyAdminReview(id: id, response: replyText)
            await MainActor.run {
                showReplySheet = false
                toastMessage = "Review response posted!"
                withAnimation { showToast = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation { showToast = false }
                }
            }
            await loadData()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }

    private func updateTowingStatus(id: Int, status: String) async {
        let api = APIService.shared
        do {
            _ = try await api.updateAdminTowingStatus(id: id, status: status)
            await MainActor.run {
                toastMessage = "Towing status updated to \(status)!"
                withAnimation { showToast = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation { showToast = false }
                }
            }
            await loadData()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }

    private func executePendingDelete() async {
        let api = APIService.shared
        do {
            if deleteType == "Invoice", let inv = invoiceToDelete {
                _ = try await api.deleteInvoice(id: inv.id)
                toastMessage = "Invoice deleted!"
            } else if deleteType == "Deal", let d = dealToDelete {
                _ = try await api.deleteDeal(id: d.id)
                toastMessage = "Deal deleted!"
            } else if deleteType == "Review", let r = reviewToDelete {
                _ = try await api.deleteAdminReview(id: r.id)
                toastMessage = "Review deleted!"
            }

            await MainActor.run {
                withAnimation { showToast = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation { showToast = false }
                }
            }
            await loadData()
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

// MARK: - Admin Create Invoice Sheet
struct AdminCreateInvoiceSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onSaved: () -> Void

    @State private var customerName: String = ""
    @State private var customerEmail: String = ""
    @State private var itemName: String = "Comprehensive Vehicle Service"
    @State private var itemPrice: String = "250.00"
    @State private var isSaving: Bool = false
    @State private var errorMessage: String = ""
    @State private var showErrorAlert: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("CLIENT DETAILS").foregroundColor(.primaryGold)) {
                    TextField("Customer Name", text: $customerName)
                    TextField("Customer Email", text: $customerEmail)
                }

                Section(header: Text("LINE ITEM").foregroundColor(.primaryGold)) {
                    TextField("Description", text: $itemName)
                    TextField("Amount ($)", text: $itemPrice)
                }
            }
            .background(Color.bgDark)
            .scrollContentBackground(.hidden)
            .navigationTitle("New Invoice")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.textMuted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving..." : "Create") {
                        Task { await createInvoice() }
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primaryGold)
                    .disabled(customerName.isEmpty || isSaving)
                }
            }
            #endif
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func createInvoice() async {
        isSaving = true
        let p = Double(itemPrice) ?? 0.0
        let req = CreateInvoiceRequest(
            bookingId: nil,
            userId: nil,
            customerName: customerName,
            customerEmail: customerEmail,
            items: [["description": itemName, "unit_price": "\(p)", "quantity": "1", "total": "\(p)"]],
            subtotal: p,
            tax: 0.0,
            total: p,
            dueDate: nil,
            notes: "Generated by workshop administration"
        )

        do {
            _ = try await APIService.shared.createInvoice(req)
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

// MARK: - Admin Create Deal Sheet
struct AdminCreateDealSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onSaved: () -> Void

    @State private var title: String = ""
    @State private var code: String = ""
    @State private var discountType: String = "PERCENTAGE"
    @State private var discountValue: String = "15"
    @State private var minSpend: String = "50"
    @State private var isSaving: Bool = false
    @State private var errorMessage: String = ""
    @State private var showErrorAlert: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("COUPON DETAILS").foregroundColor(.primaryGold)) {
                    TextField("Title (e.g. 15% Spring Brake Service)", text: $title)
                    TextField("Coupon Code (e.g. BRAKE15)", text: $code)
                }

                Section(header: Text("DISCOUNT").foregroundColor(.primaryGold)) {
                    Picker("Type", selection: $discountType) {
                        Text("Percentage (%)").tag("PERCENTAGE")
                        Text("Fixed Dollar Amount ($)").tag("FIXED")
                    }
                    TextField("Discount Value", text: $discountValue)
                    TextField("Minimum Spend ($)", text: $minSpend)
                }
            }
            .background(Color.bgDark)
            .scrollContentBackground(.hidden)
            .navigationTitle("New Deal / Coupon")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.textMuted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving..." : "Create") {
                        Task { await createDeal() }
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primaryGold)
                    .disabled(title.isEmpty || code.isEmpty || isSaving)
                }
            }
            #endif
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func createDeal() async {
        isSaving = true
        let val = Double(discountValue) ?? 10.0
        let min = Double(minSpend)

        let req = CreateDealRequest(
            title: title,
            description: title,
            code: code.uppercased(),
            discountType: discountType,
            discountValue: val,
            minSpend: min,
            startsAt: nil,
            endsAt: nil,
            appliesTo: "all",
            publicDeal: true
        )

        do {
            _ = try await APIService.shared.createDeal(req)
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
