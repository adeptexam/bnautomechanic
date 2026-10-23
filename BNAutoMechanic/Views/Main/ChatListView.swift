//
//  ChatListView.swift
//  BNAutoMechanic
//

import SwiftUI

struct ChatListView: View {
    @State private var chatRooms: [ChatRoom] = []
    @State private var isLoading = false
    @State private var showNewEnquiryAlert = false
    @State private var newSubject = ""

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Messages")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.textForeground)
                Spacer()
                Button(action: { showNewEnquiryAlert = true }) {
                    Label("New", systemImage: "plus")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.bgDark)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(Color.primaryGold)
                        .cornerRadius(8)
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 12)

            Divider().background(Color.borderSubtle)

            if isLoading {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .primaryGold))
                Spacer()
            } else if chatRooms.isEmpty {
                Spacer()
                VStack(spacing: 14) {
                    Image(systemName: "bubble.left.and.bubble.right")
                        .font(.system(size: 40))
                        .foregroundColor(.textSubtle)
                    Text("No conversations yet")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.textMuted)
                    Text("Start an enquiry with our workshop advisors")
                        .font(.system(size: 13))
                        .foregroundColor(.textSubtle)

                    Button(action: { showNewEnquiryAlert = true }) {
                        Text("Start Chat")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.bgDark)
                            .padding(.horizontal, 24)
                            .padding(.vertical, 10)
                            .background(Color.primaryGold)
                            .cornerRadius(10)
                    }
                    .padding(.top, 4)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(chatRooms) { room in
                            NavigationLink(destination: ChatRoomView(roomId: room.id, roomSubject: room.subject ?? "Workshop Chat")) {
                                ChatRoomCardView(room: room)
                            }
                            Divider().background(Color.borderSubtle).padding(.leading, 64)
                        }
                    }
                    .padding(.bottom, 24)
                }
                .refreshable {
                    await loadRooms()
                }
            }
        }
        .background(Color.bgDark.ignoresSafeArea())
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .task {
            await loadRooms()
        }
        .alert("Start Workshop Enquiry", isPresented: $showNewEnquiryAlert) {
            TextField("e.g. Brake noise question...", text: $newSubject)
            Button("Create") {
                createRoom()
            }
            Button("Cancel", role: .cancel) {
                newSubject = ""
            }
        } message: {
            Text("What can our master mechanics assist you with?")
        }
    }

    private func loadRooms() async {
        isLoading = chatRooms.isEmpty
        if let response = try? await APIService.shared.getChatRooms() {
            await MainActor.run {
                chatRooms = response.data?.items ?? []
                isLoading = false
            }
        } else {
            await MainActor.run { isLoading = false }
        }
    }

    private func createRoom() {
        guard !newSubject.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        Task {
            if let response = try? await APIService.shared.createChatRoom(subject: newSubject.trimmingCharacters(in: .whitespaces)) {
                if let _ = response.data {
                    await loadRooms()
                }
            }
            await MainActor.run { newSubject = "" }
        }
    }
}

struct ChatRoomCardView: View {
    let room: ChatRoom

    var body: some View {
        HStack(spacing: 12) {
            // Avatar
            ZStack {
                Circle()
                    .fill(Color.primaryGoldTint)
                    .frame(width: 44, height: 44)
                Image(systemName: "bubble.left.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.primaryGold)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(room.subject ?? "General Enquiry")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.textForeground)
                    .lineLimit(1)

                Text(room.lastMessage ?? "No messages yet")
                    .font(.system(size: 12))
                    .foregroundColor(.textMuted)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                if let status = room.status {
                    Text(status)
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(status == "OPEN" ? .statusCompleted : .textSubtle)
                }
                Image(systemName: "chevron.right")
                    .font(.system(size: 12))
                    .foregroundColor(.textSubtle)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}

// MARK: - Chat Room View
struct ChatRoomView: View {
    let roomId: Int
    let roomSubject: String
    @State private var messages: [ChatMessage] = []
    @State private var messageText = ""
    @State private var isLoading = true
    @Environment(\.dismiss) var dismiss

    private var currentUserId: Int {
        SessionManager.shared.getUser()?.id ?? 0
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(spacing: 12) {
                Button(action: { dismiss() }) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.textForeground)
                        .frame(width: 36, height: 36)
                        .background(Color.cardDarkElevated)
                        .cornerRadius(10)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(roomSubject)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.textForeground)
                        .lineLimit(1)

                    Text("🟢 Admin Active")
                        .font(.system(size: 10))
                        .foregroundColor(.statusCompleted)
                }

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.bgDark)

            Divider().background(Color.borderSubtle)

            // Messages
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(messages) { msg in
                            chatBubble(msg)
                                .id(msg.id)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                }
                .onChange(of: messages.count) { _ in
                    if let last = messages.last {
                        withAnimation {
                            proxy.scrollTo(last.id, anchor: .bottom)
                        }
                    }
                }
            }

            Divider().background(Color.borderSubtle)

            // Input
            HStack(spacing: 10) {
                TextField("Type your message...", text: $messageText)
                    .font(.system(size: 14))
                    .foregroundColor(.textForeground)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(Color.cardDarkElevated)
                    .cornerRadius(20)

                Button(action: sendMessage) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 16))
                        .foregroundColor(.bgDark)
                        .frame(width: 40, height: 40)
                        .background(Color.primaryGold)
                        .cornerRadius(20)
                }
                .disabled(messageText.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color.bgDark)
        }
        .background(Color.surfaceDark.ignoresSafeArea())
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .task {
            await loadMessages()
            startPolling()
        }
    }

    private func chatBubble(_ msg: ChatMessage) -> some View {
        let isMe = msg.senderId == currentUserId
        return HStack {
            if isMe { Spacer(minLength: 60) }

            VStack(alignment: isMe ? .trailing : .leading, spacing: 4) {
                if !isMe {
                    Text(msg.senderName ?? "Workshop Advisor")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.primaryGold)
                }

                Text(msg.body)
                    .font(.system(size: 13))
                    .foregroundColor(isMe ? .bgDark : .textForeground)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                    .background(isMe ? Color.primaryGold : Color.cardDarkElevated)
                    .cornerRadius(16)

                if let time = msg.createdAt {
                    Text(time)
                        .font(.system(size: 9))
                        .foregroundColor(.textSubtle)
                }
            }

            if !isMe { Spacer(minLength: 60) }
        }
    }

    private func sendMessage() {
        let text = messageText.trimmingCharacters(in: .whitespaces)
        guard !text.isEmpty, text.count <= 250 else { return }

        let localMsg = ChatMessage(
            id: Int.random(in: 1000...9999),
            roomId: roomId,
            senderId: currentUserId,
            senderName: SessionManager.shared.getUser()?.name ?? "You",
            senderRole: "CUSTOMER",
            body: text,
            createdAt: DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .short)
        )

        messages.append(localMsg)
        messageText = ""

        Task {
            _ = try? await APIService.shared.sendMessage(roomId: roomId, body: text)
        }
    }

    private func loadMessages() async {
        if let response = try? await APIService.shared.getChatMessages(roomId: roomId) {
            await MainActor.run {
                messages = response.data?.items ?? []
                isLoading = false
            }
        } else {
            await MainActor.run { isLoading = false }
        }
    }

    private func startPolling() {
        Task {
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: 3_500_000_000) // 3.5 seconds
                if let response = try? await APIService.shared.getChatMessages(roomId: roomId) {
                    let newItems = response.data?.items ?? []
                    if newItems.count != messages.count {
                        await MainActor.run {
                            messages = newItems
                        }
                    }
                }
            }
        }
    }
}
