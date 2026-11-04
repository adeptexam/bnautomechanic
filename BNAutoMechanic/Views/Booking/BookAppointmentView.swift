//
//  BookAppointmentView.swift
//  BNAutoMechanic
//
//  Pixel-perfect replica of Android BookAppointmentActivity 5-step wizard
//

import SwiftUI

struct BookAppointmentView: View {
    var preselectedServiceId: Int? = nil
    @Environment(\.dismiss) var dismiss

    // Wizard step 1 to 5
    @State private var currentStep = 1
    private let totalSteps = 5

    // Step 1: Vehicle
    @State private var vehicles: [Vehicle] = []
    @State private var selectedVehicleId: Int? = nil
    @State private var make = ""
    @State private var model = ""
    @State private var yearText = "2023"
    @State private var plate = ""

    // Step 2: Services
    @State private var allServices: [Service] = []
    @State private var selectedServiceIds: Set<Int> = []

    // Step 3: Date & Time (Real-Time Backend Bay Slot Sync)
    @State private var selectedDate: Date = {
        let calendar = Calendar.current
        var target = calendar.date(byAdding: .day, value: 1, to: Date()) ?? Date()
        if calendar.component(.weekday, from: target) == 1 { // Skip Sunday default
            target = calendar.date(byAdding: .day, value: 1, to: target) ?? target
        }
        return target
    }()
    @State private var selectedSlot: AvailabilitySlot? = nil
    @State private var availabilitySlots: [AvailabilitySlot] = []
    @State private var isLoadingSlots: Bool = false
    @State private var availabilityError: String? = nil
    @State private var isWorkshopClosedOnDate: Bool = false

    // Step 4: Notes & Promo
    @State private var notes = ""
    @State private var couponCode = ""

    // State
    @State private var isLoading = false
    @State private var isSubmitting = false
    @State private var bookingSuccessRef: String? = nil
    @State private var errorMessage = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Button(action: {
                    if currentStep > 1 {
                        withAnimation { currentStep -= 1 }
                    } else {
                        dismiss()
                    }
                }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textForeground)
                        .frame(width: 38, height: 38)
                        .background(Color.cardDarkElevated)
                        .cornerRadius(10)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Schedule Service")
                        .font(.system(size: 17, weight: .bold))
                        .foregroundColor(.textForeground)

                    Text("Step \(currentStep) of \(totalSteps): \(stepTitle)")
                        .font(.system(size: 11))
                        .foregroundColor(.primaryGold)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            // Step Progress Bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .fill(Color.borderSubtle)
                        .frame(height: 3)

                    Rectangle()
                        .fill(Color.primaryGold)
                        .frame(width: geo.size.width * CGFloat(currentStep) / CGFloat(totalSteps), height: 3)
                }
            }
            .frame(height: 3)

            if let ref = bookingSuccessRef {
                successView(ref: ref)
            } else {
                // Wizard Body
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        switch currentStep {
                        case 1: step1VehicleView
                        case 2: step2ServicesView
                        case 3: step3DateTimeView
                        case 4: step4NotesView
                        case 5: step5ReviewView
                        default: EmptyView()
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 24)
                }

                // Bottom Action Bar
                VStack(spacing: 0) {
                    Divider().background(Color.borderSubtle)

                    if !errorMessage.isEmpty {
                        Text(errorMessage)
                            .font(.system(size: 12))
                            .foregroundColor(.statusCancelled)
                            .padding(.horizontal, 16)
                            .padding(.top, 8)
                    }

                    HStack(spacing: 12) {
                        if currentStep > 1 {
                            Button(action: { withAnimation { currentStep -= 1 } }) {
                                Text("Previous")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.textForeground)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(Color.borderMedium, lineWidth: 1)
                                    )
                            }
                        }

                        Button(action: handleNextStep) {
                            if isSubmitting {
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle(tint: .bgDark))
                            } else {
                                Text(currentStep == totalSteps ? "Confirm Appointment" : "Continue")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.bgDark)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 48)
                                    .background(Color.primaryGold)
                                    .cornerRadius(10)
                            }
                        }
                        .disabled(isSubmitting)
                    }
                    .padding(16)
                }
                .background(Color.surfaceDark)
            }
        }
        .background(Color.bgDark.ignoresSafeArea())
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .hideBottomDockOnPush()
        .task {
            await loadInitialData()
        }
    }

    private var stepTitle: String {
        switch currentStep {
        case 1: return "Vehicle Selection"
        case 2: return "Service Selection"
        case 3: return "Date & Arrival Slot"
        case 4: return "Service Notes"
        case 5: return "Review & Confirmation"
        default: return ""
        }
    }

    // MARK: - Step 1: Vehicle
    private var step1VehicleView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Select or Enter Your Vehicle")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.textForeground)

            if !vehicles.isEmpty {
                Text("Select from your garage:")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.textMuted)

                ForEach(vehicles) { v in
                    Button(action: {
                        selectedVehicleId = v.id
                        make = v.make
                        model = v.model
                        yearText = "\(v.year)"
                        plate = v.registrationNumber ?? ""
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: selectedVehicleId == v.id ? "checkmark.circle.fill" : "circle")
                                .foregroundColor(selectedVehicleId == v.id ? .primaryGold : .textSubtle)

                            VStack(alignment: .leading, spacing: 2) {
                                Text("\(v.year) \(v.make) \(v.model)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.textForeground)
                                Text("Plate: \(v.registrationNumber ?? "None")")
                                    .font(.system(size: 11))
                                    .foregroundColor(.textMuted)
                            }
                            Spacer()
                        }
                        .padding(14)
                        .background(selectedVehicleId == v.id ? Color.primaryGoldTint : Color.cardDark)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(selectedVehicleId == v.id ? Color.primaryGold : Color.borderSubtle, lineWidth: 1)
                        )
                    }
                }

                HStack {
                    Rectangle().fill(Color.borderSubtle).frame(height: 1)
                    Text("or enter manually")
                        .font(.system(size: 11))
                        .foregroundColor(.textSubtle)
                    Rectangle().fill(Color.borderSubtle).frame(height: 1)
                }
                .padding(.vertical, 4)
            }

            VStack(alignment: .leading, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Make *")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.textForeground)
                    TextField("e.g. BMW, Toyota", text: $make)
                        .textFieldStyle(DarkInputFieldStyle())
                        .onChange(of: make) { _ in selectedVehicleId = nil }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Model *")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.textForeground)
                    TextField("e.g. 330i, Camry", text: $model)
                        .textFieldStyle(DarkInputFieldStyle())
                        .onChange(of: model) { _ in selectedVehicleId = nil }
                }

                HStack(spacing: 12) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Year *")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.textForeground)
                        TextField("2022", text: $yearText)
                            .textFieldStyle(DarkInputFieldStyle())
                            .keyboardType(.numberPad)
                    }

                    VStack(alignment: .leading, spacing: 6) {
                        Text("License Plate")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.textForeground)
                        TextField("ABC-1234", text: $plate)
                            .textFieldStyle(DarkInputFieldStyle())
                            #if os(iOS)
                            .textInputAutocapitalization(.characters)
                            #endif
                    }
                }
            }
        }
    }

    // MARK: - Step 2: Services
    private var step2ServicesView: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Select Required Services")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.textForeground)

            Text("Select one or more services to be performed during this workshop visit.")
                .font(.system(size: 12))
                .foregroundColor(.textMuted)

            if isLoading {
                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .primaryGold))
            } else {
                ForEach(allServices) { service in
                    let isSelected = selectedServiceIds.contains(service.id)
                    Button(action: {
                        if isSelected {
                            selectedServiceIds.remove(service.id)
                        } else {
                            selectedServiceIds.insert(service.id)
                        }
                    }) {
                        HStack(spacing: 12) {
                            Image(systemName: isSelected ? "checkmark.square.fill" : "square")
                                .font(.system(size: 18))
                                .foregroundColor(isSelected ? .primaryGold : .textSubtle)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(service.name)
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.textForeground)
                                    .lineLimit(1)

                                HStack(spacing: 6) {
                                    Text(service.formattedDuration())
                                        .font(.system(size: 11))
                                        .foregroundColor(.textMuted)
                                    Text("•")
                                        .foregroundColor(.textSubtle)
                                    Text(service.category?.name ?? "Service")
                                        .font(.system(size: 11))
                                        .foregroundColor(.textMuted)
                                }
                            }

                            Spacer()

                            Text(service.formattedPrice())
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.primaryGold)
                        }
                        .padding(14)
                        .background(isSelected ? Color.primaryGoldTint : Color.cardDark)
                        .cornerRadius(10)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(isSelected ? Color.primaryGold : Color.borderSubtle, lineWidth: 1)
                        )
                    }
                }
            }
        }
    }

    // MARK: - Step 3: Date & Time (Real-Time Backend Bay Slot Sync)
    private var step3DateTimeView: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header
            VStack(alignment: .leading, spacing: 4) {
                Text("Choose Appointment Date")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.textForeground)

                Text("Select your preferred service date to check live bay availability at our Ewing workshop.")
                    .font(.system(size: 12))
                    .foregroundColor(.textMuted)
            }

            // Calendar Picker
            DatePicker("Scheduled Date", selection: $selectedDate, in: Date()..., displayedComponents: .date)
                .datePickerStyle(.graphical)
                .accentColor(.primaryGold)
                .padding(10)
                .luxuryCard()
                .onChange(of: selectedDate) { newDate in
                    Task {
                        await loadAvailability(for: newDate)
                    }
                }

            // Arrival Slot Header with live sync indicator
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Select Arrival Slot")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.textForeground)

                    Text(formattedSelectedDateHeader)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.primaryGold)
                }

                Spacer()

                if isLoadingSlots {
                    HStack(spacing: 6) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .primaryGold))
                            .scaleEffect(0.7)
                        Text("Syncing bays...")
                            .font(.system(size: 11))
                            .foregroundColor(.textMuted)
                    }
                } else if !isWorkshopClosedOnDate {
                    HStack(spacing: 5) {
                        Circle()
                            .fill(Color.statusCompleted)
                            .frame(width: 6, height: 6)
                        Text("Live Bay Capacity")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.statusCompleted)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.statusCompleted.opacity(0.12))
                    .cornerRadius(6)
                }
            }
            .padding(.top, 4)

            // Dynamic Slot States
            if isLoadingSlots && availabilitySlots.isEmpty {
                VStack(spacing: 12) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .primaryGold))
                    Text("Checking workshop bay availability with server...")
                        .font(.system(size: 12))
                        .foregroundColor(.textMuted)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 28)
                .luxuryCard()
            } else if isWorkshopClosedOnDate {
                workshopClosedBanner
            } else {
                slotsGridView
            }

            if let err = availabilityError {
                HStack(spacing: 8) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.primaryGold)
                    Text(err)
                        .font(.system(size: 11))
                        .foregroundColor(.textMuted)
                    Spacer()
                    Button("Retry") {
                        Task { await loadAvailability(for: selectedDate) }
                    }
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.primaryGold)
                }
                .padding(10)
                .background(Color.cardDarkElevated)
                .cornerRadius(8)
            }
        }
    }

    // MARK: - Workshop Closed or Fully Booked Card
    private var workshopClosedBanner: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 38))
                .foregroundColor(.primaryGold)

            Text("No Arrival Slots Available")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.textForeground)

            let isSunday = Calendar.current.component(.weekday, from: selectedDate) == 1
            Text(isSunday
                 ? "Our workshop bays are closed on Sundays for scheduled repairs. Emergency 24/7 towing remains available."
                 : "All technician bays are at maximum capacity on this date. Please select another date from the calendar.")
                .font(.system(size: 12))
                .foregroundColor(.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16)

            Button(action: jumpToNextOpenWeekday) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.forward.circle.fill")
                        .font(.system(size: 13))
                    Text("Jump to Next Available Day")
                        .font(.system(size: 12, weight: .bold))
                }
                .foregroundColor(.bgDark)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color.primaryGold)
                .cornerRadius(8)
            }
            .padding(.top, 4)
        }
        .frame(maxWidth: .infinity)
        .padding(20)
        .luxuryCard()
    }

    // MARK: - Live Slots Grid
    private var slotsGridView: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            ForEach(availabilitySlots) { slot in
                let isBookable = slot.isBookable(on: selectedDate)
                let isSelected = selectedSlot?.time == slot.time

                Button(action: {
                    if isBookable {
                        selectedSlot = slot
                        errorMessage = ""
                    }
                }) {
                    HStack(spacing: 8) {
                        VStack(alignment: .leading, spacing: 3) {
                            Text(slot.displayTime)
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(
                                    !isBookable
                                        ? Color.textSubtle
                                        : (isSelected ? Color.bgDark : Color.textForeground)
                                )

                            HStack(spacing: 4) {
                                if !isBookable {
                                    Image(systemName: "lock.fill")
                                        .font(.system(size: 8))
                                    Text(slot.isPastTime(on: selectedDate) ? "Passed" : "Fully Booked")
                                        .font(.system(size: 9, weight: .medium))
                                } else if let rem = slot.remaining, rem == 1 {
                                    Circle()
                                        .fill(isSelected ? Color.bgDark : Color.primaryGold)
                                        .frame(width: 5, height: 5)
                                    Text("1 bay left")
                                        .font(.system(size: 9, weight: .bold))
                                } else {
                                    Circle()
                                        .fill(isSelected ? Color.bgDark : Color.statusCompleted)
                                        .frame(width: 5, height: 5)
                                    Text("\(slot.remaining ?? 3) bays open")
                                        .font(.system(size: 9))
                                }
                            }
                            .foregroundColor(
                                !isBookable
                                    ? Color.textSubtle.opacity(0.8)
                                    : (isSelected ? Color.bgDark.opacity(0.85) : (slot.remaining == 1 ? Color.primaryGold : Color.statusCompleted))
                            )
                        }

                        Spacer()

                        if isSelected {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.bgDark)
                        } else if !isBookable {
                            Image(systemName: "nosign")
                                .font(.system(size: 13))
                                .foregroundColor(.textSubtle.opacity(0.5))
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        !isBookable
                            ? Color.cardDark.opacity(0.4)
                            : (isSelected ? Color.primaryGold : Color.cardDarkElevated)
                    )
                    .cornerRadius(8)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(
                                !isBookable
                                    ? Color.borderSubtle.opacity(0.3)
                                    : (isSelected ? Color.primaryGold : Color.borderSubtle),
                                lineWidth: isSelected ? 1.5 : 1
                            )
                    )
                }
                .disabled(!isBookable)
            }
        }
    }

    // MARK: - Step 4: Notes & Promo
    private var step4NotesView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Service Notes & Symptoms")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.textForeground)

            Text("Describe any specific issues, symptoms, warning lights, or instructions for our technicians.")
                .font(.system(size: 12))
                .foregroundColor(.textMuted)

            TextEditor(text: $notes)
                .frame(height: 120)
                .padding(10)
                .background(Color.surfaceDark)
                .cornerRadius(10)
                .foregroundColor(.textForeground)
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.borderMedium, lineWidth: 1)
                )

            Text("Promotional Code (Optional)")
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.textForeground)
                .padding(.top, 8)

            TextField("e.g. OIL15, BRAKE20", text: $couponCode)
                .textFieldStyle(DarkInputFieldStyle())
                #if os(iOS)
                .textInputAutocapitalization(.characters)
                #endif
        }
    }

    // MARK: - Step 5: Review
    private var step5ReviewView: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Review Your Appointment")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.textForeground)

            // Vehicle summary
            VStack(alignment: .leading, spacing: 8) {
                Label("VEHICLE", systemImage: "car.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.primaryGold)
                Text("\(yearText) \(make) \(model)")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.textForeground)
                if !plate.isEmpty {
                    Text("Plate: \(plate)")
                        .font(.system(size: 12))
                        .foregroundColor(.textMuted)
                }
            }
            .padding(14)
            .luxuryCard()

            // Date / Time summary
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Label("APPOINTMENT TIME", systemImage: "calendar")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.primaryGold)

                    Spacer()

                    if let slot = selectedSlot {
                        Text(slot.statusBadgeText)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.statusCompleted)
                            .padding(.horizontal, 7)
                            .padding(.vertical, 2)
                            .background(Color.statusCompleted.opacity(0.12))
                            .cornerRadius(4)
                    }
                }

                let formatter = DateFormatter()
                let _ = { formatter.dateStyle = .medium }()
                Text("\(formatter.string(from: selectedDate))  •  \(selectedSlot?.displayTime ?? "Select Slot")")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.textForeground)

                Text("Bay Arrival Window: \(selectedSlot?.time ?? "--:--") (1200 Parkway Ave, Ewing NJ)")
                    .font(.system(size: 11))
                    .foregroundColor(.textMuted)
            }
            .padding(14)
            .luxuryCard()

            // Services list summary
            VStack(alignment: .leading, spacing: 8) {
                Label("SELECTED SERVICES", systemImage: "wrench.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.primaryGold)

                let chosen = allServices.filter { selectedServiceIds.contains($0.id) }
                ForEach(chosen) { s in
                    HStack {
                        Text("• \(s.name)")
                            .font(.system(size: 13))
                            .foregroundColor(.textForeground)
                        Spacer()
                        Text(s.formattedPrice())
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.primaryGold)
                    }
                }
            }
            .padding(14)
            .luxuryCard()

            if !notes.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("NOTES")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.textSubtle)
                    Text(notes)
                        .font(.system(size: 13))
                        .foregroundColor(.textMuted)
                }
                .padding(14)
                .luxuryCard()
            }
        }
    }

    // MARK: - Success View
    private func successView(ref: String) -> some View {
        VStack(spacing: 16) {
            Spacer()

            ZStack {
                Circle()
                    .fill(Color.statusCompleted.opacity(0.15))
                    .frame(width: 80, height: 80)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 50))
                    .foregroundColor(.statusCompleted)
            }

            Text("Appointment Scheduled!")
                .font(.system(size: 22, weight: .bold))
                .foregroundColor(.textForeground)

            Text("Booking Reference:")
                .font(.system(size: 13))
                .foregroundColor(.textMuted)

            Text(ref)
                .font(.system(size: 18, weight: .black))
                .foregroundColor(.primaryGold)
                .tracking(2)
                .padding(.horizontal, 20)
                .padding(.vertical, 8)
                .background(Color.primaryGoldTint)
                .cornerRadius(8)

            Text("A service advisor will review your vehicle requirements and assign certified workshop technicians.")
                .font(.system(size: 13))
                .foregroundColor(.textMuted)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 8)

            Spacer()

            Button(action: { dismiss() }) {
                Text("Done")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.bgDark)
                    .frame(maxWidth: .infinity)
                    .frame(height: 50)
                    .background(Color.primaryGold)
                    .cornerRadius(10)
            }
            .padding(16)
        }
    }

    // MARK: - Step Validation and Next
    private func handleNextStep() {
        errorMessage = ""
        switch currentStep {
        case 1:
            if selectedVehicleId == nil && (make.trimmingCharacters(in: .whitespaces).isEmpty || model.trimmingCharacters(in: .whitespaces).isEmpty) {
                errorMessage = "Please select or enter your vehicle make and model."
                return
            }
            withAnimation { currentStep = 2 }

        case 2:
            if selectedServiceIds.isEmpty {
                errorMessage = "Please select at least one service."
                return
            }
            Task { await loadAvailability(for: selectedDate) }
            withAnimation { currentStep = 3 }

        case 3:
            if isWorkshopClosedOnDate {
                errorMessage = "The workshop is closed or fully booked on this date. Please pick another date above."
                return
            }
            guard let slot = selectedSlot, slot.isBookable(on: selectedDate) else {
                errorMessage = "Please select an available workshop arrival slot."
                return
            }
            withAnimation { currentStep = 4 }

        case 4:
            withAnimation { currentStep = 5 }

        case 5:
            submitBooking()

        default: break
        }
    }

    private func submitBooking() {
        guard let slot = selectedSlot else {
            errorMessage = "Please select an available workshop arrival slot."
            return
        }

        isSubmitting = true
        errorMessage = ""

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let dateString = formatter.string(from: selectedDate)

        let vehicleReq = selectedVehicleId == nil ? CreateVehicleRequest(
            make: make.trimmingCharacters(in: .whitespaces),
            model: model.trimmingCharacters(in: .whitespaces),
            year: Int(yearText) ?? 2023,
            registrationNumber: plate.trimmingCharacters(in: .whitespaces).isEmpty ? nil : plate.trimmingCharacters(in: .whitespaces),
            vehicleType: nil
        ) : nil

        let req = CreateBookingRequest(
            serviceIds: Array(selectedServiceIds),
            vehicleId: selectedVehicleId,
            vehicle: vehicleReq,
            scheduledDate: dateString,
            scheduledTime: slot.time, // Exact 24-hr format synchronized with backend (e.g. "08:30", "10:30")
            notes: notes.trimmingCharacters(in: .whitespaces).isEmpty ? nil : notes.trimmingCharacters(in: .whitespaces),
            couponCode: couponCode.trimmingCharacters(in: .whitespaces).isEmpty ? nil : couponCode.trimmingCharacters(in: .whitespaces)
        )

        Task {
            do {
                let response = try await APIService.shared.createBooking(req)
                await MainActor.run {
                    isSubmitting = false
                    if let booking = response.data {
                        bookingSuccessRef = booking.reference
                    } else {
                        errorMessage = response.message ?? "Could not schedule appointment. Please try again."
                    }
                }
            } catch {
                await MainActor.run {
                    isSubmitting = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }

    private func loadInitialData() async {
        isLoading = true
        // Vehicles
        if let vResp = try? await APIService.shared.getVehicles() {
            let vList = vResp.data?.items ?? []
            await MainActor.run {
                vehicles = vList
                if let first = vList.first {
                    selectedVehicleId = first.id
                    make = first.make
                    model = first.model
                    yearText = "\(first.year)"
                    plate = first.registrationNumber ?? ""
                }
            }
        }

        // Services
        if let sResp = try? await APIService.shared.getServices(perPage: 50) {
            let sList = sResp.data?.items ?? []
            await MainActor.run {
                allServices = sList
                if let pre = preselectedServiceId {
                    selectedServiceIds = [pre]
                } else if let first = sList.first {
                    selectedServiceIds = [first.id]
                }
            }
        }

        // Live availability for default selected date
        await loadAvailability(for: selectedDate)

        await MainActor.run { isLoading = false }
    }

    // MARK: - Backend Slot Availability Sync (GET /bookings/availability?date=YYYY-MM-DD)
    private func loadAvailability(for date: Date) async {
        await MainActor.run {
            isLoadingSlots = true
            availabilityError = nil
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        let dateString = formatter.string(from: date)

        let isSunday = Calendar.current.component(.weekday, from: date) == 1

        do {
            let resp = try await APIService.shared.getAvailability(
                date: dateString,
                serviceId: selectedServiceIds.first
            )

            await MainActor.run {
                isLoadingSlots = false
                if let avail = resp.data {
                    let fetchedSlots = avail.allSlots
                    if fetchedSlots.isEmpty {
                        useFallbackSlots(for: date, isSunday: isSunday)
                    } else {
                        self.availabilitySlots = fetchedSlots
                        self.isWorkshopClosedOnDate = isSunday || fetchedSlots.allSatisfy { !$0.isBookable(on: date) }
                        reconcileSelectedSlot(for: date)
                    }
                } else {
                    useFallbackSlots(for: date, isSunday: isSunday)
                }
            }
        } catch {
            await MainActor.run {
                isLoadingSlots = false
                availabilityError = "Could not reach live schedule. Standard slots loaded."
                useFallbackSlots(for: date, isSunday: isSunday)
            }
        }
    }

    private func useFallbackSlots(for date: Date, isSunday: Bool) {
        let standardTimes = ["08:30", "09:30", "10:30", "11:30", "13:00", "14:00", "15:00", "16:00"]
        let slots = standardTimes.map { time in
            AvailabilitySlot(
                time: time,
                available: !isSunday,
                remaining: isSunday ? 0 : 3
            )
        }
        self.availabilitySlots = slots
        self.isWorkshopClosedOnDate = isSunday || slots.allSatisfy { !$0.isBookable(on: date) }
        reconcileSelectedSlot(for: date)
    }

    private func reconcileSelectedSlot(for date: Date) {
        // If currently chosen slot is still available, keep it
        if let current = selectedSlot,
           let updated = availabilitySlots.first(where: { $0.time == current.time }),
           updated.isBookable(on: date) {
            selectedSlot = updated
            return
        }

        // Auto-select the first bookable slot for convenience
        if let first = availabilitySlots.first(where: { $0.isBookable(on: date) }) {
            selectedSlot = first
        } else {
            selectedSlot = nil
        }
    }

    private func jumpToNextOpenWeekday() {
        var nextDate = selectedDate
        let calendar = Calendar.current
        for _ in 1...7 {
            if let candidate = calendar.date(byAdding: .day, value: 1, to: nextDate) {
                let weekday = calendar.component(.weekday, from: candidate)
                if weekday != 1 { // Not Sunday
                    selectedDate = candidate
                    Task { await loadAvailability(for: candidate) }
                    break
                }
                nextDate = candidate
            }
        }
    }

    private var formattedSelectedDateHeader: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMMM d, yyyy"
        return formatter.string(from: selectedDate)
    }
}
