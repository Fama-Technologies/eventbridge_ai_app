import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/core/storage/storage_service.dart';
import 'package:eventbridge/core/network/api_service.dart';
import 'package:eventbridge/features/auth/data/auth_repository.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:eventbridge/features/shared/widgets/top_notification.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'providers/profile_provider.dart';
import '../data/repositories/profile_repository.dart';
import '../domain/models/customer_profile.dart';
import '../../auth/presentation/auth_provider.dart';

class CustomerSettingsScreen extends ConsumerStatefulWidget {
  const CustomerSettingsScreen({super.key});

  @override
  ConsumerState<CustomerSettingsScreen> createState() => _CustomerSettingsScreenState();
}

class _CustomerSettingsScreenState extends ConsumerState<CustomerSettingsScreen> {
  bool _emailUpdates = false;
  bool _darkMode = false;
  String _selectedCurrency = 'UGX';

  final List<String> _currencies = ['UGX', 'USD', 'KES', 'TZS', 'RWF', 'GBP', 'EUR'];

  @override
  void initState() {
    super.initState();
    // Load saved currency from SharedPrefs
    final saved = StorageService().getString('display_currency');
    if (saved != null && _currencies.contains(saved)) {
      _selectedCurrency = saved;
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(customerProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final backgroundColor = isDark ? AppColors.backgroundDark : AppColors.warmCream;

    return Scaffold(
      backgroundColor: backgroundColor,
      body: profileAsync.when(
        data: (profile) => CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildSliverAppBar(context, isDark),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 80),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildProfileCard(context, isDark, profile).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
                  const SizedBox(height: 32),
                  
                  _buildSectionTitle('Preferences', isDark),
                  const SizedBox(height: 16),
                  _buildToggleGroup([
                    _ToggleItem(
                      icon: Icons.email_rounded,
                      iconColor: const Color(0xFF4338CA),
                      title: 'Email Updates',
                      subtitle: 'Weekly digest & promotions',
                      value: _emailUpdates,
                      onChanged: (v) => setState(() => _emailUpdates = v),
                    ),
                    _ToggleItem(
                      icon: Icons.dark_mode_rounded,
                      iconColor: const Color(0xFF1E293B),
                      title: 'Dark Mode',
                      subtitle: 'Use dark theme across the app',
                      value: _darkMode,
                      onChanged: (v) => setState(() => _darkMode = v),
                    ),
                  ], isDark).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 32),
                  _buildSectionTitle('Regional', isDark),
                  const SizedBox(height: 16),
                  _buildGlassCard(
                    isDark: isDark,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      child: Row(
                        children: [
                          _buildIconContainer(Icons.currency_exchange_rounded, AppColors.primary01),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Display Currency',
                                    style: GoogleFonts.outfit(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: isDark ? Colors.white : AppColors.primary01)),
                                Text('Select your preferred currency',
                                    style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: isDark ? Colors.white38 : const Color(0xFF64748B))),
                              ],
                            ),
                          ),
                          DropdownButton<String>(
                            value: _selectedCurrency,
                            underline: const SizedBox(),
                            dropdownColor: isDark ? AppColors.darkNeutral01 : Colors.white,
                            icon: Icon(Icons.keyboard_arrow_down_rounded, color: isDark ? Colors.white38 : AppColors.primary01),
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.primary01 : AppColors.primary01,
                            ),
                            items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                            onChanged: (val) {
                              if (val != null) {
                                setState(() => _selectedCurrency = val);
                                StorageService().setString('display_currency', val);
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 32),
                  _buildSectionTitle('Account & Security', isDark),
                  const SizedBox(height: 16),
                  _buildMenuGroup([
                    _MenuItem(
                      icon: Icons.person_outline_rounded,
                      iconColor: AppColors.primary01,
                      title: 'Personal Information',
                      subtitle: 'Name, email, phone',
                      onTap: () => _showPersonalInformation(context, profile, isDark),
                    ),
                    _MenuItem(
                      icon: Icons.lock_outline_rounded,
                      iconColor: const Color(0xFF4338CA),
                      title: 'Password & Security',
                      subtitle: 'Change password, 2FA',
                      onTap: () => _showSecuritySettings(context, isDark),
                    ),
                    _MenuItem(
                      icon: Icons.payment_rounded,
                      iconColor: const Color(0xFF00CFA1),
                      title: 'Payment Methods',
                      subtitle: 'Manage cards & billing',
                      onTap: () => _showPaymentMethods(context, isDark),
                    ),
                  ], isDark).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 32),
                  _buildSectionTitle('Danger Zone', isDark),
                  const SizedBox(height: 16),
                  _buildGlassCard(
                    isDark: isDark,
                    child: Column(
                      children: [
                        _buildSettingsItem(
                          icon: Icons.logout_rounded,
                          title: 'Sign Out',
                          subtitle: 'Safely exit your account',
                          titleColor: Colors.orange,
                          isDark: isDark,
                          onTap: () => _handleLogout(context),
                          showArrow: false,
                        ),
                        _buildDivider(isDark, indent: 0),
                        _buildSettingsItem(
                          icon: Icons.delete_forever_rounded,
                          title: 'Delete Account',
                          subtitle: 'Permanently remove all data',
                          titleColor: Colors.redAccent,
                          isDark: isDark,
                          onTap: () => _handleDeleteAccount(context),
                          showArrow: false,
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1, end: 0),
                  
                  const SizedBox(height: 48),
                  Center(
                    child: Text(
                      'EventBridge Premium v2.4.0',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white24 : Colors.black26,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary01)),
        error: (e, s) => Center(child: Text('Failed to load profile', style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black))),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 140,
      pinned: true,
      elevation: 0,
      stretch: true,
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.warmCream,
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: GestureDetector(
          onTap: () => context.pop(),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.1) : Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.arrow_back_ios_new_rounded, 
              size: 16, 
              color: isDark ? Colors.white : AppColors.primary01),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: false,
        titlePadding: const EdgeInsets.only(left: 60, bottom: 16),
        title: Text(
          'Settings',
          style: GoogleFonts.outfit(
            fontSize: 24,
            fontWeight: FontWeight.w900,
            color: AppColors.primary01,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: isDark 
                ? [AppColors.primary01.withValues(alpha: 0.05), Colors.transparent]
                : [AppColors.softPeach, AppColors.warmCream],
            ),
          ),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Positioned(
                right: -40,
                top: -40,
                child: Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.primary01.withValues(alpha: isDark ? 0.05 : 0.03),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context, bool isDark, dynamic profile) {
    final userName = profile?.name ?? StorageService().getString('user_name') ?? 'Customer';
    final userEmail = profile?.email ?? StorageService().getString('user_email') ?? 'premium@eventbridge.ai';
    
    return _buildGlassCard(
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [AppColors.primary01, Color(0xFFFFA892)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary01.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : 'C',
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
                  Text(userName,
                      style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF1A1A24))),
                  const SizedBox(height: 2),
                  Text(userEmail,
                      style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white38 : const Color(0xFF64748B))),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _showPersonalInformation(context, profile, isDark),
              child: _buildEditBadge(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditBadge(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary01.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(
        'EDIT',
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: AppColors.primary01,
          letterSpacing: 0.5,
        ),
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
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildGlassCard({required Widget child, required bool isDark}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkNeutral02.withValues(alpha: 0.6) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: child,
    );
  }

  Widget _buildToggleGroup(List<_ToggleItem> items, bool isDark) {
    return _buildGlassCard(
      isDark: isDark,
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    _buildIconContainer(item.icon, item.iconColor),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title,
                              style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF1E293B))),
                          Text(item.subtitle,
                              style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: isDark ? Colors.white38 : const Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: item.value,
                      onChanged: item.onChanged,
                      activeColor: AppColors.primary01,
                      activeTrackColor: AppColors.primary01.withValues(alpha: 0.3),
                    ),
                  ],
                ),
              ),
              if (i < items.length - 1) _buildDivider(isDark),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMenuGroup(List<_MenuItem> items, bool isDark) {
    return _buildGlassCard(
      isDark: isDark,
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          return Column(
            children: [
              InkWell(
                onTap: item.onTap,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      _buildIconContainer(item.icon, item.iconColor),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title,
                                style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? Colors.white : const Color(0xFF1E293B))),
                            Text(item.subtitle,
                                style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: isDark ? Colors.white38 : const Color(0xFF64748B))),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: Color(0xFFD1D5DB), size: 22),
                    ],
                  ),
                ),
              ),
              if (i < items.length - 1) _buildDivider(isDark),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
    bool showArrow = true,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(
          children: [
            _buildIconContainer(icon, titleColor ?? AppColors.primary01),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: titleColor ?? (isDark ? Colors.white : const Color(0xFF1E293B)))),
                  Text(subtitle,
                      style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white38 : const Color(0xFF64748B))),
                ],
              ),
            ),
            if (showArrow) const Icon(Icons.chevron_right_rounded, color: Color(0xFFCBD5E1), size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildIconContainer(IconData icon, Color color) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildDivider(bool isDark, {double indent = 72}) {
    return Divider(
      height: 1,
      indent: indent,
      endIndent: 16,
      color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF1F5F9),
    );
  }

  void _showPersonalInformation(BuildContext context, CustomerProfile? profile, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildModalContainer(
        isDark: isDark,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModalDragHandle(isDark),
            const SizedBox(height: 24),
            Text('Personal Information', 
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1A1A24))),
            const SizedBox(height: 8),
            Text('Manage your basic details used across EventBridge.', 
                style: GoogleFonts.outfit(fontSize: 14, color: isDark ? Colors.white38 : const Color(0xFF64748B))),
            const SizedBox(height: 32),
            _buildInfoTile('Full Name', profile?.name ?? 'Not set', Icons.person_rounded, isDark),
            _buildInfoTile('Email Address', profile?.email ?? 'Not set', Icons.email_rounded, isDark),
            _buildInfoTile('Phone Number', profile?.phone ?? '+256 700 000 000', Icons.phone_android_rounded, isDark),
            _buildInfoTile('Location', profile?.location ?? 'Kampala, Uganda', Icons.location_on_rounded, isDark),
            const SizedBox(height: 24),
            _buildPrimaryButton(
              context: context,
              label: 'Update Profile',
              onTap: () {
                Navigator.pop(context);
                _showEditProfileFields(context, profile, isDark);
              },
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showEditProfileFields(BuildContext context, CustomerProfile? profile, bool isDark) {
    final nameController = TextEditingController(text: profile?.name);
    final phoneController = TextEditingController(text: profile?.phone);
    final locationController = TextEditingController(text: profile?.location);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkNeutral01 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text('Update Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
              _buildModernTextField(nameController, 'Full Name', Icons.person_outline, isDark),
              const SizedBox(height: 16),
              _buildModernTextField(phoneController, 'Phone Number', Icons.phone_android, isDark),
              const SizedBox(height: 16),
              _buildModernTextField(locationController, 'Location', Icons.location_on, isDark),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey))),
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
                    message: 'Profile updated successfully!',
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
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary01, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('Save', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTextField(TextEditingController controller, String label, IconData icon, bool isDark) {
    return TextField(
      controller: controller,
      style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.outfit(color: isDark ? Colors.white38 : Colors.black38),
        prefixIcon: Icon(icon, color: AppColors.primary01, size: 20),
        filled: true,
        fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.05),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
  }

  void _showSecuritySettings(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildModalContainer(
        isDark: isDark,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModalDragHandle(isDark),
            const SizedBox(height: 24),
            Text('Password & Security', 
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1A1A24))),
            const SizedBox(height: 8),
            Text('Secure your account with multi-layered protection.', 
                style: GoogleFonts.outfit(fontSize: 14, color: isDark ? Colors.white38 : const Color(0xFF64748B))),
            const SizedBox(height: 32),
            _buildActionTile('Change Password', 'Update your login credentials', Icons.lock_outline_rounded, isDark, () => _showEditFieldDialog(context, 'Change Password', 'Enter your new secure password.', isDark)),
            _buildActionTile('Two-Factor Authentication', 'Add an extra layer of security', Icons.security_rounded, isDark, () => _showNotImplemented(context)),
            _buildActionTile('Active Sessions', 'Manage your logged-in devices', Icons.devices_rounded, isDark, () => _showNotImplemented(context)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  void _showPaymentMethods(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildModalContainer(
        isDark: isDark,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildModalDragHandle(isDark),
            const SizedBox(height: 24),
            Text('Payment Methods', 
                style: GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w900, color: isDark ? Colors.white : const Color(0xFF1A1A24))),
            const SizedBox(height: 8),
            Text('Securely manage your billing and card info.', 
                style: GoogleFonts.outfit(fontSize: 14, color: isDark ? Colors.white38 : const Color(0xFF64748B))),
            const SizedBox(height: 32),
            _buildPaymentCard('Visa Platinum', '•••• 4242', '08/26', context),
            _buildPaymentCard('Mobile Money', '+256 700 ••• 000', 'Active', context),
            const SizedBox(height: 24),
            _buildPrimaryButton(
              context: context,
              label: 'Add New Method',
              onTap: () => _showNotImplemented(context),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildModalContainer({required bool isDark, required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkNeutral01 : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 40, offset: const Offset(0, -10)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: child,
    );
  }

  Widget _buildModalDragHandle(bool isDark) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 12),
        width: 40,
        height: 5,
        decoration: BoxDecoration(
          color: isDark ? Colors.white12 : Colors.black12,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget _buildInfoTile(String label, String val, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        children: [
          _buildIconContainer(icon, AppColors.primary01),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.outfit(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white24 : Colors.black38)),
              Text(val, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1E293B))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionTile(String title, String subtitle, IconData icon, bool isDark, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            _buildIconContainer(icon, AppColors.primary01),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                  Text(subtitle, style: GoogleFonts.outfit(fontSize: 13, color: isDark ? Colors.white38 : const Color(0xFF64748B))),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFCBD5E1)),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentCard(String type, String number, String expiry, BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.white12 : const Color(0xFFF1F5F9)),
      ),
      child: Row(
        children: [
          const Icon(Icons.credit_card_rounded, color: AppColors.primary01),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(type, style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? Colors.white : const Color(0xFF1E293B))),
                Text(number, style: GoogleFonts.outfit(fontSize: 13, color: isDark ? Colors.white38 : const Color(0xFF64748B))),
              ],
            ),
          ),
          Text(expiry, style: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primary01)),
        ],
      ),
    );
  }

  Widget _buildPrimaryButton({required BuildContext context, required String label, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 56,
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [AppColors.primary01, Color(0xFFFFA892)]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: AppColors.primary01.withValues(alpha: 0.2), blurRadius: 15, offset: const Offset(0, 5)),
          ],
        ),
        child: Center(
          child: Text(label, style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
        ),
      ),
    );
  }

  void _showEditFieldDialog(BuildContext context, String title, String subtitle, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.darkNeutral01 : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(title, style: GoogleFonts.outfit(fontWeight: FontWeight.w900)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(subtitle, style: GoogleFonts.outfit(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87)),
            const SizedBox(height: 20),
            TextField(
              decoration: InputDecoration(
                filled: true,
                fillColor: isDark ? Colors.white.withValues(alpha: 0.05) : const Color(0xFFF8FAFC),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                hintText: 'Enter new value...',
                hintStyle: GoogleFonts.outfit(color: isDark ? Colors.white24 : Colors.black26),
              ),
              style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel', style: GoogleFonts.outfit(color: Colors.grey))),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              TopNotificationOverlay.show(
                context: context,
                title: 'Request Sent',
                message: 'Your update request is being processed.',
                onTap: () {},
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary01, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('Update', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showNotImplemented(BuildContext context) {
    TopNotificationOverlay.show(
      context: context,
      title: 'Coming Soon',
      message: 'This feature is currently under high-priority development.',
      onTap: () {},
    );
  }

  void _handleLogout(BuildContext context) {
    _showConfirmBottomSheet(
      context: context,
      title: 'Sign Out',
      message: 'Are you sure you want to sign out of EventBridge?',
      confirmLabel: 'Sign Out',
      confirmColor: Colors.orange,
      icon: Icons.logout_rounded,
      isDark: Theme.of(context).brightness == Brightness.dark,
      onConfirm: () async {
        await AuthRepository().logout();
        if (context.mounted) context.go('/login');
      },
    );
  }

  Future<void> _handleDeleteAccount(BuildContext context) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    _showConfirmBottomSheet(
      context: context,
      title: 'Delete Account',
      message: 'This action is permanent and will erase all your data. Proceed with extreme caution.',
      confirmLabel: 'Delete Forever',
      confirmColor: Colors.redAccent,
      icon: Icons.delete_forever_rounded,
      isDark: isDark,
      onConfirm: () async {
        final userId = StorageService().getString('user_id');
        if (userId != null) {
          try {
            await ApiService.instance.deleteAccount(userId);
          } catch (e) {
            if (context.mounted) {
              TopNotificationOverlay.show(
                context: context,
                title: 'Error',
                message: 'Failed to delete account. Please contact support.',
                onTap: () {},
              );
            }
            return;
          }
        }
        await AuthRepository().logout();
        if (context.mounted) context.go('/login');
      },
    );
  }

  void _showConfirmBottomSheet({
    required BuildContext context,
    required String title,
    required String message,
    required String confirmLabel,
    required Color confirmColor,
    required IconData icon,
    required bool isDark,
    required VoidCallback onConfirm,
  }) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildModalContainer(
        isDark: isDark,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildModalDragHandle(isDark),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF1A1A24),
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: confirmColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: confirmColor, size: 48),
            ),
            const SizedBox(height: 24),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 32),
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.outfit(
                        color: Colors.grey,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      onConfirm();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: confirmColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      confirmLabel,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─── Data models ─────────────────────────────────────
class _ToggleItem {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _ToggleItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });
}

class _MenuItem {
  final IconData icon;
  final Color iconColor;
  final String title, subtitle;
  final VoidCallback onTap;
  const _MenuItem({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });
}
