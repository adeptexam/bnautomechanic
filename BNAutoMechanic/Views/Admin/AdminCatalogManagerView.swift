//
//  AdminCatalogManagerView.swift
//  BNAutoMechanic
//
//  Superadmin & Admin Catalog Management:
//  Full CRUD on Services, Categories, and Brands.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct AdminCatalogManagerView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var session: SessionManager

    @State private var services: [Service] = []
    @State private var categories: [ServiceCategory] = []
    @State private var brands: [Brand] = []

    @State private var selectedTab: Int = 0 // 0: Services, 1: Categories, 2: Brands
    @State private var searchQuery: String = ""
    @State private var isLoading: Bool = false

    // Sheets & Alerts
    @State private var showAddServiceSheet: Bool = false
    @State private var serviceToEdit: Service? = nil
    @State private var serviceToDelete: Service? = nil

    @State private var showAddCategorySheet: Bool = false
    @State private var categoryToDelete: ServiceCategory? = nil

    @State private var showAddBrandSheet: Bool = false
    @State private var brandToDelete: Brand? = nil

    @State private var showDeleteConfirm: Bool = false
    @State private var deleteTargetType: String = "" // "Service", "Category", "Brand"

    @State private var toastMessage: String = ""
    @State private var showToast: Bool = false
    @State private var errorMessage: String = ""
    @State private var showErrorAlert: Bool = false

    private var filteredServices: [Service] {
        if searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
            return services
        }
        let q = searchQuery.lowercased()
        return services.filter {
            $0.name.lowercased().contains(q) ||
            ($0.category?.name.lowercased().contains(q) ?? false) ||
            ($0.description?.lowercased().contains(q) ?? false)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            catalogHeader

            // Segment Tabs
            segmentPicker

            // Search Bar (if on services)
            if selectedTab == 0 {
                searchBarView
            }

            // Main Content List
            if isLoading && services.isEmpty && categories.isEmpty {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .primaryGold))
                    .scaleEffect(1.2)
                Spacer()
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        switch selectedTab {
                        case 0:
                            servicesListSection
                        case 1:
                            categoriesListSection
                        case 2:
                            brandsListSection
                        default:
                            servicesListSection
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .bottomDockClearance()
                }
                .refreshable {
                    await loadCatalogData()
                }
            }
        }
        .background(Color.bgDark.ignoresSafeArea())
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .task {
            await loadCatalogData()
        }
        .sheet(isPresented: $showAddServiceSheet) {
            AddOrEditServiceSheet(service: nil, categories: categories) {
                Task { await loadCatalogData() }
            }
        }
        .sheet(item: $serviceToEdit) { svc in
            AddOrEditServiceSheet(service: svc, categories: categories) {
                Task { await loadCatalogData() }
            }
        }
        .sheet(isPresented: $showAddCategorySheet) {
            AddCategorySheet {
                Task { await loadCatalogData() }
            }
        }
        .sheet(isPresented: $showAddBrandSheet) {
            AddBrandSheet {
                Task { await loadCatalogData() }
            }
        }
        .alert("Confirm Deletion", isPresented: $showDeleteConfirm) {
            Button("Delete Permanently", role: .destructive) {
                Task { await executePendingDelete() }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this \(deleteTargetType)? This action is immediate on the live database.")
        }
        .alert("Error", isPresented: $showErrorAlert) {
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
    private var catalogHeader: some View {
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
                Text("CATALOG & PRICING")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(.primaryGold)
                    .tracking(1)
                Text("Full CRUD on Services, Categories & Brands")
                    .font(.system(size: 11))
                    .foregroundColor(.textMuted)
            }

            Spacer()

            Button {
                triggerHaptic()
                switch selectedTab {
                case 0: showAddServiceSheet = true
                case 1: showAddCategorySheet = true
                case 2: showAddBrandSheet = true
                default: break
                }
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .bold))
                    Text(actionButtonLabel)
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

    private var actionButtonLabel: String {
        switch selectedTab {
        case 0: return "Add Service"
        case 1: return "Add Category"
        case 2: return "Add Brand"
        default: return "Add"
        }
    }

    // MARK: - Segment Picker
    private var segmentPicker: some View {
        HStack(spacing: 8) {
            tabButton("Services (\(services.count))", index: 0)
            tabButton("Categories (\(categories.count))", index: 1)
            tabButton("Brands (\(brands.count))", index: 2)
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
                .font(.system(size: 11, weight: selectedTab == index ? .bold : .medium))
                .foregroundColor(selectedTab == index ? .bgDark : .textForeground)
                .frame(maxWidth: .infinity)
                .frame(height: 32)
                .background(selectedTab == index ? Color.primaryGold : Color.cardDarkElevated)
                .cornerRadius(8)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(selectedTab == index ? Color.primaryGold : Color.borderSubtle, lineWidth: 1))
        }
    }

    // MARK: - Search Bar
    private var searchBarView: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.primaryGold)
                .font(.system(size: 13))

            TextField("Search catalog services...", text: $searchQuery)
                .font(.system(size: 12))
                .foregroundColor(.textForeground)

            if !searchQuery.isEmpty {
                Button { searchQuery = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.textMuted)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.cardDarkElevated)
        .cornerRadius(8)
        .padding(.horizontal, 16)
        .padding(.bottom, 6)
    }

    // MARK: - Services List
    private var servicesListSection: some View {
        VStack(spacing: 10) {
            ForEach(filteredServices) { svc in
                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(svc.name)
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.textForeground)
                            Text(svc.category?.name ?? "General Automotive")
                                .font(.system(size: 11))
                                .foregroundColor(.textMuted)
                        }

                        Spacer()

                        VStack(alignment: .trailing, spacing: 2) {
                            Text(String(format: "$%.2f", svc.effectivePrice))
                                .font(.system(size: 15, weight: .black))
                                .foregroundColor(.primaryGold)

                            Text(svc.formattedDuration())
                                .font(.system(size: 10))
                                .foregroundColor(.textMuted)
                        }
                    }

                    if let desc = svc.description ?? svc.shortDescription, !desc.isEmpty {
                        Text(desc)
                            .font(.system(size: 11))
                            .foregroundColor(.textMuted)
                            .lineLimit(2)
                    }

                    HStack(spacing: 8) {
                        if svc.featured == true {
                            Text("FEATURED")
                                .font(.system(size: 9, weight: .black))
                                .foregroundColor(.bgDark)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.primaryGold)
                                .cornerRadius(4)
                        }

                        Spacer()

                        // Edit Button
                        Button {
                            triggerHaptic()
                            serviceToEdit = svc
                        } label: {
                            Label("Edit", systemImage: "pencil")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.primaryGold)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.primaryGold, lineWidth: 1))
                        }

                        // Delete Button
                        Button {
                            triggerHaptic()
                            serviceToDelete = svc
                            deleteTargetType = "Service"
                            showDeleteConfirm = true
                        } label: {
                            Image(systemName: "trash")
                                .font(.system(size: 12))
                                .foregroundColor(.statusCancelled)
                                .padding(8)
                                .background(Color.statusCancelled.opacity(0.12))
                                .cornerRadius(6)
                        }
                    }
                }
                .padding(14)
                .luxuryCard()
            }
        }
    }

    // MARK: - Categories List
    private var categoriesListSection: some View {
        VStack(spacing: 10) {
            ForEach(categories) { cat in
                HStack(spacing: 12) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.primaryGold.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: cat.icon ?? "folder.fill")
                            .font(.system(size: 16))
                            .foregroundColor(.primaryGold)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(cat.name)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.textForeground)
                        if let desc = cat.description, !desc.isEmpty {
                            Text(desc)
                                .font(.system(size: 11))
                                .foregroundColor(.textMuted)
                                .lineLimit(1)
                        }
                    }

                    Spacer()

                    Button {
                        triggerHaptic()
                        categoryToDelete = cat
                        deleteTargetType = "Category"
                        showDeleteConfirm = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(.statusCancelled)
                            .padding(8)
                            .background(Color.statusCancelled.opacity(0.12))
                            .cornerRadius(6)
                    }
                }
                .padding(12)
                .luxuryCard()
            }
        }
    }

    // MARK: - Brands List
    private var brandsListSection: some View {
        VStack(spacing: 10) {
            ForEach(brands) { b in
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.primaryGold.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Text(String(b.name.prefix(2)).uppercased())
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.primaryGold)
                    }

                    Text(b.name)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.textForeground)

                    Spacer()

                    Button {
                        triggerHaptic()
                        brandToDelete = b
                        deleteTargetType = "Brand"
                        showDeleteConfirm = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(.statusCancelled)
                            .padding(8)
                            .background(Color.statusCancelled.opacity(0.12))
                            .cornerRadius(6)
                    }
                }
                .padding(12)
                .luxuryCard()
            }
        }
    }

    // MARK: - API Calls
    private func loadCatalogData() async {
        isLoading = true
        let api = APIService.shared

        // Load Services
        if let sResp = try? await api.getServices(perPage: 100) {
            await MainActor.run { services = sResp.data?.items ?? [] }
        }

        // Load Categories
        if let cResp = try? await api.getCategories() {
            await MainActor.run { categories = cResp.data ?? [] }
        }

        // Load Brands
        if let bResp = try? await api.getBrands() {
            await MainActor.run { brands = bResp.data?.items ?? [] }
        }

        await MainActor.run { isLoading = false }
    }

    private func executePendingDelete() async {
        let api = APIService.shared
        do {
            switch deleteTargetType {
            case "Service":
                if let s = serviceToDelete {
                    _ = try await api.deleteService(id: s.id)
                    toastMessage = "Service \(s.name) deleted!"
                }
            case "Category":
                if let c = categoryToDelete {
                    _ = try await api.deleteCategory(id: c.id)
                    toastMessage = "Category \(c.name) deleted!"
                }
            case "Brand":
                if let b = brandToDelete {
                    _ = try await api.deleteBrand(id: b.id)
                    toastMessage = "Brand \(b.name) deleted!"
                }
            default: break
            }

            await MainActor.run {
                withAnimation { showToast = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation { showToast = false }
                }
            }
            await loadCatalogData()
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

// MARK: - Add or Edit Service Sheet
struct AddOrEditServiceSheet: View {
    @Environment(\.dismiss) private var dismiss
    let service: Service?
    let categories: [ServiceCategory]
    var onSaved: () -> Void

    @State private var name: String = ""
    @State private var categoryId: Int = 1
    @State private var price: String = ""
    @State private var salePrice: String = ""
    @State private var durationMinutes: String = "60"
    @State private var featured: Bool = false
    @State private var status: String = "active"
    @State private var description: String = ""
    @State private var includedItems: String = ""
    @State private var warrantyInfo: String = "12 Months / 12,000 Miles"
    @State private var isSaving: Bool = false
    @State private var errorMessage: String = ""
    @State private var showErrorAlert: Bool = false

    var isEdit: Bool { service != nil }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("SERVICE SPECIFICATION").foregroundColor(.primaryGold)) {
                    TextField("Service Name", text: $name)

                    Picker("Category", selection: $categoryId) {
                        ForEach(categories) { c in
                            Text(c.name).tag(c.id)
                        }
                    }

                    TextField("Regular Price ($)", text: $price)
                    TextField("Sale Price (Optional)", text: $salePrice)
                    TextField("Duration (Minutes)", text: $durationMinutes)
                }

                Section(header: Text("PROPERTIES & VISIBILITY").foregroundColor(.primaryGold)) {
                    Toggle("Featured on Portal", isOn: $featured)
                    TextField("Warranty Info", text: $warrantyInfo)
                    TextField("Service Description", text: $description)
                    TextField("Included Checklist Items", text: $includedItems)
                }
            }
            .background(Color.bgDark)
            .scrollContentBackground(.hidden)
            .navigationTitle(isEdit ? "Edit Service" : "Add Service")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.textMuted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving..." : "Save") {
                        Task { await saveService() }
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primaryGold)
                    .disabled(name.isEmpty || price.isEmpty || isSaving)
                }
            }
            #endif
            .onAppear {
                if let s = service {
                    name = s.name
                    categoryId = s.category?.id ?? 1
                    if let bp = s.basePrice ?? s.price {
                        price = String(format: "%.2f", bp)
                    }
                    if let sp = s.salePrice { salePrice = String(format: "%.2f", sp) }
                    durationMinutes = "\(s.durationMinutes ?? 60)"
                    featured = s.featured ?? false
                    description = s.description ?? s.shortDescription ?? ""
                    includedItems = s.includedItems?.joined(separator: ", ") ?? ""
                    warrantyInfo = s.warrantyInfo ?? "12 Months / 12,000 Miles"
                } else if let firstCat = categories.first {
                    categoryId = firstCat.id
                }
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func saveService() async {
        guard let p = Double(price) else { return }
        isSaving = true
        let api = APIService.shared
        let sp = Double(salePrice)
        let dur = Int(durationMinutes) ?? 60

        do {
            if let s = service {
                var dict: [String: Any] = [
                    "name": name,
                    "category_id": categoryId,
                    "price": p,
                    "duration_minutes": dur,
                    "featured": featured,
                    "description": description,
                    "warranty_info": warrantyInfo
                ]
                if let sp = sp {
                    dict["sale_price"] = sp
                }
                if !includedItems.isEmpty {
                    dict["included_items"] = includedItems.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                }
                _ = try await api.updateService(id: s.id, data: dict)
            } else {
                let req = CreateServiceRequest(
                    name: name,
                    categoryId: categoryId,
                    price: p,
                    salePrice: sp,
                    durationMinutes: dur,
                    featured: featured,
                    status: "active",
                    description: description,
                    shortDescription: description,
                    includedItems: includedItems,
                    warrantyInfo: warrantyInfo
                )
                _ = try await api.createService(req)
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

// MARK: - Add Category Sheet
struct AddCategorySheet: View {
    @Environment(\.dismiss) private var dismiss
    var onSaved: () -> Void

    @State private var name: String = ""
    @State private var icon: String = "wrench.and.screwdriver.fill"
    @State private var description: String = ""
    @State private var isSaving: Bool = false
    @State private var errorMessage: String = ""
    @State private var showErrorAlert: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("CATEGORY DETAILS").foregroundColor(.primaryGold)) {
                    TextField("Category Name (e.g. Brake Systems)", text: $name)
                    TextField("SF Symbol Icon (e.g. car.fill)", text: $icon)
                    TextField("Description", text: $description)
                }
            }
            .background(Color.bgDark)
            .scrollContentBackground(.hidden)
            .navigationTitle("New Category")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.textMuted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving..." : "Create") {
                        Task { await createCategory() }
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primaryGold)
                    .disabled(name.isEmpty || isSaving)
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

    private func createCategory() async {
        isSaving = true
        let req = CreateCategoryRequest(name: name, icon: icon, description: description, displayOrder: 0)
        do {
            _ = try await APIService.shared.createCategory(req)
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

// MARK: - Add Brand Sheet
struct AddBrandSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onSaved: () -> Void

    @State private var name: String = ""
    @State private var logoUrl: String = ""
    @State private var isSaving: Bool = false
    @State private var errorMessage: String = ""
    @State private var showErrorAlert: Bool = false

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("BRAND DETAILS").foregroundColor(.primaryGold)) {
                    TextField("Brand Name (e.g. Porsche, Audi, BMW)", text: $name)
                    TextField("Logo URL (Optional)", text: $logoUrl)
                }
            }
            .background(Color.bgDark)
            .scrollContentBackground(.hidden)
            .navigationTitle("New Vehicle Brand")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.textMuted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Saving..." : "Create") {
                        Task { await createBrand() }
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primaryGold)
                    .disabled(name.isEmpty || isSaving)
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

    private func createBrand() async {
        isSaving = true
        let req = CreateBrandRequest(name: name, logoUrl: logoUrl.isEmpty ? nil : logoUrl, status: "active")
        do {
            _ = try await APIService.shared.createBrand(req)
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
