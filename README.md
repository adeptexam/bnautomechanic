# BN Auto Mechanic - Native iOS Application (Version 2.0)

[![Platform](https://img.shields.io/badge/Platform-iOS%2016.0%2B-blue.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-5.9%2B-orange.svg)](https://swift.org)
[![Version](https://img.shields.io/badge/Version-2.0.0%20(Build%202)-gold.svg)]()
[![API](https://img.shields.io/badge/API-REST%20v2.0-green.svg)](https://api.bnautomechanic.net/docs/)

Native iOS mobile application for **BN Auto Mechanic**, built with **SwiftUI** for iOS 16+. Replicates the exact visual design, color palette, dark luxury aesthetics, and functionality of the Android application, integrated with the production REST API at `https://api.bnautomechanic.net/api/v2/`.

---

## What's New in Version 2.0

1. **REST API v2 & Token Refresh Coordinator**
   - Fully migrated to `https://api.bnautomechanic.net/api/v2/` with serialized `TokenRefreshCoordinator` actor handling silent JWT access token refresh on HTTP 401.
   - Dual header version tagging (`X-App-Version: 2.0.0`, `User-Agent: BNAutoMechanic-iOS/2.0.0`).

2. **Apple Guideline 5.1.1(v) Customer Self-Service Account Deletion**
   - In-app permanent account deletion (`DELETE /users/me`) with double-confirmation dialog, optional departure feedback, credential wiping, and return to clean logged-out state.

3. **Apple Guideline 1.2 User-Generated Content (UGC) Moderation & Safety**
   - New [`ContentModerationManager`](file:///BNAutoMechanic/Services/ContentModerationManager.swift) singleton managing persistent blocked users and reported content.
   - Action menu on every customer review and chat message: **"Report Review"** (categorized reasons) and **"Block Author"**.
   - Pre-submission client-side objectionable content and profanity filtering.

4. **Apple Guideline 3.1.5(a) Physical Repair Payment Gateway**
   - Production [`PaymentGatewaySheet`](file:///BNAutoMechanic/Views/Invoice/PaymentGatewaySheet.swift) supporting Credit/Debit Card (Square/Stripe compatible), Bank Wire/ACH, and Workshop Desk settlement for physical automotive labor and parts.

5. **Dynamic Bay Arrival Slot Capacity Synchronization**
   - Integrated live backend slot synchronization (`GET /bookings/availability?date=YYYY-MM-DD`).
   - Dynamic bay occupancy status (`"3 bays open"`, `"1 bay left"`, `"Fully Booked"`).
   - Workshop closed day detection (Sundays/holidays) with one-tap shortcut to jump to the next open weekday.

6. **Vehicle Garage Full CRUD**
   - Full vehicle update (`PATCH /vehicles/{id}`) with rich spec chips and delete confirmation.

7. **Multi-Role Portal System**
   - Customer Portal, Bay Technician Portal (`/mechanic/jobs`), Admin Dispatcher Portal, and Superadmin Master Dashboard (`DELETE /admin/users/{id}`).

---

## Technical Stack & Architecture

- **Language & Framework**: Swift 5.9+ / SwiftUI (iOS 16.0+)
- **Architecture**: MVVM with async/await modern concurrency & Swift actors
- **Backend API**: RESTful API via `https://api.bnautomechanic.net/api/v2/`
- **State & Session**: `@Published` observable `SessionManager` with persistent credentials and auth headers
- **Theming**: Dark luxury design system matching Android resources (`#050607` background, `#0F1117` luxury cards, `#F5B900` automotive gold, `#E8E9EC` typography)

---

## Project Structure

```
BNAutoMechanic/
├── BNAutoMechanicApp.swift            # App entry, splash screen & session router
├── Theme/
│   └── AppTheme.swift                 # Colors, status badges, buttons, cards & text styles
├── Models/
│   └── Models.swift                   # Typed Codable API models (User, Booking, Service, etc.)
├── Services/
│   ├── APIService.swift               # REST API v2 service & SessionManager
│   └── ContentModerationManager.swift # Apple Guideline 1.2 UGC moderation & blocking
├── Views/
│   ├── Auth/
│   │   └── LoginView.swift            # Sign In, Register & Forgot Password
│   ├── Main/
│   │   ├── MainTabView.swift          # 5-tab luxury navigation bar
│   │   ├── PortalView.swift           # Customer dashboard & quick action hub
│   │   ├── ServicesView.swift         # Categorized service catalog & search
│   │   ├── BookingsView.swift         # Active & completed appointments
│   │   └── ChatListView.swift         # Workshop chat enquiries & UGC report/block
│   ├── Booking/
│   │   ├── BookAppointmentView.swift  # 5-step wizard with real-time bay slot sync
│   │   └── BookingDetailView.swift    # Visit details, extras approval & invoice pay
│   ├── Service/
│   │   └── ServiceDetailView.swift    # Inclusions, warranty, FAQs & direct booking
│   ├── Garage/
│   │   └── VehiclesView.swift         # Garage management & Edit/Add Vehicle sheets
│   ├── History/
│   │   └── ServiceHistoryView.swift   # Lifetime service & repair records
│   ├── Invoice/
│   │   ├── InvoicesView.swift         # Invoices list & itemized payment receipts
│   │   └── PaymentGatewaySheet.swift  # Guideline 3.1.5(a) Card/ACH/Desk settlement
│   ├── Towing/
│   │   └── TowingView.swift           # 24/7 Roadside dispatch & Towing status tracking
│   ├── Tracking/
│   │   └── TrackBookingView.swift     # Live reference code & phone lookup
│   ├── Reviews/
│   │   └── ReviewsView.swift          # Verified reviews with Report & Block actions
│   ├── Deals/
│   │   └── DealsView.swift            # Promotional vouchers & copyable codes
│   ├── Notifications/
│   │   └── NotificationsView.swift    # Notifications center with unread badges
│   ├── Profile/
│   │   ├── ProfileView.swift          # Account settings & version 2.0 footer
│   │   └── ProfileDetailsView.swift   # Profile editing & self-service account deletion
│   ├── Admin/
│   │   ├── SuperadminDashboardView.swift   # Master workshop dashboard
│   │   ├── AdminUsersRolesView.swift       # User deletion & role management
│   │   ├── AdminCatalogManagerView.swift   # Services & pricing editor
│   │   ├── AdminBookingsManagerView.swift  # Booking dispatcher
│   │   └── AdminFinancialsView.swift       # Revenue & transaction reports
│   ├── Mechanic/
│   │   └── MechanicPortalView.swift        # Bay technician active job queue
│   └── Static/
│       └── InfoPageView.swift         # Workshop contacts, hours & v2.0 credentials
└── Assets.xcassets/
    ├── AccentColor.colorset           # Primary gold #F5B900 accent color
    ├── AppIcon.appiconset             # App icon set
    └── AppLogo.imageset               # Official BN Auto Mechanic emblem
```

---

## App Store Submission Information (Version 2.0)

- **Marketing Version**: `2.0`
- **Build Number**: `2`
- **Bundle ID**: `tealover.BNAutoMechanic`
- **Apple Review Demo Account**: `apple.tester@bnautomechanic.net` / `Password123!`
- **Guideline Compliance**:
  - `Guideline 1.2` (Safety: UGC Moderation, Blocking & Pre-Submission Filtering)
  - `Guideline 2.1` (Performance: App Completeness & Full Physical Walkthrough)
  - `Guideline 3.1.5(a)` (Physical Automotive Services & External Payment Settlement)
  - `Guideline 5.1.1(v)` (Privacy: In-App Self-Service Customer Account Deletion)
