import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge_ai/core/theme/app_colors.dart';
import 'package:eventbridge_ai/core/network/api_service.dart';
import 'package:eventbridge_ai/core/storage/storage_service.dart';
import 'package:eventbridge_ai/core/widgets/app_toast.dart';

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
    final canAddMore = _packages.length < _maxPackages;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A24)),
          onPressed: () => context.pop(),
        ),
        title: Column(
          children: [
            Text(
              'Pricing Packages',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A24),
              ),
            ),
            Text(
              '${_packages.length} of $_maxPackages limit',
              style: GoogleFonts.roboto(
                fontSize: 12,
                color: const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        actions: [
          if (_vendorPlan == 'business_pro')
            Padding(
              padding: const EdgeInsets.only(right: 16, top: 16, bottom: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFFFEDD5)),
                ),
                child: Center(
                  child: Text(
                    'PRO+',
                    style: GoogleFonts.roboto(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Manage your service offerings and pricing for clients to see.',
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            ..._packages.map((p) => Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildPackageCard(p),
                )),
            const SizedBox(height: 32),
            if (canAddMore)
              _buildAddNewButton()
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEF2F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFFECACA)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.lock_rounded, color: Color(0xFFEF4444), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'You have reached your package limit. Upgrade plan to add more.',
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: const Color(0xFF991B1B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildPackageCard(_PackageData pkg) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: pkg.isActive ? Colors.transparent : const Color(0xFFF1F5F9),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
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
                  color: pkg.isActive ? const Color(0xFFECFDF5) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  pkg.isActive ? 'ACTIVE' : 'DRAFT',
                  style: GoogleFonts.roboto(
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    color: pkg.isActive ? const Color(0xFF059669) : const Color(0xFF64748B),
                  ),
                ),
              ),
              PopupMenuButton(
                icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF94A3B8)),
                onSelected: (val) {
                  if (val == 'edit') {
                    _showPackageForm(pkg);
                  } else if (val == 'delete') {
                    _showDeleteConfirmation(pkg);
                  }
                },
                itemBuilder: (context) => [
                  if (_canEdit)
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit Package'),
                    ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete', style: TextStyle(color: Color(0xFFEF4444))),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            pkg.title,
            style: GoogleFonts.roboto(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            pkg.description,
            style: GoogleFonts.roboto(
              fontSize: 14,
              color: const Color(0xFF64748B),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '\$${pkg.price.toStringAsFixed(0)}',
                style: GoogleFonts.roboto(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary01,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAddNewButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFFFEDD5), width: 2),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _showPackageForm(),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_circle_outline_rounded, color: AppColors.primary01, size: 24),
                const SizedBox(width: 12),
                Text(
                  'ADD NEW PACKAGE',
                  style: GoogleFonts.roboto(
                    fontSize: 14,
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
}
