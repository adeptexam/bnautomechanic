//
//  PortalView.swift
//  BNAutoMechanic
//

import SwiftUI

struct PortalView: View {
    @EnvironmentObject var session: SessionManager
    @Binding var selectedTab: Int
    @State private var activeBooking: Booking?
    @State private var featuredServices: [Service] = []
    @State private var unreadCount = 0
    @State private var isRefreshing = false

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                // Header
                headerSection

                // Active Booking or Schedule Prompt
                if let booking = activeBooking {
                    activeBookingCard(booking)
                } else {
                    schedulePromptCard
                }

                // Towing Emergency Banner
                towingBanner

                // Quick Access Hub Grid
                hubGrid

                // Featured Services
                featuredServicesSection
            }
            .bottomDockClearance()
        }
        .refreshable {
            await loadPortalData()
        }
        .background(Color.bgDark.ignoresSafeArea())
        #if os(iOS)
        .toolbar(.hidden, for: .navigationBar)
        #endif
        .task {
            await loadPortalData()
        }
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack(spacing: 12) {
            // Profile avatar
            Button(action: { selectedTab = 4 }) {
                ZStack {
                    Circle()
                        .fill(Color.primaryGoldTint)
                        .frame(width: 42, height: 42)
                        .overlay(
                            Circle().stroke(Color.goldBorder, lineWidth: 1)
                        )
                    Text(session.currentUser?.initials() ?? "BN")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.primaryGold)
                }
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(greetingText)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.textForeground)
                Text("Your automotive dashboard")
                    .font(.system(size: 11))
                    .foregroundColor(.textMuted)
            }

            Spacer()

            // Notification Bell
            NavigationLink(destination: NotificationsView()) {
                ZStack(alignment: .topTrailing) {
                    Image(systemName: "bell.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.textMuted)
                        .frame(width: 40, height: 40)
                        .background(Color.cardDarkElevated)
                        .cornerRadius(10)

                    if unreadCount > 0 {
                        Text(unreadCount > 9 ? "9+" : "\(unreadCount)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.bgDark)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(Color.primaryGold)
                            .cornerRadius(8)
                            .offset(x: 4, y: -4)
                    }
                }
            }
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
        .padding(.bottom, 16)
    }

    private var greetingText: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let firstName = session.currentUser?.firstName() ?? "Guest"
        let greeting: String
        switch hour {
        case 0...11: greeting = "Good morning"
        case 12...17: greeting = "Good afternoon"
        default: greeting = "Good evening"
        }
        return "\(greeting), \(firstName)"
    }

    // MARK: - Active Booking Card
    private func activeBookingCard(_ booking: Booking) -> some View {
        NavigationLink(destination: BookingDetailView(bookingId: booking.id, bookingRef: booking.reference)) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Active Service Visit")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.primaryGold)
                        Text("Ref: \(booking.reference)")
                            .font(.system(size: 12))
                            .foregroundColor(.textMuted)
                    }
                    Spacer()
                    StatusBadge(status: booking.status)
                }

                Divider().background(Color.borderSubtle)

                HStack(spacing: 16) {
                    VStack(alignment: .leading, spacing: 4) {
                        Label(booking.servicesSummary(), systemImage: "wrench.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.textForeground)
                            .lineLimit(1)

                        Label(booking.vehicle?.displayName() ?? "Registered Vehicle", systemImage: "car.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.textMuted)
                            .lineLimit(1)

                        Label("\(booking.scheduledDate)  •  \(booking.scheduledTime)", systemImage: "clock.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.textMuted)
                    }
                    Spacer()
                }

                HStack {
                    Spacer()
                    Text("View Details →")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.primaryGold)
                }
            }
            .padding(16)
            .goldBorderCard()
        }
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Schedule Prompt
    private var schedulePromptCard: some View {
        VStack(spacing: 14) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 28))
                .foregroundColor(.primaryGold)

            Text("Schedule Your Next Service")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.textForeground)

            Text("Book an appointment with our certified technicians")
                .font(.system(size: 12))
                .foregroundColor(.textMuted)
                .multilineTextAlignment(.center)

            HStack(spacing: 12) {
                NavigationLink(destination: BookAppointmentView()) {
                    Text("Book Appointment")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.bgDark)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .background(Color.primaryGold)
                        .cornerRadius(10)
                }

                Button(action: { selectedTab = 2 }) {
                    Text("View History")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.textForeground)
                        .frame(maxWidth: .infinity)
                        .frame(height: 40)
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.borderMedium, lineWidth: 1)
                        )
                }
            }
        }
        .padding(20)
        .luxuryCard()
        .padding(.horizontal, 16)
        .padding(.top, 8)
    }

    // MARK: - Towing Banner
    private var towingBanner: some View {
        VStack(spacing: 12) {
            HStack {
                Image(systemName: "truck.box.fill")
                    .font(.system(size: 16))
                    .foregroundColor(.primaryGold)
                Text("ROADSIDE ASSISTANCE")
                    .font(.system(size: 12, weight: .black))
                    .foregroundColor(.primaryGold)
                    .tracking(0.5)
                Spacer()
            }

            Text("24/7 Emergency Towing & Roadside Help")
                .font(.system(size: 13))
                .foregroundColor(.textMuted)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 10) {
                NavigationLink(destination: TowingStatusView()) {
                    Label("Status", systemImage: "location.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.textForeground)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.borderMedium, lineWidth: 1)
                        )
                }

                Button(action: callTowing) {
                    Label("Call Now", systemImage: "phone.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.bgDark)
                        .frame(maxWidth: .infinity)
                        .frame(height: 36)
                        .background(Color.primaryGold)
                        .cornerRadius(8)
                }
            }
        }
        .padding(16)
        .luxuryCard()
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }

    private func callTowing() {
        if let url = URL(string: "tel:+16095550199") {
            #if os(iOS)
            UIApplication.shared.open(url)
            #endif
        }
    }

    // MARK: - Hub Grid
    private var hubGrid: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Quick Access")
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(.textForeground)
                .padding(.horizontal, 16)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 8), count: 3), spacing: 8) {
                hubItem(icon: "car.fill", label: "Vehicles", destination: AnyView(VehiclesView()))
                hubItem(icon: "doc.text.fill", label: "Invoices", destination: AnyView(InvoicesView()))
                hubItem(icon: "magnifyingglass", label: "Track Visit", destination: AnyView(TrackBookingView()))
                hubItem(icon: "clock.fill", label: "History", destination: AnyView(ServiceHistoryView()))
                hubItem(icon: "star.fill", label: "Reviews", destination: AnyView(ReviewsView()))
                hubItem(icon: "tag.fill", label: "Offers", destination: AnyView(DealsView()))
            }
            .padding(.horizontal, 16)
        }
        .padding(.top, 20)
    }

    private func hubItem(icon: String, label: String, destination: AnyView) -> some View {
        NavigationLink(destination: destination) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(.primaryGold)

                Text(label)
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.textForeground)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .luxuryCard()
        }
    }

    // MARK: - Featured Services
    private var featuredServicesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Featured Services")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.textForeground)
                Spacer()
                Button(action: { selectedTab = 1 }) {
                    Text("View all →")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.primaryGold)
                }
            }
            .padding(.horizontal, 16)

            ForEach(featuredServices) { service in
                NavigationLink(destination: ServiceDetailView(serviceId: service.id, serviceName: service.name, serviceDesc: service.description ?? service.shortDescription, serviceDuration: service.formattedDuration(), serviceCategory: service.category?.name ?? "Maintenance")) {
                    ServiceCardView(service: service)
                }
                .padding(.horizontal, 16)
            }
        }
        .padding(.top, 24)
    }

    // MARK: - Data Loading
    private func loadPortalData() async {
        let api = APIService.shared

        // Load active bookings
        if let response = try? await api.getBookings(perPage: 10) {
            let bookings = response.data?.items ?? []
            await MainActor.run {
                activeBooking = bookings.first(where: { !$0.isClosed() })
            }
        }

        // Load featured services
        var services: [Service] = []
        if let response = try? await api.getServices(perPage: 6, featured: true) {
            services = response.data?.items ?? []
        }
        if services.isEmpty {
            if let response = try? await api.getServices(perPage: 6) {
                services = response.data?.items ?? []
            }
        }
        await MainActor.run {
            featuredServices = services
        }

        // Load unread count
        if let response = try? await api.getUnreadCount() {
            await MainActor.run {
                unreadCount = response.data?.count ?? 0
            }
        }
    }
}

// MARK: - Service Card View
struct ServiceCardView: View {
    let service: Service

    var body: some View {
        HStack(spacing: 14) {
            // Service icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.primaryGoldTint)
                    .frame(width: 44, height: 44)
                Image(systemName: "wrench.and.screwdriver")
                    .font(.system(size: 18))
                    .foregroundColor(.primaryGold)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(service.name)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.textForeground)
                    .lineLimit(1)

                HStack(spacing: 8) {
                    if let cat = service.category?.name {
                        Text(cat)
                            .font(.system(size: 11))
                            .foregroundColor(.textMuted)
                    }
                    Text("•")
                        .foregroundColor(.textSubtle)
                        .font(.system(size: 11))
                    Text(service.formattedDuration())
                        .font(.system(size: 11))
                        .foregroundColor(.textMuted)
                }
            }

            Spacer()

            NavigationLink(destination: BookAppointmentView(preselectedServiceId: service.id)) {
                Text("Book")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.bgDark)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 7)
                    .background(Color.primaryGold)
                    .cornerRadius(8)
            }
        }
        .padding(14)
        .luxuryCard()
    }
}
