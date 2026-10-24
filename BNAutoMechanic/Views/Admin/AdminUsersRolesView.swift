//
//  AdminUsersRolesView.swift
//  BNAutoMechanic
//
//  Superadmin & Admin User Governance & Role Assignment Hub:
//  Full CRUD: Create staff/users, Read all accounts, Update roles & permissions, Delete accounts.
//

import SwiftUI
#if canImport(UIKit)
import UIKit
#endif

struct AdminUsersRolesView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject var session: SessionManager

    @State private var users: [User] = []
    @State private var selectedRoleFilter: String = "ALL"
    @State private var searchQuery: String = ""
    @State private var isLoading: Bool = false

    // Sheet States
    @State private var showCreateUserSheet: Bool = false
    @State private var userToEditRole: User? = nil
    @State private var userToDelete: User? = nil
    @State private var showDeleteConfirmAlert: Bool = false

    // Toast & Error
    @State private var toastMessage: String = ""
    @State private var showToast: Bool = false
    @State private var errorMessage: String = ""
    @State private var showErrorAlert: Bool = false

    private let rolesList = ["ALL", "SUPER_ADMIN", "ADMIN", "MECHANIC", "CUSTOMER"]

    private var filteredUsers: [User] {
        var list = users
        if selectedRoleFilter != "ALL" {
            list = list.filter { ($0.role?.uppercased() ?? "CUSTOMER") == selectedRoleFilter }
        }
        if !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty {
            let q = searchQuery.lowercased()
            list = list.filter {
                $0.name.lowercased().contains(q) ||
                $0.email.lowercased().contains(q) ||
                ($0.phone?.contains(q) ?? false)
            }
        }
        return list
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            usersHeader

            // Search Bar
            searchBarView

            // Role Filter Chips
            roleFilterChips

            // Content List
            if isLoading && users.isEmpty {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .primaryGold))
                    .scaleEffect(1.2)
                Spacer()
            } else if filteredUsers.isEmpty {
                Spacer()
                VStack(spacing: 12) {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 38))
                        .foregroundColor(.textSubtle)
                    Text("No users match query")
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.textForeground)
                }
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 10) {
                        ForEach(filteredUsers) { user in
                            userCardView(user)
                        }
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 10)
                    .bottomDockClearance()
                }
                .refreshable {
                    await loadUsers()
                }
            }
        }
        .background(Color.bgDark.ignoresSafeArea())
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .task {
            await loadUsers()
        }
        .sheet(item: $userToEditRole) { u in
            EditUserRoleSheet(user: u) {
                Task { await loadUsers() }
            }
        }
        .sheet(isPresented: $showCreateUserSheet) {
            CreateUserSheet {
                Task { await loadUsers() }
            }
        }
        .alert("Delete Account", isPresented: $showDeleteConfirmAlert) {
            Button("Delete Permanently", role: .destructive) {
                if let u = userToDelete {
                    Task { await deleteUser(id: u.id) }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete user \(userToDelete?.name ?? "") (\(userToDelete?.email ?? ""))? This cannot be undone.")
        }
        .alert("Error", isPresented: $showErrorAlert) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
        .overlay(alignment: .bottom) {
            if showToast {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                        .foregroundColor(.statusConfirmed)
                    Text(toastMessage)
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.textForeground)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(Color.cardDarkElevated)
                .cornerRadius(20)
                .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.primaryGold.opacity(0.5), lineWidth: 1))
                .padding(.bottom, 20)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    // MARK: - Header
    private var usersHeader: some View {
        HStack(spacing: 12) {
            Button {
                dismiss()
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.primaryGold)
                    .frame(width: 36, height: 36)
                    .background(Color.cardDarkElevated)
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.borderSubtle, lineWidth: 1)
                    )
            }

            VStack(alignment: .leading, spacing: 2) {
                Text("USERS & PERMISSIONS")
                    .font(.system(size: 18, weight: .black))
                    .foregroundColor(.primaryGold)
                    .tracking(1)
                Text("Role Elevation, Superadmin Rights & Customer Registry")
                    .font(.system(size: 11))
                    .foregroundColor(.textMuted)
            }

            Spacer()

            Button {
                triggerHaptic()
                showCreateUserSheet = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "person.badge.plus")
                        .font(.system(size: 12, weight: .bold))
                    Text("New User")
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(.bgDark)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.primaryGold)
                .cornerRadius(8)
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 6)
    }

    // MARK: - Search Bar
    private var searchBarView: some View {
        HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.primaryGold)
                .font(.system(size: 13))

            TextField("Search by name, email, phone...", text: $searchQuery)
                .font(.system(size: 12))
                .foregroundColor(.textForeground)

            if !searchQuery.isEmpty {
                Button { searchQuery = "" } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.textMuted)
                }
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color.cardDarkElevated)
        .cornerRadius(8)
        .padding(.horizontal, 16)
        .padding(.bottom, 4)
    }

    // MARK: - Filter Chips
    private var roleFilterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(rolesList, id: \.self) { r in
                    let isSelected = selectedRoleFilter == r
                    Button {
                        triggerHaptic()
                        withAnimation { selectedRoleFilter = r }
                    } label: {
                        Text(r.replacingOccurrences(of: "_", with: " "))
                            .font(.system(size: 11, weight: isSelected ? .bold : .medium))
                            .foregroundColor(isSelected ? .bgDark : .textForeground)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(isSelected ? Color.primaryGold : Color.cardDarkElevated)
                            .cornerRadius(8)
                            .overlay(RoundedRectangle(cornerRadius: 8).stroke(isSelected ? Color.primaryGold : Color.borderSubtle, lineWidth: 1))
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
    }

    // MARK: - User Card View
    private func userCardView(_ u: User) -> some View {
        let role = u.role?.uppercased() ?? "CUSTOMER"
        let isSuper = role == "SUPER_ADMIN" || role == "SUPERADMIN"
        let isAdmin = role == "ADMIN"
        let isMech = role == "MECHANIC" || role == "TECHNICIAN"

        return VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                // Avatar
                ZStack {
                    Circle()
                        .fill(isSuper ? Color.primaryGold : (isAdmin ? Color.primaryGold.opacity(0.3) : Color.cardDarkElevated))
                        .frame(width: 42, height: 42)
                        .overlay(Circle().stroke(Color.primaryGold, lineWidth: 1))
                    Text(u.initials())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(isSuper ? .bgDark : .primaryGold)
                }

                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text(u.name)
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.textForeground)

                        Spacer()

                        // Role Badge
                        Text(role.replacingOccurrences(of: "_", with: " "))
                            .font(.system(size: 9, weight: .black))
                            .foregroundColor(isSuper ? .bgDark : (isAdmin ? .primaryGold : (isMech ? .statusConfirmed : .textMuted)))
                            .padding(.horizontal, 7)
                            .padding(.vertical, 3)
                            .background(isSuper ? Color.primaryGold : (isAdmin ? Color.primaryGold.opacity(0.15) : (isMech ? Color.statusConfirmed.opacity(0.15) : Color.cardDarkElevated)))
                            .cornerRadius(6)
                    }

                    Text(u.email)
                        .font(.system(size: 11))
                        .foregroundColor(.textMuted)

                    if let p = u.phone, !p.isEmpty {
                        Text(p)
                            .font(.system(size: 10))
                            .foregroundColor(.textSubtle)
                    }
                }
            }

            Divider().background(Color.borderSubtle)

            // Actions: Change Role, Delete
            HStack(spacing: 10) {
                Button {
                    triggerHaptic()
                    userToEditRole = u
                } label: {
                    Label("Change Role & Access", systemImage: "key.fill")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.primaryGold)
                        .frame(maxWidth: .infinity)
                        .frame(height: 32)
                        .background(Color.cardDarkElevated)
                        .cornerRadius(6)
                        .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.primaryGold.opacity(0.6), lineWidth: 1))
                }

                // Delete Button (cannot delete self)
                if u.id != session.currentUser?.id {
                    Button {
                        triggerHaptic()
                        userToDelete = u
                        showDeleteConfirmAlert = true
                    } label: {
                        Image(systemName: "trash")
                            .font(.system(size: 12))
                            .foregroundColor(.statusCancelled)
                            .frame(width: 32, height: 32)
                            .background(Color.statusCancelled.opacity(0.12))
                            .cornerRadius(6)
                    }
                }
            }
        }
        .padding(12)
        .luxuryCard()
    }

    // MARK: - Backend Actions
    private func loadUsers() async {
        isLoading = true
        let api = APIService.shared
        if let resp = try? await api.getAdminUsers(perPage: 100) {
            await MainActor.run {
                users = resp.data?.items ?? []
                isLoading = false
            }
        } else {
            await MainActor.run { isLoading = false }
        }
    }

    private func deleteUser(id: Int) async {
        let api = APIService.shared
        do {
            _ = try await api.deleteUser(userId: id)
            await MainActor.run {
                toastMessage = "User deleted successfully."
                withAnimation { showToast = true }
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation { showToast = false }
                }
            }
            await loadUsers()
        } catch {
            await MainActor.run {
                errorMessage = error.localizedDescription
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

// MARK: - Edit User Role Sheet
struct EditUserRoleSheet: View {
    @Environment(\.dismiss) private var dismiss
    let user: User
    var onSaved: () -> Void

    @State private var selectedRole: String = "CUSTOMER"
    @State private var isSaving: Bool = false
    @State private var errorMessage: String = ""
    @State private var showErrorAlert: Bool = false

    private let availableRoles = [
        ("SUPER_ADMIN", "Superadministrator", "Unrestricted system control, settings, and deletion"),
        ("ADMIN", "Workshop Admin", "Staff dispatcher, approvals, estimates, and management"),
        ("MECHANIC", "Technician / Bay Mechanic", "Service bay access, job claiming, and status completion"),
        ("CUSTOMER", "Customer Account", "Booking appointments, vehicles garage, and invoicing")
    ]

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // User info card
                VStack(alignment: .leading, spacing: 4) {
                    Text(user.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.textForeground)
                    Text(user.email)
                        .font(.system(size: 12))
                        .foregroundColor(.textMuted)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(14)
                .luxuryCard()

                Text("ASSIGN ROLE LEVEL")
                    .font(.system(size: 11, weight: .black))
                    .foregroundColor(.primaryGold)
                    .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 10) {
                    ForEach(availableRoles, id: \.0) { roleKey, title, desc in
                        let isSelected = selectedRole == roleKey
                        Button {
                            selectedRole = roleKey
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 3) {
                                    Text(title)
                                        .font(.system(size: 13, weight: .bold))
                                        .foregroundColor(isSelected ? .primaryGold : .textForeground)
                                    Text(desc)
                                        .font(.system(size: 10))
                                        .foregroundColor(.textMuted)
                                        .multilineTextAlignment(.leading)
                                }
                                Spacer()
                                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(isSelected ? .primaryGold : .textSubtle)
                            }
                            .padding(12)
                            .background(isSelected ? Color.primaryGold.opacity(0.12) : Color.cardDarkElevated)
                            .cornerRadius(10)
                            .overlay(RoundedRectangle(cornerRadius: 10).stroke(isSelected ? Color.primaryGold : Color.borderSubtle, lineWidth: 1))
                        }
                    }
                }

                Spacer()

                Button {
                    Task { await saveRole() }
                } label: {
                    HStack {
                        if isSaving {
                            ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .bgDark))
                        }
                        Text(isSaving ? "Updating Role..." : "APPLY ROLE PERMISSION")
                            .font(.system(size: 13, weight: .black))
                    }
                    .foregroundColor(.bgDark)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(Color.primaryGold)
                    .cornerRadius(10)
                }
                .disabled(isSaving)
            }
            .padding(16)
            .background(Color.bgDark.ignoresSafeArea())
            .navigationTitle("Manage Role")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.textMuted)
                }
            }
            #endif
            .onAppear {
                selectedRole = user.role?.uppercased() ?? "CUSTOMER"
            }
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func saveRole() async {
        isSaving = true
        let api = APIService.shared
        do {
            _ = try await api.updateUserRole(userId: user.id, role: selectedRole)
            await MainActor.run {
                isSaving = false
                dismiss()
                onSaved()
            }
        } catch {
            await MainActor.run {
                isSaving = false
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
}

// MARK: - Create User Sheet
struct CreateUserSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onSaved: () -> Void

    @State private var name: String = ""
    @State private var email: String = ""
    @State private var phone: String = ""
    @State private var role: String = "CUSTOMER"
    @State private var password: String = "Password@123"
    @State private var isSaving: Bool = false
    @State private var errorMessage: String = ""
    @State private var showErrorAlert: Bool = false

    private let roles = ["CUSTOMER", "MECHANIC", "ADMIN", "SUPER_ADMIN"]

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("USER PROFILE").foregroundColor(.primaryGold)) {
                    TextField("Full Name", text: $name)
                    TextField("Email Address", text: $email)
                    TextField("Contact Phone", text: $phone)
                }

                Section(header: Text("ROLE & CREDENTIALS").foregroundColor(.primaryGold)) {
                    Picker("Role Level", selection: $role) {
                        ForEach(roles, id: \.self) { r in
                            Text(r.replacingOccurrences(of: "_", with: " ")).tag(r)
                        }
                    }
                    TextField("Initial Password", text: $password)
                }
            }
            .background(Color.bgDark)
            .scrollContentBackground(.hidden)
            .navigationTitle("Create User / Staff")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.textMuted)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isSaving ? "Creating..." : "Create") {
                        Task { await createUser() }
                    }
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.primaryGold)
                    .disabled(name.isEmpty || email.isEmpty || isSaving)
                }
            }
            #endif
            .alert("Error", isPresented: $showErrorAlert) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(errorMessage)
            }
        }
    }

    private func createUser() async {
        isSaving = true
        let req = CreateStaffRequest(
            name: name,
            email: email,
            phone: phone.isEmpty ? nil : phone,
            role: role,
            department: role == "MECHANIC" ? "Service Bay" : "Administration",
            password: password
        )

        do {
            _ = try await APIService.shared.createAdminStaff(req)
            await MainActor.run {
                isSaving = false
                dismiss()
                onSaved()
            }
        } catch {
            await MainActor.run {
                isSaving = false
                errorMessage = error.localizedDescription
                showErrorAlert = true
            }
        }
    }
}
