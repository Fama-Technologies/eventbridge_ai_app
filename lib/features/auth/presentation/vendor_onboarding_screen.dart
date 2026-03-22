import 'dart:io';
import 'dart:convert';
import 'dart:typed_data';

import 'package:eventbridge/core/network/api_service.dart';
import 'package:eventbridge/core/services/upload_service.dart';
import 'package:eventbridge/core/storage/storage_service.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:eventbridge/core/widgets/app_toast.dart';
import 'dart:async';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:dio/dio.dart';

// ─── Constants ────────────────────────────────────────────────────────────────
const _kOrange = AppColors.primary01;
const _kBg = Color(0xFFF6F7FB);
const _kCard = Colors.white;
const _kText = Color(0xFF111827);
const _kMuted = AppColors.darkNeutral06; // Changed from Color(0xFF6B7280)
const _kBorder = Color(0xFFE5E7EB);
const _kMapsApiKey = "AIzaSyBh-GVHVYhZ7irbZ5o8QAyzpZPsXuNUwLM"; // Added

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
  double? _lat;
  double? _lng;
  double _radiusKm = 20.0;
  
  // Autocomplete state
  Timer? _debounce;
  List<Map<String, String>> _placeSuggestions = [];
  bool _isLoadingPlaces = false;
  String? _selectedPlaceDescription;
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
  String _selectedCurrency = 'UGX';
  final List<String> _currencies = ['UGX', 'USD', 'KES', 'TZS', 'RWF', 'GBP', 'EUR'];
  String _selectedPriceUnit = 'Per Event';
  final List<String> _priceUnits = ['Per Event', 'Per Plate', 'Per Hour', 'Per Day', 'Per Session', 'Flat Rate'];

  // ── Nav ──────────────────────────────────────────────────────────────────────
  void _goto(int s) {
    if (s < 0 || s > 1) return;
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

  Future<void> _showLocationPicker() async {
    // Check permissions
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) AppToast.show(context, message: 'Location services are disabled.', type: ToastType.error);
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) AppToast.show(context, message: 'Location permissions are denied.', type: ToastType.error);
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) AppToast.show(context, message: 'Location permissions are permanently denied.', type: ToastType.error);
      return;
    }

    Position? currentPos;
    try {
      currentPos = await Geolocator.getCurrentPosition();
    } catch (_) {}

    if (!mounted) return;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _LocationPickerSheet(
        initialLat: _lat ?? currentPos?.latitude ?? 0.3476, // default Kampala
        initialLng: _lng ?? currentPos?.longitude ?? 32.5825,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _lat = result['lat'];
        _lng = result['lng'];
        _location.text = result['address'];
        _selectedPlaceDescription = result['address']; // Update selected place description
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
    _location.addListener(_onLocationChanged); // Added listener
  }

  @override
  void dispose() {
    _location.removeListener(_onLocationChanged); // Removed listener
    _page.dispose();
    _bizName.dispose();
    _country.dispose();
    _location.dispose();
    _descCtrl.dispose();
    _expCtrl.dispose();
    _priceCtrl.dispose();
    _debounce?.cancel(); // Cancel debounce timer
    super.dispose();
  }

  void _onLocationChanged() {
    final query = _location.text;
    if (query.isEmpty || query == _selectedPlaceDescription) {
      if (_placeSuggestions.isNotEmpty) {
        setState(() => _placeSuggestions.clear());
      }
      return;
    }

    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      _fetchPlaceSuggestions(query);
    });
  }

  Future<void> _fetchPlaceSuggestions(String query) async {
    if (query.isEmpty) return;
    setState(() => _isLoadingPlaces = true);
    try {
      final url = 'https://maps.googleapis.com/maps/api/place/autocomplete/json?input=$query&key=$_kMapsApiKey';
      final res = await Dio().get(url);
      if (res.data['status'] == 'OK') {
        final preds = res.data['predictions'] as List;
        setState(() {
          _placeSuggestions = preds.map((p) => {
            'description': p['description'] as String,
            'place_id': p['place_id'] as String,
          }).toList();
        });
      } else {
        setState(() => _placeSuggestions.clear());
      }
    } catch (_) {
      setState(() => _placeSuggestions.clear());
    } finally {
      if (mounted) setState(() => _isLoadingPlaces = false);
    }
  }

  Future<void> _selectPlace(String placeId, String description) async {
    setState(() {
      _selectedPlaceDescription = description;
      _location.text = description;
      _placeSuggestions.clear();
      FocusScope.of(context).unfocus();
    });

    try {
      final url = 'https://maps.googleapis.com/maps/api/place/details/json?place_id=$placeId&key=$_kMapsApiKey';
      final res = await Dio().get(url);
      if (res.data['status'] == 'OK') {
        final resultInfo = res.data['result'];
        final loc = resultInfo['geometry']['location'];
        final addressComponents = resultInfo['address_components'] as List?;
        String? foundCountry;
        if (addressComponents != null) {
          for (var comp in addressComponents) {
            final types = comp['types'] as List;
            if (types.contains('country')) {
              foundCountry = comp['long_name'];
              break;
            }
          }
        }
        setState(() {
          _lat = loc['lat'];
          _lng = loc['lng'];
          if (foundCountry != null) {
             _country.text = foundCountry;
             // Auto-select currency based on country for convenience
             if (foundCountry.contains('Uganda')) _selectedCurrency = 'UGX';
             else if (foundCountry.contains('Kenya')) _selectedCurrency = 'KES';
             else if (foundCountry.contains('Tanzania')) _selectedCurrency = 'TZS';
             else if (foundCountry.contains('Rwanda')) _selectedCurrency = 'RWF';
             else _selectedCurrency = 'USD';
          }
        });
      }
    } catch (_) {
      if (mounted) AppToast.show(context, message: 'Could not fetch coordinates.', type: ToastType.error);
    }
  }

  Future<void> _loadDraft() async {
    final draftStr = StorageService().getString('vendor_onboarding_draft');
    debugPrint('📋 Loading draft: ${draftStr != null ? "found" : "none"}');
    if (draftStr != null) {
      try {
        final draft = jsonDecode(draftStr);
        setState(() {
          _bizName.text = draft['bizName'] ?? '';
          _country.text = draft['country'] ?? '';
          _location.text = draft['location'] ?? '';
          if (draft['lat'] != null) _lat = (draft['lat'] as num).toDouble();
          if (draft['lng'] != null) _lng = (draft['lng'] as num).toDouble();
          if (draft['radiusKm'] != null) _radiusKm = (draft['radiusKm'] as num).toDouble();
          if (draft['currency'] != null) _selectedCurrency = draft['currency'];
          if (draft['priceUnit'] != null) _selectedPriceUnit = draft['priceUnit'];
          _selectedPlaceDescription = _location.text; // Added this line
          _descCtrl.text = draft['desc'] ?? '';
          _expCtrl.text = draft['exp'] ?? '';
          _priceCtrl.text = draft['price'] ?? '';
          if (draft['selectedSvc'] != null) {
            _selectedSvc.clear();
            _selectedSvc.addAll(List<String>.from(draft['selectedSvc']));
          }
          if (draft['selectedEvt'] != null) {
            _selectedEvt.clear();
            _selectedEvt.addAll(List<String>.from(draft['selectedEvt']));
          }
          // Resume from saved step
          final savedStep = draft['step'] ?? 0;
          if (savedStep > 0 && savedStep <= 2) {
            _step = savedStep;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              _page.jumpToPage(savedStep);
            });
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
        'lat': _lat,
        'lng': _lng,
        'radiusKm': _radiusKm,
        'desc': _descCtrl.text,
        'exp': _expCtrl.text,
        'price': _priceCtrl.text,
        'selectedSvc': _selectedSvc.toList(),
        'selectedEvt': _selectedEvt.toList(),
        'currency': _selectedCurrency,
        'priceUnit': _selectedPriceUnit,
        'step': _step,
      };
      final jsonStr = jsonEncode(draft);
      await StorageService().setString('vendor_onboarding_draft', jsonStr);
      debugPrint('📋 Draft saved: $jsonStr');
      if (!mounted) return;
      AppToast.show(context, message: 'Progress saved as draft!', type: ToastType.success);
    } catch (e) {
      debugPrint('❌ Draft save error: $e');
      if (!mounted) return;
      AppToast.show(context, message: 'Failed to save draft.', type: ToastType.error);
    }
  }

  // ── Submission ──────────────────────────────────────────────────────────────
  bool _isSubmitting = false;

  Future<void> _submitForm() async {
    if (_bizName.text.isEmpty || _country.text.isEmpty || _selectedSvc.isEmpty) {
      AppToast.show(context, message: 'Please fill out all required fields.', type: ToastType.error);
      return;
    }

    setState(() => _isSubmitting = true);
    
    try {
      final api = ApiService.instance;
      final upload = UploadService.instance;
      final userId = StorageService().getString('user_id') ?? '';

      // Upload avatar to S3
      String? avatarUrl;
      if (_avatar != null) {
        final bytes = kIsWeb
            ? await _readWebFileBytes(_avatar!)
            : await _avatar!.readAsBytes();
        avatarUrl = await upload.uploadFile(
          bytes: bytes,
          fileName: 'avatar_${DateTime.now().millisecondsSinceEpoch}.jpg',
          contentType: 'image/jpeg',
          folder: 'avatars/$userId',
        );
      }

      // Upload gallery images to S3
      List<String>? galleryUrls;
      if (_gallery.isNotEmpty) {
        galleryUrls = [];
        for (int i = 0; i < _gallery.length; i++) {
          final bytes = kIsWeb
              ? await _readWebFileBytes(_gallery[i])
              : await _gallery[i].readAsBytes();
          final url = await upload.uploadFile(
            bytes: bytes,
            fileName: 'gallery_${i}_${DateTime.now().millisecondsSinceEpoch}.jpg',
            contentType: 'image/jpeg',
            folder: 'gallery/$userId',
          );
          galleryUrls.add(url);
        }
      }
      
      await api.submitVendorOnboarding(
        userId: userId,
        businessName: _bizName.text,
        country: _country.text,
        location: _location.text,
        description: _descCtrl.text,
        experience: _expCtrl.text,
        price: _priceCtrl.text,
        serviceCategories: _selectedSvc.toList(),
        eventCategories: _selectedEvt.toList(),
        avatarUrl: avatarUrl,
        galleryUrls: galleryUrls,
        latitude: _lat,
        longitude: _lng,
        travelRadius: _radiusKm.toInt(),
        currency: _selectedCurrency,
        priceUnit: _selectedPriceUnit,
        isVerified: false,
      );

      await StorageService().remove('vendor_onboarding_draft');
      await StorageService().setString('onboarding_completed', 'true');
      if (avatarUrl != null) {
        await StorageService().setString('user_image', avatarUrl);
      }

      if (!mounted) return;
      context.go('/vendor-home');

    } catch (e) {
      if (mounted) AppToast.show(context, message: 'Error: ${e.toString().replaceAll('Exception: ', '')}', type: ToastType.error);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  Future<Uint8List> _readWebFileBytes(File file) async {
    // On web, File.path is a blob URL, use XFile approach
    final xFile = XFile(file.path);
    return await xFile.readAsBytes();
  }

  Future<void> _addCustomCategory(bool isService) async {
    final ctrl = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final result = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkNeutral02 : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 20,
                  offset: Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkNeutral03 : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Gap(24),
                Text(
                  'Add Custom ${isService ? 'Service' : 'Event'}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const Gap(8),
                Text(
                  isService
                      ? 'Type the name of a specialty service you provide.'
                      : 'Type the name of a unique event type you cover.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.darkNeutral06,
                  ),
                ),
                const Gap(24),
                TextField(
                  controller: ctrl,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 16,
                  ),
                  decoration: InputDecoration(
                    hintText: isService ? 'e.g. Drone Photography' : 'e.g. Cultural Ceremonies',
                    hintStyle: const TextStyle(color: Color(0xFF9CA3AF), fontSize: 15),
                    filled: true,
                    fillColor: isDark ? AppColors.darkNeutral03 : const Color(0xFFF9FAFB),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: isDark ? const Color(0xFF333333) : Colors.grey.shade200),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide(color: isDark ? const Color(0xFF333333) : Colors.grey.shade200),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: const BorderSide(color: AppColors.primary01, width: 2),
                    ),
                  ),
                ),
                const Gap(24),
                ElevatedButton(
                  onPressed: () {
                    if (ctrl.text.trim().isNotEmpty) {
                       Navigator.pop(ctx, ctrl.text.trim());
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary01,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Add Category', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (result != null && result.isNotEmpty && mounted) {
      setState(() {
        if (isService) {
          if (!_serviceCats.contains(result)) _serviceCats.add(result);
          _selectedSvc.add(result);
          _moreServices = true; // Ensure newly added is visible
        } else {
          if (!_eventCats.contains(result)) _eventCats.add(result);
          _selectedEvt.add(result);
          _moreEvents = true; // Ensure newly added is visible
        }
      });
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
                children: [_step1(), _step2()],
              ),
            ),
            if (_isSubmitting)
               const Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator(color: AppColors.primary01)),
            if (!_isSubmitting)
              _BottomNav(
                step: _step,
                onNext: () {
                  if (_step == 0) {
                    if (_bizName.text.isEmpty || _country.text.isEmpty || _selectedSvc.isEmpty) {
                      AppToast.show(context, message: 'Please fill in all required fields marked with *', type: ToastType.error);
                      return;
                    }
                    _goto(1);
                  } else {
                    _submitForm();
                  }
                },
                onBack: _step > 0 ? () => _goto(_step - 1) : null,
                onSkip: null,
                onSaveDraft: _step < 1 ? _saveDraft : null,
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                const _FieldLabel('Business Name', isRequired: true),
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
                  isRequired: true,
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
                _AddCustomButton(onTap: () => _addCustomCategory(true)),
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
                _AddCustomButton(onTap: () => _addCustomCategory(false)),
              ],
            ),
          ).animate(delay: 160.ms).fadeIn(duration: 350.ms).slideY(begin: 0.12),

          const Gap(16),

          // Location card
          _Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _FieldLabel('Country', isRequired: true),
                const Gap(10),
                _Input(ctrl: _country, hint: 'Enter country'),
                const Gap(16),
                _FieldLabel('Primary Location'),
                const Gap(10),
                Stack(
                  children: [
                    _Input(
                      ctrl: _location,
                      hint: 'Type your city or district...',
                      prefix: const Icon(
                        Icons.location_on_rounded,
                        size: 18,
                        color: _kOrange,
                      ),
                    ),
                    if (_isLoadingPlaces)
                      const Positioned(
                        right: 14,
                        top: 14,
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: _kOrange),
                        ),
                      ),
                  ],
                ),
                if (_placeSuggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkNeutral02 : Colors.white,
                      border: Border.all(color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB)),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.zero,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _placeSuggestions.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: isDark ? const Color(0xFF333333) : const Color(0xFFE5E7EB)),
                      itemBuilder: (ctx, i) {
                        final s = _placeSuggestions[i];
                        return ListTile(
                          leading: const Icon(Icons.place_outlined, color: _kMuted, size: 20),
                          title: Text(s['description']!, style: const TextStyle(fontSize: 13)),
                          onTap: () => _selectPlace(s['place_id']!, s['description']!),
                        );
                      },
                    ),
                  ),
                if (_lat != null && _lng != null && _placeSuggestions.isEmpty) ...[
                  const Gap(12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      height: 120,
                      width: double.infinity,
                      child: GoogleMap(
                        key: ValueKey('${_lat!}_${_lng!}'),
                        initialCameraPosition: CameraPosition(
                          target: LatLng(_lat!, _lng!),
                          zoom: 14,
                        ),
                        liteModeEnabled: true,
                        mapToolbarEnabled: false,
                        zoomControlsEnabled: false,
                        myLocationButtonEnabled: false,
                        markers: {
                          Marker(
                            markerId: const MarkerId('vendor_loc'),
                            position: LatLng(_lat!, _lng!),
                          ),
                        },
                      ),
                    ),
                  ),
                  const Gap(16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const _FieldLabel('Service Radius'),
                      Text('${_radiusKm.toInt()} km', style: const TextStyle(fontWeight: FontWeight.bold, color: _kOrange)),
                    ],
                  ),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      activeTrackColor: _kOrange,
                      inactiveTrackColor: _kOrange.withOpacity(0.2),
                      thumbColor: _kOrange,
                      overlayColor: _kOrange.withOpacity(0.1),
                      trackHeight: 4,
                    ),
                    child: Slider(
                      value: _radiusKm,
                      min: 5,
                      max: 500,
                      divisions: 495,
                      onChanged: (val) => setState(() => _radiusKm = val),
                    ),
                  ),
                  const Text(
                    "This sets how far you're willing to travel for events.",
                    style: TextStyle(fontSize: 12, color: _kMuted),
                  ),
                ],
                if (_lat == null) ...[
                  const Gap(6),
                  const Text(
                    "We'll match you with local events.",
                    style: TextStyle(fontSize: 12, color: _kMuted),
                  ),
                ]
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
                        keyboardType: TextInputType.number,
                        prefix: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCurrency,
                              icon: const Icon(Icons.keyboard_arrow_down, size: 14, color: _kOrange),
                              items: _currencies.map((String c) {
                                return DropdownMenuItem(
                                  value: c,
                                  child: Text(c, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: _kOrange)),
                                );
                              }).toList(),
                              onChanged: (v) {
                                if (v != null) setState(() => _selectedCurrency = v);
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      flex: 3,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
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
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _selectedPriceUnit,
                            isExpanded: true,
                            icon: const Icon(Icons.arrow_drop_down, color: _kMuted),
                            dropdownColor: Theme.of(context).brightness == Brightness.dark 
                              ? AppColors.darkNeutral02 
                              : Colors.white,
                            items: _priceUnits.map((String unit) {
                              return DropdownMenuItem(
                                value: unit,
                                child: Text(unit, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _kMuted)),
                              );
                            }).toList(),
                            onChanged: (v) {
                              if (v != null) setState(() => _selectedPriceUnit = v);
                            },
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
    const labels = ['Profile Setup', 'Services'];
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
                  Flexible(
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: (done || active) ? _kOrange : Colors.grey.shade400,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
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
            label: step == 1 ? 'Submit for Review' : 'Next Step',
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
  final bool isRequired;
  const _FieldLabel(this.text, {this.isRequired = false});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.white : const Color(0xFF111827);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        if (isRequired)
          const Text(
            ' *',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _kOrange,
            ),
          ),
      ],
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
  final TextInputType? keyboardType;
  const _Input({required this.ctrl, required this.hint, this.prefix, this.keyboardType});

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
      keyboardType: keyboardType,
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
  final bool isRequired;
  final VoidCallback onToggle;
  const _CategoryHeader({
    required this.title,
    required this.expanded,
    required this.onToggle,
    this.isRequired = false,
  });

  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: _kText,
            ),
          ),
          if (isRequired)
            const Text(
              ' *',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _kOrange,
              ),
            ),
        ],
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
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: text,
                ),
              ),
            ),
            const Gap(4),
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

// ════════════════════════════════════════════════════════════════════════════════
// Location Picker Sheet
// ════════════════════════════════════════════════════════════════════════════════
class _LocationPickerSheet extends StatefulWidget {
  final double initialLat;
  final double initialLng;

  const _LocationPickerSheet({required this.initialLat, required this.initialLng});

  @override
  State<_LocationPickerSheet> createState() => _LocationPickerSheetState();
}

class _LocationPickerSheetState extends State<_LocationPickerSheet> {
  late GoogleMapController _controller;
  late LatLng _target;
  bool _isDragging = false;
  String _currentAddress = 'Move map to select location';

  @override
  void initState() {
    super.initState();
    _target = LatLng(widget.initialLat, widget.initialLng);
    _updateAddress(_target);
  }

  Future<void> _updateAddress(LatLng pos) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(pos.latitude, pos.longitude);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        if (mounted) {
          setState(() {
            _currentAddress = [p.street, p.subLocality, p.locality, p.country]
                .where((e) => e != null && e.isNotEmpty)
                .join(', ');
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _currentAddress = 'Unknown location');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkNeutral02 : Colors.white;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Pin Primary Location',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: _target,
                    zoom: 15,
                  ),
                  onMapCreated: (ctrl) => _controller = ctrl,
                  onCameraMoveStarted: () => setState(() => _isDragging = true),
                  onCameraMove: (pos) => _target = pos.target,
                  onCameraIdle: () {
                    setState(() => _isDragging = false);
                    _updateAddress(_target);
                  },
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  zoomControlsEnabled: false,
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 40),
                    child: Icon(
                      Icons.location_pin,
                      size: 40,
                      color: _isDragging ? Colors.grey : AppColors.primary01,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: bg,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                )
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.place_outlined, color: AppColors.primary01),
                      const Gap(10),
                      Expanded(
                        child: Text(
                          _currentAddress,
                          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const Gap(16),
                  ElevatedButton(
                    onPressed: _isDragging
                        ? null
                        : () {
                            Navigator.pop(context, {
                              'lat': _target.latitude,
                              'lng': _target.longitude,
                              'address': _currentAddress,
                            });
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary01,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Confirm Location', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

