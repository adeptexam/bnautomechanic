# BN Auto Mechanic - Native iOS Application

Native iOS mobile application for **BN Auto Mechanic**, built with **SwiftUI** for iOS 16+. Replicates the exact visual design, color palette, dark luxury aesthetics, and functionality of the Android application, integrated with the backend at `https://api.bnautomechanic.net/api/v1/`.

---

## Technical Stack & Architecture

- **Language & Framework**: Swift 5.9+ / SwiftUI (iOS 16.0+)
- **Architecture**: MVVM with async/await modern concurrency
- **Backend API**: RESTful API via `https://api.bnautomechanic.net/api/v1/`
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
│   └── APIService.swift               # REST API service & SessionManager
├── Views/
│   ├── Auth/
│   │   └── LoginView.swift            # Sign In, Register & Forgot Password
│   ├── Main/
│   │   ├── MainTabView.swift          # 5-tab luxury navigation bar
│   │   ├── PortalView.swift           # Customer dashboard & quick action hub
│   │   ├── ServicesView.swift         # Categorized service catalog & search
│   │   ├── BookingsView.swift         # Active & completed appointments
│   │   └── ChatListView.swift         # Workshop chat enquiries & live messaging
│   ├── Booking/
│   │   ├── BookAppointmentView.swift  # 5-step interactive scheduling wizard
│   │   └── BookingDetailView.swift    # Visit details, estimates, rescheduling & cancel
│   ├── Service/
│   │   └── ServiceDetailView.swift    # Inclusions, warranty, FAQs & direct booking
│   ├── Garage/
│   │   └── VehiclesView.swift         # Garage management & Add Vehicle sheet
│   ├── History/
│   │   └── ServiceHistoryView.swift   # Lifetime service & repair records
│   ├── Invoice/
│   │   └── InvoicesView.swift         # Invoices list & itemized payment receipts
│   ├── Towing/
│   │   └── TowingView.swift           # 24/7 Roadside dispatch & Towing status tracking
│   ├── Tracking/
│   │   └── TrackBookingView.swift     # Live reference code & phone lookup
│   ├── Reviews/
│   │   └── ReviewsView.swift          # Verified reviews & Write Review sheet
│   ├── Deals/
│   │   └── DealsView.swift            # Promotional vouchers & copyable codes
│   ├── Notifications/
│   │   └── NotificationsView.swift    # Notifications center with unread badges
│   ├── Profile/
│   │   ├── ProfileView.swift          # Account settings & hub navigation
│   │   └── ProfileDetailsView.swift   # Profile editing
│   └── Static/
│       └── InfoPageView.swift         # Workshop contacts, hours & 12k-mile warranty
└── Assets.xcassets/
    ├── AccentColor.colorset           # Primary gold #F5B900 accent color
    └── AppIcon.appiconset             # App icon set
```

---

## Features & Screen Mapping

1. **Authentication Flow**
   - **Sign In**: Email & password authentication with show/hide password toggle.
   - **Register**: Full name, email, password, and contact phone number.
   - **Forgot Password**: Password reset request with instant feedback.

2. **Customer Portal Dashboard**
   - Time-sensitive greeting (Morning / Afternoon / Evening).
   - Unread notifications counter badge.
   - Active booking alert card with status pill.
   - 24/7 Roadside Assistance & Emergency Towing call action (`tel:+16095550199`).
   - 6-grid quick access hub (Vehicles, Invoices, Track, History, Reviews, Offers).
   - Featured service cards with direct booking action.

3. **5-Step Booking Wizard**
   - **Step 1**: Select vehicle from user's garage or enter Make, Model, Year, Plate.
   - **Step 2**: Multi-select workshop services with live pricing and duration.
   - **Step 3**: Graphical calendar date picker & arrival time slots.
   - **Step 4**: Service notes, symptom descriptions & promotional coupon code.
   - **Step 5**: Summary review & appointment confirmation with reference generation.

4. **Service Visits & Estimates**
   - Live status badge (`PENDING`, `CONFIRMED`, `IN_PROGRESS`, `ESTIMATE_SENT`, `COMPLETED`, `CANCELLED`).
   - Estimate quotation card with one-tap "Approve Estimate" or "Decline Estimate" with optional reason dialog.
   - Billing breakdown (Subtotal, Total, Paid, Balance Due).
   - Reschedule sheet with calendar picker.
   - Cancel appointment action with confirmation warning.

5. **Customer Garage & Vehicles**
   - Add vehicle dialog (Make, Model, Year, License Plate).
   - Delete vehicle confirmation dialog.

6. **Roadside Assistance & Towing**
   - Emergency 24/7 telephone dispatch.
   - Online flatbed towing request.
   - Active towing status tracking.

7. **Track Visit by Reference**
   - Booking reference code & phone number lookup.
   - Real-time diagnostic stage indicator and lead mechanic assignment.

8. **Reviews & Ratings**
   - 5-star rating breakdown and verified customer reviews.
   - Interactive review submission modal.

9. **Invoices & Receipts**
   - Itemized parts and labor totals, state sales tax, and payment status receipts.

10. **Workshop Messages & Enquiries**
    - Multi-thread chat room list with live messaging and advisor support.