import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:eventbridge/core/theme/app_colors.dart';
import 'package:eventbridge/features/matching/presentation/matching_controller.dart';
import 'package:eventbridge/features/matching/models/match_vendor.dart';

class AiResultsMapScreen extends ConsumerStatefulWidget {
  const AiResultsMapScreen({super.key});

  @override
  ConsumerState<AiResultsMapScreen> createState() => _AiResultsMapScreenState();
}

class _AiResultsMapScreenState extends ConsumerState<AiResultsMapScreen> {
  GoogleMapController? _mapController;
  LatLng _center = const LatLng(0.3476, 32.5825); // Kampala default
  Set<Marker> _markers = {};
  MatchVendor? _selectedVendor;
  bool _isLocating = true;

  @override
  void initState() {
    super.initState();
    _initMap();
  }

  Future<void> _initMap() async {
    final state = ref.read(matchingControllerProvider);
    final location = state.request?.location;

    // Try geocoding the event location
    if (location != null && location.isNotEmpty) {
      try {
        final locs = await locationFromAddress(location);
        if (locs.isNotEmpty) {
          _center = LatLng(locs.first.latitude, locs.first.longitude);
        }
      } catch (_) {
        await _fallbackToDeviceLocation();
      }
    } else {
      await _fallbackToDeviceLocation();
    }

    _buildMarkers(state.matches);

    if (mounted) {
      setState(() => _isLocating = false);
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(_center, 12));
    }
  }

  Future<void> _fallbackToDeviceLocation() async {
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
      _center = LatLng(pos.latitude, pos.longitude);
    } catch (_) {}
  }

  void _buildMarkers(List<MatchVendor> vendors) {
    final markers = <Marker>{};
    for (final v in vendors) {
      if (v.latitude == null || v.longitude == null) continue;
      markers.add(
        Marker(
          markerId: MarkerId(v.id),
          position: LatLng(v.latitude!, v.longitude!),
          infoWindow: InfoWindow(
            title: v.name,
            snippet: '${(v.matchScore * 100).toInt()}% match',
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

  void _showVendorCard(MatchVendor vendor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _VendorMapCard(
        vendor: vendor,
        onViewProfile: () {
          Navigator.pop(context);
          context.push('/vendor-public/${vendor.id}');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(matchingControllerProvider);
    final noCoords = state.matches.every((m) => m.latitude == null || m.longitude == null);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.neutrals08),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vendors Near Your Event',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.neutrals08,
              ),
            ),
            if (state.request?.location != null)
              Text(
                state.request!.location,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: AppColors.neutrals07,
                ),
              ),
          ],
        ),
      ),
      body: Stack(
        children: [
          if (_isLocating)
            const Center(child: CircularProgressIndicator(color: AppColors.primary01))
          else
            GoogleMap(
              initialCameraPosition: CameraPosition(target: _center, zoom: 12),
              onMapCreated: (controller) {
                _mapController = controller;
                _mapController?.animateCamera(
                  CameraUpdate.newLatLngZoom(_center, 12),
                );
              },
              markers: _markers,
              myLocationButtonEnabled: true,
              myLocationEnabled: true,
              zoomControlsEnabled: false,
            ),

          if (!_isLocating && noCoords)
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
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.location_off_outlined,
                        size: 48, color: AppColors.neutrals05),
                    const SizedBox(height: 12),
                    Text(
                      'Vendor locations not available yet',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.neutrals08,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Vendors need to update their location settings for pins to appear here.',
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

class _VendorMapCard extends StatelessWidget {
  final MatchVendor vendor;
  final VoidCallback onViewProfile;

  const _VendorMapCard({required this.vendor, required this.onViewProfile});

  @override
  Widget build(BuildContext context) {
    final matchPercent = (vendor.matchScore * 100).toInt();

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
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Image.network(
                  vendor.portfolio.isNotEmpty
                      ? vendor.portfolio.first
                      : 'https://via.placeholder.com/80',
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 72,
                    height: 72,
                    color: AppColors.neutrals02,
                    child: const Icon(Icons.image_not_supported_rounded,
                        color: AppColors.neutrals06),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            vendor.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.neutrals08,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.primary01.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '$matchPercent%',
                            style: GoogleFonts.outfit(
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary01,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      vendor.services.take(3).join(' • '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: AppColors.neutrals07,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.star_rounded,
                            color: AppColors.warningAmber, size: 14),
                        const SizedBox(width: 3),
                        Text(
                          vendor.rating.toStringAsFixed(1),
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.neutrals08,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.location_on_outlined,
                            size: 13, color: AppColors.neutrals06),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            vendor.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: AppColors.neutrals07,
                            ),
                          ),
                        ),
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
