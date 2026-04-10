import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/core/theme/design_tokens.dart';

/// Dialog for creating a new project
class CreateProjectDialog extends StatefulWidget {
  final Function(String name, String category, String description)
      onProjectCreate;

  const CreateProjectDialog({
    required this.onProjectCreate,
  });

  @override
  State<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<CreateProjectDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  String _selectedCategory = 'Weddings';
  bool _isLoading = false;

  final List<Map<String, dynamic>> categories = [
    {
      'name': 'Weddings',
      'icon': Icons.favorite_rounded,
      'color': Color(0xFFE11D48),
    },
    {
      'name': 'Corporate',
      'icon': Icons.business_center_rounded,
      'color': Color(0xFF3B82F6),
    },
    {
      'name': 'Parties',
      'icon': Icons.celebration_rounded,
      'color': Color(0xFFF59E0B),
    },
    {
      'name': 'Other',
      'icon': Icons.category_rounded,
      'color': Color(0xFF8B5CF6),
    },
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submitForm() {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a project name')),
      );
      return;
    }

    widget.onProjectCreate(
      _nameController.text.trim(),
      _selectedCategory,
      _descriptionController.text.trim(),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(SpacingTokens.lg),
      child: GestureDetector(
        onTap: () {}, // Prevent dismissing on tap
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkNeutral01 : Colors.white,
            borderRadius: BorderRadius.circular(RadiusTokens.round),
            boxShadow: [ShadowTokens.xlDark],
          ),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(SpacingTokens.xxl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'New Project',
                        style: GoogleFonts.outfit(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black,
                          letterSpacing: -0.5,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(SpacingTokens.sm),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.1)
                                : Colors.black.withOpacity(0.05),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            size: 20,
                            color: isDark ? Colors.white60 : Colors.black54,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Gaps.xl,

                  // Project Name Input
                  _buildInputField(
                    controller: _nameController,
                    label: 'Project Name',
                    hint: 'e.g. Sarah & John Wedding',
                    icon: Icons.title_rounded,
                    isDark: isDark,
                  ),
                  Gaps.xl,

                  // Category Selector
                  Text(
                    'Select Category',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Gaps.lg,
                  _buildCategoryGrid(isDark),
                  Gaps.xxl,

                  // Description Input (Optional)
                  _buildInputField(
                    controller: _descriptionController,
                    label: 'Description (Optional)',
                    hint: 'Add notes about this project...',
                    icon: Icons.description_rounded,
                    isDark: isDark,
                    maxLines: 3,
                  ),
                  Gaps.xxl,

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: SpacingTokens.lg,
                            ),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.white.withOpacity(0.05)
                                  : Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(RadiusTokens.lg),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white10
                                    : Colors.black.withOpacity(0.1),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Gaps.hLg,
                      Expanded(
                        child: GestureDetector(
                          onTap: _isLoading ? null : _submitForm,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: SpacingTokens.lg,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary01,
                              borderRadius: BorderRadius.circular(RadiusTokens.lg),
                              boxShadow: [ShadowTokens.getShadow(8)],
                            ),
                            child: Center(
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white,
                                        ),
                                      ),
                                    )
                                  : Text(
                                      'Create Project',
                                      style: GoogleFonts.outfit(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        Gaps.md,
        TextField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.outfit(
              color: isDark ? Colors.white38 : Colors.black38,
              fontSize: 14,
            ),
            prefixIcon: Icon(
              icon,
              color: AppColors.primary01,
              size: 20,
            ),
            filled: true,
            fillColor: isDark
                ? Colors.white.withOpacity(0.05)
                : Colors.black.withOpacity(0.03),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(RadiusTokens.lg),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withOpacity(0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(RadiusTokens.lg),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withOpacity(0.1),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(RadiusTokens.lg),
              borderSide: const BorderSide(
                color: AppColors.primary01,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: SpacingTokens.lg,
              vertical: SpacingTokens.lg,
            ),
          ),
          style: GoogleFonts.outfit(
            color: isDark ? Colors.white : Colors.black,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryGrid(bool isDark) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: SpacingTokens.lg,
      crossAxisSpacing: SpacingTokens.lg,
      children: categories.map((cat) {
        final isSelected = _selectedCategory == cat['name'];
        return GestureDetector(
          onTap: () => setState(() => _selectedCategory = cat['name']),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected
                  ? cat['color'].withOpacity(0.1)
                  : (isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.03)),
              borderRadius: BorderRadius.circular(RadiusTokens.lg),
              border: Border.all(
                color: isSelected
                    ? cat['color']
                    : (isDark
                        ? Colors.white10
                        : Colors.black.withOpacity(0.1)),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(SpacingTokens.md),
                  decoration: BoxDecoration(
                    color: cat['color'].withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    cat['icon'],
                    color: cat['color'],
                    size: 28,
                  ),
                ),
                Gaps.md,
                Text(
                  cat['name'],
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

/// Dialog for selecting/uploading images for a project
class ManageProjectImagesDialog extends StatefulWidget {
  final String projectName;
  final List<String> existingImages;
  final Function(List<String> imagesToAdd) onImagesSelect;

  const ManageProjectImagesDialog({
    required this.projectName,
    required this.existingImages,
    required this.onImagesSelect,
  });

  @override
  State<ManageProjectImagesDialog> createState() =>
      _ManageProjectImagesDialogState();
}

class _ManageProjectImagesDialogState extends State<ManageProjectImagesDialog> {
  List<String> _selectedImages = [];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(SpacingTokens.lg),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkNeutral01 : Colors.white,
          borderRadius: BorderRadius.circular(RadiusTokens.round),
          boxShadow: [ShadowTokens.xlDark],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(SpacingTokens.xxl),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Add Images',
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      Gaps.xs,
                      Text(
                        widget.projectName,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(SpacingTokens.sm),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.05),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.close_rounded,
                        size: 20,
                        color: isDark ? Colors.white60 : Colors.black54,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Divider(
              color: isDark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.08),
              height: 1,
            ),

            // Action Buttons
            Padding(
              padding: const EdgeInsets.all(SpacingTokens.xxl),
              child: Column(
                children: [
                  // Upload New Image
                  _buildActionButton(
                    icon: Icons.cloud_upload_rounded,
                    title: 'Upload New Image',
                    subtitle: 'Take photo or choose from device',
                    isDark: isDark,
                    onTap: () {
                      // This will be handled by parent
                      Navigator.pop(context, 'upload');
                    },
                  ),
                  Gaps.lg,

                  // Select Existing
                  _buildActionButton(
                    icon: Icons.image_search_rounded,
                    title: 'Select Existing Image',
                    subtitle: 'Choose from your portfolio',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context, 'select_existing');
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.lg),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.03),
          borderRadius: BorderRadius.circular(RadiusTokens.lg),
          border: Border.all(
            color: isDark
                ? Colors.white10
                : Colors.black.withOpacity(0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(SpacingTokens.md),
              decoration: BoxDecoration(
                color: AppColors.primary01.withOpacity(0.15),
                borderRadius: BorderRadius.circular(RadiusTokens.md),
              ),
              child: Icon(
                icon,
                color: AppColors.primary01,
                size: 24,
              ),
            ),
            Gaps.hLg,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Gaps.xs,
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white54 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
          ],
        ),
      ),
    );
  }
}
