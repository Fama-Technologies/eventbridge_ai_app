import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/core/storage/storage_service.dart';
import 'package:eventbridge/core/network/api_service.dart';
import 'package:eventbridge/features/auth/data/auth_repository.dart';

class CustomerSettingsScreen extends StatefulWidget {
  const CustomerSettingsScreen({super.key});

  @override
  State<CustomerSettingsScreen> createState() => _CustomerSettingsScreenState();
}

class _CustomerSettingsScreenState extends State<CustomerSettingsScreen> {
  bool _notifications = true;
  bool _emailUpdates = false;
  bool _darkMode = false;
  bool _locationSharing = true;
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
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          SliverToBoxAdapter(child: _buildProfileCard(context)),
          SliverToBoxAdapter(child: _sectionLabel('Preferences')),
          SliverToBoxAdapter(
            child: _buildToggleCard([
              _ToggleItem(
                icon: Icons.notifications_rounded,
                iconColor: AppColors.primary01,
                title: 'Push Notifications',
                subtitle: 'Vendor updates & match alerts',
                value: _notifications,
                onChanged: (v) => setState(() => _notifications = v),
              ),
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
              _ToggleItem(
                icon: Icons.location_on_rounded,
                iconColor: const Color(0xFF00CFA1),
                title: 'Location Sharing',
                subtitle: 'Improve nearby vendor matches',
                value: _locationSharing,
                onChanged: (v) => setState(() => _locationSharing = v),
              ),
            ]),
          ),
          // Currency Selector
          SliverToBoxAdapter(child: _sectionLabel('Currency')),
          SliverToBoxAdapter(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 20),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.03),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary01.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.currency_exchange_rounded, color: AppColors.primary01, size: 20),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Display Currency',
                            style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary01)),
                        Text('Select your preferred currency',
                            style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: const Color(0xFF9CA3AF))),
                      ],
                    ),
                  ),
                  DropdownButton<String>(
                    value: _selectedCurrency,
                    underline: const SizedBox(),
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary01,
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
          ),
          SliverToBoxAdapter(child: _sectionLabel('Account')),
          SliverToBoxAdapter(
            child: _buildMenuCard([
              _MenuItem(
                icon: Icons.person_rounded,
                iconColor: AppColors.primary01,
                title: 'Personal Information',
                subtitle: 'Name, email, phone',
                onTap: () {},
              ),
              _MenuItem(
                icon: Icons.lock_rounded,
                iconColor: const Color(0xFF4338CA),
                title: 'Password & Security',
                subtitle: 'Change password, 2FA',
                onTap: () {},
              ),
              _MenuItem(
                icon: Icons.credit_card_rounded,
                iconColor: const Color(0xFF00CFA1),
                title: 'Payment Methods',
                subtitle: 'Manage cards & billing',
                onTap: () {},
              ),
              _MenuItem(
                icon: Icons.star_rounded,
                iconColor: const Color(0xFFFFB800),
                title: 'Subscription Plan',
                subtitle: 'Premium — Active',
                onTap: () {},
              ),
            ]),
          ),
          SliverToBoxAdapter(child: _sectionLabel('Support')),
          SliverToBoxAdapter(
            child: _buildMenuCard([
              _MenuItem(
                icon: Icons.help_rounded,
                iconColor: const Color(0xFF6B7280),
                title: 'Help & Support',
                subtitle: 'FAQs, contact us',
                onTap: () {},
              ),
              _MenuItem(
                icon: Icons.privacy_tip_rounded,
                iconColor: const Color(0xFF6B7280),
                title: 'Privacy Policy',
                subtitle: 'How we handle your data',
                onTap: () {},
              ),
              _MenuItem(
                icon: Icons.description_rounded,
                iconColor: const Color(0xFF6B7280),
                title: 'Terms of Service',
                subtitle: 'Usage agreements',
                onTap: () {},
              ),
            ]),
          ),
          SliverToBoxAdapter(child: _sectionLabel('Account Actions')),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 48),
              child: Column(
                children: [
                  // Switch User
                  _buildActionButton(
                    icon: Icons.swap_horiz_rounded,
                    label: 'Switch User',
                    color: const Color(0xFF4338CA),
                    onTap: () => context.go('/role-selection'),
                  ),
                  const SizedBox(height: 12),
                  // Log Out
                  _buildActionButton(
                    icon: Icons.logout_rounded,
                    label: 'Sign Out',
                    color: const Color(0xFFEF4444),
                    onTap: () async {
                      await AuthRepository().logout();
                      if (!context.mounted) return;
                      context.go('/login');
                    },
                  ),
                  const SizedBox(height: 12),
                  // Delete Account
                  _buildActionButton(
                    icon: Icons.delete_forever_rounded,
                    label: 'Delete Account',
                    color: const Color(0xFFEF4444),
                    onTap: () async {
                      final confirm = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete Account?'),
                          content: const Text(
                              'This will permanently delete your account and all data. This action cannot be undone.'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx, false),
                                child: const Text('Cancel')),
                            TextButton(
                              onPressed: () => Navigator.pop(ctx, true),
                              child: const Text('Delete',
                                  style: TextStyle(color: Color(0xFFEF4444))),
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
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to delete account')),
                              );
                            }
                            return;
                          }
                        }
                        await AuthRepository().logout();
                        if (context.mounted) context.go('/login');
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, MediaQuery.of(context).padding.top + 12, 20, 20),
      color: const Color(0xFFF9F9FB),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  size: 16, color: AppColors.primary01),
            ),
          ),
          const SizedBox(width: 16),
          Text(
            'Settings',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.primary01,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileCard(BuildContext context) {
    final userName = StorageService().getString('user_name') ?? 'Customer';
    final userEmail = StorageService().getString('user_email') ?? '';
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary01,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2.5),
            ),
            child: ClipOval(
              child: Container(
                color: Colors.white.withValues(alpha: 0.2),
                child: Center(
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : 'C',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
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
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Colors.white)),
                const SizedBox(height: 2),
                Text(userEmail,
                    style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.6))),
              ],
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text('Edit',
                  style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: const Color(0xFF9CA3AF),
          letterSpacing: 1,
        ),
      ),
    );
  }

  Widget _buildToggleCard(List<_ToggleItem> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: item.iconColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.icon, color: item.iconColor, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.title,
                              style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary01)),
                          Text(item.subtitle,
                              style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  color: const Color(0xFF9CA3AF))),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: item.value,
                      onChanged: item.onChanged,
                      activeThumbColor: AppColors.primary01,
                      activeTrackColor: AppColors.primary01.withValues(alpha: 0.4),
                    ),
                  ],
                ),
              ),
              if (i < items.length - 1)
                const Divider(height: 1, indent: 70, color: Color(0xFFF3F4F6)),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildMenuCard(List<_MenuItem> items) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          return Column(
            children: [
              GestureDetector(
                onTap: item.onTap,
                child: Container(
                  color: Colors.transparent,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: item.iconColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(item.icon, color: item.iconColor, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(item.title,
                                style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary01)),
                            Text(item.subtitle,
                                style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: const Color(0xFF9CA3AF))),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: Color(0xFFD1D5DB), size: 20),
                    ],
                  ),
                ),
              ),
              if (i < items.length - 1)
                const Divider(height: 1, indent: 70, color: Color(0xFFF3F4F6)),
            ],
          );
        }),
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
