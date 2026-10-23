//
//  DealsView.swift
//  BNAutoMechanic
//
//  Pixel-perfect replica of Android DealsActivity and item_deal
//

import SwiftUI

struct DealsView: View {
    @Environment(\.dismiss) var dismiss
    @State private var deals: [Deal] = []
    @State private var isLoading = false
    @State private var copiedCoupon: String? = nil
    @State private var showBookingSheet = false

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

                Text("Special Offers & Deals")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.textForeground)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider().background(Color.borderSubtle)

            if isLoading {
                Spacer()
                ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .primaryGold))
                Spacer()
            } else if deals.isEmpty {
                Spacer()
                VStack(spacing: 14) {
                    Image(systemName: "tag.slash")
                        .font(.system(size: 44))
                        .foregroundColor(.textSubtle)

                    Text("No active promotions right now")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.textForeground)

                    Text("Check back regularly for seasonal maintenance specials and coupon discounts.")
                        .font(.system(size: 13))
                        .foregroundColor(.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 14) {
                        ForEach(deals) { deal in
                            dealCard(deal)
                        }
                    }
                    .padding(16)
                }
                .refreshable {
                    await loadDeals()
                }
            }
        }
        .background(Color.bgDark.ignoresSafeArea())
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .task {
            await loadDeals()
        }
        .sheet(isPresented: $showBookingSheet) {
            BookAppointmentView()
        }
    }

    // MARK: - Deal Card (Matching item_deal.xml)
    private func dealCard(_ deal: Deal) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(deal.discountBadge())
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.bgDark)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Color.primaryGold)
                    .cornerRadius(4)

                Spacer()

                if let exp = deal.expiresAt {
                    Text("Expires \(exp)")
                        .font(.system(size: 11))
                        .foregroundColor(.textSubtle)
                }
            }

            Text(deal.title)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.textForeground)

            if let desc = deal.description, !desc.isEmpty {
                Text(desc)
                    .font(.system(size: 13))
                    .foregroundColor(.textMuted)
                    .lineSpacing(3)
            }

            Divider().background(Color.borderSubtle)

            // Coupon Code & Copy Action
            HStack(spacing: 10) {
                if let code = deal.code, !code.isEmpty {
                    Button(action: {
                        UIPasteboard.general.string = code
                        copiedCoupon = code
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            if copiedCoupon == code { copiedCoupon = nil }
                        }
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: copiedCoupon == code ? "checkmark" : "doc.on.doc")
                                .font(.system(size: 11, weight: .bold))
                            Text(copiedCoupon == code ? "COPIED" : code)
                                .font(.system(size: 12, weight: .black))
                                .tracking(1)
                        }
                        .foregroundColor(.primaryGold)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color.primaryGoldTint)
                        .cornerRadius(6)
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.primaryGold, style: StrokeStyle(lineWidth: 1, dash: [4]))
                        )
                    }
                }

                Spacer()

                Button(action: { showBookingSheet = true }) {
                    Text("Claim Deal")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.bgDark)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.primaryGold)
                        .cornerRadius(6)
                }
            }
        }
        .padding(16)
        .luxuryCard()
    }

    private func loadDeals() async {
        isLoading = deals.isEmpty
        if let response = try? await APIService.shared.getDeals() {
            await MainActor.run {
                deals = response.data?.items ?? []
                isLoading = false
            }
        } else {
            await MainActor.run { isLoading = false }
        }
    }
}
