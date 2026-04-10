import 'package:eventbridge/features/home/presentation/widgets/vendor_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
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
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          _buildSliverAppBar(context, isDark),
          savedVendorsAsync.when(
            data: (vendors) => vendors.isEmpty
                ? SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(isDark),
                  )
                : SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    sliver: SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 20,
                        childAspectRatio: 0.8,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => VendorCard(
                          vendor: vendors[index],
                          isDark: isDark,
                        )
                            .animate()
                            .fadeIn(duration: 400.ms, delay: (index * 100).ms)
                            .slideY(begin: 0.1, end: 0),
                        childCount: vendors.length,
                      ),
                    ),
                  ),
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator(color: AppColors.primary01)),
            ),
            error: (err, stack) => SliverFillRemaining(
              child: Center(child: Text('Failed to load saved vendors', style: GoogleFonts.outfit(color: Colors.red))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, bool isDark) {
    return SliverAppBar(
      expandedHeight: 100,
      pinned: true,
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.warmCream,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_rounded, color: isDark ? Colors.white : Colors.black, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        title: Text(
          'Saved Vendors',
          style: GoogleFonts.outfit(
            fontSize: 18,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF1A1A24),
          ),
        ),
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
