//
//  AppTheme.swift
//  BNAutoMechanic
//

import SwiftUI

// MARK: - Color Palette (Exact match of Android colors.xml)
extension Color {
    // Primary Gold Accents
    static let primaryGold = Color(hex: "F5B900")
    static let primaryBright = Color(hex: "FFC21A")
    static let primaryGoldDark = Color(hex: "D49E00")
    static let primaryGoldTint = Color(hex: "F5B900").opacity(0.15)
    static let primaryGoldSubtle = Color(hex: "F5B900").opacity(0.08)
    static let goldBorder = Color(hex: "F5B900").opacity(0.35)

    // Surfaces & Backgrounds
    static let bgDark = Color(hex: "050607")
    static let surfaceDark = Color(hex: "0B0D11")
    static let cardDark = Color(hex: "0F1117")
    static let cardDarkElevated = Color(hex: "161922")
    static let cardDarkHover = Color(hex: "1D212C")
    static let bottomNavBg = Color(hex: "07090C").opacity(0.95)

    // Borders & Dividers
    static let borderSubtle = Color(hex: "1C1F26")
    static let borderMedium = Color(hex: "262A34")
    static let borderStrong = Color(hex: "363C4A")

    // Typography & Text
    static let textForeground = Color(hex: "E8E9EC")
    static let textMuted = Color(hex: "A8A9AD")
    static let textSubtle = Color(hex: "666970")
    static let textGold = Color(hex: "F5B900")

    // Status & Semantic Badges
    static let statusPending = Color(hex: "F59E0B")
    static let statusPendingBg = Color(hex: "F59E0B").opacity(0.125)
    static let statusWarning = Color(hex: "F59E0B")
    static let statusWarningBg = Color(hex: "F59E0B").opacity(0.125)
    static let statusConfirmed = Color(hex: "3B82F6")
    static let statusConfirmedBg = Color(hex: "3B82F6").opacity(0.125)
    static let statusInProgress = Color(hex: "F5B900")
    static let statusInProgressBg = Color(hex: "F5B900").opacity(0.145)
    static let statusCompleted = Color(hex: "10B981")
    static let statusCompletedBg = Color(hex: "10B981").opacity(0.125)
    static let statusCancelled = Color(hex: "EF4444")
    static let statusCancelledBg = Color(hex: "EF4444").opacity(0.125)
    static let statusAssigned = Color(hex: "8B5CF6")
    static let statusAssignedBg = Color(hex: "8B5CF6").opacity(0.125)

    // Hex Initializer
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    // Status color helpers
    static func statusColor(for status: String) -> Color {
        switch status.uppercased() {
        case "PENDING": return .statusPending
        case "CONFIRMED": return .statusConfirmed
        case "IN_PROGRESS", "IN PROGRESS": return .statusInProgress
        case "COMPLETED": return .statusCompleted
        case "CANCELLED", "DECLINED", "NO_SHOW": return .statusCancelled
        case "ASSIGNED": return .statusAssigned
        case "APPROVED", "ESTIMATE_APPROVED": return .statusCompleted
        case "ESTIMATE_SENT", "APPROVED_FOR_ESTIMATE": return .statusConfirmed
        case "ESTIMATE_REJECTED": return .statusCancelled
        default: return .statusPending
        }
    }

    static func statusBgColor(for status: String) -> Color {
        switch status.uppercased() {
        case "PENDING": return .statusPendingBg
        case "CONFIRMED": return .statusConfirmedBg
        case "IN_PROGRESS", "IN PROGRESS": return .statusInProgressBg
        case "COMPLETED": return .statusCompletedBg
        case "CANCELLED", "DECLINED", "NO_SHOW": return .statusCancelledBg
        case "ASSIGNED": return .statusAssignedBg
        case "APPROVED", "ESTIMATE_APPROVED": return .statusCompletedBg
        case "ESTIMATE_SENT", "APPROVED_FOR_ESTIMATE": return .statusConfirmedBg
        case "ESTIMATE_REJECTED": return .statusCancelledBg
        default: return .statusPendingBg
        }
    }
}

// MARK: - Reusable View Modifiers
struct GoldButtonStyle: ButtonStyle {
    var isEnabled: Bool = true

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.bgDark)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .background(isEnabled ? Color.primaryGold : Color.primaryGold.opacity(0.5))
            .cornerRadius(12)
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct OutlineButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 14, weight: .bold))
            .foregroundColor(.textForeground)
            .frame(maxWidth: .infinity)
            .frame(height: 48)
            .background(Color.clear)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.borderMedium, lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
    }
}

struct LuxuryCardModifier: ViewModifier {
    var hasBorder: Bool = true

    func body(content: Content) -> some View {
        content
            .background(Color.cardDark)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(hasBorder ? Color.borderSubtle : Color.clear, lineWidth: 1)
            )
    }
}

struct GoldBorderCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.cardDark)
            .cornerRadius(14)
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.goldBorder, lineWidth: 1)
            )
    }
}

extension View {
    func luxuryCard(hasBorder: Bool = true) -> some View {
        self.modifier(LuxuryCardModifier(hasBorder: hasBorder))
    }

    func goldBorderCard() -> some View {
        self.modifier(GoldBorderCardModifier())
    }
}

// MARK: - Status Badge View
struct StatusBadge: View {
    let status: String

    var body: some View {
        Text(status.replacingOccurrences(of: "_", with: " "))
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(Color.statusColor(for: status))
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Color.statusBgColor(for: status))
            .cornerRadius(6)
    }
}

// MARK: - Input Field Style
struct DarkInputFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.surfaceDark)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.borderMedium, lineWidth: 1)
            )
            .foregroundColor(.textForeground)
            .font(.system(size: 14))
    }
}

// MARK: - Navigation Bar Style
struct DarkNavigationBar: View {
    let title: String
    var showBack: Bool = true
    var onBack: (() -> Void)?
    var trailingContent: AnyView? = nil

    var body: some View {
        HStack(spacing: 12) {
            if showBack {
                Button(action: { onBack?() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textForeground)
                        .frame(width: 36, height: 36)
                        .background(Color.cardDarkElevated)
                        .cornerRadius(10)
                }
            }

            Text(title)
                .font(.system(size: 17, weight: .bold))
                .foregroundColor(.textForeground)

            Spacer()

            if let trailing = trailingContent {
                trailing
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Color.bgDark)
    }
}
