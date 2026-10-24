//
//  Models.swift
//  BNAutoMechanic
//
//  Database-backed data models aligned with backend API: https://api.bnautomechanic.net/api/v1/
//  Covers all 27 database schema tables and relationships.
//

import Foundation

// MARK: - Image Resolution Helper
extension String {
    public func resolvedApiImageUrl() -> String {
        let trimmed = self.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.hasPrefix("http://") || trimmed.hasPrefix("https://") {
            return trimmed
        }
        if trimmed.hasPrefix("/") {
            return "https://api.bnautomechanic.net" + trimmed
        }
        return "https://api.bnautomechanic.net/" + trimmed
    }
}

// MARK: - API Response Wrapper
struct ApiMeta: Codable {
    let page: Int?
    let perPage: Int?
    let total: Int?
    let totalPages: Int?

    enum CodingKeys: String, CodingKey {
        case page, total
        case perPage = "per_page"
        case totalPages = "total_pages"
    }
}

struct ApiErrorDetail: Codable {
    let code: String?
    let message: String?
}

struct ApiResponse<T: Codable>: Codable {
    let success: Bool?
    let data: T?
    let message: String?
    let code: String?
    let error: ApiErrorDetail?
    let meta: ApiMeta?

    enum CodingKeys: String, CodingKey {
        case success, data, message, code, error, meta
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
        meta = try? container.decode(ApiMeta.self, forKey: .meta)
        error = try? container.decode(ApiErrorDetail.self, forKey: .error)

        let msg = try? container.decode(String.self, forKey: .message)
        message = msg ?? error?.message

        let cd = try? container.decode(String.self, forKey: .code)
        code = cd ?? error?.code
    }

    init(success: Bool?, data: T?, message: String?, code: String?) {
        self.success = success
        self.data = data
        self.message = message
        self.code = code
        self.error = nil
        self.meta = nil
    }

    init(from directData: T) {
        self.init(success: true, data: directData, message: nil, code: nil)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(success, forKey: .success)
        try container.encodeIfPresent(data, forKey: .data)
        try container.encodeIfPresent(message, forKey: .message)
        try container.encodeIfPresent(code, forKey: .code)
        try container.encodeIfPresent(error, forKey: .error)
        try container.encodeIfPresent(meta, forKey: .meta)
    }
}

// MARK: - Paginated List Container
// Safely decodes whether the API returns an array directly: {"data": [...]}
// or an object containing {"items": [...], "total": ...}
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
        // Case 1: The container is an array directly: [T]
        if let singleContainer = try? decoder.singleValueContainer(),
           let directArray = try? singleContainer.decode([T].self) {
            self.items = directArray
            self.total = directArray.count
            self.page = 1
            self.perPage = directArray.count
            self.pages = 1
            return
        }

        // Case 2: Standard dictionary container
        let container = try decoder.container(keyedBy: CodingKeys.self)
        total = try? container.decode(Int.self, forKey: .total)
        page = try? container.decode(Int.self, forKey: .page)
        perPage = try? container.decode(Int.self, forKey: .perPage)
        pages = try? container.decode(Int.self, forKey: .pages)

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

// MARK: - Table: users
struct User: Codable, Identifiable {
    let id: Int
    let name: String
    let email: String
    let phone: String?
    let role: String?
    let avatarUrl: String?
    let address: String?
    let city: String?
    let status: String?
    let emailVerified: Bool?
    let altPhone: String?
    let dateOfBirth: String?
    let gender: String?
    let state: String?
    let postalCode: String?
    let country: String?
    let companyName: String?
    let taxId: String?
    let preferredContact: String?
    let bio: String?
    let showOnAbout: Bool?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, email, phone, role, address, city, status, gender, state, country, bio
        case avatarUrl = "avatar_url"
        case emailVerified = "email_verified"
        case altPhone = "alt_phone"
        case dateOfBirth = "date_of_birth"
        case postalCode = "postal_code"
        case companyName = "company_name"
        case taxId = "tax_id"
        case preferredContact = "preferred_contact"
        case showOnAbout = "show_on_about"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(
        id: Int,
        name: String,
        email: String,
        phone: String? = nil,
        role: String? = "CUSTOMER",
        avatarUrl: String? = nil,
        address: String? = nil,
        city: String? = nil,
        status: String? = "ACTIVE",
        emailVerified: Bool? = false,
        altPhone: String? = nil,
        dateOfBirth: String? = nil,
        gender: String? = nil,
        state: String? = nil,
        postalCode: String? = nil,
        country: String? = nil,
        companyName: String? = nil,
        taxId: String? = nil,
        preferredContact: String? = nil,
        bio: String? = nil,
        showOnAbout: Bool? = nil,
        createdAt: String? = nil,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.name = name
        self.email = email
        self.phone = phone
        self.role = role
        self.avatarUrl = avatarUrl
        self.address = address
        self.city = city
        self.status = status
        self.emailVerified = emailVerified
        self.altPhone = altPhone
        self.dateOfBirth = dateOfBirth
        self.gender = gender
        self.state = state
        self.postalCode = postalCode
        self.country = country
        self.companyName = companyName
        self.taxId = taxId
        self.preferredContact = preferredContact
        self.bio = bio
        self.showOnAbout = showOnAbout
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(
        id: Int,
        name: String,
        email: String,
        phone: String?,
        address: String?,
        city: String?,
        role: String?,
        status: String?,
        emailVerified: Bool?,
        createdAt: String?
    ) {
        self.init(
            id: id,
            name: name,
            email: email,
            phone: phone,
            role: role,
            avatarUrl: nil,
            address: address,
            city: city,
            status: status,
            emailVerified: emailVerified,
            createdAt: createdAt
        )
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

    func fullAvatarUrl() -> String? {
        return avatarUrl?.resolvedApiImageUrl()
    }

    var userRole: UserRole {
        guard let r = role?.uppercased() else { return .customer }
        if r == "SUPER_ADMIN" || r == "SUPERADMIN" { return .superAdmin }
        if r == "ADMIN" { return .admin }
        if r == "EDITOR" { return .editor }
        if r == "MECHANIC" || r == "TECHNICIAN" { return .mechanic }
        if r == "STAFF" { return .staff }
        return .customer
    }

    var isSuperAdmin: Bool { userRole.isSuperAdmin }
    var isAdmin: Bool { userRole.isAdmin }
    var isMechanic: Bool { userRole.isMechanic }
    var isStaff: Bool { userRole.isStaff }
}

// MARK: - User Roles & Portals
enum UserRole: String, Codable, CaseIterable {
    case superAdmin = "SUPER_ADMIN"
    case admin = "ADMIN"
    case editor = "EDITOR"
    case mechanic = "MECHANIC"
    case staff = "STAFF"
    case customer = "CUSTOMER"

    var isSuperAdmin: Bool { self == .superAdmin }
    var isAdmin: Bool { self == .superAdmin || self == .admin }
    var isMechanic: Bool { self == .mechanic }
    var isStaff: Bool { self == .superAdmin || self == .admin || self == .editor || self == .mechanic || self == .staff }

    var displayName: String {
        switch self {
        case .superAdmin: return "Superadministrator"
        case .admin: return "Workshop Admin"
        case .editor: return "Service Editor"
        case .mechanic: return "Technician / Mechanic"
        case .staff: return "Workshop Staff"
        case .customer: return "Customer Account"
        }
    }
}

enum PortalMode: String, CaseIterable, Identifiable {
    case superadmin = "Superadmin"
    case admin = "Admin"
    case technician = "Technician"
    case customer = "Customer"

    var id: String { rawValue }
}

// MARK: - Auth & Sessions
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

// MARK: - Table: vehicles
struct Vehicle: Codable, Identifiable {
    let id: Int
    let userId: Int?
    let make: String
    let model: String
    let variant: String?
    let year: Int
    let registrationNumber: String?
    let engineNumber: String?
    let vin: String?
    let mileage: Int?
    let fuelType: String?
    let transmission: String?
    let color: String?
    let vehicleType: String?
    let notes: String?
    let mechanicId: Int?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, make, model, variant, year, vin, color, notes, mileage, transmission
        case userId = "user_id"
        case registrationNumber = "registration_number"
        case engineNumber = "engine_number"
        case fuelType = "fuel_type"
        case vehicleType = "vehicle_type"
        case mechanicId = "mechanic_id"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    func displayName() -> String {
        if let reg = registrationNumber, !reg.isEmpty {
            return "\(year) \(make) \(model) (\(reg))"
        }
        return "\(year) \(make) \(model)"
    }

    init(
        id: Int,
        userId: Int? = nil,
        make: String,
        model: String,
        variant: String? = nil,
        year: Int,
        registrationNumber: String? = nil,
        engineNumber: String? = nil,
        vin: String? = nil,
        mileage: Int? = nil,
        fuelType: String? = nil,
        transmission: String? = nil,
        color: String? = nil,
        vehicleType: String? = nil,
        notes: String? = nil,
        mechanicId: Int? = nil,
        createdAt: String? = nil,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.make = make
        self.model = model
        self.variant = variant
        self.year = year
        self.registrationNumber = registrationNumber
        self.engineNumber = engineNumber
        self.vin = vin
        self.mileage = mileage
        self.fuelType = fuelType
        self.transmission = transmission
        self.color = color
        self.vehicleType = vehicleType
        self.notes = notes
        self.mechanicId = mechanicId
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

struct CreateVehicleRequest: Codable {
    let make: String
    let model: String
    let year: Int
    let variant: String?
    let registrationNumber: String?
    let engineNumber: String?
    let vin: String?
    let mileage: Int?
    let fuelType: String?
    let transmission: String?
    let color: String?
    let vehicleType: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case make, model, year, variant, vin, color, notes, mileage, transmission
        case registrationNumber = "registration_number"
        case engineNumber = "engine_number"
        case fuelType = "fuel_type"
        case vehicleType = "vehicle_type"
    }

    init(
        make: String,
        model: String,
        year: Int,
        variant: String? = nil,
        registrationNumber: String? = nil,
        engineNumber: String? = nil,
        vin: String? = nil,
        mileage: Int? = nil,
        fuelType: String? = nil,
        transmission: String? = nil,
        color: String? = nil,
        vehicleType: String? = nil,
        notes: String? = nil
    ) {
        self.make = make
        self.model = model
        self.year = year
        self.variant = variant
        self.registrationNumber = registrationNumber
        self.engineNumber = engineNumber
        self.vin = vin
        self.mileage = mileage
        self.fuelType = fuelType
        self.transmission = transmission
        self.color = color
        self.vehicleType = vehicleType
        self.notes = notes
    }
}

// MARK: - Table: brands
struct Brand: Codable, Identifiable {
    let id: Int
    let name: String
    let logoUrl: String?
    let displayOrder: Int?
    let status: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, status
        case logoUrl = "logo_url"
        case displayOrder = "display_order"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    func fullLogoUrl() -> String? {
        return logoUrl?.resolvedApiImageUrl()
    }
}

// MARK: - Table: categories
struct ServiceCategory: Codable, Identifiable {
    let id: Int
    let name: String
    let slug: String?
    let icon: String?
    let imageUrl: String?
    let description: String?
    let displayOrder: Int?
    let status: String?
    let servicesCount: Int?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, slug, icon, description, status
        case imageUrl = "image_url"
        case displayOrder = "display_order"
        case servicesCount = "services_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    func fullImageUrl() -> String? {
        return imageUrl?.resolvedApiImageUrl()
    }
}

// MARK: - Table: services
struct ServiceFaq: Codable {
    let question: String
    let answer: String
}

struct Service: Codable, Identifiable {
    let id: Int
    let categoryId: Int?
    let name: String
    let slug: String?
    let description: String?
    let shortDescription: String?
    let imageUrl: String?
    let basePrice: Double?
    let salePrice: Double?
    let durationMinutes: Int?
    let featured: Bool?
    let status: String?
    let displayOrder: Int?
    let includedItems: [String]?
    let warrantyInfo: String?
    let benefits: [String]?
    let faqs: [ServiceFaq]?
    let ratingAverage: Double?
    let reviewsCount: Int?
    let features: [String]?
    let tags: [String]?
    let category: ServiceCategory?
    let createdAt: String?
    let updatedAt: String?

    var price: Double? {
        return salePrice ?? basePrice
    }

    var effectivePrice: Double {
        return salePrice ?? basePrice ?? 0.0
    }

    func effectivePrice() -> Double {
        return effectivePrice
    }

    enum CodingKeys: String, CodingKey {
        case id, name, slug, description, featured, status, benefits, faqs, features, tags, category
        case categoryId = "category_id"
        case shortDescription = "short_description"
        case imageUrl = "image_url"
        case price
        case basePrice = "base_price"
        case salePrice = "sale_price"
        case durationMinutes = "duration_minutes"
        case displayOrder = "display_order"
        case includedItems = "included_items"
        case warrantyInfo = "warranty_info"
        case ratingAverage = "rating_average"
        case reviewsCount = "reviews_count"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        categoryId = try? container.decode(Int.self, forKey: .categoryId)
        slug = try? container.decode(String.self, forKey: .slug)
        description = try? container.decode(String.self, forKey: .description)
        shortDescription = try? container.decode(String.self, forKey: .shortDescription)
        imageUrl = try? container.decode(String.self, forKey: .imageUrl)

        // Support both "price" and "base_price" keys
        basePrice = (try? container.decode(Double.self, forKey: .price)) ?? (try? container.decode(Double.self, forKey: .basePrice))
        salePrice = try? container.decode(Double.self, forKey: .salePrice)
        durationMinutes = try? container.decode(Int.self, forKey: .durationMinutes)
        featured = try? container.decode(Bool.self, forKey: .featured)
        status = try? container.decode(String.self, forKey: .status)
        displayOrder = try? container.decode(Int.self, forKey: .displayOrder)
        warrantyInfo = try? container.decode(String.self, forKey: .warrantyInfo)
        ratingAverage = try? container.decode(Double.self, forKey: .ratingAverage)
        reviewsCount = try? container.decode(Int.self, forKey: .reviewsCount)
        category = try? container.decode(ServiceCategory.self, forKey: .category)
        createdAt = try? container.decode(String.self, forKey: .createdAt)
        updatedAt = try? container.decode(String.self, forKey: .updatedAt)

        // Arrays with string fallback
        includedItems = try? container.decode([String].self, forKey: .includedItems)
        benefits = try? container.decode([String].self, forKey: .benefits)
        faqs = try? container.decode([ServiceFaq].self, forKey: .faqs)
        features = try? container.decode([String].self, forKey: .features)
        tags = try? container.decode([String].self, forKey: .tags)
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(categoryId, forKey: .categoryId)
        try container.encodeIfPresent(slug, forKey: .slug)
        try container.encodeIfPresent(description, forKey: .description)
        try container.encodeIfPresent(shortDescription, forKey: .shortDescription)
        try container.encodeIfPresent(imageUrl, forKey: .imageUrl)
        try container.encodeIfPresent(basePrice, forKey: .basePrice)
        try container.encodeIfPresent(salePrice, forKey: .salePrice)
        try container.encodeIfPresent(durationMinutes, forKey: .durationMinutes)
        try container.encodeIfPresent(featured, forKey: .featured)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(displayOrder, forKey: .displayOrder)
        try container.encodeIfPresent(includedItems, forKey: .includedItems)
        try container.encodeIfPresent(warrantyInfo, forKey: .warrantyInfo)
        try container.encodeIfPresent(benefits, forKey: .benefits)
        try container.encodeIfPresent(faqs, forKey: .faqs)
        try container.encodeIfPresent(ratingAverage, forKey: .ratingAverage)
        try container.encodeIfPresent(reviewsCount, forKey: .reviewsCount)
        try container.encodeIfPresent(features, forKey: .features)
        try container.encodeIfPresent(tags, forKey: .tags)
        try container.encodeIfPresent(category, forKey: .category)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
    }

    init(
        id: Int,
        name: String,
        slug: String? = nil,
        status: String? = nil,
        featured: Bool? = nil,
        imageUrl: String? = nil,
        categoryId: Int? = nil,
        category: ServiceCategory? = nil,
        description: String? = nil,
        shortDescription: String? = nil,
        basePrice: Double? = nil,
        salePrice: Double? = nil,
        durationMinutes: Int? = nil,
        displayOrder: Int? = nil,
        warrantyInfo: String? = nil,
        benefits: [String]? = nil,
        includedItems: [String]? = nil,
        faqs: [ServiceFaq]? = nil,
        ratingAverage: Double? = nil,
        reviewsCount: Int? = nil,
        features: [String]? = nil,
        tags: [String]? = nil,
        createdAt: String? = nil,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.name = name
        self.slug = slug
        self.status = status
        self.featured = featured
        self.imageUrl = imageUrl
        self.categoryId = categoryId
        self.category = category
        self.description = description
        self.shortDescription = shortDescription
        self.basePrice = basePrice
        self.salePrice = salePrice
        self.durationMinutes = durationMinutes
        self.displayOrder = displayOrder
        self.warrantyInfo = warrantyInfo
        self.benefits = benefits
        self.includedItems = includedItems
        self.faqs = faqs
        self.ratingAverage = ratingAverage
        self.reviewsCount = reviewsCount
        self.features = features
        self.tags = tags
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    init(
        id: Int,
        categoryId: Int?,
        name: String,
        slug: String? = nil,
        description: String? = nil,
        shortDescription: String? = nil,
        imageUrl: String? = nil,
        basePrice: Double? = nil,
        salePrice: Double? = nil,
        durationMinutes: Int? = nil,
        featured: Bool? = nil,
        status: String? = nil,
        displayOrder: Int? = nil,
        includedItems: [String]? = nil,
        warrantyInfo: String? = nil,
        benefits: [String]? = nil,
        faqs: [ServiceFaq]? = nil,
        ratingAverage: Double? = nil,
        reviewsCount: Int? = nil,
        features: [String]? = nil,
        tags: [String]? = nil,
        category: ServiceCategory? = nil,
        createdAt: String? = nil,
        updatedAt: String? = nil
    ) {
        self.init(
            id: id,
            name: name,
            slug: slug,
            status: status,
            featured: featured,
            imageUrl: imageUrl,
            categoryId: categoryId,
            category: category,
            description: description,
            shortDescription: shortDescription,
            basePrice: basePrice,
            salePrice: salePrice,
            durationMinutes: durationMinutes,
            displayOrder: displayOrder,
            warrantyInfo: warrantyInfo,
            benefits: benefits,
            includedItems: includedItems,
            faqs: faqs,
            ratingAverage: ratingAverage,
            reviewsCount: reviewsCount,
            features: features,
            tags: tags,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    func formattedDuration() -> String {
        guard let mins = durationMinutes else { return "Flexible" }
        if mins < 60 { return "\(mins)m" }
        if mins % 60 == 0 { return "\(mins / 60)h" }
        return "\(mins / 60)h \(mins % 60)m"
    }

    func formattedPrice() -> String {
        if let sp = salePrice, sp > 0 {
            return String(format: "$%.2f", sp)
        }
        guard let p = basePrice, p > 0 else { return "Price on request" }
        return String(format: "$%.2f", p)
    }

    func fullImageUrl() -> String? {
        return imageUrl?.resolvedApiImageUrl()
    }
}

// MARK: - Table: bookings
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
        case name
        case durationMinutes = "duration_minutes"
    }

    init(id: Int = 0, serviceName: String, price: Double? = nil, quantity: Int? = 1) {
        self.id = id
        self.bookingId = nil
        self.serviceId = nil
        self.serviceName = serviceName
        self.quantity = quantity
        self.durationMinutes = nil
        self.price = price
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = (try? container.decode(Int.self, forKey: .id)) ?? 0
        bookingId = try? container.decode(Int.self, forKey: .bookingId)
        serviceId = try? container.decode(Int.self, forKey: .serviceId)
        quantity = try? container.decode(Int.self, forKey: .quantity)
        durationMinutes = try? container.decode(Int.self, forKey: .durationMinutes)
        price = try? container.decode(Double.self, forKey: .price)

        let sName = (try? container.decode(String.self, forKey: .serviceName)) ?? (try? container.decode(String.self, forKey: .name))
        serviceName = sName ?? "Vehicle Service"
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(bookingId, forKey: .bookingId)
        try container.encodeIfPresent(serviceId, forKey: .serviceId)
        try container.encode(serviceName, forKey: .serviceName)
        try container.encodeIfPresent(quantity, forKey: .quantity)
        try container.encodeIfPresent(durationMinutes, forKey: .durationMinutes)
        try container.encodeIfPresent(price, forKey: .price)
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

struct EstimateItem: Codable, Identifiable {
    var id: String { "\(name)-\(unitPrice)-\(quantity)" }
    let name: String
    let description: String?
    let type: String?
    let unitPrice: Double
    let quantity: Double
    let total: Double

    enum CodingKeys: String, CodingKey {
        case name, description, type, total, quantity
        case unitPrice = "unit_price"
        case price
    }

    init(name: String, description: String? = nil, type: String? = "service", unitPrice: Double, quantity: Double = 1.0) {
        self.name = name
        self.description = description
        self.type = type
        self.unitPrice = unitPrice
        self.quantity = quantity
        self.total = unitPrice * quantity
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        name = (try? c.decode(String.self, forKey: .name)) ?? "Service Item"
        description = try? c.decode(String.self, forKey: .description)
        type = try? c.decode(String.self, forKey: .type)
        let up = (try? c.decode(Double.self, forKey: .unitPrice)) ?? (try? c.decode(Double.self, forKey: .price)) ?? 0.0
        unitPrice = up
        quantity = (try? c.decode(Double.self, forKey: .quantity)) ?? 1.0
        total = (try? c.decode(Double.self, forKey: .total)) ?? (up * quantity)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(name, forKey: .name)
        try c.encodeIfPresent(description, forKey: .description)
        try c.encodeIfPresent(type, forKey: .type)
        try c.encode(unitPrice, forKey: .unitPrice)
        try c.encode(quantity, forKey: .quantity)
        try c.encode(total, forKey: .total)
    }
}

struct Estimate: Codable {
    let id: Int?
    let items: [EstimateItem]?
    let partsCost: Double?
    let laborCost: Double?
    let subtotal: Double?
    let discount: Double?
    let taxRate: Double?
    let taxAmount: Double?
    let tax: Double?
    let total: Double?
    let status: String?
    let notes: String?
    let approvedByStaff: Bool?
    let approvalNote: String?
    let approvedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, items, subtotal, discount, tax, total, status, notes
        case partsCost = "parts_cost"
        case laborCost = "labor_cost"
        case taxRate = "tax_rate"
        case taxAmount = "tax_amount"
        case approvedByStaff = "approved_by_staff"
        case approvalNote = "approval_note"
        case approvedAt = "approved_at"
    }

    init(
        id: Int? = nil,
        items: [EstimateItem]? = nil,
        partsCost: Double? = nil,
        laborCost: Double? = nil,
        subtotal: Double? = nil,
        discount: Double? = nil,
        taxRate: Double? = nil,
        taxAmount: Double? = nil,
        tax: Double? = nil,
        total: Double? = nil,
        status: String? = nil,
        notes: String? = nil,
        approvedByStaff: Bool? = nil,
        approvalNote: String? = nil,
        approvedAt: String? = nil
    ) {
        self.id = id
        self.items = items
        self.partsCost = partsCost
        self.laborCost = laborCost
        self.subtotal = subtotal
        self.discount = discount
        self.taxRate = taxRate
        self.taxAmount = taxAmount
        self.tax = tax
        self.total = total
        self.status = status
        self.notes = notes
        self.approvedByStaff = approvedByStaff
        self.approvalNote = approvalNote
        self.approvedAt = approvedAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try? c.decode(Int.self, forKey: .id)
        items = try? c.decode([EstimateItem].self, forKey: .items)
        partsCost = try? c.decode(Double.self, forKey: .partsCost)
        laborCost = try? c.decode(Double.self, forKey: .laborCost)
        subtotal = try? c.decode(Double.self, forKey: .subtotal)
        discount = try? c.decode(Double.self, forKey: .discount)
        taxRate = try? c.decode(Double.self, forKey: .taxRate)
        taxAmount = try? c.decode(Double.self, forKey: .taxAmount)
        tax = try? c.decode(Double.self, forKey: .tax)
        total = try? c.decode(Double.self, forKey: .total)
        status = try? c.decode(String.self, forKey: .status)
        notes = try? c.decode(String.self, forKey: .notes)
        approvedByStaff = try? c.decode(Bool.self, forKey: .approvedByStaff)
        approvalNote = try? c.decode(String.self, forKey: .approvalNote)
        approvedAt = try? c.decode(String.self, forKey: .approvedAt)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encodeIfPresent(id, forKey: .id)
        try c.encodeIfPresent(items, forKey: .items)
        try c.encodeIfPresent(partsCost, forKey: .partsCost)
        try c.encodeIfPresent(laborCost, forKey: .laborCost)
        try c.encodeIfPresent(subtotal, forKey: .subtotal)
        try c.encodeIfPresent(discount, forKey: .discount)
        try c.encodeIfPresent(taxRate, forKey: .taxRate)
        try c.encodeIfPresent(taxAmount, forKey: .taxAmount)
        try c.encodeIfPresent(tax, forKey: .tax)
        try c.encodeIfPresent(total, forKey: .total)
        try c.encodeIfPresent(status, forKey: .status)
        try c.encodeIfPresent(notes, forKey: .notes)
        try c.encodeIfPresent(approvedByStaff, forKey: .approvedByStaff)
        try c.encodeIfPresent(approvalNote, forKey: .approvalNote)
        try c.encodeIfPresent(approvedAt, forKey: .approvedAt)
    }

    var effectiveTotal: Double {
        if let t = total, t > 0 { return t }
        let sub = subtotal ?? ((partsCost ?? 0) + (laborCost ?? 0))
        let tx = taxAmount ?? tax ?? 0
        let disc = discount ?? 0
        return max(0, sub + tx - disc)
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
    let declineReason: String?
    let cancelReason: String?
    let startedAt: String?
    let completedAt: String?
    let adminNotes: String?
    let createdAt: String?
    let updatedAt: String?

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
        case declineReason = "decline_reason"
        case cancelReason = "cancel_reason"
        case startedAt = "started_at"
        case completedAt = "completed_at"
        case adminNotes = "admin_notes"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        reference = (try? container.decode(String.self, forKey: .reference)) ?? "BK-\(id)"
        status = (try? container.decode(String.self, forKey: .status)) ?? "PENDING"
        userId = try? container.decode(Int.self, forKey: .userId)
        vehicleId = try? container.decode(Int.self, forKey: .vehicleId)
        mechanicId = try? container.decode(Int.self, forKey: .mechanicId)
        scheduledDate = (try? container.decode(String.self, forKey: .scheduledDate)) ?? ""
        scheduledTime = (try? container.decode(String.self, forKey: .scheduledTime)) ?? ""
        notes = try? container.decode(String.self, forKey: .notes)
        totalAmount = try? container.decode(Double.self, forKey: .totalAmount)
        paymentStatus = try? container.decode(String.self, forKey: .paymentStatus)
        amountPaid = try? container.decode(Double.self, forKey: .amountPaid)
        balanceDue = try? container.decode(Double.self, forKey: .balanceDue)
        customerName = try? container.decode(String.self, forKey: .customerName)
        customerEmail = try? container.decode(String.self, forKey: .customerEmail)
        customerPhone = try? container.decode(String.self, forKey: .customerPhone)
        invoiceId = try? container.decode(Int.self, forKey: .invoiceId)
        declineReason = try? container.decode(String.self, forKey: .declineReason)
        cancelReason = try? container.decode(String.self, forKey: .cancelReason)
        startedAt = try? container.decode(String.self, forKey: .startedAt)
        completedAt = try? container.decode(String.self, forKey: .completedAt)
        adminNotes = try? container.decode(String.self, forKey: .adminNotes)
        createdAt = try? container.decode(String.self, forKey: .createdAt)
        updatedAt = try? container.decode(String.self, forKey: .updatedAt)

        // Resilient services decoding: supports [BookingService] OR comma-separated/JSON string from SQLite
        if let sList = try? container.decode([BookingService].self, forKey: .services) {
            services = sList
        } else if let sString = try? container.decode(String.self, forKey: .services) {
            if let data = sString.data(using: .utf8),
               let parsed = try? JSONDecoder().decode([BookingService].self, from: data) {
                services = parsed
            } else {
                let parts = sString.components(separatedBy: ",").map { $0.trimmingCharacters(in: .whitespaces) }.filter { !$0.isEmpty }
                services = parts.map { BookingService(serviceName: $0) }
            }
        } else {
            services = nil
        }

        // Resilient vehicle decoding
        if let vObj = try? container.decode(Vehicle.self, forKey: .vehicle) {
            vehicle = vObj
        } else if let vString = try? container.decode(String.self, forKey: .vehicle),
                  let data = vString.data(using: .utf8),
                  let parsed = try? JSONDecoder().decode(Vehicle.self, from: data) {
            vehicle = parsed
        } else {
            vehicle = nil
        }

        // Resilient towing decoding
        if let tObj = try? container.decode(TowingDetails.self, forKey: .towing) {
            towing = tObj
        } else if let tString = try? container.decode(String.self, forKey: .towing),
                  let data = tString.data(using: .utf8),
                  let parsed = try? JSONDecoder().decode(TowingDetails.self, from: data) {
            towing = parsed
        } else {
            towing = nil
        }

        // Resilient estimate decoding
        if let eObj = try? container.decode(Estimate.self, forKey: .estimate) {
            estimate = eObj
        } else if let eString = try? container.decode(String.self, forKey: .estimate),
                  let data = eString.data(using: .utf8),
                  let parsed = try? JSONDecoder().decode(Estimate.self, from: data) {
            estimate = parsed
        } else {
            estimate = nil
        }

        // Resilient extras decoding
        if let xList = try? container.decode([BookingExtra].self, forKey: .extras) {
            extras = xList
        } else if let xString = try? container.decode(String.self, forKey: .extras),
                  let data = xString.data(using: .utf8),
                  let parsed = try? JSONDecoder().decode([BookingExtra].self, from: data) {
            extras = parsed
        } else {
            extras = nil
        }

        // Resilient coupon decoding
        if let cObj = try? container.decode(AppliedCoupon.self, forKey: .coupon) {
            coupon = cObj
        } else if let cString = try? container.decode(String.self, forKey: .coupon),
                  let data = cString.data(using: .utf8),
                  let parsed = try? JSONDecoder().decode(AppliedCoupon.self, from: data) {
            coupon = parsed
        } else {
            coupon = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(reference, forKey: .reference)
        try container.encode(status, forKey: .status)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encodeIfPresent(vehicleId, forKey: .vehicleId)
        try container.encodeIfPresent(mechanicId, forKey: .mechanicId)
        try container.encode(scheduledDate, forKey: .scheduledDate)
        try container.encode(scheduledTime, forKey: .scheduledTime)
        try container.encodeIfPresent(notes, forKey: .notes)
        try container.encodeIfPresent(totalAmount, forKey: .totalAmount)
        try container.encodeIfPresent(paymentStatus, forKey: .paymentStatus)
        try container.encodeIfPresent(amountPaid, forKey: .amountPaid)
        try container.encodeIfPresent(balanceDue, forKey: .balanceDue)
        try container.encodeIfPresent(customerName, forKey: .customerName)
        try container.encodeIfPresent(customerEmail, forKey: .customerEmail)
        try container.encodeIfPresent(customerPhone, forKey: .customerPhone)
        try container.encodeIfPresent(invoiceId, forKey: .invoiceId)
        try container.encodeIfPresent(declineReason, forKey: .declineReason)
        try container.encodeIfPresent(cancelReason, forKey: .cancelReason)
        try container.encodeIfPresent(startedAt, forKey: .startedAt)
        try container.encodeIfPresent(completedAt, forKey: .completedAt)
        try container.encodeIfPresent(adminNotes, forKey: .adminNotes)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(services, forKey: .services)
        try container.encodeIfPresent(vehicle, forKey: .vehicle)
        try container.encodeIfPresent(towing, forKey: .towing)
        try container.encodeIfPresent(estimate, forKey: .estimate)
        try container.encodeIfPresent(extras, forKey: .extras)
        try container.encodeIfPresent(coupon, forKey: .coupon)
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

    init(
        id: Int,
        reference: String,
        status: String,
        userId: Int? = nil,
        vehicleId: Int? = nil,
        mechanicId: Int? = nil,
        scheduledDate: String,
        scheduledTime: String,
        notes: String? = nil,
        totalAmount: Double? = nil,
        paymentStatus: String? = nil,
        amountPaid: Double? = nil,
        balanceDue: Double? = nil,
        customerName: String? = nil,
        customerEmail: String? = nil,
        customerPhone: String? = nil,
        services: [BookingService]? = nil,
        vehicle: Vehicle? = nil,
        towing: TowingDetails? = nil,
        estimate: Estimate? = nil,
        extras: [BookingExtra]? = nil,
        coupon: AppliedCoupon? = nil,
        invoiceId: Int? = nil,
        declineReason: String? = nil,
        cancelReason: String? = nil,
        startedAt: String? = nil,
        completedAt: String? = nil,
        adminNotes: String? = nil,
        createdAt: String? = nil,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.reference = reference
        self.status = status
        self.userId = userId
        self.vehicleId = vehicleId
        self.mechanicId = mechanicId
        self.scheduledDate = scheduledDate
        self.scheduledTime = scheduledTime
        self.notes = notes
        self.totalAmount = totalAmount
        self.paymentStatus = paymentStatus
        self.amountPaid = amountPaid
        self.balanceDue = balanceDue
        self.customerName = customerName
        self.customerEmail = customerEmail
        self.customerPhone = customerPhone
        self.services = services
        self.vehicle = vehicle
        self.towing = towing
        self.estimate = estimate
        self.extras = extras
        self.coupon = coupon
        self.invoiceId = invoiceId
        self.declineReason = declineReason
        self.cancelReason = cancelReason
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.adminNotes = adminNotes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
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

    init(
        serviceIds: [Int],
        vehicleId: Int? = nil,
        vehicle: CreateVehicleRequest? = nil,
        scheduledDate: String,
        scheduledTime: String,
        notes: String? = nil,
        couponCode: String? = nil
    ) {
        self.serviceIds = serviceIds
        self.vehicleId = vehicleId
        self.vehicle = vehicle
        self.scheduledDate = scheduledDate
        self.scheduledTime = scheduledTime
        self.notes = notes
        self.couponCode = couponCode
    }

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
    let technicianName: String?

    enum CodingKeys: String, CodingKey {
        case booking, reference, status, timeline
        case vehicleSummary = "vehicle_summary"
        case technicianName = "technician_name"
    }
}

// MARK: - Table: towing_requests
struct TowingRequest: Codable, Identifiable {
    let id: Int
    let userId: Int?
    let pickupLocation: String
    let destination: String?
    let vehicleInfo: String?
    let status: String
    let notes: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, destination, status, notes
        case userId = "user_id"
        case pickupLocation = "pickup_location"
        case vehicleInfo = "vehicle_info"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct CreateTowingRequest: Codable {
    let pickupLocation: String
    let destination: String?
    let vehicleInfo: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case destination, notes
        case pickupLocation = "pickup_location"
        case vehicleInfo = "vehicle_info"
    }
}

// MARK: - Table: chat_rooms & chat_messages
struct ChatRoom: Codable, Identifiable {
    let id: Int
    let userId: Int?
    let bookingId: Int?
    let subject: String?
    let status: String?
    let guestName: String?
    let guestEmail: String?
    let guestPhone: String?
    let vehicleId: Int?
    let isPinned: Bool?
    let customerName: String?
    let lastMessage: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, subject, status
        case userId = "user_id"
        case bookingId = "booking_id"
        case guestName = "guest_name"
        case guestEmail = "guest_email"
        case guestPhone = "guest_phone"
        case vehicleId = "vehicle_id"
        case isPinned = "is_pinned"
        case customerName = "customer_name"
        case lastMessage = "last_message"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

struct ChatMessage: Codable, Identifiable {
    let id: Int
    let roomId: Int?
    let senderId: Int?
    let senderName: String?
    let senderRole: String?
    let guest: Bool?
    let body: String
    let attachmentUrl: String?
    let readAt: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, body, guest
        case roomId = "room_id"
        case senderId = "sender_id"
        case senderName = "sender_name"
        case senderRole = "sender_role"
        case attachmentUrl = "attachment_url"
        case readAt = "read_at"
        case createdAt = "created_at"
    }

    init(
        id: Int,
        roomId: Int? = nil,
        senderId: Int? = nil,
        senderName: String? = nil,
        senderRole: String? = nil,
        guest: Bool? = nil,
        body: String,
        attachmentUrl: String? = nil,
        readAt: String? = nil,
        createdAt: String? = nil
    ) {
        self.id = id
        self.roomId = roomId
        self.senderId = senderId
        self.senderName = senderName
        self.senderRole = senderRole
        self.guest = guest
        self.body = body
        self.attachmentUrl = attachmentUrl
        self.readAt = readAt
        self.createdAt = createdAt
    }
}

struct SendMessageRequest: Codable {
    let body: String
}

struct CreateRoomRequest: Codable {
    let subject: String
}

// MARK: - Table: contact_messages
struct ContactMessageRequest: Codable {
    let name: String
    let email: String
    let phone: String?
    let subject: String?
    let message: String
}

// MARK: - Table: notifications
struct AppNotification: Codable, Identifiable {
    let id: Int
    let userId: Int?
    let type: String?
    let title: String
    let message: String
    let link: String?
    var read: Bool
    let readAt: String?
    let createdAt: String?

    enum CodingKeys: String, CodingKey {
        case id, type, title, message, body, link, read
        case userId = "user_id"
        case readAt = "read_at"
        case createdAt = "created_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        userId = try? container.decode(Int.self, forKey: .userId)
        type = try? container.decode(String.self, forKey: .type)
        title = try container.decode(String.self, forKey: .title)
        link = try? container.decode(String.self, forKey: .link)
        readAt = try? container.decode(String.self, forKey: .readAt)
        createdAt = try? container.decode(String.self, forKey: .createdAt)

        // Supports both "body" (DB column) and "message"
        let msg = (try? container.decode(String.self, forKey: .body)) ?? (try? container.decode(String.self, forKey: .message))
        message = msg ?? ""

        if let r = try? container.decode(Bool.self, forKey: .read) {
            read = r
        } else if let _ = readAt {
            read = true
        } else {
            read = false
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encodeIfPresent(type, forKey: .type)
        try container.encode(title, forKey: .title)
        try container.encode(message, forKey: .message)
        try container.encodeIfPresent(link, forKey: .link)
        try container.encode(read, forKey: .read)
        try container.encodeIfPresent(readAt, forKey: .readAt)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
    }

    init(
        id: Int,
        userId: Int? = nil,
        type: String? = nil,
        title: String,
        message: String,
        link: String? = nil,
        read: Bool = false,
        readAt: String? = nil,
        createdAt: String? = nil
    ) {
        self.id = id
        self.userId = userId
        self.type = type
        self.title = title
        self.message = message
        self.link = link
        self.read = read
        self.readAt = readAt
        self.createdAt = createdAt
    }

    init(
        id: Int,
        userId: Int?,
        title: String,
        message: String,
        type: String?,
        read: Bool,
        createdAt: String?
    ) {
        self.init(
            id: id,
            userId: userId,
            type: type,
            title: title,
            message: message,
            link: nil,
            read: read,
            readAt: nil,
            createdAt: createdAt
        )
    }
}

struct UnreadCount: Codable {
    let count: Int
}

// MARK: - Table: invoices
struct InvoiceItem: Codable, Identifiable {
    var id: String { description ?? UUID().uuidString }
    let description: String?
    let quantity: Int?
    let unitPrice: Double?
    let total: Double?

    enum CodingKeys: String, CodingKey {
        case description, quantity, total
        case unitPrice = "unit_price"
    }
}

struct Invoice: Codable, Identifiable {
    let id: Int
    let invoiceNumber: String
    let userId: Int?
    let vehicleId: Int?
    let bookingId: Int?
    let bookingReference: String?
    let items: [InvoiceItem]?
    let itemsRaw: String?
    let subtotal: Double?
    let discount: Double?
    let tax: Double?
    let total: Double?
    let amountPaid: Double?
    let status: String?
    let issuedAt: String?
    let dueDate: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, status, subtotal, discount, tax, total
        case invoiceNumber = "invoice_number"
        case userId = "user_id"
        case vehicleId = "vehicle_id"
        case bookingId = "booking_id"
        case bookingReference = "booking_reference"
        case items
        case amountPaid = "amount_paid"
        case issuedAt = "issued_at"
        case dueDate = "due_date"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        invoiceNumber = try container.decode(String.self, forKey: .invoiceNumber)
        userId = try? container.decode(Int.self, forKey: .userId)
        vehicleId = try? container.decode(Int.self, forKey: .vehicleId)
        bookingId = try? container.decode(Int.self, forKey: .bookingId)
        bookingReference = try? container.decode(String.self, forKey: .bookingReference)
        subtotal = try? container.decode(Double.self, forKey: .subtotal)
        discount = try? container.decode(Double.self, forKey: .discount)
        tax = try? container.decode(Double.self, forKey: .tax)
        total = try? container.decode(Double.self, forKey: .total)
        amountPaid = try? container.decode(Double.self, forKey: .amountPaid)
        status = try? container.decode(String.self, forKey: .status)
        issuedAt = try? container.decode(String.self, forKey: .issuedAt)
        dueDate = try? container.decode(String.self, forKey: .dueDate)
        createdAt = try? container.decode(String.self, forKey: .createdAt)
        updatedAt = try? container.decode(String.self, forKey: .updatedAt)

        if let directItems = try? container.decode([InvoiceItem].self, forKey: .items) {
            items = directItems
            itemsRaw = nil
        } else if let raw = try? container.decode(String.self, forKey: .items) {
            itemsRaw = raw
            if let data = raw.data(using: .utf8),
               let parsed = try? JSONDecoder().decode([InvoiceItem].self, from: data) {
                items = parsed
            } else {
                items = nil
            }
        } else {
            items = nil
            itemsRaw = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(invoiceNumber, forKey: .invoiceNumber)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encodeIfPresent(vehicleId, forKey: .vehicleId)
        try container.encodeIfPresent(bookingId, forKey: .bookingId)
        try container.encodeIfPresent(bookingReference, forKey: .bookingReference)
        try container.encodeIfPresent(subtotal, forKey: .subtotal)
        try container.encodeIfPresent(discount, forKey: .discount)
        try container.encodeIfPresent(tax, forKey: .tax)
        try container.encodeIfPresent(total, forKey: .total)
        try container.encodeIfPresent(amountPaid, forKey: .amountPaid)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(issuedAt, forKey: .issuedAt)
        try container.encodeIfPresent(dueDate, forKey: .dueDate)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        if let directItems = items {
            try container.encode(directItems, forKey: .items)
        } else if let raw = itemsRaw {
            try container.encode(raw, forKey: .items)
        }
    }

    init(
        id: Int,
        invoiceNumber: String,
        userId: Int? = nil,
        vehicleId: Int? = nil,
        bookingId: Int? = nil,
        bookingReference: String? = nil,
        items: [InvoiceItem]? = nil,
        itemsRaw: String? = nil,
        subtotal: Double? = nil,
        discount: Double? = nil,
        tax: Double? = nil,
        total: Double? = nil,
        amountPaid: Double? = nil,
        status: String? = nil,
        issuedAt: String? = nil,
        dueDate: String? = nil,
        createdAt: String? = nil,
        updatedAt: String? = nil
    ) {
        self.id = id
        self.invoiceNumber = invoiceNumber
        self.userId = userId
        self.vehicleId = vehicleId
        self.bookingId = bookingId
        self.bookingReference = bookingReference
        self.items = items
        self.itemsRaw = itemsRaw
        self.subtotal = subtotal
        self.discount = discount
        self.tax = tax
        self.total = total
        self.amountPaid = amountPaid
        self.status = status
        self.issuedAt = issuedAt
        self.dueDate = dueDate
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

// MARK: - Table: payments
struct Payment: Codable, Identifiable {
    let id: Int
    let invoiceId: Int?
    let bookingId: Int?
    let userId: Int?
    let amount: Double
    let method: String
    let transactionId: String?
    let referenceNote: String?
    let gateway: String?
    let gatewayMode: String?
    let gatewayOrderId: String?
    let receiptUrl: String?
    let receiptNumber: String?
    let cardBrand: String?
    let cardLast4: String?
    let currency: String?
    let failureCode: String?
    let failureMessage: String?
    let status: String
    let approvedAt: String?
    let approvedByName: String?
    let paidAt: String?
    let refundedAmount: Double?
    let refundStatus: String?
    let createdAt: String?
    let updatedAt: String?
    let cashReceived: Double?
    let changeGiven: Double?
    let estimateVersion: Int?

    enum CodingKeys: String, CodingKey {
        case id, amount, method, gateway, currency, status
        case invoiceId = "invoice_id"
        case bookingId = "booking_id"
        case userId = "user_id"
        case transactionId = "transaction_id"
        case referenceNote = "reference_note"
        case gatewayMode = "gateway_mode"
        case gatewayOrderId = "gateway_order_id"
        case receiptUrl = "receipt_url"
        case receiptNumber = "receipt_number"
        case cardBrand = "card_brand"
        case cardLast4 = "card_last4"
        case failureCode = "failure_code"
        case failureMessage = "failure_message"
        case approvedAt = "approved_at"
        case approvedByName = "approved_by_name"
        case paidAt = "paid_at"
        case refundedAmount = "refunded_amount"
        case refundStatus = "refund_status"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case cashReceived = "cash_received"
        case changeGiven = "change_given"
        case estimateVersion = "estimate_version"
    }
}

// MARK: - Table: reviews
struct Review: Codable, Identifiable {
    let id: Int
    let bookingId: Int?
    let serviceId: Int?
    let serviceName: String?
    let userId: Int?
    let customerName: String?
    let customerAvatarUrl: String?
    let rating: Int
    let comment: String?
    let status: String?
    let createdAt: String?
    let updatedAt: String?
    let source: String?
    let googleReviewId: String?
    let reviewDate: String?
    let editedLocally: Bool?
    let verifiedCustomer: Bool?
    let bookingReference: String?
    let response: String?

    var userName: String? {
        return customerName
    }

    enum CodingKeys: String, CodingKey {
        case id, rating, comment, status, source, response
        case bookingId = "booking_id"
        case serviceId = "service_id"
        case serviceName = "service_name"
        case userId = "user_id"
        case customerName = "customer_name"
        case userName = "user_name"
        case customerAvatarUrl = "customer_avatar_url"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
        case googleReviewId = "google_review_id"
        case reviewDate = "review_date"
        case editedLocally = "edited_locally"
        case verifiedCustomer = "verified_customer"
        case bookingReference = "booking_reference"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int.self, forKey: .id)
        bookingId = try? container.decode(Int.self, forKey: .bookingId)
        serviceId = try? container.decode(Int.self, forKey: .serviceId)
        serviceName = try? container.decode(String.self, forKey: .serviceName)
        userId = try? container.decode(Int.self, forKey: .userId)
        rating = (try? container.decode(Int.self, forKey: .rating)) ?? 5
        comment = try? container.decode(String.self, forKey: .comment)
        status = try? container.decode(String.self, forKey: .status)
        createdAt = try? container.decode(String.self, forKey: .createdAt)
        updatedAt = try? container.decode(String.self, forKey: .updatedAt)
        source = try? container.decode(String.self, forKey: .source)
        googleReviewId = try? container.decode(String.self, forKey: .googleReviewId)
        reviewDate = try? container.decode(String.self, forKey: .reviewDate)
        bookingReference = try? container.decode(String.self, forKey: .bookingReference)
        response = try? container.decode(String.self, forKey: .response)
        customerAvatarUrl = try? container.decode(String.self, forKey: .customerAvatarUrl)

        // Supports both "customer_name" and "user_name"
        let cName = (try? container.decode(String.self, forKey: .customerName)) ?? (try? container.decode(String.self, forKey: .userName))
        customerName = cName

        // Boolean or Int flags (edited_locally, verified_customer)
        if let v = try? container.decode(Bool.self, forKey: .verifiedCustomer) {
            verifiedCustomer = v
        } else if let v = try? container.decode(Int.self, forKey: .verifiedCustomer) {
            verifiedCustomer = v == 1
        } else {
            verifiedCustomer = nil
        }

        if let e = try? container.decode(Bool.self, forKey: .editedLocally) {
            editedLocally = e
        } else if let e = try? container.decode(Int.self, forKey: .editedLocally) {
            editedLocally = e == 1
        } else {
            editedLocally = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(bookingId, forKey: .bookingId)
        try container.encodeIfPresent(serviceId, forKey: .serviceId)
        try container.encodeIfPresent(serviceName, forKey: .serviceName)
        try container.encodeIfPresent(userId, forKey: .userId)
        try container.encodeIfPresent(customerName, forKey: .customerName)
        try container.encodeIfPresent(customerAvatarUrl, forKey: .customerAvatarUrl)
        try container.encode(rating, forKey: .rating)
        try container.encodeIfPresent(comment, forKey: .comment)
        try container.encodeIfPresent(status, forKey: .status)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try container.encodeIfPresent(source, forKey: .source)
        try container.encodeIfPresent(googleReviewId, forKey: .googleReviewId)
        try container.encodeIfPresent(reviewDate, forKey: .reviewDate)
        try container.encodeIfPresent(editedLocally, forKey: .editedLocally)
        try container.encodeIfPresent(verifiedCustomer, forKey: .verifiedCustomer)
        try container.encodeIfPresent(bookingReference, forKey: .bookingReference)
        try container.encodeIfPresent(response, forKey: .response)
    }

    init(
        id: Int,
        bookingId: Int? = nil,
        serviceId: Int? = nil,
        serviceName: String? = nil,
        userId: Int? = nil,
        customerName: String? = nil,
        customerAvatarUrl: String? = nil,
        rating: Int,
        comment: String? = nil,
        status: String? = "active",
        createdAt: String? = nil,
        updatedAt: String? = nil,
        source: String? = nil,
        googleReviewId: String? = nil,
        reviewDate: String? = nil,
        editedLocally: Bool? = nil,
        verifiedCustomer: Bool? = nil,
        bookingReference: String? = nil,
        response: String? = nil
    ) {
        self.id = id
        self.bookingId = bookingId
        self.serviceId = serviceId
        self.serviceName = serviceName
        self.userId = userId
        self.customerName = customerName
        self.customerAvatarUrl = customerAvatarUrl
        self.rating = rating
        self.comment = comment
        self.status = status
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.source = source
        self.googleReviewId = googleReviewId
        self.reviewDate = reviewDate
        self.editedLocally = editedLocally
        self.verifiedCustomer = verifiedCustomer
        self.bookingReference = bookingReference
        self.response = response
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

// MARK: - Table: deals
struct Deal: Codable, Identifiable {
    let id: Int
    let title: String
    let description: String?
    let code: String?
    let imageUrl: String?
    let discountType: String?
    let discountValue: Double?
    let serviceId: Int?
    let serviceIds: String?
    let minSpend: Double?
    let maxUses: Int?
    let oncePerCustomer: Bool?
    let publicDeal: Bool?
    let startsAt: String?
    let endsAt: String?
    let appliesTo: String?
    let status: String?
    let createdAt: String?
    let updatedAt: String?

    // Backward-compatibility computed helpers
    var expiresAt: String? { endsAt }
    var discountPercent: Double? {
        if discountType?.uppercased() == "PERCENTAGE" || discountType?.uppercased() == "PERCENT" {
            return discountValue
        }
        return nil
    }
    var discountAmount: Double? {
        if discountType?.uppercased() == "FIXED" || discountType?.uppercased() == "AMOUNT" {
            return discountValue
        }
        return nil
    }

    enum CodingKeys: String, CodingKey {
        case id, title, description, code, status
        case imageUrl = "image_url"
        case discountType = "discount_type"
        case discountValue = "discount_value"
        case serviceId = "service_id"
        case serviceIds = "service_ids"
        case minSpend = "min_spend"
        case maxUses = "max_uses"
        case oncePerCustomer = "once_per_customer"
        case publicDeal = "public"
        case startsAt = "starts_at"
        case endsAt = "ends_at"
        case appliesTo = "applies_to"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    func discountBadge() -> String {
        if let type = discountType?.uppercased(), let val = discountValue, val > 0 {
            if type == "PERCENTAGE" || type == "PERCENT" {
                return "\(Int(val))% OFF"
            } else {
                return String(format: "$%.0f OFF", val)
            }
        }
        if let val = discountValue, val > 0 {
            return "\(Int(val))% OFF"
        }
        return "SPECIAL"
    }

    func fullImageUrl() -> String? {
        return imageUrl?.resolvedApiImageUrl()
    }
}

// MARK: - Table: mechanics
struct MechanicTimeOff: Codable, Identifiable {
    var id: String { "\(startDate ?? "")-\(endDate ?? "")-\(reason ?? "")" }
    let startDate: String?
    let endDate: String?
    let reason: String?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case reason, status
        case startDate = "start_date"
        case endDate = "end_date"
        case start, end
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        reason = try? container.decode(String.self, forKey: .reason)
        status = try? container.decode(String.self, forKey: .status)
        startDate = (try? container.decode(String.self, forKey: .startDate)) ?? (try? container.decode(String.self, forKey: .start))
        endDate = (try? container.decode(String.self, forKey: .endDate)) ?? (try? container.decode(String.self, forKey: .end))
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(startDate, forKey: .startDate)
        try container.encodeIfPresent(endDate, forKey: .endDate)
        try container.encodeIfPresent(reason, forKey: .reason)
        try container.encodeIfPresent(status, forKey: .status)
    }
}

struct Mechanic: Codable, Identifiable {
    let id: Int
    let userId: Int?
    let name: String
    let photoUrl: String?
    let phone: String?
    let email: String?
    let specialization: String?
    let experienceYears: Int?
    let certification: String?
    let status: String?
    let workingHours: String?
    let employeeId: String?
    let bio: String?
    let timeOff: [MechanicTimeOff]?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, name, phone, email, specialization, certification, status, bio
        case userId = "user_id"
        case photoUrl = "photo_url"
        case experienceYears = "experience_years"
        case workingHours = "working_hours"
        case employeeId = "employee_id"
        case timeOff = "time_off"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    func fullPhotoUrl() -> String? {
        return photoUrl?.resolvedApiImageUrl()
    }
}

// MARK: - Table: service_history
struct ServiceHistoryRecord: Codable, Identifiable {
    let id: Int
    let bookingId: Int?
    let vehicleId: Int?
    let userId: Int?
    let serviceName: String
    let mechanicName: String?
    let performedAt: String
    let mileage: Int?
    let workPerformed: String?
    let partsUsed: String?
    let cost: Double?
    let notes: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, mileage, cost, notes
        case bookingId = "booking_id"
        case vehicleId = "vehicle_id"
        case userId = "user_id"
        case serviceName = "service_name"
        case mechanicName = "mechanic_name"
        case performedAt = "performed_at"
        case workPerformed = "work_performed"
        case partsUsed = "parts_used"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

// MARK: - Table: favorites
struct Favorite: Codable, Identifiable {
    let id: Int
    let userId: Int
    let serviceId: Int
    let createdAt: String?
    let service: Service?

    enum CodingKeys: String, CodingKey {
        case id, service
        case userId = "user_id"
        case serviceId = "service_id"
        case createdAt = "created_at"
    }
}

// MARK: - Table: blog_posts
struct BlogPost: Codable, Identifiable {
    let id: Int
    let title: String
    let slug: String
    let excerpt: String?
    let content: String?
    let coverImageUrl: String?
    let authorName: String?
    let tags: String?
    let publishedAt: String?
    let status: String?
    let createdAt: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, title, slug, excerpt, content, tags, status
        case coverImageUrl = "cover_image_url"
        case authorName = "author_name"
        case publishedAt = "published_at"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }

    func fullCoverImageUrl() -> String? {
        return coverImageUrl?.resolvedApiImageUrl()
    }
}

// MARK: - Table: device_tokens
struct RegisterDeviceTokenRequest: Codable {
    let token: String
    let platform: String
    let deviceName: String?
    let deviceModel: String?
    let appVersion: String?

    enum CodingKeys: String, CodingKey {
        case token, platform
        case deviceName = "device_name"
        case deviceModel = "device_model"
        case appVersion = "app_version"
    }
}

// MARK: - Table: settings
struct OpeningHourDay: Codable, Identifiable {
    var id: String { day }
    let day: String
    let opensAt: String?
    let closesAt: String?
    let closed: Bool

    enum CodingKeys: String, CodingKey {
        case day, closed
        case opensAt = "opens_at"
        case closesAt = "closes_at"
    }

    func formattedSummary() -> String {
        if closed { return "\(day): Closed" }
        if let o = opensAt, let c = closesAt {
            return "\(day): \(o) - \(c)"
        }
        return "\(day): Open"
    }
}

struct SocialLinks: Codable {
    let facebook: String?
    let instagram: String?
    let tiktok: String?
    let twitter: String?
    let youtube: String?
}

struct PublicSettings: Codable {
    let id: Int?
    let siteName: String?
    let tagline: String?
    let logoUrl: String?
    let phone: String?
    let secondaryPhone: String?
    let email: String?
    let address: String?
    let mapUrl: String?
    let directionsUrl: String?
    let openingHoursList: [OpeningHourDay]?
    let openingHoursRaw: String?
    let social: SocialLinks?
    let currency: String?
    let currencySymbol: String?
    let taxRate: Double?
    let googleRating: Double?
    let googleReviewCount: Int?
    let onlinePaymentEnabled: Bool?
    let heroImageUrl: String?
    let bookingStepsImageUrl: String?
    let aboutImageUrl: String?
    let maintenanceMode: Bool?
    let maintenanceMessage: String?
    let maintenanceUntil: String?

    // Backward-compatibility computed properties
    var emergencyPhone: String? {
        return secondaryPhone ?? phone
    }

    var operatingHours: String? {
        if let list = openingHoursList, !list.isEmpty {
            return list.map { $0.formattedSummary() }.joined(separator: "\n")
        }
        return openingHoursRaw
    }

    enum CodingKeys: String, CodingKey {
        case id, phone, email, address, social, currency
        case siteName = "site_name"
        case tagline
        case logoUrl = "logo_url"
        case secondaryPhone = "secondary_phone"
        case mapUrl = "map_url"
        case directionsUrl = "directions_url"
        case openingHours = "opening_hours"
        case currencySymbol = "currency_symbol"
        case taxRate = "tax_rate"
        case googleRating = "google_rating"
        case googleReviewCount = "google_review_count"
        case onlinePaymentEnabled = "online_payment_enabled"
        case heroImageUrl = "hero_image_url"
        case bookingStepsImageUrl = "booking_steps_image_url"
        case aboutImageUrl = "about_image_url"
        case maintenanceMode = "maintenance_mode"
        case maintenanceMessage = "maintenance_message"
        case maintenanceUntil = "maintenance_until"
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try? container.decode(Int.self, forKey: .id)
        siteName = try? container.decode(String.self, forKey: .siteName)
        tagline = try? container.decode(String.self, forKey: .tagline)
        logoUrl = try? container.decode(String.self, forKey: .logoUrl)
        phone = try? container.decode(String.self, forKey: .phone)
        secondaryPhone = try? container.decode(String.self, forKey: .secondaryPhone)
        email = try? container.decode(String.self, forKey: .email)
        address = try? container.decode(String.self, forKey: .address)
        mapUrl = try? container.decode(String.self, forKey: .mapUrl)
        directionsUrl = try? container.decode(String.self, forKey: .directionsUrl)
        social = try? container.decode(SocialLinks.self, forKey: .social)
        currency = try? container.decode(String.self, forKey: .currency)
        currencySymbol = try? container.decode(String.self, forKey: .currencySymbol)
        taxRate = try? container.decode(Double.self, forKey: .taxRate)
        googleRating = try? container.decode(Double.self, forKey: .googleRating)
        googleReviewCount = try? container.decode(Int.self, forKey: .googleReviewCount)
        heroImageUrl = try? container.decode(String.self, forKey: .heroImageUrl)
        bookingStepsImageUrl = try? container.decode(String.self, forKey: .bookingStepsImageUrl)
        aboutImageUrl = try? container.decode(String.self, forKey: .aboutImageUrl)
        maintenanceMessage = try? container.decode(String.self, forKey: .maintenanceMessage)
        maintenanceUntil = try? container.decode(String.self, forKey: .maintenanceUntil)

        // Opening hours: can be [OpeningHourDay] or string
        if let list = try? container.decode([OpeningHourDay].self, forKey: .openingHours) {
            openingHoursList = list
            openingHoursRaw = nil
        } else if let str = try? container.decode(String.self, forKey: .openingHours) {
            openingHoursList = nil
            openingHoursRaw = str
        } else {
            openingHoursList = nil
            openingHoursRaw = nil
        }

        // Flags: online_payment_enabled, maintenance_mode (can be Int 0/1 or Bool)
        if let b = try? container.decode(Bool.self, forKey: .onlinePaymentEnabled) {
            onlinePaymentEnabled = b
        } else if let i = try? container.decode(Int.self, forKey: .onlinePaymentEnabled) {
            onlinePaymentEnabled = i == 1
        } else {
            onlinePaymentEnabled = nil
        }

        if let b = try? container.decode(Bool.self, forKey: .maintenanceMode) {
            maintenanceMode = b
        } else if let i = try? container.decode(Int.self, forKey: .maintenanceMode) {
            maintenanceMode = i == 1
        } else {
            maintenanceMode = nil
        }
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(id, forKey: .id)
        try container.encodeIfPresent(siteName, forKey: .siteName)
        try container.encodeIfPresent(tagline, forKey: .tagline)
        try container.encodeIfPresent(logoUrl, forKey: .logoUrl)
        try container.encodeIfPresent(phone, forKey: .phone)
        try container.encodeIfPresent(secondaryPhone, forKey: .secondaryPhone)
        try container.encodeIfPresent(email, forKey: .email)
        try container.encodeIfPresent(address, forKey: .address)
        try container.encodeIfPresent(mapUrl, forKey: .mapUrl)
        try container.encodeIfPresent(directionsUrl, forKey: .directionsUrl)
        try container.encodeIfPresent(social, forKey: .social)
        try container.encodeIfPresent(currency, forKey: .currency)
        try container.encodeIfPresent(currencySymbol, forKey: .currencySymbol)
        try container.encodeIfPresent(taxRate, forKey: .taxRate)
        try container.encodeIfPresent(googleRating, forKey: .googleRating)
        try container.encodeIfPresent(googleReviewCount, forKey: .googleReviewCount)
        try container.encodeIfPresent(heroImageUrl, forKey: .heroImageUrl)
        try container.encodeIfPresent(bookingStepsImageUrl, forKey: .bookingStepsImageUrl)
        try container.encodeIfPresent(aboutImageUrl, forKey: .aboutImageUrl)
        try container.encodeIfPresent(maintenanceMessage, forKey: .maintenanceMessage)
        try container.encodeIfPresent(maintenanceUntil, forKey: .maintenanceUntil)
        try container.encodeIfPresent(onlinePaymentEnabled, forKey: .onlinePaymentEnabled)
        try container.encodeIfPresent(maintenanceMode, forKey: .maintenanceMode)
        if let list = openingHoursList {
            try container.encode(list, forKey: .openingHours)
        } else if let raw = openingHoursRaw {
            try container.encode(raw, forKey: .openingHours)
        }
    }

    func fullHeroImageUrl() -> String? {
        return heroImageUrl?.resolvedApiImageUrl()
    }

    func fullLogoUrl() -> String? {
        return logoUrl?.resolvedApiImageUrl()
    }
}

// MARK: - Admin Statistics Model (/admin/stats)
struct AdminStats: Codable {
    let bookingsTotal: Int?
    let bookingsToday: Int?
    let bookingsPending: Int?
    let bookingsConfirmed: Int?
    let servicesCompleted: Int?
    let estimatesPending: Int?
    let estimatesApproved: Int?
    let servicesActive: Int?
    let revenueTotal: Double?
    let paymentsPending: Int?
    let customersTotal: Int?
    let vehiclesTotal: Int?
    let totalMechanics: Int?
    let invoicesPaid: Int?
    let invoicesPaidTotal: Double?
    let invoicesOutstanding: Int?
    let invoicesOutstandingTotal: Double?
    let averageTicket: Double?

    enum CodingKeys: String, CodingKey {
        case bookingsTotal = "bookings_total"
        case bookingsToday = "bookings_today"
        case bookingsPending = "bookings_pending"
        case bookingsConfirmed = "bookings_confirmed"
        case servicesCompleted = "services_completed"
        case estimatesPending = "estimates_pending"
        case estimatesApproved = "estimates_approved"
        case servicesActive = "services_active"
        case revenueTotal = "revenue_total"
        case paymentsPending = "payments_pending"
        case customersTotal = "customers_total"
        case vehiclesTotal = "vehicles_total"
        case totalMechanics = "total_mechanics"
        case invoicesPaid = "invoices_paid"
        case invoicesPaidTotal = "invoices_paid_total"
        case invoicesOutstanding = "invoices_outstanding"
        case invoicesOutstandingTotal = "invoices_outstanding_total"
        case averageTicket = "average_ticket"
    }

    init(
        bookingsTotal: Int? = 0,
        bookingsToday: Int? = 0,
        bookingsPending: Int? = 0,
        bookingsConfirmed: Int? = 0,
        servicesCompleted: Int? = 0,
        estimatesPending: Int? = 0,
        estimatesApproved: Int? = 0,
        servicesActive: Int? = 0,
        revenueTotal: Double? = 0.0,
        paymentsPending: Int? = 0,
        customersTotal: Int? = 0,
        vehiclesTotal: Int? = 0,
        totalMechanics: Int? = 0,
        invoicesPaid: Int? = 0,
        invoicesPaidTotal: Double? = 0.0,
        invoicesOutstanding: Int? = 0,
        invoicesOutstandingTotal: Double? = 0.0,
        averageTicket: Double? = 0.0
    ) {
        self.bookingsTotal = bookingsTotal
        self.bookingsToday = bookingsToday
        self.bookingsPending = bookingsPending
        self.bookingsConfirmed = bookingsConfirmed
        self.servicesCompleted = servicesCompleted
        self.estimatesPending = estimatesPending
        self.estimatesApproved = estimatesApproved
        self.servicesActive = servicesActive
        self.revenueTotal = revenueTotal
        self.paymentsPending = paymentsPending
        self.customersTotal = customersTotal
        self.vehiclesTotal = vehiclesTotal
        self.totalMechanics = totalMechanics
        self.invoicesPaid = invoicesPaid
        self.invoicesPaidTotal = invoicesPaidTotal
        self.invoicesOutstanding = invoicesOutstanding
        self.invoicesOutstandingTotal = invoicesOutstandingTotal
        self.averageTicket = averageTicket
    }
}

// MARK: - Payment & Gateway Settings (/admin/payment-settings)
struct PaymentSettings: Codable {
    var onlinePaymentEnabled: Bool?
    var squareMode: String?
    var squareApplicationIdSandbox: String?
    var squareApplicationIdLive: String?
    var squareLocationIdSandbox: String?
    var squareLocationIdLive: String?
    var squareAccessTokenSandbox: String?
    var squareAccessTokenLive: String?
    var payCashEnabled: Bool?
    var payCardEnabled: Bool?
    var payQrEnabled: Bool?
    var payBankTransferEnabled: Bool?
    var qrImageUrl: String?
    var qrInstructions: String?
    var cashInstructions: String?
    var cardBrands: String?
    var cardSurchargePercent: Double?
    var cardInstructions: String?
    var bankName: String?
    var bankAccountName: String?
    var bankAccountNumber: String?
    var bankBranch: String?
    var bankSwiftCode: String?
    var bankRoutingCode: String?
    var bankInstructions: String?

    enum CodingKeys: String, CodingKey {
        case onlinePaymentEnabled = "online_payment_enabled"
        case squareMode = "square_mode"
        case squareApplicationIdSandbox = "square_application_id_sandbox"
        case squareApplicationIdLive = "square_application_id_live"
        case squareLocationIdSandbox = "square_location_id_sandbox"
        case squareLocationIdLive = "square_location_id_live"
        case squareAccessTokenSandbox = "square_access_token_sandbox"
        case squareAccessTokenLive = "square_access_token_live"
        case payCashEnabled = "pay_cash_enabled"
        case payCardEnabled = "pay_card_enabled"
        case payQrEnabled = "pay_qr_enabled"
        case payBankTransferEnabled = "pay_bank_transfer_enabled"
        case qrImageUrl = "qr_image_url"
        case qrInstructions = "qr_instructions"
        case cashInstructions = "cash_instructions"
        case cardBrands = "card_brands"
        case cardSurchargePercent = "card_surcharge_percent"
        case cardInstructions = "card_instructions"
        case bankName = "bank_name"
        case bankAccountName = "bank_account_name"
        case bankAccountNumber = "bank_account_number"
        case bankBranch = "bank_branch"
        case bankSwiftCode = "bank_swift_code"
        case bankRoutingCode = "bank_routing_code"
        case bankInstructions = "bank_instructions"
    }
}

// MARK: - Staff Member Model (/admin/staff)
struct StaffMember: Codable, Identifiable {
    let id: Int
    let name: String
    let email: String
    let phone: String?
    let role: String?
    let status: String?
    let department: String?
    let employeeId: String?
    let jobTitle: String?

    enum CodingKeys: String, CodingKey {
        case id, name, email, phone, role, status, department
        case employeeId = "employee_id"
        case jobTitle = "job_title"
    }
}

// MARK: - Staff Schedule Model (/admin/staff-schedule)
struct StaffSchedule: Codable, Identifiable {
    let id: Int
    let staffId: Int?
    let staffName: String?
    let dayOfWeek: String?
    let startTime: String?
    let endTime: String?
    let isWorking: Bool?

    enum CodingKeys: String, CodingKey {
        case id
        case staffId = "staff_id"
        case staffName = "staff_name"
        case dayOfWeek = "day_of_week"
        case startTime = "start_time"
        case endTime = "end_time"
        case isWorking = "is_working"
    }
}

// MARK: - Staff Leave Model (/admin/staff-leave)
struct StaffLeave: Codable, Identifiable {
    let id: Int
    let staffId: Int?
    let staffName: String?
    let startDate: String?
    let endDate: String?
    let reason: String?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case id, reason, status
        case staffId = "staff_id"
        case staffName = "staff_name"
        case startDate = "start_date"
        case endDate = "end_date"
    }
}

// MARK: - Mechanic Personal Profile (/mechanic/me)
struct MechanicMe: Codable {
    let id: Int
    let name: String
    let specialty: String?
    let photoUrl: String?
    let phone: String?
    let email: String?
    let workingHours: String?

    enum CodingKeys: String, CodingKey {
        case id, name, specialty, phone, email
        case photoUrl = "photo_url"
        case workingHours = "working_hours"
    }
}

// MARK: - Mechanic Jobs Model (/mechanic/jobs & /mechanic/available)
struct MechanicJobVehicle: Codable {
    let make: String?
    let model: String?
    let year: Int?
    let registrationNumber: String?
    let vehicleType: String?

    enum CodingKeys: String, CodingKey {
        case make, model, year
        case registrationNumber = "registration_number"
        case vehicleType = "vehicle_type"
    }

    func displayName() -> String {
        return "\(year.map { "\($0) " } ?? "")\(make ?? "") \(model ?? "")".trimmingCharacters(in: .whitespaces)
    }
}

struct MechanicJob: Codable, Identifiable {
    let id: Int
    let reference: String
    let status: String
    let scheduledDate: String
    let scheduledTime: String
    let services: [String]?
    let notes: String?
    let vehicle: MechanicJobVehicle?
    let customerFirstName: String?
    let paymentStatus: String?
    let updatedAt: String?

    enum CodingKeys: String, CodingKey {
        case id, reference, status, notes, services, vehicle
        case scheduledDate = "scheduled_date"
        case scheduledTime = "scheduled_time"
        case customerFirstName = "customer_first_name"
        case paymentStatus = "payment_status"
        case updatedAt = "updated_at"
    }
}

// MARK: - Admin Creation & Update Requests
struct CreateServiceRequest: Codable {
    let name: String
    let categoryId: Int?
    let price: Double
    let salePrice: Double?
    let durationMinutes: Int
    let featured: Bool
    let status: String
    let description: String?
    let shortDescription: String?
    let includedItems: String?
    let warrantyInfo: String?

    enum CodingKeys: String, CodingKey {
        case name, price, featured, status, description
        case categoryId = "category_id"
        case salePrice = "sale_price"
        case durationMinutes = "duration_minutes"
        case shortDescription = "short_description"
        case includedItems = "included_items"
        case warrantyInfo = "warranty_info"
    }
}

struct CreateCategoryRequest: Codable {
    let name: String
    let icon: String?
    let description: String?
    let displayOrder: Int?

    enum CodingKeys: String, CodingKey {
        case name, icon, description
        case displayOrder = "display_order"
    }
}

struct CreateBrandRequest: Codable {
    let name: String
    let logoUrl: String?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case name
        case logoUrl = "logo_url"
        case status
    }
}

struct CreateDealRequest: Codable {
    let title: String
    let description: String?
    let code: String
    let discountType: String
    let discountValue: Double
    let minSpend: Double?
    let startsAt: String?
    let endsAt: String?
    let appliesTo: String?
    let publicDeal: Bool?

    enum CodingKeys: String, CodingKey {
        case title, description, code
        case discountType = "discount_type"
        case discountValue = "discount_value"
        case minSpend = "min_spend"
        case startsAt = "starts_at"
        case endsAt = "ends_at"
        case appliesTo = "applies_to"
        case publicDeal = "public"
    }
}

struct CreateMechanicRequest: Codable {
    let name: String
    let email: String?
    let phone: String?
    let specialization: String?
    let experienceYears: Int?
    let workingHours: String?
    let status: String?

    enum CodingKeys: String, CodingKey {
        case name, email, phone, specialization, status
        case experienceYears = "experience_years"
        case workingHours = "working_hours"
    }
}

struct CreateStaffRequest: Codable {
    let name: String
    let email: String
    let phone: String?
    let role: String
    let department: String?
    let password: String?

    enum CodingKeys: String, CodingKey {
        case name, email, phone, role, department, password
    }
}

struct UpdateSettingsRequest: Codable {
    var siteName: String?
    var tagline: String?
    var phone: String?
    var secondaryPhone: String?
    var email: String?
    var address: String?
    var mapUrl: String?
    var currency: String?
    var currencySymbol: String?
    var taxRate: Double?
    var maintenanceMode: Bool?
    var maintenanceMessage: String?
    var maintenanceUntil: String?

    enum CodingKeys: String, CodingKey {
        case phone, email, address, currency
        case siteName = "site_name"
        case tagline
        case secondaryPhone = "secondary_phone"
        case mapUrl = "map_url"
        case currencySymbol = "currency_symbol"
        case taxRate = "tax_rate"
        case maintenanceMode = "maintenance_mode"
        case maintenanceMessage = "maintenance_message"
        case maintenanceUntil = "maintenance_until"
    }
}

struct CreateInvoiceRequest: Codable {
    let bookingId: Int?
    let userId: Int?
    let customerName: String?
    let customerEmail: String?
    let items: [[String: String]]
    let subtotal: Double
    let tax: Double
    let total: Double
    let dueDate: String?
    let notes: String?

    enum CodingKeys: String, CodingKey {
        case items, subtotal, tax, total, notes
        case bookingId = "booking_id"
        case userId = "user_id"
        case customerName = "customer_name"
        case customerEmail = "customer_email"
        case dueDate = "due_date"
    }
}

struct GoogleSyncResult: Codable {
    let success: Bool?
    let message: String?
    let reviewsCount: Int?
    let syncedAt: String?

    enum CodingKeys: String, CodingKey {
        case success, message
        case reviewsCount = "reviews_count"
        case syncedAt = "synced_at"
    }
}

struct CashReport: Codable {
    let totalCash: Double?
    let transactionsCount: Int?
    let reportDate: String?

    enum CodingKeys: String, CodingKey {
        case totalCash = "total_cash"
        case transactionsCount = "transactions_count"
        case reportDate = "report_date"
    }
}
