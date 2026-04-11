import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/features/home/domain/models/vendor.dart';
import 'package:eventbridge/features/matching/presentation/matching_controller.dart';

class VendorCard extends StatefulWidget {
  final Vendor vendor;
  final double width;
  final bool isDark;

  const VendorCard({
    super.key,
    required this.vendor,
    this.width = 185,
    this.isDark = false,
  });

  @override
  State<VendorCard> createState() => _VendorCardState();
}

class _VendorCardState extends State<VendorCard> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.vendor.images.isNotEmpty
        ? widget.vendor.images
        : (widget.vendor.avatarUrl != null ? [widget.vendor.avatarUrl!] : []);
    final businessName = _displayBusinessName(widget.vendor.businessName);
    final primaryCategory = _displayCategory(widget.vendor.serviceCategories);
    final location = _displayLocation(widget.vendor.location);
    final priceLabel = _displayPrice(widget.vendor.price);
    final matchPercent = widget.vendor.matchScore > 0
        ? (widget.vendor.matchScore * 100).round()
        : null;
    final cardRadius = BorderRadius.circular(22);

    return GestureDetector(
      onTap: () => context.push('/vendor-public/${widget.vendor.id}'),
      child: Container(
        width: widget.width,
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.darkNeutral02 : AppColors.cardWhite,
          borderRadius: cardRadius,
          border: Border.all(
            color: widget.isDark
                ? AppColors.darkNeutral03
                : AppColors.neutrals02,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: widget.isDark ? 0.22 : 0.08,
              ),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              child: Stack(
                children: [
                  SizedBox(
                    height: 104,
                    width: double.infinity,
                    child: images.isEmpty
                        ? Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: widget.isDark
                                    ? const [
                                        AppColors.darkNeutral03,
                                        AppColors.darkNeutral01,
                                      ]
                                    : const [
                                        Color(0xFFF6F2EE),
                                        Color(0xFFE9E2DB),
                                      ],
                              ),
                            ),
                            child: Icon(
                              Icons.storefront_rounded,
                              color: widget.isDark
                                  ? Colors.white70
                                  : const Color(0xFF6B7280),
                              size: 34,
                            ),
                          )
                        : PageView.builder(
                            onPageChanged: (idx) =>
                                setState(() => _currentIndex = idx),
                            itemCount: images.length,
                            itemBuilder: (context, idx) => Image.network(
                              images[idx],
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stack) =>
                                  Container(
                                    color: widget.isDark
                                        ? AppColors.darkNeutral03
                                        : AppColors.neutrals02,
                                    child: Icon(
                                      Icons.broken_image_outlined,
                                      color: widget.isDark
                                          ? Colors.white60
                                          : AppColors.textSecondary,
                                      size: 28,
                                    ),
                                  ),
                            ),
                          ),
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: widget.isDark
                            ? Colors.black.withValues(alpha: 0.4)
                            : Colors.white.withValues(alpha: 0.9),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        primaryCategory,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: widget.isDark
                              ? Colors.white
                              : AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Consumer(
                      builder: (context, ref, child) {
                        final isFavorite = ref.watch(
                          matchingControllerProvider.select(
                            (s) => s.favoriteIds.contains(widget.vendor.id),
                          ),
                        );
                        return GestureDetector(
                          onTap: () => ref
                              .read(matchingControllerProvider.notifier)
                              .toggleFavorite(widget.vendor.id),
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: widget.isDark
                                  ? AppColors.darkNeutral02.withValues(
                                      alpha: 0.88,
                                    )
                                  : Colors.white.withValues(alpha: 0.94),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(
                              isFavorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: isFavorite
                                  ? const Color(0xFFD64545)
                                  : (widget.isDark
                                        ? Colors.white70
                                        : AppColors.textPrimary),
                              size: 16,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (images.length > 1)
                    Positioned(
                      bottom: 10,
                      left: 10,
                      child: Row(
                        children: List.generate(images.length, (idx) {
                          final isActive = idx == _currentIndex;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 4),
                            width: isActive ? 16 : 5,
                            height: 5,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.58),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          );
                        }),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    businessName,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: widget.isDark
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 13,
                        color: widget.isDark
                            ? Colors.white60
                            : AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: widget.isDark
                                ? Colors.white60
                                : AppColors.textSecondary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: widget.isDark
                                ? AppColors.darkNeutral01
                                : const Color(0xFFF4F4F5),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            priceLabel,
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: widget.isDark
                                  ? Colors.white70
                                  : AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: widget.isDark
                              ? const Color(0xFF2D2616)
                              : const Color(0xFFFFF7E8),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star_rounded,
                              color: Color(0xFFE0A100),
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              widget.vendor.rating.toStringAsFixed(1),
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: widget.isDark
                                    ? Colors.white70
                                    : AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (matchPercent != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: widget.isDark
                            ? const Color(0xFF173229)
                            : const Color(0xFFEAF6F1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$matchPercent% match for you',
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1E6A56),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _displayBusinessName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'vendor') {
      return 'Event vendor';
    }
    return trimmed;
  }

  String _displayCategory(List<String> categories) {
    for (final category in categories) {
      final trimmed = category.trim();
      if (trimmed.isNotEmpty) return trimmed;
    }
    return 'Event service';
  }

  String _displayLocation(String location) {
    final trimmed = location.trim();
    if (trimmed.isEmpty || trimmed.toLowerCase() == 'unknown location') {
      return 'Location pending';
    }
    return trimmed;
  }

  bool _hasUsablePrice(String? price) {
    final trimmed = price?.trim();
    return trimmed != null &&
        trimmed.isNotEmpty &&
        trimmed.toLowerCase() != 'null';
  }

  String _displayPrice(String? price) {
    if (!_hasUsablePrice(price)) return 'Price on inquiry';
    final trimmed = price!.trim();
    return trimmed.contains('/') ? trimmed : '$trimmed / event';
  }
}
