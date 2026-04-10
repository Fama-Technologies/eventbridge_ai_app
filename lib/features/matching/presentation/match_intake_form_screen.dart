import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/features/matching/presentation/matching_controller.dart';
import 'package:eventbridge/features/matching/models/event_request.dart';

class MatchIntakeFormScreen extends ConsumerStatefulWidget {
  const MatchIntakeFormScreen({super.key});

  @override
  ConsumerState<MatchIntakeFormScreen> createState() => _MatchIntakeFormScreenState();
}

class _MatchIntakeFormScreenState extends ConsumerState<MatchIntakeFormScreen> {
  final _locationController = TextEditingController();
  final _guestController = TextEditingController(text: '50');
  final _budgetController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 30));

  final List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  final List<String> _eventTypes = [
    'Wedding', 'Graduation', 'Corporate', 'Birthday', 'Anniversary', 'Concert',
    'Party', 'Conference', 'Exhibition', 'Other',
  ];

  String _selectedEventType = 'Wedding';

  @override
  void dispose() {
    _locationController.dispose();
    _guestController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _submit() {
    FocusScope.of(context).unfocus();
    if (_locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a location')),
      );
      return;
    }

    final guestCount = int.tryParse(_guestController.text.trim()) ?? 50;
    final budgetStr = _budgetController.text.replaceAll(',', '').trim();
    final budget = double.tryParse(budgetStr) ?? 5000000.0;

    final request = EventRequest(
      eventType: _selectedEventType,
      services: [],
      guestCount: guestCount,
      eventDate: _selectedDate,
      location: _locationController.text.trim(),
      budget: budget,
      prompt:
          'Finding the best vendors for my $_selectedEventType at ${_locationController.text.trim()}',
    );

    ref.read(matchingControllerProvider.notifier).searchMatches(request);
    context.push('/ai-analyzing');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.neutrals08),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/customer-home');
            }
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, color: AppColors.primary01, size: 16),
            const SizedBox(width: 6),
            Text(
              'AI Match',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.neutrals08,
              ),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Tell us about your event',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.neutrals08,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'We\'ll find the best vendors for you.',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: AppColors.neutrals07,
              ),
            ),
            const SizedBox(height: 28),

            // Event type
            Text(
              'Event Type',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.neutrals08,
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _eventTypes.map((type) {
                final selected = _selectedEventType == type;
                return GestureDetector(
                  onTap: () => setState(() => _selectedEventType = type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary01 : Colors.white,
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(
                        color: selected ? AppColors.primary01 : AppColors.neutrals03,
                      ),
                    ),
                    child: Text(
                      type,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: selected ? Colors.white : AppColors.neutrals08,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Location
            Text(
              'Location',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.neutrals08,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              decoration: _inputDecoration(
                hint: 'Where is the event?',
                icon: Icons.location_on_outlined,
              ),
            ),
            const SizedBox(height: 20),

            // Date & Guests
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.neutrals08,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                            builder: (context, child) => Theme(
                              data: Theme.of(context).copyWith(
                                colorScheme: const ColorScheme.light(
                                  primary: AppColors.primary01,
                                  onPrimary: Colors.white,
                                  onSurface: Colors.black87,
                                ),
                              ),
                              child: child!,
                            ),
                          );
                          if (picked != null) setState(() => _selectedDate = picked);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.neutrals03),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_outlined,
                                  size: 18, color: AppColors.primary01),
                              const SizedBox(width: 8),
                              Text(
                                '${_selectedDate.day} ${_months[_selectedDate.month - 1]} ${_selectedDate.year}',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.neutrals08,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Guests',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.neutrals08,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _guestController,
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: _inputDecoration(hint: 'e.g. 50'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Budget
            Text(
              'Estimated Budget (UGX)',
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.neutrals08,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _budgetController,
              keyboardType: TextInputType.number,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.primary01,
              ),
              decoration: InputDecoration(
                hintText: 'e.g. 5000000',
                hintStyle: GoogleFonts.outfit(color: AppColors.neutrals05),
                prefixText: 'UGX ',
                prefixStyle: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary01,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.neutrals03),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.neutrals03),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: AppColors.primary01, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 36),

            ElevatedButton(
              onPressed: _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary01,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.auto_awesome, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Match Me with Vendors',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({required String hint, IconData? icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.outfit(color: AppColors.neutrals05),
      prefixIcon: icon != null ? Icon(icon, color: AppColors.primary01, size: 20) : null,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.neutrals03),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.neutrals03),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primary01, width: 2),
      ),
    );
  }
}
