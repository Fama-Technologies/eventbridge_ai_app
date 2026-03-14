import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge_ai/core/network/api_service.dart';
import 'package:eventbridge_ai/core/storage/storage_service.dart';
import 'package:eventbridge_ai/core/widgets/app_toast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:eventbridge_ai/core/services/upload_service.dart';
import 'package:eventbridge_ai/core/theme/app_colors.dart';

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
  final String _vendorPlan = 'business_pro';

  final List<String> _portfolioImages = [];

  int get _maxImages => _vendorPlan == 'business_pro' ? 20 : 12;

  final _businessNameCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  String _location = 'Location not provided';

  final _instaCtrl = TextEditingController(text: '@your_insta');
  final _tiktokCtrl = TextEditingController(text: '@your_tiktok');
  final _fbCtrl = TextEditingController(text: 'Your Facebook');
  final _webCtrl = TextEditingController(text: 'www.yourwebsite.com');

  List<String> _serviceCategories = [];
  String _price = '';

  TimeOfDay _startTime = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 22, minute: 0);

  @override
  void initState() {
    super.initState();
    _loadProfileData();
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
          _businessNameCtrl.text = profile['businessName'] ?? '';
          _descriptionCtrl.text = profile['description'] ?? '';
          _location = profile['location'] ?? 'Location not provided';
          _locationCtrl.text = _location == 'Location not provided' ? '' : _location;
          _serviceCategories = List<String>.from(profile['serviceCategories'] ?? []).toSet().toList();
          _price = profile['price'] ?? '';
          _webCtrl.text = profile['website'] ?? '';
          _travelRadius = (profile['travelRadius'] ?? 50.0).toDouble();

          if (profile['galleryUrls'] != null) {
             _portfolioImages.clear();
             _portfolioImages.addAll(List<String>.from(profile['galleryUrls']));
          } 


          if (profile['workingHours'] != null) {
            try {
              final wh = profile['workingHours'];
              if (wh['start'] != null) {
                final parts = wh['start'].split(':');
                _startTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
              }
              if (wh['end'] != null) {
                final parts = wh['end'].split(':');
                _endTime = TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
              }
            } catch (e) {
              debugPrint('Error parsing working hours: $e');
            }
          }
        });
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, message: 'Failed to load profile details', type: ToastType.error);
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

      final result = await ApiService.instance.submitVendorOnboarding(
        userId: userId,
        businessName: _businessNameCtrl.text,
        description: _descriptionCtrl.text,
        experience: '5', 
        location: _locationCtrl.text,
        serviceCategories: _serviceCategories.toSet().toList(),
        price: _price,
        galleryUrls: _portfolioImages.toSet().toList(),
        website: _webCtrl.text,
        travelRadius: _travelRadius.toInt(),
        workingHours: {
          'start': '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}',
          'end': '${_endTime.hour.toString().padLeft(2, '0')}:${_endTime.minute.toString().padLeft(2, '0')}',
        },
      );

      if (mounted) {
        if (result['success'] == true) {
          AppToast.show(context, message: 'Profile updated successfully!', type: ToastType.success);
          // Reload to be safe
          _loadProfileData();
        } else {
          AppToast.show(context, message: result['message'] ?? 'Failed to update profile', type: ToastType.error);
        }
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, message: 'An error occurred during save', type: ToastType.error);
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
        final fileName = 'portfolio_${DateTime.now().millisecondsSinceEpoch}.jpg';
        
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
          AppToast.show(context, message: 'Upload failed: $e', type: ToastType.error);
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
        ? const Center(child: CircularProgressIndicator(color: AppColors.primary01))
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
                ],
              ),
            ),
            const SizedBox(height: 32),
            _ProfileSectionHeader(
              icon: Icons.auto_awesome_rounded,
              title: 'Service Categories',
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
            const SizedBox(height: 20),
            _TagWrap(tags: _serviceCategories),
            const SizedBox(height: 40),
            _ProfileSectionHeader(
              icon: Icons.image_rounded,
              title: 'Portfolio Gallery',
              trailing: '${_portfolioImages.length} / $_maxImages',
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
            _buildPremiumTextField(label: 'Instagram', controller: _instaCtrl, icon: Icons.camera_alt_outlined),
            const SizedBox(height: 16),
            _buildPremiumTextField(label: 'TikTok', controller: _tiktokCtrl, icon: Icons.music_note_outlined),
            const SizedBox(height: 16),
            _buildPremiumTextField(label: 'Website', controller: _webCtrl, icon: Icons.language_rounded),
            const SizedBox(height: 24),
            _buildPremiumTextField(label: 'Business Location', controller: _locationCtrl, icon: Icons.location_on_rounded),
            const SizedBox(height: 40),
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
            maxLines: maxLines,
            controller: controller ?? TextEditingController(text: initialValue ?? ''),
            style: GoogleFonts.roboto(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: const Color(0xFF1E293B),
            ),
            decoration: InputDecoration(
              prefixIcon: icon != null ? Icon(icon, color: AppColors.primary01, size: 20) : null,
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
  final List<String> tags;
  const _TagWrap({required this.tags});

  @override
  Widget build(BuildContext context) {
    if (tags.isEmpty) {
      return const SizedBox();
    }

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ...tags.map((tag) => _buildAnimatedTag(tag, isSelected: true)),
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
    final String timeStr = '${time.hourOfPeriod}:${time.minute.toString().padLeft(2, '0')} ${time.period == DayPeriod.am ? 'AM' : 'PM'}';

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



