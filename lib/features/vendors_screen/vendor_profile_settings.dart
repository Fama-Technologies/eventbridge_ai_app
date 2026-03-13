import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
// import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:go_router/go_router.dart';

class VendorProfileSettingsScreen extends StatefulWidget {
  const VendorProfileSettingsScreen({super.key});

  @override
  State<VendorProfileSettingsScreen> createState() =>
      _VendorProfileSettingsScreenState();
}

class _VendorProfileSettingsScreenState
    extends State<VendorProfileSettingsScreen> {
  double _travelRadius = 50.0;
  final String _vendorPlan = 'business_pro';

  final List<String> _portfolioImages = [
    'https://images.unsplash.com/photo-1519741497674-611481863552?q=80&w=1000&auto=format&fit=crop',
    'https://images.unsplash.com/photo-1511795409834-ef04bbd61622?q=80&w=1000&auto=format&fit=crop',
  ];

  int get _maxImages => _vendorPlan == 'business_pro' ? 20 : 12;

  final _instaCtrl = TextEditingController(text: '@goldenhour_photo');
  final _tiktokCtrl = TextEditingController(text: '@goldenhour_weddings');
  final _fbCtrl = TextEditingController(text: 'Golden Hour Photography');
  final _webCtrl = TextEditingController(text: 'www.goldenhour.com');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1A24)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Vendor Profile Settings',
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A24),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _ProfileSectionHeader(
              icon: Icons.store_rounded,
              title: 'Business Info',
            ),
            const SizedBox(height: 16),
            _buildPremiumTextField(
              label: 'Business Name',
              initialValue: 'Golden Hour Photography',
            ),
            const SizedBox(height: 16),
            _buildPremiumTextField(
              label: 'Business Description',
              initialValue:
                  'Specializing in cinematic natural light wedding photography and candid event coverage.',
              maxLines: 4,
            ),
            const SizedBox(height: 32),
            _ProfileSectionHeader(
              icon: Icons.auto_awesome_rounded,
              title: 'AI Matching Tags',
            ),
            const SizedBox(height: 8),
            Text(
              'Select keywords that describe your expertise to help our AI match you with the right clients.',
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            const _TagWrap(),
            const SizedBox(height: 32),
            _ProfileSectionHeader(
              icon: Icons.image_rounded,
              title: 'Portfolio',
              trailing: '${_portfolioImages.length} / $_maxImages',
            ),
            const SizedBox(height: 16),
            _PortfolioGrid(
              images: _portfolioImages,
              maxImages: _maxImages,
              onAdd: () {
                if (_portfolioImages.length < _maxImages) {
                  setState(() {
                    _portfolioImages.add(
                      'https://images.unsplash.com/photo-1519741497674-611481863552?q=80&w=1000&auto=format&fit=crop',
                    );
                  });
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Portfolio limit reached for your plan.')),
                  );
                }
              },
              onRemove: (index) {
                setState(() => _portfolioImages.removeAt(index));
              },
            ),
            const SizedBox(height: 32),
            _ProfileSectionHeader(
              icon: Icons.link_rounded,
              title: 'Social Links',
            ),
            const SizedBox(height: 16),
            _buildPremiumTextField(label: 'Instagram', initialValue: _instaCtrl.text, controller: _instaCtrl),
            const SizedBox(height: 12),
            _buildPremiumTextField(label: 'TikTok', initialValue: _tiktokCtrl.text, controller: _tiktokCtrl),
            const SizedBox(height: 12),
            _buildPremiumTextField(label: 'Facebook', initialValue: _fbCtrl.text, controller: _fbCtrl),
            const SizedBox(height: 12),
            _buildPremiumTextField(label: 'Website', initialValue: _webCtrl.text, controller: _webCtrl),
            const SizedBox(height: 32),
            _ProfileSectionHeader(
              icon: Icons.location_on_rounded,
              title: 'Service Areas',
            ),
            const SizedBox(height: 16),
            _ServiceAreaCard(
              radius: _travelRadius,
              onChanged: (val) => setState(() => _travelRadius = val),
            ),
            const SizedBox(height: 16),
            _buildPrimaryLocation(),
            const SizedBox(height: 32),
            _ProfileSectionHeader(
              icon: Icons.local_offer_rounded,
              title: 'Pricing Packages',
              trailing: 'Manage',
              onTrailingPressed: () => context.push('/vendor-packages'),
            ),
            const SizedBox(height: 16),
            _buildPackageSummaryTile(context),
            const SizedBox(height: 32),
            _ProfileSectionHeader(
              icon: Icons.calendar_month_rounded,
              title: 'Availability',
            ),
            const SizedBox(height: 16),
            const _AvailabilityCalendar(),
            const SizedBox(height: 48),
            _buildPremiumSaveButton(),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumTextField({
    required String label,
    required String initialValue,
    int maxLines = 1,
    TextEditingController? controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF475569),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: TextField(
            maxLines: maxLines,
            controller: controller ?? TextEditingController(text: initialValue),
            style: GoogleFonts.roboto(
              fontSize: 15,
              color: const Color(0xFF1E293B),
            ),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.all(18),
              border: InputBorder.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryLocation() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.location_on, size: 16, color: Color(0xFF64748B)),
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(
              style: GoogleFonts.roboto(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
              children: [
                const TextSpan(text: 'Primary Location: '),
                TextSpan(
                  text: 'Austin, TX',
                  style: GoogleFonts.roboto(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPackageSummaryTile(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/vendor-packages'),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFF1F5F9)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF0F9FF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.inventory_2_rounded,
                color: Color(0xFF0EA5E9),
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '3 Pricing Packages',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Starter, Premium, and Candid Mini',
                    style: GoogleFonts.roboto(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF94A3B8)),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumSaveButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFF97316), Color(0xFFEA580C)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF97316).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: const Icon(Icons.check_circle_rounded, size: 22),
        label: Text(
          'Save Changes',
          style: GoogleFonts.roboto(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

class _ProfileSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final VoidCallback? onTrailingPressed;

  const _ProfileSectionHeader({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTrailingPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 22, color: const Color(0xFFF97316)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.roboto(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0F172A),
              ),
            ),
          ),
          if (trailing != null)
            TextButton(
              onPressed: onTrailingPressed ?? () {},
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFF97316),
                visualDensity: VisualDensity.compact,
              ),
              child: Text(
                trailing!,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TagWrap extends StatelessWidget {
  const _TagWrap();

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _buildAnimatedTag('Natural Look', isSelected: true),
        _buildAnimatedTag('Cinematic', isSelected: true),
        _buildAnimatedTag('Luxury Events'),
        _buildAnimatedTag('Minimalist'),
        _buildAnimatedTag('Vegan Catering'),
        _buildActionTag('+ Add Tag'),
      ],
    );
  }

  Widget _buildAnimatedTag(String label, {bool isSelected = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFFF97316) : Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isSelected ? const Color(0xFFF97316) : const Color(0xFFE2E8F0),
        ),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: const Color(0xFFF97316).withValues(alpha: 0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: GoogleFonts.roboto(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : const Color(0xFF475569),
            ),
          ),
          if (isSelected) ...[
            const SizedBox(width: 6),
            const Icon(Icons.close, size: 14, color: Colors.white),
          ],
        ],
      ),
    );
  }

  Widget _buildActionTag(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFFFEDD5)),
      ),
      child: Text(
        label,
        style: GoogleFonts.roboto(
          fontSize: 13,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFF97316),
        ),
      ),
    );
  }
}

class _PortfolioGrid extends StatelessWidget {
  final List<String> images;
  final int maxImages;
  final VoidCallback onAdd;
  final Function(int) onRemove;

  const _PortfolioGrid({
    required this.images,
    required this.maxImages,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: images.length < maxImages ? images.length + 1 : images.length,
        itemBuilder: (context, index) {
          if (index == images.length) {
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _buildAddMoreCard(),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildImageCard(images[index], index),
          );
        },
      ),
    );
  }

  Widget _buildImageCard(String url, int index) {
    return Stack(
      children: [
        Container(
          width: 110,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            image: DecorationImage(image: NetworkImage(url), fit: BoxFit.cover),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => onRemove(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close_rounded, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAddMoreCard() {
    return GestureDetector(
      onTap: onAdd,
      child: Container(
        width: 110,
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFFFEDD5), width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.add_rounded, color: Color(0xFFF97316), size: 28),
            const SizedBox(height: 6),
            Text(
              'ADD MORE',
              style: GoogleFonts.roboto(
                fontSize: 11,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFF97316),
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServiceAreaCard extends StatelessWidget {
  final double radius;
  final ValueChanged<double> onChanged;

  const _ServiceAreaCard({required this.radius, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Travel Radius',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${radius.toInt()} miles',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFF97316),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SliderTheme(
            data: SliderThemeData(
              trackHeight: 6,
              activeTrackColor: const Color(0xFFF97316),
              inactiveTrackColor: const Color(0xFFFFEDD5),
              thumbColor: Colors.white,
              overlayColor: const Color(0xFFF97316).withValues(alpha: 0.1),
              thumbShape: const RoundSliderThumbShape(
                enabledThumbRadius: 12,
                elevation: 4,
              ),
            ),
            child: Slider(
              value: radius,
              min: 0,
              max: 100,
              onChanged: onChanged,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['0MI', '25MI', '50MI', '75MI', '100+MI'].map((label) {
              return Text(
                label,
                style: GoogleFonts.roboto(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF94A3B8),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _AvailabilityCalendar extends StatelessWidget {
  const _AvailabilityCalendar();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'September 2024',
                style: GoogleFonts.roboto(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
              Row(
                children: [
                  _CalendarNav(icon: Icons.chevron_left),
                  const SizedBox(width: 12),
                  _CalendarNav(icon: Icons.chevron_right),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ['SUN', 'MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT'].map((
              day,
            ) {
              return Expanded(
                child: Center(
                  child: Text(
                    day,
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 7,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            children: List.generate(35, (index) {
              final day = index - 3;
              if (day < 1 || day > 30) return const SizedBox();

              bool isSelected = day == 7;
              bool isPending = day == 6 || day == 3;

              return _CalendarDay(
                day: day,
                isSelected: isSelected,
                isPending: isPending,
              );
            }),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendItem(label: 'SELECTED', color: const Color(0xFFF97316)),
              const SizedBox(width: 24),
              _LegendItem(label: 'PENDING', color: const Color(0xFFFFEDD5)),
              const SizedBox(width: 24),
              _LegendItem(label: 'FREE', color: const Color(0xFFF1F5F9)),
            ],
          ),
        ],
      ),
    );
  }
}

class _CalendarNav extends StatelessWidget {
  final IconData icon;
  const _CalendarNav({required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Icon(icon, size: 20, color: const Color(0xFF64748B)),
    );
  }
}

class _CalendarDay extends StatelessWidget {
  final int day;
  final bool isSelected;
  final bool isPending;

  const _CalendarDay({
    required this.day,
    required this.isSelected,
    required this.isPending,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor = Colors.transparent;
    Color textColor = const Color(0xFF475569);
    FontWeight weight = FontWeight.normal;

    if (isSelected) {
      bgColor = const Color(0xFFF97316);
      textColor = Colors.white;
      weight = FontWeight.bold;
    } else if (isPending) {
      bgColor = const Color(0xFFFFEDD5);
      textColor = const Color(0xFFF97316);
      weight = FontWeight.bold;
    }

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          '$day',
          style: GoogleFonts.roboto(
            fontSize: 14,
            color: textColor,
            fontWeight: weight,
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final String label;
  final Color color;

  const _LegendItem({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: GoogleFonts.roboto(
            fontSize: 10,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF94A3B8),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }
}
