import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:eventbridge_ai/core/theme/app_colors.dart';
import 'package:eventbridge_ai/core/network/api_service.dart';
import 'package:eventbridge_ai/core/storage/storage_service.dart';
import 'package:eventbridge_ai/core/widgets/app_toast.dart';

class VendorAvailabilityScreen extends StatefulWidget {
  const VendorAvailabilityScreen({super.key});

  @override
  State<VendorAvailabilityScreen> createState() =>
      _VendorAvailabilityScreenState();
}

class _VendorAvailabilityScreenState extends State<VendorAvailabilityScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;

  // Data for dates
  final Set<DateTime> _bookedDates = {};
  final Set<DateTime> _blockedDates = {};
  bool _sameDayAvailable = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    setState(() => _isLoading = true);
    try {
      final userId = StorageService().getString('user_id');
      if (userId == null) return;

      final response = await ApiService.instance.getVendorAvailability(userId);
      if (response['success'] == true) {
        setState(() {
          _sameDayAvailable = response['sameDayService'] ?? false;
          
          final blocked = response['blockedDates'] as List?;
          _blockedDates.clear();
          if (blocked != null) {
            for (var d in blocked) {
              if (d is String) {
                _blockedDates.add(DateTime.parse(d));
              }
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, message: 'Failed to load availability: $e', type: ToastType.error);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveAvailability() async {
    // We don't necessarily need a full page loader for small toggles, 
    // but for blocking/unblocking it's good feedback.
    try {
      final userId = StorageService().getString('user_id');
      if (userId == null) return;

      final blockedList = _blockedDates.map((d) => d.toIso8601String()).toList();

      await ApiService.instance.saveVendorAvailability(
        userId: userId,
        blockedDates: blockedList,
        sameDayService: _sameDayAvailable,
        // workingHours can be added later if needed
      );
      if (mounted) {
        AppToast.show(context, message: 'Availability updated!', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, message: 'Failed to save availability: $e', type: ToastType.error);
      }
    }
  }

  bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  bool _isBooked(DateTime day) {
    return _bookedDates.any((d) => isSameDay(d, day));
  }

  bool _isBlocked(DateTime day) {
    return _blockedDates.any((d) => isSameDay(d, day));
  }

  void _onDaySelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDay = selectedDay;
      _focusedDay = focusedDay;
    });

    _showDateOptionsSheet(selectedDay);
  }

  void _showDateOptionsSheet(DateTime day) {
    final booked = _isBooked(day);
    final blocked = _isBlocked(day);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, 24 + MediaQuery.of(context).padding.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${day.day}/${day.month}/${day.year}',
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A24),
                ),
              ),
              const SizedBox(height: 8),
              if (booked)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary01.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Confirmed Booking: Sarah & John Wedding',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary01,
                    ),
                  ),
                )
              else if (blocked)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Blocked / Unavailable',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4B5563),
                    ),
                  ),
                )
              else
                Text(
                  'Available for bookings',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
                    color: const Color(0xFF22C55E),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 24),
              if (!booked)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
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
                    style: ElevatedButton.styleFrom(
                      backgroundColor: blocked
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFEF4444),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      blocked ? 'Unblock Date' : 'Block Date',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              if (booked)
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      context.pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text("Cannot block a confirmed date.")),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF3F4F6),
                      foregroundColor: const Color(0xFF9CA3AF),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      'Block Date',
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A24)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Availability',
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A24),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
            Container(
              color: Colors.white,
              child: TableCalendar(
                firstDay: DateTime.utc(2020, 1, 1),
                lastDay: DateTime.utc(2030, 12, 31),
                focusedDay: _focusedDay,
                selectedDayPredicate: (day) =>
                    _selectedDay != null && isSameDay(_selectedDay!, day),
                onDaySelected: _onDaySelected,
                calendarFormat: CalendarFormat.month,
                headerStyle: HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A24),
                  ),
                  leftChevronIcon: const Icon(Icons.chevron_left_rounded),
                  rightChevronIcon: const Icon(Icons.chevron_right_rounded),
                ),
                calendarBuilders: CalendarBuilders(
                  defaultBuilder: (context, day, focusedDay) {
                    if (_isBooked(day)) {
                      return _buildCalendarCell(day, AppColors.primary01, Colors.white);
                    } else if (_isBlocked(day)) {
                      return _buildCalendarCell(day, const Color(0xFFE5E7EB), const Color(0xFF4B5563));
                    }
                    return null; // use default
                  },
                  selectedBuilder: (context, day, focusedDay) {
                    final color = _isBooked(day)
                        ? AppColors.primary01
                        : (_isBlocked(day) ? const Color(0xFF9CA3AF) : Colors.blue);
                    return Container(
                      margin: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        border: Border.all(color: color, width: 2),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${day.day}',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                  todayBuilder: (context, day, focusedDay) {
                    return _buildCalendarCell(day, Colors.blue.withValues(alpha: 0.1), Colors.blue);
                  },
                ),
              ),
            ),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Legend',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF1A1A24),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildLegendItem(AppColors.primary01, 'Booked Event'),
                  _buildLegendItem(const Color(0xFFE5E7EB), 'Blocked Date'),
                  _buildLegendItem(Colors.white, 'Available', hasBorder: true),
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE5E7EB)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF1F0),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.bolt_rounded,
                            color: AppColors.primary01,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Last-minute requests',
                                style: GoogleFonts.roboto(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF1A1A24),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Accept same-day bookings',
                                style: GoogleFonts.roboto(
                                  fontSize: 13,
                                  color: const Color(0xFF6B7280),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _sameDayAvailable,
                          activeThumbImage: null,
                          activeTrackColor: AppColors.primary01.withValues(alpha: 0.5),
                          activeColor: AppColors.primary01,
                          onChanged: (val) {
                            setState(() => _sameDayAvailable = val);
                            _saveAvailability();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarCell(DateTime day, Color bgColor, Color textColor) {
    return Container(
      margin: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: bgColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: GoogleFonts.roboto(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, {bool hasBorder = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: hasBorder ? Border.all(color: const Color(0xFFE5E7EB)) : null,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: const Color(0xFF4B5563),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
