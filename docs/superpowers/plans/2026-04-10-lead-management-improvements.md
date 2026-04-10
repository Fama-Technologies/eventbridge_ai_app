# Lead Management Improvements — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Fix the booked tab filter bug, polish the convert-to-booking form, and add a booking details bottom sheet.

**Architecture:** Three independent changes touching the vendor lead management flow. Bug fix in state/filter logic, form redesign in the existing bottom sheet, and a new bottom sheet widget for booking details. All use the app's existing theme system (AppColors, design_tokens, GoogleFonts.outfit).

**Tech Stack:** Flutter/Dart, Riverpod, Material Design, GoogleFonts, flutter_animate

---

### Task 1: Fix Booked Tab Filter Bug

**Files:**
- Modify: `lib/features/shared/providers/shared_lead_state.dart:187` (confirmBooking local state update)
- Modify: `lib/features/vendors_screen/leads_improved.dart:133-135` (segment filter logic)

- [ ] **Step 1: Fix `confirmBooking` in shared_lead_state.dart to set `isAccepted: true`**

In `lib/features/shared/providers/shared_lead_state.dart`, find line 187:

```dart
// BEFORE:
if (l.id == leadId) return l.copyWith(status: 'booked');

// AFTER:
if (l.id == leadId) return l.copyWith(status: 'booked', isAccepted: true);
```

- [ ] **Step 2: Fix segment filter in leads_improved.dart**

In `lib/features/vendors_screen/leads_improved.dart`, find lines 133-135:

```dart
// BEFORE:
var filteredLeads = allLeads
    .where((l) => _selectedSegment == 0 ? !l.isAccepted : l.isAccepted)
    .toList();

// AFTER:
var filteredLeads = allLeads.where((l) {
  final isBooked = l.isAccepted ||
      l.status == 'booked' ||
      l.status == 'confirmed' ||
      l.status == 'CONFIRMED';
  return _selectedSegment == 0 ? !isBooked : isBooked;
}).toList();
```

- [ ] **Step 3: Verify the fix compiles**

Run: `cd /home/robotics1025/projects/eventbridge_ai_app && flutter analyze lib/features/shared/providers/shared_lead_state.dart lib/features/vendors_screen/leads_improved.dart`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/shared/providers/shared_lead_state.dart lib/features/vendors_screen/leads_improved.dart
git commit -m "fix(leads): booked tab now shows confirmed bookings

The segment filter only checked isAccepted, missing leads with
status 'booked' set by confirmBooking(). Also set isAccepted=true
in local state after booking creation."
```

---

### Task 2: Redesign Convert to Booking Form

**Files:**
- Modify: `lib/features/vendors_screen/widgets/lead_details_bottom_sheet.dart` (replace `_showConfirmBookingSheet`, `_buildFieldLabel`, `_inputDecoration`)

- [ ] **Step 1: Replace `_showConfirmBookingSheet` method**

In `lib/features/vendors_screen/widgets/lead_details_bottom_sheet.dart`, replace the entire `_showConfirmBookingSheet` method (lines 834-1009) with:

```dart
void _showConfirmBookingSheet(Lead lead, bool isDark) {
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  final priceCtrl = TextEditingController(
    text: lead.budget > 0 ? lead.budget.toStringAsFixed(0) : '',
  );
  final notesCtrl = TextEditingController();
  bool isSubmitting = false;

  // Try to parse the lead's existing time
  if (lead.time.isNotEmpty && lead.time != 'TBD') {
    final parts = lead.time.split(':');
    if (parts.length >= 2) {
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1].replaceAll(RegExp(r'[^0-9]'), ''));
      if (h != null && m != null) {
        selectedTime = TimeOfDay(hour: h, minute: m);
      }
    }
  }

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkNeutral01 : Colors.white,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(32),
          ),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          MediaQuery.of(ctx).viewInsets.bottom + 32,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Convert to Booking',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF1A1A24),
                ),
              ),
              const SizedBox(height: 20),

              // Client summary card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.06),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundImage: NetworkImage(lead.clientImageUrl),
                      backgroundColor: isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : Colors.black.withValues(alpha: 0.05),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lead.clientName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1A1A24),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  AppColors.primary01.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              lead.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary01,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Event Date field
              _buildFieldLabel('Event Date *', isDark),
              GestureDetector(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: selectedDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.fromSeed(
                          seedColor: AppColors.primary01,
                          brightness: isDark
                              ? Brightness.dark
                              : Brightness.light,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setSheetState(() => selectedDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              AppColors.primary01.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                          color: AppColors.primary01,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          selectedDate == null
                              ? 'Select event date'
                              : _formatDate(selectedDate!),
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: selectedDate == null
                                ? (isDark
                                    ? Colors.white38
                                    : Colors.black38)
                                : (isDark
                                    ? Colors.white
                                    : const Color(0xFF1A1A24)),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: isDark ? Colors.white24 : Colors.black26,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Event Time field
              _buildFieldLabel('Event Time', isDark),
              GestureDetector(
                onTap: () async {
                  final picked = await showTimePicker(
                    context: ctx,
                    initialTime: selectedTime ?? TimeOfDay.now(),
                    builder: (context, child) => Theme(
                      data: Theme.of(context).copyWith(
                        colorScheme: ColorScheme.fromSeed(
                          seedColor: AppColors.primary01,
                          brightness: isDark
                              ? Brightness.dark
                              : Brightness.light,
                        ),
                      ),
                      child: child!,
                    ),
                  );
                  if (picked != null) {
                    setSheetState(() => selectedTime = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color:
                              AppColors.primary01.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.access_time_rounded,
                          size: 18,
                          color: AppColors.primary01,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          selectedTime == null
                              ? 'Select event time'
                              : selectedTime!.format(ctx),
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: selectedTime == null
                                ? (isDark
                                    ? Colors.white38
                                    : Colors.black38)
                                : (isDark
                                    ? Colors.white
                                    : const Color(0xFF1A1A24)),
                          ),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: isDark ? Colors.white24 : Colors.black26,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Price field
              _buildFieldLabel('Agreed Price (Optional)', isDark),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF1A1A24),
                ),
                decoration: InputDecoration(
                  hintText: 'Enter agreed price',
                  hintStyle: GoogleFonts.outfit(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  prefixText: 'USh  ',
                  prefixStyle: GoogleFonts.outfit(
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary01,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.primary01,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Notes field
              _buildFieldLabel('Notes (Optional)', isDark),
              TextField(
                controller: notesCtrl,
                maxLines: 3,
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : const Color(0xFF1A1A24),
                ),
                decoration: InputDecoration(
                  hintText: 'Any extra details for this booking...',
                  hintStyle: GoogleFonts.outfit(
                    color: isDark ? Colors.white38 : Colors.black38,
                  ),
                  filled: true,
                  fillColor: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : const Color(0xFFF9FAFB),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.08),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: AppColors.primary01,
                      width: 1.5,
                    ),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 16,
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Confirm button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (selectedDate == null) {
                            AppToast.show(
                              context,
                              message: 'Please select a date for the booking',
                              type: ToastType.error,
                            );
                            return;
                          }
                          setSheetState(() => isSubmitting = true);
                          final success = await ref
                              .read(sharedLeadStateProvider.notifier)
                              .confirmBooking(
                                leadId: lead.id,
                                bookingDate: selectedDate!,
                                clientName: lead.clientName,
                                eventType: lead.title,
                                price: double.tryParse(priceCtrl.text),
                                notes: notesCtrl.text,
                              );
                          if (!ctx.mounted || !mounted) return;
                          if (success) {
                            ctx.pop();
                            context.pop();
                            AppToast.show(
                              context,
                              message: 'Booking confirmed!',
                              type: ToastType.success,
                            );
                          } else {
                            setSheetState(() => isSubmitting = false);
                            AppToast.show(
                              context,
                              message: 'Failed to create booking. Try again.',
                              type: ToastType.error,
                            );
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    disabledBackgroundColor:
                        const Color(0xFF10B981).withValues(alpha: 0.5),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Confirm Booking',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

String _formatDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
}
```

- [ ] **Step 2: Verify it compiles**

Run: `cd /home/robotics1025/projects/eventbridge_ai_app && flutter analyze lib/features/vendors_screen/widgets/lead_details_bottom_sheet.dart`
Expected: No errors.

- [ ] **Step 3: Commit**

```bash
git add lib/features/vendors_screen/widgets/lead_details_bottom_sheet.dart
git commit -m "feat(leads): redesign convert-to-booking form

Adds client summary card, themed Material date/time pickers,
styled text fields with OutlineInputBorder, loading state on
submit, and AppToast for validation errors."
```

---

### Task 3: Create Booking Details Bottom Sheet

**Files:**
- Create: `lib/features/vendors_screen/widgets/booking_details_bottom_sheet.dart`
- Modify: `lib/features/vendors_screen/leads_improved.dart` (wire up the new bottom sheet)

- [ ] **Step 1: Create `booking_details_bottom_sheet.dart`**

Create `lib/features/vendors_screen/widgets/booking_details_bottom_sheet.dart`:

```dart
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/core/storage/storage_service.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge/features/vendors_screen/models/lead_model.dart';
import 'package:flutter_animate/flutter_animate.dart';

class BookingDetailsBottomSheet extends StatelessWidget {
  final Lead booking;

  const BookingDetailsBottomSheet({super.key, required this.booking});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.backgroundDark.withValues(alpha: 0.95)
              : Colors.white.withValues(alpha: 0.98),
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(40)),
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.6)
                  : Colors.black.withValues(alpha: 0.12),
              blurRadius: 40,
              spreadRadius: 12,
              offset: const Offset(0, -8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(isDark),
                    const SizedBox(height: 24),
                    _buildStatsRow(isDark),
                    const SizedBox(height: 24),
                    _buildEventDetails(isDark),
                    if (booking.clientMessage.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildNotes(isDark),
                    ],
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),

            // Action bar
            _buildActionBar(context, isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkNeutral02.withValues(alpha: 0.5)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundImage: NetworkImage(booking.clientImageUrl),
            backgroundColor: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.05),
          ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.clientName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1A1A24),
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color:
                            AppColors.primary01.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        booking.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary01,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.check_circle_rounded,
                            color: Color(0xFF10B981),
                            size: 12,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Booked',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF10B981),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(bool isDark) {
    return Row(
      children: [
        _buildStatCard(
          label: 'Date',
          value: booking.date,
          icon: Icons.event_available_rounded,
          isDark: isDark,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          label: 'Guests',
          value: '${booking.guests}',
          icon: Icons.people_outline_rounded,
          isDark: isDark,
        ),
        const SizedBox(width: 12),
        _buildStatCard(
          label: 'Budget',
          value: 'USh ${booking.budget.toInt()}',
          icon: Icons.payments_outlined,
          isDark: isDark,
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.darkNeutral02.withValues(alpha: 0.4)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
              size: 18,
            ),
            const SizedBox(height: 8),
            Text(
              value,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A1A24),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? Colors.white.withValues(alpha: 0.5)
                    : const Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventDetails(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkNeutral02.withValues(alpha: 0.5)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.04),
        ),
      ),
      child: Column(
        children: [
          _buildDetailRow(
            icon: Icons.calendar_today_rounded,
            label: 'Date & Time',
            value: '${booking.date} • ${booking.time}',
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _buildDetailRow(
            icon: Icons.location_on_rounded,
            label: 'Venue',
            value: booking.venueName.isNotEmpty
                ? booking.venueName
                : booking.location,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary01.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.primary01.withValues(alpha: 0.2),
            ),
          ),
          child: Icon(icon, color: AppColors.primary01, size: 18),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.5)
                      : const Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1A1A24),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildNotes(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Notes',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1A1A24),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.04)
                : AppColors.primary01.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : AppColors.primary01.withValues(alpha: 0.12),
            ),
          ),
          child: Text(
            booking.clientMessage,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.85)
                  : const Color(0xFF1F2937),
              height: 1.6,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionBar(BuildContext context, bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkNeutral01 : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                final customerId = booking.customerId?.trim() ?? '';
                final vendorId =
                    StorageService().getString('user_id') ?? '';
                if (vendorId.isEmpty || customerId.isEmpty) return;

                final lookupKey = '${customerId}_$vendorId';
                context.pop();
                context.push(
                  '/vendor-chat/$lookupKey'
                  '?phone=${Uri.encodeComponent(booking.phoneNumber ?? '')}'
                  '&leadTitle=${Uri.encodeComponent(booking.title)}'
                  '&leadDate=${Uri.encodeComponent(booking.date)}'
                  '&otherUserName=${Uri.encodeComponent(booking.clientName)}'
                  '&customerId=$customerId',
                );
              },
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 18,
                        color: isDark ? Colors.white70 : Colors.black54,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Message',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color:
                              isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 2,
            child: GestureDetector(
              onTap: () {
                context.pop();
                context.push(
                  '/active-booking-details/${booking.id}',
                );
              },
              child: Container(
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary01,
                      AppColors.primary01.withValues(alpha: 0.85),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color:
                          AppColors.primary01.withValues(alpha: 0.35),
                      blurRadius: 16,
                      spreadRadius: 2,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    'View Full Details',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 2: Wire the bottom sheet into `leads_improved.dart`**

In `lib/features/vendors_screen/leads_improved.dart`, add the import at the top (after the existing imports):

```dart
import 'package:eventbridge/features/vendors_screen/widgets/booking_details_bottom_sheet.dart';
```

Then in `_buildActiveBookingCard`, change the `onTap` on the `InkWell` (line 545):

```dart
// BEFORE:
onTap: () => context.push('/active-booking-details/${lead.id}'),

// AFTER:
onTap: () {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => BookingDetailsBottomSheet(booking: lead),
  );
},
```

- [ ] **Step 3: Verify it compiles**

Run: `cd /home/robotics1025/projects/eventbridge_ai_app && flutter analyze lib/features/vendors_screen/widgets/booking_details_bottom_sheet.dart lib/features/vendors_screen/leads_improved.dart`
Expected: No errors.

- [ ] **Step 4: Commit**

```bash
git add lib/features/vendors_screen/widgets/booking_details_bottom_sheet.dart lib/features/vendors_screen/leads_improved.dart
git commit -m "feat(leads): add booking details bottom sheet

Shows client info, event stats, venue details, and notes in a
blur-backdrop bottom sheet matching the lead details pattern.
Actions: Message Client + View Full Details."
```
