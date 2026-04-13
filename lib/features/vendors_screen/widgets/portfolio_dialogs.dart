import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/core/theme/design_tokens.dart';
import 'package:eventbridge/features/matching/models/match_vendor.dart';

/// Dialog for creating a new project
class CreateProjectDialog extends StatefulWidget {
  final Function(String name, List<String> tags, String description)
  onProjectCreate;

  const CreateProjectDialog({super.key, required this.onProjectCreate});

  @override
  State<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<CreateProjectDialog> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  final Set<String> _selectedTags = {'Weddings'}; // multi-select

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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter a project name')));
      return;
    }
    if (_selectedTags.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please select at least one tag')));
      return;
    }

    widget.onProjectCreate(
      _nameController.text.trim(),
      _selectedTags.toList(),
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
                                ? Colors.white.withValues(alpha: 0.1)
                                : Colors.black.withValues(alpha: 0.05),
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

                  // Category / Tag Multi-Selector
                  Text(
                    'Select Tags',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  Gaps.xs,
                  Text(
                    'Pick all that apply — projects can span multiple categories.',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white54 : Colors.black45,
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
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.black.withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(
                                RadiusTokens.lg,
                              ),
                              border: Border.all(
                                color: isDark
                                    ? Colors.white10
                                    : Colors.black.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Center(
                              child: Text(
                                'Cancel',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white60
                                      : Colors.black54,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Gaps.hLg,
                      Expanded(
                        child: GestureDetector(
                          onTap: _submitForm,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: SpacingTokens.lg,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary01,
                              borderRadius: BorderRadius.circular(
                                RadiusTokens.lg,
                              ),
                              boxShadow: [ShadowTokens.getShadow(8)],
                            ),
                            child: Center(
                              child: Text(
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
            prefixIcon: Icon(icon, color: AppColors.primary01, size: 20),
            filled: true,
            fillColor: isDark
                ? Colors.white.withValues(alpha: 0.05)
                : Colors.black.withValues(alpha: 0.03),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(RadiusTokens.lg),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(RadiusTokens.lg),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white10
                    : Colors.black.withValues(alpha: 0.1),
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
      childAspectRatio: 2.2,
      children: categories.map((cat) {
        final isSelected = _selectedTags.contains(cat['name']);
        return GestureDetector(
          onTap: () => setState(() {
            if (isSelected) {
              // Keep at least one tag selected
              if (_selectedTags.length > 1) {
                _selectedTags.remove(cat['name']);
              }
            } else {
              _selectedTags.add(cat['name'] as String);
            }
          }),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: isSelected
                  ? (cat['color'] as Color).withValues(alpha: 0.12)
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.03)),
              borderRadius: BorderRadius.circular(RadiusTokens.lg),
              border: Border.all(
                color: isSelected
                    ? (cat['color'] as Color)
                    : (isDark
                          ? Colors.white10
                          : Colors.black.withValues(alpha: 0.1)),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  cat['icon'] as IconData,
                  color: isSelected
                      ? (cat['color'] as Color)
                      : (isDark ? Colors.white54 : Colors.black38),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  cat['name'] as String,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                    color: isSelected
                        ? (isDark ? Colors.white : Colors.black87)
                        : (isDark ? Colors.white60 : Colors.black54),
                  ),
                ),
                if (isSelected) ...[
                  const SizedBox(width: 6),
                  Icon(
                    Icons.check_circle_rounded,
                    size: 14,
                    color: cat['color'] as Color,
                  ),
                ],
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
    super.key,
    required this.projectName,
    required this.existingImages,
    required this.onImagesSelect,
  });

  @override
  State<ManageProjectImagesDialog> createState() =>
      _ManageProjectImagesDialogState();
}

class _ManageProjectImagesDialogState extends State<ManageProjectImagesDialog> {
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
                            ? Colors.white.withValues(alpha: 0.1)
                            : Colors.black.withValues(alpha: 0.05),
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
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.08),
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
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.03),
          borderRadius: BorderRadius.circular(RadiusTokens.lg),
          border: Border.all(
            color: isDark
                ? Colors.white10
                : Colors.black.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(SpacingTokens.md),
              decoration: BoxDecoration(
                color: AppColors.primary01.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(RadiusTokens.md),
              ),
              child: Icon(icon, color: AppColors.primary01, size: 24),
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

/// Dialog for choosing between creating a new project or adding to an existing one
class PortfolioActionDialog extends StatelessWidget {
  const PortfolioActionDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(SpacingTokens.lg),
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.xxl),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkNeutral01 : Colors.white,
          borderRadius: BorderRadius.circular(RadiusTokens.round),
          boxShadow: [ShadowTokens.xlDark],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                      'Add to Portfolio',
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : Colors.black,
                        letterSpacing: -0.5,
                      ),
                    )
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideX(begin: -0.2, end: 0),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(SpacingTokens.sm),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.1)
                          : Colors.black.withValues(alpha: 0.05),
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
            Text(
              'How would you like to organize your images?',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ).animate().fadeIn(delay: 100.ms, duration: 400.ms),
            Gaps.xxl,
            _buildActionCard(
              context: context,
              icon: Icons.create_new_folder_rounded,
              title: 'Create New Project',
              subtitle: 'Start a new collection for a specific event or shoot.',
              color: AppColors.primary01,
              isDark: isDark,
              onTap: () => Navigator.pop(context, 'new_project'),
            ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
            Gaps.lg,
            _buildActionCard(
              context: context,
              icon: Icons.folder_open_rounded,
              title: 'Add to Existing Project',
              subtitle:
                  'Select an existing project and upload new images to it.',
              color: const Color(0xFF3B82F6),
              isDark: isDark,
              onTap: () => Navigator.pop(context, 'existing_project'),
            ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.xl),
        decoration: BoxDecoration(
          color: color.withValues(alpha: isDark ? 0.08 : 0.04),
          borderRadius: BorderRadius.circular(RadiusTokens.xxl),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.2 : 0.1),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(SpacingTokens.lg),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(RadiusTokens.lg),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            Gaps.hLg,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  Gaps.xs,
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white60 : Colors.black54,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            Gaps.hMd,
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: color.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

/// Dialog for selecting an existing project from the current list
class SelectProjectDialog extends StatelessWidget {
  final List<VendorProject> projects;

  const SelectProjectDialog({super.key, required this.projects});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.all(SpacingTokens.lg),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkNeutral01 : Colors.white,
          borderRadius: BorderRadius.circular(RadiusTokens.round),
          boxShadow: [ShadowTokens.xlDark],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(SpacingTokens.xxl),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Select Project',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Icon(
                      Icons.close_rounded,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),

            if (projects.isEmpty)
              Padding(
                padding: const EdgeInsets.all(SpacingTokens.xxl),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.folder_off_rounded,
                        size: 48,
                        color: isDark
                            ? Colors.white24
                            : Colors.black.withValues(alpha: 0.24),
                      ),
                      Gaps.lg,
                      Text(
                        'No projects found',
                        style: GoogleFonts.outfit(
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(
                    SpacingTokens.xxl,
                    0,
                    SpacingTokens.xxl,
                    SpacingTokens.xxl,
                  ),
                  itemCount: projects.length,
                  separatorBuilder: (context, index) => Gaps.md,
                  itemBuilder: (context, index) {
                    final project = projects[index];
                    return GestureDetector(
                      onTap: () => Navigator.pop(context, project),
                      child: Container(
                        padding: const EdgeInsets.all(SpacingTokens.md),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withValues(alpha: 0.03)
                              : Colors.black.withValues(alpha: 0.02),
                          borderRadius: BorderRadius.circular(RadiusTokens.xl),
                          border: Border.all(
                            color: isDark
                                ? Colors.white10
                                : Colors.black.withValues(alpha: 0.05),
                          ),
                        ),
                        child: Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                RadiusTokens.lg,
                              ),
                              child: Container(
                                width: 60,
                                height: 60,
                                color: isDark
                                    ? Colors.white10
                                    : Colors.black.withValues(alpha: 0.1),
                                child: Image.network(
                                  project.thumbnail,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(
                                        Icons.image_rounded,
                                        color: Colors.grey,
                                      ),
                                ),
                              ),
                            ),
                            Gaps.hLg,
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    project.title,
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                  Gaps.xs,
                                  Text(
                                    '${project.images.length} images',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: isDark
                                          ? Colors.white54
                                          : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
