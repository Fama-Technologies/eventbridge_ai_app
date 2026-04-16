import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge/core/network/api_service.dart';
import 'package:eventbridge/core/storage/storage_service.dart';
import 'package:eventbridge/core/widgets/app_toast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:eventbridge/core/services/upload_service.dart';
import 'package:eventbridge/core/theme/app_colors.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:gap/gap.dart';
import 'models/service_taxonomy_model.dart';

const _kMapsApiKey = "AIzaSyBh-GVHVYhZ7irbZ5o8QAyzpZPsXuNUwLM";

class VendorProfileSettingsScreen extends StatefulWidget {
  const VendorProfileSettingsScreen({super.key});

  @override
  State<VendorProfileSettingsScreen> createState() =>
      _VendorProfileSettingsScreenState();
}

class _VendorProfileSettingsScreenState
    extends State<VendorProfileSettingsScreen> {
  bool _isLoading = true;
  double _travelRadius = 50.0;
  String _vendorPlan = 'Basic'; // Use Basic as default

  final List<dynamic> _portfolioImages = [];

  int get _maxImages {
    final plan = _vendorPlan.toLowerCase();
    if (plan.contains('pro_max') || plan.contains('pro max')) return 30;
    if (plan.contains('pro')) return 20;
    return 12; // Default for Basic/Free
  }

  final _businessNameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  String _location = 'Location not provided';

  final _instaCtrl = TextEditingController(text: '@your_insta');
  final _tiktokCtrl = TextEditingController(text: '@your_tiktok');
  final _fbCtrl = TextEditingController(text: 'Your Facebook');
  final _webCtrl = TextEditingController(text: 'www.yourwebsite.com');

  List<String> _serviceCategories = [];
  List<String> _eventCategories = [];
  List<ServiceItem> _taxonomy = [];
  bool _isLoadingTaxonomy = true;

  double? _lat;
  double? _lng;

  final _countryCtrl = TextEditingController();
  final _expCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  String _currency = 'UGX';
  String _priceUnit = 'Per Event';

  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 22, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadProfileData();
    _fetchTaxonomy();
  }

  Future<void> _fetchTaxonomy() async {
    try {
      final items = await ApiService.instance.getServicesTaxonomy();
      if (mounted) {
        setState(() {
          _taxonomy = items;
          _isLoadingTaxonomy = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching taxonomy: $e');
      if (mounted) setState(() => _isLoadingTaxonomy = false);
    }
  }

  Future<void> _loadProfileData() async {
    try {
      final userId = StorageService().getString('user_id');
      if (userId == null) {
        throw Exception('User ID not found');
      }

      final result = await ApiService.instance.getVendorProfile(userId);
      if (result['success'] == true && result['profile'] != null) {
        final profile = result['profile'];
        setState(() {
          _vendorPlan = profile['subscriptionPlan'] ?? 'Basic';
          _businessNameCtrl.text = profile['businessName'] ?? '';
          _descriptionCtrl.text = profile['description'] ?? '';
          _location = profile['location'] ?? 'Location not provided';
          _locationCtrl.text = _location == 'Location not provided'
              ? ''
              : _location;
          _serviceCategories = List<String>.from(
            profile['serviceCategories'] ?? [],
          ).toSet().toList();
          _eventCategories = List<String>.from(
            profile['eventCategories'] ?? [],
          ).toSet().toList();
          _priceCtrl.text = profile['price']?.toString() ?? '';
          _countryCtrl.text = profile['country'] ?? '';
          _expCtrl.text = profile['experience']?.toString() ?? '';
          _currency = profile['currency'] ?? 'UGX';
          _priceUnit = profile['priceUnit'] ?? 'Per Event';
          _webCtrl.text = profile['websiteUrl'] ?? profile['website'] ?? '';
          _instaCtrl.text = profile['instagramHandle'] ?? '';
          _tiktokCtrl.text = profile['tiktokHandle'] ?? '';
          _fbCtrl.text = profile['facebookHandle'] ?? '';
          _travelRadius =
              double.tryParse(profile['travelRadius']?.toString() ?? '50.0') ??
              50.0;
          final latData = profile['latitude'];
          final lngData = profile['longitude'];
          _lat = latData != null ? double.tryParse(latData.toString()) : null;
          _lng = lngData != null ? double.tryParse(lngData.toString()) : null;

          if (profile['galleryUrls'] != null) {
            _portfolioImages.clear();
            for (var item in profile['galleryUrls']) {
              _portfolioImages.add(_getDisplayUrl(item));
            }
          }

          if (profile['workingHours'] != null) {
            try {
              final wh = profile['workingHours'];
              String? startStr = wh['startTime'] ?? wh['start'];
              String? endStr = wh['endTime'] ?? wh['end'];
              
              if (startStr != null) {
                final parts = startStr.split(':');
                _startTime = TimeOfDay(
                  hour: int.parse(parts[0]),
                  minute: int.parse(parts[1]),
                );
              }
              if (endStr != null) {
                final parts = endStr.split(':');
                _endTime = TimeOfDay(
                  hour: int.parse(parts[0]),
                  minute: int.parse(parts[1]),
                );
              }
            } catch (e) {
              debugPrint('Error parsing working hours: $e');
            }
          }
        });
      }
    } catch (e) {
      debugPrint('Error loading profile data: $e');
      if (mounted) {
        AppToast.show(
          context,
          message: 'Failed to load profile details: $e',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveChanges() async {
    try {
      setState(() => _isLoading = true);

      final userId = StorageService().getString('user_id');

      if (userId == null) return;

      if (_priceCtrl.text.trim().isEmpty || _priceCtrl.text.trim() == '0') {
        AppToast.show(
          context,
          message: 'Base price is required for your profile.',
          type: ToastType.error,
        );
        return;
      }

      final result = await ApiService.instance.submitVendorOnboarding(
        userId: userId,
        businessName: _businessNameCtrl.text,
        description: _descriptionCtrl.text,
        experience: _expCtrl.text,
        location: _locationCtrl.text,
        country: _countryCtrl.text,
        categories: _serviceCategories.toSet().toList(),
        services: _eventCategories.toSet().toList(),
        price: _priceCtrl.text,
        currency: _currency,
        priceUnit: _priceUnit,
        galleryUrls: _portfolioImages.map((e) => e.toString()).toSet().toList(),
        website: _webCtrl.text,
        instagram: _instaCtrl.text,
        tiktok: _tiktokCtrl.text,
        facebook: _fbCtrl.text,
        travelRadius: _travelRadius.toInt(),
        latitude: _lat,
        longitude: _lng,
        workingHours: {
          'startTime':
              '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
          'endTime':
              '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
        },
      );

      if (mounted) {
        if (result['success'] == true) {
          AppToast.show(
            context,
            message: 'Profile updated successfully!',
            type: ToastType.success,
          );
          // Reload to be safe
          _loadProfileData();
        } else {
          AppToast.show(
            context,
            message: result['message'] ?? 'Failed to update profile',
            type: ToastType.error,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(
          context,
          message: 'An error occurred during save',
          type: ToastType.error,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() => _isLoading = true);
      try {
        final bytes = await image.readAsBytes();
        final fileName =
            'portfolio_${DateTime.now().millisecondsSinceEpoch}.jpg';

        final url = await UploadService.instance.uploadFile(
          bytes: bytes,
          fileName: fileName,
          contentType: 'image/jpeg',
          folder: 'portfolio',
        );

        setState(() {
          _portfolioImages.add(url);
        });

        // Auto-save the profile with the new image
        await _saveChanges();
      } catch (e) {
        if (mounted) {
          AppToast.show(
            context,
            message: 'Upload failed: $e',
            type: ToastType.error,
          );
        }
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _businessNameCtrl.dispose();
    _descriptionCtrl.dispose();
    _locationCtrl.dispose();
    _countryCtrl.dispose();
    _expCtrl.dispose();
    _priceCtrl.dispose();
    _instaCtrl.dispose();
    _tiktokCtrl.dispose();
    _fbCtrl.dispose();
    _webCtrl.dispose();
    super.dispose();
  }

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
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary01),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 30,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _ProfileSectionHeader(
                          icon: Icons.store_rounded,
                          title: 'Business Identity',
                        ),
                        const SizedBox(height: 24),
                        _buildPremiumTextField(
                          label: 'Business Name',
                          controller: _businessNameCtrl,
                        ),
                        const SizedBox(height: 24),
                        _buildPremiumTextField(
                          label: 'Business Description',
                          initialValue: '',
                          controller: _descriptionCtrl,
                          maxLines: 4,
                        ),
                        const SizedBox(height: 24),
                        _buildPremiumTextField(
                          label: 'Years of Experience',
                          controller: _expCtrl,
                          icon: Icons.work_history_rounded,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  _ProfileSectionHeader(
                    icon: Icons.auto_awesome_rounded,
                    title: 'Business Categories',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select the categories that best describe your business specialization (e.g. Photography, Venues).',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _TagWrap(
                    tags: _serviceCategories,
                    onAdd: () => _showTaxonomyPicker(),
                  ),
                  const SizedBox(height: 40),
                  _ProfileSectionHeader(
                    icon: Icons.celebration_rounded,
                    title: 'Service Capabilities',
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select the specific capabilities you offer (e.g. DJ, Sound, Decor).',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _TagWrap(
                    tags: _eventCategories,
                    onAdd: () => _showTaxonomyPicker(),
                  ),
                  const SizedBox(height: 40),
                  _ProfileSectionHeader(
                    icon: Icons.image_rounded,
                    title: 'Portfolio Gallery',
                    trailing: '${_portfolioImages.length} / $_maxImages',
                    onActionTap: () => context.push('/vendor-portfolio'),
                    actionLabel: 'View Live',
                  ),
                  const SizedBox(height: 20),
                  _PortfolioGrid(
                    images: _portfolioImages,
                    maxImages: _maxImages,
                    onAdd: _pickAndUploadImage,
                    onRemove: (index) {
                      setState(() => _portfolioImages.removeAt(index));
                      _saveChanges();
                    },
                  ),
                  const SizedBox(height: 40),
                  _ProfileSectionHeader(
                    icon: Icons.link_rounded,
                    title: 'Digital Presence',
                  ),
                  const SizedBox(height: 20),
                  _buildPremiumTextField(
                    label: 'Instagram',
                    controller: _instaCtrl,
                    icon: Icons.camera_alt_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildPremiumTextField(
                    label: 'TikTok',
                    controller: _tiktokCtrl,
                    icon: Icons.music_note_outlined,
                  ),
                  const SizedBox(height: 16),
                  _buildPremiumTextField(
                    label: 'Website',
                    controller: _webCtrl,
                    icon: Icons.language_rounded,
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildPremiumTextField(
                          label: 'Country',
                          controller: _countryCtrl,
                          icon: Icons.flag_rounded,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: _buildPremiumTextField(
                          label: 'City/District Location',
                          controller: _locationCtrl,
                          icon: Icons.location_on_rounded,
                          readOnly: true,
                          onTap: _showLocationPicker,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ServiceAreaCard(
                    radius: _travelRadius,
                    onChanged: (val) => setState(() => _travelRadius = val),
                  ),
                  const SizedBox(height: 40),
                  _ProfileSectionHeader(
                    icon: Icons.payments_rounded,
                    title: 'Pricing & Currency',
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildPremiumDropdown(
                          label: 'Currency',
                          value: _currency,
                          items: const [
                            'UGX',
                            'USD',
                            'KES',
                            'TZS',
                            'RWF',
                            'GBP',
                            'EUR',
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _currency = val);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: 3,
                        child: _buildPremiumTextField(
                          label: 'Starting Price',
                          controller: _priceCtrl,
                          icon: Icons.attach_money_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildPremiumDropdown(
                    label: 'Price Unit',
                    value: _priceUnit,
                    items: const [
                      'Per Event',
                      'Per Plate',
                      'Per Hour',
                      'Per Day',
                      'Per Session',
                      'Flat Rate',
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => _priceUnit = val);
                    },
                  ),
                  const SizedBox(height: 40),
                  _ProfileSectionHeader(
                    icon: Icons.calendar_month_rounded,
                    title: 'Availability Window',
                  ),
                  const SizedBox(height: 20),
                  _AvailabilityCard(
                    startTime: _startTime,
                    endTime: _endTime,
                    onStartTimeTap: () => _pickTime(true),
                    onEndTimeTap: () => _pickTime(false),
                  ),
                  const SizedBox(height: 48),
                  _buildPremiumSaveButton(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildPremiumTextField({
    required String label,
    String? initialValue,
    int maxLines = 1,
    TextEditingController? controller,
    IconData? icon,
    bool readOnly = false,
    VoidCallback? onTap,
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
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          ),
          child: TextField(
            readOnly: readOnly,
            onTap: onTap,
            maxLines: maxLines,
            controller:
                controller ?? TextEditingController(text: initialValue ?? ''),
            style: GoogleFonts.roboto(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1E293B),
            ),
            decoration: InputDecoration(
              prefixIcon: icon != null
                  ? Icon(icon, color: AppColors.primary01, size: 20)
                  : null,
              contentPadding: const EdgeInsets.all(20),
              border: InputBorder.none,
              hintText: 'Enter $label...',
              hintStyle: GoogleFonts.roboto(color: const Color(0xFF94A3B8)),
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
                  text: _location,
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
        onPressed: _saveChanges,
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

  Widget _buildPremiumDropdown({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
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
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(color: const Color(0xFFE2E8F0), width: 1.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              icon: const Icon(
                Icons.arrow_drop_down_rounded,
                color: AppColors.primary01,
              ),
              style: GoogleFonts.roboto(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1E293B),
              ),
              items: items
                  .map(
                    (item) => DropdownMenuItem(value: item, child: Text(item)),
                  )
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showTaxonomyPicker() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cats = _taxonomy.map((e) => e.categoryName).toSet().toList();
    String? selectedTopCat;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Gap(24),
              Text(
                'Add Specialized Services',
                style: GoogleFonts.roboto(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Gap(8),
              Text(
                'Select a category to see specific services.',
                style: GoogleFonts.roboto(color: Colors.grey, fontSize: 14),
              ),
              const Gap(20),
              if (selectedTopCat == null)
                Expanded(
                  child: ListView.builder(
                    itemCount: cats.length,
                    itemBuilder: (ctx, i) => ListTile(
                      title: Text(cats[i]),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () => setModalState(() => selectedTopCat = cats[i]),
                    ),
                  ),
                )
              else ...[
                TextButton.icon(
                  onPressed: () => setModalState(() => selectedTopCat = null),
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Back to Categories'),
                ),
                const Gap(10),
                Expanded(
                  child: ListView(
                    children: _taxonomy
                        .where((e) => e.categoryName == selectedTopCat)
                        .map((svc) {
                      final isSelected = _serviceCategories.contains(svc.name) || 
                                         _eventCategories.contains(svc.name);
                      return CheckboxListTile(
                        title: Text(svc.name),
                        value: isSelected,
                        activeColor: AppColors.primary01,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _serviceCategories.add(svc.name);
                              if (!_serviceCategories.contains(svc.categoryName)) {
                                _serviceCategories.add(svc.categoryName);
                              }
                            } else {
                              _serviceCategories.remove(svc.name);
                            }
                          });
                          setModalState(() {});
                        },
                      );
                    }).toList(),
                  ),
                ),
              ],
              const Gap(20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    _saveChanges();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary01,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text('Confirm & Save'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showLocationPicker() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted)
        AppToast.show(
          context,
          message: 'Location services are disabled.',
          type: ToastType.error,
        );
      return;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted)
          AppToast.show(
            context,
            message: 'Location permissions are denied.',
            type: ToastType.error,
          );
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted)
        AppToast.show(
          context,
          message: 'Location permissions are permanently denied.',
          type: ToastType.error,
        );
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
        initialLat: _lat ?? currentPos?.latitude ?? 0.3476,
        initialLng: _lng ?? currentPos?.longitude ?? 32.5825,
      ),
    );

    if (result != null && mounted) {
      setState(() {
        _lat = result['lat'];
        _lng = result['lng'];
        _locationCtrl.text = result['address'];
      });
      _saveChanges();
    }
  }

  Future<void> _pickTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }
}

class _ProfileSectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final String? actionLabel;
  final VoidCallback? onTrailingPressed;
  final VoidCallback? onActionTap;

  const _ProfileSectionHeader({
    required this.icon,
    required this.title,
    this.trailing,
    this.actionLabel,
    this.onTrailingPressed,
    this.onActionTap,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.roboto(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                if (trailing != null)
                  Text(
                    trailing!,
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF94A3B8),
                    ),
                  ),
              ],
            ),
          ),
          if (actionLabel != null)
            TextButton(
              onPressed: onActionTap,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary01,
                backgroundColor: AppColors.primary01.withOpacity(0.1),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 4,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                actionLabel!,
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TagWrap extends StatelessWidget {
  final List<String> tags;
  final VoidCallback? onAdd;
  const _TagWrap({required this.tags, this.onAdd});

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return Wrap(children: [_buildActionTag('+ Add Tag', onAdd)]);
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ...tags.map((tag) => _buildAnimatedTag(tag, isSelected: true)),
        _buildActionTag('+ Add Tag', onAdd),
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

  Widget _buildActionTag(String label, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
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
      ),
    );
  }
}

class _PortfolioGrid extends StatelessWidget {
  final List<dynamic> images;
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
        itemCount: images.length < maxImages
            ? images.length + 1
            : images.length,
        itemBuilder: (context, index) {
          if (index == images.length) {
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: _buildAddMoreCard(),
            );
          }
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildImageCard(_getDisplayUrl(images[index]), index),
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
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 14,
              ),
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

class _AvailabilityCard extends StatelessWidget {
  final TimeOfDay startTime;
  final TimeOfDay endTime;
  final VoidCallback onStartTimeTap;
  final VoidCallback onEndTimeTap;

  const _AvailabilityCard({
    required this.startTime,
    required this.endTime,
    required this.onStartTimeTap,
    required this.onEndTimeTap,
  });

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
          _buildTimeRow(
            context,
            'Morning Start',
            startTime,
            onStartTimeTap,
            Icons.wb_sunny_rounded,
            const Color(0xFFF97316),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Divider(color: Color(0xFFF1F5F9), thickness: 1),
          ),
          _buildTimeRow(
            context,
            'Evening End',
            endTime,
            onEndTimeTap,
            Icons.nightlight_round,
            const Color(0xFF6366F1),
          ),
        ],
      ),
    );
  }

  Widget _buildTimeRow(
    BuildContext context,
    String label,
    TimeOfDay time,
    VoidCallback onTap,
    IconData icon,
    Color color,
  ) {
    final String timeStr =
        '${time.hourOfPeriod}:${time.minute.toString().padLeft(2, '0')} ${time.period == DayPeriod.am ? 'AM' : 'PM'}';

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timeStr,
                style: GoogleFonts.roboto(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFFF97316),
            backgroundColor: const Color(0xFFFFF7ED),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: Text(
            'Change',
            style: GoogleFonts.roboto(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }
}

class _LocationPickerSheet extends StatefulWidget {
  final double initialLat;
  final double initialLng;

  const _LocationPickerSheet({
    required this.initialLat,
    required this.initialLng,
  });

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
      List<Placemark> placemarks = await placemarkFromCoordinates(
        pos.latitude,
        pos.longitude,
      );
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        if (mounted) {
          setState(() {
            _currentAddress = [
              p.street,
              p.subLocality,
              p.locality,
              p.country,
            ].where((e) => e != null && e.isNotEmpty).join(', ');
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
                ),
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
                ),
              ],
            ),
            child: SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        color: AppColors.primary01,
                      ),
                      const Gap(10),
                      Expanded(
                        child: Text(
                          _currentAddress,
                          style: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
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
                    child: const Text(
                      'Confirm Location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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

String _getDisplayUrl(dynamic item) {
  if (item == null) return '';
  if (item is String) {
    if (item.startsWith('{') && item.endsWith('}')) {
      try {
        final decoded = json.decode(item);
        return _getDisplayUrl(decoded);
      } catch (_) {
        return item;
      }
    }
    return item;
  }
  if (item is Map) {
    final urlValue = item['url'];
    if (urlValue != null) {
      return _getDisplayUrl(urlValue);
    }
  }
  return item.toString();
}
