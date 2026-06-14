import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../constants/app_colors.dart';
import '../constants/map_styles.dart';

class MapSearchScreen extends StatefulWidget {
  const MapSearchScreen({super.key});

  @override
  State<MapSearchScreen> createState() => _MapSearchScreenState();
}

class _MapSearchScreenState extends State<MapSearchScreen> {
  LatLng? _pinnedLocation;
  String? _pinnedPlaceName;
  final TextEditingController _searchController = TextEditingController();
  GoogleMapController? _mapController;
  LatLng _fallback = const LatLng(10.7828, 79.1318);

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<LatLng> _getInitialCamera() async {
    try {
      final status = await Geolocator.checkPermission();
      if (status == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition();
      return LatLng(pos.latitude, pos.longitude);
    } catch (_) {
      return _fallback;
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LatLng>(
      future: _getInitialCamera(),
      builder: (context, snap) {
        final initial = snap.data ?? _fallback;
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Stack(
            children: [
              (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows)
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_off_rounded, color: Colors.grey, size: 64),
                          const SizedBox(height: 16),
                          Text(
                            'Map search is not supported on Windows',
                            style: GoogleFonts.inter(
                              color: Colors.grey,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: initial,
                        zoom: 13,
                      ),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      onMapCreated: (controller) {
                        _mapController = controller;
                        controller.setMapStyle(darkMapStyle);
                      },
                      onTap: (pos) async {
                        setState(() {
                          _pinnedLocation = pos;
                          _pinnedPlaceName = 'Selected Location';
                        });
                      },
                      markers: _pinnedLocation != null
                          ? {
                              Marker(
                                markerId: const MarkerId('pinned'),
                                position: _pinnedLocation!,
                                icon: BitmapDescriptor.defaultMarkerWithHue(45),
                              ),
                            }
                          : {},
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
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      Icon(
                        Icons.search_rounded,
                        color: AppColors.secondary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          controller: _searchController,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.text,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Search for a place...',
                            hintStyle: GoogleFonts.inter(
                              color: AppColors.secondary,
                              fontSize: 14,
                            ),
                            border: InputBorder.none,
                          ),
                          onSubmitted: (query) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Search not implemented. Tap map to select.',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.statCard,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              Positioned(
                bottom: 140,
                right: 16,
                child: GestureDetector(
                  onTap: () async {
                    try {
                      final pos = await Geolocator.getCurrentPosition();
                      final latlng = LatLng(pos.latitude, pos.longitude);
                      _mapController?.animateCamera(
                        CameraUpdate.newLatLng(latlng),
                      );
                    } catch (_) {}
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.navBorder),
                    ),
                    child: Icon(
                      Icons.my_location_rounded,
                      color: AppColors.gold,
                      size: 22,
                    ),
                  ),
                ),
              ),

              if (_pinnedLocation != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.card,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                      border: Border(
                        top: BorderSide(color: AppColors.navBorder),
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_rounded,
                              color: AppColors.gold,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _pinnedPlaceName ?? 'Selected Location',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.text,
                                ),
                                softWrap: true,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_pinnedLocation!.latitude.toStringAsFixed(4)}, ${_pinnedLocation!.longitude.toStringAsFixed(4)}',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                color: AppColors.secondary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context, {
                              'name': _pinnedPlaceName ?? 'Selected Location',
                              'lat': _pinnedLocation!.latitude,
                              'lng': _pinnedLocation!.longitude,
                            });
                          },
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
                                  color: AppColors.gold.withOpacity(0.3),
                                  blurRadius: 16,
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.lock_rounded,
                                  color: AppColors.background,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Lock This Destination',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.background,
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
            ],
          ),
        );
      },
    );
  }
}
