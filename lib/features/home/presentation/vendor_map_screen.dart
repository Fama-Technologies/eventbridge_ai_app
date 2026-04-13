import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/core/network/api_service.dart';

class VendorMapScreen extends StatefulWidget {
  final double initialLat;
  final double initialLng;

  const VendorMapScreen({
    super.key,
    required this.initialLat,
    required this.initialLng,
  });

  @override
  State<VendorMapScreen> createState() => _VendorMapScreenState();
}

class _VendorMapScreenState extends State<VendorMapScreen> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  List<Map<String, dynamic>> _vendors = [];
  Map<String, dynamic>? _selectedVendor;
  bool _isLoading = true;
  String? _error;

  late LatLng _center;

  @override
  void initState() {
    super.initState();
    _center = LatLng(widget.initialLat, widget.initialLng);
    _loadNearbyVendors();
  }

  Future<void> _loadNearbyVendors() async {
    try {
      final data = await ApiService().getNearbyVendors(
        lat: _center.latitude,
        lng: _center.longitude,
      );
      final vendors = List<Map<String, dynamic>>.from(data['vendors'] ?? []);
      _vendors = vendors;
      _buildMarkers(vendors);
    } catch (e) {
      if (mounted) setState(() => _error = 'Could not load nearby vendors.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _buildMarkers(List<Map<String, dynamic>> vendors) {
    final markers = <Marker>{};
    for (final v in vendors) {
      final lat = v['latitude'];
      final lng = v['longitude'];
      if (lat == null || lng == null) continue;
      markers.add(
        Marker(
          markerId: MarkerId(v['id'].toString()),
          position: LatLng((lat as num).toDouble(), (lng as num).toDouble()),
          infoWindow: InfoWindow(
            title: v['businessName'] ?? '',
            snippet: v['distanceKm'] != null ? '${v['distanceKm']} km away' : null,
          ),
          onTap: () {
            setState(() => _selectedVendor = v);
            _showVendorCard(v);
          },
        ),
      );
    }
    setState(() => _markers = markers);
  }

  void _showVendorCard(Map<String, dynamic> vendor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _NearbyVendorCard(
        vendor: vendor,
        onViewProfile: () {
          Navigator.pop(context);
          context.push('/vendor-public/${vendor['id']}');
        },
      ),
    );
  }

  Future<void> _goToMyLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return;
      }
      if (permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition();
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(LatLng(pos.latitude, pos.longitude), 13),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.neutrals08),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Vendors Near You',
          style: GoogleFonts.outfit(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.neutrals08,
          ),
        ),
        actions: [
          if (!_isLoading && _vendors.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.primary01.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(100),
                  ),
                  child: Text(
                    '${_vendors.length} found',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary01,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: _center, zoom: 12),
            onMapCreated: (controller) {
              _mapController = controller;
            },
            markers: _markers,
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
          ),

          if (_isLoading)
            Container(
              color: Colors.white.withOpacity(0.7),
              child: const Center(
                child: CircularProgressIndicator(color: AppColors.primary01),
              ),
            ),

          if (!_isLoading && _error != null)
            Center(
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wifi_off_rounded,
                        size: 48, color: AppColors.neutrals05),
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: AppColors.neutrals07,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _error = null;
                          _isLoading = true;
                        });
                        _loadNearbyVendors();
                      },
                      child: Text(
                        'Retry',
                        style: GoogleFonts.outfit(
                          color: AppColors.primary01,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          if (!_isLoading && _error == null && _vendors.isEmpty)
            Center(
              child: Container(
                margin: const EdgeInsets.all(32),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.store_mall_directory_outlined,
                        size: 48, color: AppColors.neutrals05),
                    const SizedBox(height: 12),
                    Text(
                      'No vendors found nearby',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.neutrals08,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Try expanding the search radius or browse all vendors.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color: AppColors.neutrals07,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          Positioned(
            bottom: 24,
            right: 16,
            child: FloatingActionButton(
              onPressed: _goToMyLocation,
              backgroundColor: Colors.white,
              elevation: 4,
              mini: true,
              child: const Icon(Icons.my_location_rounded,
                  color: AppColors.primary01),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

class _NearbyVendorCard extends StatelessWidget {
  final Map<String, dynamic> vendor;
  final VoidCallback onViewProfile;

  const _NearbyVendorCard({required this.vendor, required this.onViewProfile});

  @override
  Widget build(BuildContext context) {
    final rating = (vendor['rating'] as num?)?.toDouble() ?? 0.0;
    final categories = (vendor['serviceCategories'] as List?)?.cast<String>() ?? [];
    final distance = vendor['distanceKm']?.toString();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 32),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
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
                color: AppColors.neutrals03,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.neutrals02,
                backgroundImage: vendor['avatarUrl'] != null
                    ? NetworkImage(vendor['avatarUrl'])
                    : null,
                child: vendor['avatarUrl'] == null
                    ? const Icon(Icons.store_rounded,
                        color: AppColors.neutrals06)
                    : null,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendor['businessName'] ?? 'Unknown',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.neutrals08,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (categories.isNotEmpty)
                      Text(
                        categories.take(3).join(' • '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: AppColors.neutrals07,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: AppColors.warningAmber, size: 14),
                        const SizedBox(width: 3),
                        Text(
                          rating.toStringAsFixed(1),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.neutrals08,
                          ),
                        ),
                        if (distance != null) ...[
                          const SizedBox(width: 10),
                          const Icon(Icons.near_me_rounded,
                              size: 13, color: AppColors.neutrals06),
                          const SizedBox(width: 2),
                          Text(
                            '$distance km away',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppColors.neutrals07,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onViewProfile,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary01,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              child: Text(
                'View Profile',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
