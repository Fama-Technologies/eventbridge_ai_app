import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/core/network/api_service.dart';
import 'package:eventbridge/core/storage/storage_service.dart';
import 'package:eventbridge/core/widgets/app_toast.dart';

import 'package:image_picker/image_picker.dart';
import 'package:eventbridge/core/services/upload_service.dart';

class VendorPortfolioScreen extends StatefulWidget {
  const VendorPortfolioScreen({super.key});

  @override
  State<VendorPortfolioScreen> createState() => _VendorPortfolioScreenState();
}

class _VendorPortfolioScreenState extends State<VendorPortfolioScreen> {
  bool _isLoading = true;
  bool _isUploading = false;
  String _businessName = 'My Business';
  List<dynamic> _portfolioImages = []; // Can be String (URL) or Map<String, dynamic> {url, category}
  String _activeCategory = 'All';
  final List<String> _categories = ['All', 'Weddings', 'Corporate', 'Parties', 'Other'];

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
        setState(() {
          _businessName = profile['businessName'] ?? 'My Business';
          if (profile['galleryUrls'] != null) {
            _portfolioImages = (profile['galleryUrls'] as List).map((item) {
              final url = _getDisplayUrl(item);
              // Handle nested category if exists, otherwise fallback
              String category = 'Other';
              if (item is Map) {
                category = item['category']?.toString() ?? 'Other';
              }
              return {'url': url, 'category': category};
            }).toList();
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, message: 'Failed to load portfolio', type: ToastType.error);
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _showCategoryDialog(String imageUrl, {int? index}) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    final Map<String, IconData> categoryIcons = {
      'Weddings': Icons.favorite_rounded,
      'Corporate': Icons.business_center_rounded,
      'Parties': Icons.celebration_rounded,
      'Other': Icons.more_horiz_rounded,
    };

    String? selectedCategory;
    
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(40)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              index == null ? 'Categorize New Project' : 'Update Category',
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select a category to help clients find your work.',
              style: GoogleFonts.outfit(
                color: isDark ? Colors.white38 : Colors.black38,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 32),
            ..._categories.where((c) => c != 'All').map((cat) {
              final icon = categoryIcons[cat] ?? Icons.label_rounded;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  onTap: () {
                    selectedCategory = cat;
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(icon, color: theme.primaryColor, size: 24),
                        ),
                        const SizedBox(width: 20),
                        Text(
                          cat,
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: isDark ? Colors.white24 : Colors.black26,
                        ),
                      ],
                    ),
                  ),
                ).animate().slideX(begin: 0.1, end: 0, duration: 400.ms, curve: Curves.easeOutQuint),
              );
            }).toList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );

    if (selectedCategory != null) {
      setState(() {
        if (index != null) {
          _portfolioImages[index] = {'url': imageUrl, 'category': selectedCategory};
        } else {
          _portfolioImages.insert(0, {'url': imageUrl, 'category': selectedCategory});
        }
      });
      await _saveChanges();
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() => _isUploading = true);
      try {
        final bytes = await image.readAsBytes();
        final fileName = 'portfolio_${DateTime.now().millisecondsSinceEpoch}.jpg';
        
        final url = await UploadService.instance.uploadFile(
          bytes: bytes,
          fileName: fileName,
          contentType: 'image/jpeg',
          folder: 'portfolio',
        );

        if (mounted) {
          setState(() => _isUploading = false);
          await _showCategoryDialog(url);
        }
      } catch (e) {
        if (mounted) {
          AppToast.show(context, message: 'Upload failed: $e', type: ToastType.error);
          setState(() => _isUploading = false);
        }
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
        galleryUrls: _portfolioImages,
      );

      if (mounted && result['success'] == true) {
        AppToast.show(context, message: 'Portfolio updated!', type: ToastType.success);
      }
    } catch (e) {
      debugPrint('Save failed: $e');
    }
  }

  void _deleteImage(int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(40),
            border: Border.all(color: Colors.redAccent.withOpacity(0.1)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 30,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 36),
              ),
              const SizedBox(height: 32),
              Text(
                'Delete Project?',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'This will permanently remove this project from your public portfolio. This action cannot be undone.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white38 : Colors.black38,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 40),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text(
                        'CANCEL',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : Colors.black26,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context, true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: Text(
                        'DELETE',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      setState(() {
        _portfolioImages.removeAt(index);
      });
      await _saveChanges();
    }
  }

  void _editTag(int index) async {
    final item = _portfolioImages[index];
    final imageUrl = (item is Map) ? item['url'] : item.toString();
    await _showCategoryDialog(imageUrl, index: index);
  }

  void _openImageDetail(String url, int index) {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        pageBuilder: (context, animation, _) => FadeTransition(
          opacity: animation,
          child: _ImageDetailView(
            url: url, 
            index: index, 
            allImages: _portfolioImages,
            onDelete: () {
              Navigator.pop(context);
              _deleteImage(index);
            },
            onEdit: () {
              Navigator.pop(context);
              _editTag(index);
            },
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      floatingActionButton: GestureDetector(
        onTap: _isUploading ? null : _pickAndUploadImage,
        child: AnimatedContainer(
          duration: 300.ms,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [theme.primaryColor, theme.primaryColor.withBlue(255).withGreen(100)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: theme.primaryColor.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _isUploading 
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.add_photo_alternate_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              Text(
                _isUploading ? 'UPLOADING...' : 'ADD PROJECT',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800, 
                  color: Colors.white,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ).animate().scale(delay: 400.ms, curve: Curves.easeOutBack),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: theme.primaryColor))
          : Stack(
              children: [
                CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    _buildSliverAppBar(theme, isDark),
                    SliverToBoxAdapter(
                      child: _buildCategoryFilters(theme, isDark),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 100), // extra padding for FAB
                      sliver: _buildPortfolioGrid(theme, isDark),
                    ),
                  ],
                ),
                if (_isUploading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withOpacity(0.3),
                      child: const Center(
                        child: CircularProgressIndicator(color: AppColors.primary01),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }

  String _getDisplayUrl(dynamic item) {
    if (item == null) return '';
    if (item is String) {
      if (item.startsWith('{') && item.endsWith('}')) {
        try {
          final decoded = json.decode(item);
          return _getDisplayUrl(decoded);
        } catch (_) {
          return item;
        }
      }
      return item;
    }
    if (item is Map) {
      final urlValue = item['url'];
      if (urlValue != null) {
        return _getDisplayUrl(urlValue);
      }
    }
    return item.toString();
  }

  Widget _buildSliverAppBar(ThemeData theme, bool isDark) {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      stretch: true,
      backgroundColor: theme.scaffoldBackgroundColor,
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
            // Featured Image or Gradient
            if (_portfolioImages.isNotEmpty)
              Image.network(
                _getDisplayUrl(_portfolioImages.first),
                fit: BoxFit.cover,
              )
            else
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark 
                      ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                      : [AppColors.primary01.withOpacity(0.1), AppColors.primary01.withOpacity(0.3)],
                  ),
                ),
              ),
            // Glass Overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    isDark ? Colors.black.withOpacity(0.2) : Colors.white.withOpacity(0.1),
                    Colors.transparent,
                    theme.scaffoldBackgroundColor.withOpacity(0.8),
                    theme.scaffoldBackgroundColor,
                  ],
                ),
              ),
            ),
            // Header Content
            Positioned(
              left: 24,
              right: 24,
              bottom: 30,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
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
                        const SizedBox(width: 8),
                        Text(
                          'OFFICIAL PORTFOLIO',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _businessName,
                    style: GoogleFonts.workSans(
                      fontSize: 42,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: -1.5,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildHeaderStats(isDark),
                ],
              ).animate().fadeIn(duration: 800.ms).slideY(begin: 0.1, end: 0),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderStats(bool isDark) {
    return Row(
      children: [
        _statBadge(Icons.auto_awesome_rounded, 'PREMIUM VENDOR', const Color(0xFFF59E0B)),
        const SizedBox(width: 12),
        _statBadge(Icons.check_circle_rounded, 'VERIFIED', const Color(0xFF3B82F6)),
      ],
    );
  }

  Widget _statBadge(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 9,
              fontWeight: FontWeight.w900,
              color: color,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilters(ThemeData theme, bool isDark) {
    return Container(
      height: 90,
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final isActive = _activeCategory == cat;
          return GestureDetector(
            onTap: () => setState(() => _activeCategory = cat),
            child: AnimatedContainer(
              duration: 300.ms,
              curve: Curves.easeOutQuint,
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? theme.primaryColor : (isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02)),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: isActive ? theme.primaryColor : (isDark? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08)),
                  width: 1.5,
                ),
                boxShadow: isActive ? [
                  BoxShadow(
                    color: theme.primaryColor.withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  )
                ] : null,
              ),
              child: Center(
                child: Text(
                  cat,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                    color: isActive ? Colors.white : (isDark ? Colors.white60 : Colors.black54),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPortfolioGrid(ThemeData theme, bool isDark) {
    // Filter images based on active category
    final filteredImages = _activeCategory == 'All'
        ? _portfolioImages
        : _portfolioImages.where((item) {
            final category = (item is Map) ? item['category'] : null;
            return category == _activeCategory;
          }).toList();

    if (filteredImages.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.photo_library_outlined,
                size: 64,
                color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
              ),
              const SizedBox(height: 20),
              Text(
                _activeCategory == 'All' 
                  ? 'No projects to show yet'
                  : 'No $_activeCategory projects yet',
                style: GoogleFonts.outfit(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontSize: 16,
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
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 0.75,
      ),
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final item = filteredImages[index];
          final imageUrl = _getDisplayUrl(item);
          final tag = (item is Map) ? item['category'] : 'Project';
          
          return GestureDetector(
            onTap: () => _openImageDetail(imageUrl, index),
            child: Hero(
              tag: 'portfolio_$index',
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.4 : 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.withOpacity(0.1))),
                      // Dynamic Gradient overlay
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: const [0.3, 1.0],
                              colors: [
                                Colors.transparent,
                                Colors.black.withOpacity(0.85),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: 16,
                        bottom: 16,
                        right: 16,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: theme.primaryColor.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                tag.toUpperCase(),
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1,
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
            ),
          ).animate(delay: (index * 80).ms).fadeIn(duration: 400.ms).scale(begin: const Offset(0.95, 0.95));
        },
        childCount: filteredImages.length,
      ),
    );
  }
}

class _ImageDetailView extends StatelessWidget {
  final String url;
  final int index;
  final List<dynamic> allImages;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  const _ImageDetailView({
    required this.url, 
    required this.index, 
    required this.allImages,
    required this.onDelete,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black.withOpacity(0.9),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Center(
            child: Hero(
              tag: 'portfolio_$index',
              child: Image.network(url, fit: BoxFit.contain),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 20,
            left: 20,
            right: 20,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white, size: 30),
                  onPressed: () => Navigator.pop(context),
                ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_note_rounded, color: Colors.white, size: 28),
                      onPressed: onEdit,
                      tooltip: 'Edit Tag',
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 28),
                      onPressed: onDelete,
                      tooltip: 'Delete Image',
                    ),
                  ],
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(30),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: Text(
                  'Project Image ${index + 1} of ${allImages.length}',
                  style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
