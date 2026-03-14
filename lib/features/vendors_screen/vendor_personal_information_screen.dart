import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eventbridge_ai/core/theme/app_colors.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge_ai/core/storage/storage_service.dart';
import 'package:eventbridge_ai/core/network/api_service.dart';
import 'package:eventbridge_ai/core/services/upload_service.dart';
import 'package:eventbridge_ai/core/widgets/app_toast.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class VendorPersonalInformationScreen extends StatefulWidget {
  const VendorPersonalInformationScreen({super.key});

  @override
  State<VendorPersonalInformationScreen> createState() =>
      _VendorPersonalInformationScreenState();
}

class _VendorPersonalInformationScreenState
    extends State<VendorPersonalInformationScreen> {
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  String? _userImage;
  bool _isUpdatingAvatar = false;

  @override
  void initState() {
    super.initState();
    _loadPersonalInfo();
  }

  Future<void> _loadPersonalInfo() async {
    final storage = StorageService();
    final fullName = storage.getString('user_name') ?? '';
    final email = storage.getString('user_email') ?? '';
    final image = storage.getString('user_image');
    final parts = fullName.trim().split(' ');
    
    if (mounted) {
      setState(() {
        _firstNameCtrl.text = parts.isNotEmpty ? parts[0] : '';
        _lastNameCtrl.text = parts.length > 1 ? parts.sublist(1).join(' ') : '';
        _emailCtrl.text = email;
        _userImage = (image != null && image.isNotEmpty) ? image : null;
      });
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
        fileName: 'avatar_${userId}_${DateTime.now().millisecondsSinceEpoch}.jpg',
        contentType: 'image/jpeg',
        folder: 'avatars/$userId',
      );

      // Update account with new avatar
      await ApiService.instance.submitVendorOnboarding(
        userId: userId,
        businessName: storage.getString('business_name') ?? 'Vendor',
        serviceCategories: [],
        avatarUrl: avatarUrl,
      );

      // Persist locally
      await storage.setString('user_image', avatarUrl);
      
      if (mounted) {
        setState(() => _userImage = avatarUrl);
        AppToast.show(context, message: 'Profile picture updated!', type: ToastType.success);
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, message: 'Failed to update avatar', type: ToastType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isUpdatingAvatar = false);
      }
    }
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? AppColors.darkNeutral01 : const Color(0xFFF7F7F8);
    final textPrimary = isDark ? AppColors.shadesWhite : const Color(0xFF1E293B);
    final cardColor = isDark ? AppColors.darkNeutral02 : Colors.white;
    final borderColor = isDark ? AppColors.darkNeutral03 : const Color(0xFFF1F5F9);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'Personal Information',
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          decoration: BoxDecoration(
            color: cardColor,
            shape: BoxShape.circle,
            border: Border.all(color: borderColor),
          ),
          child: IconButton(
            icon: Icon(Icons.chevron_left_rounded, color: textPrimary, size: 24),
            onPressed: () => context.pop(),
            padding: EdgeInsets.zero,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: _isUpdatingAvatar ? null : _pickAndUploadAvatar,
                child: Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? AppColors.darkNeutral03 : AppColors.neutrals02,
                        border: Border.all(
                          color: AppColors.primary01.withOpacity(0.2),
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: _isUpdatingAvatar 
                          ? const Center(child: CircularProgressIndicator(strokeWidth: 3))
                          : (_userImage != null && _userImage!.isNotEmpty
                              ? Image.network(
                                  _userImage!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => _buildInitialsPlaceholder(),
                                )
                              : _buildInitialsPlaceholder()),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: AppColors.primary01,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Basic Details',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildInputField(
              label: 'First Name',
              controller: _firstNameCtrl,
              cardColor: cardColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              label: 'Last Name',
              controller: _lastNameCtrl,
              cardColor: cardColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              label: 'Email Address',
              controller: _emailCtrl,
              cardColor: cardColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              inputType: TextInputType.emailAddress,
            ),
            
            const SizedBox(height: 32),
            Text(
              'Change Password',
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            _buildInputField(
              label: 'Current Password',
              controller: _currentPasswordCtrl,
              cardColor: cardColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              obscureText: true,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              label: 'New Password',
              controller: _newPasswordCtrl,
              cardColor: cardColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              obscureText: true,
            ),
            const SizedBox(height: 16),
            _buildInputField(
              label: 'Confirm New Password',
              controller: _confirmPasswordCtrl,
              cardColor: cardColor,
              borderColor: borderColor,
              textPrimary: textPrimary,
              obscureText: true,
            ),

            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  // Simulate save
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Personal information saved')),
                  );
                  context.pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary01,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'Save Changes',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required Color cardColor,
    required Color borderColor,
    required Color textPrimary,
    bool obscureText = false,
    TextInputType inputType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: TextField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: inputType,
            style: GoogleFonts.roboto(
              fontSize: 15,
              color: textPrimary,
            ),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.all(18),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildInitialsPlaceholder() {
    final storage = StorageService();
    final fullName = storage.getString('user_name') ?? 'Vendor';
    String initials = 'V';
    if (fullName.trim().isNotEmpty) {
      final parts = fullName.trim().split(' ');
      if (parts.length >= 2) {
        initials = (parts[0][0] + parts[1][0]).toUpperCase();
      } else if (parts[0].isNotEmpty) {
        initials = parts[0][0].toUpperCase();
      }
    }
    return Container(
      color: const Color(0xFFE5E7EB),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: const TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: Color(0xFF4B5563),
        ),
      ),
    );
  }
}
