import 'dart:async';
// 'FontFeature' is available through Flutter's material exports.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../constants/app_colors.dart';
import '../constants/map_styles.dart';

class MapSearchScreen extends StatefulWidget {
  const MapSearchScreen({super.key, this.currentLocation});

  final LatLng? currentLocation;

  @override
  State<MapSearchScreen> createState() => _MapSearchScreenState();
}

class _MapSearchScreenState extends State<MapSearchScreen> {
  static const LatLng _fallbackLocation = LatLng(10.7828, 79.1318);

  final TextEditingController _searchController = TextEditingController();
  final Completer<GoogleMapController> _mapController = Completer();

  LatLng? _pinnedLocation;
  String? _pinnedPlaceName;

  LatLng get _initialLocation => widget.currentLocation ?? _fallbackLocation;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Map style is provided via the `style` property on `GoogleMap`.
  // Complete the controller when the map is created.

  Future<void> _pinLocation(LatLng position, {String? name}) async {
    setState(() {
      _pinnedLocation = position;
      _pinnedPlaceName = (name?.trim().isNotEmpty ?? false)
          ? name!.trim()
          : 'Selected Location';
    });
  }

  Future<void> _submitSearch(String query) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return;
    }

    try {
      final controller = await _mapController.future;
      final bounds = await controller.getVisibleRegion();
      final center = LatLng(
        (bounds.northeast.latitude + bounds.southwest.latitude) / 2,
        (bounds.northeast.longitude + bounds.southwest.longitude) / 2,
      );

      await _pinLocation(center, name: trimmedQuery);
      await controller.animateCamera(CameraUpdate.newLatLngZoom(center, 15));
    } catch (_) {
      await _pinLocation(_initialLocation, name: trimmedQuery);
    }
  }

  Future<void> _recenterToCurrentLocation() async {
    try {
      final controller = await _mapController.future;
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(_initialLocation, 14),
      );
    } catch (_) {
      // No-op: the control should never crash the search screen.
    }
  }

  void _lockDestination() {
    final pinnedLocation = _pinnedLocation;
    if (pinnedLocation == null) {
      return;
    }

    Navigator.pop(context, {
      'name': _pinnedPlaceName ?? 'Selected Location',
      'lat': pinnedLocation.latitude,
      'lng': pinnedLocation.longitude,
    });
  }

  @override
  Widget build(BuildContext context) {
    final pinnedLocation = _pinnedLocation;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _initialLocation,
              zoom: 13,
            ),
            myLocationEnabled: widget.currentLocation != null,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            style: darkMapStyle,
            onMapCreated: (controller) {
              if (!_mapController.isCompleted) {
                _mapController.complete(controller);
              }
            },
            onTap: (position) => _pinLocation(position),
            markers: {
              if (pinnedLocation != null)
                Marker(
                  markerId: const MarkerId('pinned_destination'),
                  position: pinnedLocation,
                  icon: BitmapDescriptor.defaultMarkerWithHue(45),
                  infoWindow: InfoWindow(
                    title: _pinnedPlaceName ?? 'Selected Location',
                  ),
                ),
            },
          ),
          Positioned(
            top: 50,
            left: 16,
            right: 16,
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.navBorder),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  const Icon(
                    Icons.search_rounded,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      cursorColor: AppColors.gold,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppColors.text,
                        fontFeatures: const [FontFeature.enable('kern')],
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search for a place...',
                        hintStyle: GoogleFonts.inter(
                          color: AppColors.secondary,
                          fontSize: 14,
                          fontFeatures: const [FontFeature.enable('kern')],
                        ),
                        border: InputBorder.none,
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: _submitSearch,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 36,
                      height: 36,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.statCard,
                      ),
                      child: const Icon(
                        Icons.close_rounded,
                        color: AppColors.text,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: pinnedLocation == null ? 32 : 140,
            right: 16,
            child: GestureDetector(
              onTap: _recenterToCurrentLocation,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.card,
                  border: Border.all(color: AppColors.navBorder),
                ),
                child: const Icon(
                  Icons.my_location_rounded,
                  color: AppColors.gold,
                  size: 22,
                ),
              ),
            ),
          ),
          if (pinnedLocation != null)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SafeArea(
                top: false,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                    border: Border(top: BorderSide(color: AppColors.navBorder)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on_rounded,
                            color: AppColors.gold,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _pinnedPlaceName ?? 'Selected Location',
                              softWrap: true,
                              overflow: TextOverflow.visible,
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.text,
                                fontFeatures: const [
                                  FontFeature.enable('kern'),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${pinnedLocation.latitude.toStringAsFixed(4)}, '
                            '${pinnedLocation.longitude.toStringAsFixed(4)}',
                            softWrap: true,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              color: AppColors.secondary,
                              fontFeatures: const [FontFeature.enable('kern')],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _lockDestination,
                        child: Container(
                          width: double.infinity,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppColors.gold, AppColors.goldDark],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.gold.withValues(alpha: 0.3),
                                blurRadius: 16,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.lock_rounded,
                                color: AppColors.background,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Lock This Destination',
                                softWrap: true,
                                overflow: TextOverflow.visible,
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.background,
                                  fontFeatures: const [
                                    FontFeature.enable('kern'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
