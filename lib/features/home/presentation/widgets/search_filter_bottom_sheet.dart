import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/features/home/presentation/providers/category_provider.dart';
import 'package:eventbridge/features/matching/presentation/widgets/match_intake_bottom_sheet.dart';

class SearchFilterBottomSheet extends ConsumerStatefulWidget {
  final String? initialCategory;
  const SearchFilterBottomSheet({super.key, this.initialCategory});

  @override
  ConsumerState<SearchFilterBottomSheet> createState() => _SearchFilterBottomSheetState();
}

class _SearchFilterBottomSheetState extends ConsumerState<SearchFilterBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onQuickSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      context.pop();
      context.push('/customer-explore?q=${Uri.encodeComponent(query)}');
    } else if (_selectedCategory != null) {
      context.pop();
      context.push('/customer-explore?cat=${Uri.encodeComponent(_selectedCategory!)}');
    }
  }

  void _onAIMatch() {
    if (_selectedCategory != null) {
      context.pop();
      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => MatchIntakeBottomSheet(
          categoryName: _selectedCategory!,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 40,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDark ? Colors.white24 : Colors.black12,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Search & Filter',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1A1A24),
            ),
          ),
          const SizedBox(height: 24),
          // Vendor Name Search
          Text(
            'Search by Vendor Name',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                if (val.isNotEmpty && _selectedCategory != null) {
                  setState(() => _selectedCategory = null);
                }
              },
              style: GoogleFonts.outfit(color: isDark ? Colors.white : Colors.black87),
              decoration: InputDecoration(
                hintText: 'Enter vendor business name...',
                hintStyle: GoogleFonts.outfit(color: Colors.grey[500]),
                border: InputBorder.none,
                icon: Icon(Icons.storefront_rounded, color: AppColors.primary01, size: 20),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Categories
          Text(
            'Filter by Category',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 12),
          categoriesAsync.when(
            data: (categories) => Wrap(
              spacing: 8,
              runSpacing: 10,
              children: categories.map((cat) {
                final isSelected = _selectedCategory == cat.name;
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedCategory = isSelected ? null : cat.name;
                      if (!isSelected) _searchController.clear();
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary01 : (isDark ? Colors.white.withValues(alpha: 0.05) : Colors.white),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.primary01 : (isDark ? Colors.white10 : Colors.grey[300]!),
                      ),
                    ),
                    child: Text(
                      cat.name,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (_, __) => const Text('Failed to load categories'),
          ),
          const SizedBox(height: 32),
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: (_selectedCategory != null || _searchController.text.trim().isNotEmpty)
                      ? _onQuickSearch
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white10 : Colors.grey[100],
                    foregroundColor: AppColors.primary01,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Quick Search',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
              if (_selectedCategory != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _onAIMatch,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary01,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.auto_awesome_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'AI Match',
                          style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
