//
//  VehiclesView.swift
//  BNAutoMechanic
//
//  Customer Garage & Vehicle Management:
//  Full CRUD: Create new vehicle, Read garage fleet, Update/Patch vehicle specs, Delete vehicle.
//

import SwiftUI

struct VehiclesView: View {
    @Environment(\.dismiss) var dismiss
    @State private var vehicles: [Vehicle] = []
    @State private var isLoading = false
    @State private var showAddVehicleSheet = false
    @State private var vehicleToEdit: Vehicle?
    @State private var vehicleToDelete: Vehicle?
    @State private var showDeleteAlert = false
    @State private var errorMessage = ""
    @State private var showErrorAlert = false

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

            if isLoading && vehicles.isEmpty {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .primaryGold))
                    .scaleEffect(1.2)
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

                    Text("Add your vehicles to speed up appointment scheduling, track diagnostic records, and view service history.")
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
                    LazyVStack(spacing: 12) {
                        ForEach(vehicles) { vehicle in
                            vehicleCard(vehicle)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 36)
                }
                .refreshable {
                    await loadVehicles()
                }
            }
        }
        .background(Color.bgDark.ignoresSafeArea())
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .hideBottomDockOnPush()
        .task {
            await loadVehicles()
        }
        .sheet(isPresented: $showAddVehicleSheet) {
            AddVehicleSheet(onVehicleAdded: {
                Task { await loadVehicles() }
            })
        }
        .sheet(item: $vehicleToEdit) { v in
            EditVehicleSheet(vehicle: v, onVehicleUpdated: {
                Task { await loadVehicles() }
            })
        }
        .alert("Remove Vehicle", isPresented: $showDeleteAlert) {
            Button("Remove Permanently", role: .destructive) {
                if let v = vehicleToDelete {
                    deleteVehicle(v)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let v = vehicleToDelete {
                Text("Are you sure you want to remove \(v.year) \(v.make) \(v.model) from your garage? This cannot be undone.")
            } else {
                Text("Are you sure you want to remove this vehicle?")
            }
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Vehicle Card
    private func vehicleCard(_ vehicle: Vehicle) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 14) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.primaryGoldTint)
                        .frame(width: 46, height: 46)
                    Image(systemName: "car.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.primaryGold)
                }

                // Info
                VStack(alignment: .leading, spacing: 3) {
                    Text("\(vehicle.year) \(vehicle.make) \(vehicle.model)")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.textForeground)
                        .lineLimit(1)

                    let plate = vehicle.registrationNumber?.isEmpty == false ? vehicle.registrationNumber! : "No Plate"
                    Text("Plate: \(plate)")
                        .font(.system(size: 12))
                        .foregroundColor(.textMuted)
                }

                Spacer()

                // Actions: Edit & Delete
                HStack(spacing: 8) {
                    Button(action: {
                        vehicleToEdit = vehicle
                    }) {
                        Image(systemName: "pencil")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.primaryGold)
                            .frame(width: 34, height: 34)
                            .background(Color.primaryGoldTint)
                            .cornerRadius(8)
                    }

                    Button(action: {
                        vehicleToDelete = vehicle
                        showDeleteAlert = true
                    }) {
                        Image(systemName: "trash")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.statusCancelled)
                            .frame(width: 34, height: 34)
                            .background(Color.statusCancelled.opacity(0.12))
                            .cornerRadius(8)
                    }
                }
            }

            // Specs Chips: Mileage, Transmission, Fuel Type, Color
            HStack(spacing: 6) {
                if let mileage = vehicle.mileage, mileage > 0 {
                    specChip(icon: "speedometer", text: "\(mileage) mi")
                }
                if let trans = vehicle.transmission, !trans.isEmpty {
                    specChip(icon: "gearshape.2.fill", text: trans)
                }
                if let fuel = vehicle.fuelType, !fuel.isEmpty {
                    specChip(icon: "fuelpump.fill", text: fuel)
                }
                if let color = vehicle.color, !color.isEmpty {
                    specChip(icon: "paintpalette.fill", text: color)
                }
            }

            if let notes = vehicle.notes, !notes.isEmpty {
                Text(notes)
                    .font(.system(size: 11))
                    .foregroundColor(.textSubtle)
                    .lineLimit(2)
                    .padding(.top, 2)
            }
        }
        .padding(14)
        .luxuryCard()
    }

    private func specChip(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 9))
                .foregroundColor(.primaryGold)
            Text(text)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.textMuted)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(Color.cardDarkElevated)
        .cornerRadius(6)
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
            do {
                _ = try await APIService.shared.deleteVehicle(id: vehicle.id)
                await loadVehicles()
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    showErrorAlert = true
                }
            }
        }
    }
}

// MARK: - Add Vehicle Sheet
struct AddVehicleSheet: View {
    @Environment(\.dismiss) var dismiss
    var onVehicleAdded: () -> Void

    @State private var make = ""
    @State private var model = ""
    @State private var yearText = "2024"
    @State private var plate = ""
    @State private var color = ""
    @State private var mileageText = ""
    @State private var transmission = "Automatic"
    @State private var fuelType = "Gasoline"
    @State private var notes = ""
    @State private var isSaving = false
    @State private var errorMessage = ""

    private let transmissions = ["Automatic", "Manual", "Dual-Clutch", "Electric"]
    private let fuelTypes = ["Gasoline", "Diesel", "Hybrid", "Electric"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Add Vehicle to Garage")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.textForeground)
                        .padding(.top, 4)

                    Text("Enter specifications for accurate workshop inspections and booking.")
                        .font(.system(size: 12))
                        .foregroundColor(.textMuted)

                    // Make & Model
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Make *")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.textForeground)
                            TextField("e.g. BMW, Toyota", text: $make)
                                .textFieldStyle(DarkInputFieldStyle())
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Model *")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.textForeground)
                            TextField("e.g. M3, Camry", text: $model)
                                .textFieldStyle(DarkInputFieldStyle())
                        }
                    }

                    // Year & License Plate
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Year *")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.textForeground)
                            TextField("2024", text: $yearText)
                                .textFieldStyle(DarkInputFieldStyle())
                                .keyboardType(.numberPad)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("License Plate")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.textForeground)
                            TextField("e.g. ABC-1234", text: $plate)
                                .textFieldStyle(DarkInputFieldStyle())
                                #if os(iOS)
                                .textInputAutocapitalization(.characters)
                                #endif
                        }
                    }

                    // Mileage & Color
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Mileage (miles)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.textForeground)
                            TextField("e.g. 25000", text: $mileageText)
                                .textFieldStyle(DarkInputFieldStyle())
                                .keyboardType(.numberPad)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Color")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.textForeground)
                            TextField("e.g. Midnight Black", text: $color)
                                .textFieldStyle(DarkInputFieldStyle())
                        }
                    }

                    // Transmission Selector
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Transmission")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.textForeground)

                        HStack(spacing: 8) {
                            ForEach(transmissions, id: \.self) { t in
                                Button(action: { transmission = t }) {
                                    Text(t)
                                        .font(.system(size: 11, weight: transmission == t ? .bold : .medium))
                                        .foregroundColor(transmission == t ? .bgDark : .textForeground)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 34)
                                        .background(transmission == t ? Color.primaryGold : Color.cardDarkElevated)
                                        .cornerRadius(6)
                                }
                            }
                        }
                    }

                    // Fuel Type Selector
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Fuel Type")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.textForeground)

                        HStack(spacing: 8) {
                            ForEach(fuelTypes, id: \.self) { f in
                                Button(action: { fuelType = f }) {
                                    Text(f)
                                        .font(.system(size: 11, weight: fuelType == f ? .bold : .medium))
                                        .foregroundColor(fuelType == f ? .bgDark : .textForeground)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 34)
                                        .background(fuelType == f ? Color.primaryGold : Color.cardDarkElevated)
                                        .cornerRadius(6)
                                }
                            }
                        }
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Vehicle Notes (Optional)")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.textForeground)
                        TextField("e.g. Track edition, custom exhaust", text: $notes)
                            .textFieldStyle(DarkInputFieldStyle())
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
                            Text("Save Vehicle to Garage")
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

        let year = Int(yearText) ?? 2024
        let trimmedPlate = plate.trimmingCharacters(in: .whitespaces).isEmpty ? nil : plate.trimmingCharacters(in: .whitespaces)
        let mileage = Int(mileageText.trimmingCharacters(in: .whitespaces))
        let trimmedColor = color.trimmingCharacters(in: .whitespaces).isEmpty ? nil : color.trimmingCharacters(in: .whitespaces)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces)

        isSaving = true
        errorMessage = ""

        Task {
            do {
                let req = CreateVehicleRequest(
                    make: trimmedMake,
                    model: trimmedModel,
                    year: year,
                    registrationNumber: trimmedPlate,
                    mileage: mileage,
                    fuelType: fuelType,
                    transmission: transmission,
                    color: trimmedColor,
                    vehicleType: "CAR",
                    notes: trimmedNotes
                )
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

// MARK: - Edit Vehicle Sheet (PATCH /vehicles/{id})
struct EditVehicleSheet: View {
    @Environment(\.dismiss) var dismiss
    let vehicle: Vehicle
    var onVehicleUpdated: () -> Void

    @State private var make: String = ""
    @State private var model: String = ""
    @State private var yearText: String = ""
    @State private var plate: String = ""
    @State private var color: String = ""
    @State private var mileageText: String = ""
    @State private var transmission: String = "Automatic"
    @State private var fuelType: String = "Gasoline"
    @State private var notes: String = ""
    @State private var isSaving: Bool = false
    @State private var errorMessage: String = ""

    private let transmissions = ["Automatic", "Manual", "Dual-Clutch", "Electric"]
    private let fuelTypes = ["Gasoline", "Diesel", "Hybrid", "Electric"]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Edit Vehicle Specifications")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.textForeground)
                        .padding(.top, 4)

                    Text("Update odometer readings, color, license plate or inspection notes.")
                        .font(.system(size: 12))
                        .foregroundColor(.textMuted)

                    // Make & Model
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Make")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.textForeground)
                            TextField("Make", text: $make)
                                .textFieldStyle(DarkInputFieldStyle())
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Model")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.textForeground)
                            TextField("Model", text: $model)
                                .textFieldStyle(DarkInputFieldStyle())
                        }
                    }

                    // Year & Plate
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Year")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.textForeground)
                            TextField("Year", text: $yearText)
                                .textFieldStyle(DarkInputFieldStyle())
                                .keyboardType(.numberPad)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("License Plate")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.textForeground)
                            TextField("Plate", text: $plate)
                                .textFieldStyle(DarkInputFieldStyle())
                                #if os(iOS)
                                .textInputAutocapitalization(.characters)
                                #endif
                        }
                    }

                    // Mileage & Color
                    HStack(spacing: 12) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Odometer Mileage (mi)")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.textForeground)
                            TextField("e.g. 28000", text: $mileageText)
                                .textFieldStyle(DarkInputFieldStyle())
                                .keyboardType(.numberPad)
                        }

                        VStack(alignment: .leading, spacing: 6) {
                            Text("Color")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.textForeground)
                            TextField("Color", text: $color)
                                .textFieldStyle(DarkInputFieldStyle())
                        }
                    }

                    // Transmission
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Transmission")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.textForeground)

                        HStack(spacing: 8) {
                            ForEach(transmissions, id: \.self) { t in
                                Button(action: { transmission = t }) {
                                    Text(t)
                                        .font(.system(size: 11, weight: transmission == t ? .bold : .medium))
                                        .foregroundColor(transmission == t ? .bgDark : .textForeground)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 34)
                                        .background(transmission == t ? Color.primaryGold : Color.cardDarkElevated)
                                        .cornerRadius(6)
                                }
                            }
                        }
                    }

                    // Fuel Type
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Fuel Type")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.textForeground)

                        HStack(spacing: 8) {
                            ForEach(fuelTypes, id: \.self) { f in
                                Button(action: { fuelType = f }) {
                                    Text(f)
                                        .font(.system(size: 11, weight: fuelType == f ? .bold : .medium))
                                        .foregroundColor(fuelType == f ? .bgDark : .textForeground)
                                        .frame(maxWidth: .infinity)
                                        .frame(height: 34)
                                        .background(fuelType == f ? Color.primaryGold : Color.cardDarkElevated)
                                        .cornerRadius(6)
                                }
                            }
                        }
                    }

                    // Notes
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Notes")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.textForeground)
                        TextField("Vehicle notes", text: $notes)
                            .textFieldStyle(DarkInputFieldStyle())
                    }

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.system(size: 12))
                            .foregroundColor(.statusCancelled)
                    }

                    // Submit Update Button
                    Button(action: performUpdate) {
                        if isSaving {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .bgDark))
                        } else {
                            Text("Update Vehicle Specs")
                        }
                    }
                    .buttonStyle(GoldButtonStyle(isEnabled: !isSaving))
                    .disabled(isSaving)
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
            .onAppear {
                make = vehicle.make
                model = vehicle.model
                yearText = "\(vehicle.year)"
                plate = vehicle.registrationNumber ?? ""
                color = vehicle.color ?? ""
                if let m = vehicle.mileage {
                    mileageText = "\(m)"
                }
                if let t = vehicle.transmission, !t.isEmpty {
                    transmission = t
                }
                if let f = vehicle.fuelType, !f.isEmpty {
                    fuelType = f
                }
                notes = vehicle.notes ?? ""
            }
        }
    }

    private func performUpdate() {
        isSaving = true
        errorMessage = ""

        let year = Int(yearText.trimmingCharacters(in: .whitespaces))
        let mileage = Int(mileageText.trimmingCharacters(in: .whitespaces))
        let trimmedPlate = plate.trimmingCharacters(in: .whitespaces).isEmpty ? nil : plate.trimmingCharacters(in: .whitespaces)
        let trimmedColor = color.trimmingCharacters(in: .whitespaces).isEmpty ? nil : color.trimmingCharacters(in: .whitespaces)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces)

        let req = UpdateVehicleRequest(
            make: make.trimmingCharacters(in: .whitespaces).isEmpty ? nil : make.trimmingCharacters(in: .whitespaces),
            model: model.trimmingCharacters(in: .whitespaces).isEmpty ? nil : model.trimmingCharacters(in: .whitespaces),
            year: year,
            registrationNumber: trimmedPlate,
            mileage: mileage,
            fuelType: fuelType,
            transmission: transmission,
            color: trimmedColor,
            notes: trimmedNotes
        )

        Task {
            do {
                let resp = try await APIService.shared.updateVehicle(id: vehicle.id, req)
                await MainActor.run {
                    isSaving = false
                    if resp.success == true || resp.data != nil {
                        onVehicleUpdated()
                        dismiss()
                    } else {
                        errorMessage = resp.message ?? "Failed to update vehicle"
                    }
                }
            } catch {
                await MainActor.run {
                    isSaving = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}
