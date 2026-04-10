import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/features/matching/models/match_vendor.dart';
import 'package:eventbridge/features/matching/models/event_request.dart';
import 'package:eventbridge/features/matching/presentation/matching_controller.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:eventbridge/features/shared/widgets/top_notification.dart';

class InquiryBottomSheet extends ConsumerStatefulWidget {
  final MatchVendor vendor;
  final VendorPackage? package;
  const InquiryBottomSheet({super.key, required this.vendor, this.package});

  static Future<void> show(BuildContext context, MatchVendor vendor, {VendorPackage? package}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => InquiryBottomSheet(vendor: vendor, package: package),
    );
  }

  @override
  ConsumerState<InquiryBottomSheet> createState() => _InquiryBottomSheetState();
}

class _InquiryBottomSheetState extends ConsumerState<InquiryBottomSheet> {
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 7));
  TimeOfDay _selectedTime = const TimeOfDay(hour: 10, minute: 0);
  final _guestCountController = TextEditingController();
  final _budgetController = TextEditingController();
  final _messageController = TextEditingController();
  final _serviceController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.vendor.services.isNotEmpty) {
      _serviceController.text = widget.vendor.services.first;
    }
    _guestCountController.text = '50';
    
    if (widget.package != null) {
      _budgetController.text = widget.package!.price.toStringAsFixed(0);
      _messageController.text = "I'm interested in the ${widget.package!.title} package.";
    } else {
      _budgetController.text = widget.vendor.minPackagePrice.toStringAsFixed(0);
    }
  }

  @override
  void dispose() {
    _guestCountController.dispose();
    _budgetController.dispose();
    _messageController.dispose();
    _serviceController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary01,
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary01,
              onPrimary: Colors.white,
              onSurface: Color(0xFF1E293B),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedTime = picked);
    }
  }

  Future<void> _handleSubmit() async {
    setState(() => _isSubmitting = true);

    final service = _serviceController.text;
    final guests = int.tryParse(_guestCountController.text) ?? 50;

    final request = EventRequest(
      eventType: service,
      services: [service],
      guestCount: guests,
      eventDate: _selectedDate,
      eventTime: _selectedTime.format(context),
      location: widget.vendor.location, // Fallback to vendor location
      budget: double.tryParse(_budgetController.text) ?? widget.vendor.minPackagePrice,
      prompt: _messageController.text,
    );

    try {
      await ref.read(matchingControllerProvider.notifier).sendInquiry(
        vendor: widget.vendor,
        request: request,
      );
      if (!mounted) return;
      
      Navigator.pop(context);
      
      final currentContext = context;
      TopNotificationOverlay.show(
        context: currentContext,
        title: 'Inquiry Sent!',
        message: 'Your inquiry has been sent to ${widget.vendor.name}. They will be notified immediately.',
        onTap: () {
          // Optional: Navigate to the chat if possible, 
          // but usually it takes a moment to create the chat
        },
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to send inquiry. Please try again.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
              physics: const BouncingScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.primary01.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.send_rounded, color: AppColors.primary01, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Make Inquiry',
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF1A1A24),
                              ),
                            ),
                            Text(
                              'to ${widget.vendor.name}',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: const Color(0xFF64748B),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ).animate().fadeIn().slideX(begin: -0.1, end: 0),
                  
                  const SizedBox(height: 32),
                  
                  _buildSectionTitle('Event Details', isDark),
                  const SizedBox(height: 16),
                  
                  Row(
                    children: [
                      Expanded(
                        child: _buildPickerField(
                          label: 'Date',
                          value: DateFormat('MMM dd, yyyy').format(_selectedDate),
                          icon: Icons.calendar_today_rounded,
                          onTap: _selectDate,
                          isDark: isDark,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildPickerField(
                          label: 'Time',
                          value: _selectedTime.format(context),
                          icon: Icons.access_time_rounded,
                          onTap: _selectTime,
                          isDark: isDark,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('Expected Guests', isDark),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _guestCountController,
                    hint: 'How many guests?',
                    icon: Icons.people_rounded,
                    keyboardType: TextInputType.number,
                    isDark: isDark,
                  ),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('Your Budget (UGX)', isDark),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _budgetController,
                    hint: 'Enter your budget',
                    icon: Icons.payments_rounded,
                    keyboardType: TextInputType.number,
                    isDark: isDark,
                  ),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('Service Required', isDark),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _serviceController,
                    hint: 'What service do you need?',
                    icon: Icons.category_rounded,
                    isDark: isDark,
                  ),
                  
                  const SizedBox(height: 24),
                  _buildSectionTitle('Additional Details', isDark),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _messageController,
                    hint: 'Tell the vendor what you need...',
                    icon: Icons.message_rounded,
                    maxLines: 4,
                    isDark: isDark,
                  ),
                  
                  const SizedBox(height: 48),
                  
                  SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _handleSubmit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary01,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 4,
                        shadowColor: AppColors.primary01.withValues(alpha: 0.3),
                      ),
                      child: _isSubmitting 
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Send Inquiry',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : const Color(0xFF1A1A24),
      ),
    );
  }

  Widget _buildPickerField({
    required String label,
    required String value,
    required IconData icon,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 14, color: AppColors.primary01),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: keyboardType,
        style: GoogleFonts.outfit(
          color: isDark ? Colors.white : const Color(0xFF1E293B),
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.outfit(color: const Color(0xFF94A3B8)),
          icon: Icon(icon, color: AppColors.primary01, size: 20),
          border: InputBorder.none,
        ),
      ),
    );
  }

}
