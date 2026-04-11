import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/features/matching/presentation/matching_controller.dart';
import 'package:eventbridge/features/matching/models/event_request.dart';

class MatchIntakeBottomSheet extends ConsumerStatefulWidget {
  final String? initialEventType;
  final String? initialService;

  const MatchIntakeBottomSheet({
    super.key,
    this.initialEventType,
    this.initialService,
  });

  @override
  ConsumerState<MatchIntakeBottomSheet> createState() => _MatchIntakeBottomSheetState();
}

class _MatchIntakeBottomSheetState extends ConsumerState<MatchIntakeBottomSheet> {
  final _locationController = TextEditingController();
  DateTime _selectedDate = DateTime.now().add(const Duration(days: 30));
  final _guestController = TextEditingController(text: '50');
  final _budgetController = TextEditingController();

  final List<String> _eventTypeOptions = ['Wedding', 'Birthday', 'Corporate', 'Concert', 'Graduation', 'Other'];
  String? _selectedEventType;

  final List<String> _serviceOptions = [
    'Venue', 'Photographer', 'Videographer', 'Decorator', 'Caterer', 
    'Makeup Artist', 'Hair Stylist', 'DJ', 'MC', 'Live Band', 
    'Fashion / Bridal Wear', 'Cake', 'Transport', 'Ushering', 'Other'
  ];
  final List<String> _selectedServices = [];
  bool _hasVenue = false;
  String _selectedCurrency = 'UGX';
  double _searchRadius = 50.0; // Default 50 km

  final List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
  ];

  @override
  void initState() {
    super.initState();
    _selectedEventType = widget.initialEventType;
    if (widget.initialService != null) {
      _selectedServices.add(widget.initialService!);
      if (widget.initialService == 'Venue') {
        _hasVenue = false;
      }
    } else {
      _selectedServices.add('Venue');
      _hasVenue = false;
    }
  }

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

    if (_selectedEventType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select what you are planning')),
      );
      return;
    }

    final guestCount = int.tryParse(_guestController.text.trim()) ?? 50;
    final budgetStr = _budgetController.text.replaceAll(',', '').trim();
    final budget = double.tryParse(budgetStr) ?? 5000000.0;

    String finalPrompt = 'Finding the best vendors for my $_selectedEventType at ${_locationController.text.trim()} within ${_searchRadius.toInt()}km.';
    if (_selectedServices.isNotEmpty) {
      finalPrompt += ' Looking for: ${_selectedServices.join(', ')}.';
      if (!_selectedServices.contains('Venue')) {
        finalPrompt += _hasVenue ? ' I already have a venue.' : ' I also need a venue.';
      }
    }
    finalPrompt += ' Budget: $_selectedCurrency $budgetStr.';

    final request = EventRequest(
      eventType: _selectedEventType!,
      services: _selectedServices,
      guestCount: guestCount,
      eventDate: _selectedDate,
      location: _locationController.text.trim(),
      targetRadius: _searchRadius,
      budget: budget,
      prompt: finalPrompt,
    );

    // Call match controller
    ref.read(matchingControllerProvider.notifier).searchMatches(request);

    // Close bottom sheet
    Navigator.pop(context);

    // Navigate to loading screen
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
          padding: EdgeInsets.fromLTRB(28, 16, 28, MediaQuery.of(context).viewInsets.bottom + 24),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
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
                        color: AppColors.primary01.withValues(alpha: 0.1),
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
                            _selectedEventType ?? (widget.initialService != null ? widget.initialService! : 'Your Event'),
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

                // Event Type Input (Conditional if not provided)
                if (widget.initialEventType == null) ...[
                  _buildSectionHeader('Event Type', Icons.celebration_rounded),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _eventTypeOptions.map((type) {
                      final isSelected = _selectedEventType == type;
                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedEventType = type;
                          });
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary01 : Colors.white,
                            border: Border.all(
                              color: isSelected ? AppColors.primary01 : const Color(0xFFE5E7EB),
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            type,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                              color: isSelected ? Colors.white : Colors.grey[700],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 32),
                ],
                
                // Services Input
                _buildSectionHeader('Services Required', Icons.design_services_rounded),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: _serviceOptions.map((service) {
                    final isSelected = _selectedServices.contains(service);
                    return InkWell(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            _selectedServices.remove(service);
                            if (service == 'Venue') {
                              _hasVenue = true;
                            }
                          } else {
                            _selectedServices.add(service);
                            if (service == 'Venue') {
                              _hasVenue = false;
                            }
                          }
                        });
                      },
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.primary01 : Colors.white,
                          border: Border.all(
                            color: isSelected ? AppColors.primary01 : const Color(0xFFE5E7EB),
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          service,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected ? Colors.white : Colors.grey[800],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.primary01.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary01.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'I already have a venue booked',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      Switch(
                        value: _hasVenue,
                        onChanged: (val) {
                          setState(() {
                            _hasVenue = val;
                            if (val) {
                              _selectedServices.remove('Venue');
                            } else {
                              if (!_selectedServices.contains('Venue')) {
                                _selectedServices.add('Venue');
                              }
                            }
                          });
                        },
                        activeThumbColor: AppColors.primary01,
                        activeTrackColor: AppColors.primary01.withValues(alpha: 0.4),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Location & Radius Input
                _buildSectionHeader('Location & Radius', Icons.location_on_rounded),
                const SizedBox(height: 12),
                TextField(
                  controller: _locationController,
                  decoration: InputDecoration(
                    hintText: 'Where is the event? (e.g. Kampala)',
                    hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary01),
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
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Search Radius',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      '${_searchRadius.toInt()} km',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary01,
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: _searchRadius,
                  min: 25,
                  max: 200,
                  divisions: 35,
                  activeColor: AppColors.primary01,
                  inactiveColor: AppColors.primary01.withValues(alpha: 0.2),
                  onChanged: (value) {
                    setState(() {
                      _searchRadius = value;
                    });
                  },
                ),
                const SizedBox(height: 24),

                // Date & Guests Row
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Date', Icons.calendar_today_rounded),
                          const SizedBox(height: 12),
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
                                  Text(
                                    '${_selectedDate.day} ${_months[_selectedDate.month - 1]}, ${_selectedDate.year}',
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
                      flex: 0,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Guests', Icons.people_rounded),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: 110,
                            child: TextField(
                              controller: _guestController,
                              keyboardType: TextInputType.number,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.black87,
                              ),
                              decoration: InputDecoration(
                                hintText: '50',
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
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),

                // Budget Field with Currency
                _buildSectionHeader('Estimated Budget', Icons.account_balance_wallet_rounded),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      height: 56,
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCurrency,
                          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.primary01),
                          items: ['UGX', 'USD', 'EUR', 'GBP'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: GoogleFonts.outfit(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary01,
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (newValue) {
                            if (newValue != null) {
                              setState(() {
                                _selectedCurrency = newValue;
                              });
                            }
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: _budgetController,
                        keyboardType: TextInputType.number,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                        decoration: InputDecoration(
                          hintText: 'e.g. 5,000,000',
                          hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
                          filled: true,
                          fillColor: Colors.grey[50],
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
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
                    ),
                  ],
                ),
                const SizedBox(height: 48),

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
                    elevation: 4,
                    shadowColor: AppColors.primary01.withValues(alpha: 0.3),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.psychology_rounded, color: Colors.white, size: 24),
                      const SizedBox(width: 10),
                      Text(
                        'Confirm & Find Vendors',
                        style: GoogleFonts.outfit(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary01),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
