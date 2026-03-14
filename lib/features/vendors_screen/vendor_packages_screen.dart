import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge_ai/core/theme/app_colors.dart';
import 'package:eventbridge_ai/core/network/api_service.dart';
import 'package:eventbridge_ai/core/storage/storage_service.dart';
import 'package:eventbridge_ai/core/widgets/app_toast.dart';
import 'package:flutter_animate/flutter_animate.dart';

class _PackageData {
  String id;
  String title;
  String description;
  double price;
  bool isActive;

  _PackageData({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.isActive,
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

  final List<_PackageData> _packages = [];

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
                price: (p['price'] is num) ? p['price'].toDouble() : 0.0,
                isActive: p['isActive'] ?? true,
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

  void _showPackageForm([_PackageData? editingPackage]) {
    final isEditing = editingPackage != null;
    final titleCtrl = TextEditingController(text: editingPackage?.title ?? '');
    final descCtrl = TextEditingController(text: editingPackage?.description ?? '');
    final priceCtrl = TextEditingController(text: editingPackage?.price.toString() ?? '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Edit Package' : 'Add New Package',
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A1A24),
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField(titleCtrl, 'Package Title', 'e.g. Starter Package'),
              const SizedBox(height: 16),
              _buildTextField(descCtrl, 'Description', 'What is included?', maxLines: 3),
              const SizedBox(height: 16),
              _buildTextField(priceCtrl, 'Price (USD)', 'e.g. 500', isNumber: true),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final price = double.tryParse(priceCtrl.text) ?? 0;
                    if (titleCtrl.text.isEmpty || price <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter valid details.')),
                      );
                      return;
                    }
                    setState(() {
                      if (isEditing) {
                        editingPackage.title = titleCtrl.text;
                        editingPackage.description = descCtrl.text;
                        editingPackage.price = price;
                      } else {
                        _packages.add(_PackageData(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: titleCtrl.text,
                          description: descCtrl.text,
                          price: price,
                          isActive: true,
                        ));
                      }
                    });
                    context.pop();
                    _savePackagesToBackend();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary01,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    isEditing ? 'Save Changes' : 'Create Package',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showDeleteConfirmation(_PackageData pkg) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Delete Package?',
            style: GoogleFonts.roboto(fontWeight: FontWeight.bold),
          ),
          content: Text('Are you sure you want to delete "${pkg.title}"? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280))),
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
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, String hint, {int maxLines = 1, bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF1A1A24),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
            filled: true,
            fillColor: const Color(0xFFF3F4F6),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canAddMore = _packages.length < _maxPackages;

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
                    if (_vendorPlan == 'business_pro')
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildPackageCard(_packages[index], isDark, index),
                    );
                  },
                  childCount: _packages.length,
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
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkNeutral01 : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: pkg.isActive 
              ? AppColors.primary01.withValues(alpha: isDark ? 0.3 : 0.5)
              : (isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: pkg.isActive 
                ? AppColors.primary01.withValues(alpha: isDark ? 0.1 : 0.05)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: pkg.isActive 
                      ? (isDark ? const Color(0xFF059669).withValues(alpha: 0.2) : const Color(0xFFECFDF5))
                      : (isDark ? Colors.white10 : const Color(0xFFF1F5F9)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  pkg.isActive ? 'ACTIVE' : 'DRAFT',
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: pkg.isActive 
                        ? (isDark ? const Color(0xFF34D399) : const Color(0xFF059669))
                        : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                    letterSpacing: 1,
                  ),
                ),
              ),
              PopupMenuButton(
                icon: Icon(Icons.more_horiz_rounded, color: isDark ? Colors.white54 : const Color(0xFF94A3B8)),
                color: isDark ? AppColors.darkNeutral02 : Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: (val) {
                  if (val == 'edit') {
                    _showPackageForm(pkg);
                  } else if (val == 'delete') {
                    _showDeleteConfirmation(pkg);
                  }
                },
                itemBuilder: (context) => [
                  if (_canEdit)
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
                          const SizedBox(width: 12),
                          Text('Edit Package', style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_rounded, color: Color(0xFFEF4444), size: 20),
                        const SizedBox(width: 12),
                        Text('Delete', style: GoogleFonts.outfit(color: const Color(0xFFEF4444), fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            pkg.title,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF1A1A24),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            pkg.description,
            style: GoogleFonts.outfit(
              fontSize: 15,
              color: isDark ? Colors.white60 : const Color(0xFF4B5563),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Price',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white38 : Colors.black38,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'USh ${pkg.price.toStringAsFixed(0)}', // Updated to USh
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      color: AppColors.primary01,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkNeutral01 : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 20, offset: const Offset(0, -5)),
            ],
          ),
          padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24,
          ),
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
                isEditing ? 'Edit Package' : 'Create Package',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : Colors.black,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              _buildTextField(titleCtrl, 'Package Title', 'e.g. Premium Event Coverage', isDark),
              const SizedBox(height: 20),
              _buildTextField(descCtrl, 'Description', 'What exactly is included in this package?', isDark, maxLines: 4),
              const SizedBox(height: 20),
              _buildTextField(priceCtrl, 'Price (USh)', 'e.g. 500000', isDark, isNumber: true),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    final price = double.tryParse(priceCtrl.text) ?? 0;
                    if (titleCtrl.text.isEmpty || price <= 0) {
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
                                child: Text('Please enter valid package details.', style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
                              ),
                            ],
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: const Color(0xFFEF4444), // Error Red
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
                      } else {
                        _packages.add(_PackageData(
                          id: DateTime.now().millisecondsSinceEpoch.toString(),
                          title: titleCtrl.text,
                          description: descCtrl.text,
                          price: price,
                          isActive: true,
                        ));
                      }
                    });
                    context.pop();
                    _savePackagesToBackend();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary01,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    elevation: 10,
                    shadowColor: AppColors.primary01.withValues(alpha: 0.4),
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
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTextField(TextEditingController ctrl, String label, String hint, bool isDark, {int maxLines = 1, bool isNumber = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white70 : Colors.black87,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: isNumber ? TextInputType.number : TextInputType.text,
          style: GoogleFonts.outfit(
            color: isDark ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(color: isDark ? Colors.white30 : Colors.black38, fontWeight: FontWeight.w400),
            filled: true,
            fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
