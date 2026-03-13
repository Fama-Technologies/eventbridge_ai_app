# EventBridge User Flow and Product Rules

## 1. Product Summary
EventBridge is an automated AI vendor-matching platform that connects customers planning events with trusted vendors who are available and ready for work.

## 2. User Roles
- Customer: Creates event requests, receives vendor matches, sends inquiries, books vendors, rates vendors, and reports issues.
- Vendor: Creates profile, configures packages/portfolio/calendar, receives inquiries, accepts or declines, and communicates with customers.
- Platform/Admin (implicit): Handles support, verification logic, moderation/reporting, and subscription billing.

## 3. Customer Journey (Matching Flow)
### 3.1 Request Input
Customer provides:
- Event type
- Service or services needed
- Guest list (optional)
- Event date
- Event location
- Event time (optional)
- Budget
- Detailed free-text prompt for AI matching

### 3.2 AI Matching
System matches vendors based on:
- Availability on requested date/time
- Budget fit
- Service/event fit
- Customer preferences and prompt intent

### 3.3 Match Results
System returns at least 3-5 matching vendors.

Customer can view:
- Vendor business overview
- Portfolio photos
- Social links (Instagram, TikTok, Facebook, website)
- Service packages
- Reviews/ratings from previous customers

### 3.4 Inquiry
If customer likes a vendor, they send an inquiry with all preference details.

Vendor receives:
- Match alert
- Inquiry details
- Option to accept or decline

### 3.5 Related Recommendations
Customer can also see other commonly searched service providers for the same event type.

## 4. Inquiry Outcome and Booking Flow
### 4.1 Vendor Accepts
- Customer is notified of successful match.
- Messaging thread opens for customer and vendor.
- Vendor and customer discuss details.
- If agreed, vendor adds booking to availability calendar.

### 4.2 Vendor Declines
- Customer is notified.
- System provides new vendor options.

### 4.3 Calendar Availability Logic
- Vendor can block unavailable dates.
- Blocked dates are excluded from matching.
- Vendors can opt in for same-day/last-minute service matching.

## 5. Packages Rules by Plan
### Pro Plan
- Max 3 service packages
- After publish: cannot edit
- Can delete after publish

### Business Pro Plan
- Max 6 service packages
- Can edit after publish
- Can delete after publish

## 6. Portfolio Rules by Plan
### Pro Plan
- Up to 12 photos
- Social links for additional work/info

### Business Pro Plan
- Up to 20 photos
- Social links for additional work/info

## 7. Booking Display
- Confirmed bookings should be visible in vendor availability calendar.

## 8. Settings and Account Management
### Vendor Settings
Vendor can:
- Manage account
- Configure preferences
- Configure work conditions
- Access support

### Customer Settings
Customer can:
- Edit profile
- Become a vendor
- Access support

## 9. Vendor Discovery (Customer Side)
Customer can:
- Search for vendors
- Open vendor public profile page

## 10. Subscription and Billing
Vendors pay monthly to continue receiving matches and full app access.

### Pro Plan Pricing
- USD 15/month
- UGX 54,750

### Business Pro Pricing
- USD 30/month
- UGX 109,500

### Plan Entitlements
Pro:
- 3 service packages
- Calendar access
- Limited recommendations and matches

Business Pro:
- 6 service packages
- Unlimited calendar rights (add bookings)
- Top recommendation priority in matches

### Trial Rule
- Every new vendor starts on a free Pro plan for 1 month.

## 11. Verification Rules
Vendor can receive a verification checkmark by:
- Submitting business/registration documents
- Maintaining sustained high rating performance (4-5 stars over time)

Verification badge appears as a small checkmark on vendor profile/name.

## 12. Reviews
- Only customers who matched with a vendor can rate after event completion.

## 13. Reporting and Safety
- Customers can report vendors.
- Vendors can report customers.
- Reporting should route to platform review/moderation.

## 14. Support
- Support access must be available in settings for both customers and vendors.

## 15. Functional Summary (MVP Checklist)
- AI matching from customer event request
- 3-5 vendor result set minimum
- Vendor profile with portfolio, social links, packages, reviews
- Inquiry flow (accept/decline)
- Match notifications
- In-app messaging
- Vendor availability calendar with block/book actions
- Plan-based package and portfolio limits
- Subscription billing and plan gating
- Verification badge logic
- Ratings and reporting
- Customer and vendor settings

## 16. Technical Architecture (From Product Notes)
### Front End
- Flutter (mobile)
- Next.js + TypeScript (web)

### Backend
- Node.js + Express

### Hosting/Cloud
- AWS Lambda (backend compute)
- API Gateway (API endpoints)
- DynamoDB (database)
- Cognito (authentication)
- S3 (image storage)
- SNS (notifications)
- CloudWatch (errors and performance)

## 17. Open Clarifications Needed
- Exact definition of "limited recommendations and matched" on Pro plan (daily/monthly caps).
- Exact criteria/time window for rating-based verification.
- Whether package edit restrictions apply only after publish or also in draft state.
- Whether same-day opt-in is a paid feature or available to all vendors.
- Whether customer can choose package directly at inquiry time or during chat/booking stage.

## 18. Implementation Blueprint (Follow Existing App Patterns)
This section translates product flow into implementation tasks using the same patterns already present in the app.

### 18.1 Architecture Pattern to Follow
- Use feature-first modules under `lib/features/...`.
- Keep `presentation`, `data`, and `models` separated.
- Use Riverpod providers/controllers for state and async actions.
- Keep backend/network calls behind repository classes.
- Keep UI constants in theme files and avoid hardcoding duplicate colors across screens.

### 18.2 Folder Pattern (Recommended)
- `lib/features/matching/presentation/`
- `lib/features/matching/data/`
- `lib/features/matching/models/`
- `lib/features/inquiries/presentation/`
- `lib/features/inquiries/data/`
- `lib/features/inquiries/models/`
- `lib/features/bookings/presentation/`
- `lib/features/bookings/data/`
- `lib/features/bookings/models/`
- `lib/features/subscriptions/presentation/`
- `lib/features/subscriptions/data/`
- `lib/features/subscriptions/models/`

## 19. Screen-to-Flow Mapping
### 19.1 Customer App Screens
- Event request form screen
: collects event type, services, location, date, budget, optional guest/time, and detailed prompt.
- Match results screen
: lists 3-5+ vendors returned by ranking.
- Vendor public profile screen
: overview, portfolio, social links, packages, reviews, verification badge.
- Inquiry confirmation screen
: summary before submit.
- Inquiry status screen
: pending, accepted, declined, rematched.
- Messaging screen
: opens after vendor accepts.
- Customer settings screen
: profile edit, become vendor, support, reports.

### 19.2 Vendor App Screens
- Vendor leads/matches screen
: incoming inquiries with accept/decline actions.
- Vendor availability calendar screen
: add booking, block day, same-day opt-in.
- Vendor packages screen
: enforce plan package limits and edit/delete rules.
- Vendor portfolio manager
: enforce plan photo limits.
- Vendor profile/settings screen
: account, work preferences, support, verification status.

## 20. Business Rules to Enforce in Code
### 20.1 Matching Rules
- Return minimum 3 vendors where possible.
- Exclude vendors blocked/unavailable for request date.
- Filter by budget compatibility.
- Rank by relevance score (service fit, date fit, budget fit, response quality).

### 20.2 Plan Gating Rules
- Pro: max 3 packages, max 12 photos.
- Business Pro: max 6 packages, max 20 photos.
- Pro published package: no edits, delete allowed.
- Business Pro published package: edit and delete allowed.

### 20.3 Review and Verification Rules
- Only matched and completed events can create ratings.
- Verification badge if docs approved or rating consistency threshold met.

## 21. API Contract Draft (Node/Express + AWS)
### 21.1 Matching and Discovery
- `POST /v1/matches/search`
- `GET /v1/vendors/:vendorId/public-profile`
- `GET /v1/vendors/:vendorId/reviews`

### 21.2 Inquiry Lifecycle
- `POST /v1/inquiries`
- `GET /v1/inquiries/:id`
- `POST /v1/inquiries/:id/accept`
- `POST /v1/inquiries/:id/decline`

### 21.3 Calendar and Bookings
- `GET /v1/vendors/:vendorId/calendar`
- `POST /v1/vendors/:vendorId/calendar/block-day`
- `POST /v1/vendors/:vendorId/bookings`

### 21.4 Packages and Portfolio
- `GET /v1/vendors/:vendorId/packages`
- `POST /v1/vendors/:vendorId/packages`
- `PATCH /v1/vendors/:vendorId/packages/:packageId`
- `DELETE /v1/vendors/:vendorId/packages/:packageId`
- `POST /v1/vendors/:vendorId/portfolio`
- `DELETE /v1/vendors/:vendorId/portfolio/:assetId`

### 21.5 Subscription and Verification
- `GET /v1/subscriptions/current`
- `POST /v1/subscriptions/checkout`
- `POST /v1/vendors/:vendorId/verification/documents`
- `GET /v1/vendors/:vendorId/verification/status`

## 22. Data Model Draft (DynamoDB High Level)
- `users`
: `userId`, `role`, `plan`, `profile`, `createdAt`.
- `vendors`
: `vendorId`, `businessOverview`, `services`, `socialLinks`, `verificationStatus`, `ratingStats`.
- `matchRequests`
: customer request payload and AI prompt fields.
- `matchResults`
: `requestId`, ranked `vendorIds`, `scores`.
- `inquiries`
: `inquiryId`, `requestId`, `customerId`, `vendorId`, `status`, `createdAt`.
- `bookings`
: `bookingId`, `vendorId`, `customerId`, `eventDate`, `status`.
- `vendorCalendarBlocks`
: `vendorId`, blocked date entries.
- `packages`
: package details with publish/edit constraints.
- `portfolioAssets`
: media metadata and S3 URLs.
- `reviews`
: rating entries linked to completed inquiry/booking.
- `reports`
: user and vendor reports with moderation state.

## 23. Delivery Phases
### Phase 1 (Core MVP)
- Event request form
- Match search and results
- Vendor profile public view
- Inquiry submit and accept/decline
- Messaging open on accept

### Phase 2 (Operations)
- Vendor calendar booking/block day
- Package management with plan gating
- Portfolio management with plan gating
- Subscription checks and trial handling

### Phase 3 (Trust and Scale)
- Verification workflow
- Reviews after event completion
- Reporting and support center
- Same-day request opt-in

## 24. Definition of Done (Per Feature)
- UI implemented and responsive for mobile widths.
- Riverpod state handling with loading/error/empty states.
- Repository and API integration complete.
- Plan limits enforced on client and backend.
- Logs/metrics visible in CloudWatch for backend flow.
- Feature documented in this file with any rule changes.
