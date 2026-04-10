import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/features/home/presentation/widgets/vendor_card.dart';
import 'package:eventbridge/features/home/presentation/providers/vendor_provider.dart';
import 'package:eventbridge/features/home/domain/models/vendor.dart';

class RecommendationsScreen extends ConsumerWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recommendationsAsync = ref.watch(recommendedVendorsProvider);
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
                'AI Recommendations',
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
          recommendationsAsync.when(
            data: (vendors) {
              if (vendors.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text('No recommendations yet'),
                  ),
                );
              }

              // Group vendors by category
              final Map<String, List<Vendor>> groupedVendors = {};
              for (final vendor in vendors) {
                if (vendor.serviceCategories.isEmpty) {
                  groupedVendors.putIfAbsent('General', () => []).add(vendor);
                } else {
                  for (final category in vendor.serviceCategories) {
                    groupedVendors.putIfAbsent(category, () => []).add(vendor);
                  }
                }
              }

              final categories = groupedVendors.keys.toList()..sort();

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final category = categories[index];
                    final categoryVendors = groupedVendors[category]!;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 32),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: Text(
                              'AI Recommendations in $category',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            height: 230,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                              clipBehavior: Clip.none,
                              itemCount: categoryVendors.length,
                              itemBuilder: (context, vIndex) {
                                return Padding(
                                  padding: const EdgeInsets.only(right: 16),
                                  child: VendorCard(vendor: categoryVendors[vIndex]),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: categories.length,
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
          const SliverToBoxAdapter(
            child: SizedBox(height: 20),
          ),
        ],
      ),
    );
  }
}
