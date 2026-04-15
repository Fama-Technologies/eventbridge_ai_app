import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/core/network/api_service.dart';
import 'package:eventbridge/core/storage/storage_service.dart';
import 'package:eventbridge/core/widgets/app_toast.dart';
import 'package:flutter_animate/flutter_animate.dart';

class _PackageData {
  String id;
  String title;
  String description;
  double price;
  bool isActive;
  String unit;
  List<String> features;
  String highlightBadge; // 'none', 'popular', 'best_value'

  _PackageData({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.isActive,
    this.unit = 'event',
    this.features = const [],
    this.highlightBadge = 'none',
  });
}

class VendorPackagesScreen extends StatefulWidget {
  const VendorPackagesScreen({super.key});

  @override
  State<VendorPackagesScreen> createState() => _VendorPackagesScreenState();
}

class _VendorPackagesScreenState extends State<VendorPackagesScreen> {
  // Mocking vendor plan: 'pro' or 'business_pro'
  final String _vendorPlan = 'business_pro'; 
  bool _isLoading = false;

  bool _isSearching = false;
  String _searchQuery = '';
  String _sortBy = 'recent'; // 'recent', 'price_high', 'price_low'
  final TextEditingController _searchController = TextEditingController();

  final List<_PackageData> _packages = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  Future<void> _loadPackages() async {
    setState(() => _isLoading = true);
    try {
      final userId = StorageService().getString('user_id');
      if (userId == null) return;

      final response = await ApiService.instance.getVendorProfile(userId);
      if (response['success'] == true) {
        final profile = response['profile'];
        final pkgs = profile['packages'] as List?;
        if (pkgs != null) {
          setState(() {
            _packages.clear();
            for (var p in pkgs) {
              _packages.add(_PackageData(
                id: p['id'].toString(),
                title: p['title'] ?? '',
                description: p['description'] ?? '',
                price: double.tryParse(p['price']?.toString() ?? '') ?? 0.0,
                isActive: p['isActive'] ?? true,
                unit: p['unit'] ?? 'event',
                features: (p['features'] as List?)?.map((e) => e.toString()).toList() ?? [],
                highlightBadge: p['highlightBadge'] ?? 'none',
              ));
            }
          });
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, message: 'Failed to load packages: $e', type: ToastType.error);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _savePackagesToBackend() async {
    setState(() => _isLoading = true);
    try {
      final userId = StorageService().getString('user_id');
      if (userId == null) return;

      final packageList = _packages.map((p) => {
        'title': p.title,
        'description': p.description,
        'price': p.price,
        'isActive': p.isActive,
        'unit': p.unit,
        'features': p.features,
        'highlightBadge': p.highlightBadge,
      }).toList();

      final response = await ApiService.instance.saveVendorPackages(
        userId: userId,
        packages: packageList,
      );

      if (response['success'] == true) {
        if (mounted) {
          AppToast.show(context, message: 'Packages saved successfully', type: ToastType.success);
        }
        _loadPackages(); // Reload to get IDs
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, message: 'Failed to save packages: $e', type: ToastType.error);
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  int get _maxPackages => _vendorPlan == 'business_pro' ? 6 : 3;
  bool get _canEdit => _vendorPlan == 'business_pro';


  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canAddMore = _packages.length < _maxPackages;

    // Apply Filtering
    var displayPackages = List<_PackageData>.from(_packages);
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      displayPackages = displayPackages.where((p) => 
        p.title.toLowerCase().contains(query) ||
        p.description.toLowerCase().contains(query)
      ).toList();
    }
    
    // Apply Sorting
    if (_sortBy == 'price_high') {
      displayPackages.sort((a, b) => b.price.compareTo(a.price));
    } else if (_sortBy == 'price_low') {
      displayPackages.sort((a, b) => a.price.compareTo(b.price));
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 20),
            sliver: SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (!_isSearching)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Packages',
                            style: GoogleFonts.outfit(
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              color: isDark ? Colors.white : Colors.black,
                              letterSpacing: -1,
                            ),
                          ).animate().fadeIn().slideX(begin: -0.1, end: 0, curve: Curves.easeOutQuart),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary01.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_packages.length} of $_maxPackages ACTIVE',
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.primary01,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: const Duration(milliseconds: 100)),
                        ],
                      ),
                    if (_isSearching)
                      Expanded(
                        child: Container(
                          height: 50,
                          margin: const EdgeInsets.only(right: 12),
                          child: TextField(
                            controller: _searchController,
                            autofocus: true,
                            onChanged: (val) => setState(() => _searchQuery = val),
                            style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black, fontSize: 18, fontWeight: FontWeight.w600),
                            decoration: InputDecoration(
                              hintText: 'Search packages...',
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
                      ),
                    Row(
                      children: [
                        if (!_isSearching && _vendorPlan == 'business_pro')
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Text(
                              'PRO+',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ).animate().scale(delay: const Duration(milliseconds: 200), curve: Curves.easeOutBack),
                        if (!_isSearching) ...[
                          _buildHeaderAction(Icons.search_rounded, isDark, onTap: () => setState(() => _isSearching = true)),
                          const SizedBox(width: 8),
                        ],
                        _buildHeaderAction(Icons.tune_rounded, isDark, onTap: () => _showFilterSheet(context, isDark)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
              child: Text(
                'Manage your service offerings and pricing. These will be visible to clients when matching with your profile.',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: isDark ? Colors.white54 : Colors.black54,
                  height: 1.5,
                ),
              ).animate().fadeIn(delay: const Duration(milliseconds: 150)),
            ),
          ),
          if (_isLoading && _packages.isEmpty)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (!_isLoading && displayPackages.isEmpty && _searchQuery.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(top: 80),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.search_off_rounded, size: 60, color: isDark ? Colors.white30 : Colors.black26),
                      const SizedBox(height: 16),
                      Text(
                        'No packages found',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          color: isDark ? Colors.white54 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildPackageCard(displayPackages[index], isDark, index),
                    );
                  },
                  childCount: displayPackages.length,
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 100), // Extra bottom padding for floating nav
              child: canAddMore
                  ? _buildAddNewButton(isDark).animate().fadeIn(delay: Duration(milliseconds: 300 + (_packages.length * 100)))
                  : Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF991B1B).withValues(alpha: 0.1) : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: isDark ? const Color(0xFF991B1B).withValues(alpha: 0.3) : const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lock_rounded, color: isDark ? const Color(0xFFF87171) : const Color(0xFFEF4444), size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'You have reached your package limit. Upgrade plan to add more.',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? const Color(0xFFFCA5A5) : const Color(0xFF991B1B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageCard(_PackageData pkg, bool isDark, int index) {
    // Formatting price with commas manually
    String getFormattedPrice(double p) {
      if (p <= 0) return 'Custom';
      String s = p.toStringAsFixed(0);
      return s.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]},');
    }

    final isBestValue = pkg.highlightBadge == 'best_value';
    final isPopular = pkg.highlightBadge == 'popular';
    final hasBadge = isBestValue || isPopular;

    return Stack(
      children: [
        Container(
          width: double.infinity,
          margin: const EdgeInsets.only(top: 14),
          padding: const EdgeInsets.fromLTRB(26, 36, 26, 26),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF161622) : Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              if (!isDark)
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              if (pkg.isActive && hasBadge)
                BoxShadow(
                  color: const Color(0xFFF97316).withValues(alpha: 0.15),
                  blurRadius: 40,
                  spreadRadius: -10,
                  offset: const Offset(0, 20),
                ),
            ],
            border: Border.all(
              color: pkg.isActive 
                  ? (hasBadge 
                      ? const Color(0xFFF97316).withValues(alpha: 0.8) 
                      : (isDark ? Colors.white12 : Colors.black.withValues(alpha: 0.05)))
                  : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
              width: hasBadge && pkg.isActive ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      pkg.title,
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: PopupMenuButton(
                      icon: Icon(Icons.more_horiz_rounded, color: isDark ? Colors.white54 : const Color(0xFF64748B), size: 28),
                      color: isDark ? AppColors.darkNeutral02 : Colors.white,
                      elevation: 10,
                      shadowColor: Colors.black.withValues(alpha: 0.2),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      onSelected: (val) {
                        if (val == 'delete') {
                          _showDeleteConfirmation(pkg);
                        }
                      },
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.delete_rounded, color: Color(0xFFEF4444), size: 18),
                              ),
                              const SizedBox(width: 14),
                              Text('Delete Package', style: GoogleFonts.outfit(color: const Color(0xFFEF4444), fontWeight: FontWeight.w700, fontSize: 16)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                pkg.description,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: isDark ? Colors.white60 : const Color(0xFF475569),
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withValues(alpha: 0.03) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      pkg.price <= 0 ? 'Custom ' : 'UGX ',
                      style: GoogleFonts.outfit(
                        fontSize: pkg.price <= 0 ? 28 : 18,
                        fontWeight: FontWeight.w900,
                        color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                        letterSpacing: -0.5,
                      ),
                    ),
                    if (pkg.price > 0)
                      Text(
                        getFormattedPrice(pkg.price),
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                          letterSpacing: -1.5,
                          height: 1,
                        ),
                      ),
                    if (pkg.price > 0 && pkg.unit.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4, left: 4),
                        child: Text(
                          ' / ${pkg.unit}',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            color: isDark ? Colors.white54 : const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    if (pkg.price <= 0)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4, left: 4),
                        child: Text(
                          'pricing',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            color: isDark ? Colors.white54 : const Color(0xFF64748B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              // Features List
              if (pkg.features.isNotEmpty)
                ...pkg.features.map((feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF97316).withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_rounded, color: Color(0xFFF97316), size: 14),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              feature,
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                color: isDark ? const Color(0xFFCBD5E1) : const Color(0xFF334155),
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showPackageForm(pkg),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                    foregroundColor: isDark ? Colors.black : Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: Text(
                    'Edit Package Details',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        // Highlight Badge positioning
        if (hasBadge) {
          final isBest = pkg.highlightBadge == 'best';
          final isRecommended = pkg.highlightBadge == 'recommended';
          final isPremium = pkg.highlightBadge == 'premium';
          
          Color badgeColor1;
          Color badgeColor2;
          IconData badgeIcon;
          String badgeText;

          if (isBest) {
            badgeColor1 = const Color(0xFFF97316);
            badgeColor2 = const Color(0xFFEA580C);
            badgeIcon = Icons.star_rounded;
            badgeText = 'BEST CHOICE';
          } else if (isBestValue) {
            badgeColor1 = const Color(0xFF10B981);
            badgeColor2 = const Color(0xFF059669);
            badgeIcon = Icons.auto_awesome_rounded;
            badgeText = 'BEST VALUE';
          } else if (isRecommended) {
            badgeColor1 = const Color(0xFF3B82F6);
            badgeColor2 = const Color(0xFF2563EB);
            badgeIcon = Icons.thumb_up_rounded;
            badgeText = 'RECOMMENDED';
          } else if (isPremium) {
            badgeColor1 = const Color(0xFF8B5CF6);
            badgeColor2 = const Color(0xFF7C3AED);
            badgeIcon = Icons.workspace_premium_rounded;
            badgeText = 'PREMIUM';
          } else {
            // Popular
            badgeColor1 = const Color(0xFFEC4899);
            badgeColor2 = const Color(0xFFDB2777);
            badgeIcon = Icons.local_fire_department_rounded;
            badgeText = 'MOST POPULAR';
          }

          return Positioned(
            top: 0,
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [badgeColor1, badgeColor2]),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: badgeColor1.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(badgeIcon, color: Colors.white, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    badgeText,
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
          
          if (!pkg.isActive && !hasBadge)
             Positioned(
              top: 0,
              right: 24,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Text(
                  'DRAFT',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                    color: isDark ? Colors.white70 : const Color(0xFF475569),
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
      ],
    ).animate().fadeIn(delay: Duration(milliseconds: 200 + (index * 100))).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildAddNewButton(bool isDark) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? AppColors.primary01.withValues(alpha: 0.05) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? AppColors.primary01.withValues(alpha: 0.2) : const Color(0xFFFFEDD5), 
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showPackageForm(),
          borderRadius: BorderRadius.circular(24),
          splashColor: AppColors.primary01.withValues(alpha: 0.1),
          highlightColor: AppColors.primary01.withValues(alpha: 0.05),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_rounded, color: AppColors.primary01, size: 28),
                const SizedBox(width: 12),
                Text(
                  'CREATE NEW PACKAGE',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColors.primary01,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showPackageForm([_PackageData? editingPackage]) {
    final isEditing = editingPackage != null;
    final titleCtrl = TextEditingController(text: editingPackage?.title ?? '');
    final descCtrl = TextEditingController(text: editingPackage?.description ?? '');
    final priceCtrl = TextEditingController(text: editingPackage?.price.toString() ?? '');
    final unitCtrl = TextEditingController(text: editingPackage?.unit ?? 'event');
    final featureCtrl = TextEditingController();
    List<String> featuresList = List<String>.from(editingPackage?.features ?? []);
    String selectedBadge = editingPackage?.highlightBadge ?? 'none';
    
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.92,
              decoration: BoxDecoration(
                color: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 40, offset: const Offset(0, -10)),
                ],
              ),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkNeutral01 : Colors.white,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          isEditing ? 'Edit Package' : 'Create Package',
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                            letterSpacing: -0.5,
                          ),
                        ),
                        Material(
                          color: isDark ? Colors.white10 : const Color(0xFFF1F5F9),
                          shape: const CircleBorder(),
                          child: InkWell(
                            onTap: () => context.pop(),
                            customBorder: const CircleBorder(),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Icon(Icons.close_rounded, size: 24, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Content
                  Expanded(
                    child: ListView(
                      padding: EdgeInsets.fromLTRB(
                        24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 100,
                      ),
                      physics: const BouncingScrollPhysics(),
                      children: [
                        _buildTextField(titleCtrl, 'Package Title', 'e.g. Premium Event Coverage', isDark),
                        const SizedBox(height: 24),
                        _buildTextField(descCtrl, 'Description', 'What exactly is included in this package?', isDark, maxLines: 4),
                        const SizedBox(height: 24),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildTextField(priceCtrl, 'Price (UGX)', 'e.g. 500000', isDark, isNumber: true)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildTextField(unitCtrl, 'Pricing Unit', 'e.g. event, hour', isDark)),
                          ],
                        ),
                        const SizedBox(height: 32),
                        
                        // ── Dynamic Features List ──
                        Text(
                          'Features Included',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: featureCtrl,
                                style: GoogleFonts.outfit(
                                  color: isDark ? Colors.white : Colors.black,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16,
                                ),
                                decoration: InputDecoration(
                                  hintText: 'e.g. Bridal Table Décor',
                                  hintStyle: GoogleFonts.outfit(color: isDark ? Colors.white30 : Colors.black38, fontWeight: FontWeight.w400),
                                  filled: true,
                                  fillColor: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: isDark ? BorderSide.none : BorderSide(color: const Color(0xFFE2E8F0)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: const BorderSide(color: Color(0xFFF97316), width: 2),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                ),
                                onSubmitted: (val) {
                                  if (val.trim().isNotEmpty) {
                                    setSheetState(() {
                                      featuresList.add(val.trim());
                                      featureCtrl.clear();
                                    });
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Material(
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                              borderRadius: BorderRadius.circular(16),
                              elevation: 4,
                              shadowColor: (isDark ? Colors.white : const Color(0xFF0F172A)).withValues(alpha: 0.3),
                              child: InkWell(
                                borderRadius: BorderRadius.circular(16),
                                onTap: () {
                                  if (featureCtrl.text.trim().isNotEmpty) {
                                    setSheetState(() {
                                      featuresList.add(featureCtrl.text.trim());
                                      featureCtrl.clear();
                                    });
                                  }
                                },
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Icon(Icons.add_rounded, color: isDark ? Colors.black : Colors.white, size: 24),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        // Display added features as removable chips
                        if (featuresList.isNotEmpty)
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: featuresList.asMap().entries.map((entry) {
                              final idx = entry.key;
                              final feature = entry.value;
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                decoration: BoxDecoration(
                                  color: isDark ? const Color(0xFFF97316).withValues(alpha: 0.1) : const Color(0xFFFFF7ED),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: Color(0xFFF97316), size: 16),
                                    const SizedBox(width: 10),
                                    Flexible(
                                      child: Text(
                                        feature,
                                        style: GoogleFonts.outfit(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    GestureDetector(
                                      onTap: () => setSheetState(() => featuresList.removeAt(idx)),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(Icons.close_rounded, size: 14, color: isDark ? Colors.white70 : const Color(0xFF64748B)),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ).animate().fadeIn(),
                        if (featuresList.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Text(
                              'No features added yet. Type above and tap + to add.',
                              style: GoogleFonts.outfit(fontSize: 14, color: isDark ? Colors.white30 : Colors.black38),
                            ),
                          ),
                        
                        const SizedBox(height: 32),
                        Text(
                          'Highlight Badge',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isDark ? Colors.transparent : const Color(0xFFE2E8F0)),
                          ),
                          child: DropdownButtonFormField<String>(
                            initialValue: selectedBadge,
                            decoration: InputDecoration(
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            ),
                            icon: Icon(Icons.keyboard_arrow_down_rounded, color: isDark ? Colors.white54 : const Color(0xFF64748B)),
                            dropdownColor: isDark ? AppColors.darkNeutral02 : Colors.white,
                            style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black, fontSize: 16, fontWeight: FontWeight.w600),
                            items: const [
                              DropdownMenuItem(value: 'none', child: Text('None')),
                              DropdownMenuItem(value: 'popular', child: Text('Most Popular')),
                              DropdownMenuItem(value: 'best', child: Text('Best Choice')),
                              DropdownMenuItem(value: 'best_value', child: Text('Best Value')),
                              DropdownMenuItem(value: 'recommended', child: Text('Recommended')),
                              DropdownMenuItem(value: 'premium', child: Text('Premium')),
                            ],
                            onChanged: (val) {
                              if (val != null) {
                                setSheetState(() => selectedBadge = val);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Pinned Bottom Action Bar
                  Container(
                    padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).viewInsets.bottom + 24),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkNeutral01 : Colors.white,
                      boxShadow: [
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4)),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final priceText = priceCtrl.text.replaceAll(',', '');
                          final price = double.tryParse(priceText) ?? 0;
                          if (titleCtrl.text.isEmpty) {
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
                                      child: const Icon(Icons.error_rounded, color: Colors.white, size: 16),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text('Please enter a package title.', style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                                    ),
                                  ],
                                ),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: const Color(0xFFEF4444),
                                elevation: 10,
                                margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              ),
                            );
                            return;
                          }
                              
                          setState(() {
                            if (isEditing) {
                              editingPackage.title = titleCtrl.text;
                              editingPackage.description = descCtrl.text;
                              editingPackage.price = price;
                              editingPackage.unit = unitCtrl.text;
                              editingPackage.features = featuresList;
                              editingPackage.highlightBadge = selectedBadge;
                            } else {
                              _packages.add(_PackageData(
                                id: DateTime.now().millisecondsSinceEpoch.toString(),
                                title: titleCtrl.text,
                                description: descCtrl.text,
                                price: price,
                                isActive: true,
                                unit: unitCtrl.text,
                                features: featuresList,
                                highlightBadge: selectedBadge,
                              ));
                            }
                          });
                          context.pop();
                          _savePackagesToBackend();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF97316),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                          elevation: 10,
                          shadowColor: const Color(0xFFF97316).withValues(alpha: 0.4),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        child: Text(
                          isEditing ? 'SAVE CHANGES' : 'CREATE PACKAGE',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }
        );
      },
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
              'Sort Packages',
              style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black),
            ),
            const SizedBox(height: 20),
            _buildFilterOption('Most Recent', 'recent', Icons.access_time_rounded, isDark),
            _buildFilterOption('Highest Price', 'price_high', Icons.arrow_upward_rounded, isDark),
            _buildFilterOption('Lowest Price', 'price_low', Icons.arrow_downward_rounded, isDark),
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
            if (isSelected) const Icon(Icons.check_circle_rounded, color: AppColors.primary01, size: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, String hint, bool isDark, {int maxLines = 1, bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: GoogleFonts.outfit(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(color: isDark ? Colors.white30 : Colors.black38, fontWeight: FontWeight.w400),
            filled: true,
            fillColor: isDark ? Colors.white.withValues(alpha: 0.03) : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: isDark ? BorderSide.none : BorderSide(color: const Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFF97316), width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          ),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(_PackageData pkg) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.darkNeutral01 : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Delete Package',
            style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black),
          ),
          content: Text(
            'Are you sure you want to delete "${pkg.title}"? This action cannot be undone and clients will no longer see it.',
            style: GoogleFonts.outfit(color: isDark ? Colors.white70 : Colors.black87, fontSize: 16),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: Text('Cancel', style: GoogleFonts.outfit(color: isDark ? Colors.white54 : Colors.black54, fontWeight: FontWeight.w600, fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() => _packages.remove(pkg));
                context.pop();
                _savePackagesToBackend();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEF4444),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text('Delete', style: GoogleFonts.outfit(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ],
        );
      },
    );
  }
}
