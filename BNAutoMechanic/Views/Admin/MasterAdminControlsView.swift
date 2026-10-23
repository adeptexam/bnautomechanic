//
//  MasterAdminControlsView.swift
//  BNAutoMechanic
//
//  Superadmin Master Administrative Controls: Platform Configuration,
//  Maintenance Controls, Emergency Towing Hotline, Payment Gateways & Operating Hours.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct MasterAdminControlsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var session: SessionManager

    // Workshop Identity & Contact
    @State private var siteName: String = ""
    @State private var tagline: String = ""
    @State private var phone: String = ""
    @State private var secondaryPhone: String = ""
    @State private var email: String = ""
    @State private var address: String = ""
    @State private var mapUrl: String = ""

    // Maintenance & System Protection
    @State private var maintenanceMode: Bool = false
    @State private var maintenanceMessage: String = ""
    @State private var maintenanceUntil: String = ""

    // Financial & Tax Settings
    @State private var currency: String = "USD"
    @State private var currencySymbol: String = "$"
    @State private var taxRate: String = "0.0"

    // Payment Gateway Configuration
    @State private var onlinePaymentEnabled: Bool = false
    @State private var squareMode: String = "sandbox"
    @State private var squareAppId: String = ""
    @State private var squareLocationId: String = ""
    @State private var squareAccessToken: String = ""

    // Alternate Payment Methods
    @State private var payCashEnabled: Bool = true
    @State private var cashInstructions: String = ""
    @State private var payBankTransferEnabled: Bool = false
    @State private var bankName: String = ""
    @State private var bankAccountName: String = ""
    @State private var bankAccountNumber: String = ""
    @State private var bankRoutingCode: String = ""

    // UI State
    @State private var isLoading: Bool = false
    @State private var isSaving: Bool = false
    @State private var showSuccessBanner: Bool = false
    @State private var statusMessage: String = ""
    @State private var showErrorAlert: Bool = false
    @State private var activeSection: Int = 0

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Banner
                headerBanner

                // Section Selector Tabs
                sectionSelector

                // Active Section Form Card
                Group {
                    switch activeSection {
                    case 0:
                        identitySection
                    case 1:
                        maintenanceSection
                    case 2:
                        paymentsSection
                    default:
                        identitySection
                    }
                }

                // Master Save Button
                saveControlsButton
            }
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 36)
        }
        .background(Color.bgDark.ignoresSafeArea())
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .refreshable {
            await loadAllSettings()
        }
        .task {
            await loadAllSettings()
        }
        .alert("System Notification", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(statusMessage)
        }
    }

    // MARK: - Header Banner
    private var headerBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.primaryGold.opacity(0.15))
                        .frame(width: 44, height: 44)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.primaryGold, lineWidth: 1.2)
                        )
                    Image(systemName: "shield.checkered")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primaryGold)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("MASTER ADMINISTRATIVE CONTROLS")
                        .font(.system(size: 13, weight: .black))
                        .foregroundColor(.primaryGold)
                        .tracking(1)

                    Text("System-Wide Governance & Platform Engine")
                        .font(.system(size: 11))
                        .foregroundColor(.textMuted)
                }

                Spacer()

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .primaryGold))
                        .scaleEffect(0.8)
                }
            }

            if showSuccessBanner {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.statusConfirmed)
                    Text(statusMessage)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.statusConfirmed)
                    Spacer()
                }
                .padding(10)
                .background(Color.statusConfirmed.opacity(0.12))
                .cornerRadius(8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
        .padding(16)
        .luxuryCard()
    }

    // MARK: - Section Selector
    private var sectionSelector: some View {
        HStack(spacing: 8) {
            selectorTabButton(title: "Identity & Contacts", icon: "building.2.fill", index: 0)
            selectorTabButton(title: "Maintenance & Mode", icon: "wrench.and.screwdriver.fill", index: 1)
            selectorTabButton(title: "Financial & Gateways", icon: "creditcard.fill", index: 2)
        }
    }

    private func selectorTabButton(title: String, icon: String, index: Int) -> some View {
        Button {
            triggerHaptic()
            withAnimation(.easeInOut(duration: 0.2)) {
                activeSection = index
            }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                Text(title)
                    .font(.system(size: 10, weight: activeSection == index ? .bold : .medium))
                    .lineLimit(1)
            }
            .foregroundColor(activeSection == index ? .bgDark : .textForeground)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .background(activeSection == index ? Color.primaryGold : Color.cardDarkElevated)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(activeSection == index ? Color.primaryGold : Color.borderSubtle, lineWidth: 1)
            )
        }
    }

    // MARK: - Identity & Contacts Section
    private var identitySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionTitle(title: "WORKSHOP IDENTITY", icon: "car.side.fill")

            adminTextField(label: "Platform / Workshop Name", text: $siteName, placeholder: "BN Auto Mechanic")
            adminTextField(label: "Tagline", text: $tagline, placeholder: "Premium Automotive Care")
            adminTextField(label: "Primary Phone", text: $phone, placeholder: "+1 (609) 555-0199")
            adminTextField(label: "Emergency Roadside Hotline", text: $secondaryPhone, placeholder: "+1 (609) 555-0198")
            adminTextField(label: "Official Inquiries Email", text: $email, placeholder: "service@bnautomechanic.net")
            adminTextField(label: "Physical Workshop Address", text: $address, placeholder: "123 Motor Parkway, Suite A")
            adminTextField(label: "Google Maps Directions URL", text: $mapUrl, placeholder: "https://maps.google.com/...")
        }
        .padding(16)
        .luxuryCard()
    }

    // MARK: - Maintenance & Emergency Section
    private var maintenanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle(title: "SYSTEM PROTECTION & MAINTENANCE", icon: "exclamationmark.shield.fill")

            // Toggle Card
            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Maintenance Mode")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.textForeground)
                    Text(maintenanceMode ? "ACTIVE: Customer bookings are locked" : "INACTIVE: Normal operations live")
                        .font(.system(size: 11))
                        .foregroundColor(maintenanceMode ? .statusCancelled : .statusConfirmed)
                }
                Spacer()
                Toggle("", isOn: $maintenanceMode)
                    .labelsHidden()
                    .tint(.primaryGold)
            }
            .padding(12)
            .background(maintenanceMode ? Color.statusCancelled.opacity(0.12) : Color.cardDarkElevated)
            .cornerRadius(10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(maintenanceMode ? Color.statusCancelled : Color.borderSubtle, lineWidth: 1)
            )

            adminTextField(label: "Customer Notice Message", text: $maintenanceMessage, placeholder: "We are undergoing scheduled routine enhancements. Service lines remain open.")
            adminTextField(label: "Expected Online Resumption Time", text: $maintenanceUntil, placeholder: "e.g. Today at 6:00 PM EST")

            // Tax & Currency
            Divider().background(Color.borderSubtle)
            sectionTitle(title: "CURRENCY & TAX COMPLIANCE", icon: "percent")

            HStack(spacing: 12) {
                adminTextField(label: "Currency ISO", text: $currency, placeholder: "USD")
                adminTextField(label: "Symbol", text: $currencySymbol, placeholder: "$")
            }

            adminTextField(label: "Default Workshop Sales Tax Rate (%)", text: $taxRate, placeholder: "8.25")
        }
        .padding(16)
        .luxuryCard()
    }

    // MARK: - Payments & Gateways Section
    private var paymentsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            sectionTitle(title: "SQUARE ONLINE GATEWAY", icon: "creditcard.fill")

            HStack {
                VStack(alignment: .leading, spacing: 3) {
                    Text("Enable Online Processing")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.textForeground)
                    Text("Accept Square credit and debit cards directly")
                        .font(.system(size: 11))
                        .foregroundColor(.textMuted)
                }
                Spacer()
                Toggle("", isOn: $onlinePaymentEnabled)
                    .labelsHidden()
                    .tint(.primaryGold)
            }
            .padding(12)
            .background(Color.cardDarkElevated)
            .cornerRadius(10)

            // Sandbox vs Live Segmented
            VStack(alignment: .leading, spacing: 6) {
                Text("Square Environment")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.textMuted)

                HStack(spacing: 10) {
                    Button {
                        triggerHaptic()
                        squareMode = "sandbox"
                    } label: {
                        Text("SANDBOX TESTING")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(squareMode == "sandbox" ? .bgDark : .textForeground)
                            .frame(maxWidth: .infinity)
                            .frame(height: 34)
                            .background(squareMode == "sandbox" ? Color.primaryGold : Color.cardDarkElevated)
                            .cornerRadius(8)
                    }

                    Button {
                        triggerHaptic()
                        squareMode = "live"
                    } label: {
                        Text("PRODUCTION LIVE")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(squareMode == "live" ? .bgDark : .textForeground)
                            .frame(maxWidth: .infinity)
                            .frame(height: 34)
                            .background(squareMode == "live" ? Color.primaryGold : Color.cardDarkElevated)
                            .cornerRadius(8)
                    }
                }
            }

            adminTextField(label: "Square Application ID", text: $squareAppId, placeholder: "sq0idp-...")
            adminTextField(label: "Square Location ID", text: $squareLocationId, placeholder: "LXXXXXXXXX")
            adminTextField(label: "Square Access Token", text: $squareAccessToken, placeholder: "EAAAExxxxxxxx")

            // Cash and Bank Transfer
            Divider().background(Color.borderSubtle)
            sectionTitle(title: "IN-STORE CASH & BANK PAYMENTS", icon: "banknote.fill")

            HStack {
                Text("Allow Cash Payment at Workshop")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.textForeground)
                Spacer()
                Toggle("", isOn: $payCashEnabled)
                    .labelsHidden()
                    .tint(.primaryGold)
            }

            adminTextField(label: "Cash Instructions", text: $cashInstructions, placeholder: "Pay in cash at completion of service visit")

            HStack {
                Text("Allow Bank Transfer / Wire")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.textForeground)
                Spacer()
                Toggle("", isOn: $payBankTransferEnabled)
                    .labelsHidden()
                    .tint(.primaryGold)
            }

            if payBankTransferEnabled {
                adminTextField(label: "Bank Name", text: $bankName, placeholder: "Chase / Wells Fargo")
                adminTextField(label: "Account Name", text: $bankAccountName, placeholder: "BN Auto Mechanic LLC")
                adminTextField(label: "Account Number", text: $bankAccountNumber, placeholder: "1234567890")
                adminTextField(label: "Routing / SWIFT Code", text: $bankRoutingCode, placeholder: "021000021")
            }
        }
        .padding(16)
        .luxuryCard()
    }

    // MARK: - Save Controls Button
    private var saveControlsButton: some View {
        Button {
            triggerHaptic()
            Task {
                await saveAllSettings()
            }
        } label: {
            HStack(spacing: 10) {
                if isSaving {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .bgDark))
                } else {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 16, weight: .bold))
                }

                Text(isSaving ? "Synchronizing with Server..." : "SAVE MASTER CONTROLS")
                    .font(.system(size: 14, weight: .black))
                    .tracking(0.5)
            }
            .foregroundColor(.bgDark)
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(Color.primaryGold)
            .cornerRadius(12)
            .shadow(color: Color.primaryGold.opacity(0.3), radius: 10, x: 0, y: 4)
        }
        .disabled(isSaving)
    }

    // MARK: - Helper UI Builders
    private func sectionTitle(title: String, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.primaryGold)
            Text(title)
                .font(.system(size: 12, weight: .black))
                .foregroundColor(.primaryGold)
                .tracking(0.6)
            Spacer()
        }
    }

    private func adminTextField(label: String, text: Binding<String>, placeholder: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.textMuted)

            TextField(placeholder, text: text)
                .font(.system(size: 13))
                .foregroundColor(.textForeground)
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(Color.cardDarkElevated)
                .cornerRadius(8)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.borderSubtle, lineWidth: 1)
                )
        }
    }

    // MARK: - API Synchronization
    private func loadAllSettings() async {
        isLoading = true
        let api = APIService.shared

        // Load Public & Admin Settings
        if let resp = try? await api.getAdminSettings(), let s = resp.data {
            await MainActor.run {
                siteName = s.siteName ?? "BN Auto Mechanic"
                tagline = s.tagline ?? "Premium Automotive Care"
                phone = s.phone ?? ""
                secondaryPhone = s.secondaryPhone ?? ""
                email = s.email ?? ""
                address = s.address ?? ""
                mapUrl = s.mapUrl ?? ""
                currency = s.currency ?? "USD"
                currencySymbol = s.currencySymbol ?? "$"
                if let tr = s.taxRate {
                    taxRate = String(format: "%.2f", tr)
                }
                maintenanceMode = s.maintenanceMode ?? false
                maintenanceMessage = s.maintenanceMessage ?? ""
                maintenanceUntil = s.maintenanceUntil ?? ""
            }
        }

        // Load Payment Gateway Settings
        if let pResp = try? await api.getPaymentSettings(), let p = pResp.data {
            await MainActor.run {
                onlinePaymentEnabled = p.onlinePaymentEnabled ?? false
                squareMode = p.squareMode ?? "sandbox"
                if squareMode == "sandbox" {
                    squareAppId = p.squareApplicationIdSandbox ?? ""
                    squareLocationId = p.squareLocationIdSandbox ?? ""
                    squareAccessToken = p.squareAccessTokenSandbox ?? ""
                } else {
                    squareAppId = p.squareApplicationIdLive ?? ""
                    squareLocationId = p.squareLocationIdLive ?? ""
                    squareAccessToken = p.squareAccessTokenLive ?? ""
                }
                payCashEnabled = p.payCashEnabled ?? true
                cashInstructions = p.cashInstructions ?? ""
                payBankTransferEnabled = p.payBankTransferEnabled ?? false
                bankName = p.bankName ?? ""
                bankAccountName = p.bankAccountName ?? ""
                bankAccountNumber = p.bankAccountNumber ?? ""
                bankRoutingCode = p.bankRoutingCode ?? ""
            }
        }

        await MainActor.run {
            isLoading = false
        }
    }

    private func saveAllSettings() async {
        isSaving = true
        let api = APIService.shared

        let rateDouble = Double(taxRate) ?? 0.0

        let settingsReq = UpdateSettingsRequest(
            siteName: siteName,
            tagline: tagline,
            phone: phone,
            secondaryPhone: secondaryPhone,
            email: email,
            address: address,
            mapUrl: mapUrl,
            currency: currency,
            currencySymbol: currencySymbol,
            taxRate: rateDouble,
            maintenanceMode: maintenanceMode,
            maintenanceMessage: maintenanceMessage,
            maintenanceUntil: maintenanceUntil
        )

        var paymentObj = PaymentSettings(
            onlinePaymentEnabled: onlinePaymentEnabled,
            squareMode: squareMode,
            payCashEnabled: payCashEnabled,
            payBankTransferEnabled: payBankTransferEnabled,
            cashInstructions: cashInstructions,
            bankName: bankName,
            bankAccountName: bankAccountName,
            bankAccountNumber: bankAccountNumber,
            bankRoutingCode: bankRoutingCode
        )

        if squareMode == "sandbox" {
            paymentObj.squareApplicationIdSandbox = squareAppId
            paymentObj.squareLocationIdSandbox = squareLocationId
            paymentObj.squareAccessTokenSandbox = squareAccessToken
        } else {
            paymentObj.squareApplicationIdLive = squareAppId
            paymentObj.squareLocationIdLive = squareLocationId
            paymentObj.squareAccessTokenLive = squareAccessToken
        }

        var updateSuccess = false
        var errorDesc: String? = nil

        do {
            _ = try await api.updateAdminSettings(settingsReq)
            _ = try await api.updatePaymentSettings(paymentObj)
            updateSuccess = true
        } catch {
            errorDesc = error.localizedDescription
        }

        await MainActor.run {
            isSaving = false
            if updateSuccess {
                statusMessage = "Master controls synchronized and applied globally."
                withAnimation {
                    showSuccessBanner = true
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation {
                        showSuccessBanner = false
                    }
                }
            } else {
                statusMessage = errorDesc ?? "Failed to save configuration settings."
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
