import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/core/network/api_service.dart';
import 'package:eventbridge/core/storage/storage_service.dart';
import 'package:eventbridge/core/widgets/app_toast.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class PromotionalAdsScreen extends StatefulWidget {
  const PromotionalAdsScreen({super.key});

  @override
  State<PromotionalAdsScreen> createState() => _PromotionalAdsScreenState();
}

class _PromotionalAdsScreenState extends State<PromotionalAdsScreen> {
  bool _isLoading = true;
  List<dynamic> _ads = [];
  int _maxAds = 0;
  String _planName = 'Free';
  
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final userId = StorageService().getString('user_id');
      if (userId == null) return;

      // 1. Fetch Plan Limits
      final profile = await ApiService.instance.getVendorProfile(userId);
      if (profile['success'] == true) {
        final plan = (profile['profile']['subscriptionPlan'] ?? 'free').toString().toLowerCase();
        setState(() {
          _planName = profile['profile']['subscriptionPlan'] ?? 'Free';
          if (plan == 'business_pro') {
            _maxAds = 4;
          } else if (plan == 'pro') {
            _maxAds = 2;
          } else {
            _maxAds = 0;
          }
        });
      }

      // 2. Fetch Ads
      final result = await ApiService.instance.getVendorAds(userId);
      if (mounted && result['success'] == true) {
        setState(() {
          _ads = result['ads'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading ads: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAddAdSheet() {
    if (_ads.length >= _maxAds && _maxAds > 0) {
      AppToast.show(context, message: 'Monthly limit reached! Upgrade or wait for next cycle.', type: ToastType.error);
      return;
    }
    if (_maxAds == 0) {
      AppToast.show(context, message: 'Free plan does not support promotions. Please upgrade.', type: ToastType.warning);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AddAdBottomSheet(
        onSuccess: () {
          Navigator.pop(context);
          _loadData();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text(
          'Promotional Ads',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: isDark ? Colors.white : Colors.black,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAdSheet,
        backgroundColor: AppColors.primary01,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Post New Ad', style: GoogleFonts.outfit(fontWeight: FontWeight.w600, color: Colors.white)),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary01))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildQuotaCard(isDark),
                  const SizedBox(height: 32),
                  Text(
                    'Active Promotions',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (_ads.isEmpty)
                    _buildEmptyState(isDark)
                  else
                    ..._ads.map((ad) => _buildAdCard(ad, isDark)).toList(),
                  const SizedBox(height: 80),
                ],
              ),
            ),
    );
  }

  Widget _buildQuotaCard(bool isDark) {
    final used = _ads.length;
    final progress = _maxAds > 0 ? (used / _maxAds) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Monthly Quota',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$_planName Plan',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary01,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary01.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$used / $_maxAds used',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary01,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
              valueColor: const AlwaysStoppedAnimation(AppColors.primary01),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Your promotional ads are shown to customers on the home screen. Quota resets every billing cycle.',
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdCard(dynamic ad, bool isDark) {
    final title = ad['title'] ?? 'Promotion';
    final imageUrl = ad['media_url'] ?? '';
    final expiresAt = ad['expires_at'] != null ? DateTime.tryParse(ad['expires_at'].toString()) : null;
    final isActive = ad['is_active'] == true && (expiresAt == null || expiresAt.isAfter(DateTime.now()));

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: AspectRatio(
              aspectRatio: 21 / 9,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(color: Colors.grey[300]),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        expiresAt != null 
                            ? 'Expires ${DateFormat('MMM dd, yyyy').format(expiresAt)}'
                            : 'No expiry',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: isDark ? Colors.white38 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    isActive ? 'ACTIVE' : 'EXPIRED',
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.green : Colors.red,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(PhosphorIconsRegular.megaphone, size: 64, color: isDark ? Colors.white24 : Colors.black12),
          const SizedBox(height: 16),
          Text(
            'No promotions running',
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}

class _AddAdBottomSheet extends StatefulWidget {
  final VoidCallback onSuccess;
  const _AddAdBottomSheet({required this.onSuccess});

  @override
  State<_AddAdBottomSheet> createState() => _AddAdBottomSheetState();
}

class _AddAdBottomSheetState extends State<_AddAdBottomSheet> {
  final _titleController = TextEditingController();
  final _placeController = TextEditingController();
  File? _imageFile;
  bool _isSubmitting = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _submit() async {
    if (_titleController.text.isEmpty || _imageFile == null) {
      AppToast.show(context, message: 'Title and Image are required', type: ToastType.warning);
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final userId = StorageService().getString('user_id');
      if (userId == null) return;

      // 1. Upload Image
      final uploadRes = await ApiService.instance.uploadImage(_imageFile!);
      if (uploadRes['success'] != true) throw Exception('Image upload failed');
      final imageUrl = uploadRes['url'];

      // 2. Submit Ad
      final result = await ApiService.instance.postVendorAd(
        userId: userId,
        title: _titleController.text,
        imageUrl: imageUrl,
        place: _placeController.text,
      );

      if (result['success'] == true) {
        AppToast.show(context, message: 'Promotion posted successfully!', type: ToastType.success);
        widget.onSuccess();
      } else {
        throw Exception(result['message'] ?? 'Submission failed');
      }
    } catch (e) {
      AppToast.show(context, message: e.toString(), type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 40,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 24),
            Text('Create Promotion', style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 8),
            Text('Your ad will be featured to potential customers.', style: GoogleFonts.outfit(fontSize: 14, color: isDark ? Colors.white60 : Colors.black54)),
            const SizedBox(height: 32),
            
            // Image Picker
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                ),
                child: _imageFile != null
                    ? ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.file(_imageFile!, fit: BoxFit.cover))
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(PhosphorIconsRegular.image, size: 40, color: AppColors.primary01),
                          const SizedBox(height: 8),
                          Text('Select Promotion Image', style: GoogleFonts.outfit(color: AppColors.primary01, fontWeight: FontWeight.w600)),
                        ],
                      ),
              ),
            ),
            
            const SizedBox(height: 24),
            _buildField('Ad Title (e.g. Wedding Special)', _titleController, isDark),
            const SizedBox(height: 16),
            _buildField('Location / Note', _placeController, isDark),
            
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary01,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                child: _isSubmitting 
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Publish Ad', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white60 : Colors.black54)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black),
          decoration: InputDecoration(
            filled: true,
            fillColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.02),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }
}
