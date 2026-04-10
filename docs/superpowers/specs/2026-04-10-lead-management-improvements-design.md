# Lead Management Improvements — Design Spec

**Date:** 2026-04-10
**Scope:** Vendor lead management — bug fix + UI improvements

---

## 1. Bug Fix: Booked Tab Not Showing Bookings

**Problem:** `leads_improved.dart:134` filters the "Active Bookings" tab with `l.isAccepted`, but `confirmBooking()` in `shared_lead_state.dart` sets `status: 'booked'` without setting `isAccepted: true`. Bookings from the API also come with `status: 'CONFIRMED'` and set `isAccepted: true`, but locally converted ones slip through.

**Fix:**
- In `leads_improved.dart`, change the segment 1 filter to: `l.isAccepted || l.status == 'booked' || l.status == 'confirmed'`
- In `shared_lead_state.dart` `confirmBooking()`, also set `isAccepted: true` when updating local state after a successful booking.
- Segment 0 (New Leads) inverse: `!l.isAccepted && l.status != 'booked' && l.status != 'confirmed'`

**Files:** `leads_improved.dart`, `shared_lead_state.dart`

---

## 2. Convert to Booking Form — UI Polish

**Current:** Basic bottom sheet at `lead_details_bottom_sheet.dart:834-1009` with stock date picker, two text fields, plain button.

**Redesign (same bottom sheet, better UX):**

- **Client summary card** at the top: avatar (40px circle), client name, event type chip — gives context to what the vendor is booking.
- **Date field:** Tappable container with calendar icon, opens Material `showDatePicker` themed with app colors. Shows formatted date (`Mon, 15 Apr 2026`) instead of `15/4/2026`.
- **Time field (new):** Tappable container with clock icon, opens Material `showTimePicker`. Pre-filled with lead's existing time if available.
- **Price field:** Material `TextField` with `OutlineInputBorder`, rounded corners (12px), prefix text "USh", proper number keyboard.
- **Notes field:** Same styling, 3 lines max, hint text.
- **Confirm button:** Full-width, green gradient matching existing button style, loading spinner on tap, disabled until date is selected.
- **Form validation:** Date required — show inline error text if user taps confirm without selecting. Use `AppToast` for errors instead of `SnackBar`.
- **Theme:** Use `AppColors`, `GoogleFonts.outfit`, dark/light mode via `isDark`, rounded corners (16px cards, 12px inputs).

**File:** `lead_details_bottom_sheet.dart` (modify `_showConfirmBookingSheet`)

---

## 3. Booking Details Bottom Sheet

**New widget** shown when tapping a booking card in the "Active Bookings" tab (instead of navigating to `ActiveBookingDetailsScreen`).

**Layout:**
- Backdrop blur + rounded top corners (40px) — matching `LeadDetailsBottomSheet`
- Drag handle
- **Header section:** Client avatar (48px), name, event type chip, green "Booked" status badge
- **Stats row:** 3 compact stat cards — Date, Guests, Budget (reuse pattern from `LeadDetailsBottomSheet._buildStatsRow`)
- **Event details card:** Date & time row, venue row (icon + label + value pattern from existing `_buildDetailRow`)
- **Notes section:** If booking has notes/client message, show in a subtle card
- **Action bar:** Two buttons — "Message Client" (secondary) + "View Full Details" (primary, navigates to `ActiveBookingDetailsScreen`)

**File:** New widget `lib/features/vendors_screen/widgets/booking_details_bottom_sheet.dart`
**Integration:** `leads_improved.dart` — change `_buildActiveBookingCard` onTap to show this bottom sheet instead of pushing to full-screen route.

---

## Files Changed

| File | Change |
|------|--------|
| `lib/features/shared/providers/shared_lead_state.dart` | Fix `confirmBooking` to set `isAccepted: true` |
| `lib/features/vendors_screen/leads_improved.dart` | Fix segment filter; wire booking bottom sheet |
| `lib/features/vendors_screen/widgets/lead_details_bottom_sheet.dart` | Redesign `_showConfirmBookingSheet` |
| `lib/features/vendors_screen/widgets/booking_details_bottom_sheet.dart` | New booking details bottom sheet |

## Design Constraints

- Material Design components (DatePicker, TimePicker, TextField with OutlineInputBorder)
- App global theme: `AppColors`, `GoogleFonts.outfit`, dark/light via `isDark`
- No payment handling — this app only handles payments for plan upgrades
- Match existing bottom sheet patterns (blur backdrop, drag handle, rounded corners)
