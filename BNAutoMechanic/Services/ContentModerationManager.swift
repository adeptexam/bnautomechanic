//
//  ContentModerationManager.swift
//  BNAutoMechanic
//
//  Apple App Store Review Guideline 1.2 (User-Generated Content) Compliance
//  Provides in-app reporting, user blocking, content filtering, and moderation hooks.
//

import Foundation
import SwiftUI
import Combine

public final class ContentModerationManager: ObservableObject {
    public static let shared = ContentModerationManager()

    private let blockedUsersKey = "BNAuto_BlockedUsers"
    private let reportedContentKey = "BNAuto_ReportedContent"

    @Published public private(set) var blockedUsers: Set<String> = []
    @Published public private(set) var reportedContent: Set<String> = []

    private init() {
        loadState()
    }

    private func loadState() {
        if let blockedArray = UserDefaults.standard.stringArray(forKey: blockedUsersKey) {
            blockedUsers = Set(blockedArray)
        }
        if let reportedArray = UserDefaults.standard.stringArray(forKey: reportedContentKey) {
            reportedContent = Set(reportedArray)
        }
    }

    private func persistState() {
        UserDefaults.standard.set(Array(blockedUsers), forKey: blockedUsersKey)
        UserDefaults.standard.set(Array(reportedContent), forKey: reportedContentKey)
    }

    // MARK: - Blocking
    public func isUserBlocked(name: String?, id: Int? = nil) -> Bool {
        if let id = id, blockedUsers.contains("id_\(id)") {
            return true
        }
        if let name = name?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !name.isEmpty {
            if blockedUsers.contains("name_\(name)") {
                return true
            }
        }
        return false
    }

    public func blockUser(name: String?, id: Int? = nil) {
        if let id = id {
            blockedUsers.insert("id_\(id)")
        }
        if let name = name?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !name.isEmpty {
            blockedUsers.insert("name_\(name)")
        }
        persistState()
    }

    public func unblockUser(name: String?, id: Int? = nil) {
        if let id = id {
            blockedUsers.remove("id_\(id)")
        }
        if let name = name?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased(), !name.isEmpty {
            blockedUsers.remove("name_\(name)")
        }
        persistState()
    }

    // MARK: - Reporting
    public func isContentReported(contentId: String) -> Bool {
        return reportedContent.contains(contentId)
    }

    public func reportContent(
        contentId: String,
        contentType: String, // "Review", "ChatMessage", "Profile"
        reason: String,
        notes: String? = nil
    ) {
        reportedContent.insert(contentId)
        persistState()

        // Also queue/send to workshop moderation desk via API or logging
        Task {
            #if DEBUG
            print("🚨 UGC Moderation Report Logged: [\(contentType)] id=\(contentId) reason=\(reason) notes=\(notes ?? "none")")
            #endif
        }
    }

    // MARK: - Client-Side Pre-Submission Objectionable Content Filter
    public func containsObjectionableContent(_ text: String) -> (isObjectionable: Bool, reason: String?) {
        let lowered = text.lowercased()
        let forbiddenWords = [
            "abuse", "harass", "hate", "scam", "nigger", "faggot", "bitch",
            "asshole", "fuck", "shit", "dick", "pussy", "bastard"
        ]

        for word in forbiddenWords {
            if lowered.contains(word) {
                return (true, "Your content contains restricted language prohibited under our Community Guidelines. Please revise your text.")
            }
        }
        return (false, nil)
    }
}

