import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/core/theme/app_theme.dart';
import 'package:eventbridge/core/services/upload_service.dart';
import 'package:eventbridge/core/widgets/app_toast.dart';
import 'package:eventbridge/features/matching/models/match_vendor.dart';


class VendorPortfolioDetailScreen extends StatefulWidget {
  const VendorPortfolioDetailScreen({
    super.key,
    required this.project,
    required this.title,
    required this.category,
    required this.onImagesChanged,
    required this.onDelete,
  });

  final VendorProject project;
  final String title;
  final String category;
  final ValueChanged<List<String>> onImagesChanged;
  final VoidCallback onDelete;

  @override
  State<VendorPortfolioDetailScreen> createState() =>
      _VendorPortfolioDetailScreenState();
}

class _VendorPortfolioDetailScreenState
    extends State<VendorPortfolioDetailScreen> {
  late List<String> _images;
  bool _isUploading = false;
  bool _isSelectMode = false;
  final Set<int> _selectedIndices = {};

  @override
  void initState() {
    super.initState();
    _images = List<String>.from(widget.project.images);
  }

  // ---------------------------------------------------------------------------
  // Actions
  // ---------------------------------------------------------------------------

  Future<void> _uploadImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 72);
    if (picked.isEmpty) return;

    setState(() => _isUploading = true);

    try {
      final urls = <String>[];
      for (var i = 0; i < picked.length; i++) {
        final bytes = await picked[i].readAsBytes();
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
        _images.addAll(urls);
        _isUploading = false;
      });
      widget.onImagesChanged(_images);

      if (mounted) {
        AppToast.show(context,
            message:
                '${urls.length} photo${urls.length == 1 ? '' : 's'} added',
            type: ToastType.success);
      }
    } catch (e) {
      if (!mounted) return;
      AppToast.show(context,
          message: 'Upload failed', type: ToastType.error);
      setState(() => _isUploading = false);
    }
  }

  void _toggleSelectMode() {
    setState(() {
      _isSelectMode = !_isSelectMode;
      _selectedIndices.clear();
    });
  }

  void _deleteSelected() async {
    if (_selectedIndices.isEmpty) return;

    final count = _selectedIndices.length;
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
              Text('Delete $count image${count == 1 ? '' : 's'}?',
                  style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color:
                          isDark ? Colors.white : AppColors.textPrimary)),
              const SizedBox(height: 8),
              Text(
                'This cannot be undone.',
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
      final sorted = _selectedIndices.toList()..sort((a, b) => b.compareTo(a));
      for (final idx in sorted) {
        if (idx < _images.length) _images.removeAt(idx);
      }
      _isSelectMode = false;
      _selectedIndices.clear();
    });
    widget.onImagesChanged(_images);
  }

  void _openFullScreenViewer(int initialIndex) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenImageViewer(
          images: _images,
          initialIndex: initialIndex,
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
          _buildInfoBar(isDark),
          Expanded(
            child: _images.isEmpty
                ? _buildEmptyState(isDark)
                : _buildImageGrid(isDark),
          ),
        ],
      ),
      floatingActionButton: _isSelectMode
          ? null
          : Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: FloatingActionButton(
                onPressed: _isUploading ? null : _uploadImages,
                backgroundColor: AppColors.primary01,
                elevation: 4,
                child: _isUploading
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                            strokeWidth: 2.5, color: Colors.white))
                    : const Icon(
                        Icons.add_a_photo_rounded, color: Colors.white),
              ),
            ),
    );
  }

  // -- Header -----------------------------------------------------------------

  Widget _buildHeader(bool isDark) {
    final topPadding = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.only(
        top: topPadding + 12,
        left: AppSpacing.lg,
        right: 8,
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
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              widget.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          if (_isSelectMode) ...[
            TextButton(
              onPressed: _deleteSelected,
              child: Text(
                'Delete (${_selectedIndices.length})',
                style: GoogleFonts.outfit(
                    color: Colors.white, fontWeight: FontWeight.w600),
              ),
            ),
            IconButton(
              onPressed: _toggleSelectMode,
              icon: const Icon(Icons.close_rounded, color: Colors.white),
            ),
          ] else
            PopupMenuButton<String>(
              icon:
                  const Icon(Icons.more_vert_rounded, color: Colors.white),
              color: isDark ? AppColors.darkNeutral02 : Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onSelected: (value) {
                if (value == 'select') _toggleSelectMode();
                if (value == 'delete') {
                  Navigator.pop(context);
                  widget.onDelete();
                }
              },
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'select',
                  child: Row(
                    children: [
                      Icon(Icons.check_circle_outline_rounded,
                          size: 20,
                          color: isDark
                              ? Colors.white70
                              : AppColors.textPrimary),
                      const SizedBox(width: 8),
                      Text('Select images',
                          style: GoogleFonts.outfit(
                              color: isDark
                                  ? Colors.white
                                  : AppColors.textPrimary)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      const Icon(Icons.delete_outline_rounded,
                          size: 20, color: AppColors.errorsMain),
                      const SizedBox(width: 8),
                      Text('Delete project',
                          style: GoogleFonts.outfit(
                              color: AppColors.errorsMain)),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  // -- Info bar ---------------------------------------------------------------

  Widget _buildInfoBar(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: 12),
      color: isDark ? AppColors.darkNeutral02 : Colors.white,
      child: Row(
        children: [
          // Tags
          Expanded(
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: widget.project.tags.map((tag) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary01.withValues(alpha:0.1),
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Text(
                    tag,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary01,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          // Photo count
          Text(
            '${_images.length} photo${_images.length == 1 ? '' : 's'}',
            style: GoogleFonts.outfit(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  // -- Image grid -------------------------------------------------------------

  Widget _buildImageGrid(bool isDark) {
    return GridView.builder(
      padding: const EdgeInsets.all(4),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 4,
        mainAxisSpacing: 4,
      ),
      itemCount: _images.length,
      itemBuilder: (context, index) {
        final image = _images[index];
        final isSelected = _selectedIndices.contains(index);

        return GestureDetector(
          onTap: () {
            if (_isSelectMode) {
              setState(() {
                if (isSelected) {
                  _selectedIndices.remove(index);
                } else {
                  _selectedIndices.add(index);
                }
              });
            } else {
              _openFullScreenViewer(index);
            }
          },
          onLongPress: () {
            if (!_isSelectMode) {
              setState(() {
                _isSelectMode = true;
                _selectedIndices.add(index);
              });
            }
          },
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.network(
                image,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: isDark ? AppColors.darkNeutral02 : AppColors.neutrals02,
                  child: const Icon(Icons.broken_image_rounded,
                      color: Colors.grey),
                ),
              ),
              if (_isSelectMode)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  color: isSelected
                      ? AppColors.primary01.withValues(alpha:0.3)
                      : Colors.transparent,
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary01
                              : Colors.white.withValues(alpha:0.7),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary01
                                : Colors.grey,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check_rounded,
                                color: Colors.white, size: 14)
                            : null,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ).animate().fadeIn(duration: 200.ms, delay: (index * 30).ms);
      },
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
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary01.withValues(alpha:0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.photo_library_outlined,
                  size: 36, color: AppColors.primary01),
            ),
            const SizedBox(height: 16),
            Text(
              'No images yet',
              style: GoogleFonts.outfit(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add photos to showcase this project',
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: isDark ? Colors.white60 : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _uploadImages,
              icon: const Icon(Icons.add_a_photo_rounded, size: 20),
              label: Text('Add Photos',
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
        ).animate().fadeIn(duration: 400.ms),
      ),
    );
  }
}

// =============================================================================
// Full-screen image viewer with swipe
// =============================================================================

class _FullScreenImageViewer extends StatefulWidget {
  const _FullScreenImageViewer({
    required this.images,
    required this.initialIndex,
  });

  final List<String> images;
  final int initialIndex;

  @override
  State<_FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<_FullScreenImageViewer> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Image pager
          PageView.builder(
            controller: _pageController,
            itemCount: widget.images.length,
            onPageChanged: (index) =>
                setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              return InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Image.network(
                    widget.images[index],
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image_rounded,
                        color: Colors.white54,
                        size: 48),
                  ),
                ),
              );
            },
          ),

          // Top bar
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha:0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close_rounded,
                        color: Colors.white, size: 22),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha:0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_currentIndex + 1} / ${widget.images.length}',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
