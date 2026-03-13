import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import 'package:eventbridge_ai/core/theme/app_colors.dart';
import 'package:eventbridge_ai/features/matching/models/event_request.dart';
import 'package:eventbridge_ai/features/matching/presentation/matching_controller.dart';

// ─── Data ───────────────────────────────────────────────────────────────────

const _eventTypes = [
  'Wedding', 'Birthday', 'Corporate', 'Introduction', 'Graduation',
  'Baby Shower', 'Funeral', 'Concert', 'Party', 'Other',
];

const _serviceCategories = [
  'Photography', 'Videography', 'Catering', 'Decor', 'DJ / Sound',
  'MC / Host', 'Makeup Artist', 'Venue', 'Cake', 'Transport',
  'Security', 'Florist', 'Tent / Chairs', 'Ushers',
];

// ─── Screen ──────────────────────────────────────────────────────────────────

class EventRequestScreen extends ConsumerStatefulWidget {
  const EventRequestScreen({super.key});

  @override
  ConsumerState<EventRequestScreen> createState() => _EventRequestScreenState();
}

class _EventRequestScreenState extends ConsumerState<EventRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  final _guestCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _timeCtrl = TextEditingController();
  final _budgetCtrl = TextEditingController();
  final _promptCtrl = TextEditingController();

  String? _selectedEventType;
  final Set<String> _selectedServices = {};
  DateTime? _selectedDate;
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _guestCtrl.dispose();
    _locationCtrl.dispose();
    _timeCtrl.dispose();
    _budgetCtrl.dispose();
    _promptCtrl.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now.add(const Duration(days: 1)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary01,
              onPrimary: Colors.white,
              surface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submit() async {
    if (_selectedEventType == null) {
      _showError('Please select an event type.');
      return;
    }
    if (_selectedServices.isEmpty) {
      _showError('Please select at least one service.');
      return;
    }
    if (_selectedDate == null) {
      _showError('Please select an event date.');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final budget = double.tryParse(_budgetCtrl.text.trim()) ?? 0;
    final guest = int.tryParse(_guestCtrl.text.trim());

    final request = EventRequest(
      eventType: _selectedEventType!,
      services: _selectedServices.toList(),
      guestCount: guest,
      eventDate: _selectedDate!,
      location: _locationCtrl.text.trim(),
      eventTime: _timeCtrl.text.trim().isEmpty ? null : _timeCtrl.text.trim(),
      budget: budget,
      prompt: _promptCtrl.text.trim(),
    );

    await ref.read(matchingControllerProvider.notifier).searchMatches(request);
    if (!mounted) return;
    context.go('/matches');
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.primary01,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(matchingControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      body: Form(
        key: _formKey,
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            _buildHeroHeader(),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _sectionLabel('What type of event?', topPadding: 28),
                  const SizedBox(height: 12),
                  _buildEventTypeChips(),
                  _sectionLabel('Services needed'),
                  const SizedBox(height: 12),
                  _buildServicesChips(),
                  _sectionLabel('Event date'),
                  const SizedBox(height: 12),
                  _buildDatePicker(),
                  _sectionLabel('Location'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    _locationCtrl, 'e.g. Munyonyo, Kampala',
                    prefixIcon: Icons.location_on_rounded,
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Required' : null,
                  ),
                  _sectionLabel('Event time (optional)'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    _timeCtrl, 'e.g. 3:00 PM',
                    prefixIcon: Icons.access_time_rounded,
                  ),
                  _sectionLabel('Number of guests (optional)'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    _guestCtrl, 'e.g. 200',
                    prefixIcon: Icons.people_rounded,
                    keyboardType: TextInputType.number,
                  ),
                  _sectionLabel('Your budget (USD)'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    _budgetCtrl, 'e.g. 1500',
                    prefixIcon: Icons.attach_money_rounded,
                    keyboardType: TextInputType.number,
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Required';
                      if (double.tryParse(v.trim()) == null) {
                        return 'Enter a valid number';
                      }
                      return null;
                    },
                  ),
                  _sectionLabel('Tell the AI what you\'re looking for'),
                  const SizedBox(height: 12),
                  _buildPromptField(),
                  const SizedBox(height: 32),
                  _buildSubmitButton(state.isLoading),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Widgets ──────────────────────────────────────────────────────────────

  Widget _buildHeroHeader() {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A24), Color(0xFF2D1810)],
          ),
          borderRadius: BorderRadius.only(
            bottomLeft: Radius.circular(36),
            bottomRight: Radius.circular(36),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary01.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.primary01.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.auto_awesome_rounded,
                        color: AppColors.primary01,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'AI MATCHING',
                        style: GoogleFonts.roboto(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primary01,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'Plan Your\nPerfect Event',
              style: GoogleFonts.roboto(
                fontSize: 34,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                height: 1.1,
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Tell us what you need and EventBridge AI will match you with trusted, available vendors.',
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.65),
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label, {double topPadding = 24}) {
    return Padding(
      padding: EdgeInsets.only(top: topPadding, bottom: 0),
      child: Text(
        label,
        style: GoogleFonts.roboto(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: const Color(0xFF1A1A24),
        ),
      ),
    );
  }

  Widget _buildEventTypeChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _eventTypes.map((type) {
        final selected = _selectedEventType == type;
        return GestureDetector(
          onTap: () => setState(() => _selectedEventType = type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary01 : Colors.white,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: selected ? AppColors.primary01 : const Color(0xFFE5E7EB),
              ),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.primary01.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : [],
            ),
            child: Text(
              type,
              style: GoogleFonts.roboto(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF4B5563),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildServicesChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _serviceCategories.map((svc) {
        final selected = _selectedServices.contains(svc);
        return GestureDetector(
          onTap: () {
            setState(() {
              if (selected) {
                _selectedServices.remove(svc);
              } else {
                _selectedServices.add(svc);
              }
            });
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(
              color: selected
                  ? AppColors.primary01.withValues(alpha: 0.1)
                  : Colors.white,
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: selected
                    ? AppColors.primary01
                    : const Color(0xFFE5E7EB),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (selected) ...[
                  Icon(
                    Icons.check_circle_rounded,
                    size: 15,
                    color: AppColors.primary01,
                  ),
                  const SizedBox(width: 5),
                ],
                Text(
                  svc,
                  style: GoogleFonts.roboto(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: selected
                        ? AppColors.primary01
                        : const Color(0xFF4B5563),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildDatePicker() {
    final hasDate = _selectedDate != null;
    return GestureDetector(
      onTap: _pickDate,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasDate ? AppColors.primary01 : const Color(0xFFE5E7EB),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: hasDate
                    ? AppColors.primary01.withValues(alpha: 0.1)
                    : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.calendar_month_rounded,
                color: hasDate ? AppColors.primary01 : const Color(0xFF9CA3AF),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                hasDate
                    ? DateFormat('EEEE, MMMM d, yyyy').format(_selectedDate!)
                    : 'Select event date',
                style: GoogleFonts.roboto(
                  fontSize: 15,
                  fontWeight: hasDate ? FontWeight.w600 : FontWeight.w400,
                  color: hasDate
                      ? const Color(0xFF1A1A24)
                      : const Color(0xFF9CA3AF),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: const Color(0xFF9CA3AF),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController ctrl,
    String hint, {
    IconData? prefixIcon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
      style: GoogleFonts.roboto(fontSize: 15, color: const Color(0xFF1A1A24)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.roboto(
          fontSize: 14,
          color: const Color(0xFF9CA3AF),
        ),
        prefixIcon: prefixIcon != null
            ? Icon(prefixIcon, size: 20, color: const Color(0xFF9CA3AF))
            : null,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
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
          borderSide: BorderSide(color: AppColors.primary01, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildPromptField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: AppColors.primary01,
                ),
                const SizedBox(width: 8),
                Text(
                  'AI Prompt',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary01,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          TextFormField(
            controller: _promptCtrl,
            maxLines: 5,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Please describe your event needs' : null,
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: const Color(0xFF1A1A24),
              height: 1.6,
            ),
            decoration: InputDecoration(
              hintText:
                  'Describe the vibe, style, special requirements, and priorities for your event...',
              hintStyle: GoogleFonts.roboto(
                fontSize: 14,
                color: const Color(0xFF9CA3AF),
                height: 1.6,
              ),
              filled: false,
              contentPadding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(bool isLoading) {
    return GestureDetector(
      onTap: isLoading ? null : _submit,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: double.infinity,
        height: 60,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: isLoading
                ? [const Color(0xFF9CA3AF), const Color(0xFF6B7280)]
                : [AppColors.primary01, const Color(0xFFFF6433)],
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: isLoading
              ? []
              : [
                  BoxShadow(
                    color: AppColors.primary01.withValues(alpha: 0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
        ),
        child: Center(
          child: isLoading
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: Colors.white,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.auto_awesome_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'Find My Match',
                      style: GoogleFonts.roboto(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}
