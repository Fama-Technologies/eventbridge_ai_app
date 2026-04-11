import 'package:eventbridge/features/home/presentation/widgets/vendor_card.dart';
import 'package:eventbridge/core/storage/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge/core/theme/app_colors.dart';

import 'providers/vendor_provider.dart';
import 'package:eventbridge/features/matching/presentation/widgets/match_intake_bottom_sheet.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:eventbridge/shared/widgets/app_header.dart';

class CustomerHomeScreen extends ConsumerStatefulWidget {
  const CustomerHomeScreen({super.key});

  @override
  ConsumerState<CustomerHomeScreen> createState() => _CustomerHomeScreenState();
}

class _CustomerHomeScreenState extends ConsumerState<CustomerHomeScreen> {
  String? _selectedLookingForCategory;

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final recommendedVendorsAsync = ref.watch(recommendedVendorsProvider);

    final storage = StorageService();
    final fullName = storage.getString('user_name')?.trim() ?? 'mugole';
    final avatarLetter = fullName.isNotEmpty ? fullName[0].toUpperCase() : 'M';
    final displayName = fullName.toLowerCase();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          AppHeader(
            greeting: 'Welcome back,',
            username: '$displayName 👋',
            showSearch: true,
            avatarLetter: avatarLetter,
            onAvatarTap: () => context.push('/customer-profile'),
            onSearchTap: () => context.push('/customer-explore'),
          ),
          Expanded(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 20),
                        // ── Hero Carousel ──────────────────────────────
                        const EventBridgeHeroCarousel(),
                        const SizedBox(height: 28),
                        Text(
                          'Looking for',
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          clipBehavior: Clip.none,
                          child: Row(
                            children:
                                [
                                  'Venues',
                                  'Photographers',
                                  'Decorators',
                                  'Caterers',
                                  'Fashion',
                                  'Bridal Wear',
                                ].map((cat) {
                                  final isSelected =
                                      _selectedLookingForCategory == cat;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: ChoiceChip(
                                      label: Text(cat),
                                      selected: isSelected,
                                      onSelected: (_) {
                                        setState(() {
                                          _selectedLookingForCategory = cat;
                                        });
                                        showModalBottomSheet(
                                          context: context,
                                          isScrollControlled: true,
                                          backgroundColor: Colors.transparent,
                                          builder: (context) {
                                            String mappedService = 'Other';
                                            if (cat == 'Venues') mappedService = 'Venue';
                                            if (cat == 'Photographers') mappedService = 'Photography';
                                            if (cat == 'Caterers') mappedService = 'Caterer';
                                            
                                            return MatchIntakeBottomSheet(
                                              initialService: mappedService,
                                            );
                                          },
                                        );
                                      },
                                      labelStyle: GoogleFonts.outfit(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected
                                            ? AppColors.white
                                            : AppColors.textPrimary,
                                      ),
                                      backgroundColor: Colors.white,
                                      selectedColor: AppColors.primary01,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                          100,
                                        ),
                                        side: BorderSide(
                                          color: isSelected
                                              ? AppColors.primary01
                                              : AppColors.neutrals03,
                                        ),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 8,
                                      ),
                                      showCheckmark: false,
                                    ),
                                  );
                                }).toList(),
                          ),
                        ),
                        const SizedBox(height: 28),
                      ],
                    ),
                  ),
                ),
                // ── AI Recommendations ───────────────────────────────
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    color: Colors.white,
                    child: Padding(
                      padding: const EdgeInsets.only(
                        top: 10,
                        left: 20,
                        right: 0,
                        bottom: 10,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 20),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'AI Recommendations',
                                  style: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                                InkWell(
                                  onTap: () =>
                                      context.push('/recommendations'),
                                  borderRadius: BorderRadius.circular(8),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    child: Text(
                                      'View All',
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary01,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          recommendedVendorsAsync.when(
                            data: (vendors) => vendors.isEmpty
                                ? const SizedBox.shrink()
                                : Builder(
                                    builder: (context) {
                                      final visibleVendors =
                                          vendors.take(6).toList();
                                      final screenW =
                                          MediaQuery.sizeOf(context).width;
                                      // Show 2 full cards + small peek of 3rd
                                      final cardW =
                                          (screenW - 40 - 12) / 2.15;
                                      return SizedBox(
                                        height: cardW / 0.72,
                                        child: ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          clipBehavior: Clip.none,
                                          padding: const EdgeInsets.only(
                                            right: 20,
                                          ),
                                          itemCount: visibleVendors.length,
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(width: 12),
                                          itemBuilder: (context, index) =>
                                              SizedBox(
                                            width: cardW,
                                            child: VendorCard(
                                              vendor: visibleVendors[index],
                                              width: cardW,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                            loading: () => const Center(
                              child: CircularProgressIndicator(),
                            ),
                            error: (err, stack) => const Padding(
                              padding: EdgeInsets.only(right: 20),
                              child: Text('Failed to load recommendations'),
                            ),
                          ),
                          const SizedBox(height: 28),
                        ],
                      ),
                    ),
                  ),
                ),
                // ── What are you planning today? ─────────────────────
                const SliverToBoxAdapter(child: _PlanningTodaySection()),
                // ── Events & Others ─────────────────────────────────
                const SliverToBoxAdapter(child: _EventsAdsSection()),
                const SliverToBoxAdapter(child: SizedBox(height: 120)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  Events & Others — Ad Cards
// ═══════════════════════════════════════════════

class _EventAdItem {
  final String category;
  final String title;
  final String date;
  final String price;
  final String location;
  final String time;
  final String imageUrl;
  final Color cardColor;
  const _EventAdItem({
    required this.category,
    required this.title,
    required this.date,
    required this.price,
    required this.location,
    required this.time,
    required this.imageUrl,
    required this.cardColor,
  });
}

class _EventsAdsSection extends StatelessWidget {
  const _EventsAdsSection();

  static const _events = [
    _EventAdItem(
      category: 'PARTY',
      title: 'Rooftop DJ Night',
      date: 'Apr 20',
      price: 'UGX 35,000',
      location: 'Nakasero',
      time: '7 PM',
      imageUrl:
          'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?w=600&fit=crop&auto=format',
      cardColor: Color(0xFFBF3B1E),
    ),
    _EventAdItem(
      category: 'CONCERT',
      title: 'Afrobeats Fest 2026',
      date: 'May 3',
      price: 'UGX 80,000',
      location: 'Lugogo Arena',
      time: '5 PM',
      imageUrl:
          'https://images.unsplash.com/photo-1493225457124-a3eb161ffa5f?w=600&fit=crop&auto=format',
      cardColor: Color(0xFF1A3A6B),
    ),
    _EventAdItem(
      category: 'WEDDING FAIR',
      title: 'Bridal Expo Kampala',
      date: 'May 10',
      price: 'Free Entry',
      location: 'Serena Hotel',
      time: '10 AM',
      imageUrl:
          'https://images.unsplash.com/photo-1519741497674-611481863552?w=600&fit=crop&auto=format',
      cardColor: Color(0xFF6B2D5E),
    ),
    _EventAdItem(
      category: 'FASHION',
      title: 'Kampala Fashion Week',
      date: 'Jun 1',
      price: 'UGX 50,000',
      location: 'Kololo Grounds',
      time: '2 PM',
      imageUrl:
          'https://images.unsplash.com/photo-1558618047-3c8c76ca7d13?w=600&fit=crop&auto=format',
      cardColor: Color(0xFF2D1A4A),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Events & Others',
                style: GoogleFonts.outfit(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827),
                  letterSpacing: -0.2,
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Text(
                  'See all',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary01,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 172,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _events.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, i) => _EventAdCard(event: _events[i]),
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

class _EventAdCard extends StatefulWidget {
  final _EventAdItem event;
  const _EventAdCard({required this.event});

  @override
  State<_EventAdCard> createState() => _EventAdCardState();
}

class _EventAdCardState extends State<_EventAdCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final e = widget.event;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) => setState(() => _pressed = false),
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: SizedBox(
          width: 290,
          height: 172,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // ── Photo background ──────────────────────────────
                Image.network(
                  e.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: e.cardColor),
                ),
                // ── Left-heavy colour scrim ────────────────────────
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        e.cardColor.withValues(alpha: 0.95),
                        e.cardColor.withValues(alpha: 0.7),
                        e.cardColor.withValues(alpha: 0.15),
                      ],
                      stops: const [0.0, 0.55, 1.0],
                    ),
                  ),
                ),
                // ── Content ───────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 100, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Category
                      Text(
                        e.category,
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.8),
                          letterSpacing: 1.4,
                        ),
                      ),
                      // Title
                      Text(
                        e.title,
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.4,
                          height: 1.15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Date + price row
                      Row(
                        children: [
                          _AdPill(text: e.date, isPrimary: true),
                          const SizedBox(width: 8),
                          _AdPill(text: e.price, isPrimary: false),
                        ],
                      ),
                      // Location · time
                      _AdPill(
                        text: '${e.location} · ${e.time}',
                        isPrimary: false,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdPill extends StatelessWidget {
  final String text;
  final bool isPrimary;
  const _AdPill({required this.text, required this.isPrimary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: isPrimary
            ? Colors.white.withValues(alpha: 0.22)
            : Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: isPrimary ? 0.35 : 0.15),
        ),
      ),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: isPrimary ? FontWeight.w700 : FontWeight.w500,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  What are you planning today?
// ═══════════════════════════════════════════════

class _PlanningItem {
  final String label;
  final String subtitle;
  final IconData icon;
  final String imageUrl;
  const _PlanningItem({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.imageUrl,
  });
}

class _PlanningTodaySection extends StatelessWidget {
  const _PlanningTodaySection();

  static const _items = [
    _PlanningItem(
      label: 'Wedding',
      subtitle: 'Venues · Decor · Catering',
      icon: PhosphorIconsFill.heart,
      // Elegant wedding ceremony aisle with flowers & white chairs
      imageUrl:
          'https://images.unsplash.com/photo-1606800052052-a08af7148866?w=600&fit=crop&auto=format',
    ),
    _PlanningItem(
      label: 'Birthday',
      subtitle: 'Caterers · Decor · Cakes',
      icon: PhosphorIconsFill.cake,
      // Birthday cake with lit candles close-up
      imageUrl:
          'https://images.unsplash.com/photo-1464349095431-e9a21285b5f3?w=600&fit=crop&auto=format',
    ),
    _PlanningItem(
      label: 'Corporate',
      subtitle: 'Venues · AV · Catering',
      icon: PhosphorIconsFill.briefcase,
      // Professional conference / business event setup
      imageUrl:
          'https://images.unsplash.com/photo-1515187029135-18ee286d815b?w=600&fit=crop&auto=format',
    ),
    _PlanningItem(
      label: 'Concert',
      subtitle: 'Stages · Sound · Security',
      icon: PhosphorIconsFill.musicNote,
      // Live concert stage with colorful lights & crowd
      imageUrl:
          'https://images.unsplash.com/photo-1470229722913-7c0e2dbbafd3?w=600&fit=crop&auto=format',
    ),
    _PlanningItem(
      label: 'Fashion Show',
      subtitle: 'Runways · Photography · Bridal',
      icon: PhosphorIconsFill.dress,
      // Models walking fashion runway with lights
      imageUrl:
          'https://images.unsplash.com/photo-1509631179647-0177331693ae?w=600&fit=crop&auto=format',
    ),
    _PlanningItem(
      label: 'Graduation',
      subtitle: 'Venues · Photographers · Gifts',
      icon: PhosphorIconsFill.graduationCap,
      // Graduates tossing caps in the air
      imageUrl:
          'https://images.unsplash.com/photo-1627556704302-624286467c65?w=600&fit=crop&auto=format',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'What are you planning today?',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pick an event type to discover the perfect vendors',
            style: GoogleFonts.outfit(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.65,
            ),
            itemCount: _items.length,
            itemBuilder: (context, i) => _PlanningCard(item: _items[i]),
          ),
          const SizedBox(height: 28),
        ],
      ),
    );
  }
}

class _PlanningCard extends StatefulWidget {
  final _PlanningItem item;
  const _PlanningCard({required this.item});

  @override
  State<_PlanningCard> createState() => _PlanningCardState();
}

class _PlanningCardState extends State<_PlanningCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => MatchIntakeBottomSheet(initialEventType: item.label),
        );
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 130),
        curve: Curves.easeOut,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Background photo ──────────────────────────────────
              Image.network(
                item.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(color: const Color(0xFF1F2937)),
              ),

              // ── Full dark scrim ───────────────────────────────────
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.black.withValues(alpha: 0.78),
                      Colors.black.withValues(alpha: 0.42),
                      Colors.black.withValues(alpha: 0.12),
                    ],
                    stops: const [0.0, 0.55, 1.0],
                  ),
                ),
              ),

              // ── Landscape content: icon left, text right ──────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Icon badge
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.28),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.25),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        item.icon,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Text column
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            item.label,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                              height: 1.1,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            item.subtitle,
                            style: GoogleFonts.outfit(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.72),
                              letterSpacing: 0.1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          // "Explore →" chip
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Explore',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withValues(alpha: 0.9),
                                ),
                              ),
                              const SizedBox(width: 3),
                              Icon(
                                PhosphorIconsFill.arrowRight,
                                size: 10,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════
//  EventBridge Hero Carousel — auto-scrolling
// ═══════════════════════════════════════════════

class EventBridgeHeroCarousel extends StatefulWidget {
  const EventBridgeHeroCarousel({super.key});

  @override
  State<EventBridgeHeroCarousel> createState() =>
      _EventBridgeHeroCarouselState();
}

class _EventBridgeHeroCarouselState extends State<EventBridgeHeroCarousel> {
  late final PageController _ctrl;
  int _currentPage = 0;
  bool _disposed = false;

  static const _slides = [
    _HeroSlide(
      badge: 'TRUSTED VENDORS',
      title: 'Find the right vendors.',
      subtitle:
          'Browse venues, catering, decor, photography & more in one place.',
      cta: 'Browse • Compare • Connect',
      gradientColors: [Color(0xFF111827), Color(0xFF334155)],
      accentIcon: PhosphorIconsFill.sparkle,
    ),
    _HeroSlide(
      badge: 'AI POWERED',
      title: 'Smart matches, just for you.',
      subtitle:
          'Our AI analyses your preferences and recommends the best vendors instantly.',
      cta: 'Discover • Match • Book',
      gradientColors: [Color(0xFF1A1040), Color(0xFF3B2F72)],
      accentIcon: PhosphorIconsFill.robot,
    ),
    _HeroSlide(
      badge: 'TOP VENUES',
      title: 'Dream spaces, any occasion.',
      subtitle:
          'From intimate gatherings to grand celebrations — the perfect venue awaits.',
      cta: 'Search • Tour • Reserve',
      gradientColors: [Color(0xFF0A2E1A), Color(0xFF1B5E3B)],
      accentIcon: PhosphorIconsFill.buildings,
    ),
    _HeroSlide(
      badge: 'SEAMLESS PLANNING',
      title: 'Plan your event with ease.',
      subtitle:
          'Send inquiries, compare quotes, and track vendors — all in one app.',
      cta: 'Plan • Track • Execute',
      gradientColors: [Color(0xFF2C1010), Color(0xFF7A2B2B)],
      accentIcon: PhosphorIconsFill.calendarCheck,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _ctrl = PageController();
    _startAutoScroll();
  }

  Future<void> _startAutoScroll() async {
    while (!_disposed) {
      await Future.delayed(const Duration(seconds: 4));
      if (_disposed || !mounted) break;
      final next = (_currentPage + 1) % _slides.length;
      await _ctrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 192,
          child: PageView.builder(
            controller: _ctrl,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, i) => _HeroCard(slide: _slides[i]),
          ),
        ),
        const SizedBox(height: 12),
        // ── Dot indicators ──────────────────────────────────────────
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(_slides.length, (i) {
            final active = i == _currentPage;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: active ? 22 : 6,
              height: 6,
              decoration: BoxDecoration(
                color: active
                    ? const Color(0xFF111827)
                    : const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(999),
              ),
            );
          }),
        ),
      ],
    );
  }
}

// ─── Data model ──────────────────────────────────────────────────────────────

class _HeroSlide {
  final String badge;
  final String title;
  final String subtitle;
  final String cta;
  final List<Color> gradientColors;
  final IconData accentIcon;

  const _HeroSlide({
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.cta,
    required this.gradientColors,
    required this.accentIcon,
  });
}

// ─── Individual card ─────────────────────────────────────────────────────────

class _HeroCard extends StatelessWidget {
  final _HeroSlide slide;

  const _HeroCard({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: slide.gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            // Background decorative circles
            Positioned(
              right: -60,
              top: -60,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              left: -30,
              bottom: -40,
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              right: 80,
              bottom: -20,
              child: Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.04),
                ),
              ),
            ),

            // ── Content ──────────────────────────────────────────────
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 80, 16),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Badge pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(slide.accentIcon, color: Colors.white, size: 12),
                          const SizedBox(width: 5),
                          Text(
                            slide.badge,
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Title
                    Text(
                      slide.title,
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        letterSpacing: -0.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 5),
                    // Subtitle
                    Text(
                      slide.subtitle,
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.75),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    // CTA pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                        ),
                      ),
                      child: Text(
                        slide.cta,
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Right-side accent icon ────────────────────────────────
            Positioned(
              right: 20,
              top: 0,
              bottom: 0,
              child: Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                  child: const Icon(
                    PhosphorIconsFill.arrowRight,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
