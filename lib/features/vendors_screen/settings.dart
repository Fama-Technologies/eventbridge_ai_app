import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';

import 'package:eventbridge/core/storage/storage_service.dart';
import 'package:eventbridge/core/widgets/app_toast.dart';
import 'package:eventbridge/features/auth/data/auth_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'package:eventbridge/core/services/upload_service.dart';
import 'package:eventbridge/core/network/api_service.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'dart:io';
import 'dart:ui';

class VendorSettingsScreen extends StatefulWidget {
  const VendorSettingsScreen({super.key});

  @override
  State<VendorSettingsScreen> createState() => _VendorSettingsScreenState();
}

class _VendorSettingsScreenState extends State<VendorSettingsScreen> {
  String _userName = 'Vendor';
  String? _userImage;
  bool _isUpdatingAvatar = false;
  String? _planName;
  String? _joinedDate;
  bool _isVerifiedBadge = false;
  bool _isLoadingData = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _loadVendorPlan();
  }

  Future<void> _loadUserData() async {
    final storage = StorageService();
    final name = storage.getString('user_name');
    final image = storage.getString('user_image');
    if (mounted) {
      setState(() {
        if (name != null && name.isNotEmpty) _userName = name;
        _userImage = (image != null && image.isNotEmpty) ? image : null;
      });
    }
  }

  Future<void> _loadVendorPlan() async {
    try {
      final storage = StorageService();
      final userId = storage.getString('user_id');
      if (userId == null) return;

      final result = await ApiService.instance.getVendorProfile(userId);
      if (result['success'] == true && result['profile'] != null) {
        final profile = result['profile'];
        if (mounted) {
          setState(() {
            _planName = profile['subscriptionPlan'] ?? 'Basic';
            storage.setString(
              'vendor_plan',
              _planName!,
            ); // Persist for other screens
            final createdAt = profile['createdAt'];
            if (createdAt != null) {
              final date = DateTime.parse(createdAt);
              _joinedDate = DateFormat('MMMM yyyy').format(date);
            }
            _isVerifiedBadge = profile['isVerifiedBadge'] == true;
            _isLoadingData = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoadingData = false);
      }
    }
  }

  Future<void> _pickAndUploadAvatar() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 512,
        maxHeight: 512,
      );

      if (pickedFile == null) return;

      setState(() => _isUpdatingAvatar = true);

      final storage = StorageService();
      final userId = storage.getString('user_id');
      if (userId == null) throw Exception('User not found');

      final file = File(pickedFile.path);
      final bytes = await file.readAsBytes();

      final uploadService = UploadService.instance;
      final avatarUrl = await uploadService.uploadFile(
        bytes: bytes,
        fileName:
            'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        contentType: 'image/jpeg',
        folder: 'avatars/$userId',
      );

      // Update account with new avatar via onboarding endpoint (used for updates too)
      await ApiService.instance.submitVendorOnboarding(
        userId: userId,
        businessName: storage.getString('business_name') ?? _userName,
        avatarUrl: avatarUrl,
      );

      // Persist locally
      await storage.setString('user_image', avatarUrl);

      if (mounted) {
        setState(() => _userImage = avatarUrl);
        AppToast.show(
          context,
          message: 'Profile picture updated!',
          type: ToastType.success,
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          message: 'Failed to update avatar',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingAvatar = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkNeutral01 : const Color(0xFFF7F7F8);
    final cardColor = isDark ? AppColors.darkNeutral02 : Colors.white;
    final textPrimary = isDark
        ? AppColors.shadesWhite
        : const Color(0xFF1E293B);
    final textSecondary = isDark
        ? AppColors.darkNeutral04
        : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left_rounded,
            color: Colors.white,
            size: 28,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/vendor-home');
            }
          },
        ),
        title: Text(
          'My Account',
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
            onPressed: () async {
              await AuthRepository().logout();
              if (mounted) {
                context.go('/login');
              }
            },
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: SingleChildScrollView(
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Orange Header
                Container(
                  height: 240,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                    ),
                  ),
                ),
                // Blurred dots/pattern overlay
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.1,
                    child: GridView.count(
                      crossAxisCount: 10,
                      physics: const NeverScrollableScrollPhysics(),
                      children: List.generate(
                        40,
                        (i) => const Icon(
                          Icons.circle,
                          size: 4,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                // Integrated Profile Info inside Header (Vertically Centered)
                Positioned.fill(
                  top: 40, // Account for app bar height roughly
                  child: Center(
                    child: _buildProfileHeader(
                      isDark,
                      textPrimary,
                      textSecondary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Account Settings',
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildAccountSection(cardColor, textPrimary, textSecondary),
                  const SizedBox(height: 32),
                  Text(
                    'Preferences & Others',
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildOthersSection(cardColor, textPrimary, textSecondary),
                  const SizedBox(height: 100), // Padding for bottom nav
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(
    bool isDark,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _isUpdatingAvatar ? null : _pickAndUploadAvatar,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Pro Plan Crown
              if (_planName?.toLowerCase() == 'business_pro')
                Positioned(
                  top: -18,
                  left: 0,
                  right: 0,
                  child: Center(
                    child:
                        Icon(
                              Icons
                                  .king_bed_rounded, // Using king_bed as a simple crown representation or custom icon
                              color: const Color(0xFFFFD700),
                              size: 28,
                            )
                            .animate(
                              onPlay: (controller) =>
                                  controller.repeat(reverse: true),
                            )
                            .scale(
                              duration: 1.seconds,
                              begin: const Offset(1, 1),
                              end: const Offset(1.1, 1.1),
                            )
                            .shimmer(delay: 2.seconds),
                  ),
                ),

              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  border: Border.all(
                    color: _planName?.toLowerCase() == 'business_pro'
                        ? const Color(0xFFFFD700)
                        : Colors.white.withOpacity(0.5),
                    width: 3,
                  ),
                ),
                child: ClipOval(
                  child: _isUpdatingAvatar
                      ? const Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : (_userImage != null && _userImage!.isNotEmpty
                            ? Image.network(
                                _userImage!,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    _buildInitialsPlaceholder(isHeader: true),
                              )
                            : _buildInitialsPlaceholder(isHeader: true)),
                ),
              ),

              // Free Plan White Bubble Badge (Exterior Tab Look)
              if (_planName?.toLowerCase() != 'business_pro')
                Positioned(
                  left: 92, // Positioned tangent to the 100px avatar edge
                  top: 38,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: const Color(0xFFEA580C),
                        width: 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 8,
                          offset: const Offset(3, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      'FREE PLAN',
                      style: GoogleFonts.roboto(
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFEA580C),
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ),

              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: Color(0xFFEA580C),
                    size: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _userName,
              style: GoogleFonts.roboto(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (_isVerifiedBadge) ...[
              const SizedBox(width: 8),
              const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
            ],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          '${_planName ?? "Basic"} Vendor since ${_joinedDate ?? "2024"}',
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(0.9),
          ),
        ),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => context.push('/vendor-subscription'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.upgrade_rounded,
                  color: Colors.white,
                  size: 14,
                ),
                const SizedBox(width: 6),
                Text(
                  _planName == null || _planName == 'free_trial'
                      ? 'Upgrade Plan'
                      : 'Active: ${_planName == "business_pro" ? "Premium Vendor" : "Basic Vendor"}',
                  style: GoogleFonts.roboto(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInitialsPlaceholder({bool isHeader = false}) {
    String initials = 'V';
    if (_userName.trim().isNotEmpty) {
      final parts = _userName.trim().split(' ');
      if (parts.length >= 2) {
        initials = (parts[0][0] + parts[1][0]).toUpperCase();
      } else if (parts[0].isNotEmpty) {
        initials = parts[0][0].toUpperCase();
      }
    }
    return Container(
      color: isHeader ? Colors.white.withOpacity(0.1) : const Color(0xFFE5E7EB),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w900,
          color: isHeader ? Colors.white : const Color(0xFF4B5563),
        ),
      ),
    );
  }

  Widget _buildAccountSection(
    Color cardColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildListItem(
            icon: Icons.person_outline_rounded,
            title: 'Personal Information',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            onTap: () => context.push('/vendor-personal-info'),
          ),
          _buildListItem(
            icon: Icons.storefront_outlined,
            title: 'Business Profile',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            onTap: () => context.push('/vendor-profile-settings'),
          ),
          _buildListItem(
            icon: Icons.location_on_outlined,
            title: 'Location',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            onTap: () => _showLocationPicker(context),
          ),
          _buildListItem(
            icon: Icons.photo_library_outlined,
            title: 'My Portfolio',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            onTap: () => context.push('/vendor-portfolio'),
          ),
          _buildListItem(
            icon: Icons.vpn_key_outlined,
            title: 'Security',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            isLast: true,
            onTap: () {
              context.push('/vendor-personal-info');
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOthersSection(
    Color cardColor,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          _buildListItem(
            icon: Icons.inventory_2_outlined,
            title: 'My Items',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            onTap: () {
              AppToast.show(
                context,
                message: 'My Items coming soon!',
                type: ToastType.info,
              );
            },
          ),
          _buildListItem(
            icon: Icons.notifications_none_outlined,
            title: 'Preferences',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            onTap: () {
              AppToast.show(
                context,
                message: 'Preferences coming soon!',
                type: ToastType.info,
              );
            },
          ),
          _buildListItem(
            icon: Icons.translate_outlined,
            title: 'Language',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            onTap: () {
              AppToast.show(
                context,
                message: 'Language coming soon!',
                type: ToastType.info,
              );
            },
          ),
          _buildListItem(
            icon: Icons.rate_review_outlined,
            title: 'Ratings / Review',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            onTap: () {
              AppToast.show(
                context,
                message: 'Reviews coming soon!',
                type: ToastType.info,
              );
            },
          ),
          _buildListItem(
            icon: Icons.help_outline_outlined,
            title: 'Help / Support',
            textPrimary: textPrimary,
            textSecondary: textSecondary,
            onTap: () => context.push('/vendor-help-support'),
          ),
          _buildListItem(
            icon: Icons.logout_rounded,
            title: 'Log out',
            textPrimary: const Color(0xFFEF4444),
            textSecondary: textSecondary,
            onTap: () async {
              await AuthRepository().logout();
              if (mounted) {
                context.go('/login');
              }
            },
          ),
          _buildListItem(
            icon: Icons.delete_forever_rounded,
            title: 'Delete Account',
            textPrimary: const Color(0xFFEF4444),
            textSecondary: textSecondary,
            isLast: true,
            onTap: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete Account?'),
                  content: const Text(
                    'This will permanently delete your account and all data. This action cannot be undone.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text(
                        'Delete',
                        style: TextStyle(color: Color(0xFFEF4444)),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true && mounted) {
                final userId = StorageService().getString('user_id');
                if (userId != null) {
                  try {
                    await ApiService.instance.deleteAccount(userId);
                  } catch (e) {
                    if (mounted) {
                      AppToast.show(
                        context,
                        message:
                            'Failed to delete account: ${e.toString().replaceAll("Exception: ", "")}',
                        type: ToastType.error,
                      );
                    }
                    return;
                  }
                }
                await AuthRepository().logout();
                if (mounted) context.go('/login');
              }
            },
          ),
        ],
      ),
    );
  }

  void _showLocationPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LocationPickerSheet(
        onLocationSelected: (lat, lng, address) async {
          final userId = StorageService().getString('user_id');
          if (userId == null) return;

          try {
            await ApiService.instance.submitVendorOnboarding(
              userId: userId,
              businessName:
                  StorageService().getString('business_name') ?? 'Vendor',
              latitude: lat,
              longitude: lng,
              location: address,
            );

            if (mounted) {
              StorageService().setString('vendor_location', address);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Location saved successfully')),
              );
              Navigator.pop(context);
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to save location: $e'),
                  backgroundColor: const Color(0xFFDC2626),
                ),
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required String title,
    required Color textPrimary,
    required Color textSecondary,
    bool isLast = false,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: isLast
          ? const BorderRadius.vertical(bottom: Radius.circular(16))
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 24, color: textPrimary),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: textPrimary,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 24, color: textSecondary),
          ],
        ),
      ),
    );
  }
}

// Location Picker Bottom Sheet Widget
class LocationPickerSheet extends StatefulWidget {
  final Function(double, double, String) onLocationSelected;

  const LocationPickerSheet({
    super.key,
    required this.onLocationSelected,
  });

  @override
  State<LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<LocationPickerSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isBusinessMode = true;
  double? _lat;
  double? _lng;
  String? _address;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
      child: Container(
        decoration: BoxDecoration(
          color: isDark
              ? AppColors.backgroundDark.withValues(alpha: 0.95)
              : Colors.white.withValues(alpha: 0.98),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(36)),
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04),
              width: 1,
            ),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 16, bottom: 16),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set Your Location',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF1A1A24),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Help clients find you',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.6)
                          : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Tab buttons
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: _buildTabButton(
                      label: 'Business Address',
                      isActive: _isBusinessMode,
                      isDark: isDark,
                      onTap: () =>
                          setState(() => _isBusinessMode = true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTabButton(
                      label: 'Current Location',
                      isActive: !_isBusinessMode,
                      isDark: isDark,
                      onTap: () =>
                          setState(() => _isBusinessMode = false),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Content
            if (_isLoading)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text(
                      _isBusinessMode
                          ? 'Searching location...'
                          : 'Getting your location...',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.7)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              )
            else if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFDC2626).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ),
              )
            else if (_address != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary01.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary01.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_rounded,
                          color: AppColors.primary01, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _address!,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF1A1A24),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GestureDetector(
                  onTap: _isBusinessMode
                      ? _selectBusinessAddress
                      : _getCurrentLocation,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.darkNeutral02.withValues(alpha: 0.3)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary01.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _isBusinessMode
                            ? 'Search for your business address'
                            : 'Detect my current location',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary01,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 32),

            // Save button
            Padding(
              padding: EdgeInsets.fromLTRB(
                  24, 0, 24, MediaQuery.of(context).padding.bottom + 24),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed:
                      (_lat == null || _lng == null || _address == null)
                          ? null
                          : () {
                            widget.onLocationSelected(_lat!, _lng!, _address!);
                          },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary01,
                    disabledBackgroundColor:
                        AppColors.primary01.withValues(alpha: 0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    'Save Location',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required String label,
    required bool isActive,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary01.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isActive
                ? AppColors.primary01.withValues(alpha: 0.3)
                : isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.1),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isActive
                  ? AppColors.primary01
                  : isDark
                      ? Colors.white.withValues(alpha: 0.6)
                      : const Color(0xFF6B7280),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _selectBusinessAddress() async {
    // Use Google Places API similar to vendor onboarding
    // For now, show a simple dialog
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Search Address'),
        content: TextField(
          decoration: const InputDecoration(
            hintText: 'Enter business address',
            border: OutlineInputBorder(),
          ),
          onChanged: (value) {},
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, {'lat': 0.3476, 'lng': 32.5825, 'address': 'Kampala, Uganda'}),
            child: const Text('Select'),
          ),
        ],
      ),
    );

    if (result != null) {
      setState(() {
        _lat = result['lat'];
        _lng = result['lng'];
        _address = result['address'];
        _errorMessage = null;
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Request permission
      final permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _errorMessage =
              'Location permission denied. Enable in phone settings.';
          _isLoading = false;
        });
        return;
      }

      // Get current position
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Reverse geocode to get address
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      final place = placemarks.isNotEmpty ? placemarks.first : null;
      final address = place != null
          ? '${place.locality}, ${place.country}'
          : 'Unknown location';

      setState(() {
        _lat = position.latitude;
        _lng = position.longitude;
        _address = address;
        _isLoading = false;
        _errorMessage = null;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to get location: ${e.toString()}';
        _isLoading = false;
      });
    }
  }
}
