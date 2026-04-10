import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/features/matching/presentation/matching_controller.dart';
import 'package:eventbridge/features/matching/models/event_request.dart';

class MatchIntakeBottomSheet extends ConsumerStatefulWidget {
  final String categoryName;

  const MatchIntakeBottomSheet({
    super.key,
    required this.categoryName,
  });

  @override
  ConsumerState<MatchIntakeBottomSheet> createState() => _MatchIntakeBottomSheetState();
}

class _MatchIntakeBottomSheetState extends ConsumerState<MatchIntakeBottomSheet> {
  final _locationController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 30));
  final _guestController = TextEditingController(text: '50');
  final _budgetController = TextEditingController();

  final List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

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
      eventType: widget.categoryName,
      services: [], // AI decides or user adds later
      guestCount: guestCount,
      eventDate: _selectedDate,
      location: _locationController.text.trim(),
      budget: budget,
      prompt: 'Finding the best vendors for my ${widget.categoryName} at ${_locationController.text.trim()}',
    );

    // Call match controller
    ref.read(matchingControllerProvider.notifier).searchMatches(request);

    // Close bottom sheet
    Navigator.pop(context);

    // Navigate to loading
    context.push('/ai-analyzing');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 48,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary01.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.auto_awesome, color: AppColors.primary01),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Find Vendors For',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            widget.categoryName,
                            style: GoogleFonts.outfit(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                
                // Location Input
                Text(
                  'Location',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    hintText: 'Where is the event?',
                    hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.location_on_outlined, color: AppColors.primary01),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primary01, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Date & Guests Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Date',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
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
                                builder: (context, child) {
                                  return Theme(
                                    data: Theme.of(context).copyWith(
                                      colorScheme: const ColorScheme.light(
                                        primary: AppColors.primary01,
                                        onPrimary: Colors.white,
                                        onSurface: Colors.black87,
                                      ),
                                    ),
                                    child: child!,
                                  );
                                },
                              );
                              if (picked != null) {
                                setState(() => _selectedDate = picked);
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE5E7EB)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.primary01),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${_selectedDate.day} ${_months[_selectedDate.month - 1]}',
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
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
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _guestController,
                            keyboardType: TextInputType.number,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                            decoration: InputDecoration(
                              hintText: 'e.g. 50',
                              filled: true,
                              fillColor: Colors.grey[50],
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: AppColors.primary01, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Budget Slider
                Text(
                  'Estimated Budget (UGX)',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _budgetController,
                  keyboardType: TextInputType.number,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary01,
                  ),
                  decoration: InputDecoration(
                    hintText: 'e.g. 5000000',
                    hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
                    prefixText: 'UGX ',
                    prefixStyle: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary01,
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primary01, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Match Button
                ElevatedButton(
                  onPressed: _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary01,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Text(
                    'Match Me with Vendors',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
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
}
