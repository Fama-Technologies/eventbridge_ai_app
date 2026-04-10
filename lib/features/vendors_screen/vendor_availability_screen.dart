import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/core/network/api_service.dart';
import 'package:eventbridge/core/storage/storage_service.dart';
import 'package:eventbridge/core/widgets/app_toast.dart';
import 'package:eventbridge/core/services/notification_service.dart';

// ─── Local Booking Model ─────────────────────────────────────────────────────
class _BookingData {
  final int id;
  final String status;
  final DateTime bookingDate;
  final double totalPrice;
  final String? notes;
  final String? eventType;
  final String clientName;

  const _BookingData({
    required this.id,
    required this.status,
    required this.bookingDate,
    required this.totalPrice,
    this.notes,
    this.eventType,
    this.clientName = 'Unknown Client',
  });

  factory _BookingData.fromMap(Map<String, dynamic> m) => _BookingData(
    id: m['id'] is int ? m['id'] : int.tryParse(m['id'].toString()) ?? 0,
    status: m['status'] ?? 'pending',
    bookingDate: m['bookingDate'] != null
        ? DateTime.parse(m['bookingDate'].toString())
        : DateTime.now(),
    totalPrice: double.tryParse(m['totalPrice']?.toString() ?? '') ?? 0.0,
    notes: m['notes'],
    eventType: m['eventType'],
    clientName: m['clientName'] ?? 'Unknown Client',
  );
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class VendorAvailabilityScreen extends StatefulWidget {
  const VendorAvailabilityScreen({super.key});

  @override
  State<VendorAvailabilityScreen> createState() =>
      _VendorAvailabilityScreenState();
}

class _VendorAvailabilityScreenState extends State<VendorAvailabilityScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  // Range selection disabled per requirements

  final Set<DateTime> _blockedDates = {};
  List<_BookingData> _bookings = [];
  bool _sameDayAvailable = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ─── Data Layer ─────────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userId = StorageService().getString('user_id');
      if (userId == null) return;

      final results = await Future.wait([
        ApiService.instance.getVendorAvailability(userId),
        ApiService.instance.getVendorBookings(userId),
      ]);

      final availResp = results[0];
      final bookResp = results[1];

      setState(() {
        if (availResp['success'] == true) {
          _sameDayAvailable = availResp['sameDayService'] ?? false;
          final rawBlocked = availResp['blockedDates'];
          _blockedDates.clear();
          if (rawBlocked is List) {
            for (var d in rawBlocked) {
              if (d is String) _blockedDates.add(DateTime.parse(d));
            }
          }
        }
        if (bookResp['success'] == true || bookResp['bookings'] != null) {
          final List raw = bookResp['bookings'] is List
              ? bookResp['bookings']
              : [];
          _bookings = raw
              .map((e) {
                try {
                  return _BookingData.fromMap(Map<String, dynamic>.from(e));
                } catch (err) {
                  return null;
                }
              })
              .whereType<_BookingData>()
              .toList();
        }
      });

      // Schedule 3-day-ahead reminders (5× per day) for upcoming bookings
      final bookingDates = _bookings.map((b) => b.bookingDate).toList();
      NotificationService()
          .scheduleBookingReminders(bookingDates)
          .catchError((e) => debugPrint('Failed to schedule reminders: $e'));
    } catch (e) {
      if (mounted)
        AppToast.show(
          context,
          message: 'Failed to load data: $e',
          type: ToastType.error,
        );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAvailability() async {
    try {
      final userId = StorageService().getString('user_id');
      if (userId == null) return;
      await ApiService.instance.saveVendorAvailability(
        userId: userId,
        blockedDates: _blockedDates.map((d) => d.toIso8601String()).toList(),
        sameDayService: _sameDayAvailable,
      );
      if (mounted)
        AppToast.show(
          context,
          message: 'Availability updated!',
          type: ToastType.success,
        );
    } catch (e) {
      if (mounted)
        AppToast.show(
          context,
          message: 'Failed to save: $e',
          type: ToastType.error,
        );
    }
  }

  // ─── Helpers ────────────────────────────────────────────────────────────────

  bool isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isBooked(DateTime day) =>
      _bookings.any((b) => isSameDay(b.bookingDate, day));
  bool _isBlocked(DateTime day) => _blockedDates.any((d) => isSameDay(d, day));

  List<_BookingData> _bookingsForDay(DateTime day) =>
      _bookings.where((b) => isSameDay(b.bookingDate, day)).toList();

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return const Color(0xFF22C55E);
      case 'cancelled':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final today = DateTime(
      DateTime.now().year,
      DateTime.now().month,
      DateTime.now().day,
    );
    // Include bookings from the last 7 days + all future bookings
    final displayThreshold = today.subtract(const Duration(days: 7));
    final displayBookings =
        _bookings
            .where((b) => !b.bookingDate.isBefore(displayThreshold))
            .toList()
          ..sort((a, b) => a.bookingDate.compareTo(b.bookingDate));

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : const Color(0xFFF8FAFC),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildHeader(isDark),
                SliverToBoxAdapter(child: _buildCalendar(isDark)),
                SliverToBoxAdapter(child: _buildSameDayToggle(isDark)),
                SliverToBoxAdapter(child: _buildLegend(isDark)),
                SliverToBoxAdapter(
                  child: _buildUpcomingHeader(isDark, displayBookings.length),
                ),
                if (displayBookings.isEmpty)
                  SliverToBoxAdapter(child: _buildEmptyBookings(isDark))
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, i) =>
                            _buildBookingCard(displayBookings[i], isDark, i),
                        childCount: displayBookings.length,
                      ),
                    ),
                  ),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddBookingSheet(context, isDark),
        backgroundColor: AppColors.primary01,
        elevation: 8,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          'Add Booking',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ).animate().scale(delay: 400.ms, curve: Curves.easeOutBack),
    );
  }

  // ─── Header ─────────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isDark) {
    return SliverAppBar(
      expandedHeight: 160,
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      elevation: 0,
      pinned: true,
      stretch: true,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: isDark ? Colors.white : const Color(0xFF1A1A24),
          size: 20,
        ),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.backgroundDark, AppColors.darkNeutral01],
                  )
                : const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, Color(0xFFF8FAFC)],
                  ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -40,
                right: -30,
                child: Container(
                  width: 160,
                  height: 160,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary01.withValues(alpha: 0.06),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Availability',
                      style: GoogleFonts.outfit(
                        fontSize: 36,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF1A1A24),
                        letterSpacing: -1,
                      ),
                    ).animate().fadeIn().slideX(begin: -0.1, end: 0),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary01.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_bookings.length} Bookings',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary01,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '${_blockedDates.length} Blocked',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: isDark ? Colors.white38 : Colors.black38,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 150.ms),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Calendar ────────────────────────────────────────────────────────────────

  Widget _buildCalendar(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkNeutral01 : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: TableCalendar(
          firstDay: DateTime.utc(2024, 1, 1),
          lastDay: DateTime.utc(2030, 12, 31),
          focusedDay: _focusedDay,
          selectedDayPredicate: (day) =>
              _selectedDay != null && isSameDay(_selectedDay!, day),
          rangeSelectionMode: RangeSelectionMode.disabled,
          onDaySelected: (selectedDay, focusedDay) {
            setState(() {
              _selectedDay = selectedDay;
              _focusedDay = focusedDay;
            });
            _showDateOptionsSheet(selectedDay);
          },
          calendarFormat: CalendarFormat.month,
          headerStyle: HeaderStyle(
            formatButtonVisible: false,
            titleCentered: true,
            titleTextStyle: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1A1A24),
              letterSpacing: -0.5,
            ),
            leftChevronIcon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chevron_left_rounded,
                color: isDark ? Colors.white70 : const Color(0xFF1A1A24),
                size: 20,
              ),
            ),
            rightChevronIcon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.03),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.chevron_right_rounded,
                color: isDark ? Colors.white70 : const Color(0xFF1A1A24),
                size: 20,
              ),
            ),
            headerPadding: const EdgeInsets.fromLTRB(0, 20, 0, 20),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkNeutral01 : Colors.white,
            ),
          ),
          daysOfWeekStyle: DaysOfWeekStyle(
            weekdayStyle: GoogleFonts.outfit(
              color: isDark ? Colors.white38 : Colors.black38,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            weekendStyle: GoogleFonts.outfit(
              color: AppColors.primary01.withValues(alpha: 0.5),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          calendarStyle: CalendarStyle(
            outsideDaysVisible: false,
            defaultTextStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : const Color(0xFF1A1A24),
            ),
            weekendTextStyle: GoogleFonts.outfit(
              fontWeight: FontWeight.w600,
              color: AppColors.primary01.withValues(alpha: 0.8),
            ),
            rangeStartDecoration: BoxDecoration(
              color: AppColors.primary01,
              shape: BoxShape.circle,
            ),
            rangeEndDecoration: BoxDecoration(
              color: AppColors.primary01,
              shape: BoxShape.circle,
            ),
            rangeHighlightColor: AppColors.primary01.withValues(alpha: 0.12),
            withinRangeTextStyle: GoogleFonts.outfit(
              color: AppColors.primary01,
              fontWeight: FontWeight.bold,
            ),
          ),
          calendarBuilders: CalendarBuilders(
            defaultBuilder: (context, day, focusedDay) =>
                _statusCell(day, isDark, isDefault: true),
            selectedBuilder: (context, day, focusedDay) =>
                _statusCell(day, isDark, isSelected: true),
            todayBuilder: (context, day, _) =>
                _statusCell(day, isDark, isToday: true),
            rangeStartBuilder: (context, day, focusedDay) =>
                _statusCell(day, isDark, isRangeStart: true),
            rangeEndBuilder: (context, day, focusedDay) =>
                _statusCell(day, isDark, isRangeEnd: true),
            withinRangeBuilder: (context, day, focusedDay) =>
                _statusCell(day, isDark, isWithinRange: true),
          ),
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  Widget _statusCell(
    DateTime day,
    bool isDark, {
    bool isDefault = false,
    bool isSelected = false,
    bool isToday = false,
    bool isRangeStart = false,
    bool isRangeEnd = false,
    bool isWithinRange = false,
  }) {
    final booked = _isBooked(day);
    final blocked = _isBlocked(day);

    // Color constants
    const Color bookedColor = Color(0xFF22C55E); // Green
    const Color blockedColor = Color(0xFFEF4444); // Red
    const Color todayColor = Color(0xFFF97316); // Orange

    // Decorations
    BoxDecoration? decoration;
    Color textColor = (isDark ? Colors.white : const Color(0xFF1A1A24));

    if (isSelected || isRangeStart || isRangeEnd) {
      decoration = BoxDecoration(
        color: AppColors.primary01,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary01.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      );
      textColor = Colors.white;
    } else if (booked) {
      // ✅ Booked → Green
      decoration = BoxDecoration(
        color: bookedColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: bookedColor.withValues(alpha: 0.35),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      );
      textColor = Colors.white;
    } else if (isToday) {
      // 🟠 Today → Orange outline
      decoration = BoxDecoration(
        color: todayColor.withValues(alpha: 0.12),
        shape: BoxShape.circle,
        border: Border.all(color: todayColor, width: 2),
      );
      textColor = todayColor;
    } else if (blocked) {
      // 🔴 Blocked → Red
      decoration = BoxDecoration(
        color: blockedColor,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: blockedColor.withValues(alpha: 0.3),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      );
      textColor = Colors.white;
    }

    Widget content = Center(
      child: Text(
        '${day.day}',
        style: GoogleFonts.outfit(
          fontSize: 16,
          fontWeight:
              (booked ||
                  blocked ||
                  isToday ||
                  isSelected ||
                  isRangeStart ||
                  isRangeEnd)
              ? FontWeight.w900
              : FontWeight.w600,
          color: textColor,
        ),
      ),
    );

    // Range background
    Widget? rangeBg;
    if (isRangeStart || isRangeEnd || isWithinRange) {
      rangeBg = Positioned.fill(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.primary01.withValues(alpha: 0.12),
            borderRadius: isRangeStart
                ? const BorderRadius.horizontal(left: Radius.circular(20))
                : (isRangeEnd
                      ? const BorderRadius.horizontal(
                          right: Radius.circular(20),
                        )
                      : BorderRadius.zero),
          ),
        ),
      );
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        if (rangeBg != null) rangeBg,
        Container(
          width: 38,
          height: 38,
          decoration: decoration,
          child: content,
        ),
        if (booked &&
            (isSelected ||
                isRangeStart ||
                isRangeEnd ||
                isWithinRange ||
                isToday))
          Positioned(
            bottom: 4,
            child: Container(
              width: 4,
              height: 4,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }

  Widget _calendarCell(DateTime day, Color bg, Color textColor) {
    // Legacy - no longer used
    return Container();
  }

  Widget _rangeDateColumn(String label, DateTime date, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white24 : Colors.black26,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${_monthAbbr(date.month)} ${date.day}, ${date.year}',
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : const Color(0xFF1A1A24),
          ),
        ),
      ],
    );
  }

  // ─── Legend ──────────────────────────────────────────────────────────────────

  Widget _buildLegend(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _legendDot(const Color(0xFF22C55E), 'Booked', isDark),
          _legendDot(const Color(0xFFEF4444), 'Blocked', isDark),
          _legendDot(
            const Color(0xFFF97316).withValues(alpha: 0.15),
            'Today',
            isDark,
            border: const Color(0xFFF97316),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _legendDot(Color color, String label, bool isDark, {Color? border}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
              border: border != null
                  ? Border.all(color: border, width: 1.5)
                  : null,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white54 : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Same-Day Toggle ──────────────────────────────────────────────────────────

  Widget _buildSameDayToggle(bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkNeutral01 : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary01.withValues(alpha: 0.15),
                  AppColors.primary01.withValues(alpha: 0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.bolt_rounded,
              color: AppColors.primary01,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Last-minute Requests',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : const Color(0xFF1A1A24),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Accept same-day bookings',
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: isDark ? Colors.white38 : const Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: _sameDayAvailable,
            activeColor: AppColors.primary01,
            onChanged: (val) {
              setState(() => _sameDayAvailable = val);
              _saveAvailability();
            },
          ),
        ],
      ),
    ).animate().fadeIn(delay: 250.ms);
  }

  // ─── Upcoming Bookings ────────────────────────────────────────────────────────

  Widget _buildUpcomingHeader(bool isDark, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 12),
      child: Row(
        children: [
          Text(
            'Recent & Upcoming',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF1A1A24),
              letterSpacing: -0.5,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary01.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '$count',
              style: GoogleFonts.outfit(
                fontSize: 13,
                fontWeight: FontWeight.w800,
                color: AppColors.primary01,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms);
  }

  Widget _buildEmptyBookings(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.primary01.withValues(alpha: 0.15),
                        AppColors.primary01.withValues(alpha: 0.02),
                      ],
                    ),
                  ),
                ),
                Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primary01.withValues(alpha: 0.1),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary01.withValues(alpha: 0.1),
                            blurRadius: 20,
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.event_available_rounded,
                        color: AppColors.primary01,
                        size: 32,
                      ),
                    )
                    .animate(
                      onPlay: (controller) => controller.repeat(reverse: true),
                    )
                    .moveY(
                      begin: -5,
                      end: 5,
                      duration: 2000.ms,
                      curve: Curves.easeInOut,
                    ),
              ],
            ),
            const SizedBox(height: 24),
            Text(
              'Your Calendar is Fresh',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF1A1A24),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'No upcoming bookings scheduled yet.\nSelect dates to block them or add a new booking manually.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: isDark ? Colors.white38 : Colors.black45,
                height: 1.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildBookingCard(_BookingData booking, bool isDark, int index) {
    final statusColor = _statusColor(booking.status);
    final isPast = booking.bookingDate.isBefore(DateTime.now());

    return Container(
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkNeutral01 : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.05),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showBookingDetailSheet(booking, isDark),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      // Date Block
                      Container(
                        width: 56,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isPast
                                ? [Colors.grey.shade300, Colors.grey.shade400]
                                : [
                                    AppColors.primary01.withValues(alpha: 0.8),
                                    AppColors.primary01,
                                  ],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _monthAbbr(booking.bookingDate.month),
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white70,
                              ),
                            ),
                            Text(
                              '${booking.bookingDate.day}',
                              style: GoogleFonts.outfit(
                                fontSize: 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Info
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              booking.clientName,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF1A1A24),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              booking.eventType ?? 'Event',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: isDark ? Colors.white54 : Colors.black45,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (booking.totalPrice > 0) ...[
                              const SizedBox(height: 6),
                              Text(
                                'USh ${booking.totalPrice.toStringAsFixed(0)}',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary01,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: statusColor.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          _capitalize(booking.status),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        )
        .animate(delay: Duration(milliseconds: 300 + index * 80))
        .fadeIn()
        .slideY(begin: 0.1, end: 0);
  }

  // ─── Action Sheet: Tap a Calendar Date ───────────────────────────────────────

  void _showDateOptionsSheet(DateTime day) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final booked = _isBooked(day);
    final blocked = _isBlocked(day);
    final dayBookings = _bookingsForDay(day);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkNeutral01 : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 30,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            24 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: booked
                            ? [
                                AppColors.primary01.withValues(alpha: 0.15),
                                AppColors.primary01.withValues(alpha: 0.05),
                              ]
                            : blocked
                            ? [
                                Colors.grey.withValues(alpha: 0.1),
                                Colors.grey.withValues(alpha: 0.05),
                              ]
                            : [
                                const Color(0xFF22C55E).withValues(alpha: 0.1),
                                const Color(0xFF22C55E).withValues(alpha: 0.05),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      '${_dayName(day.weekday)}, ${_monthName(day.month)} ${day.day}',
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF1A1A24),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: booked
                          ? AppColors.primary01.withValues(alpha: 0.1)
                          : blocked
                          ? Colors.grey.withValues(alpha: 0.1)
                          : const Color(0xFF22C55E).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      booked
                          ? 'Booked'
                          : blocked
                          ? 'Blocked'
                          : 'Available',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: booked
                            ? AppColors.primary01
                            : blocked
                            ? Colors.grey
                            : const Color(0xFF22C55E),
                      ),
                    ),
                  ),
                ],
              ),
              if (dayBookings.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  'Bookings for this day',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white54 : Colors.black45,
                  ),
                ),
                const SizedBox(height: 10),
                ...dayBookings.map(
                  (b) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.04)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _statusColor(b.status).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                b.clientName,
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1A1A24),
                                ),
                              ),
                              Text(
                                b.eventType ?? 'Event',
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white38
                                      : Colors.black38,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (b.status == 'pending')
                          Row(
                            children: [
                              _sheetActionBtn(
                                Icons.close_rounded,
                                const Color(0xFFEF4444),
                                () {
                                  _updateStatus(b.id, 'cancelled');
                                  context.pop();
                                },
                              ),
                              const SizedBox(width: 8),
                              _sheetActionBtn(
                                Icons.check_rounded,
                                const Color(0xFF22C55E),
                                () {
                                  _updateStatus(b.id, 'confirmed');
                                  context.pop();
                                },
                              ),
                            ],
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: _statusColor(
                                b.status,
                              ).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _capitalize(b.status),
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: _statusColor(b.status),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 16),
              // Block/Unblock button
              if (!booked)
                _sheetPrimaryButton(
                  blocked ? 'Unblock Date' : 'Block this Date',
                  blocked ? const Color(0xFF22C55E) : const Color(0xFFEF4444),
                  blocked ? Icons.lock_open_rounded : Icons.block_rounded,
                  () {
                    setState(() {
                      if (blocked) {
                        _blockedDates.removeWhere((d) => isSameDay(d, day));
                      } else {
                        _blockedDates.add(day);
                      }
                    });
                    context.pop();
                    _saveAvailability();
                  },
                ),
              const SizedBox(height: 10),
              // Add booking button
              _sheetPrimaryButton(
                'Add Booking for This Day',
                AppColors.primary01,
                Icons.add_rounded,
                () {
                  context.pop();
                  _showAddBookingSheet(context, isDark, prefillDate: day);
                },
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _selectedDay = null;
                    });
                    context.pop();
                  },
                  child: Text(
                    'Clear Selection',
                    style: GoogleFonts.outfit(
                      color: isDark ? Colors.white38 : Colors.black38,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetActionBtn(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
    );
  }

  Widget _sheetPrimaryButton(
    String label,
    Color color,
    IconData icon,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          label,
          style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w800),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  // ─── Booking Detail Sheet ────────────────────────────────────────────────────

  void _showBookingDetailSheet(_BookingData booking, bool isDark) {
    final statusColor = _statusColor(booking.status);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkNeutral01 : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
        ),
        padding: EdgeInsets.fromLTRB(
          24,
          16,
          24,
          24 + MediaQuery.of(context).padding.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Row(
              children: [
                Expanded(
                  child: Text(
                    booking.clientName,
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF1A1A24),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _capitalize(booking.status),
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _detailRow(
              Icons.event_rounded,
              booking.eventType ?? 'Event',
              isDark,
            ),
            _detailRow(
              Icons.calendar_month_rounded,
              '${_dayName(booking.bookingDate.weekday)}, ${_monthName(booking.bookingDate.month)} ${booking.bookingDate.day}, ${booking.bookingDate.year}',
              isDark,
            ),
            if (booking.totalPrice > 0)
              _detailRow(
                Icons.payments_outlined,
                'USh ${booking.totalPrice.toStringAsFixed(0)}',
                isDark,
                highlight: true,
              ),
            if (booking.notes != null && booking.notes!.isNotEmpty)
              _detailRow(Icons.notes_rounded, booking.notes!, isDark),
            if (booking.status == 'pending') ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _updateStatus(booking.id, 'cancelled');
                        context.pop();
                      },
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: Text(
                        'Reject',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _updateStatus(booking.id, 'confirmed');
                        context.pop();
                      },
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: Text(
                        'Accept',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF22C55E),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _detailRow(
    IconData icon,
    String text,
    bool isDark, {
    bool highlight = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: highlight
                ? AppColors.primary01
                : (isDark ? Colors.white38 : Colors.black38),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
                color: highlight
                    ? AppColors.primary01
                    : (isDark ? Colors.white70 : const Color(0xFF374151)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Add Booking Sheet ────────────────────────────────────────────────────────

  void _showAddBookingSheet(
    BuildContext context,
    bool isDark, {
    DateTime? prefillDate,
  }) {
    final clientNameCtrl = TextEditingController();
    final eventTypeCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final notesCtrl = TextEditingController();
    DateTime selectedDate = prefillDate ?? DateTime.now();

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkNeutral01 : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(36),
                  ),
                ),
                padding: EdgeInsets.fromLTRB(
                  24,
                  16,
                  24,
                  24 + MediaQuery.of(ctx).padding.bottom,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Premium gradient handle and header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(0, 12, 0, 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: isDark
                                ? [
                                    AppColors.darkNeutral01,
                                    AppColors.backgroundDark,
                                  ]
                                : [Colors.white, const Color(0xFFFFF7F5)],
                          ),
                          border: Border(
                            bottom: BorderSide(
                              color: isDark
                                  ? Colors.white10
                                  : Colors.black.withValues(alpha: 0.04),
                            ),
                          ),
                        ),
                        child: Column(
                          children: [
                            Center(
                              child: Container(
                                width: 40,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white24
                                      : Colors.black12,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 24,
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          AppColors.primary01,
                                          AppColors.primary01.withValues(
                                            alpha: 0.7,
                                          ),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(
                                      Icons.add_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Add a Booking',
                                        style: GoogleFonts.outfit(
                                          fontSize: 22,
                                          fontWeight: FontWeight.w900,
                                          color: isDark
                                              ? Colors.white
                                              : const Color(0xFF1A1A24),
                                          letterSpacing: -0.5,
                                        ),
                                      ),
                                      Text(
                                        'Manually schedule a booking',
                                        style: GoogleFonts.outfit(
                                          fontSize: 13,
                                          color: isDark
                                              ? Colors.white38
                                              : Colors.black38,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Date Picker Row
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2030),
                            builder: (c, child) => Theme(
                              data: ThemeData(
                                colorScheme: ColorScheme(
                                  brightness: isDark
                                      ? Brightness.dark
                                      : Brightness.light,
                                  primary: AppColors.primary01,
                                  onPrimary: Colors.white,
                                  secondary: AppColors.primary01,
                                  onSecondary: Colors.white,
                                  error: Colors.red,
                                  onError: Colors.white,
                                  surface: isDark
                                      ? AppColors.darkNeutral01
                                      : Colors.white,
                                  onSurface: isDark
                                      ? Colors.white
                                      : Colors.black,
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null)
                            setSheetState(() => selectedDate = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primary01.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_month_rounded,
                                color: AppColors.primary01,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                '${_dayName(selectedDate.weekday)}, ${_monthName(selectedDate.month)} ${selectedDate.day}, ${selectedDate.year}',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF1A1A24),
                                ),
                              ),
                              const Spacer(),
                              Icon(
                                Icons.edit_rounded,
                                size: 16,
                                color: AppColors.primary01,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _addBookingField(
                        clientNameCtrl,
                        'Client Name',
                        'e.g. John & Mary',
                        isDark,
                        icon: Icons.person_rounded,
                      ),
                      _addBookingField(
                        eventTypeCtrl,
                        'Event Type',
                        'e.g. Wedding, Corporate',
                        isDark,
                        icon: Icons.event_rounded,
                      ),
                      _addBookingField(
                        priceCtrl,
                        'Price (USh)',
                        'e.g. 500000',
                        isDark,
                        icon: Icons.payments_outlined,
                        isNumber: true,
                      ),
                      _addBookingField(
                        notesCtrl,
                        'Notes (Optional)',
                        'Any extra details...',
                        isDark,
                        icon: Icons.notes_rounded,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final userId = StorageService().getString(
                              'user_id',
                            );
                            if (userId == null) return;
                            final priceText = priceCtrl.text.replaceAll(
                              ',',
                              '',
                            );
                            try {
                              await ApiService.instance.createVendorBooking(
                                userId: userId,
                                bookingDate: selectedDate.toIso8601String(),
                                clientName: clientNameCtrl.text.trim().isEmpty
                                    ? null
                                    : clientNameCtrl.text.trim(),
                                eventType: eventTypeCtrl.text.trim().isEmpty
                                    ? null
                                    : eventTypeCtrl.text.trim(),
                                totalPrice: double.tryParse(priceText),
                                notes: notesCtrl.text.trim().isEmpty
                                    ? null
                                    : notesCtrl.text.trim(),
                              );
                              if (ctx.mounted) ctx.pop();
                              _loadData();
                              if (mounted) {
                                AppToast.show(
                                  context,
                                  message: 'Booking added!',
                                  type: ToastType.success,
                                );
                              }
                            } catch (e) {
                              if (mounted) {
                                AppToast.show(
                                  context,
                                  message: 'Failed: $e',
                                  type: ToastType.error,
                                );
                              }
                            }
                          },
                          icon: const Icon(Icons.check_rounded, size: 20),
                          label: Text(
                            'Save Booking',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary01,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _addBookingField(
    TextEditingController ctrl,
    String label,
    String hint,
    bool isDark, {
    IconData? icon,
    int maxLines = 1,
    bool isNumber = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        style: GoogleFonts.outfit(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : const Color(0xFF1A1A24),
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon != null
              ? Icon(icon, color: AppColors.primary01, size: 20)
              : null,
          labelStyle: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white54 : Colors.black45,
          ),
          hintStyle: GoogleFonts.outfit(
            color: isDark ? Colors.white24 : Colors.black26,
          ),
          filled: true,
          fillColor: isDark
              ? Colors.white.withValues(alpha: 0.04)
              : const Color(0xFFF8FAFC),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.07),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(
              color: isDark
                  ? Colors.white10
                  : Colors.black.withValues(alpha: 0.07),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: AppColors.primary01, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  // ─── Status Update ────────────────────────────────────────────────────────────

  Future<void> _updateStatus(int bookingId, String status) async {
    try {
      await ApiService.instance.updateBookingStatus(
        bookingId: bookingId,
        status: status,
      );
      _loadData();
      if (mounted) {
        AppToast.show(
          context,
          message: status == 'confirmed'
              ? 'Booking Accepted!'
              : 'Booking Cancelled',
          type: status == 'confirmed' ? ToastType.success : ToastType.error,
        );
      }
    } catch (e) {
      if (mounted)
        AppToast.show(context, message: 'Failed: $e', type: ToastType.error);
    }
  }

  // ─── Utils ───────────────────────────────────────────────────────────────────

  String _monthAbbr(int m) => [
    '',
    'JAN',
    'FEB',
    'MAR',
    'APR',
    'MAY',
    'JUN',
    'JUL',
    'AUG',
    'SEP',
    'OCT',
    'NOV',
    'DEC',
  ][m];

  String _monthName(int m) => [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][m];

  String _dayName(int d) => [
    '',
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ][d];

  String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}
