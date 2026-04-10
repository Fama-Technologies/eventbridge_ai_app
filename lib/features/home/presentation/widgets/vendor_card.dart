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

    return GestureDetector(
      onTap: () => context.push('/vendor-public/${widget.vendor.id}'),
      child: Container(
        width: widget.width,
        decoration: BoxDecoration(
          color: widget.isDark ? AppColors.darkNeutral01 : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: widget.isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 115,
                    width: double.infinity,
                    child: images.isEmpty
                        ? Container(
                            color: AppColors.primary01.withValues(alpha: 0.1),
                            child: const Center(
                              child: Icon(
                                Icons.business,
                                color: AppColors.primary01,
                                size: 30,
                              ),
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
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.error_outline,
                                      color: Colors.red,
                                    ),
                                  ),
                            ),
                          ),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Consumer(
                    builder: (context, ref, child) {
                      final isFavorite = ref.watch(matchingControllerProvider.select(
                        (s) => s.favoriteIds.contains(widget.vendor.id),
                      ));
                      return GestureDetector(
                        onTap: () => ref.read(matchingControllerProvider.notifier).toggleFavorite(widget.vendor.id),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isFavorite ? Icons.favorite : Icons.favorite_border,
                            color: isFavorite ? Colors.red : Colors.white,
                            size: 16,
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (images.length > 1)
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(images.length, (idx) {
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: idx == _currentIndex
                                ? Colors.white
                                : Colors.white.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                        );
                      }),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 0, 8, 4),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   if (widget.vendor.matchScore > 0)
                    Container(
                      width: 3,
                      height: 45,
                      margin: const EdgeInsets.only(top: 2, right: 10),
                      decoration: BoxDecoration(
                        color: AppColors.primary01,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.vendor.businessName,
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: widget.isDark ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${widget.vendor.serviceCategories.isNotEmpty ? widget.vendor.serviceCategories.first : "Service"} • ${widget.vendor.location}',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: widget.isDark ? Colors.white38 : Colors.grey[500],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            if (widget.vendor.price != null)
                              Expanded(
                                child: Text(
                                  '${widget.vendor.price!} / event',
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: widget.isDark ? Colors.white70 : Colors.black87,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              )
                            else
                              Expanded(
                                child: Text(
                                  'Price on inquiry',
                                  style: GoogleFonts.outfit(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary01,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            Icon(Icons.star, color: Colors.amber[700], size: 10),
                            const SizedBox(width: 2),
                            Text(
                              widget.vendor.rating.toStringAsFixed(1),
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: widget.isDark ? Colors.white70 : Colors.grey[800],
                              ),
                            ),
                          ],
                        ),
                        if (widget.vendor.matchScore > 0) ...[
                          const SizedBox(height: 4),
                          Text(
                            '${(widget.vendor.matchScore * 100).toInt()}% match for you',
                            style: GoogleFonts.outfit(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary01,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
