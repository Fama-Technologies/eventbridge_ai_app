import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventbridge/features/matching/presentation/matching_controller.dart';
import 'package:eventbridge/features/matching/models/event_request.dart';

class MatchIntakeFormScreen extends ConsumerStatefulWidget {
  const MatchIntakeFormScreen({super.key});

  @override
  ConsumerState<MatchIntakeFormScreen> createState() => _MatchIntakeFormScreenState();
}

class _MatchIntakeFormScreenState extends ConsumerState<MatchIntakeFormScreen> {
  int _step = 0; // 0 = Event Type, 1 = Details, 2 = Budget
  final PageController _pageController = PageController();

  // Step 1 – Event Type
  String? _selectedEventType;
  final List<Map<String, String>> _eventTypes = [
    {
      'name': 'Wedding',
      'image':
          'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?q=80&w=400&auto=format&fit=crop'
    },
    {
      'name': 'Graduation',
      'image':
          'https://images.unsplash.com/photo-1523050854058-8df90110c9f1?q=80&w=400&auto=format&fit=crop'
    },
    {
      'name': 'Corporate',
      'image':
          'https://images.unsplash.com/photo-1511578314322-379afb476865?q=80&w=400&auto=format&fit=crop'
    },
    {
      'name': 'Birthday',
      'image':
          'https://images.unsplash.com/photo-1464349153735-7db50ed83c84?q=80&w=400&auto=format&fit=crop'
    },
    {
      'name': 'Anniversary',
      'image':
          'https://images.unsplash.com/photo-1515934751635-c81c6bc9a2d8?q=80&w=400&auto=format&fit=crop'
    },
    {
      'name': 'Concert',
      'image':
          'https://images.unsplash.com/photo-1459749411177-042180ce673c?q=80&w=400&auto=format&fit=crop'
    },
  ];

  // Step 1 – Services
  final List<String> _allServices = [
    'Photographer',
    'DJ',
    'Caterer',
    'Makeup Artist',
    'Florist',
    'Venue'
  ];
  final Set<String> _selectedServices = {};
  final Map<String, IconData> _serviceIcons = {
    'Photographer': Icons.camera_alt_rounded,
    'DJ': Icons.music_note_rounded,
    'Caterer': Icons.restaurant_rounded,
    'Makeup Artist': Icons.face_retouching_natural_rounded,
    'Florist': Icons.local_florist_rounded,
    'Venue': Icons.location_city_rounded,
  };

  // Step 2 – Details
  final _locationController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 30));
  int _guestCount = 50;

  // Step 3 – Budget
  double _budgetMin = 2000000;
  double _budgetMax = 15000000;
  String _currency = 'UGX';

  @override
  void dispose() {
    _locationController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _goNext() {
    if (_step == 0 && _selectedEventType == null) return;
    if (_step == 1 && _locationController.text.isEmpty) return;

    if (_step < 2) {
      setState(() => _step++);
      _pageController.animateToPage(_step,
          duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
    } else {
      // Trigger AI Search
      final request = EventRequest(
        eventType: _selectedEventType ?? 'Event',
        services: _selectedServices.toList(),
        guestCount: _guestCount,
        eventDate: _selectedDate,
        location: _locationController.text,
        budget: _budgetMax,
        prompt: 'Finding the best vendors for my ${_selectedEventType ?? 'event'} at ${_locationController.text}',
      );
      ref.read(matchingControllerProvider.notifier).searchMatches(request);
      context.push('/ai-analyzing');
    }
  }

  void _goBack() {
    if (_step > 0) {
      setState(() => _step--);
      _pageController.animateToPage(_step,
          duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
    } else {
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      body: Stack(
        children: [
          _buildBackgroundGradient(),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                _buildStepper(),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _buildStep1(),
                      _buildStep2(),
                      _buildStep3(),
                    ],
                  ),
                ),
                _buildBottomActions(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundGradient() {
    return Positioned(
      top: -100,
      right: -50,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              AppColors.primary01.withValues(alpha: 0.12),
              AppColors.primary01.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          GestureDetector(
            onTap: _goBack,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                  )
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 18, color: AppColors.primary01),
            ),
          ),
          Text(
            'MATCH INTAKE',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.primary01,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(width: 38), // Balance for back button
        ],
      ),
    );
  }

  Widget _buildStepper() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Row(
        children: List.generate(3, (i) {
          final bool isActive = i == _step;
          final bool isDone = i < _step;
          return Expanded(
            child: Row(
              children: [
                Expanded(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDone || isActive
                          ? AppColors.primary01
                          : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                if (i < 2) const SizedBox(width: 8),
              ],
            ),
          );
        }),
      ),
    );
  }

  // ──────────────────────────────
  // STEP 1: Premium Visual Selection
  // ──────────────────────────────
  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What beautiful event\nare we planning?',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.primary01,
              height: 1.1,
            ),
          ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
          const SizedBox(height: 24),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.85,
            ),
            itemCount: _eventTypes.length,
            itemBuilder: (context, index) {
              final type = _eventTypes[index];
              final isSelected = _selectedEventType == type['name'];
              return GestureDetector(
                onTap: () => setState(() => _selectedEventType = type['name']),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isSelected ? AppColors.primary01 : Colors.transparent,
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(21),
                    child: Stack(
                      children: [
                        Image.network(
                          type['image']!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (context, error, stackTrace) => Container(
                            color: Colors.grey[200],
                             child: const Icon(Icons.celebration_rounded, color: Colors.grey),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,
                                Colors.black.withValues(alpha: 0.7),
                              ],
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          left: 12,
                          right: 12,
                          child: Text(
                            type['name']!,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        if (isSelected)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: const BoxDecoration(
                                color: AppColors.primary01,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check_rounded,
                                  color: Colors.white, size: 16),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 32),
          Text(
            'Select Essential Services',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.primary01,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _allServices.map((s) {
              final bool sel = _selectedServices.contains(s);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (sel) {
                      _selectedServices.remove(s);
                    } else {
                      _selectedServices.add(s);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary01 : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: sel ? AppColors.primary01 : const Color(0xFFE5E7EB),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _serviceIcons[s] ?? Icons.star_rounded,
                        size: 16,
                        color: sel ? Colors.white : AppColors.primary01,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        s,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: sel ? Colors.white : AppColors.primary01,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // ──────────────────────────────
  // STEP 2: Location & Date Review
  // ──────────────────────────────
  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Where & When is the\nmagic happening?',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.primary01,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 180,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ],
              image: const DecorationImage(
                image: NetworkImage(
                    'https://maps.googleapis.com/maps/api/staticmap?center=40.7128,-74.0060&zoom=13&size=600x300&style=feature:all|element:labels|visibility:off&key=DEMO_KEY'),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(28),
                color: Colors.black.withValues(alpha: 0.1),
              ),
              child: const Center(
                child: Icon(Icons.location_on_rounded,
                    color: AppColors.primary01, size: 48),
              ),
            ),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _locationController,
            style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.primary01),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppColors.primary01, size: 20),
              hintText: 'Enter event location',
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Select Event Date',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.primary01,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03), blurRadius: 20)
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_monthName(_selectedDate.month)} ${_selectedDate.year}',
                      style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary01),
                    ),
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => setState(() => _selectedDate =
                              DateTime(_selectedDate.year, _selectedDate.month - 1, 1)),
                          icon: const Icon(Icons.chevron_left_rounded,
                              color: AppColors.primary01),
                        ),
                        IconButton(
                          onPressed: () => setState(() => _selectedDate =
                              DateTime(_selectedDate.year, _selectedDate.month + 1, 1)),
                          icon: const Icon(Icons.chevron_right_rounded,
                              color: AppColors.primary01),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _buildCalendarGrid(),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _buildGuestCounter(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildGuestCounter() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary01.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.primary01.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'GUEST COUNT',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary01,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '$_guestCount Attendees',
                style: GoogleFonts.outfit(
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary01),
              ),
            ],
          ),
          Row(
            children: [
              _counterBtn(Icons.remove_rounded, () {
                if (_guestCount > 1) setState(() => _guestCount--);
              }),
              const SizedBox(width: 16),
              _counterBtn(Icons.add_rounded, () {
                setState(() => _guestCount++);
              }),
            ],
          ),
        ],
      ),
    );
  }

  Widget _counterBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
                color: AppColors.primary01.withValues(alpha: 0.1),
                blurRadius: 10)
          ],
        ),
        child: Icon(icon, color: AppColors.primary01, size: 24),
      ),
    );
  }

  // ──────────────────────────────
  // STEP 3: Budget & Summary
  // ──────────────────────────────
  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Final step: Set your\nbudget & review.',
            style: GoogleFonts.outfit(
              fontSize: 28,
              fontWeight: FontWeight.w900,
              color: AppColors.primary01,
              height: 1.1,
            ),
          ),
          const SizedBox(height: 32),
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.primary01,
              borderRadius: BorderRadius.circular(32),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary01.withValues(alpha: 0.3),
                  blurRadius: 30,
                  offset: const Offset(0, 15),
                )
              ],
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _budgetInfo('MIN BUDGET', 'Shs ${_budgetMin.toInt()}'),
                    Container(width: 2, height: 40, color: Colors.white24),
                    _budgetInfo('MAX BUDGET', 'Shs ${_budgetMax.toInt()}'),
                  ],
                ),
                const SizedBox(height: 32),
                RangeSlider(
                  values: RangeValues(_budgetMin, _budgetMax),
                  min: 0,
                  max: 100000000,
                  divisions: 100,
                  activeColor: Colors.white,
                  inactiveColor: Colors.white24,
                  onChanged: (v) => setState(() {
                    _budgetMin = v.start;
                    _budgetMax = v.end;
                  }),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Match Brief Summary',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.primary01,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.02), blurRadius: 20)
              ],
            ),
            child: Column(
              children: [
                _summaryRow(Icons.auto_awesome_rounded, 'Event',
                    _selectedEventType ?? 'Not selected'),
                _summaryRow(Icons.apps_rounded, 'Services',
                    '${_selectedServices.length} Selected'),
                _summaryRow(Icons.location_on_rounded, 'Location',
                    _locationController.text),
                _summaryRow(Icons.calendar_today_rounded, 'Date',
                    '${_monthName(_selectedDate.month)} ${_selectedDate.day}'),
                _summaryRow(Icons.group_rounded, 'Guests', '$_guestCount People'),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _budgetInfo(String label, String value) {
    return Column(
      children: [
        Text(label,
            style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1)),
        const SizedBox(height: 4),
        Text(value,
            style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w900)),
      ],
    );
  }

  Widget _summaryRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary01.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary01, size: 16),
          ),
          const SizedBox(width: 12),
          Text(label,
              style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B7280))),
          const Spacer(),
          Text(value,
              style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary01)),
        ],
      ),
    );
  }

  Widget _buildBottomActions() {
    final labels = ['CONTINUE', 'NEXT STEP', 'GENERATE AI MATCHES'];
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: GestureDetector(
        onTap: _goNext,
        child: Container(
          height: 64,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [AppColors.primary01, AppColors.primary02],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary01.withValues(alpha: 0.35),
                blurRadius: 20,
                offset: const Offset(0, 10),
              )
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_step == 2)
                const Icon(Icons.auto_awesome, color: Colors.white, size: 20),
              if (_step == 2) const SizedBox(width: 10),
              Text(
                labels[_step],
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
              if (_step < 2) const SizedBox(width: 10),
              if (_step < 2)
                const Icon(Icons.arrow_forward_rounded,
                    color: Colors.white, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCalendarGrid() {
    final firstDay = DateTime(_selectedDate.year, _selectedDate.month, 1);
    final daysInMonth =
        DateTime(_selectedDate.year, _selectedDate.month + 1, 0).day;
    final startWeekday = firstDay.weekday % 7;
    final totalCells = startWeekday + daysInMonth;
    final rows = (totalCells / 7).ceil();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S']
              .map((d) => Text(d,
                  style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF9CA3AF))))
              .toList(),
        ),
        const SizedBox(height: 12),
        ...List.generate(rows, (row) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (col) {
              final cellIndex = row * 7 + col;
              final day = cellIndex - startWeekday + 1;
              if (day < 1 || day > daysInMonth) {
                return const SizedBox(width: 32, height: 32);
              }
              final isSelected = day == _selectedDate.day;
              return GestureDetector(
                onTap: () => setState(() => _selectedDate =
                    DateTime(_selectedDate.year, _selectedDate.month, day)),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary01 : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$day',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w900 : FontWeight.w600,
                        color: isSelected ? Colors.white : AppColors.primary01,
                      ),
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ],
    );
  }

  String _monthName(int month) {
    const names = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return names[month];
  }
}
