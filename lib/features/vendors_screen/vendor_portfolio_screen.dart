import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/core/theme/app_theme.dart';
import 'package:eventbridge/core/network/api_service.dart';
import 'package:eventbridge/core/storage/storage_service.dart';
import 'package:eventbridge/core/services/upload_service.dart';
import 'package:eventbridge/core/widgets/app_toast.dart';
import 'package:eventbridge/features/matching/models/match_vendor.dart';
import 'package:eventbridge/features/vendors_screen/widgets/portfolio_dialogs.dart';
import 'package:eventbridge/features/vendors_screen/vendor_portfolio_detail_screen.dart';

class VendorPortfolioScreen extends StatefulWidget {
  const VendorPortfolioScreen({super.key});

  @override
  State<VendorPortfolioScreen> createState() => _VendorPortfolioScreenState();
}

class _VendorPortfolioScreenState extends State<VendorPortfolioScreen> {
  bool _isLoading = true;
  bool _isUploading = false;
  String _businessName = 'My Business';
  List<VendorProject> _projects = [];
  String _activeCategory = 'All';

  @override
  void initState() {
    super.initState();
    _loadPortfolio();
  }

  // ---------------------------------------------------------------------------
  // Data
  // ---------------------------------------------------------------------------

  List<String> get _categories {
    final detected = _projects.map(_projectCategory).toSet();
    final ordered =
        VendorProject.supportedCategories.where(detected.contains).toList();
    if (ordered.isEmpty) {
      return ['All', ...VendorProject.supportedCategories];
    }
    return ['All', ...ordered];
  }

  List<VendorProject> get _filteredProjects {
    if (_activeCategory == 'All') return _projects;
    return _projects
        .where((p) =>
            _projectCategory(p) == _activeCategory ||
            p.tags.contains(_activeCategory))
        .toList();
  }

  String _projectCategory(VendorProject project) {
    return VendorProject.inferCategory(
      title: project.title,
      description: project.description,
      rawCategory: project.category,
    );
  }

  String _displayTitle(VendorProject project) {
    final cleaned = project.title.trim();
    final category = _projectCategory(project);
    if (cleaned.isEmpty || cleaned.toLowerCase() == category.toLowerCase()) {
      return '$category Highlights';
    }
    return cleaned;
  }

  // ---------------------------------------------------------------------------
  // API
  // ---------------------------------------------------------------------------

  Future<void> _loadPortfolio() async {
    try {
      final userId = StorageService().getString('user_id');
      if (userId == null) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      final result = await ApiService.instance.getVendorProfile(userId);
      if (!mounted) return;

      if (result['success'] == true && result['profile'] != null) {
        final profile = result['profile'] as Map<String, dynamic>;
        final vendor = MatchVendor.fromJson(profile);
        setState(() {
          _businessName =
              vendor.name.isNotEmpty ? vendor.name : 'My Business';
          _projects = vendor.projects;
          _isLoading = false;
        });
        return;
      }
      setState(() => _isLoading = false);
    } catch (e) {
      if (!mounted) return;
      AppToast.show(context,
          message: 'Failed to load portfolio', type: ToastType.error);
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveChanges() async {
    try {
      final userId = StorageService().getString('user_id');
      if (userId == null) return;

      final result = await ApiService.instance.submitVendorOnboarding(
        userId: userId,
        businessName: _businessName,
        projects: _projects.map((p) => p.toJson()).toList(),
      );

      if (mounted && result['success'] == true) {
        AppToast.show(context,
            message: 'Portfolio updated', type: ToastType.success);
      }
    } catch (e) {
      debugPrint('Portfolio save failed: $e');
    }
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _showAddPortfolioDialog() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkNeutral02 : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).padding.bottom + 16,
          top: 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : AppColors.neutrals04,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add to Portfolio',
                    style: GoogleFonts.outfit(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'How would you like to organize your images?',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: isDark ? Colors.white60 : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildSheetOption(
                    icon: Icons.create_new_folder_rounded,
                    title: 'Create New Project',
                    subtitle: 'Start a new collection for a specific event',
                    isDark: isDark,
                    onTap: () => Navigator.pop(context, 'new_project'),
                  ),
                  const SizedBox(height: 12),
                  _buildSheetOption(
                    icon: Icons.folder_open_rounded,
                    title: 'Add to Existing Project',
                    subtitle: 'Upload new images to an existing project',
                    isDark: isDark,
                    onTap: () => Navigator.pop(context, 'existing_project'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;

    if (choice == 'new_project') {
      _showCreateProjectDialog();
    } else if (choice == 'existing_project') {
      await _selectProjectAndAddImages();
    }
  }

  Widget _buildSheetOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.card),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.primary01.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: AppColors.primary01, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      )),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color:
                            isDark ? Colors.white54 : AppColors.textSecondary,
                      )),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14,
                color: isDark ? Colors.white24 : AppColors.neutrals05),
          ],
        ),
      ),
    );
  }

  void _showCreateProjectDialog() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: CreateProjectDialog(
          onProjectCreate: (name, tags, description) {
            _pickAndUploadImage(
                projectName: name, tags: tags, description: description);
          },
        ),
      ),
    );
  }

  Future<void> _selectProjectAndAddImages() async {
    final selected = await showModalBottomSheet<VendorProject>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => SelectProjectDialog(projects: _projects),
    );
    if (!mounted || selected == null) return;

    final idx = _projects.indexWhere((p) => p.id == selected.id);
    await _pickAndUploadImage(
      projectName: selected.title,
      tags: selected.tags.isNotEmpty
          ? selected.tags
          : [_projectCategory(selected)],
      description: selected.description,
      existingIndex: idx >= 0 ? idx : null,
    );
  }

  Future<void> _pickAndUploadImage({
    required String projectName,
    required List<String> tags,
    String description = '',
    int? existingIndex,
  }) async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 72);
    if (images.isEmpty) return;

    setState(() => _isUploading = true);

    try {
      final urls = <String>[];
      for (var i = 0; i < images.length; i++) {
        final bytes = await images[i].readAsBytes();
        final fileName =
            'portfolio_${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
        final url = await UploadService.instance.uploadFile(
          bytes: bytes,
          fileName: fileName,
          contentType: 'image/jpeg',
          folder: 'portfolio',
        );
        urls.add(url);
      }

      if (!mounted) return;

      setState(() {
        if (existingIndex != null &&
            existingIndex >= 0 &&
            existingIndex < _projects.length) {
          final existing = _projects[existingIndex];
          final merged = [
            ...existing.images,
            ...urls.where((u) => !existing.images.contains(u)),
          ];
          _projects[existingIndex] = VendorProject(
            id: existing.id,
            title: existing.title,
            thumbnail: existing.thumbnail.isNotEmpty
                ? existing.thumbnail
                : urls.first,
            images: merged,
            category: existing.category,
            description: existing.description,
            tags: existing.tags,
          );
        } else {
          final primaryCat = tags.isNotEmpty
              ? VendorProject.normalizeCategory(tags.first)
              : 'Other';
          _projects.insert(
            0,
            VendorProject(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              title: projectName,
              thumbnail: urls.first,
              images: urls,
              category: primaryCat,
              description: description.trim(),
              tags: tags,
            ),
          );
        }
        _isUploading = false;
      });

      await _saveChanges();
      if (mounted) {
        AppToast.show(context,
            message:
                '${urls.length} photo${urls.length == 1 ? '' : 's'} added',
            type: ToastType.success);
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.show(context,
          message: 'Upload failed: $e', type: ToastType.error);
      setState(() => _isUploading = false);
    }
  }

  Future<void> _deleteProject(int index) async {
    final project = _projects[index];
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkNeutral02 : Colors.white,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 8,
            bottom: MediaQuery.of(ctx).padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white24 : AppColors.neutrals04,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.errorsMain.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.errorsMain, size: 28),
              ),
              const SizedBox(height: 16),
              Text('Delete Project',
                  style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color:
                          isDark ? Colors.white : AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text(
                'Delete "${_displayTitle(project)}" and all its images? This cannot be undone.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                    fontSize: 14,
                    color:
                        isDark ? Colors.white60 : AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(
                            color: isDark
                                ? Colors.white24
                                : AppColors.border),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.button)),
                      ),
                      child: Text('Cancel',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? Colors.white70
                                  : AppColors.textSecondary)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.errorsMain,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppRadius.button)),
                      ),
                      child: Text('Delete',
                          style: GoogleFonts.outfit(
                              fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _projects.removeAt(index);
      if (_activeCategory != 'All' &&
          !_projects.any((p) => _projectCategory(p) == _activeCategory)) {
        _activeCategory = 'All';
      }
    });
    await _saveChanges();
  }

  void _openProjectDetail(VendorProject project, int sourceIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => VendorPortfolioDetailScreen(
          project: project,
          title: _displayTitle(project),
          category: _projectCategory(project),
          onImagesChanged: (updatedImages) {
            setState(() {
              _projects[sourceIndex] = VendorProject(
                id: project.id,
                title: project.title,
                thumbnail:
                    updatedImages.isNotEmpty ? updatedImages.first : '',
                images: updatedImages,
                category: project.category,
                description: project.description,
                tags: project.tags,
              );
            });
            _saveChanges();
          },
          onDelete: () => _deleteProject(sourceIndex),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: Column(
        children: [
          _buildHeader(isDark),
          _buildFilterChips(isDark),
          Expanded(
            child: _isLoading
                ? const Center(
                    child:
                        CircularProgressIndicator(color: AppColors.primary01))
                : _filteredProjects.isEmpty
                    ? _buildEmptyState(isDark)
                    : _buildGrid(isDark),
          ),
        ],
      ),
      floatingActionButton: _isLoading
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 74),
              child: FloatingActionButton(
                onPressed: _showAddPortfolioDialog,
                backgroundColor: AppColors.primary01,
                elevation: 4,
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
              ),
            ),
      // Upload overlay
      resizeToAvoidBottomInset: false,
    );
  }

  // -- Header -----------------------------------------------------------------

  Widget _buildHeader(bool isDark) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(
        top: topPadding + 12,
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        bottom: 16,
      ),
      decoration: const BoxDecoration(
        color: AppColors.primary01,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(20),
          bottomRight: Radius.circular(20),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Text(
            'My Portfolio',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          if (!_isLoading)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha:0.2),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                '${_projects.length} Project${_projects.length == 1 ? '' : 's'}',
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // -- Filter chips -----------------------------------------------------------

  Widget _buildFilterChips(bool isDark) {
    return SizedBox(
      height: 52,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding:
            const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 10),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isActive = cat == _activeCategory;
          return GestureDetector(
            onTap: () => setState(() => _activeCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isActive
                    ? AppColors.primary01
                    : (isDark ? AppColors.darkNeutral02 : Colors.white),
                borderRadius: BorderRadius.circular(AppRadius.chip),
                border: isActive
                    ? null
                    : Border.all(color: AppColors.border, width: 1),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppColors.primary01.withValues(alpha:0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Text(
                cat,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                  color: isActive
                      ? Colors.white
                      : (isDark ? Colors.white70 : AppColors.textSecondary),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // -- Grid -------------------------------------------------------------------

  Widget _buildGrid(bool isDark) {
    return Stack(
      children: [
        GridView.builder(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg, 4, AppSpacing.lg, 90),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: _filteredProjects.length,
          itemBuilder: (context, index) {
            final project = _filteredProjects[index];
            final sourceIndex =
                _projects.indexWhere((p) => p.id == project.id);
            return _ProjectCard(
              project: project,
              title: _displayTitle(project),
              index: index,
              onTap: () => _openProjectDetail(
                  project, sourceIndex >= 0 ? sourceIndex : index),
              onLongPress: () => _deleteProject(
                  sourceIndex >= 0 ? sourceIndex : index),
            );
          },
        ),
        // Upload overlay
        if (_isUploading)
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha:0.5),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkNeutral02 : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(
                        width: 36,
                        height: 36,
                        child: CircularProgressIndicator(
                            strokeWidth: 3, color: AppColors.primary01),
                      ),
                      const SizedBox(height: 16),
                      Text('Uploading images...',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark
                                ? Colors.white
                                : AppColors.textPrimary,
                          )),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // -- Empty state ------------------------------------------------------------

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary01.withValues(alpha:0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.folder_outlined,
                  size: 40, color: AppColors.primary01),
            ),
            const SizedBox(height: 20),
            Text(
              _activeCategory == 'All'
                  ? 'No projects yet'
                  : 'No $_activeCategory projects',
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Showcase your work by adding your first project',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: isDark ? Colors.white60 : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _showAddPortfolioDialog,
              icon: const Icon(Icons.add_rounded, size: 20),
              label: Text('Add Project',
                  style: GoogleFonts.outfit(
                      fontSize: 15, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary01,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.button)),
              ),
            ),
          ],
        ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
      ),
    );
  }
}

// =============================================================================
// Project Folder Card
// =============================================================================

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    required this.project,
    required this.title,
    required this.index,
    required this.onTap,
    required this.onLongPress,
  });

  final VendorProject project;
  final String title;
  final int index;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasThumbnail = project.thumbnail.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.card),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha:isDark ? 0.3 : 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Thumbnail or placeholder
              if (hasThumbnail)
                Image.network(
                  project.thumbnail,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) =>
                      _buildPlaceholder(isDark),
                )
              else
                _buildPlaceholder(isDark),

              // Gradient scrim
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.4, 1.0],
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha:0.75),
                      ],
                    ),
                  ),
                ),
              ),

              // Image count badge (top-right)
              if (project.images.isNotEmpty)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary01,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.photo_library_rounded,
                            color: Colors.white, size: 12),
                        const SizedBox(width: 4),
                        Text(
                          '${project.images.length}',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              // Name + tags (bottom)
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: project.tags.take(2).map((tag) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha:0.2),
                            borderRadius:
                                BorderRadius.circular(AppRadius.chip),
                          ),
                          child: Text(
                            tag,
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha:0.9),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ).animate().fadeIn(duration: 300.ms, delay: (index * 80).ms).scale(
          begin: const Offset(0.95, 0.95),
          end: const Offset(1, 1),
          duration: 300.ms,
          delay: (index * 80).ms),
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      color: isDark ? AppColors.darkNeutral02 : AppColors.neutrals02,
      child: Center(
        child: Icon(
          Icons.folder_rounded,
          size: 40,
          color: isDark ? Colors.white24 : AppColors.neutrals05,
        ),
      ),
    );
  }
}
