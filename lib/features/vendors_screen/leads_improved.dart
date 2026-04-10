// This file shows the REFACTORED leads screen using new design components
// Key improvements:
// 1. Consistent spacing (8pt grid via SpacingTokens)
// 2. Reusable card components (PremiumLeadCard, SecondaryButton)
// 3. Clean, readable code (less duplication)
// 4. Better visual hierarchy

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/core/theme/design_tokens.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge/core/storage/storage_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:eventbridge/features/vendors_screen/models/lead_model.dart';
import 'package:eventbridge/features/vendors_screen/widgets/lead_details_bottom_sheet.dart';
import 'package:eventbridge/features/vendors_screen/widgets/vendor_card_components.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventbridge/features/shared/providers/shared_lead_state.dart';

class LeadsScreenImproved extends ConsumerStatefulWidget {
  const LeadsScreenImproved({super.key});

  @override
  ConsumerState<LeadsScreenImproved> createState() =>
      _LeadsScreenImprovedState();
}

class _LeadsScreenImprovedState extends ConsumerState<LeadsScreenImproved> {
  int _selectedSegment = 0;
  bool _isSearching = false;
  String _searchQuery = '';
  String _sortBy = 'recent';
  final TextEditingController _searchController = TextEditingController();
  bool _isLoading = true;

  Future<void> _openVendorChat(BuildContext context, Lead lead) async {
    var customerId = lead.customerId?.trim() ?? '';
    final vendorId = StorageService().getString('user_id') ?? '';
    if (vendorId.isEmpty) return;

    debugPrint(
      '[LeadsScreen] Opening chat for lead ${lead.id}: '
      'customerId="$customerId", clientName="${lead.clientName}"',
    );

    // If customerId is missing, try to fetch it from the API before giving up
    if (customerId.isEmpty) {
      debugPrint('[LeadsScreen] customerId empty — attempting API enrichment...');
      final enriched = await ref
          .read(sharedLeadStateProvider.notifier)
          .enrichLeadCustomerId(lead.id);
      if (enriched != null && enriched.isNotEmpty) {
        customerId = enriched;
        debugPrint('[LeadsScreen] Enriched customerId: $customerId');
      }
    }

    if (customerId.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Cannot start chat — customer info unavailable for this lead. '
              'Please refresh and try again.',
            ),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    final lookupKey = '${customerId}_$vendorId';
    if (context.mounted) {
      context.push(
        '/vendor-chat/$lookupKey'
        '?phone=${Uri.encodeComponent(lead.phoneNumber ?? '')}'
        '&leadTitle=${Uri.encodeComponent(lead.title)}'
        '&leadDate=${Uri.encodeComponent(lead.date)}'
        '&otherUserName=${Uri.encodeComponent(lead.clientName)}'
        '&customerId=$customerId',
      );
    }
  }

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
    setState(() {
      _isLoading = true;
    });

    try {
      final userId = StorageService().getString('user_id');
      if (userId == null) return;

      await ref.read(sharedLeadStateProvider.notifier).fetchLeads(userId);

      if (mounted) setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Error fetching leads: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allLeads = ref.watch(sharedLeadStateProvider);

    // Filter leads by segment
    var filteredLeads = allLeads.where((l) {
      final isBooked = l.isAccepted ||
          l.status == 'booked' ||
          l.status == 'confirmed' ||
          l.status == 'CONFIRMED';
      return _selectedSegment == 0 ? !isBooked : isBooked;
    }).toList();

    // Search filter
    if (_searchQuery.isNotEmpty) {
      filteredLeads = filteredLeads.where((l) {
        final query = _searchQuery.toLowerCase();
        return l.title.toLowerCase().contains(query) ||
            l.clientName.toLowerCase().contains(query);
      }).toList();
    }

    // Sorting
    if (_sortBy == 'score') {
      filteredLeads.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    } else if (_sortBy == 'budget') {
      filteredLeads.sort((a, b) => b.budget.compareTo(a.budget));
    }

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.backgroundDark
          : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // Header with search
          _buildHeader(context, isDark, filteredLeads.length),

          // Segment switcher
          _buildSegmentSwitcher(isDark),

          // Loading state
          if (_isLoading)
            const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.only(top: SpacingTokens.xxxl),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),

          // Empty state
          if (!_isLoading && filteredLeads.isEmpty)
            SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: SpacingTokens.xxxl),
                  child: Text(
                    'No ${_selectedSegment == 0 ? 'new' : 'active'} leads found',
                    style: GoogleFonts.outfit(
                      color: isDark ? Colors.white38 : Colors.black38,
                    ),
                  ),
                ),
              ),
            ),

          // Leads list
          if (!_isLoading && filteredLeads.isNotEmpty)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                SpacingTokens.xxl,
                0,
                SpacingTokens.xxl,
                SpacingTokens.huge,
              ),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final lead = filteredLeads[index];
                  if (_selectedSegment == 1) {
                    return _buildActiveBookingCard(
                      context,
                      lead,
                      isDark,
                      index,
                    );
                  }
                  return _buildNewLeadCard(context, lead, isDark, index);
                }, childCount: filteredLeads.length),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, bool isDark, int count) {
    return SliverAppBar(
      expandedHeight: 180,
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      elevation: 0,
      pinned: true,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [
          StretchMode.blurBackground,
          StretchMode.zoomBackground,
        ],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Decorative circle
            Positioned(
              top: -50,
              right: -50,
              child:
                  Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primary01.withValues(alpha: 0.1),
                    ),
                  ).animate().scale(
                    duration: const Duration(seconds: 1),
                    curve: Curves.easeOutBack,
                  ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                SpacingTokens.xxl,
                0,
                SpacingTokens.xxl,
                SpacingTokens.lg,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (!_isSearching)
                    Text(
                      'Leads',
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
                      margin: const EdgeInsets.only(bottom: SpacingTokens.lg),
                      child: TextField(
                        controller: _searchController,
                        autofocus: true,
                        onChanged: (val) => setState(() => _searchQuery = val),
                        style: GoogleFonts.outfit(
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search...',
                          hintStyle: GoogleFonts.outfit(
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: AppColors.primary01,
                          ),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () => setState(() {
                              _isSearching = false;
                              _searchQuery = '';
                              _searchController.clear();
                            }),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : Colors.black.withValues(alpha: 0.03),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(
                              RadiusTokens.lg,
                            ),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: SpacingTokens.lg,
                          ),
                        ),
                      ),
                    ).animate().fadeIn().scale(
                      begin: const Offset(0.9, 1),
                      alignment: Alignment.centerRight,
                      curve: Curves.easeOutCubic,
                    ),
                  Gaps.sm,
                  if (!_isSearching)
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: SpacingTokens.md,
                            vertical: SpacingTokens.xs,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary01.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              RadiusTokens.md,
                            ),
                          ),
                          child: Text(
                            '$count ${_selectedSegment == 0 ? 'New' : 'Active'}',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary01,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(
                      delay: const Duration(milliseconds: 200),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (!_isSearching)
          Padding(
            padding: const EdgeInsets.only(right: SpacingTokens.md),
            child: _buildHeaderButton(
              Icons.search_rounded,
              isDark,
              onTap: () => setState(() => _isSearching = true),
            ),
          ),
        Padding(
          padding: const EdgeInsets.only(right: SpacingTokens.lg),
          child: _buildHeaderButton(
            Icons.tune_rounded,
            isDark,
            onTap: () => _showFilterSheet(context, isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderButton(IconData icon, bool isDark, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(RadiusTokens.lg),
        ),
        child: Icon(
          icon,
          color: isDark ? Colors.white70 : const Color(0xFF4B5563),
          size: 22,
        ),
      ),
    );
  }

  Widget _buildSegmentSwitcher(bool isDark) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: SpacingTokens.xxl,
          vertical: SpacingTokens.xl,
        ),
        child: Container(
          height: 64,
          padding: const EdgeInsets.all(SpacingTokens.sm),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(RadiusTokens.xxl),
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
            color: isSelected
                ? (isDark ? Colors.white : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(RadiusTokens.xl),
            boxShadow: isSelected
                ? [ShadowTokens.getShadow(4, isDark: isDark)]
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

  Widget _buildNewLeadCard(
    BuildContext context,
    Lead lead,
    bool isDark,
    int index,
  ) {
    return PremiumLeadCard(
          clientImage: lead.clientImageUrl,
          clientName: lead.clientName,
          leadTitle: lead.title,
          date: lead.date,
          guestCount: lead.guests,
          budget: lead.budget,
          isHighValue: lead.isHighValue,
          isDark: isDark,
          onTap: () {
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => LeadDetailsBottomSheet(leadId: lead.id),
            );
          },
          trailingWidget: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Expanded(
                child: SecondaryButton(
                  label: 'Details',
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) =>
                          LeadDetailsBottomSheet(leadId: lead.id),
                    );
                  },
                  isDark: isDark,
                ),
              ),
              Gaps.hMd,
              Expanded(
                child: PrimaryButton(
                  label: 'Message',
                  onTap: () => _openVendorChat(context, lead),
                  isDark: isDark,
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(
          duration: const Duration(milliseconds: 600),
          delay: Duration(milliseconds: index * 100),
        )
        .moveY(begin: 20, end: 0, curve: Curves.easeOutQuart);
  }

  Widget _buildActiveBookingCard(
    BuildContext context,
    Lead lead,
    bool isDark,
    int index,
  ) {
    return Container(
          margin: const EdgeInsets.only(bottom: SpacingTokens.lg),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkNeutral02 : Colors.white,
            borderRadius: BorderRadius.circular(RadiusTokens.round),
            border: Border.all(
              color: AppColors.primary01.withValues(alpha: 0.2),
              width: 1.5,
            ),
            boxShadow: [ShadowTokens.getShadow(8, isDark: isDark)],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(RadiusTokens.round),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push('/active-booking-details/${lead.id}'),
                child: Padding(
                  padding: const EdgeInsets.all(SpacingTokens.xxl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(
                                RadiusTokens.lg,
                              ),
                              image: DecorationImage(
                                image: NetworkImage(lead.clientImageUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Gaps.hLg,
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lead.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : Colors.black,
                                  ),
                                ),
                                Gaps.xs,
                                Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.green,
                                      size: 14,
                                    ),
                                    Gaps.hXs,
                                    Text(
                                      'Confirmed',
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
                          StatusBadge(
                            label: 'Active',
                            backgroundColor: AppColors.primary01.withValues(
                              alpha: 0.1,
                            ),
                            textColor: AppColors.primary01,
                          ),
                        ],
                      ),
                      Gaps.xl,
                      // Stats container
                      Container(
                        padding: const EdgeInsets.all(SpacingTokens.lg),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.03)
                              : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(RadiusTokens.lg),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildStat(
                              Icons.event_available_rounded,
                              'Date',
                              lead.date,
                              isDark,
                            ),
                            _buildStat(
                              Icons.payments_rounded,
                              'Total',
                              'UGX ${lead.budget.toInt()}',
                              isDark,
                            ),
                            _buildStat(
                              Icons.location_on_rounded,
                              'Venue',
                              lead.location,
                              isDark,
                            ),
                          ],
                        ),
                      ),
                      Gaps.xl,
                      // Actions
                      Row(
                        children: [
                          Expanded(
                            child: PrimaryButton(
                              label: 'Message Client',
                              onTap: () => _openVendorChat(context, lead),
                              isDark: isDark,
                            ),
                          ),
                          Gaps.hMd,
                          Expanded(
                            child: SecondaryButton(
                              label: 'Details',
                              onTap: () => context.push(
                                '/active-booking-details/${lead.id}',
                              ),
                              isDark: isDark,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(
          duration: const Duration(milliseconds: 600),
          delay: Duration(milliseconds: index * 100),
        )
        .moveY(begin: 20, end: 0, curve: Curves.easeOutQuart);
  }

  Widget _buildStat(IconData icon, String label, String value, bool isDark) {
    return Flexible(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 12,
                color: isDark ? Colors.white38 : Colors.black38,
              ),
              Gaps.hXs,
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
          Gaps.xs,
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A1A24),
            ),
          ),
        ],
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
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(RadiusTokens.round),
          ),
          boxShadow: [ShadowTokens.getShadow(12, isDark: isDark)],
        ),
        padding: const EdgeInsets.all(SpacingTokens.xxl),
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
            Gaps.xl,
            Text(
              'Sort Leads',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            Gaps.lg,
            _buildFilterOption(
              'Most Recent',
              'recent',
              Icons.access_time_rounded,
              isDark,
            ),
            _buildFilterOption(
              'Highest Match',
              'score',
              Icons.auto_awesome_rounded,
              isDark,
            ),
            _buildFilterOption(
              'Highest Budget',
              'budget',
              Icons.payments_rounded,
              isDark,
            ),
            Gaps.xxxl,
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(
    String title,
    String value,
    IconData icon,
    bool isDark,
  ) {
    final isSelected = _sortBy == value;
    return GestureDetector(
      onTap: () {
        setState(() => _sortBy = value);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: SpacingTokens.md),
        padding: const EdgeInsets.all(SpacingTokens.lg),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary01.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(RadiusTokens.lg),
          border: Border.all(
            color: isSelected
                ? AppColors.primary01
                : (isDark
                      ? Colors.white10
                      : Colors.black.withValues(alpha: 0.05)),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected
                  ? AppColors.primary01
                  : (isDark ? Colors.white38 : Colors.black38),
              size: 24,
            ),
            Gaps.hLg,
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                color: isSelected
                    ? AppColors.primary01
                    : (isDark ? Colors.white : Colors.black),
              ),
            ),
            const Spacer(),
            if (isSelected)
              Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary01,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }
}
