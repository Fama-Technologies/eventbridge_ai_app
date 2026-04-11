import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/core/theme/design_tokens.dart';
import 'package:eventbridge/core/network/api_service.dart';
import 'package:eventbridge/core/storage/storage_service.dart';
import 'package:eventbridge/core/widgets/app_toast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:eventbridge/core/services/upload_service.dart';
import 'package:eventbridge/features/matching/models/match_vendor.dart';
import 'package:eventbridge/features/vendors_screen/widgets/portfolio_dialogs.dart';

class VendorPortfolioImproved extends StatefulWidget {
  const VendorPortfolioImproved({super.key});

  @override
  State<VendorPortfolioImproved> createState() =>
      _VendorPortfolioImprovedState();
}

class _VendorPortfolioImprovedState extends State<VendorPortfolioImproved> {
  bool _isLoading = true;
  bool _isUploading = false;
  String _businessName = 'My Business';
  List<VendorProject> _projects = [];
  String _activeCategory = 'All';
  final List<String> _categories = [
    'All',
    'Weddings',
    'Corporate',
    'Parties',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    _loadPortfolio();
  }

  Future<void> _loadPortfolio() async {
    try {
      final userId = StorageService().getString('user_id');
      if (userId == null) return;

      final result = await ApiService.instance.getVendorProfile(userId);
      if (result['success'] == true && result['profile'] != null) {
        final profile = result['profile'];
        final matchVendor = MatchVendor.fromJson(profile);
        setState(() {
          _businessName =
              matchVendor.name.isNotEmpty ? matchVendor.name : 'My Business';
          _projects = matchVendor.projects;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context,
            message: 'Failed to load portfolio', type: ToastType.error);
        setState(() => _isLoading = false);
      }
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
            message: 'Portfolio updated!', type: ToastType.success);
      }
    } catch (e) {
      debugPrint('Save failed: $e');
    }
  }

  void _showCreateProjectDialog() {
    showDialog(
      context: context,
      builder: (context) => CreateProjectDialog(
        onProjectCreate: (name, category, description) {
          // After project is created, show image picker
          _showManageImagesDialog(name, category, []);
        },
      ),
    );
  }

  void _showManageImagesDialog(
    String projectName,
    String category,
    List<String> existingImages,
  ) async {
    final result = await showDialog(
      context: context,
      builder: (context) => ManageProjectImagesDialog(
        projectName: projectName,
        existingImages: existingImages,
        onImagesSelect: (images) => print('Selected: $images'),
      ),
    );

    if (result == 'upload') {
      _pickAndUploadImage(projectName, category);
    } else if (result == 'select_existing') {
      _showSelectExistingImagesDialog(projectName, category);
    }
  }

  Future<void> _pickAndUploadImage(String projectName, String category) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() => _isUploading = true);
      try {
        final bytes = await image.readAsBytes();
        final fileName =
            'portfolio_${DateTime.now().millisecondsSinceEpoch}.jpg';

        final url = await UploadService.instance.uploadFile(
          bytes: bytes,
          fileName: fileName,
          contentType: 'image/jpeg',
          folder: 'portfolio',
        );

        if (mounted) {
          setState(() => _isUploading = false);

          // Add to project or create new one
          final existingProjectIdx =
              _projects.indexWhere((p) => p.title == projectName);
          if (existingProjectIdx != -1) {
            final p = _projects[existingProjectIdx];
            _projects[existingProjectIdx] = VendorProject(
              id: p.id,
              title: p.title,
              thumbnail: p.thumbnail,
              images: [...p.images, url],
            );
          } else {
            _projects.insert(
              0,
              VendorProject(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                title: projectName,
                thumbnail: url,
                images: [url],
              ),
            );
          }

          await _saveChanges();

          if (mounted) {
            AppToast.show(context,
                message: 'Image added!', type: ToastType.success);
          }
        }
      } catch (e) {
        if (mounted) {
          AppToast.show(context,
              message: 'Upload failed: $e', type: ToastType.error);
          setState(() => _isUploading = false);
        }
      }
    }
  }

  void _showSelectExistingImagesDialog(
    String projectName,
    String category,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(RadiusTokens.round),
            boxShadow: [ShadowTokens.xlDark],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(SpacingTokens.xxl),
                child: Text(
                  'Select from existing images',
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              // Grid of existing images from all projects
              GridView.builder(
                shrinkWrap: true,
                padding: const EdgeInsets.symmetric(
                    horizontal: SpacingTokens.xxl),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: SpacingTokens.lg,
                  crossAxisSpacing: SpacingTokens.lg,
                ),
                itemCount: _projects.fold<int>(
                  0,
                  (sum, p) => sum + p.images.length,
                ),
                itemBuilder: (context, index) {
                  // Flatten all images from all projects
                  int count = 0;
                  String? selectedImage;
                  for (var project in _projects) {
                    if (index < count + project.images.length) {
                      selectedImage = project.images[index - count];
                      break;
                    }
                    count += project.images.length;
                  }

                  if (selectedImage == null) return SizedBox.shrink();

                  return GestureDetector(
                    onTap: () {
                      // Add selected image to project
                      final existingProjectIdx = _projects
                          .indexWhere((p) => p.title == projectName);
                      if (existingProjectIdx != -1) {
                        final p = _projects[existingProjectIdx];
                        if (!p.images.contains(selectedImage)) {
                          _projects[existingProjectIdx] = VendorProject(
                            id: p.id,
                            title: p.title,
                            thumbnail: p.thumbnail,
                            images: [...p.images, selectedImage],
                          );
                        }
                      } else {
                        _projects.insert(
                          0,
                          VendorProject(
                            id:
                                DateTime.now().millisecondsSinceEpoch.toString(),
                            title: projectName,
                            thumbnail: selectedImage,
                            images: [selectedImage],
                          ),
                        );
                      }

                      Navigator.pop(context);
                      _saveChanges();
                      AppToast.show(context,
                          message: 'Image added!', type: ToastType.success);
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(RadiusTokens.lg),
                        image: DecorationImage(
                          image: NetworkImage(selectedImage),
                          fit: BoxFit.cover,
                        ),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(RadiusTokens.lg),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.3),
                            ],
                          ),
                        ),
                        child: const Align(
                          alignment: Alignment.bottomRight,
                          child: Padding(
                            padding: EdgeInsets.all(SpacingTokens.md),
                            child: Icon(
                              Icons.add_circle_rounded,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              Gaps.xxl,
            ],
          ),
        ),
      ),
    );
  }

  void _deleteProject(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => _buildDeleteConfirmDialog(context),
    );

    if (confirmed == true) {
      setState(() {
        _projects.removeAt(index);
      });
      await _saveChanges();
    }
  }

  void _editProject(int index) {
    final project = _projects[index];
    _showManageImagesDialog(project.title, project.title, project.images);
  }

  void _openProjectDetail(VendorProject project, int index) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, _) => FadeTransition(
          opacity: animation,
          child: _ProjectImageViewerPage(
            project: project,
            index: index,
            totalProjects: _projects.length,
            onDelete: () {
              Navigator.pop(context);
              _deleteProject(index);
            },
            onEdit: () {
              Navigator.pop(context);
              _editProject(index);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      floatingActionButton: _buildFAB(isDark),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: AppColors.primary01),
            )
          : CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                _buildHeader(isDark),
                _buildCategoryFilter(isDark),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    SpacingTokens.xxl,
                    SpacingTokens.xxl,
                    SpacingTokens.xxl,
                    SpacingTokens.huge,
                  ),
                  sliver: _buildPortfolioGrid(isDark),
                ),
              ],
            ),
    );
  }

  Widget _buildFAB(bool isDark) {
    return FloatingActionButton.extended(
      onPressed: _isUploading ? null : _showCreateProjectDialog,
      backgroundColor: AppColors.primary01,
      foregroundColor: Colors.white,
      icon: _isUploading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Icon(Icons.add_rounded),
      label: Text(
        _isUploading ? 'Uploading...' : 'New Project',
        style: GoogleFonts.outfit(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    ).animate().scale(delay: 400.ms, curve: Curves.easeOutBack);
  }

  Widget _buildHeader(bool isDark) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor:
          isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: isDark ? Colors.white : Colors.black87,
          size: 20,
        ),
        onPressed: () => context.pop(),
      ),
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Background image or gradient
            if (_projects.isNotEmpty)
              Image.network(
                _projects.first.thumbnail,
                fit: BoxFit.cover,
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary01.withOpacity(0.15),
                      AppColors.primary01.withOpacity(0.08),
                    ],
                  ),
                ),
              ),

            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    isDark
                        ? Colors.black.withOpacity(0.2)
                        : Colors.white.withOpacity(0.1),
                    Colors.transparent,
                    isDark
                        ? AppColors.backgroundDark.withOpacity(0.8)
                        : const Color(0xFFF8FAFC).withOpacity(0.8),
                    isDark ? AppColors.backgroundDark : const Color(0xFFF8FAFC),
                  ],
                ),
              ),
            ),

            // Header content
            Positioned(
              left: SpacingTokens.xxl,
              right: SpacingTokens.xxl,
              bottom: SpacingTokens.lg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpacingTokens.md,
                      vertical: SpacingTokens.xs,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(RadiusTokens.md),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: Color(0xFF22C55E),
                            shape: BoxShape.circle,
                          ),
                        ),
                        Gaps.hSm,
                        Text(
                          'PUBLIC PORTFOLIO',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Gaps.lg,

                  // Business name
                  Text(
                    _businessName,
                    style: GoogleFonts.outfit(
                      fontSize: 40,
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: -1.5,
                      height: 1.1,
                    ),
                  ),
                  Gaps.lg,

                  // Stats
                  Row(
                    children: [
                      _buildHeaderBadge(
                        '${_projects.length}',
                        'Projects',
                        Icons.folder_rounded,
                        AppColors.primary01,
                        isDark,
                      ),
                      Gaps.hLg,
                      _buildHeaderBadge(
                        '${_projects.fold<int>(0, (sum, p) => sum + p.images.length)}',
                        'Images',
                        Icons.image_rounded,
                        const Color(0xFF3B82F6),
                        isDark,
                      ),
                    ],
                  ),
                ].animate(interval: 50.ms).fadeIn().slideY(begin: 0.1, end: 0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBadge(
    String value,
    String label,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: SpacingTokens.md,
        vertical: SpacingTokens.sm,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(RadiusTokens.md),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          Gaps.hSm,
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter(bool isDark) {
    return SliverToBoxAdapter(
      child: Container(
        height: 60,
        padding: const EdgeInsets.symmetric(vertical: SpacingTokens.lg),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: SpacingTokens.xxl),
          itemCount: _categories.length,
          itemBuilder: (context, index) {
            final cat = _categories[index];
            final isActive = _activeCategory == cat;
            return GestureDetector(
              onTap: () => setState(() => _activeCategory = cat),
              child: AnimatedContainer(
                duration: 300.ms,
                margin: const EdgeInsets.only(right: SpacingTokens.md),
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.lg,
                  vertical: SpacingTokens.sm,
                ),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.primary01
                      : (isDark
                          ? Colors.white.withOpacity(0.05)
                          : Colors.black.withOpacity(0.05)),
                  borderRadius: BorderRadius.circular(RadiusTokens.full),
                  border: Border.all(
                    color: isActive
                        ? AppColors.primary01
                        : (isDark
                            ? Colors.white10
                            : Colors.black.withOpacity(0.1)),
                  ),
                  boxShadow: isActive ? [ShadowTokens.getShadow(4)] : null,
                ),
                child: Center(
                  child: Text(
                    cat,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight:
                          isActive ? FontWeight.w800 : FontWeight.w600,
                      color: isActive
                          ? Colors.white
                          : (isDark ? Colors.white60 : Colors.black54),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPortfolioGrid(bool isDark) {
    final filteredProjects = _activeCategory == 'All'
        ? _projects
        : _projects.where((p) => p.title == _activeCategory).toList();

    if (filteredProjects.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(SpacingTokens.xxl),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.05),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.photo_library_outlined,
                  size: 48,
                  color: isDark ? Colors.white.withOpacity(0.24) : Colors.black.withOpacity(0.24),
                ),
              ),
              Gaps.xxl,
              Text(
                _activeCategory == 'All'
                    ? 'No projects yet'
                    : 'No $_activeCategory projects',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Gaps.lg,
              Text(
                'Tap "New Project" to get started',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white54 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SliverGrid(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: SpacingTokens.lg,
        crossAxisSpacing: SpacingTokens.lg,
        childAspectRatio: 0.7,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final project = filteredProjects[index];

          return GestureDetector(
            onTap: () => _openProjectDetail(project, index),
            child: Hero(
              tag: 'portfolio_$index',
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(RadiusTokens.xxl),
                  boxShadow: [ShadowTokens.getShadow(8, isDark: isDark)],
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(RadiusTokens.xxl),
                      child: Image.network(
                        project.thumbnail,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.05),
                        ),
                      ),
                    ),

                    // Gradient overlay
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(RadiusTokens.xxl),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.4, 1.0],
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.7),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Bottom info & actions
                    Positioned(
                      left: SpacingTokens.lg,
                      right: SpacingTokens.lg,
                      bottom: SpacingTokens.lg,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Category badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: SpacingTokens.md,
                              vertical: SpacingTokens.xs,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary01.withOpacity(0.9),
                              borderRadius:
                                  BorderRadius.circular(RadiusTokens.md),
                            ),
                            child: Text(
                              project.title.toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          Gaps.md,

                          // Image count
                          Text(
                            '${project.images.length} Image${project.images.length != 1 ? 's' : ''}',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Edit/Delete buttons (top right)
                    Positioned(
                      top: SpacingTokens.md,
                      right: SpacingTokens.md,
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: () => _editProject(index),
                            child: Container(
                              padding: const EdgeInsets.all(SpacingTokens.sm),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                                backdropFilter:
                                    ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              ),
                              child: const Icon(
                                Icons.edit_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                            ),
                          ),
                          Gaps.hSm,
                          GestureDetector(
                            onTap: () => _deleteProject(index),
                            child: Container(
                              padding: const EdgeInsets.all(SpacingTokens.sm),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.2),
                                shape: BoxShape.circle,
                                backdropFilter:
                                    ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              ),
                              child: const Icon(
                                Icons.delete_rounded,
                                color: Colors.redAccent,
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
              .animate(delay: (index * 80).ms)
              .fadeIn(duration: 400.ms)
              .scale(begin: const Offset(0.95, 0.95));
        },
        childCount: filteredProjects.length,
      ),
    );
  }

  Widget _buildDeleteConfirmDialog(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(SpacingTokens.xxl),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkNeutral01 : Colors.white,
          borderRadius: BorderRadius.circular(RadiusTokens.xxl),
          border: Border.all(
            color: Colors.redAccent.withOpacity(0.1),
          ),
          boxShadow: [ShadowTokens.xlDark],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(SpacingTokens.lg),
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_sweep_rounded,
                color: Colors.redAccent,
                size: 32,
              ),
            ),
            Gaps.xl,
            Text(
              'Delete Project?',
              style: GoogleFonts.outfit(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            Gaps.lg,
            Text(
              'This will permanently remove this project from your portfolio.',
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: isDark ? Colors.white54 : Colors.black54,
                height: 1.5,
              ),
            ),
            Gaps.xxl,
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context, false),
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
                    onTap: () => Navigator.pop(context, true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        vertical: SpacingTokens.lg,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(RadiusTokens.lg),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.redAccent.withOpacity(0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          'Delete',
                          style: GoogleFonts.outfit(
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
    );
  }
}

/// Full-screen image viewer for project detail
class _ProjectImageViewerPage extends StatefulWidget {
  final VendorProject project;
  final int index;
  final int totalProjects;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _ProjectImageViewerPage({
    required this.project,
    required this.index,
    required this.totalProjects,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  State<_ProjectImageViewerPage> createState() =>
      _ProjectImageViewerPageState();
}

class _ProjectImageViewerPageState extends State<_ProjectImageViewerPage> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.95),
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Image viewer
          Hero(
            tag: 'portfolio_${widget.index}',
            child: PageView.builder(
              controller: _pageController,
              onPageChanged: (idx) => setState(() => _currentIndex = idx),
              itemCount: widget.project.images.length,
              itemBuilder: (context, idx) {
                return Image.network(
                  widget.project.images[idx],
                  fit: BoxFit.contain,
                );
              },
            ),
          ),

          // Header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: SpacingTokens.lg,
                  vertical: SpacingTokens.lg,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(SpacingTokens.sm),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                          backdropFilter:
                              ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 24,
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        GestureDetector(
                          onTap: widget.onEdit,
                          child: Container(
                            padding: const EdgeInsets.all(SpacingTokens.sm),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.1),
                              shape: BoxShape.circle,
                              backdropFilter:
                                  ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            ),
                            child: const Icon(
                              Icons.edit_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                        Gaps.hMd,
                        GestureDetector(
                          onTap: widget.onDelete,
                          child: Container(
                            padding: const EdgeInsets.all(SpacingTokens.sm),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.2),
                              shape: BoxShape.circle,
                              backdropFilter:
                                  ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            ),
                            child: const Icon(
                              Icons.delete_rounded,
                              color: Colors.redAccent,
                              size: 20,
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

          // Bottom info
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(SpacingTokens.lg),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.8),
                  ],
                ),
              ),
              child: SafeArea(
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: SpacingTokens.lg,
                      vertical: SpacingTokens.md,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(RadiusTokens.full),
                      backdropFilter:
                          ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.2),
                      ),
                    ),
                    child: Text(
                      '${_currentIndex + 1} of ${widget.project.images.length}',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
