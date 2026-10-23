//
//  ServicesView.swift
//  BNAutoMechanic
//

import SwiftUI

struct ServicesView: View {
    @Binding var selectedTab: Int
    @State private var allServices: [Service] = []
    @State private var categories: [ServiceCategory] = []
    @State private var selectedCategoryId: Int? = nil
    @State private var searchText = ""
    @State private var isLoading = false

    private var filteredServices: [Service] {
        let q = searchText.trimmingCharacters(in: .whitespaces).lowercased()
        return allServices.filter { service in
            let matchCategory = selectedCategoryId == nil || service.categoryId == selectedCategoryId
            let matchQuery = q.isEmpty ||
                service.name.lowercased().contains(q) ||
                (service.description?.lowercased().contains(q) == true) ||
                (service.category?.name.lowercased().contains(q) == true)
            return matchCategory && matchQuery
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Services")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.textForeground)
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)

            // Search
            HStack(spacing: 10) {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.textMuted)
                    .font(.system(size: 14))

                TextField("Search services...", text: $searchText)
                    .foregroundColor(.textForeground)
                    .font(.system(size: 14))
                    .textInputAutocapitalization(.never)

                if !searchText.isEmpty {
                    Button(action: { searchText = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.textMuted)
                            .font(.system(size: 14))
                    }
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 12)
            .background(Color.surfaceDark)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.borderMedium, lineWidth: 1)
            )
            .padding(.horizontal, 16)

            // Category Chips
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    chipButton(label: "All", isSelected: selectedCategoryId == nil) {
                        selectedCategoryId = nil
                    }
                    ForEach(categories) { cat in
                        chipButton(label: cat.name, isSelected: selectedCategoryId == cat.id) {
                            selectedCategoryId = cat.id
                        }
                    }
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }

            Divider().background(Color.borderSubtle)

            // Services List
            if isLoading {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .primaryGold))
                Spacer()
            } else if filteredServices.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "wrench.and.screwdriver")
                        .font(.system(size: 36))
                        .foregroundColor(.textSubtle)
                    Text("No services found")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.textMuted)
                    Text("Try adjusting your filters or search")
                        .font(.system(size: 12))
                        .foregroundColor(.textSubtle)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredServices) { service in
                            NavigationLink(destination: ServiceDetailView(
                                serviceId: service.id,
                                serviceName: service.name,
                                serviceDesc: service.description ?? service.shortDescription,
                                serviceDuration: service.formattedDuration(),
                                serviceCategory: service.category?.name ?? "Maintenance"
                            )) {
                                ServiceCardView(service: service)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                }
                .refreshable {
                    await loadServices()
                }
            }
        }
        .background(Color.bgDark.ignoresSafeArea())
        .navigationBarHidden(true)
        .task {
            await loadServices()
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

    private func loadServices() async {
        isLoading = allServices.isEmpty
        let api = APIService.shared

        // Load categories
        if let catResponse = try? await api.getCategories() {
            await MainActor.run {
                categories = catResponse.data ?? []
            }
        }

        // Load services
        if let response = try? await api.getServices(perPage: 50) {
            await MainActor.run {
                allServices = response.data?.items ?? []
            }
        }

        await MainActor.run { isLoading = false }
    }
}

