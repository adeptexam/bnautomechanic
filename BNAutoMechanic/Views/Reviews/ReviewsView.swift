//
//  ReviewsView.swift
//  BNAutoMechanic
//
//  Pixel-perfect replica of Android ReviewsActivity and dialog_write_review
//  Includes full Apple Guideline 1.2 (User-Generated Content) reporting, blocking, and moderation.
//

import SwiftUI

struct ReviewsView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var moderation = ContentModerationManager.shared

    @State private var reviews: [Review] = []
    @State private var summary: ReviewSummary?
    @State private var isLoading = false
    @State private var showWriteReviewSheet = false

    // Moderation States
    @State private var reviewToReport: Review?
    @State private var showReportConfirmation = false
    @State private var showBlockConfirmation = false
    @State private var userToBlock: String?
    @State private var reportStatusMessage: String?
    @State private var showStatusToast = false

    private var visibleReviews: [Review] {
        reviews.filter { r in
            !moderation.isUserBlocked(name: r.userName) &&
            !moderation.isContentReported(contentId: "review_\(r.id)")
        }
    }

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

                Text("Customer Reviews")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.textForeground)

                Spacer()

                Button(action: { showWriteReviewSheet = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "pencil")
                            .font(.system(size: 12, weight: .bold))
                        Text("Write")
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

            // Status Toast
            if showStatusToast, let msg = reportStatusMessage {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.shield.fill")
                        .foregroundColor(.statusCompleted)
                    Text(msg)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.textForeground)
                    Spacer()
                }
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.cardDarkElevated)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.statusCompleted.opacity(0.3), lineWidth: 1)
                )
                .padding(.horizontal, 16)
                .padding(.top, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }

            ScrollView {
                VStack(spacing: 16) {
                    // Rating Summary Hero (Matching Android tvAverageRating and tvTotalReviews)
                    ratingSummaryCard
                        .padding(.horizontal, 16)
                        .padding(.top, 12)

                    // Apple Guideline 1.2 UGC Safety Notice
                    HStack(spacing: 8) {
                        Image(systemName: "hand.raised.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.primaryGold)
                        Text("Community Guidelines: Objectionable or abusive content is strictly prohibited. Tap the menu on any review to report or block.")
                            .font(.system(size: 10))
                            .foregroundColor(.textMuted)
                            .lineLimit(2)
                        Spacer()
                    }
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(Color.cardDarkElevated.opacity(0.5))
                    .cornerRadius(8)
                    .padding(.horizontal, 16)

                    if isLoading {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .primaryGold))
                            .padding(.top, 24)
                    } else if visibleReviews.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "star.slash")
                                .font(.system(size: 40))
                                .foregroundColor(.textSubtle)
                            Text("No reviews visible")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(.textForeground)
                            Text("Be the first to share your experience with BN Auto Mechanic!")
                                .font(.system(size: 12))
                                .foregroundColor(.textMuted)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal, 32)
                        }
                        .padding(.top, 32)
                    } else {
                        LazyVStack(spacing: 10) {
                            ForEach(visibleReviews) { review in
                                reviewCard(review)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                }
                .padding(.bottom, 36)
            }
            .refreshable {
                await loadReviews()
            }
        }
        .background(Color.bgDark.ignoresSafeArea())
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .hideBottomDockOnPush()
        .task {
            await loadReviews()
        }
        .sheet(isPresented: $showWriteReviewSheet) {
            WriteReviewSheet(onReviewSubmitted: {
                Task { await loadReviews() }
            })
        }
        // Apple Guideline 1.2: Report Content Confirmation Dialog
        .confirmationDialog("Report Review", isPresented: $showReportConfirmation, titleVisibility: .visible) {
            Button("Spam or Advertising", role: .none) {
                submitReport(reason: "Spam or Advertising")
            }
            Button("Harassment or Hate Speech", role: .none) {
                submitReport(reason: "Harassment or Hate Speech")
            }
            Button("Inappropriate / Offensive Language", role: .none) {
                submitReport(reason: "Inappropriate / Offensive Language")
            }
            Button("Defamatory or False Information", role: .none) {
                submitReport(reason: "Defamatory or False Information")
            }
            Button("Cancel", role: .cancel) {
                reviewToReport = nil
            }
        } message: {
            Text("Help us keep our community safe. Please specify why you are reporting this review. Our moderation team reviews all reports within 24 hours.")
        }
        // Apple Guideline 1.2: Block User Alert
        .alert("Block User", isPresented: $showBlockConfirmation) {
            Button("Block Author", role: .destructive) {
                if let name = userToBlock {
                    moderation.blockUser(name: name)
                    triggerToast("Author blocked. Their content is now hidden from your feed.")
                }
                userToBlock = nil
            }
            Button("Cancel", role: .cancel) {
                userToBlock = nil
            }
        } message: {
            Text("Are you sure you want to block \(userToBlock ?? "this user")? You will no longer see reviews or messages from them.")
        }
    }

    // MARK: - Rating Summary Card
    private var ratingSummaryCard: some View {
        HStack(spacing: 20) {
            VStack(spacing: 4) {
                Text(String(format: "%.1f", summary?.average ?? 4.9))
                    .font(.system(size: 38, weight: .black))
                    .foregroundColor(.primaryGold)

                HStack(spacing: 3) {
                    ForEach(1...5, id: \.self) { _ in
                        Image(systemName: "star.fill")
                            .font(.system(size: 13))
                            .foregroundColor(.primaryGold)
                    }
                }
            }

            Rectangle()
                .fill(Color.borderSubtle)
                .frame(width: 1, height: 50)

            VStack(alignment: .leading, spacing: 4) {
                Text("VERIFIED REVIEWS")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.textForeground)
                    .tracking(0.5)

                let count = summary?.total ?? visibleReviews.count
                Text("Based on \(count) verified customer ratings across Ewing & Mercer County.")
                    .font(.system(size: 11))
                    .foregroundColor(.textMuted)
                    .lineLimit(2)
            }

            Spacer()
        }
        .padding(16)
        .goldBorderCard()
    }

    // MARK: - Review Card with Guideline 1.2 UGC Moderation Menu
    private func reviewCard(_ r: Review) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                // User initials circle
                ZStack {
                    Circle()
                        .fill(Color.primaryGoldTint)
                        .frame(width: 34, height: 34)
                    Text(initials(for: r.userName))
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.primaryGold)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(r.userName ?? "Customer")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.textForeground)

                    Text(r.createdAt ?? "Recent visit")
                        .font(.system(size: 10))
                        .foregroundColor(.textSubtle)
                }

                Spacer()

                // Star Rating
                HStack(spacing: 2) {
                    ForEach(1...5, id: \.self) { star in
                        Image(systemName: star <= r.rating ? "star.fill" : "star")
                            .font(.system(size: 11))
                            .foregroundColor(star <= r.rating ? .primaryGold : .textSubtle)
                    }
                }

                // Apple Guideline 1.2 UGC Actions Menu (Report / Block)
                Menu {
                    Button(role: .destructive) {
                        reviewToReport = r
                        showReportConfirmation = true
                    } label: {
                        Label("Report Review", systemImage: "flag")
                    }

                    Button(role: .destructive) {
                        userToBlock = r.userName ?? "Customer"
                        showBlockConfirmation = true
                    } label: {
                        Label("Block Author", systemImage: "hand.raised.slash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 14))
                        .foregroundColor(.textSubtle)
                        .frame(width: 28, height: 28)
                        .contentShape(Rectangle())
                }
            }

            if let comment = r.comment, !comment.isEmpty {
                Text(comment)
                    .font(.system(size: 13))
                    .foregroundColor(.textForeground)
                    .lineSpacing(3)
            }
        }
        .padding(14)
        .luxuryCard()
    }

    private func initials(for name: String?) -> String {
        guard let name = name, !name.isEmpty else { return "BN" }
        let parts = name.split(separator: " ").map(String.init)
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        }
        return String(name.prefix(2)).uppercased()
    }

    private func submitReport(reason: String) {
        guard let r = reviewToReport else { return }
        moderation.reportContent(
            contentId: "review_\(r.id)",
            contentType: "Review",
            reason: reason,
            notes: "Author: \(r.userName ?? "Unknown"), Comment: \(r.comment ?? "None")"
        )
        triggerToast("Review reported for '\(reason)'. Content has been hidden.")
        reviewToReport = nil
    }

    private func triggerToast(_ msg: String) {
        withAnimation {
            reportStatusMessage = msg
            showStatusToast = true
        }
        Task {
            try? await Task.sleep(nanoseconds: 3_500_000_000)
            await MainActor.run {
                withAnimation {
                    showStatusToast = false
                }
            }
        }
    }

    private func loadReviews() async {
        isLoading = reviews.isEmpty
        let api = APIService.shared

        // Load Summary
        if let sResp = try? await api.getReviewSummary() {
            await MainActor.run {
                summary = sResp.data
            }
        }

        // Load Reviews List
        if let rResp = try? await api.getReviews() {
            await MainActor.run {
                reviews = rResp.data?.items ?? []
                isLoading = false
            }
        } else {
            await MainActor.run { isLoading = false }
        }
    }
}

// MARK: - Write Review Sheet (Matching dialog_write_review.xml with Guideline 1.2 pre-submission filter)
struct WriteReviewSheet: View {
    @Environment(\.dismiss) var dismiss
    var onReviewSubmitted: () -> Void

    @State private var rating = 5
    @State private var comment = ""
    @State private var isSubmitting = false
    @State private var errorMessage = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                Text("Write a Review")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.textForeground)
                    .padding(.top, 10)

                Text("How was your recent vehicle service experience at BN Auto Mechanic?")
                    .font(.system(size: 13))
                    .foregroundColor(.textMuted)

                // Star Rating Selector
                HStack(spacing: 12) {
                    Spacer()
                    ForEach(1...5, id: \.self) { star in
                        Button(action: { rating = star }) {
                            Image(systemName: star <= rating ? "star.fill" : "star")
                                .font(.system(size: 32))
                                .foregroundColor(star <= rating ? .primaryGold : .textSubtle)
                        }
                    }
                    Spacer()
                }
                .padding(.vertical, 12)
                .luxuryCard()

                // Comment
                VStack(alignment: .leading, spacing: 6) {
                    Text("Your Review Comment")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.textForeground)

                    TextEditor(text: $comment)
                        .frame(height: 120)
                        .padding(10)
                        .background(Color.surfaceDark)
                        .cornerRadius(10)
                        .foregroundColor(.textForeground)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.borderMedium, lineWidth: 1)
                        )
                }

                // Apple Guideline 1.2 Terms Notice
                HStack(spacing: 6) {
                    Image(systemName: "checkmark.shield")
                        .font(.system(size: 11))
                        .foregroundColor(.primaryGold)
                    Text("By posting, you agree to our Community Guidelines. Objectionable, defamatory, or abusive content will be immediately removed.")
                        .font(.system(size: 10))
                        .foregroundColor(.textMuted)
                }

                if !errorMessage.isEmpty {
                    Text(errorMessage)
                        .font(.system(size: 12))
                        .foregroundColor(.statusCancelled)
                }

                Spacer()

                Button(action: submitReview) {
                    if isSubmitting {
                        ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .bgDark))
                    } else {
                        Text("Submit Review")
                    }
                }
                .buttonStyle(GoldButtonStyle(isEnabled: !isSubmitting))
                .disabled(isSubmitting)
                .padding(.bottom, 16)
            }
            .padding(16)
            .background(Color.bgDark.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.textMuted)
                }
            }
        }
    }

    private func submitReview() {
        let cleanText = comment.trimmingCharacters(in: .whitespacesAndNewlines)

        // Apple Guideline 1.2 Pre-submission Content Filtering
        let filterResult = ContentModerationManager.shared.containsObjectionableContent(cleanText)
        if filterResult.isObjectionable {
            errorMessage = filterResult.reason ?? "Content contains prohibited language."
            return
        }

        isSubmitting = true
        errorMessage = ""

        Task {
            do {
                let req = CreateReviewRequest(
                    rating: rating,
                    comment: cleanText,
                    bookingId: nil,
                    serviceId: nil
                )
                let resp = try await APIService.shared.createReview(req)
                await MainActor.run {
                    isSubmitting = false
                    if resp.success == true || resp.data != nil {
                        onReviewSubmitted()
                        dismiss()
                    } else {
                        errorMessage = resp.message ?? "Could not post review."
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
}
