import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/features/vendors_screen/models/lead_model.dart';
import 'package:eventbridge/core/network/api_service.dart';
import 'package:eventbridge/core/storage/storage_service.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

class VendorSearchScreen extends StatefulWidget {
  const VendorSearchScreen({super.key});

  @override
  State<VendorSearchScreen> createState() => _VendorSearchScreenState();
}

class _VendorSearchScreenState extends State<VendorSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Lead> _allLeads = [];
  List<Lead> _filteredLeads = [];
  bool _isLoading = true;
  String _sortBy = 'recent'; // 'recent', 'score', 'budget'

  @override
  void initState() {
    super.initState();
    _fetchLeads();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchLeads() async {
    try {
      final userId = StorageService().getString('user_id');
      if (userId == null) return;

      final result = await ApiService.instance.getVendorLeads(userId);
      if (mounted && result['success'] == true) {
        final List<dynamic> leadsData = result['leads'] ?? [];
        setState(() {
          _allLeads = leadsData.map((json) => Lead(
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
            clientImageUrl: json['clientImageUrl'] ?? 'https://via.placeholder.com/150',
            isHighValue: json['isHighValue'] ?? false,
            lastActive: json['lastActive'] ?? 'Active now',
            isAccepted: json['isAccepted'] ?? false,
          )).toList();
          _filteredLeads = _allLeads;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching leads: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredLeads = _allLeads.where((lead) {
        return lead.title.toLowerCase().contains(query) ||
               lead.clientName.toLowerCase().contains(query) ||
               lead.location.toLowerCase().contains(query);
      }).toList();
      _applySorting();
    });
  }

  void _applySorting() {
    if (_sortBy == 'score') {
      _filteredLeads.sort((a, b) => b.matchScore.compareTo(a.matchScore));
    } else if (_sortBy == 'budget') {
      _filteredLeads.sort((a, b) => b.budget.compareTo(a.budget));
    } else {
      // Default: Recent (keeping original order)
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: isDark ? Colors.white : Colors.black),
          onPressed: () => context.pop(),
        ),
        title: Text(
          "Search Results",
          style: GoogleFonts.outfit(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: _buildSearchBar(isDark),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredLeads.isEmpty
                    ? _buildEmptyState(isDark)
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                        physics: const BouncingScrollPhysics(),
                        itemCount: _filteredLeads.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: _buildResultCard(context, _filteredLeads[index], isDark),
                          ).animate().fadeIn(delay: (index * 50).ms, duration: 400.ms).slideY(begin: 0.1, end: 0);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkNeutral02 : Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(Icons.search_rounded, color: isDark ? Colors.white60 : Colors.black45),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              style: GoogleFonts.outfit(
                color: isDark ? Colors.white : Colors.black,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: "Search leads, clients...",
                hintStyle: GoogleFonts.outfit(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 16,
                ),
                border: InputBorder.none,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.tune_rounded, color: AppColors.primary01),
            onPressed: () => _showFilterSheet(context, isDark),
          ),
          const SizedBox(width: 8),
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, -5))],
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
              'Sort Results',
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
        setState(() {
          _sortBy = value;
          _applySorting();
        });
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary01.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary01 : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05))),
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

  Widget _buildResultCard(BuildContext context, Lead lead, bool isDark) {
    return GestureDetector(
      onTap: () => context.push('/lead-details/${lead.id}'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkNeutral02 : Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: DecorationImage(
                  image: NetworkImage(lead.clientImageUrl),
                  fit: BoxFit.cover,
                ),
              ),
            ),
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
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Text(
                    lead.clientName,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${lead.matchScore.toInt()}%',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF22C55E),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SvgPicture.asset(
            'assets/icons/megaphone-premium.svg',
            width: 80,
            height: 80,
            colorFilter: const ColorFilter.mode(AppColors.primary01, BlendMode.srcIn),
          ),
          const SizedBox(height: 24),
          Text(
            "No matching results",
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Try adjusting your search or filters",
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
