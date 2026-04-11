import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/shared/widgets/app_header.dart';
import 'providers/profile_provider.dart';
import 'package:eventbridge/features/shared/widgets/top_notification.dart';
import 'package:eventbridge/features/home/data/repositories/profile_repository.dart';
import 'package:eventbridge/features/auth/presentation/auth_provider.dart';
import 'saved_vendors_screen.dart';
import 'inquiry_history_screen.dart';
import 'help_center_screen.dart';
import 'terms_screen.dart';

class CustomerProfileScreen extends ConsumerStatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  ConsumerState<CustomerProfileScreen> createState() =>
      _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends ConsumerState<CustomerProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(customerProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.warmCream,
      body: profileAsync.when(
        data: (profile) => Column(
          children: [
            AppHeader(
              title: 'Profile',
              username: profile?.name,
              showBack: false,
            ),
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.only(
                      top: 20,
                      left: 20,
                      right: 20,
                      bottom: 40,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const SizedBox(height: 12),
                        _buildSectionTitle('Manage Account', isDark),
                        const SizedBox(height: 16),
                        _buildGroupedCard([
                          _buildSettingsItem(
                            icon: Icons.person_outline_rounded,
                            title: 'Profile Information',
                            subtitle: 'Name, Email, and Phone',
                            onTap: () =>
                                _showProfileInfo(context, profile, isDark),
                            isDark: isDark,
                          ),
                          _buildDivider(isDark),
                          _buildSettingsItem(
                            icon: Icons.settings_outlined,
                            title: 'Security & Preferences',
                            subtitle: 'Notifications, Logout, & Privacy',
                            onTap: () =>
                                _showSettingsAndSecurity(context, isDark),
                            isDark: isDark,
                          ),
                        ], isDark),
                        const SizedBox(height: 32),
                        _buildSectionTitle('Activity', isDark),
                        const SizedBox(height: 16),
                        _buildGroupedCard([
                          _buildSettingsItem(
                            icon: Icons.favorite_border_rounded,
                            title: 'Saved Vendors',
                            subtitle: 'View your bookmarked services',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const SavedVendorsScreen(),
                              ),
                            ),
                            isDark: isDark,
                          ),
                          _buildDivider(isDark),
                          _buildSettingsItem(
                            icon: Icons.history_rounded,
                            title: 'Inquiry History',
                            subtitle: 'Track your recent requests',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const InquiryHistoryScreen(),
                              ),
                            ),
                            isDark: isDark,
                          ),
                        ], isDark),
                        const SizedBox(height: 32),
                        _buildSectionTitle('App Info', isDark),
                        const SizedBox(height: 16),
                        _buildGroupedCard([
                          _buildSettingsItem(
                            icon: Icons.help_outline_rounded,
                            title: 'Help Center',
                            subtitle: 'FAQs and Support',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const HelpCenterScreen(),
                              ),
                            ),
                            isDark: isDark,
                          ),
                          _buildDivider(isDark),
                          _buildSettingsItem(
                            icon: Icons.description_outlined,
                            title: 'Terms of Service',
                            subtitle: 'Legal and Privacy policies',
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const TermsScreen(),
                              ),
                            ),
                            isDark: isDark,
                          ),
                        ], isDark),
                        const SizedBox(height: 48),
                        Center(
                          child: Text(
                            'App Version 2.4.0 (Platinum)',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: isDark ? Colors.white24 : Colors.black26,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 120)),
                ],
              ),
            ),
          ],
        ),
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.primary01),
        ),
        error: (err, stack) => Center(
          child: TextButton(
            onPressed: () => ref.refresh(customerProfileProvider),
            child: const Text('Retry'),
          ),
        ),
      ),
    );
  }

  void _showProfileInfo(BuildContext context, dynamic profile, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildGlassContainer(
        isDark: isDark,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildModalHeader('Profile Details', isDark),
                TextButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showEditProfileDialog(
                      profile?.name ?? 'Guest User',
                      profile?.phone ?? '',
                      profile?.location ?? '',
                      isDark,
                    );
                  },
                  icon: const Icon(
                    Icons.edit_outlined,
                    size: 18,
                    color: AppColors.primary01,
                  ),
                  label: Text(
                    'Edit',
                    style: GoogleFonts.outfit(
                      color: AppColors.primary01,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildDetailItem(
              'Full Name',
              profile?.name ?? 'Guest User',
              Icons.person_rounded,
              isDark,
            ),
            _buildDetailItem(
              'Email Address',
              profile?.email ?? 'Not set',
              Icons.alternate_email_rounded,
              isDark,
            ),
            _buildDetailItem(
              'Phone Number',
              profile?.phone ?? '+256 700 000 000',
              Icons.phone_android_rounded,
              isDark,
            ),
            _buildDetailItem(
              'Location',
              profile?.location ?? 'Kampala, Uganda',
              Icons.location_on_rounded,
              isDark,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(
    String initialName,
    String initialPhone,
    String initialLocation,
    bool isDark,
  ) {
    final nameController = TextEditingController(text: initialName);
    final phoneController = TextEditingController(text: initialPhone);
    final locationController = TextEditingController(text: initialLocation);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkNeutral01 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(
              nameController,
              'Full Name',
              Icons.person_outline,
              isDark,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              phoneController,
              'Phone Number',
              Icons.phone_android,
              isDark,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              locationController,
              'Location',
              Icons.location_on,
              isDark,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(
                color: isDark ? Colors.white38 : Colors.black38,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final profileRepo = ref.read(profileRepositoryProvider);
              final authRepo = ref.read(authRepositoryProvider);
              final userId = authRepo.getUserId();

              if (userId != null) {
                final success = await profileRepo.updateCustomerProfile(
                  userId: userId,
                  name: nameController.text.trim(),
                  phone: phoneController.text.trim(),
                  location: locationController.text.trim(),
                );

                if (success) {
                  ref.invalidate(customerProfileProvider);
                  Navigator.pop(context);
                  TopNotificationOverlay.show(
                    context: context,
                    title: 'Success',
                    message: 'Profile Updated Successfully!',
                    onTap: () {},
                  );
                } else {
                  TopNotificationOverlay.show(
                    context: context,
                    title: 'Error',
                    message: 'Failed to update profile.',
                    onTap: () {},
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary01,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Save Changes',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    bool isDark,
  ) {
    return TextField(
      controller: controller,
      style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(
          color: isDark ? Colors.white38 : Colors.black38,
        ),
        prefixIcon: Icon(icon, color: AppColors.primary01, size: 20),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void _showSettingsAndSecurity(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildGlassContainer(
        isDark: isDark,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModalHeader('Settings & Security', isDark),
            const SizedBox(height: 24),
            _buildSettingsItem(
              icon: Icons.lock_outline_rounded,
              title: 'Privacy Settings',
              subtitle: 'Data usage and visibility',
              onTap: () => _showPrivacyInfo(context, isDark),
              isDark: isDark,
            ),
            const SizedBox(height: 32),
            _buildSectionTitle('Destructive Actions', isDark),
            const SizedBox(height: 12),
            _buildSettingsItem(
              icon: Icons.logout_rounded,
              title: 'Log Out',
              subtitle: 'Safe termination of session',
              titleColor: Colors.orange,
              onTap: () => _handleLogout(context, isDark),
              isDark: isDark,
              showArrow: false,
            ),
            _buildDivider(isDark),
            _buildSettingsItem(
              icon: Icons.delete_forever_rounded,
              title: 'Delete Account',
              subtitle: 'Permanently erase all data',
              titleColor: Colors.redAccent,
              onTap: () => _handleDeleteAccount(context, isDark),
              isDark: isDark,
              showArrow: false,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showPrivacyInfo(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkNeutral01 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900),
        ),
        content: Text(
          'Your data is encrypted and never shared with third parties without your explicit consent. You can request a copy of your data or its deletion at any time.',
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Close',
              style: GoogleFonts.outfit(color: AppColors.primary01),
            ),
          ),
        ],
      ),
    );
  }

  void _handleLogout(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkNeutral01 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Sign Out',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w900),
        ),
        content: Text(
          'Are you sure you want to sign out?',
          style: GoogleFonts.outfit(
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
          ),
          TextButton(
            onPressed: () {
              ref.read(authRepositoryProvider).logout();
              context.go('/login');
            },
            child: Text(
              'Sign Out',
              style: GoogleFonts.outfit(
                color: Colors.orangeAccent,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleDeleteAccount(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkNeutral01 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Delete Account',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            color: Colors.redAccent,
          ),
        ),
        content: Text(
          'This action is permanent and cannot be undone. All your data will be erased.',
          style: GoogleFonts.outfit(
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final authRepo = ref.read(authRepositoryProvider);
              final profileRepo = ref.read(profileRepositoryProvider);
              final userId = authRepo.getUserId();
              if (userId != null) {
                final success = await profileRepo.deleteAccount(userId);
                if (success) {
                  await authRepo.logout();
                  context.go('/login');
                } else {
                  TopNotificationOverlay.show(
                    context: context,
                    title: 'Error',
                    message: 'Failed to delete account.',
                    onTap: () {},
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            child: Text(
              'Delete',
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassContainer({required bool isDark, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkNeutral01.withValues(alpha: 0.95)
            : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 40,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      child: child,
    );
  }

  Widget _buildModalHeader(String title, bool isDark) {
    return Column(
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white12 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF1A1A24),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem(
    String label,
    String val,
    IconData icon,
    bool isDark,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary01.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary01, size: 20),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white24 : Colors.black38,
                ),
              ),
              Text(
                val,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title.toUpperCase(),
      style: GoogleFonts.outfit(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: AppColors.primary01,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildGroupedCard(List<Widget> children, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkNeutral02 : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
    Color? titleColor,
    bool showArrow = true,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (titleColor ?? AppColors.primary01).withValues(
                  alpha: 0.08,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: titleColor ?? AppColors.primary01,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color:
                          titleColor ??
                          (isDark ? Colors.white : const Color(0xFF1E293B)),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white38 : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null)
              trailing
            else if (showArrow)
              const Icon(
                Icons.chevron_right_rounded,
                color: Color(0xFFCBD5E1),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(left: 64, right: 20),
      child: Divider(
        height: 1,
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : const Color(0xFFF1F5F9),
      ),
    );
  }
}
