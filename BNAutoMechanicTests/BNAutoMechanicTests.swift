//
//  BNAutoMechanicTests.swift
//  BNAutoMechanicTests
//
//  Created by TeaLover on 22/10/2026.
//

import Testing
import Foundation
@testable import BNAutoMechanic

struct BNAutoMechanicTests {

    @Test func userInitials() throws {
        let user1 = User(id: 1, name: "John Doe", email: "john@example.com", phone: nil, address: nil, city: nil, role: "CUSTOMER", status: "ACTIVE", emailVerified: true, createdAt: nil)
        #expect(user1.initials() == "JD")

        let user2 = User(id: 2, name: "Admin", email: "admin@example.com", phone: nil, address: nil, city: nil, role: "ADMIN", status: "ACTIVE", emailVerified: true, createdAt: nil)
        #expect(user2.initials() == "AD")

        let user3 = User(id: 3, name: "", email: "test@example.com", phone: nil, address: nil, city: nil, role: "CUSTOMER", status: "ACTIVE", emailVerified: true, createdAt: nil)
        #expect(user3.initials() == "BN")
    }

    @Test func bookingStatusLogic() throws {
        let activeBooking = Booking(
            id: 1,
            reference: "BN-2023-0001",
            status: "CONFIRMED",
            userId: 1,
            vehicleId: 1,
            mechanicId: nil,
            scheduledDate: "2026-11-01",
            scheduledTime: "10:00 AM",
            notes: nil,
            totalAmount: 150.0,
            paymentStatus: nil,
            amountPaid: 0.0,
            balanceDue: 150.0,
            customerName: nil,
            customerEmail: nil,
            customerPhone: nil,
            services: nil,
            vehicle: nil,
            towing: nil,
            estimate: nil,
            extras: nil,
            coupon: nil,
            invoiceId: nil,
            createdAt: nil
        )

        #expect(activeBooking.canCancel() == true)
        #expect(activeBooking.canReschedule() == true)
        #expect(activeBooking.isClosed() == false)

        let completedBooking = Booking(
            id: 2,
            reference: "BN-2023-0002",
            status: "COMPLETED",
            userId: 1,
            vehicleId: 1,
            mechanicId: nil,
            scheduledDate: "2026-10-01",
            scheduledTime: "10:00 AM",
            notes: nil,
            totalAmount: 200.0,
            paymentStatus: nil,
            amountPaid: 200.0,
            balanceDue: 0.0,
            customerName: nil,
            customerEmail: nil,
            customerPhone: nil,
            services: nil,
            vehicle: nil,
            towing: nil,
            estimate: nil,
            extras: nil,
            coupon: nil,
            invoiceId: nil,
            createdAt: nil
        )

        #expect(completedBooking.canCancel() == false)
        #expect(completedBooking.canReschedule() == false)
        #expect(completedBooking.isClosed() == true)
    }

    @Test func serviceFormatting() throws {
        let service = Service(
            id: 1,
            name: "Full Synthetic Oil Service",
            slug: nil,
            status: "ACTIVE",
            featured: true,
            imageUrl: nil,
            categoryId: 1,
            category: nil,
            description: "Complete synthetic oil and genuine filter replacement.",
            shortDescription: "Oil & filter change",
            basePrice: 89.99,
            durationMinutes: 60,
            warrantyInfo: nil,
            benefits: ["Smooth engine performance", "Extended engine life"],
            includedItems: ["Synthetic oil up to 5 qts", "OEM filter", "Fluid top-off"],
            faqs: nil,
            ratingAverage: 4.9,
            reviewsCount: 120
        )

        #expect(service.formattedDuration() == "1h")
        #expect(service.formattedPrice() == "$89.99")
    }

    @Test func apiResponseDecoding() throws {
        let json = """
        {
            "success": true,
            "data": {
                "id": 10,
                "name": "Jane Smith",
                "email": "jane@example.com"
            },
            "message": "User loaded successfully"
        }
        """.data(using: .utf8)!

        let response = try JSONDecoder().decode(ApiResponse<User>.self, from: json)
        #expect(response.success == true)
        #expect(response.data?.name == "Jane Smith")
        #expect(response.data?.email == "jane@example.com")
        #expect(response.data?.initials() == "JS")
    }
}
