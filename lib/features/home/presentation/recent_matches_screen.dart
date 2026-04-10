import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/features/home/presentation/widgets/vendor_card.dart';
import 'package:eventbridge/features/home/presentation/providers/match_provider.dart';
import 'package:eventbridge/features/home/domain/models/vendor.dart';

class RecentMatchesScreen extends ConsumerWidget {
  const RecentMatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recentMatchesAsync = ref.watch(recentMatchesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.warmCream,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            elevation: 0,
            backgroundColor: isDark ? AppColors.backgroundDark : AppColors.warmCream,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'Recent Matches',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF1A1A24),
                  fontSize: 20,
                ),
              ),
              centerTitle: false,
              titlePadding: const EdgeInsets.only(left: 56, bottom: 16),
            ),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: isDark ? Colors.white : const Color(0xFF1A1A24),
                size: 20,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          recentMatchesAsync.when(
            data: (matches) {
              if (matches.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text('No recent matches found'),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 20,
                    childAspectRatio: 0.8,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final match = matches[index];
                      return VendorCard(
                        vendor: Vendor(
                          id: match.vendorId,
                          businessName: match.vendorName,
                          location: match.location,
                          serviceCategories: [match.eventType],
                          avatarUrl: match.imageUrl,
                          images: match.images,
                          rating: match.rating,
                          price: match.budget.toString(),
                          matchScore: match.matchScore,
                          matchReasons: match.matchReasons,
                        ),
                      );
                    },
                    childCount: matches.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.primary01),
              ),
            ),
            error: (err, stack) => SliverFillRemaining(
              child: Center(
                child: Text('Error: $err'),
              ),
            ),
          ),
          // Extra padding at the bottom for comfortable scrolling
          const SliverToBoxAdapter(
            child: SizedBox(height: 40),
          ),
        ],
      ),
    );
  }
}
