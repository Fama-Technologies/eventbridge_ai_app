import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/core/storage/storage_service.dart';
import 'package:eventbridge/core/network/api_service.dart';
import 'package:eventbridge/features/auth/data/auth_repository.dart';
import 'package:eventbridge/core/widgets/app_toast.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class VendorProfileScreen extends StatefulWidget {
  const VendorProfileScreen({super.key});

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  final _storage = StorageService();
  bool _isLoading = true;
  String? _planName;
  String? _joinedDate;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _loadVendorProfile();
  }

  Future<void> _loadVendorProfile() async {
    try {
      final userId = _storage.getString('user_id');
      if (userId == null) return;

      final result = await ApiService.instance.getVendorProfile(userId);
      if (result['success'] == true && result['profile'] != null) {
        final profile = result['profile'];
        if (mounted) {
          setState(() {
            _planName = profile['subscriptionPlan'] ?? 'Basic';
            // Assuming join date might come from profile or we use a default
            final createdAt = profile['createdAt'];
            if (createdAt != null) {
              final date = DateTime.parse(createdAt);
              _joinedDate = DateFormat('MMMM yyyy').format(date);
            }
            _isVerified = profile['isVerifiedBadge'] == true;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userName = _storage.getString('user_name') ?? 'Vendor';
    final userImage = _storage.getString('user_image');
    
    // Mock data for visual metrics
    const averageRating = 4.8;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context, userName, userImage),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  
                  Text(
                    'SETTINGS & ACCOUNT',
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF9CA3AF),
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  _buildSettingsTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Personal Information',
                    subtitle: 'Manage names and contact details',
                    onTap: () => context.push('/vendor-personal-info'),
                  ),
                  _buildSettingsTile(
                    icon: Icons.storefront_rounded,
                    title: 'Business Profile',
                    subtitle: 'Portfolio, description, and socials',
                    onTap: () => context.push('/vendor-profile-settings'),
                  ),
                  _buildSettingsTile(
                    icon: Icons.workspace_premium_rounded,
                    title: 'Subscription Plan',
                    subtitle: 'Manage your vendor plan and billing',
                    onTap: () => context.push('/subscription'),
                  ),
                  _buildSettingsTile(
                    icon: Icons.photo_library_outlined,
                    title: 'My Portfolio',
                    subtitle: 'Public view of your best work',
                    onTap: () => context.push('/vendor-portfolio'),
                  ),
                  _buildSettingsTile(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Support',
                    subtitle: 'FAQs and direct contact',
                    onTap: () => context.push('/vendor-help-support'),
                  ),
                  _buildSettingsTile(
                    icon: Icons.logout_rounded,
                    title: 'Log out',
                    subtitle: 'Sign out of your account',
                    onTap: () async {
                      await AuthRepository().logout();
                      if (context.mounted) {
                        context.go('/login');
                      }
                    },
                    iconColor: const Color(0xFFEF4444),
                    titleColor: const Color(0xFFEF4444),
                  ),
                  _buildSettingsTile(
                    icon: Icons.delete_forever_rounded,
                    title: 'Delete Account',
                    subtitle: 'Permanently remove your data',
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          backgroundColor: Colors.white,
                          surfaceTintColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24),
                          ),
                          titlePadding: const EdgeInsets.only(top: 32, left: 24, right: 24),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                          actionsPadding: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
                          title: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.delete_forever_rounded, color: Color(0xFFEF4444), size: 36),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                'Delete Account?',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.roboto(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w900,
                                  color: const Color(0xFF1E293B),
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                          content: Text(
                            'This action cannot be undone. All your data, portfolio, and settings will be permanently removed.',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.roboto(
                              fontSize: 15,
                              color: const Color(0xFF64748B),
                              height: 1.4,
                            ),
                          ),
                          actionsAlignment: MainAxisAlignment.center,
                          actions: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      backgroundColor: const Color(0xFFF1F5F9),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      'Cancel',
                                      style: GoogleFonts.roboto(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 16),
                                      backgroundColor: const Color(0xFFEF4444),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: Text(
                                      'Delete',
                                      style: GoogleFonts.roboto(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                      if (confirm == true && context.mounted) {
                        final userId = StorageService().getString('user_id');
                        if (userId != null) {
                          try {
                            await ApiService.instance.deleteAccount(userId);
                          } catch (e) {
                            if (context.mounted) {
                              AppToast.show(context, message: 'Failed to delete account', type: ToastType.error);
                            }
                            return;
                          }
                        }
                        await AuthRepository().logout();
                        if (context.mounted) context.go('/login');
                      }
                    },
                    iconColor: const Color(0xFFEF4444),
                    titleColor: const Color(0xFFEF4444),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, String userName, String? userImage) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      backgroundColor: const Color(0xFFEA580C),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background gradient (Orange)
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                ),
              ),
            ),
            // Dots/Pattern overlay
            Opacity(
              opacity: 0.1,
              child: GridView.count(
                crossAxisCount: 10,
                physics: const NeverScrollableScrollPhysics(),
                children: List.generate(100, (i) => const Icon(Icons.circle, size: 4, color: Colors.white)),
              ),
            ),
            // Rating Icon Button in Header
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.star_rounded, color: Colors.white, size: 28),
                onPressed: () => _showRatingDetails(context),
              ),
            ),
            // Integrated Profile Content
            _isLoading
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : SafeArea(
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 20),
                          // Avatar with border
                          Stack(
                            clipBehavior: Clip.none,
                            children: [
                              // Pro Plan Crown
                              if (_planName?.toLowerCase() == 'business_pro')
                                Positioned(
                                  top: -18,
                                  left: 0,
                                  right: 0,
                                  child: Center(
                                    child: Icon(
                                      Icons.king_bed_rounded,
                                      color: const Color(0xFFFFD700),
                                      size: 28,
                                    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
                                     .scale(duration: 1.seconds, begin: const Offset(1, 1), end: const Offset(1.1, 1.1))
                                     .shimmer(delay: 2.seconds),
                                  ),
                                ),
                              
                              Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF7F7F8),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _planName?.toLowerCase() == 'business_pro' 
                                        ? const Color(0xFFFFD700) 
                                        : Colors.transparent,
                                    width: 2,
                                  ),
                                ),
                                child: Hero(
                                  tag: 'vendor_avatar',
                                  child: Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primary01.withValues(alpha: 0.1),
                                    ),
                                    child: ClipOval(
                                      child: (userImage != null && userImage.isNotEmpty)
                                          ? Image.network(
                                              userImage,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  _buildInitialsPlaceholder(userName),
                                            )
                                          : _buildInitialsPlaceholder(userName),
                                    ),
                                  ),
                                ),
                              ),

                              // Free Plan White Bubble Badge (Exterior Tab Look)
                              if (_planName?.toLowerCase() != 'business_pro')
                                Positioned(
                                  left: 92, // Positioned tangent to the 100px avatar edge
                                  top: 38,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(24),
                                      border: Border.all(color: const Color(0xFFEA580C), width: 2),
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
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Name and Badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                userName,
                                style: GoogleFonts.roboto(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              if (_isVerified) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.verified_rounded, color: Colors.white, size: 20),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          // Plan and Join Date
                          Text(
                            '${_planName ?? "Basic"} Vendor since ${_joinedDate ?? "2024"}',
                            style: GoogleFonts.roboto(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  void _showRatingDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(32),
            topRight: Radius.circular(32),
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Business Performance',
              style: GoogleFonts.roboto(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1A1A24),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 48),
                const SizedBox(width: 12),
                Text(
                  '4.8',
                  style: GoogleFonts.roboto(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFF1A1A24),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Based on 128 client reviews',
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEA580C),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text('Close Details', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInitialsPlaceholder(String name) {
    final initials = name.isNotEmpty ? name.substring(0, 1).toUpperCase() : 'V';
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.roboto(
          fontSize: 36,
          fontWeight: FontWeight.w900,
          color: AppColors.primary01,
        ),
      ),
    );
  }




  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? trailing,
    Color? iconColor,
    Color? titleColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconColor?.withOpacity(0.1) ?? const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor ?? const Color(0xFF4B5563), size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.roboto(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: titleColor ?? const Color(0xFF1A1A24),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: GoogleFonts.roboto(
                        fontSize: 12,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    trailing,
                    style: GoogleFonts.roboto(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFF97316),
                    ),
                  ),
                ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFFD1D5DB)),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.05, end: 0),
    );
  }
}
