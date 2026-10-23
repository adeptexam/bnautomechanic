//
//  APIService.swift
//  BNAutoMechanic
//

import Foundation

// MARK: - Session Manager
class SessionManager: ObservableObject {
    static let shared = SessionManager()

    private let defaults = UserDefaults.standard
    private let tokenKey = "access_token"
    private let userKey = "user_json"
    private let loggedInKey = "is_logged_in"

    @Published var isLoggedIn: Bool = false
    @Published var currentUser: User?

    private init() {
        isLoggedIn = defaults.bool(forKey: loggedInKey) && getToken() != nil
        currentUser = getUser()
    }

    func saveAuth(token: String, user: User) {
        defaults.set(token, forKey: tokenKey)
        if let data = try? JSONEncoder().encode(user) {
            defaults.set(data, forKey: userKey)
        }
        defaults.set(true, forKey: loggedInKey)
        DispatchQueue.main.async {
            self.isLoggedIn = true
            self.currentUser = user
        }
    }

    func getToken() -> String? {
        return defaults.string(forKey: tokenKey)
    }

    func getUser() -> User? {
        guard let data = defaults.data(forKey: userKey) else { return nil }
        return try? JSONDecoder().decode(User.self, from: data)
    }

    func logout() {
        defaults.removeObject(forKey: tokenKey)
        defaults.removeObject(forKey: userKey)
        defaults.set(false, forKey: loggedInKey)
        DispatchQueue.main.async {
            self.isLoggedIn = false
            self.currentUser = nil
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

        if let params = queryParams {
            var components = URLComponents(string: urlString)!
            components.queryItems = params.map { URLQueryItem(name: $0.key, value: $0.value) }
            urlString = components.url!.absoluteString
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

        guard (200...499).contains(httpResponse.statusCode) else {
            throw APIError.serverError(httpResponse.statusCode)
        }

        do {
            let apiResponse = try decoder.decode(ApiResponse<T>.self, from: data)
            return apiResponse
        } catch {
            // Try to parse just the data field directly
            if let directData = try? decoder.decode(T.self, from: data) {
                return ApiResponse<T>(from: directData)
            }
            throw APIError.decodingError(error.localizedDescription)
        }
    }

    // MARK: - Auth
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

    // MARK: - Bookings
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

    func getAvailability(date: String) async throws -> ApiResponse<Availability> {
        return try await makeRequest(endpoint: "bookings/availability", queryParams: ["date": date])
    }

    func trackBooking(reference: String, phone: String) async throws -> ApiResponse<BookingTrack> {
        return try await makeRequest(
            endpoint: "bookings/track",
            queryParams: ["reference": reference, "phone": phone]
        )
    }

    func getServiceHistory(perPage: Int = 50) async throws -> ApiResponse<Paginated<Booking>> {
        return try await makeRequest(endpoint: "service-history", queryParams: ["per_page": "\(perPage)"])
    }

    // MARK: - Services
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
        return try await makeRequest(endpoint: "services/categories")
    }

    // MARK: - Vehicles
    func getVehicles() async throws -> ApiResponse<Paginated<Vehicle>> {
        return try await makeRequest(endpoint: "vehicles")
    }

    func createVehicle(_ request: CreateVehicleRequest) async throws -> ApiResponse<Vehicle> {
        return try await makeRequest(endpoint: "vehicles", method: "POST", body: request)
    }

    func deleteVehicle(id: Int) async throws -> ApiResponse<EmptyData> {
        return try await makeRequest(endpoint: "vehicles/\(id)", method: "DELETE")
    }

    // MARK: - Chat
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

    // MARK: - Notifications
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

    // MARK: - Invoices
    func getInvoices(perPage: Int = 50) async throws -> ApiResponse<Paginated<Invoice>> {
        return try await makeRequest(endpoint: "invoices", queryParams: ["per_page": "\(perPage)"])
    }

    func getInvoiceDetail(id: Int) async throws -> ApiResponse<Invoice> {
        return try await makeRequest(endpoint: "invoices/\(id)")
    }

    // MARK: - Reviews
    func getReviews(perPage: Int = 30) async throws -> ApiResponse<Paginated<Review>> {
        return try await makeRequest(endpoint: "reviews", queryParams: ["per_page": "\(perPage)"])
    }

    func getReviewSummary() async throws -> ApiResponse<ReviewSummary> {
        return try await makeRequest(endpoint: "reviews/summary")
    }

    func createReview(_ request: CreateReviewRequest) async throws -> ApiResponse<Review> {
        return try await makeRequest(endpoint: "reviews", method: "POST", body: request)
    }

    // MARK: - Deals & Settings
    func getDeals() async throws -> ApiResponse<Paginated<Deal>> {
        return try await makeRequest(endpoint: "deals")
    }

    func getSettings() async throws -> ApiResponse<PublicSettings> {
        return try await makeRequest(endpoint: "settings")
    }
}

// MARK: - Helpers
struct EmptyData: Codable {}

extension ApiResponse {
    init(from directData: T) {
        self.init(success: true, data: directData, message: nil, code: nil)
    }

    init(success: Bool?, data: T?, message: String?, code: String?) {
        self.success = success
        self.data = data
        self.message = message
        self.code = code
    }
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
    case serverError(Int)
    case decodingError(String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid URL"
        case .invalidResponse: return "Invalid response from server"
        case .unauthorized: return "Session expired. Please log in again."
        case .serverError(let code): return "Server error (\(code))"
        case .decodingError(let msg): return "Data parsing error: \(msg)"
        }
    }
}
