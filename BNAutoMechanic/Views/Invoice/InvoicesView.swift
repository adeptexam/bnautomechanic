//
//  InvoicesView.swift
//  BNAutoMechanic
//
//  Pixel-perfect replica of Android InvoicesActivity and InvoiceDetailActivity
//

import SwiftUI

struct InvoicesView: View {
    @Environment(\.dismiss) var dismiss
    @State private var invoices: [Invoice] = []
    @State private var isLoading = false

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

                Text("Invoices & Receipts")
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
            } else if invoices.isEmpty {
                Spacer()
                VStack(spacing: 14) {
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 44))
                        .foregroundColor(.textSubtle)

                    Text("No invoices on record")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.textForeground)

                    Text("Invoices and payment receipts will be generated once services are completed.")
                        .font(.system(size: 13))
                        .foregroundColor(.textMuted)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(invoices) { invoice in
                            NavigationLink(destination: InvoiceDetailView(invoice: invoice)) {
                                invoiceCard(invoice)
                            }
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 16)
                    .padding(.bottom, 36)
                }
                .refreshable {
                    await loadInvoices()
                }
            }
        }
        .background(Color.bgDark.ignoresSafeArea())
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .hideBottomDockOnPush()
        .task {
            await loadInvoices()
        }
    }

    private func invoiceCard(_ inv: Invoice) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.primaryGoldTint)
                    .frame(width: 44, height: 44)
                Image(systemName: "doc.text.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.primaryGold)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Invoice #\(inv.invoiceNumber)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.textForeground)

                Text(inv.createdAt ?? "Recent")
                    .font(.system(size: 11))
                    .foregroundColor(.textMuted)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                Text(String(format: "$%.2f", inv.total ?? 0))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primaryGold)

                let status = inv.status ?? "PAID"
                Text(status)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(status == "PAID" ? .statusCompleted : .statusPending)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(status == "PAID" ? Color.statusCompletedBg : Color.statusPendingBg)
                    .cornerRadius(4)
            }

            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.textSubtle)
        }
        .padding(14)
        .luxuryCard()
    }

    private func loadInvoices() async {
        isLoading = invoices.isEmpty
        if let response = try? await APIService.shared.getInvoices() {
            await MainActor.run {
                invoices = response.data?.items ?? []
                isLoading = false
            }
        } else {
            await MainActor.run { isLoading = false }
        }
    }
}

// MARK: - Invoice Detail View (Matching ActivityInvoiceDetail)
struct InvoiceDetailView: View {
    let invoice: Invoice
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

                Text("Invoice #\(invoice.invoiceNumber)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.textForeground)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider().background(Color.borderSubtle)

            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    // Invoice Status Hero
                    VStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 38))
                            .foregroundColor(.primaryGold)

                        Text("INVOICE #\(invoice.invoiceNumber)")
                            .font(.system(size: 16, weight: .black))
                            .foregroundColor(.textForeground)
                            .tracking(1)

                        if let date = invoice.createdAt {
                            Text("Date Issued: \(date)")
                                .font(.system(size: 12))
                                .foregroundColor(.textMuted)
                        }

                        let status = invoice.status ?? "PAID"
                        Text(status)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(status == "PAID" ? .statusCompleted : .statusPending)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(status == "PAID" ? Color.statusCompletedBg : Color.statusPendingBg)
                            .cornerRadius(6)
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)
                    .luxuryCard()

                    // Financial Itemization
                    VStack(alignment: .leading, spacing: 12) {
                        Text("PAYMENT SUMMARY")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.textSubtle)
                            .tracking(0.6)

                        HStack {
                            Text("Subtotal")
                                .font(.system(size: 13))
                                .foregroundColor(.textMuted)
                            Spacer()
                            Text(String(format: "$%.2f", invoice.subtotal ?? 0))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.textForeground)
                        }

                        HStack {
                            Text("State Sales Tax")
                                .font(.system(size: 13))
                                .foregroundColor(.textMuted)
                            Spacer()
                            Text(String(format: "$%.2f", invoice.tax ?? 0))
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.textForeground)
                        }

                        Divider().background(Color.borderSubtle)

                        HStack {
                            Text("Total Amount")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.textForeground)
                            Spacer()
                            Text(String(format: "$%.2f", invoice.total ?? 0))
                                .font(.system(size: 18, weight: .black))
                                .foregroundColor(.primaryGold)
                        }
                    }
                    .padding(16)
                    .luxuryCard()

                    // Workshop Info Footer
                    VStack(alignment: .leading, spacing: 6) {
                        Text("BN AUTO MECHANIC")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.primaryGold)
                        Text("1200 Parkway Ave, Ewing Township, NJ 08628\nTax ID: 82-4910284  •  Licensed State Inspection Station")
                            .font(.system(size: 11))
                            .foregroundColor(.textSubtle)
                            .lineSpacing(4)
                    }
                    .padding(16)
                    .luxuryCard()
                }
                .padding(16)
                .padding(.bottom, 36)
            }
        }
        .background(Color.bgDark.ignoresSafeArea())
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .hideBottomDockOnPush()
    }
}
