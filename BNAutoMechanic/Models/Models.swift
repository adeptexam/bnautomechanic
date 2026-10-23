//
//  Models.swift
//  BNAutoMechanic
//

import Foundation

// MARK: - API Response Wrapper
struct ApiResponse<T: Codable>: Codable {
    let success: Bool?
    let data: T?
    let message: String?
    let code: String?

    enum CodingKeys: String, CodingKey {
        case success, data, message, code
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Handle success as Bool, String, or Int
        if let boolVal = try? container.decode(Bool.self, forKey: .success) {
            success = boolVal
        } else if let strVal = try? container.decode(String.self, forKey: .success) {
            success = strVal.lowercased() == "true"
        } else if let intVal = try? container.decode(Int.self, forKey: .success) {
            success = intVal == 1
        } else {
            success = true
        }

        data = try? container.decode(T.self, forKey: .data)
        message = try? container.decode(String.self, forKey: .message)
        code = try? container.decode(String.self, forKey: .code)
    }

    init(success: Bool? = true, data: T? = nil, message: String? = nil, code: String? = nil) {
        self.success = success
        self.data = data
        self.message = message
        self.code = code
    }
}

struct Paginated<T: Codable>: Codable {
    let items: [T]?
    let total: Int?
    let page: Int?
    let perPage: Int?
    let pages: Int?

    enum CodingKeys: String, CodingKey {
        case items, total, page, pages, data, results, rows
        case perPage = "per_page"
    }

    init(items: [T]? = nil, total: Int? = nil, page: Int? = nil, perPage: Int? = nil, pages: Int? = nil) {
        self.items = items
        self.total = total
        self.page = page
        self.perPage = perPage
        self.pages = pages
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        total = try? container.decode(Int.self, forKey: .total)
        page = try? container.decode(Int.self, forKey: .page)
        perPage = try? container.decode(Int.self, forKey: .perPage)
        pages = try? container.decode(Int.self, forKey: .pages)

        // Try multiple keys for the items array
        if let i = try? container.decode([T].self, forKey: .items) {
            items = i
        } else if let i = try? container.decode([T].self, forKey: .data) {
            items = i
        } else if let i = try? container.decode([T].self, forKey: .results) {
            items = i
        } else if let i = try? container.decode([T].self, forKey: .rows) {
            items = i
        } else {
            items = []
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(items, forKey: .items)
        try container.encodeIfPresent(total, forKey: .total)
        try container.encodeIfPresent(page, forKey: .page)
        try container.encodeIfPresent(perPage, forKey: .perPage)
        try container.encodeIfPresent(pages, forKey: .pages)
    }
}

// MARK: - User
struct User: Codable, Identifiable {
    let id: Int
    let name: String
    let email: String
    let phone: String?
    let address: String?
    let city: String?
    let role: String?
    let status: String?
    let emailVerified: Bool?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, email, phone, address, city, role, status
        case emailVerified = "email_verified"
        case createdAt = "created_at"
    }

    func initials() -> String {
        let parts = name.trimmingCharacters(in: .whitespaces).split(separator: " ").map(String.init)
        if parts.count >= 2 {
            return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased()
        } else if let first = parts.first {
            return String(first.prefix(2)).uppercased()
        }
        return "BN"
    }

    func firstName() -> String {
        return name.trimmingCharacters(in: .whitespaces).split(separator: " ").first.map(String.init) ?? name
    }
}

// MARK: - Auth
struct AuthSession: Codable {
    let accessToken: String?
    let token: String?
    let refreshToken: String?
    let tokenType: String?
    let expiresIn: Int?
    let user: User?

    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case token
        case refreshToken = "refresh_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case user
    }

    func effectiveToken() -> String? {
        return accessToken ?? token
    }
}

struct LoginRequest: Codable {
    let email: String
    let password: String
}

struct RegisterRequest: Codable {
    let name: String
    let email: String
    let password: String
    let phone: String?
}

struct ForgotPasswordRequest: Codable {
    let email: String
}

struct ChangePasswordRequest: Codable {
    let currentPassword: String?
    let newPassword: String

    enum CodingKeys: String, CodingKey {
        case currentPassword = "current_password"
        case newPassword = "new_password"
    }
}

// MARK: - Vehicle
struct Vehicle: Codable, Identifiable {
    let id: Int
    let userId: Int?
    let make: String
    let model: String
    let year: Int
    let registrationNumber: String?
    let vin: String?
    let color: String?
    let vehicleType: String?

    enum CodingKeys: String, CodingKey {
        case id, make, model, year, vin, color
        case userId = "user_id"
        case registrationNumber = "registration_number"
        case vehicleType = "vehicle_type"
    }

    func displayName() -> String {
        let reg = (registrationNumber?.isEmpty == false) ? " (\(registrationNumber!))" : ""
        return "\(year) \(make) \(model)\(reg)"
    }
}

struct CreateVehicleRequest: Codable {
    let make: String
    let model: String
    let year: Int
    let registrationNumber: String?
    let vehicleType: String?

    enum CodingKeys: String, CodingKey {
        case make, model, year
        case registrationNumber = "registration_number"
        case vehicleType = "vehicle_type"
    }
}

// MARK: - Service
struct ServiceCategory: Codable, Identifiable {
    let id: Int
    let name: String
    let slug: String?
    let icon: String?
    let description: String?
}

struct ServiceFaq: Codable {
    let question: String
    let answer: String
}

struct Service: Codable, Identifiable {
    let id: Int
    let name: String
    let slug: String?
    let status: String?
    let featured: Bool?
    let imageUrl: String?
    let categoryId: Int?
    let category: ServiceCategory?
    let description: String?
    let shortDescription: String?
    let durationMinutes: Int?
    let warrantyInfo: String?
    let benefits: [String]?
    let includedItems: [String]?
    let faqs: [ServiceFaq]?
    let ratingAverage: Double?
    let reviewsCount: Int?

    enum CodingKeys: String, CodingKey {
        case id, name, slug, status, featured, category, description, benefits, faqs
        case imageUrl = "image_url"
        case categoryId = "category_id"
        case shortDescription = "short_description"
        case durationMinutes = "duration_minutes"
        case warrantyInfo = "warranty_info"
        case includedItems = "included_items"
        case ratingAverage = "rating_average"
        case reviewsCount = "reviews_count"
    }

    func formattedDuration() -> String {
        guard let mins = durationMinutes else { return "Flexible" }
        if mins < 60 { return "\(mins)m" }
        if mins % 60 == 0 { return "\(mins / 60)h" }
        return "\(mins / 60)h \(mins % 60)m"
    }
}

// MARK: - Booking
struct BookingService: Codable, Identifiable {
    let id: Int
    let bookingId: Int?
    let serviceId: Int?
    let serviceName: String
    let quantity: Int?
    let durationMinutes: Int?
    let price: Double?

    enum CodingKeys: String, CodingKey {
        case id, quantity, price
        case bookingId = "booking_id"
        case serviceId = "service_id"
        case serviceName = "service_name"
        case durationMinutes = "duration_minutes"
    }
}

struct TowingDetails: Codable {
    let pickupLocation: String?
    let destination: String?
    let contactPhone: String?
    let urgency: String?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case destination, urgency, status
        case pickupLocation = "pickup_location"
        case contactPhone = "contact_phone"
    }
}

struct Estimate: Codable {
    let id: Int?
    let partsCost: Double?
    let laborCost: Double?
    let tax: Double?
    let total: Double?
    let status: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case id, tax, total, status, notes
        case partsCost = "parts_cost"
        case laborCost = "labor_cost"
    }
}

struct BookingExtra: Codable, Identifiable {
    let id: Int
    let title: String
    let cost: Double?
    let status: String?
}

struct AppliedCoupon: Codable {
    let code: String
    let discountAmount: Double?
    let description: String?

    enum CodingKeys: String, CodingKey {
        case code, description
        case discountAmount = "discount_amount"
    }
}

struct Booking: Codable, Identifiable {
    let id: Int
    let reference: String
    let status: String
    let userId: Int?
    let vehicleId: Int?
    let mechanicId: Int?
    let scheduledDate: String
    let scheduledTime: String
    let notes: String?
    let totalAmount: Double?
    let paymentStatus: String?
    let amountPaid: Double?
    let balanceDue: Double?
    let customerName: String?
    let customerEmail: String?
    let customerPhone: String?
    let services: [BookingService]?
    let vehicle: Vehicle?
    let towing: TowingDetails?
    let estimate: Estimate?
    let extras: [BookingExtra]?
    let coupon: AppliedCoupon?
    let invoiceId: Int?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, reference, status, notes, services, vehicle, towing, estimate, extras, coupon
        case userId = "user_id"
        case vehicleId = "vehicle_id"
        case mechanicId = "mechanic_id"
        case scheduledDate = "scheduled_date"
        case scheduledTime = "scheduled_time"
        case totalAmount = "total_amount"
        case paymentStatus = "payment_status"
        case amountPaid = "amount_paid"
        case balanceDue = "balance_due"
        case customerName = "customer_name"
        case customerEmail = "customer_email"
        case customerPhone = "customer_phone"
        case invoiceId = "invoice_id"
        case createdAt = "created_at"
    }

    func servicesSummary() -> String {
        return services?.map { $0.serviceName }.joined(separator: ", ") ?? "Auto Service"
    }

    func isClosed() -> Bool {
        let closed = ["COMPLETED", "CANCELLED", "DECLINED", "NO_SHOW"]
        return closed.contains(status.uppercased())
    }

    func canCancel() -> Bool {
        let cancellable = ["PENDING", "APPROVED_FOR_ESTIMATE", "ESTIMATE_SENT", "ESTIMATE_REJECTED", "CONFIRMED", "ASSIGNED"]
        return cancellable.contains(status.uppercased())
    }

    func canReschedule() -> Bool {
        let reschedulable = ["PENDING", "APPROVED_FOR_ESTIMATE", "ESTIMATE_SENT", "ESTIMATE_REJECTED", "CONFIRMED"]
        return reschedulable.contains(status.uppercased())
    }
}

struct CreateBookingRequest: Codable {
    let serviceIds: [Int]
    let vehicleId: Int?
    let vehicle: CreateVehicleRequest?
    let scheduledDate: String
    let scheduledTime: String
    let notes: String?
    let couponCode: String?

    enum CodingKeys: String, CodingKey {
        case vehicle, notes
        case serviceIds = "service_ids"
        case vehicleId = "vehicle_id"
        case scheduledDate = "scheduled_date"
        case scheduledTime = "scheduled_time"
        case couponCode = "coupon_code"
    }
}

struct Availability: Codable {
    let date: String?
    let availableSlots: [String]?
    let isOpen: Bool?

    enum CodingKeys: String, CodingKey {
        case date
        case availableSlots = "available_slots"
        case isOpen = "is_open"
    }
}

struct BookingTrack: Codable {
    let booking: Booking?
    let reference: String?
    let status: String?
    let vehicleSummary: String?
    let timeline: [String]?

    enum CodingKeys: String, CodingKey {
        case booking, reference, status, timeline
        case vehicleSummary = "vehicle_summary"
    }
}

// MARK: - Chat
struct ChatRoom: Codable, Identifiable {
    let id: Int
    let subject: String?
    let status: String?
    let userId: Int?
    let customerName: String?
    let lastMessage: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, subject, status
        case userId = "user_id"
        case customerName = "customer_name"
        case lastMessage = "last_message"
        case updatedAt = "updated_at"
    }
}

struct ChatMessage: Codable, Identifiable {
    let id: Int
    let roomId: Int?
    let senderId: Int?
    let senderName: String?
    let senderRole: String?
    let body: String
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, body
        case roomId = "room_id"
        case senderId = "sender_id"
        case senderName = "sender_name"
        case senderRole = "sender_role"
        case createdAt = "created_at"
    }
}

struct SendMessageRequest: Codable {
    let body: String
}

struct CreateRoomRequest: Codable {
    let subject: String
}

// MARK: - Notifications
struct AppNotification: Codable, Identifiable {
    let id: Int
    let userId: Int?
    let title: String
    let message: String
    let type: String?
    var read: Bool
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title, message, type, read
        case userId = "user_id"
        case createdAt = "created_at"
    }
}

struct UnreadCount: Codable {
    let count: Int
}

// MARK: - Invoice
struct Invoice: Codable, Identifiable {
    let id: Int
    let invoiceNumber: String
    let bookingId: Int?
    let bookingReference: String?
    let status: String?
    let subtotal: Double?
    let tax: Double?
    let discount: Double?
    let total: Double?
    let amountPaid: Double?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, status, subtotal, tax, discount, total
        case invoiceNumber = "invoice_number"
        case bookingId = "booking_id"
        case bookingReference = "booking_reference"
        case amountPaid = "amount_paid"
        case createdAt = "created_at"
    }
}

// MARK: - Review
struct Review: Codable, Identifiable {
    let id: Int
    let userName: String?
    let rating: Int
    let comment: String?
    let serviceName: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, rating, comment
        case userName = "user_name"
        case serviceName = "service_name"
        case createdAt = "created_at"
    }
}

struct ReviewSummary: Codable {
    let average: Double?
    let total: Int?
    let distribution: [String: Int]?
}

struct CreateReviewRequest: Codable {
    let rating: Int
    let comment: String?
    let bookingId: Int?
    let serviceId: Int?

    enum CodingKeys: String, CodingKey {
        case rating, comment
        case bookingId = "booking_id"
        case serviceId = "service_id"
    }
}

// MARK: - Deal
struct Deal: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String?
    let code: String
    let discountPercent: Double?
    let discountAmount: Double?
    let expiresAt: String?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case id, title, description, code, status
        case discountPercent = "discount_percent"
        case discountAmount = "discount_amount"
        case expiresAt = "expires_at"
    }
}

// MARK: - Settings
struct PublicSettings: Codable {
    let phone: String?
    let emergencyPhone: String?
    let email: String?
    let address: String?
    let operatingHours: String?

    enum CodingKeys: String, CodingKey {
        case phone, email, address
        case emergencyPhone = "emergency_phone"
        case operatingHours = "operating_hours"
    }
}
