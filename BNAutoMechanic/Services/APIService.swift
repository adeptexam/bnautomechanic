//
//  APIService.swift
//  BNAutoMechanic
//
//  Production-ready networking client communicating with:
//  https://api.bnautomechanic.net/api/v1/
//

import Foundation
import SwiftUI
import Combine

// MARK: - Session Manager
class SessionManager: ObservableObject {
    static let shared = SessionManager()

    private let tokenKey = "auth_token"
    private let userKey = "current_user"
    private let loggedInKey = "is_logged_in"
    private let defaults = UserDefaults.standard

    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User? = nil
    @Published var activePortalMode: PortalMode = .customer

    private init() {
        self.isLoggedIn = defaults.bool(forKey: loggedInKey)
        if let userData = defaults.data(forKey: userKey),
           let user = try? JSONDecoder().decode(User.self, from: userData) {
            self.currentUser = user
            self.activePortalMode = Self.resolvePortalMode(for: user)
        }
    }

    private static func resolvePortalMode(for user: User?) -> PortalMode {
        guard let u = user else { return .customer }
        if u.isSuperAdmin { return .superadmin }
        if u.isAdmin { return .admin }
        if u.isMechanic { return .technician }
        return .customer
    }

    func syncPortalMode() {
        self.activePortalMode = Self.resolvePortalMode(for: currentUser)
    }

    func setPortalMode(_ mode: PortalMode) {
        withAnimation {
            self.activePortalMode = mode
        }
    }

    func saveSession(token: String, user: User?) {
        defaults.set(token, forKey: tokenKey)
        defaults.set(true, forKey: loggedInKey)
        if let user = user,
           let encoded = try? JSONEncoder().encode(user) {
            defaults.set(encoded, forKey: userKey)
        }
        DispatchQueue.main.async {
            self.isLoggedIn = true
            self.currentUser = user
            self.syncPortalMode()
        }
    }

    func getToken() -> String? {
        return defaults.string(forKey: tokenKey)
    }

    func getUser() -> User? {
        return currentUser
    }

    func saveAuth(token: String, user: User?) {
        saveSession(token: token, user: user)
    }

    func logout() {
        defaults.removeObject(forKey: tokenKey)
        defaults.removeObject(forKey: userKey)
        defaults.set(false, forKey: loggedInKey)
        DispatchQueue.main.async {
            self.isLoggedIn = false
            self.currentUser = nil
            self.activePortalMode = .customer
        }
    }
}

// MARK: - API Service
class APIService {
    static let shared = APIService()
    private let baseURL = "https://api.bnautomechanic.net/api/v1/"
    private let session = URLSession.shared
    private let decoder: JSONDecoder = {
        let d = JSONDecoder()
        return d
    }()

    private init() {}

    // MARK: - Core Request Method
    private func makeRequest<T: Codable>(
        endpoint: String,
        method: String = "GET",
        body: Encodable? = nil,
        queryParams: [String: String]? = nil
    ) async throws -> ApiResponse<T> {
        var urlString = baseURL + endpoint

        if let params = queryParams, !params.isEmpty {
            if var components = URLComponents(string: urlString) {
                var queryItems = components.queryItems ?? []
                for (key, value) in params {
                    queryItems.append(URLQueryItem(name: key, value: value))
                }
                components.queryItems = queryItems
                if let resolvedUrl = components.url?.absoluteString {
                    urlString = resolvedUrl
                }
            }
        }

        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15

        if let token = SessionManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body = body {
            request.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        // Try standard ApiResponse<T> decode
        if let apiResponse = try? decoder.decode(ApiResponse<T>.self, from: data) {
            if httpResponse.statusCode >= 400 && apiResponse.success != true {
                let errMessage = apiResponse.message ?? "Server request failed (\(httpResponse.statusCode))"
                throw APIError.serverMessage(errMessage)
            }
            return apiResponse
        }

        // Try decoding directly as T
        if let directData = try? decoder.decode(T.self, from: data) {
            return ApiResponse<T>(from: directData)
        }

        // If error response format: {"error": {"message": "...", "code": "..."}, "success": false}
        if let errObj = try? decoder.decode(ApiErrorResponse.self, from: data) {
            let msg = errObj.error?.message ?? errObj.message ?? "Server returned error (\(httpResponse.statusCode))"
            throw APIError.serverMessage(msg)
        }

        if !(200...299).contains(httpResponse.statusCode) {
            throw APIError.serverError(httpResponse.statusCode)
        }

        throw APIError.decodingError("Unable to parse response data")
    }

    // MARK: - Auth (users, tokens, password_resets)
    func login(email: String, password: String) async throws -> ApiResponse<AuthSession> {
        return try await makeRequest(
            endpoint: "auth/login",
            method: "POST",
            body: LoginRequest(email: email, password: password)
        )
    }

    func register(name: String, email: String, password: String, phone: String?) async throws -> ApiResponse<AuthSession> {
        return try await makeRequest(
            endpoint: "auth/register",
            method: "POST",
            body: RegisterRequest(name: name, email: email, password: password, phone: phone)
        )
    }

    func forgotPassword(email: String) async throws -> ApiResponse<EmptyData> {
        return try await makeRequest(
            endpoint: "auth/forgot-password",
            method: "POST",
            body: ForgotPasswordRequest(email: email)
        )
    }

    func logout() async throws -> ApiResponse<EmptyData> {
        return try await makeRequest(
            endpoint: "auth/logout",
            method: "POST"
        )
    }

    func getCurrentUser() async throws -> ApiResponse<User> {
        return try await makeRequest(endpoint: "users/me")
    }

    func updateProfile(name: String, phone: String?, address: String?, city: String?, state: String?, postalCode: String?) async throws -> ApiResponse<User> {
        struct UpdateProfileRequest: Codable {
            let name: String
            let phone: String?
            let address: String?
            let city: String?
            let state: String?
            let postalCode: String?
            enum CodingKeys: String, CodingKey {
                case name, phone, address, city, state
                case postalCode = "postal_code"
            }
        }
        let body = UpdateProfileRequest(name: name, phone: phone, address: address, city: city, state: state, postalCode: postalCode)
        return try await makeRequest(endpoint: "users/me", method: "PUT", body: body)
    }

    // MARK: - Bookings & Estimates (bookings table)
    func getBookings(perPage: Int = 50, status: String? = nil) async throws -> ApiResponse<Paginated<Booking>> {
        var params: [String: String] = ["per_page": "\(perPage)", "sort": "-scheduled_date"]
        if let s = status { params["status"] = s }
        return try await makeRequest(endpoint: "bookings", queryParams: params)
    }

    func getBookingDetail(id: Int) async throws -> ApiResponse<Booking> {
        return try await makeRequest(endpoint: "bookings/\(id)")
    }

    func createBooking(_ request: CreateBookingRequest) async throws -> ApiResponse<Booking> {
        return try await makeRequest(endpoint: "bookings", method: "POST", body: request)
    }

    func rescheduleBooking(id: Int, date: String, time: String) async throws -> ApiResponse<Booking> {
        let body: [String: String] = ["scheduled_date": date, "scheduled_time": time]
        return try await makeRequest(endpoint: "bookings/\(id)/reschedule", method: "PATCH", body: body)
    }

    func cancelBooking(id: Int, reason: String) async throws -> ApiResponse<Booking> {
        let body: [String: String] = ["reason": reason]
        return try await makeRequest(endpoint: "bookings/\(id)/cancel", method: "PATCH", body: body)
    }

    func approveEstimate(id: Int) async throws -> ApiResponse<Booking> {
        return try await makeRequest(endpoint: "bookings/\(id)/estimate/approve", method: "POST")
    }

    func rejectEstimate(id: Int, reason: String) async throws -> ApiResponse<Booking> {
        let body: [String: String] = ["reason": reason]
        return try await makeRequest(endpoint: "bookings/\(id)/estimate/reject", method: "POST", body: body)
    }

    func approveBookingExtra(bookingId: Int, extraId: Int) async throws -> ApiResponse<Booking> {
        return try await makeRequest(endpoint: "bookings/\(bookingId)/extras/\(extraId)/approve", method: "POST")
    }

    func declineBookingExtra(bookingId: Int, extraId: Int) async throws -> ApiResponse<Booking> {
        return try await makeRequest(endpoint: "bookings/\(bookingId)/extras/\(extraId)/decline", method: "POST")
    }

    func getAvailability(date: String) async throws -> ApiResponse<Availability> {
        return try await makeRequest(endpoint: "bookings/availability", queryParams: ["date": date])
    }

    func trackBooking(reference: String, phone: String) async throws -> ApiResponse<BookingTrack> {
        return try await makeRequest(
            endpoint: "bookings/track",
            queryParams: ["reference": reference, "phone": phone]
        )
    }

    // MARK: - Service History (service_history table)
    func getServiceHistory(perPage: Int = 50) async throws -> ApiResponse<Paginated<Booking>> {
        return try await makeRequest(endpoint: "service-history", queryParams: ["per_page": "\(perPage)"])
    }

    // MARK: - Services & Categories (services, categories tables)
    func getServices(perPage: Int = 50, featured: Bool? = nil, categoryId: Int? = nil, search: String? = nil) async throws -> ApiResponse<Paginated<Service>> {
        var params: [String: String] = ["per_page": "\(perPage)"]
        if let f = featured { params["featured"] = f ? "true" : "false" }
        if let c = categoryId { params["category_id"] = "\(c)" }
        if let s = search { params["search"] = s }
        return try await makeRequest(endpoint: "services", queryParams: params)
    }

    func getServiceDetail(id: Int) async throws -> ApiResponse<Service> {
        return try await makeRequest(endpoint: "services/\(id)")
    }

    func getCategories() async throws -> ApiResponse<[ServiceCategory]> {
        return try await makeRequest(endpoint: "categories")
    }

    // MARK: - Brands (brands table)
    func getBrands() async throws -> ApiResponse<Paginated<Brand>> {
        return try await makeRequest(endpoint: "brands")
    }

    // MARK: - Mechanics (mechanics table)
    func getMechanics() async throws -> ApiResponse<Paginated<Mechanic>> {
        return try await makeRequest(endpoint: "mechanics")
    }

    // MARK: - Vehicles (vehicles table)
    func getVehicles() async throws -> ApiResponse<Paginated<Vehicle>> {
        return try await makeRequest(endpoint: "vehicles")
    }

    func createVehicle(_ request: CreateVehicleRequest) async throws -> ApiResponse<Vehicle> {
        return try await makeRequest(endpoint: "vehicles", method: "POST", body: request)
    }

    func deleteVehicle(id: Int) async throws -> ApiResponse<EmptyData> {
        return try await makeRequest(endpoint: "vehicles/\(id)", method: "DELETE")
    }

    // MARK: - Towing Requests (towing_requests table)
    func getTowingRequests(perPage: Int = 50) async throws -> ApiResponse<Paginated<TowingRequest>> {
        return try await makeRequest(endpoint: "towing", queryParams: ["per_page": "\(perPage)"])
    }

    func submitTowingRequest(_ request: CreateTowingRequest) async throws -> ApiResponse<TowingRequest> {
        return try await makeRequest(endpoint: "towing", method: "POST", body: request)
    }

    // MARK: - Chat (chat_rooms & chat_messages tables)
    func getChatRooms() async throws -> ApiResponse<Paginated<ChatRoom>> {
        return try await makeRequest(endpoint: "chat/rooms")
    }

    func createChatRoom(subject: String) async throws -> ApiResponse<ChatRoom> {
        return try await makeRequest(
            endpoint: "chat/rooms",
            method: "POST",
            body: CreateRoomRequest(subject: subject)
        )
    }

    func getChatMessages(roomId: Int, perPage: Int = 100) async throws -> ApiResponse<Paginated<ChatMessage>> {
        return try await makeRequest(
            endpoint: "chat/rooms/\(roomId)/messages",
            queryParams: ["per_page": "\(perPage)"]
        )
    }

    func sendMessage(roomId: Int, body: String) async throws -> ApiResponse<ChatMessage> {
        return try await makeRequest(
            endpoint: "chat/rooms/\(roomId)/messages",
            method: "POST",
            body: SendMessageRequest(body: body)
        )
    }

    // MARK: - Notifications (notifications table)
    func getNotifications(perPage: Int = 50) async throws -> ApiResponse<Paginated<AppNotification>> {
        return try await makeRequest(endpoint: "notifications", queryParams: ["per_page": "\(perPage)"])
    }

    func getUnreadCount() async throws -> ApiResponse<UnreadCount> {
        return try await makeRequest(endpoint: "notifications/unread-count")
    }

    func markNotificationRead(id: Int) async throws -> ApiResponse<AppNotification> {
        return try await makeRequest(endpoint: "notifications/\(id)/read", method: "POST")
    }

    func markAllNotificationsRead() async throws -> ApiResponse<EmptyData> {
        return try await makeRequest(endpoint: "notifications/read-all", method: "POST")
    }

    // MARK: - Invoices (invoices table)
    func getInvoices(perPage: Int = 50) async throws -> ApiResponse<Paginated<Invoice>> {
        return try await makeRequest(endpoint: "invoices", queryParams: ["per_page": "\(perPage)"])
    }

    func getInvoiceDetail(id: Int) async throws -> ApiResponse<Invoice> {
        return try await makeRequest(endpoint: "invoices/\(id)")
    }

    // MARK: - Payments (payments table)
    func getPayments(perPage: Int = 50) async throws -> ApiResponse<Paginated<Payment>> {
        return try await makeRequest(endpoint: "payments", queryParams: ["per_page": "\(perPage)"])
    }

    // MARK: - Reviews (reviews table)
    func getReviews(perPage: Int = 30) async throws -> ApiResponse<Paginated<Review>> {
        return try await makeRequest(endpoint: "reviews", queryParams: ["per_page": "\(perPage)"])
    }

    func getReviewSummary() async throws -> ApiResponse<ReviewSummary> {
        return try await makeRequest(endpoint: "reviews/summary")
    }

    func createReview(_ request: CreateReviewRequest) async throws -> ApiResponse<Review> {
        return try await makeRequest(endpoint: "reviews", method: "POST", body: request)
    }

    // MARK: - Deals & Coupons (deals table)
    func getDeals() async throws -> ApiResponse<Paginated<Deal>> {
        return try await makeRequest(endpoint: "deals")
    }

    // MARK: - Favorites (favorites table)
    func getFavorites() async throws -> ApiResponse<[Favorite]> {
        return try await makeRequest(endpoint: "favorites")
    }

    func addFavorite(serviceId: Int) async throws -> ApiResponse<EmptyData> {
        return try await makeRequest(endpoint: "favorites/\(serviceId)", method: "POST")
    }

    func removeFavorite(serviceId: Int) async throws -> ApiResponse<EmptyData> {
        return try await makeRequest(endpoint: "favorites/\(serviceId)", method: "DELETE")
    }

    // MARK: - Contact Messages (contact_messages table)
    func submitContactMessage(_ request: ContactMessageRequest) async throws -> ApiResponse<EmptyData> {
        return try await makeRequest(endpoint: "contact", method: "POST", body: request)
    }

    // MARK: - Blog Posts (blog_posts table)
    func getBlogPosts(perPage: Int = 20) async throws -> ApiResponse<Paginated<BlogPost>> {
        return try await makeRequest(endpoint: "blogs", queryParams: ["per_page": "\(perPage)"])
    }

    // MARK: - Device Tokens (device_tokens table)
    func registerDeviceToken(_ request: RegisterDeviceTokenRequest) async throws -> ApiResponse<EmptyData> {
        return try await makeRequest(endpoint: "device-tokens", method: "POST", body: request)
    }

    // MARK: - Platform Settings (settings table)
    func getSettings() async throws -> ApiResponse<PublicSettings> {
        return try await makeRequest(endpoint: "settings")
    }

    // MARK: - Generic Raw Request for Dynamic Admin Operations
    private func makeRequestRaw<T: Codable>(
        endpoint: String,
        method: String = "GET",
        jsonBody: [String: Any]? = nil,
        queryParams: [String: String]? = nil
    ) async throws -> ApiResponse<T> {
        var urlString = baseURL + endpoint

        if let params = queryParams, !params.isEmpty {
            if var components = URLComponents(string: urlString) {
                var queryItems = components.queryItems ?? []
                for (key, value) in params {
                    queryItems.append(URLQueryItem(name: key, value: value))
                }
                components.queryItems = queryItems
                if let resolvedUrl = components.url?.absoluteString {
                    urlString = resolvedUrl
                }
            }
        }

        guard let url = URL(string: urlString) else {
            throw APIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = method
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 15

        if let token = SessionManager.shared.getToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let jsonBody = jsonBody {
            request.httpBody = try JSONSerialization.data(withJSONObject: jsonBody, options: [])
        }

        let (data, response) = try await session.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw APIError.unauthorized
        }

        if let apiResponse = try? decoder.decode(ApiResponse<T>.self, from: data) {
            if httpResponse.statusCode >= 400 && apiResponse.success != true {
                let errMessage = apiResponse.message ?? "Server request failed (\(httpResponse.statusCode))"
                throw APIError.serverMessage(errMessage)
            }
            return apiResponse
        }

        if let directData = try? decoder.decode(T.self, from: data) {
            return ApiResponse<T>(from: directData)
        }

        if let errObj = try? decoder.decode(ApiErrorResponse.self, from: data) {
            let msg = errObj.error?.message ?? errObj.message ?? "Server returned error (\(httpResponse.statusCode))"
            throw APIError.serverMessage(msg)
        }

        if !(200...299).contains(httpResponse.statusCode) {
            throw APIError.serverError(httpResponse.statusCode)
        }

        throw APIError.decodingError("Unable to parse response data")
    }

    // MARK: - Admin Statistics (/admin/stats)
    func getAdminStats() async throws -> ApiResponse<AdminStats> {
        return try await makeRequest(endpoint: "admin/stats")
    }

    // MARK: - Admin Bookings Management (CRUD, Status, Estimates, Extras, Dispatch)
    func getAdminBookings(
        page: Int = 1,
        perPage: Int = 50,
        status: String? = nil,
        search: String? = nil,
        sort: String? = "scheduled_date",
        order: String? = "desc"
    ) async throws -> ApiResponse<Paginated<Booking>> {
        var params: [String: String] = [
            "page": "\(page)",
            "per_page": "\(perPage)"
        ]
        if let s = status, !s.isEmpty, s.uppercased() != "ALL" { params["status"] = s }
        if let q = search, !q.isEmpty { params["search"] = q }
        if let sort = sort { params["sort"] = sort }
        if let order = order { params["order"] = order }
        return try await makeRequest(endpoint: "admin/bookings", queryParams: params)
    }

    func getAdminBookingDetail(id: Int) async throws -> ApiResponse<Booking> {
        return try await makeRequest(endpoint: "admin/bookings/\(id)")
    }

    func updateAdminBookingStatus(id: Int, status: String, notes: String? = nil) async throws -> ApiResponse<Booking> {
        var body: [String: Any] = ["status": status]
        if let n = notes { body["notes"] = n }
        return try await makeRequestRaw(endpoint: "admin/bookings/\(id)/status", method: "PUT", jsonBody: body)
    }

    func saveAdminEstimate(id: Int, items: [[String: Any]], discount: Double = 0.0, taxRate: Double = 0.0, notes: String = "") async throws -> ApiResponse<Booking> {
        let body: [String: Any] = [
            "items": items,
            "discount": discount,
            "tax_rate": taxRate,
            "notes": notes
        ]
        return try await makeRequestRaw(endpoint: "admin/bookings/\(id)/estimate", method: "PUT", jsonBody: body)
    }

    func sendAdminEstimate(id: Int) async throws -> ApiResponse<Booking> {
        return try await makeRequestRaw(endpoint: "admin/bookings/\(id)/estimate/send", method: "POST")
    }

    func approveAdminEstimateOnBehalf(id: Int, note: String = "Approved by staff on behalf of customer") async throws -> ApiResponse<Booking> {
        return try await makeRequestRaw(endpoint: "admin/bookings/\(id)/estimate/approve", method: "POST", jsonBody: ["note": note])
    }

    func assignMechanicToBooking(id: Int, mechanicId: Int?, mechanicIds: [Int]? = nil) async throws -> ApiResponse<Booking> {
        var body: [String: Any] = [:]
        if let m = mechanicId { body["mechanic_id"] = m }
        if let ms = mechanicIds { body["mechanic_ids"] = ms }
        return try await makeRequestRaw(endpoint: "admin/bookings/\(id)/assign", method: "POST", jsonBody: body)
    }

    func addBookingExtra(bookingId: Int, name: String, price: Double, notes: String? = nil) async throws -> ApiResponse<Booking> {
        var body: [String: Any] = ["name": name, "price": price]
        if let n = notes { body["notes"] = n }
        return try await makeRequestRaw(endpoint: "admin/bookings/\(bookingId)/extras", method: "POST", jsonBody: body)
    }

    func deleteBookingExtra(bookingId: Int, extraId: Int) async throws -> ApiResponse<Booking> {
        return try await makeRequestRaw(endpoint: "admin/bookings/\(bookingId)/extras/\(extraId)", method: "DELETE")
    }

    func confirmBookingExtra(bookingId: Int, extraId: Int) async throws -> ApiResponse<Booking> {
        return try await makeRequestRaw(endpoint: "admin/bookings/\(bookingId)/extras/\(extraId)/confirm", method: "POST")
    }

    func deleteAdminBooking(id: Int) async throws -> ApiResponse<EmptyData> {
        return try await makeRequest(endpoint: "admin/bookings/\(id)", method: "DELETE")
    }

    // MARK: - Admin Mechanics & Staff Dispatcher (CRUD)
    func getAdminMechanics() async throws -> ApiResponse<Paginated<Mechanic>> {
        return try await makeRequest(endpoint: "admin/mechanics", queryParams: ["per_page": "100"])
    }

    func createAdminMechanic(_ request: CreateMechanicRequest) async throws -> ApiResponse<Mechanic> {
        return try await makeRequest(endpoint: "admin/mechanics", method: "POST", body: request)
    }

    func updateAdminMechanic(id: Int, data: [String: Any]) async throws -> ApiResponse<Mechanic> {
        return try await makeRequestRaw(endpoint: "admin/mechanics/\(id)", method: "PUT", jsonBody: data)
    }

    func deleteAdminMechanic(id: Int) async throws -> ApiResponse<EmptyData> {
        return try await makeRequest(endpoint: "admin/mechanics/\(id)", method: "DELETE")
    }

    func getAdminStaff() async throws -> ApiResponse<[StaffMember]> {
        return try await makeRequest(endpoint: "admin/staff")
    }

    func createAdminStaff(_ request: CreateStaffRequest) async throws -> ApiResponse<StaffMember> {
        return try await makeRequest(endpoint: "admin/staff", method: "POST", body: request)
    }

    func deleteAdminStaff(id: Int) async throws -> ApiResponse<EmptyData> {
        return try await makeRequest(endpoint: "admin/staff/\(id)", method: "DELETE")
    }

    // MARK: - Admin Catalog: Services, Categories, Brands (CRUD)
    func createService(_ request: CreateServiceRequest) async throws -> ApiResponse<Service> {
        return try await makeRequest(endpoint: "admin/services", method: "POST", body: request)
    }

    func updateService(id: Int, data: [String: Any]) async throws -> ApiResponse<Service> {
        return try await makeRequestRaw(endpoint: "admin/services/\(id)", method: "PUT", jsonBody: data)
    }

    func deleteService(id: Int) async throws -> ApiResponse<EmptyData> {
        return try await makeRequest(endpoint: "admin/services/\(id)", method: "DELETE")
    }

    func createCategory(_ request: CreateCategoryRequest) async throws -> ApiResponse<ServiceCategory> {
        return try await makeRequest(endpoint: "admin/categories", method: "POST", body: request)
    }

    func updateCategory(id: Int, data: [String: Any]) async throws -> ApiResponse<ServiceCategory> {
        return try await makeRequestRaw(endpoint: "admin/categories/\(id)", method: "PUT", jsonBody: data)
    }

    func deleteCategory(id: Int) async throws -> ApiResponse<EmptyData> {
        return try await makeRequest(endpoint: "admin/categories/\(id)", method: "DELETE")
    }

    func createBrand(_ request: CreateBrandRequest) async throws -> ApiResponse<Brand> {
        return try await makeRequest(endpoint: "admin/brands", method: "POST", body: request)
    }

    func deleteBrand(id: Int) async throws -> ApiResponse<EmptyData> {
        return try await makeRequest(endpoint: "admin/brands/\(id)", method: "DELETE")
    }

    // MARK: - Admin Users & Roles (CRUD)
    func getAdminUsers(page: Int = 1, perPage: Int = 50, role: String? = nil, search: String? = nil) async throws -> ApiResponse<Paginated<User>> {
        var params: [String: String] = ["page": "\(page)", "per_page": "\(perPage)"]
        if let r = role, !r.isEmpty, r.uppercased() != "ALL" { params["role"] = r }
        if let q = search, !q.isEmpty { params["search"] = q }
        return try await makeRequest(endpoint: "admin/users", queryParams: params)
    }

    func updateUserRole(userId: Int, role: String) async throws -> ApiResponse<User> {
        let body: [String: Any] = ["role": role]
        return try await makeRequestRaw(endpoint: "admin/users/\(userId)", method: "PUT", jsonBody: body)
    }

    func deleteUser(userId: Int) async throws -> ApiResponse<EmptyData> {
        return try await makeRequest(endpoint: "admin/users/\(userId)", method: "DELETE")
    }

    // MARK: - Master Administrative Controls & Settings (CRUD)
    func getAdminSettings() async throws -> ApiResponse<PublicSettings> {
        return try await makeRequest(endpoint: "admin/settings")
    }

    func updateAdminSettings(_ request: UpdateSettingsRequest) async throws -> ApiResponse<PublicSettings> {
        return try await makeRequest(endpoint: "admin/settings", method: "PUT", body: request)
    }

    func getPaymentSettings() async throws -> ApiResponse<PaymentSettings> {
        return try await makeRequest(endpoint: "admin/payment-settings")
    }

    func updatePaymentSettings(_ settings: PaymentSettings) async throws -> ApiResponse<PaymentSettings> {
        return try await makeRequest(endpoint: "admin/payment-settings", method: "PUT", body: settings)
    }

    // MARK: - Deals & Coupons (CRUD)
    func createDeal(_ request: CreateDealRequest) async throws -> ApiResponse<Deal> {
        return try await makeRequest(endpoint: "admin/deals", method: "POST", body: request)
    }

    func deleteDeal(id: Int) async throws -> ApiResponse<EmptyData> {
        return try await makeRequest(endpoint: "admin/deals/\(id)", method: "DELETE")
    }

    func testDealCoupon(code: String, amount: Double = 100.0) async throws -> ApiResponse<AppliedCoupon> {
        let body: [String: Any] = ["code": code, "amount": amount]
        return try await makeRequestRaw(endpoint: "admin/deals/test", method: "POST", jsonBody: body)
    }

    // MARK: - Invoices, Payments & Cash Reports (CRUD)
    func getAdminInvoices(page: Int = 1, perPage: Int = 50, status: String? = nil) async throws -> ApiResponse<Paginated<Invoice>> {
        var params: [String: String] = ["page": "\(page)", "per_page": "\(perPage)"]
        if let s = status, !s.isEmpty, s.uppercased() != "ALL" { params["status"] = s }
        return try await makeRequest(endpoint: "admin/invoices", queryParams: params)
    }

    func createInvoice(_ request: CreateInvoiceRequest) async throws -> ApiResponse<Invoice> {
        return try await makeRequest(endpoint: "admin/invoices", method: "POST", body: request)
    }

    func deleteInvoice(id: Int) async throws -> ApiResponse<EmptyData> {
        return try await makeRequest(endpoint: "admin/invoices/\(id)", method: "DELETE")
    }

    func refundPayment(paymentId: Int, reason: String) async throws -> ApiResponse<Payment> {
        let body: [String: Any] = ["reason": reason]
        return try await makeRequestRaw(endpoint: "admin/payments/\(paymentId)/refund", method: "POST", jsonBody: body)
    }

    func getCashReport(date: String? = nil) async throws -> ApiResponse<CashReport> {
        var params: [String: String]? = nil
        if let d = date { params = ["date": d] }
        return try await makeRequest(endpoint: "admin/reports/cash", queryParams: params)
    }

    // MARK: - Reviews Moderation (CRUD)
    func getAdminReviews(page: Int = 1, perPage: Int = 50) async throws -> ApiResponse<Paginated<Review>> {
        let params: [String: String] = ["page": "\(page)", "per_page": "\(perPage)"]
        return try await makeRequest(endpoint: "admin/reviews", queryParams: params)
    }

    func replyAdminReview(id: Int, response: String) async throws -> ApiResponse<Review> {
        let body: [String: Any] = ["response": response]
        return try await makeRequestRaw(endpoint: "admin/reviews/\(id)", method: "PUT", jsonBody: body)
    }

    func deleteAdminReview(id: Int) async throws -> ApiResponse<EmptyData> {
        return try await makeRequest(endpoint: "admin/reviews/\(id)", method: "DELETE")
    }

    func syncGoogleReviews() async throws -> ApiResponse<GoogleSyncResult> {
        return try await makeRequestRaw(endpoint: "admin/google-reviews/sync", method: "POST")
    }

    // MARK: - Towing Management
    func getAdminTowing(status: String? = nil) async throws -> ApiResponse<Paginated<TowingRequest>> {
        var params: [String: String] = ["per_page": "50"]
        if let s = status { params["status"] = s }
        return try await makeRequest(endpoint: "admin/towing", queryParams: params)
    }

    func updateAdminTowingStatus(id: Int, status: String, notes: String? = nil) async throws -> ApiResponse<TowingRequest> {
        var body: [String: Any] = ["status": status]
        if let n = notes { body["notes"] = n }
        return try await makeRequestRaw(endpoint: "admin/towing/\(id)", method: "PUT", jsonBody: body)
    }

    // MARK: - Technician / Mechanic Bay Endpoints
    func getMechanicMe() async throws -> ApiResponse<MechanicMe> {
        return try await makeRequest(endpoint: "mechanic/me")
    }

    func getMechanicJobs() async throws -> ApiResponse<[MechanicJob]> {
        return try await makeRequest(endpoint: "mechanic/jobs")
    }

    func getMechanicAvailableJobs() async throws -> ApiResponse<[MechanicJob]> {
        return try await makeRequest(endpoint: "mechanic/available")
    }

    func claimMechanicJob(id: Int) async throws -> ApiResponse<Booking> {
        return try await makeRequestRaw(endpoint: "mechanic/jobs/\(id)/claim", method: "POST")
    }

    func updateMechanicJobStatus(id: Int, status: String, notes: String? = nil) async throws -> ApiResponse<Booking> {
        var body: [String: Any] = ["status": status]
        if let n = notes { body["notes"] = n }
        return try await makeRequestRaw(endpoint: "mechanic/jobs/\(id)/status", method: "POST", jsonBody: body)
    }
}

// MARK: - Helpers
struct EmptyData: Codable {}

struct ApiErrorResponse: Codable {
    let success: Bool?
    let message: String?
    let error: ApiErrorDetail?
}

extension Dictionary: @retroactive Encodable where Key == String, Value == String {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: DynamicCodingKeys.self)
        for (key, value) in self {
            try container.encode(value, forKey: DynamicCodingKeys(stringValue: key)!)
        }
    }
}

struct DynamicCodingKeys: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = "\(intValue)"
        self.intValue = intValue
    }
}

// MARK: - API Errors
enum APIError: LocalizedError {
    case invalidURL
    case invalidResponse
    case unauthorized
    case serverMessage(String)
    case serverError(Int)
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid server endpoint URL."
        case .invalidResponse: return "Invalid response received from server."
        case .unauthorized: return "Your session has expired. Please sign in again."
        case .serverMessage(let msg): return msg
        case .serverError(let code): return "Server returned error (\(code))."
        case .decodingError(let msg): return "Data processing error: \(msg)"
        }
    }
}
