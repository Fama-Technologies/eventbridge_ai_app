import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/shared/widgets/app_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:eventbridge/features/home/presentation/providers/vendor_provider.dart';
import 'package:eventbridge/features/matching/presentation/widgets/match_intake_bottom_sheet.dart';
import 'package:eventbridge/core/storage/storage_service.dart';

class CustomerExplore extends ConsumerStatefulWidget {
  final String? initialQuery;
  final String? initialCategory;

  const CustomerExplore({
    super.key,
    this.initialQuery,
    this.initialCategory,
  });

  @override
  ConsumerState<CustomerExplore> createState() => _CustomerExploreState();
}

class _CustomerExploreState extends ConsumerState<CustomerExplore> {
  final TextEditingController _searchController = TextEditingController();
  
  String? _searchQuery;

  List<String> _recentSearches = [];

  final List<String> _eventTypes = [
    'Wedding', 'Graduation', 'Corporate', 'Birthday', 'Anniversary', 'Concert'
  ];
  
  final List<String> _services = [
    'Photographer', 'DJ', 'Caterer', 'Makeup Artist', 'Florist', 'Venue',
    'Wedding Planners', 'Outdoor Venues', 'Live Bands', 'Photography', 'DJ & Music', 'Decorators',
  ];

  final List<String> _popularCategories = [
    'Catering',
    'Photography',
    'DJ & Music',
    'Decorators',
  ];

  @override
  void initState() {
    super.initState();
    _loadSearchHistory();
    if (widget.initialQuery != null) {
      _searchController.text = widget.initialQuery!;
      // Use microtask to ensure the search happens after the first build
      Future.microtask(() => _performSearch(widget.initialQuery!));
    } else if (widget.initialCategory != null) {
      _searchController.text = widget.initialCategory!;
      Future.microtask(() => _performSearch(widget.initialCategory!));
    }
  }

  void _loadSearchHistory() {
    final history = StorageService().getStringList('search_history') ?? [];
    setState(() {
      _recentSearches = history;
    });
  }

  void _saveSearchQuery(String query) {
    if (query.trim().isEmpty) return;
    final trimmedQuery = query.trim();
    
    // Don't save categories as search history if we want to distinguish
    // But for now, let's save everything the user searches for explicitly
    
    final newHistory = List<String>.from(_recentSearches);
    newHistory.remove(trimmedQuery); // Remove if exists to move to top
    newHistory.insert(0, trimmedQuery);
    
    if (newHistory.length > 10) {
      newHistory.removeLast();
    }
    
    setState(() {
      _recentSearches = newHistory;
    });
    StorageService().setStringList('search_history', newHistory);
  }

  void _clearSearchHistory() {
    setState(() {
      _recentSearches = [];
    });
    StorageService().remove('search_history');
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  void _performSearch(String query) {
    if (query.trim().isEmpty) {
      setState(() => _searchQuery = null);
      return;
    }
    
    final normalized = query.trim().toLowerCase();
    
    // Check if it's an Event Type
    for (final e in _eventTypes) {
      if (e.toLowerCase() == normalized || normalized.contains(e.toLowerCase())) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => MatchIntakeBottomSheet(
            initialEventType: e,
          ),
        );
        return;
      }
    }
    
    // Check if it's a Service/Category
    for (final s in _services) {
      if (s.toLowerCase() == normalized || normalized.contains(s.toLowerCase())) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => MatchIntakeBottomSheet(
            initialService: s,
          ),
        );
        return;
      }
    }
    
    // Check popular categories directly
    for (final p in _popularCategories) {
      if (p.toLowerCase() == normalized) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => MatchIntakeBottomSheet(
            initialService: p,
          ),
        );
        return;
      }
    }
    
    // Not a known category! Treat as a direct Vendor Search.
    _saveSearchQuery(query);
    setState(() {
      _searchQuery = query.trim();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search Bar Area
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey[500], size: 22),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              autofocus: true,
                              textInputAction: TextInputAction.search,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              decoration: InputDecoration(
                                hintText: 'Search for vendors, events...',
                                hintStyle: GoogleFonts.outfit(
                                  color: Colors.grey[500],
                                  fontSize: 15,
                                ),
                                border: InputBorder.none,
                                isDense: true,
                                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              onChanged: (val) {
                                if (val.isEmpty) setState(() => _searchQuery = null);
                              },
                              onSubmitted: _performSearch,
                            ),
                          ),
                          if (_searchController.text.isNotEmpty)
                            GestureDetector(
                              onTap: () {
                                _searchController.clear();
                                setState(() => _searchQuery = null);
                              },
                              child: Icon(Icons.close, color: Colors.grey[500], size: 20),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.primary01.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.map_outlined, color: AppColors.primary01),
                      tooltip: 'Map View',
                      onPressed: () async {
                        double lat = 0.3476;
                        double lng = 32.5825;
                        try {
                          bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
                          if (serviceEnabled) {
                            LocationPermission perm = await Geolocator.checkPermission();
                            if (perm == LocationPermission.denied) {
                              perm = await Geolocator.requestPermission();
                            }
                            if (perm != LocationPermission.denied &&
                                perm != LocationPermission.deniedForever) {
                              final pos = await Geolocator.getCurrentPosition();
                              lat = pos.latitude;
                              lng = pos.longitude;
                            }
                          }
                        } catch (_) {}
                        if (context.mounted) {
                          context.push('/vendor-map?lat=$lat&lng=$lng');
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            
            Expanded(
              child: _searchQuery == null ? _buildExploreHome() : _buildSearchResults(),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSearchResults() {
    final vendorsAsync = ref.watch(recommendedVendorsProvider);
    
    return vendorsAsync.when(
      data: (vendors) {
        final query = _searchQuery!.toLowerCase();
        final results = vendors.where((v) {
          final matchesName = v.businessName.toLowerCase().contains(query);
          final matchesCategory = v.serviceCategories.any((c) => c.toLowerCase().contains(query));
          return matchesName || matchesCategory;
        }).toList();
        
        if (results.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search_off_rounded, size: 64, color: Colors.grey[300]),
                const SizedBox(height: 16),
                Text(
                  'No vendors found for "$_searchQuery"',
                  style: GoogleFonts.outfit(fontSize: 16, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }
        
        return ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          itemCount: results.length,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemBuilder: (context, index) {
            final vendor = results[index];
            return GestureDetector(
              onTap: () => context.push('/vendor-public/${vendor.id}'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.grey[200]!),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        image: vendor.avatarUrl != null ? DecorationImage(
                          image: NetworkImage(vendor.avatarUrl!),
                          fit: BoxFit.cover,
                        ) : null,
                      ),
                      child: vendor.avatarUrl == null
                          ? const Center(child: Icon(Icons.storefront_rounded, color: Colors.grey))
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vendor.businessName,
                            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            vendor.serviceCategories.join(' • '),
                            style: GoogleFonts.outfit(fontSize: 13, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.star_rounded, size: 14, color: AppColors.warningAmber),
                              const SizedBox(width: 4),
                              Text(vendor.rating.toStringAsFixed(1), style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const Center(child: Text('Failed to load search results.')),
    );
  }

  Widget _buildExploreHome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Recent Searches
          if (_recentSearches.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Recent Searches',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                GestureDetector(
                  onTap: _clearSearchHistory,
                  child: Text(
                    'Clear All',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary01,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recentSearches.map((term) {
                return GestureDetector(
                  onTap: () {
                    _searchController.text = term;
                    _performSearch(term);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history, size: 16, color: Colors.grey[500]),
                        const SizedBox(width: 6),
                        Text(
                          term,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
          ],

          // Popular Categories
          Text(
            'Popular Categories',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _popularCategories.length,
            separatorBuilder: (context, index) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final term = _popularCategories[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary01.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.trending_up,
                    size: 18,
                    color: AppColors.primary01,
                  ),
                ),
                title: Text(
                  term,
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
                onTap: () {
                  _searchController.text = term;
                  _performSearch(term);
                },
              );
            },
          ),
        ],
      ),
    );
  }
}
