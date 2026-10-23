//
//  VehiclesView.swift
//  BNAutoMechanic
//
//  Pixel-perfect replica of Android ActivityVehicles
//

import SwiftUI

struct VehiclesView: View {
    @Environment(\.dismiss) var dismiss
    @State private var vehicles: [Vehicle] = []
    @State private var isLoading = false
    @State private var showAddVehicleSheet = false
    @State private var vehicleToDelete: Vehicle?
    @State private var showDeleteAlert = false

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

                Text("My Garage")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.textForeground)

                Spacer()

                Button(action: { showAddVehicleSheet = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "plus")
                            .font(.system(size: 12, weight: .bold))
                        Text("Add Vehicle")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.bgDark)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(Color.primaryGold)
                    .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider().background(Color.borderSubtle)

            if isLoading {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .primaryGold))
                Spacer()
            } else if vehicles.isEmpty {
                Spacer()
                VStack(spacing: 14) {
                    Image(systemName: "car.side.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.textSubtle)

                    Text("Your garage is empty")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.textForeground)

                    Text("Add your vehicles to speed up appointment scheduling and track service history.")
                        .font(.system(size: 13))
                        .foregroundColor(.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)

                    Button(action: { showAddVehicleSheet = true }) {
                        Label("Add Your Vehicle", systemImage: "plus")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.bgDark)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 12)
                            .background(Color.primaryGold)
                            .cornerRadius(10)
                    }
                    .padding(.top, 8)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(vehicles) { vehicle in
                            vehicleCard(vehicle)
                        }
                    }
                    .padding(16)
                }
                .refreshable {
                    await loadVehicles()
                }
            }
        }
        .background(Color.bgDark.ignoresSafeArea())
        .navigationBarHidden(true)
        .task {
            await loadVehicles()
        }
        .sheet(isPresented: $showAddVehicleSheet) {
            AddVehicleSheet(onVehicleAdded: {
                Task { await loadVehicles() }
            })
        }
        .alert("Remove Vehicle", isPresented: $showDeleteAlert) {
            Button("Remove", role: .destructive) {
                if let v = vehicleToDelete {
                    deleteVehicle(v)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let v = vehicleToDelete {
                Text("Are you sure you want to remove \(v.year) \(v.make) \(v.model) from your garage?")
            } else {
                Text("Are you sure you want to remove this vehicle?")
            }
        }
    }

    // MARK: - Vehicle Card (Matching item_vehicle.xml)
    private func vehicleCard(_ vehicle: Vehicle) -> some View {
        HStack(spacing: 14) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.primaryGoldTint)
                    .frame(width: 44, height: 44)
                Image(systemName: "car.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.primaryGold)
            }

            // Info
            VStack(alignment: .leading, spacing: 3) {
                Text("\(vehicle.year) \(vehicle.make) \(vehicle.model)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.textForeground)
                    .lineLimit(1)

                let plate = vehicle.registrationNumber?.isEmpty == false ? vehicle.registrationNumber! : "No Plate"
                Text("Plate: \(plate)   \(vehicle.vehicleType ?? "Car")")
                    .font(.system(size: 12))
                    .foregroundColor(.textMuted)
                    .lineLimit(1)
            }

            Spacer()

            // Delete Button
            Button(action: {
                vehicleToDelete = vehicle
                showDeleteAlert = true
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.textSubtle)
                    .frame(width: 36, height: 36)
                    .background(Color.cardDarkHover)
                    .cornerRadius(8)
            }
        }
        .padding(16)
        .luxuryCard()
    }

    // MARK: - API Actions
    private func loadVehicles() async {
        isLoading = vehicles.isEmpty
        if let response = try? await APIService.shared.getVehicles() {
            await MainActor.run {
                vehicles = response.data?.items ?? []
                isLoading = false
            }
        } else {
            await MainActor.run { isLoading = false }
        }
    }

    private func deleteVehicle(_ vehicle: Vehicle) {
        Task {
            _ = try? await APIService.shared.deleteVehicle(id: vehicle.id)
            await loadVehicles()
        }
    }
}

// MARK: - Add Vehicle Sheet (Matching dialog_add_vehicle.xml)
struct AddVehicleSheet: View {
    @Environment(\.dismiss) var dismiss
    var onVehicleAdded: () -> Void

    @State private var make = ""
    @State private var model = ""
    @State private var yearText = "2023"
    @State private var plate = ""
    @State private var isSaving = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    Text("Add Vehicle to Garage")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.textForeground)
                        .padding(.top, 8)

                    Text("Enter details for quick appointment booking and vehicle diagnostics.")
                        .font(.system(size: 13))
                        .foregroundColor(.textMuted)

                    // Make
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Make *")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.textForeground)
                        TextField("e.g. BMW, Toyota, Honda", text: $make)
                            .textFieldStyle(DarkInputFieldStyle())
                    }

                    // Model
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Model *")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.textForeground)
                        TextField("e.g. 330i, Camry, Civic", text: $model)
                            .textFieldStyle(DarkInputFieldStyle())
                    }

                    // Year
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Year *")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.textForeground)
                        TextField("e.g. 2022", text: $yearText)
                            .textFieldStyle(DarkInputFieldStyle())
                            .keyboardType(.numberPad)
                    }

                    // License Plate
                    VStack(alignment: .leading, spacing: 6) {
                        Text("License Plate (Optional)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.textForeground)
                        TextField("e.g. ABC-1234", text: $plate)
                            .textFieldStyle(DarkInputFieldStyle())
                            .autocapitalization(.allCharacters)
                    }

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.system(size: 12))
                            .foregroundColor(.statusCancelled)
                    }

                    // Save Button
                    Button(action: saveVehicle) {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .bgDark))
                        } else {
                            Text("Save Vehicle")
                        }
                    }
                    .buttonStyle(GoldButtonStyle(isEnabled: !make.trimmingCharacters(in: .whitespaces).isEmpty && !model.trimmingCharacters(in: .whitespaces).isEmpty && !isSaving))
                    .disabled(make.trimmingCharacters(in: .whitespaces).isEmpty || model.trimmingCharacters(in: .whitespaces).isEmpty || isSaving)
                    .padding(.top, 10)
                }
                .padding(20)
            }
            .background(Color.bgDark.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.textMuted)
                }
            }
        }
    }

    private func saveVehicle() {
        let trimmedMake = make.trimmingCharacters(in: .whitespaces)
        let trimmedModel = model.trimmingCharacters(in: .whitespaces)
        guard !trimmedMake.isEmpty && !trimmedModel.isEmpty else { return }

        let year = Int(yearText) ?? 2023
        let trimmedPlate = plate.trimmingCharacters(in: .whitespaces).isEmpty ? nil : plate.trimmingCharacters(in: .whitespaces)

        isSaving = true
        errorMessage = ""

        Task {
            do {
                let req = CreateVehicleRequest(make: trimmedMake, model: trimmedModel, year: year, registrationNumber: trimmedPlate, vehicleType: nil)
                let resp = try await APIService.shared.createVehicle(req)
                await MainActor.run {
                    isSaving = false
                    if resp.success == true || resp.data != nil {
                        onVehicleAdded()
                        dismiss()
                    } else {
                        errorMessage = resp.message ?? "Failed to add vehicle"
                    }
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isSaving = false
                }
            }
        }
    }
}
