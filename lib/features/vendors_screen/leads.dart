import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/features/vendors_screen/data/mock_lead_data.dart';
import 'package:eventbridge/features/vendors_screen/models/lead_model.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge/core/network/api_service.dart';
import 'package:eventbridge/core/storage/storage_service.dart';
import 'package:flutter_animate/flutter_animate.dart';

class LeadsScreen extends StatefulWidget {
  const LeadsScreen({super.key});

  @override
  State<LeadsScreen> createState() => _LeadsScreenState();
}

class _LeadsScreenState extends State<LeadsScreen> {
  int _selectedSegment = 0; // 0: New, 1: Active
  bool _isSearching = false;
  String _searchQuery = '';
  String _sortBy = 'recent'; // 'recent', 'score', 'budget'
  final TextEditingController _searchController = TextEditingController();
  List<Lead> _allLeads = [];
  bool _isLoading = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _fetchLeads();
  }

  Future<void> _fetchLeads() async {
    try {
      final userId = StorageService().getString('user_id');
      if (userId == null) return;

      final results = await Future.wait([
        ApiService.instance.getVendorLeads(userId),
        ApiService.instance.getVendorBookings(userId),
      ]);

      final leadsResult = results[0];
      final bookingsResult = results[1];

      if (mounted) {
        List<Lead> leads = [];
        if (leadsResult['success'] == true) {
          final List<dynamic> leadsData = leadsResult['leads'] ?? [];
          leads = leadsData.map((json) => Lead(
            id: json['id'].toString(),
            title: json['title'] ?? 'Lead',
            date: json['date'] ?? 'TBD',
            time: json['time'] ?? 'TBD',
            location: json['location'] ?? 'TBD',
            matchScore: int.tryParse(json['matchScore']?.toString() ?? '0') ?? 0,
            budget: (json['budget'] is num) ? (json['budget'] as num).toDouble() : double.tryParse(json['budget']?.toString() ?? '0.0') ?? 0.0,
            guests: int.tryParse(json['guests']?.toString() ?? '0') ?? 0,
            responseTime: json['responseTime'] ?? '2h',
            clientName: json['clientName'] ?? 'Client',
            clientMessage: json['clientMessage'] ?? '',
            venueName: json['venueName'] ?? '',
            venueAddress: json['venueAddress'] ?? '',
            clientImageUrl: json['clientImageUrl'] ?? 'https://ui-avatars.com/api/?name=${json['clientName'] ?? 'Client'}&background=random',
            isHighValue: json['isHighValue'] ?? false,
            lastActive: json['lastActive'] ?? 'Active now',
            isAccepted: json['isAccepted'] ?? false,
            phoneNumber: json['phoneNumber']?.toString(),
          )).toList();
        }

        // Merge actual bookings into the accepted leads list if appropriate
        if (bookingsResult['success'] == true) {
          final List<dynamic> bookingsData = bookingsResult['bookings'] ?? [];
          for (var b in bookingsData) {
            // Check if this booking is already in leads (it should be if it was a lead first)
            // But if it's a direct booking, we might want to add it as a Lead object for display
            final bookingId = b['id'].toString();
            if (!leads.any((l) => l.id == bookingId)) {
              leads.add(Lead(
                id: bookingId,
                title: b['eventType'] ?? 'Booking',
                date: b['bookingDate']?.toString().split(' ')[0] ?? 'TBD',
                time: 'Confirmed',
                location: 'TBD',
                matchScore: 100,
                budget: double.tryParse(b['totalPrice']?.toString() ?? '0.0') ?? 0.0,
                guests: 0,
                responseTime: 'Confirmed',
                clientName: b['clientName'] ?? 'Client',
                clientMessage: b['notes'] ?? '',
                clientImageUrl: 'https://ui-avatars.com/api/?name=${b['clientName'] ?? 'Client'}&background=random',
                isHighValue: false,
                lastActive: 'Confirmed',
                venueName: '',
                venueAddress: '',
                isAccepted: true,
                phoneNumber: b['clientPhone']?.toString(),
              ));
            }
          }
        }

        setState(() {
          _allLeads = leads;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching leads: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allLeads = _allLeads;
    
    // Initial Segment Filtering
    var filteredLeads = allLeads.where((l) => _selectedSegment == 0 ? !l.isAccepted : l.isAccepted).toList();

    // Search Filtering
    if (_searchQuery.isNotEmpty) {
      filteredLeads = filteredLeads.where((l) {
        final query = _searchQuery.toLowerCase();
        return l.title.toLowerCase().contains(query) || 
               l.clientName.toLowerCase().contains(query);
      }).toList();
    }

    // Sorting Logic
    if (_sortBy == 'score') {
      filteredLeads.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    } else if (_sortBy == 'budget') {
      filteredLeads.sort((a, b) => b.budget.compareTo(a.budget));
    } else {
      // Default: Recent (preserving original order for now as mock data doesn't have timestamps)
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildCinematicHeader(context, isDark, filteredLeads.length),
          _buildSegmentSwitcher(isDark),
          if (_isLoading)
            const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.only(top: 40), child: CircularProgressIndicator()))),
          if (!_isLoading && filteredLeads.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Text(
                    'No ${_selectedSegment == 0 ? 'new' : 'active'} leads found',
                    style: GoogleFonts.outfit(color: isDark ? Colors.white38 : Colors.black38),
                  ),
                ),
              ),
            ),
          if (!_isLoading && filteredLeads.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final lead = filteredLeads[index];
                    if (_selectedSegment == 1) {
                      return _buildActiveBookingCard(context, lead, isDark, index);
                    }
                    return _buildPremiumLeadCard(context, lead, isDark, index);
                  },
                  childCount: filteredLeads.length,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCinematicHeader(BuildContext context, bool isDark, int count) {
    return SliverAppBar(
      expandedHeight: 180,
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      elevation: 0,
      pinned: true,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.blurBackground, StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Decorative Background
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary01.withValues(alpha: 0.1),
                ),
              ).animate().scale(duration: const Duration(seconds: 1), curve: Curves.easeOutBack),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isSearching)
                    Text(
                      'Leads Management',
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF1A1A24),
                        letterSpacing: -1,
                      ),
                    ).animate().fadeIn().slideX(begin: -0.1, end: 0),
                  if (_isSearching)
                    Container(
                      height: 50,
                      margin: const EdgeInsets.only(bottom: 8),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
                        decoration: InputDecoration(
                          hintText: 'Search by client or event...',
                          hintStyle: GoogleFonts.outfit(color: isDark ? Colors.white38 : Colors.black38),
                          prefixIcon: Icon(Icons.search_rounded, color: AppColors.primary01),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => setState(() {
                              _isSearching = false;
                              _searchQuery = '';
                              _searchController.clear();
                            }),
                          ),
                          filled: true,
                          fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                        ),
                      ),
                    ).animate().fadeIn().scale(begin: const Offset(0.9, 1), alignment: Alignment.centerRight, curve: Curves.easeOutCubic),
                  const SizedBox(height: 4),
                  if (!_isSearching)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary01.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count ${_selectedSegment == 0 ? 'New' : 'Active'} Leads',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary01,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Last updated 2m ago',
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: const Duration(milliseconds: 200)),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (!_isSearching)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildHeaderAction(Icons.search_rounded, isDark, onTap: () => setState(() => _isSearching = true)),
          ),
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: _buildHeaderAction(Icons.tune_rounded, isDark, onTap: () => _showFilterSheet(context, isDark)),
        ),
      ],
    );
  }

  Widget _buildHeaderAction(IconData icon, bool isDark, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(icon, color: isDark ? Colors.white70 : const Color(0xFF4B5563), size: 22),
      ),
    );
  }

  void _showFilterSheet(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkNeutral01 : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, -5))],
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(color: isDark ? Colors.white24 : Colors.black12, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Sort Leads',
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 20),
            _buildFilterOption('Most Recent', 'recent', Icons.access_time_rounded, isDark),
            _buildFilterOption('Highest Match', 'score', Icons.auto_awesome_rounded, isDark),
            _buildFilterOption('Highest Budget', 'budget', Icons.payments_rounded, isDark),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String title, String value, IconData icon, bool isDark) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary01.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary01 : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05))),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary01 : (isDark ? Colors.white38 : Colors.black38), size: 24),
            const SizedBox(width: 16),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected ? AppColors.primary01 : (isDark ? Colors.white : Colors.black),
              ),
            ),
            const Spacer(),
            if (isSelected) Icon(Icons.check_circle_rounded, color: AppColors.primary01, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentSwitcher(bool isDark) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Container(
          height: 64,
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(22),
          ),
          child: Row(
            children: [
              _buildSegmentItem(0, 'New Leads', isDark),
              _buildSegmentItem(1, 'Active Bookings', isDark),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegmentItem(int index, String label, bool isDark) {
    final isSelected = _selectedSegment == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedSegment = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutQuart,
          decoration: BoxDecoration(
            color: isSelected ? (isDark ? Colors.white : Colors.white) : Colors.transparent,
            borderRadius: BorderRadius.circular(18),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? const Color(0xFF1A1A24)
                    : (isDark ? Colors.white38 : Colors.black38),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPremiumLeadCard(BuildContext context, Lead lead, bool isDark, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkNeutral02 : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.03),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('/lead-details/${lead.id}'),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildClientAvatar(lead),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lead.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF1A1A24),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              lead.clientName,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white38 : Colors.black45,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (lead.isHighValue) _buildPremiumBadge(),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(child: _buildMetric(Icons.calendar_today_rounded, lead.date, isDark)),
                      const SizedBox(width: 8),
                      Flexible(child: _buildMetric(Icons.people_alt_rounded, '${lead.guests} Guests', isDark)),
                      const SizedBox(width: 8),
                      Flexible(child: _buildMetric(Icons.payments_rounded, 'UGX ${lead.budget.toInt()}', isDark)), // Updated currency symbol
                    ],
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      _buildMatchScore(lead.matchScore.toInt()),
                      const Spacer(),
                      _buildQuickAction(
                        isDark ? 'View Details' : 'Details',
                        () => context.push('/lead-details/${lead.id}'),
                        false,
                        isDark,
                      ),
                      const SizedBox(width: 12),
                      _buildQuickAction(
                        'Message',
                        () => context.push('/vendor-chat/${lead.id}?phone=${lead.phoneNumber ?? ''}'),
                        true,
                        isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 600), delay: Duration(milliseconds: (index * 100))).moveY(begin: 20, end: 0, curve: Curves.easeOutQuart);
  }

  Widget _buildActiveBookingCard(BuildContext context, Lead lead, bool isDark, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkNeutral02 : Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(
          color: AppColors.primary01.withValues(alpha: 0.2), // Subtle accent for bookings
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('/active-booking-details/${lead.id}'),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      _buildClientAvatar(lead),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lead.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: isDark ? Colors.white : const Color(0xFF1A1A24),
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.check_circle_rounded, color: Colors.green, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  'Confirmed Booking',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.primary01.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Active',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary01,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildBookingStat(Icons.event_available_rounded, lead.date, 'Date', isDark),
                        _buildBookingStat(Icons.payments_rounded, 'UGX ${lead.budget.toInt()}', 'Total', isDark),
                        _buildBookingStat(Icons.person_pin_circle_rounded, lead.location, 'Venue', isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildQuickAction(
                          'Message Client',
                          () => context.push('/vendor-chat/${lead.id}'),
                          true,
                          isDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      _buildQuickAction(
                        'Details',
                        () => context.push('/active-booking-details/${lead.id}'),
                        false,
                        isDark,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: const Duration(milliseconds: 600), delay: Duration(milliseconds: (index * 100))).moveY(begin: 20, end: 0, curve: Curves.easeOutQuart);
  }

  Widget _buildBookingStat(IconData icon, String value, String label, bool isDark) {
    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: isDark ? Colors.white38 : Colors.black38),
              const SizedBox(width: 4),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white38 : Colors.black38,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A1A24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientAvatar(Lead lead) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        image: DecorationImage(
          image: NetworkImage(lead.clientImageUrl),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildPremiumBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFFF59E0B), const Color(0xFFD97706)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFD97706).withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.star_rounded, color: Colors.white, size: 14),
    );
  }

  Widget _buildMetric(IconData icon, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 14, color: AppColors.primary01),
            const SizedBox(width: 6),
            Text(
              value,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF1A1A24),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildMatchScore(int score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome_rounded, color: Color(0xFF22C55E), size: 14),
          const SizedBox(width: 6),
          Text(
            '$score% Match',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF22C55E),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String label, VoidCallback onTap, bool isPrimary, bool isDark) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isPrimary ? AppColors.primary01 : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: isPrimary ? null : Border.all(color: isDark ? Colors.white24 : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isPrimary ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }
}
