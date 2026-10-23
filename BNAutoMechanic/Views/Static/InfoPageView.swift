//
//  InfoPageView.swift
//  BNAutoMechanic
//
//  Pixel-perfect replica of Android ActivityInfoPage
//

import SwiftUI

enum InfoPageType {
    case info
    case terms
}

struct InfoPageView: View {
    let pageType: InfoPageType
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

                Text(pageType == .terms ? "Warranty & Terms" : "Workshop Information")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.textForeground)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider().background(Color.borderSubtle)

            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if pageType == .terms {
                        termsContent
                    } else {
                        workshopInfoContent
                    }
                }
                .padding(16)
                .padding(.bottom, 32)
            }
        }
        .background(Color.bgDark.ignoresSafeArea())
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
    }

    // MARK: - Terms Content
    private var termsContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Header banner
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Image(systemName: "shield.checkmark.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.primaryGold)
                    Text("12-Month / 12,000-Mile Warranty")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.textForeground)
                }

                Text("Every qualified service and repair performed by BN Auto Mechanic includes our comprehensive parts and labor warranty protection.")
                    .font(.system(size: 13))
                    .foregroundColor(.textMuted)
            }
            .padding(16)
            .luxuryCard()

            // Clause 1
            termClause(
                title: "WARRANTY COVERAGE",
                body: "All mechanical repairs, brakes, diagnostics and routine servicing performed with genuine OEM or certified equivalent components carry our 12-month or 12,000-mile warranty."
            )

            // Clause 2
            termClause(
                title: "ESTIMATE INTEGRITY",
                body: "We never initiate unauthorized work. All supplementary extra parts or procedures discovered during vehicle inspection require explicit customer estimate approval."
            )

            // Clause 3
            termClause(
                title: "DATA PRIVACY & SECURITY",
                body: "Customer vehicle records, service logs, and payment details are encrypted with TLS 1.3 standards and never distributed to third-party marketing brokers."
            )

            // Clause 4
            termClause(
                title: "CANCELLATION POLICY",
                body: "Appointments may be rescheduled or cancelled up to 2 hours prior to scheduled bay arrival without any cancellation fee."
            )
        }
    }

    // MARK: - Workshop Info Content
    private var workshopInfoContent: some View {
        VStack(alignment: .leading, spacing: 18) {
            // Main Hero
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    Image("AppLogo")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 44, height: 44)
                    Text("BN Auto Mechanic Workshop")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.textForeground)
                }

                Text("Specialized domestic and European automotive mechanics serving Ewing and greater Mercer County with master certified technicians.")
                    .font(.system(size: 13))
                    .foregroundColor(.textMuted)
            }
            .padding(16)
            .luxuryCard()

            // Contact & Location Card
            VStack(alignment: .leading, spacing: 14) {
                Text("LOCATION & HOURS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.textSubtle)
                    .tracking(0.6)

                contactRow(icon: "mappin.circle.fill", label: "Address", value: "1200 Parkway Ave, Ewing Township, NJ 08628")
                Divider().background(Color.borderSubtle)

                contactRow(icon: "phone.fill", label: "Phone", value: "(609) 555-0199") {
                    if let url = URL(string: "tel:+16095550199") {
                        #if os(iOS)
                        UIApplication.shared.open(url)
                        #endif
                    }
                }
                Divider().background(Color.borderSubtle)

                contactRow(icon: "envelope.fill", label: "Email", value: "service@bnautomechanic.net") {
                    if let url = URL(string: "mailto:service@bnautomechanic.net") {
                        #if os(iOS)
                        UIApplication.shared.open(url)
                        #endif
                    }
                }
                Divider().background(Color.borderSubtle)

                contactRow(icon: "globe", label: "Website", value: "https://bnautomechanic.net") {
                    if let url = URL(string: "https://bnautomechanic.net") {
                        #if os(iOS)
                        UIApplication.shared.open(url)
                        #endif
                    }
                }
                Divider().background(Color.borderSubtle)

                contactRow(icon: "clock.fill", label: "Operating Hours", value: "Mon - Fri: 8:00 AM - 6:00 PM\nSaturday: 8:00 AM - 3:00 PM\nSunday: Closed (Emergency Towing Available)")
            }
            .padding(16)
            .luxuryCard()

            // Certification Card
            VStack(alignment: .leading, spacing: 10) {
                Text("CERTIFICATIONS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.textSubtle)
                    .tracking(0.6)

                Text("• ASE Master Automotive Certified\n• Bosch Authorized Service Center\n• Official State Inspection Station\n• 24/7 Roadside Assistance Fleet")
                    .font(.system(size: 13))
                    .foregroundColor(.textForeground)
                    .lineSpacing(6)
            }
            .padding(16)
            .luxuryCard()
        }
    }

    private func termClause(title: String, body: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.primaryGold)
                .tracking(0.5)

            Text(body)
                .font(.system(size: 13))
                .foregroundColor(.textForeground)
                .lineSpacing(4)
        }
        .padding(16)
        .luxuryCard()
    }

    private func contactRow(icon: String, label: String, value: String, action: (() -> Void)? = nil) -> some View {
        Button(action: { action?() }) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 16))
                    .foregroundColor(.primaryGold)
                    .frame(width: 20)
                    .padding(.top, 2)

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.textSubtle)
                    Text(value)
                        .font(.system(size: 13))
                        .foregroundColor(action != nil ? .primaryGold : .textForeground)
                        .multilineTextAlignment(.leading)
                }
                Spacer()
            }
        }
        .disabled(action == nil)
    }
}
