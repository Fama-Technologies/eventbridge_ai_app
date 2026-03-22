import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/core/network/api_service.dart';
import 'package:eventbridge/core/storage/storage_service.dart';
import 'package:eventbridge/core/widgets/app_toast.dart';
import 'package:url_launcher/url_launcher.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String? _currentPlan;
  bool _isLoading = true;
  bool _isUpgrading = false;
  String _displayCurrency = 'USD'; // default until loaded

  // Conversion rates from USD
  static const Map<String, double> _conversionRates = {
    'USD': 1.0,
    'UGX': 3700.0,
    'KES': 133.0,
    'TZS': 2500.0,
    'RWF': 1300.0,
    'GBP': 0.79,
    'EUR': 0.92,
  };

  static const Map<String, String> _currencySymbols = {
    'USD': '\$',
    'UGX': 'UGX ',
    'KES': 'KES ',
    'TZS': 'TZS ',
    'RWF': 'RWF ',
    'GBP': '£',
    'EUR': '€',
  };

  // Format a USD price into the user's display currency
  String _formatPrice(double usdPrice) {
    if (usdPrice == 0) {
      return '${_currencySymbols[_displayCurrency] ?? ''}0';
    }
    final rate = _conversionRates[_displayCurrency] ?? 1.0;
    final symbol = _currencySymbols[_displayCurrency] ?? _displayCurrency + ' ';
    final converted = usdPrice * rate;
    // Show integers for currencies like UGX, KES etc, decimals for USD/GBP/EUR
    if (_displayCurrency == 'USD' || _displayCurrency == 'GBP' || _displayCurrency == 'EUR') {
      return '$symbol${converted.toStringAsFixed(0)}';
    }
    // Format with comma separators for large numbers
    final formatted = converted.toInt().toString().replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => ',',
    );
    return '$symbol$formatted';
  }

  @override
  void initState() {
    super.initState();
    // Load the user's preferred display currency
    final saved = StorageService().getString('display_currency');
    if (saved != null) _displayCurrency = saved;
    _loadProfile();
  }

  DateTime? _expiresAt;

  Future<void> _loadProfile() async {
    try {
      final userId = StorageService().getString('user_id');
      if (userId == null) return;

      final result = await ApiService.instance.getVendorProfile(userId);
      if (mounted && result['success'] == true) {
        final expiresRaw = result['profile']['subscriptionExpiresAt'];
        // Sync currency from vendor profile if not yet set by user
        final profileCurrency = result['profile']['currency'];
        if (profileCurrency != null && StorageService().getString('display_currency') == null) {
          await StorageService().setString('display_currency', profileCurrency);
        }
        setState(() {
          _currentPlan = result['profile']['subscriptionStatus'] ?? 'free_trial';
          _isLoading = false;
          _displayCurrency = StorageService().getString('display_currency') ?? profileCurrency ?? 'USD';
          if (expiresRaw != null) {
            _expiresAt = DateTime.tryParse(expiresRaw.toString());
          }
        });
        StorageService().setString('vendor_plan', _currentPlan!);
      }
    } catch (e) {
      debugPrint('Error loading plan: \$e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleUpgrade(String plan) async {
    setState(() => _isUpgrading = true);
    try {
      final userId = StorageService().getString('user_id');
      if (userId == null) return;

      final result = await ApiService.instance.upgradePlanPesapal(userId, plan);
      if (mounted && result['success'] == true) {
        if (result['isFree'] == true) {
          setState(() {
            _currentPlan = plan;
            _isUpgrading = false;
          });
          StorageService().setString('vendor_plan', plan);
          AppToast.show(context, message: 'Success! Your plan has been changed to $plan.', type: ToastType.success);
        } else if (result['redirectUrl'] != null) {
          setState(() => _isUpgrading = false);
          final url = Uri.parse(result['redirectUrl']);
          if (await canLaunchUrl(url)) {
            await launchUrl(url, mode: LaunchMode.externalApplication);
          } else {
            AppToast.show(context, message: 'Could not open payment link.', type: ToastType.error);
          }
        }
      } else {
        setState(() => _isUpgrading = false);
        AppToast.show(context, message: 'Upgrade failed. Please try again later.', type: ToastType.error);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUpgrading = false);
        AppToast.show(context, message: 'Upgrade failed: $e', type: ToastType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F8),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: Color(0xFF1A1A24)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Upgrade Plan',
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF1A1A24),
          ),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary01))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Column(
                children: [
                  // Expired plan warning
                  if (_expiresAt != null && _expiresAt!.isBefore(DateTime.now()))
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFECACA)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.block_rounded, color: Color(0xFFEF4444)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your subscription has expired. Features are blocked. Please upgrade to continue.',
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF991B1B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Free trial banner
                  if (_currentPlan == 'free_trial' || _currentPlan == null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFFFEDD5)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Color(0xFFF59E0B)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Free Trial Active: Enjoy premium features for a limited time.',
                              style: GoogleFonts.roboto(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 32),
                  _buildPlanCard(
                    context: context,
                    title: 'Free Starter',
                    planId: 'free',
                    price: _formatPrice(0),
                    icon: Icons.star_border_rounded,
                    features: [
                      '1 Package Listing',
                      '1 Portfolio Project',
                      'Basic Profile Listing',
                      'No Bookings Calendar',
                    ],
                    buttonLabel: (_currentPlan == 'free' || _currentPlan == 'free_trial' || _currentPlan == null) ? 'Current Plan' : 'Downgrade to Free',
                    isActive: _currentPlan == 'free' || _currentPlan == 'free_trial' || _currentPlan == null,
                    isPremium: false,
                  ),
                  const SizedBox(height: 24),
                  _buildPlanCard(
                    context: context,
                    title: 'Basic Vendor',
                    planId: 'pro',
                    price: _formatPrice(15),
                    icon: Icons.business_center_rounded,
                    features: [
                      '3 Package Listings',
                      '3 Portfolio Projects (5 images each)',
                      'Bookings Calendar',
                      'Messaging',
                    ],
                    buttonLabel: _currentPlan == 'pro' ? 'Current Plan' : 'Upgrade to Basic Vendor',
                    isActive: _currentPlan == 'pro',
                    isPremium: false,
                  ),
                  const SizedBox(height: 24),
                  _buildPlanCard(
                    context: context,
                    title: 'Premium Vendor',
                    planId: 'business_pro',
                    price: _formatPrice(30),
                    icon: Icons.military_tech_rounded,
                    features: [
                      '6 Package Listings',
                      '6 Portfolio Projects',
                      'Bookings Calendar',
                      'Messaging',
                      'Priority Search Placement',
                      'Top Recommended Badge',
                    ],
                    buttonLabel: _currentPlan == 'business_pro' ? 'Current Plan' : 'Upgrade to Premium Vendor',
                    isActive: _currentPlan == 'business_pro',
                    isPremium: true,
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
    );
  }

  Widget _buildPlanCard({
    required BuildContext context,
    required String title,
    required String planId,
    required String price,
    required IconData icon,
    required List<String> features,
    required String buttonLabel,
    required bool isActive,
    required bool isPremium,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isPremium ? const Color(0xFF1A1A24) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isPremium ? const Color(0xFF1A1A24) : const Color(0xFFE5E7EB),
        ),
        boxShadow: isPremium
            ? [
                BoxShadow(
                  color: const Color(0xFF1A1A24).withValues(alpha: 0.2),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                )
              ]
            : [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isPremium
                      ? Colors.white.withValues(alpha: 0.1)
                      : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: isPremium ? const Color(0xFFF59E0B) : const Color(0xFF4B5563),
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.roboto(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: isPremium ? Colors.white : const Color(0xFF1A1A24),
                      ),
                    ),
                    if (isActive)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1FAE5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'ACTIVE',
                          style: GoogleFonts.roboto(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF065F46),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price,
                style: GoogleFonts.roboto(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: isPremium ? Colors.white : const Color(0xFF1A1A24),
                  letterSpacing: -1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 6, left: 4),
                child: Text(
                  '/month',
                  style: GoogleFonts.roboto(
                    fontSize: 16,
                    color: isPremium
                        ? Colors.white.withValues(alpha: 0.6)
                        : const Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(color: Color(0xFFE5E7EB)),
          const SizedBox(height: 24),
          ...features.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 20,
                      color: isPremium ? const Color(0xFFF59E0B) : AppColors.primary01,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        f,
                        style: GoogleFonts.roboto(
                          fontSize: 14,
                          color: isPremium
                              ? Colors.white.withValues(alpha: 0.9)
                              : const Color(0xFF4B5563),
                        ),
                      ),
                    ),
                  ],
                ),
              )),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: (isActive || _isUpgrading)
                  ? null
                  : () => _handleUpgrade(planId),
              style: ElevatedButton.styleFrom(
                backgroundColor: isPremium
                    ? AppColors.primary01
                    : const Color(0xFFF3F4F6),
                foregroundColor: isPremium
                    ? Colors.white
                    : const Color(0xFF9CA3AF),
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: _isUpgrading && !isActive
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Text(
                      buttonLabel,
                      style: GoogleFonts.roboto(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
