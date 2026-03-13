import 'dart:io';
import 'dart:convert';

import 'package:eventbridge_ai/core/network/api_service.dart';
import 'package:eventbridge_ai/core/storage/storage_service.dart';
import 'package:eventbridge_ai/core/theme/app_colors.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';

// ─── Constants ────────────────────────────────────────────────────────────────
const _kOrange = AppColors.primary01;
const _kBg = Color(0xFFF6F7FB);
const _kCard = Colors.white;
const _kText = Color(0xFF111827);
const _kMuted = Color(0xFF6B7280);
const _kBorder = Color(0xFFE5E7EB);

ImageProvider<Object> _pickedImageProvider(File file) {
  if (kIsWeb) return NetworkImage(file.path);
  return FileImage(file);
}

Widget _pickedImageWidget(
  File file, {
  required BoxFit fit,
  double? width,
  double? height,
}) {
  if (kIsWeb) {
    return Image.network(file.path, fit: fit, width: width, height: height);
  }
  return Image.file(file, fit: fit, width: width, height: height);
}

// ════════════════════════════════════════════════════════════════════════════════
class VendorOnboardingScreen extends StatefulWidget {
  const VendorOnboardingScreen({super.key});

  @override
  State<VendorOnboardingScreen> createState() => _VendorOnboardingScreenState();
}

class _VendorOnboardingScreenState extends State<VendorOnboardingScreen>
    with SingleTickerProviderStateMixin {
  final PageController _page = PageController();
  int _step = 0;

  // Step 1
  File? _avatar;
  final _bizName = TextEditingController();
  final _country = TextEditingController();
  final _location = TextEditingController();
  bool _moreServices = false;
  bool _moreEvents = false;
  final _serviceCats = [
    'DJ & Music',
    'Photographer',
    'Catering',
    'Florist',
    'Event Planner',
    'Venue',
    'Decorator',
    'Lighting',
    'Videographer',
    'MC / Host',
  ];
  final _selectedSvc = <String>{'DJ & Music'};
  final _eventCats = [
    'Weddings',
    'Corporate Galas',
    'Birthdays',
    'Baby Showers',
    'Concerts',
    'Graduations',
    'Charity Events',
    'Sports Events',
  ];
  final _selectedEvt = <String>{'Weddings'};

  // Step 2
  final _descCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 22, minute: 0);
  final _gallery = <File>[];
  final _priceCtrl = TextEditingController();

  // Step 3
  File? _licenseFile;
  File? _tinFile;
  File? _locationFile;

  // ── Nav ──────────────────────────────────────────────────────────────────────
  void _goto(int s) {
    if (s < 0 || s > 2) return;
    setState(() => _step = s);
    _page.animateToPage(s, duration: 320.ms, curve: Curves.easeInOutCubic);
  }

  // ── Pickers ──────────────────────────────────────────────────────────────────
  Future<void> _pickAvatar() async {
    final p = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (p != null && mounted) setState(() => _avatar = File(p.path));
  }

  Future<void> _pickGallery() async {
    final p = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (p != null && mounted) setState(() => _gallery.add(File(p.path)));
  }

  Future<void> _pickDoc(String key) async {
    final r = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );
    if (r != null && r.files.single.path != null && mounted) {
      final f = File(r.files.single.path!);
      setState(() {
        if (key == 'license') _licenseFile = f;
        if (key == 'tin') _tinFile = f;
        if (key == 'loc') _locationFile = f;
      });
    }
  }

  Future<void> _pickTime(bool start) async {
    final p = await showTimePicker(
      context: context,
      initialTime: start ? _startTime : _endTime,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _kOrange,
            onSurface: _kText,
          ),
        ),
        child: child!,
      ),
    );
    if (p != null && mounted) {
      setState(() => start ? _startTime = p : _endTime = p);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadDraft();
  }

  Future<void> _loadDraft() async {
    final draftStr = StorageService().getString('vendor_onboarding_draft');
    if (draftStr != null) {
      try {
        final draft = jsonDecode(draftStr);
        setState(() {
          _bizName.text = draft['bizName'] ?? '';
          _country.text = draft['country'] ?? '';
          _location.text = draft['location'] ?? '';
          _descCtrl.text = draft['desc'] ?? '';
          _expCtrl.text = draft['exp'] ?? '';
          _priceCtrl.text = draft['price'] ?? '';
          if (draft['selectedSvc'] != null) {
            _selectedSvc.clear();
            _selectedSvc.addAll(List<String>.from(draft['selectedSvc']));
          }
        });
      } catch (e) {
        debugPrint('Error loading draft: $e');
      }
    }
  }

  Future<void> _saveDraft() async {
    try {
      final draft = {
        'bizName': _bizName.text,
        'country': _country.text,
        'location': _location.text,
        'desc': _descCtrl.text,
        'exp': _expCtrl.text,
        'price': _priceCtrl.text,
        'selectedSvc': _selectedSvc.toList(),
      };
      await StorageService().setString('vendor_onboarding_draft', jsonEncode(draft));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Progress saved as draft!'), backgroundColor: Colors.green),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to save draft.'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  void dispose() {
    _page.dispose();
    _bizName.dispose();
    _country.dispose();
    _location.dispose();
    _descCtrl.dispose();
    _expCtrl.dispose();
    _priceCtrl.dispose();
    super.dispose();
  }

  // ── Submission ──────────────────────────────────────────────────────────────
  bool _isSubmitting = false;

  Future<void> _submitForm() async {
    if (_bizName.text.isEmpty || _country.text.isEmpty || _selectedSvc.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill out all required fields.'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    
    try {
      final api = ApiService.instance;
      // In a real scenario we'd get the actual user ID from the Auth state/local storage.
      // For now, we use a placeholder or decode it from the stored token.
      final mockUserId = StorageService().getString('user_email') ?? 'vendor_uuid';
      
      await api.submitVendorOnboarding(
        userId: mockUserId, // Would use actual DB user ID here
        businessName: _bizName.text,
        country: _country.text,
        location: _location.text,
        description: _descCtrl.text,
        experience: _expCtrl.text,
        price: _priceCtrl.text,
        serviceCategories: _selectedSvc.toList(),
      );

      await StorageService().remove('vendor_onboarding_draft');

      if (!mounted) return;
      context.go('/vendor-dashboard');

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = theme.scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          children: [
            _AppBar(step: _step, onHelp: () {}),
            _StepRail(
              current: _step,
              onTap: (i) {
                if (i < _step) _goto(i);
              },
            ),
            const Gap(4),
            Expanded(
              child: PageView(
                controller: _page,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (i) => setState(() => _step = i),
                children: [_step1(), _step2(), _step3()],
              ),
            ),
            if (_isSubmitting)
               const Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(color: AppColors.primary01)),
            if (!_isSubmitting)
              _BottomNav(
                step: _step,
                onNext: () =>
                    _step < 2 ? _goto(_step + 1) : _submitForm(),
                onBack: _step > 0 ? () => _goto(_step - 1) : null,
                onSkip: _step == 2 ? () => _submitForm() : null,
                onSaveDraft: _step < 2 ? _saveDraft : null,
              ),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // STEP 1 – Profile Setup
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _step1() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero title
          _SectionTitle(
                label: 'Set up your\nprovider profile',
                sub: 'Reach more event organizers and grow your business.',
              )
              .animate()
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.15, curve: Curves.easeOut),

          const Gap(20),

          // Avatar card
          _Card(
            child: Column(
              children: [
                _AvatarPicker(image: _avatar, onTap: _pickAvatar),
                const Gap(12),
                const Text(
                  'Profile Photo',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _kText,
                  ),
                ),
                const Gap(4),
                const Text(
                  'JPG · PNG · Max 5 MB',
                  style: TextStyle(fontSize: 12, color: _kMuted),
                ),
              ],
            ),
          ).animate(delay: 60.ms).fadeIn(duration: 350.ms).slideY(begin: 0.12),

          const Gap(16),

          // Business name
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel('Business Name'),
                const Gap(10),
                _Input(ctrl: _bizName, hint: 'e.g. Acme Event Solutions'),
              ],
            ),
          ).animate(delay: 100.ms).fadeIn(duration: 350.ms).slideY(begin: 0.12),

          const Gap(16),

          // Service categories
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CategoryHeader(
                  title: 'Service Categories',
                  expanded: _moreServices,
                  onToggle: () =>
                      setState(() => _moreServices = !_moreServices),
                ),
                const Gap(12),
                _ChipGrid(
                  items: _moreServices
                      ? _serviceCats
                      : _serviceCats.take(5).toList(),
                  selected: _selectedSvc,
                  onToggle: (v) => setState(
                    () => _selectedSvc.contains(v)
                        ? _selectedSvc.remove(v)
                        : _selectedSvc.add(v),
                  ),
                ),
                const Gap(8),
                _AddCustomButton(onTap: () {}),
              ],
            ),
          ).animate(delay: 130.ms).fadeIn(duration: 350.ms).slideY(begin: 0.12),

          const Gap(16),

          // Event categories
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CategoryHeader(
                  title: 'Event Categories',
                  expanded: _moreEvents,
                  onToggle: () => setState(() => _moreEvents = !_moreEvents),
                ),
                const Gap(12),
                _ChipGrid(
                  items: _moreEvents ? _eventCats : _eventCats.take(4).toList(),
                  selected: _selectedEvt,
                  onToggle: (v) => setState(
                    () => _selectedEvt.contains(v)
                        ? _selectedEvt.remove(v)
                        : _selectedEvt.add(v),
                  ),
                ),
                const Gap(8),
                _AddCustomButton(onTap: () {}),
              ],
            ),
          ).animate(delay: 160.ms).fadeIn(duration: 350.ms).slideY(begin: 0.12),

          const Gap(16),

          // Location card
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _FieldLabel('Country'),
                const Gap(10),
                _Input(ctrl: _country, hint: 'Enter country'),
                const Gap(16),
                _FieldLabel('Primary Location'),
                const Gap(10),
                _Input(
                  ctrl: _location,
                  hint: 'City, state or zip…',
                  prefix: const Icon(
                    Icons.location_on_rounded,
                    size: 18,
                    color: _kOrange,
                  ),
                ),
                const Gap(6),
                const Text(
                  "We'll match you with local events.",
                  style: TextStyle(fontSize: 12, color: _kMuted),
                ),
              ],
            ),
          ).animate(delay: 190.ms).fadeIn(duration: 350.ms).slideY(begin: 0.12),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // STEP 2 – Services
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _step2() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionTitle(
            label: 'Tell us about\nyour services',
            sub: 'Help organizers understand what you offer.',
          ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.15),

          const Gap(20),

          // Description
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CounterLabel('Service Description', _descCtrl, 500),
                const Gap(10),
                _TextArea(
                  ctrl: _descCtrl,
                  max: 500,
                  hint:
                      'Describe your style, expertise and what makes you unique…',
                ),
                const Gap(6),
                Row(
                  children: [
                    const Icon(
                      Icons.info_outline_rounded,
                      size: 13,
                      color: _kMuted,
                    ),
                    const Gap(5),
                    const Expanded(
                      child: Text(
                        'Be descriptive — this is the first thing organizers read.',
                        style: TextStyle(fontSize: 12, color: _kMuted),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ).animate(delay: 60.ms).fadeIn(duration: 350.ms).slideY(begin: 0.12),

          const Gap(16),

          // Working Hours + Experience
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldLabel('Working Hours'),
                      const Gap(10),
                      _TimeRangePicker(
                        start: _startTime,
                        end: _endTime,
                        onStart: () => _pickTime(true),
                        onEnd: () => _pickTime(false),
                      ),
                    ],
                  ),
                ),
              ),
              const Gap(12),
              Expanded(
                flex: 2,
                child: _Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _FieldLabel('Experience'),
                      const Gap(10),
                      _Input(
                        ctrl: _expCtrl,
                        hint: 'e.g. 5 years',
                        prefix: const Icon(
                          Icons.workspace_premium_outlined,
                          size: 18,
                          color: _kOrange,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ).animate(delay: 130.ms).fadeIn(duration: 350.ms).slideY(begin: 0.12),

          const Gap(16),

          // Pricing Card
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FieldLabel('Pricing'),
                const Gap(10),
                Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: _Input(
                        ctrl: _priceCtrl,
                        hint: '0,000',
                        prefix: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                '\$',
                                style: TextStyle(
                                  color: _kOrange,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness == Brightness.dark
                              ? AppColors.darkNeutral02.withValues(alpha: 0.5)
                              : const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFF333333)
                                : const Color(0xFFE5E7EB),
                          ),
                        ),
                        child: const Text(
                          'Per Event',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _kMuted,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Gap(8),
                const Text(
                  'Organizers prefer vendors with transparent starting rates.',
                  style: TextStyle(fontSize: 12, color: _kMuted),
                ),
              ],
            ),
          ).animate(delay: 160.ms).fadeIn(duration: 350.ms).slideY(begin: 0.12),

          const Gap(16),

          // Gallery
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FieldLabel('Service Gallery'),
                const Gap(10),
                _GalleryGrid(
                  images: _gallery,
                  onAdd: _pickGallery,
                  onRemove: (i) => setState(() => _gallery.removeAt(i)),
                ),
              ],
            ),
          ).animate(delay: 160.ms).fadeIn(duration: 350.ms).slideY(begin: 0.12),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════════
  // STEP 3 – Verify
  // ══════════════════════════════════════════════════════════════════════════════
  Widget _step3() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hero banner
          _VerifyHeroBanner()
              .animate()
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.15),

          const Gap(20),

          // Review process
          _Card(
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: _kOrange.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.hourglass_top_rounded,
                    color: _kOrange,
                    size: 22,
                  ),
                ),
                const Gap(14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Review Process: 24–48 Hours',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: _kText,
                        ),
                      ),
                      Gap(3),
                      Text(
                        'Our team will manually review your documents for local compliance.',
                        style: TextStyle(
                          fontSize: 12,
                          color: _kMuted,
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ).animate(delay: 60.ms).fadeIn(duration: 350.ms).slideY(begin: 0.12),

          const Gap(20),

          // Doc cards
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _DocCard(
                  icon: Icons.assignment_outlined,
                  title: 'Business\nLicense',
                  hint: 'Official business registration or license.',
                  file: _licenseFile,
                  onTap: () => _pickDoc('license'),
                ),
              ),
              const Gap(10),
              Expanded(
                child: _DocCard(
                  icon: Icons.badge_outlined,
                  title: 'TIN\nDocument',
                  hint: 'Taxpayer Identification Number.',
                  file: _tinFile,
                  onTap: () => _pickDoc('tin'),
                ),
              ),
              const Gap(10),
              Expanded(
                child: _DocCard(
                  icon: Icons.location_city_outlined,
                  title: 'Location\nProof',
                  hint: 'Utility bill, lease, or bank statement.',
                  file: _locationFile,
                  onTap: () => _pickDoc('loc'),
                ),
              ),
            ],
          ).animate(delay: 100.ms).fadeIn(duration: 350.ms).slideY(begin: 0.12),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// App Bar
// ════════════════════════════════════════════════════════════════════════════════
class _AppBar extends StatelessWidget {
  final int step;
  final VoidCallback onHelp;
  const _AppBar({required this.step, required this.onHelp});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final text = isDark ? Colors.white : const Color(0xFF111827);
    final border = isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 16, 6),
      child: Row(
        children: [
          SvgPicture.asset(
            'assets/icons/Icon.svg',
            width: 34,
            height: 34,
            colorFilter: const ColorFilter.mode(_kOrange, BlendMode.srcIn),
          ),
          const Gap(10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Event Bridge',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: text,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Vendor Portal',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkNeutral06 : Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: onHelp,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkNeutral02 : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.headset_mic_outlined,
                size: 19,
                color: isDark ? AppColors.darkNeutral06 : const Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// Step Rail
// ════════════════════════════════════════════════════════════════════════════════
class _StepRail extends StatelessWidget {
  final int current;
  final ValueChanged<int> onTap;
  const _StepRail({required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const labels = ['Profile Setup', 'Services', 'Verify'];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final card = isDark ? AppColors.darkNeutral02 : Colors.white;
    final border = isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB);

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 6, 20, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(labels.length, (i) {
          final done = current > i;
          final active = current == i;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              behavior: HitTestBehavior.opaque,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: 280.ms,
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: (done || active) ? _kOrange : Colors.grey.shade100,
                      shape: BoxShape.circle,
                      boxShadow: active
                          ? [
                              BoxShadow(
                                color: _kOrange.withValues(alpha: 0.35),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ]
                          : null,
                    ),
                    child: Center(
                      child: done
                          ? const Icon(
                              Icons.check_rounded,
                              color: Colors.white,
                              size: 15,
                            )
                          : Text(
                              '${i + 1}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: active
                                    ? Colors.white
                                    : Colors.grey.shade400,
                              ),
                            ),
                    ),
                  ),
                  const Gap(7),
                  Text(
                    labels[i],
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: (done || active) ? _kOrange : Colors.grey.shade400,
                    ),
                  ),
                  if (i < labels.length - 1) ...[
                    const Spacer(),
                    Container(
                      width: 20,
                      height: 1.5,
                      color: current > i
                          ? _kOrange.withValues(alpha: 0.5)
                          : _kBorder,
                    ),
                    const Spacer(),
                  ],
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// Bottom Nav
// ════════════════════════════════════════════════════════════════════════════════
class _BottomNav extends StatelessWidget {
  final int step;
  final VoidCallback onNext;
  final VoidCallback? onBack;
  final VoidCallback? onSkip;
  final VoidCallback? onSaveDraft;
  const _BottomNav({
    required this.step,
    required this.onNext,
    this.onBack,
    this.onSkip,
    this.onSaveDraft,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.darkNeutral02 : Colors.white;
    final border = isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB);
    final muted = isDark ? AppColors.darkNeutral06 : const Color(0xFF6B7280);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 22),
      decoration: BoxDecoration(
        color: card,
        border: Border(top: BorderSide(color: border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: Row(
        children: [
          if (onBack != null) ...[
            GestureDetector(
              onTap: onBack,
              child: Container(
                height: 50,
                width: 50,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkNeutral03 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.arrow_back_rounded,
                  color: isDark ? Colors.white : const Color(0xFF111827),
                  size: 20,
                ),
              ),
            ),
            const Gap(12),
          ],
          if (onSkip != null) ...[
            GestureDetector(
              onTap: onSkip,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'Skip & Finish',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: muted,
                  ),
                ),
              ),
            ),
            const Spacer(),
          ],
          if (onSaveDraft != null) ...[
            GestureDetector(
              onTap: onSaveDraft,
              child: Text(
                'Save Draft',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.darkNeutral04 : Colors.grey.shade500,
                ),
              ),
            ),
            const Gap(16),
          ],
          if (onSkip == null) const Spacer(),
          _PrimaryButton(
            label: step == 2 ? 'Submit for Review' : 'Next Step',
            onTap: onNext,
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════════
// Reusable Widgets
// ════════════════════════════════════════════════════════════════════════════════

// Card
class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? AppColors.darkNeutral02 : Colors.white;
    final borderColor = isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}

// Section title
class _SectionTitle extends StatelessWidget {
  final String label, sub;
  const _SectionTitle({required this.label, required this.sub});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final text = isDark ? Colors.white : const Color(0xFF111827);
    final muted = isDark ? AppColors.darkNeutral06 : const Color(0xFF6B7280);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: text,
            height: 1.2,
            letterSpacing: -0.5,
          ),
        ),
        const Gap(6),
        Text(
          sub,
          style: TextStyle(fontSize: 14, color: muted, height: 1.5),
        ),
      ],
    );
  }
}

// Field label
class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.white : const Color(0xFF111827);

    return Text(
      text,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: color,
      ),
    );
  }
}

// Counter label
class _CounterLabel extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final int max;
  const _CounterLabel(this.label, this.ctrl, this.max);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);

    return ValueListenableBuilder(
      valueListenable: ctrl,
      builder: (_, __, ___) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
          Text(
            '${ctrl.text.length}/$max',
            style: TextStyle(
              fontSize: 12,
              color: ctrl.text.length >= max ? Colors.red : Colors.grey.shade400,
            ),
          ),
        ],
      ),
    );
  }
}

// Input
class _Input extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final Widget? prefix;
  const _Input({required this.ctrl, required this.hint, this.prefix});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final text = isDark ? Colors.white : const Color(0xFF111827);
    final muted = isDark ? AppColors.darkNeutral06 : const Color(0xFF6B7280);
    final fill = isDark ? AppColors.darkNeutral02.withValues(alpha: 0.5) : const Color(0xFFF9FAFB);
    final border = isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB);

    return TextField(
      controller: ctrl,
      style: TextStyle(fontSize: 14, color: text),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 14, color: muted),
        prefixIcon: prefix,
        filled: true,
        fillColor: fill,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kOrange, width: 1.5),
        ),
      ),
    );
  }
}

// Text area
class _TextArea extends StatelessWidget {
  final TextEditingController ctrl;
  final String hint;
  final int max;
  const _TextArea({required this.ctrl, required this.hint, required this.max});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final text = isDark ? Colors.white : const Color(0xFF111827);
    final muted = isDark ? AppColors.darkNeutral06 : const Color(0xFF6B7280);
    final fill = isDark ? AppColors.darkNeutral02.withValues(alpha: 0.5) : const Color(0xFFF9FAFB);
    final border = isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB);

    return TextField(
      controller: ctrl,
      maxLines: 5,
      maxLength: max,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      style: TextStyle(fontSize: 14, color: text),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(fontSize: 14, color: muted),
        filled: true,
        fillColor: fill,
        contentPadding: const EdgeInsets.all(14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kOrange, width: 1.5),
        ),
        counterText: '',
      ),
    );
  }
}

// Category header with expand
class _CategoryHeader extends StatelessWidget {
  final String title;
  final bool expanded;
  final VoidCallback onToggle;
  const _CategoryHeader({
    required this.title,
    required this.expanded,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: _kText,
        ),
      ),
      GestureDetector(
        onTap: onToggle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _kOrange.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                expanded ? 'Show less' : 'View all',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kOrange,
                ),
              ),
              const Gap(3),
              Icon(
                expanded
                    ? Icons.expand_less_rounded
                    : Icons.expand_more_rounded,
                size: 14,
                color: _kOrange,
              ),
            ],
          ),
        ),
      ),
    ],
  );
}

// Chips grid
class _ChipGrid extends StatelessWidget {
  final List<String> items;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  const _ChipGrid({
    required this.items,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.darkNeutral03 : Colors.white;
    final border = isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB);
    final muted = isDark ? AppColors.darkNeutral06 : const Color(0xFF6B7280);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items.map((item) {
        final sel = selected.contains(item);
        return GestureDetector(
          onTap: () => onToggle(item),
          child: AnimatedContainer(
            duration: 200.ms,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: sel ? _kOrange : card,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: sel ? _kOrange : border,
                width: sel ? 1.5 : 1,
              ),
              boxShadow: sel
                  ? [
                      BoxShadow(
                        color: _kOrange.withValues(alpha: 0.2),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (sel) ...[
                  const Icon(Icons.check_rounded, size: 13, color: Colors.white),
                  const Gap(4),
                ],
                Text(
                  item,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: sel ? Colors.white : muted,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// Add custom button
class _AddCustomButton extends StatelessWidget {
  final VoidCallback onTap;
  const _AddCustomButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.darkNeutral03 : Colors.white;
    final border = isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: card,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: border, style: BorderStyle.solid),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add_rounded, size: 15, color: Colors.grey.shade500),
            const Gap(4),
            Text(
              'Add Custom',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Avatar picker
class _AvatarPicker extends StatelessWidget {
  final File? image;
  final VoidCallback onTap;
  const _AvatarPicker({required this.image, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border = isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB);
    final bg = isDark ? AppColors.darkNeutral03 : const Color(0xFFF3F4F6);

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: bg,
              border: Border.all(color: border, width: 2),
              image: image != null
                  ? DecorationImage(
                      image: _pickedImageProvider(image!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: image == null
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.camera_alt_outlined,
                        size: 26,
                        color: Colors.grey.shade400,
                      ),
                      const Gap(4),
                      Text(
                        'Upload',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  )
                : null,
          ),
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: _kOrange,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
          ),
        ],
      ),
    );
  }
}

// Time range picker
class _TimeRangePicker extends StatelessWidget {
  final TimeOfDay start, end;
  final VoidCallback onStart, onEnd;
  const _TimeRangePicker({
    required this.start,
    required this.end,
    required this.onStart,
    required this.onEnd,
  });

  String _f(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: _TimeChip(label: _f(start), onTap: onStart),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          '–',
          style: TextStyle(fontSize: 16, color: Colors.grey.shade400),
        ),
      ),
      Expanded(
        child: _TimeChip(label: _f(end), onTap: onEnd),
      ),
    ],
  );
}

class _TimeChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _TimeChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark ? AppColors.darkNeutral02.withValues(alpha: 0.5) : const Color(0xFFF9FAFB);
    final border = isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB);
    final text = isDark ? Colors.white : const Color(0xFF111827);
    final muted = isDark ? AppColors.darkNeutral06 : const Color(0xFF6B7280);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: text,
              ),
            ),
            Icon(Icons.access_time_rounded, size: 14, color: muted),
          ],
        ),
      ),
    );
  }
}

// Gallery grid
class _GalleryGrid extends StatelessWidget {
  final List<File> images;
  final VoidCallback onAdd;
  final ValueChanged<int> onRemove;
  const _GalleryGrid({
    required this.images,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? AppColors.darkNeutral03 : const Color(0xFFF9FAFB);
    final border = isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB);
    final muted = isDark ? AppColors.darkNeutral06 : const Color(0xFF6B7280);

    final all = [...images, null]; // null = add button slot
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 1,
      ),
      itemCount: all.length,
      itemBuilder: (_, i) {
        if (all[i] == null) {
          return GestureDetector(
            onTap: onAdd,
            child: Container(
              decoration: BoxDecoration(
                color: _kOrange.withValues(alpha: isDark ? 0.12 : 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kOrange.withValues(alpha: 0.3)),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: _kOrange,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                  const Gap(6),
                  const Text(
                    'Add',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: _kOrange,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
        return Stack(
          children: [
            Positioned.fill(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _pickedImageWidget(images[i], fit: BoxFit.cover),
              ),
            ),
            Positioned(
              top: 5,
              right: 5,
              child: GestureDetector(
                onTap: () => onRemove(i),
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 13),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Doc upload card
class _DocCard extends StatelessWidget {
  final IconData icon;
  final String title, hint;
  final File? file;
  final VoidCallback onTap;
  const _DocCard({
    required this.icon,
    required this.title,
    required this.hint,
    required this.onTap,
    this.file,
  });

  bool _isImageFile(String path) {
    final p = path.toLowerCase();
    return p.endsWith('.jpg') || p.endsWith('.jpeg') || p.endsWith('.png');
  }

  String _fileName(String path) {
    return path.replaceAll('\\', '/').split('/').last;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final done = file != null;
    final imagePreview = done && _isImageFile(file!.path);
    final card = isDark ? AppColors.darkNeutral02 : Colors.white;
    final border = isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB);
    final text = isDark ? Colors.white : const Color(0xFF111827);
    final muted = isDark ? AppColors.darkNeutral06 : const Color(0xFF6B7280);
    final iconBg = isDark ? AppColors.darkNeutral03 : const Color(0xFFF3F4F6);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 250.ms,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: done ? _kOrange.withValues(alpha: 0.05) : card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: done ? _kOrange.withValues(alpha: 0.5) : border,
            width: done ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            if (imagePreview)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _pickedImageWidget(
                  file!,
                  fit: BoxFit.cover,
                  height: 66,
                  width: 66,
                ),
              )
            else
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: done
                      ? _kOrange.withValues(alpha: 0.12)
                      : iconBg,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  done ? Icons.check_circle_outline_rounded : icon,
                  color: done ? _kOrange : muted,
                  size: 22,
                ),
              ),
            const Gap(10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: text,
                height: 1.3,
              ),
            ),
            const Gap(5),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: muted, height: 1.4),
            ),
            if (done) ...[
              const Gap(6),
              Text(
                _fileName(file!.path),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  color: muted,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const Gap(12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
              decoration: BoxDecoration(
                color: done ? _kOrange : (isDark ? AppColors.darkNeutral03 : Colors.white),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: done ? _kOrange : border),
              ),
              child: Text(
                done ? 'Uploaded ✓' : 'Upload Files\n(PDF/JPG)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: done ? Colors.white : text,
                  height: 1.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Verify hero banner
class _VerifyHeroBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      gradient: const LinearGradient(
        colors: [Color(0xFFFF6B35), Color(0xFFFF3D00)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: _kOrange.withValues(alpha: 0.35),
          blurRadius: 16,
          offset: const Offset(0, 6),
        ),
      ],
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.verified_rounded, color: Colors.white, size: 20),
                  Gap(8),
                  Text(
                    'Boost trust with verification',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const Gap(6),
              const Text(
                '(optional)',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Gap(10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '2x more leads for verified vendors',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const Gap(10),
              Text(
                "You can do this later, but starting now helps you rank higher.",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.85),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        const Gap(12),
        const Icon(Icons.shield_rounded, color: Colors.white, size: 60),
      ],
    ),
  );
}

// Primary button
class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFFF3D00)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: _kOrange.withValues(alpha: 0.4),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.2,
            ),
          ),
          const Gap(8),
          const Icon(
            Icons.arrow_forward_rounded,
            color: Colors.white,
            size: 18,
          ),
        ],
      ),
    ),
  );
}
