import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/features/shared/widgets/customer_bottom_navbar.dart';

import 'package:eventbridge/core/network/api_service.dart';

class CustomerProfileScreen extends StatefulWidget {
  const CustomerProfileScreen({super.key});

  @override
  State<CustomerProfileScreen> createState() => _CustomerProfileScreenState();
}

class _CustomerProfileScreenState extends State<CustomerProfileScreen> {
  String _name = 'Guest User';
  String _email = 'guest@eventbridge.ai';
  String _imageUrl = 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?q=80&w=200&auto=format&fit=crop';
  bool _allowLocation = true;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    try {
      final res = await ApiService.instance.getCustomerProfile('3'); // Using a dummy ID "3" for now
      if (res['success'] == true) {
        final profile = res['profile'];
        setState(() {
          _name = profile['name'] ?? _name;
          _email = profile['email'] ?? _email;
          if (profile['imageUrl'] != null && profile['imageUrl'].toString().isNotEmpty) {
            _imageUrl = profile['imageUrl'];
          }
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutrals01,
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary01))
          : SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _buildGradientHeader(context),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Account Settings'),
                        const SizedBox(height: 16),
                        _buildSettingsList(context),
                        const SizedBox(height: 100),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      bottomNavigationBar:
          const CustomerBottomNavbar(currentRoute: '/customer-profile'),
    );
  }

  Widget _buildGradientHeader(BuildContext context) {
    return Stack(
      children: [
        Container(
          height: 280,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.primary01, AppColors.primary02],
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(40)),
          ),
        ),
        Positioned.fill(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                        image: DecorationImage(
                          image: NetworkImage(_imageUrl),
                          fit: BoxFit.cover,
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
                        child: const Icon(Icons.camera_alt_rounded,
                            color: AppColors.primary01, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _name,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _email,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingsList(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildListItem(
                icon: Icons.person_outline_rounded,
                title: 'Name: $_name',
                onTap: _showEditProfileDialog,
              ),
              _divider(),
              _buildListItem(
                icon: Icons.email_outlined,
                title: 'Email: $_email',
                onTap: _showEditProfileDialog,
              ),
              _divider(),
              _buildListItem(
                icon: Icons.lock_outline_rounded,
                title: 'Change Password',
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Change password coming soon')),
                  );
                },
              ),
              _divider(),
              _buildListItem(
                icon: Icons.location_on_outlined,
                title: 'Allow Location',
                onTap: () {},
                trailing: Switch.adaptive(
                  value: _allowLocation,
                  onChanged: (val) {
                    setState(() => _allowLocation = val);
                  },
                  activeColor: AppColors.primary01,
                ),
              ),
              _divider(),
              _buildListItem(
                icon: Icons.logout_rounded,
                title: 'Log Out',
                titleColor: const Color(0xFFEF4444),
                onTap: () => context.go('/login'),
                showArrow: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _pickImage() async {
    // In a real app, use ImagePicker. For this mock, we'll just show a toast or a placeholder logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Image picker triggered (Simulated)')),
    );
  }

  void _showEditProfileDialog() {
    final nameController = TextEditingController(text: _name);
    final emailController = TextEditingController(text: _email);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit Profile',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: 'Email'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _name = nameController.text;
                _email = emailController.text;
              });
              Navigator.pop(context);
            },
            child: const Text('Save',
                style: TextStyle(color: AppColors.primary01)),
          ),
        ],
      ),
    );
  }

  Widget _buildListItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? titleColor,
    Widget? trailing,
    bool showArrow = true,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: (titleColor ?? AppColors.primary01).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: titleColor ?? AppColors.primary01, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: titleColor ?? AppColors.primary01,
                ),
              ),
            ),
            if (trailing != null) trailing else if (showArrow)
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _divider() => Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: 20),
        color: const Color(0xFFF1F5F9),
      );

  Widget _sectionTitle(String title) => Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: AppColors.primary01,
        ),
      );

  Widget _iconButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 24),
      ),
    );
  }
}

