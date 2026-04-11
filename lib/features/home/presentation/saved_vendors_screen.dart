import 'package:eventbridge/features/home/presentation/widgets/vendor_card.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventbridge/shared/widgets/app_header.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'providers/vendor_provider.dart';

class SavedVendorsScreen extends ConsumerWidget {
  const SavedVendorsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedVendorsAsync = ref.watch(savedVendorsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.warmCream,
      body: Column(
        children: [
          AppHeader(
            title: 'Favorites',
            showBack: false,
          ),
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
          savedVendorsAsync.when(
            data: (vendors) => vendors.isEmpty
                ? SliverToBoxAdapter(child: _buildEmptyState(isDark))
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: VendorCard(
                            vendor: vendors[index],
                            isDark: isDark,
                          )
                              .animate()
                              .fadeIn(duration: 400.ms, delay: (index * 80).ms),
                        ),
                        childCount: vendors.length,
                      ),
                    ),
                  ),
            loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
            error: (err, stack) => const SliverToBoxAdapter(child: Center(child: Text('Error loading favorites'))),
          ),
          const SliverToBoxAdapter(
            child: SizedBox(height: 120),
          ),
        ],
      ),
          ),
        ],
      ),
    );
  }


  Widget _buildEmptyState(bool isDark) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.favorite_border_rounded, size: 80, color: isDark ? Colors.white10 : Colors.black.withValues(alpha: 0.05)),
        const SizedBox(height: 24),
        Text(
          'No Saved Vendors Yet',
          style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w800, color: isDark ? Colors.white70 : Colors.black54),
        ),
        const SizedBox(height: 8),
        Text(
          'Heart vendors to see them here for quick access.',
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(fontSize: 14, color: isDark ? Colors.white24 : Colors.black38),
        ),
      ],
    );
  }
}
