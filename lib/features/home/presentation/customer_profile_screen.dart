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

    return Scaffold(
      backgroundColor: Colors.white,
      body: profileAsync.when(
        data: (profile) => Column(
          children: [
            AppHeader(title: 'Account'),
            Expanded(
              child: ListView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                children: [
                  _buildUserCard(profile),
                  const SizedBox(height: 24),
                  _buildBecomeVendorButton(),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Account Settings'),
                  const SizedBox(height: 12),
                  _buildGroupedCard([
                    _buildSettingsItem(
                      icon: Icons.person_outline_rounded,
                      title: 'Profile Information',
                      subtitle: 'Name, Email, and Phone',
                      onTap: () => _showProfileInfo(context, profile),
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.lock_outline_rounded,
                      title: 'Privacy & Security',
                      subtitle: 'Password and data usage',
                      onTap: () => _showPrivacyInfo(context),
                    ),
                  ]),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Activity'),
                  const SizedBox(height: 12),
                  _buildGroupedCard([
                    _buildSettingsItem(
                      icon: Icons.favorite_border_rounded,
                      title: 'Saved Vendors',
                      subtitle: 'Places you want to visit again',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SavedVendorsScreen()),
                      ),
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.history_rounded,
                      title: 'Match History',
                      subtitle: 'Your previous inquiries',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const InquiryHistoryScreen()),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 32),
                  _buildSectionTitle('Support & Legal'),
                  const SizedBox(height: 12),
                  _buildGroupedCard([
                    _buildSettingsItem(
                      icon: Icons.help_outline_rounded,
                      title: 'Help Center',
                      subtitle: 'FAQs and direct support',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const HelpCenterScreen()),
                      ),
                    ),
                    _buildDivider(),
                    _buildSettingsItem(
                      icon: Icons.description_outlined,
                      title: 'Terms of Service',
                      subtitle: 'Legal and privacy policies',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const TermsScreen()),
                      ),
                    ),
                  ]),
                  const SizedBox(height: 32),
                  _buildSignOutButton(),
                  const SizedBox(height: 16),
                  _buildDeleteAccountButton(),
                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      'App Version 2.4.0',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: const Color(0xFFBDBDBD),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(height: 120),
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

  Widget _buildUserCard(dynamic profile) {
    final name = profile?.name ?? 'Guest User';
    final email = profile?.email ?? 'Sign in to access all features';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary01, Color(0xFFFF6B35)],
              ),
            ),
            child: Center(
              child: Text(
                name[0].toUpperCase(),
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    color: const Color(0xFF757575),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBecomeVendorButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton.icon(
        onPressed: () {
          // Navigate to vendor signup or info
        },
        icon: const Icon(Icons.rocket_launch_rounded, size: 20),
        label: Text(
          'Become a Vendor',
          style: GoogleFonts.outfit(
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A1A1A),
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF757575),
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildGroupedCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFF0F0F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary01.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.primary01, size: 20),
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
                      color: const Color(0xFF1A1A1A),
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: const Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFFBDBDBD),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignOutButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        onPressed: () => _handleLogout(context),
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: Text(
          'Sign Out',
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF1A1A1A),
          side: const BorderSide(color: Color(0xFFE0E0E0)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }

  Widget _buildDeleteAccountButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: TextButton.icon(
        onPressed: () => _handleDeleteAccount(context),
        icon: const Icon(Icons.delete_forever_rounded, size: 20),
        label: Text(
          'Delete Account',
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.errorsMain,
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return const Divider(
      height: 1,
      indent: 0,
      endIndent: 0,
      color: Color(0xFFF5F5F5),
    );
  }

  // ── Bottom sheets & dialogs ────────────────────────────────────────────────

  void _showProfileInfo(BuildContext context, dynamic profile) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildBottomSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSheetHandle(),
            const SizedBox(height: 20),
            Text(
              'Profile Details',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 24),
            _buildInfoRow(Icons.person_rounded, 'Full Name', profile?.name ?? 'Guest User'),
            _buildInfoRow(Icons.alternate_email_rounded, 'Email', profile?.email ?? 'Not set'),
            _buildInfoRow(Icons.phone_android_rounded, 'Phone', profile?.phone ?? '+256 700 000 000'),
            _buildInfoRow(Icons.location_on_rounded, 'Location', profile?.location ?? 'Kampala, Uganda'),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _showEditProfileDialog(
                    profile?.name ?? 'Guest User',
                    profile?.phone ?? '',
                    profile?.location ?? '',
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary01,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'Edit Profile',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary01.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(12),
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
                  color: const Color(0xFF9E9E9E),
                ),
              ),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A1A1A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showEditProfileDialog(
    String initialName,
    String initialPhone,
    String initialLocation,
  ) {
    final nameController = TextEditingController(text: initialName);
    final phoneController = TextEditingController(text: initialPhone);
    final locationController = TextEditingController(text: initialLocation);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Edit Profile',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildTextField(nameController, 'Full Name', Icons.person_outline),
            const SizedBox(height: 16),
            _buildTextField(phoneController, 'Phone Number', Icons.phone_android),
            const SizedBox(height: 16),
            _buildTextField(locationController, 'Location', Icons.location_on),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.outfit(color: const Color(0xFF9E9E9E)),
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
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  TopNotificationOverlay.show(
                    context: context,
                    title: 'Success',
                    message: 'Profile Updated Successfully!',
                    onTap: () {},
                  );
                } else {
                  if (!context.mounted) return;
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
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              'Save',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
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
  ) {
    return TextField(
      controller: controller,
      style: GoogleFonts.outfit(color: const Color(0xFF1A1A1A)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(color: const Color(0xFF9E9E9E)),
        prefixIcon: Icon(icon, color: AppColors.primary01, size: 20),
        filled: true,
        fillColor: const Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  void _showPrivacyInfo(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'Privacy Policy',
          style: GoogleFonts.outfit(
            fontWeight: FontWeight.w900,
            color: const Color(0xFF1A1A1A),
          ),
        ),
        content: Text(
          'Your data is encrypted and never shared with third parties without your explicit consent. You can request a copy of your data or its deletion at any time.',
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: const Color(0xFF757575),
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

  void _handleLogout(BuildContext context) {
    _showConfirmSheet(
      context: context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out of your EventBridge account?',
      confirmLabel: 'Sign Out',
      icon: Icons.logout_rounded,
      isDestructive: false,
      onConfirm: () {
        ref.read(authRepositoryProvider).logout();
        context.go('/login');
      },
    );
  }

  void _handleDeleteAccount(BuildContext context) {
    _showConfirmSheet(
      context: context,
      title: 'Delete Account',
      message: 'This is permanent. All your event data and matches will be erased forever.',
      confirmLabel: 'Delete Forever',
      icon: Icons.delete_forever_rounded,
      isDestructive: true,
      onConfirm: () async {
        final authRepo = ref.read(authRepositoryProvider);
        final profileRepo = ref.read(profileRepositoryProvider);
        final userId = authRepo.getUserId();
        if (userId != null) {
          final success = await profileRepo.deleteAccount(userId);
          if (success) {
            await authRepo.logout();
            if (!context.mounted) return;
            context.go('/login');
          } else {
            if (!context.mounted) return;
            TopNotificationOverlay.show(
              context: context,
              title: 'Error',
              message: 'Failed to delete account.',
              onTap: () {},
            );
          }
        }
      },
    );
  }

  void _showConfirmSheet({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmLabel,
    required IconData icon,
    required bool isDestructive,
    required VoidCallback onConfirm,
  }) {
    final confirmColor = isDestructive ? AppColors.errorsMain : const Color(0xFF1A1A1A);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildBottomSheet(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildSheetHandle(),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: confirmColor.withValues(alpha: 0.06),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: confirmColor, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF757575),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF757575),
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        onConfirm();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: confirmColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        confirmLabel,
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSheet({required Widget child}) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 40),
      child: child,
    );
  }

  Widget _buildSheetHandle() {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: const Color(0xFFE0E0E0),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
