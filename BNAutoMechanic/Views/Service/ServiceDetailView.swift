//
//  ServiceDetailView.swift
//  BNAutoMechanic
//
//  Pixel-perfect replica of Android ServiceDetailActivity
//

import SwiftUI

struct ServiceDetailView: View {
    let serviceId: Int
    var serviceName: String = ""
    var serviceDesc: String? = nil
    var serviceDuration: String = "45 mins"
    var serviceCategory: String = "MAINTENANCE"

    @State private var service: Service?
    @State private var showBookingWizard = false
    @Environment(\.dismiss) var dismiss

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

                Text("Service Details")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.textForeground)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider().background(Color.borderSubtle)

            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Hero
                    ZStack(alignment: .bottomLeading) {
                        LinearGradient(
                            colors: [Color.primaryGold.opacity(0.18), Color.bgDark],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                        .frame(height: 160)

                        VStack(alignment: .leading, spacing: 6) {
                            Text(categoryTitle)
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(.primaryGold)
                                .tracking(1)

                            Text(nameTitle)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.textForeground)

                            HStack(spacing: 14) {
                                Label(durationTitle, systemImage: "clock.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(.textMuted)

                                if let priceStr = service?.formattedPrice() {
                                    Text(priceStr)
                                        .font(.system(size: 14, weight: .black))
                                        .foregroundColor(.primaryGold)
                                }
                            }
                        }
                        .padding(16)
                    }

                    // Description
                    if let desc = descriptionTitle, !desc.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("About This Service")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.textForeground)

                            Text(desc)
                                .font(.system(size: 13))
                                .foregroundColor(.textMuted)
                                .lineSpacing(4)
                        }
                        .padding(16)
                    }

                    // Benefits
                    if let benefits = service?.benefits, !benefits.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Service Benefits")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.textForeground)

                            ForEach(benefits, id: \.self) { benefit in
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "checkmark.circle.fill")
                                        .font(.system(size: 14))
                                        .foregroundColor(.statusCompleted)
                                    Text(benefit)
                                        .font(.system(size: 13))
                                        .foregroundColor(.textMuted)
                                }
                            }
                        }
                        .padding(16)
                        .luxuryCard()
                        .padding(.horizontal, 16)
                        .padding(.top, 4)
                    }

                    // What's Included
                    if let items = service?.includedItems, !items.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("What's Included")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.textForeground)

                            ForEach(items, id: \.self) { item in
                                HStack(alignment: .top, spacing: 10) {
                                    Image(systemName: "wrench.fill")
                                        .font(.system(size: 12))
                                        .foregroundColor(.primaryGold)
                                    Text(item)
                                        .font(.system(size: 13))
                                        .foregroundColor(.textMuted)
                                }
                            }
                        }
                        .padding(16)
                        .luxuryCard()
                        .padding(.horizontal, 16)
                        .padding(.top, 10)
                    }

                    // FAQs
                    if let faqs = service?.faqs, !faqs.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            Text("Frequently Asked Questions")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.textForeground)

                            ForEach(Array(faqs.enumerated()), id: \.offset) { _, faq in
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(faq.question)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(.textForeground)
                                    Text(faq.answer)
                                        .font(.system(size: 12))
                                        .foregroundColor(.textMuted)
                                }
                                .padding(12)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.cardDarkElevated)
                                .cornerRadius(10)
                            }
                        }
                        .padding(16)
                    }

                    // Workshop Guarantee Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: "shield.checkmark.fill")
                                .foregroundColor(.primaryGold)
                            Text("12-Month / 12,000-Mile Warranty")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.textForeground)
                        }

                        Text("Every qualified repair includes our complete parts and master labor warranty protection.")
                            .font(.system(size: 12))
                            .foregroundColor(.textMuted)
                    }
                    .padding(16)
                    .goldBorderCard()
                    .padding(.horizontal, 16)
                    .padding(.top, 8)

                    // Book Button
                    Button(action: { showBookingWizard = true }) {
                        Text("Book This Service")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.bgDark)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.primaryGold)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 32)
                }
            }
        }
        .background(Color.bgDark.ignoresSafeArea())
        .navigationBarHidden(true)
        .sheet(isPresented: $showBookingWizard) {
            BookAppointmentView(preselectedServiceId: serviceId)
        }
        .task {
            if serviceId > 0 {
                if let response = try? await APIService.shared.getServiceDetail(id: serviceId) {
                    await MainActor.run {
                        service = response.data
                    }
                }
            }
        }
    }

    private var nameTitle: String {
        service?.name ?? (serviceName.isEmpty ? "Automotive Service" : serviceName)
    }

    private var categoryTitle: String {
        service?.category?.name.uppercased() ?? serviceCategory.uppercased()
    }

    private var durationTitle: String {
        service?.formattedDuration() ?? serviceDuration
    }

    private var descriptionTitle: String? {
        service?.description ?? service?.shortDescription ?? serviceDesc
    }
}
