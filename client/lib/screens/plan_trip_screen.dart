import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../constants/app_colors.dart';
import '../constants/map_styles.dart';
import '../models/destination.dart';
import 'map_search_screen.dart';
import 'road_view_screen.dart';

class PlanTripScreen extends StatefulWidget {
  const PlanTripScreen({super.key});

  @override
  State<PlanTripScreen> createState() => _PlanTripScreenState();
}

class _PlanTripScreenState extends State<PlanTripScreen> {
  int _days = 1;
  List<Destination> selectedDestinations = [];
  LatLng? currentLocation;
  bool _locationDeniedForever = false;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => _locationDeniedForever = true);
        return;
      }
      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        try {
          final pos = await Geolocator.getCurrentPosition();
          setState(() => currentLocation = LatLng(pos.latitude, pos.longitude));
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> _openMapSearch() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MapSearchScreen()),
    );
    if (result != null && result is Map) {
      final name = result['name'] as String? ?? 'Selected Location';
      final lat = result['lat'] as double?;
      final lng = result['lng'] as double?;
      if (lat != null && lng != null) {
        setState(() {
          if (selectedDestinations.length < 10) {
            selectedDestinations.add(
              Destination(name: name, lat: lat, lng: lng),
            );
          }
        });
      }
    }
  }

  void _startGame() {
    if (selectedDestinations.isEmpty) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RoadViewScreen(
          startLocation: currentLocation ?? const LatLng(10.7828, 79.1318),
          destinations: selectedDestinations,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: const _CircleIconButton(icon: Icons.arrow_back_rounded),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Plan Your Trip',
              softWrap: true,
              overflow: TextOverflow.visible,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
                fontFeatures: const [FontFeature.enable('kern')],
              ),
            ),
            Text(
              'Select your destinations',
              softWrap: true,
              overflow: TextOverflow.visible,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: AppColors.secondary,
                fontFeatures: const [FontFeature.enable('kern')],
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _TripDurationCard(
                    days: _days,
                    onChanged: (value) {
                      setState(() {
                        _days = value.round();
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  _DestinationsMapCard(
                    selectedDestinations: selectedDestinations,
                    currentLocation: currentLocation,
                    onSearchTap: _openMapSearch,
                    onRemove: (index) {
                      setState(() => selectedDestinations.removeAt(index));
                    },
                    mapControllerSetter: (c) {},
                    locationDeniedForever: _locationDeniedForever,
                  ),
                ],
              ),
            ),
          ),
          _StickyStartArea(
            selectedCount: selectedDestinations.length,
            onStart: selectedDestinations.isEmpty ? null : _startGame,
          ),
        ],
      ),
    );
  }
}

class _TripDurationCard extends StatelessWidget {
  const _TripDurationCard({required this.days, required this.onChanged});

  final int days;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.navBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold,
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: AppColors.background,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Trip Duration',
                softWrap: true,
                overflow: TextOverflow.visible,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.text,
                  fontFeatures: const [FontFeature.enable('kern')],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.statCard,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$days Days',
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.gold,
                    fontFeatures: const [FontFeature.enable('kern')],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AppColors.gold,
              inactiveTrackColor: AppColors.statCard,
              thumbColor: AppColors.gold,
              overlayColor: AppColors.gold.withOpacity(0.2),
              trackHeight: 4,
            ),
            child: Slider(
              min: 1,
              max: 14,
              divisions: 13,
              value: days.toDouble(),
              onChanged: onChanged,
            ),
          ),
          Row(
            children: [
              Text(
                '1 Days',
                softWrap: true,
                overflow: TextOverflow.visible,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.secondary,
                  fontFeatures: const [FontFeature.enable('kern')],
                ),
              ),
              const Spacer(),
              Text(
                '14 Days',
                softWrap: true,
                overflow: TextOverflow.visible,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.secondary,
                  fontFeatures: const [FontFeature.enable('kern')],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DestinationsMapCard extends StatefulWidget {
  const _DestinationsMapCard({
    required this.selectedDestinations,
    required this.currentLocation,
    required this.onSearchTap,
    required this.onRemove,
    required this.mapControllerSetter,
    required this.locationDeniedForever,
  });

  final List<Destination> selectedDestinations;
  final LatLng? currentLocation;
  final VoidCallback onSearchTap;
  final void Function(int) onRemove;
  final void Function(GoogleMapController) mapControllerSetter;
  final bool locationDeniedForever;

  @override
  State<_DestinationsMapCard> createState() => _DestinationsMapCardState();
}

class _DestinationsMapCardState extends State<_DestinationsMapCard> {
  final LatLng _fallback = const LatLng(10.7828, 79.1318);

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};
    for (int i = 0; i < widget.selectedDestinations.length; i++) {
      final d = widget.selectedDestinations[i];
      markers.add(
        Marker(
          markerId: MarkerId('dest_$i'),
          position: LatLng(d.lat, d.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(45),
          infoWindow: InfoWindow(title: '${i + 1}. ${d.name}'),
        ),
      );
    }
    return markers;
  }

  Set<Polyline> _buildRoutePolyline() {
    if (widget.currentLocation == null || widget.selectedDestinations.isEmpty) {
      return {};
    }
    final points = <LatLng>[widget.currentLocation!];
    points.addAll(
      widget.selectedDestinations.map((d) => LatLng(d.lat, d.lng)).toList(),
    );
    return {
      Polyline(
        polylineId: const PolylineId('route'),
        points: points,
        color: const Color(0xFFFFB800),
        width: 4,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final center = widget.currentLocation ?? _fallback;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.navBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.gold,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: AppColors.background,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Must-Visit Destinations',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                    ),
                  ),
                  Text(
                    '${widget.selectedDestinations.length}/10 selected',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: AppColors.secondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 220,
              color: Colors.black,
              child: (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows)
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.location_off_rounded, color: Colors.grey, size: 40),
                          const SizedBox(height: 12),
                          Text(
                            'Map preview not supported on Windows',
                            style: GoogleFonts.inter(
                              color: Colors.grey,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    )
                  : GoogleMap(
                      initialCameraPosition: CameraPosition(target: center, zoom: 14),
                      myLocationEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      mapToolbarEnabled: false,
                      onMapCreated: (c) {
                        widget.mapControllerSetter(c);
                        c.setMapStyle(darkMapStyle);
                      },
                      markers: _buildMarkers(),
                      polylines: _buildRoutePolyline(),
                    ),
            ),
          ),
          const SizedBox(height: 12),

          if (widget.locationDeniedForever)
            Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.secondary, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Enable location access to see your position',
                    style: GoogleFonts.inter(
                      color: AppColors.secondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            )
          else if (widget.selectedDestinations.isEmpty)
            Row(
              children: [
                Icon(Icons.info_outline, color: AppColors.secondary, size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "Tap 'Search on Map' to add destinations",
                    style: GoogleFonts.inter(
                      color: AppColors.secondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            )
          else
            Column(
              children: List.generate(widget.selectedDestinations.length, (i) {
                final d = widget.selectedDestinations[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 8, top: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.statCard,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.gold,
                        ),
                        child: Center(
                          child: Text(
                            '${i + 1}',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: AppColors.background,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          d.name,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: AppColors.text,
                          ),
                          softWrap: true,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => widget.onRemove(i),
                        child: Icon(
                          Icons.close_rounded,
                          color: AppColors.secondary,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),

          const SizedBox(height: 16),
          GestureDetector(
            onTap: widget.onSearchTap,
            child: Container(
              width: double.infinity,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.statCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.gold.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.map_rounded, color: AppColors.gold, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Search on Map',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gold,
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

// class _StickyStartArea extends StatelessWidget {
//   const _StickyStartArea();

//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       top: false,
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               width: double.infinity,
//               height: 56,
//               decoration: BoxDecoration(
//                 gradient: const LinearGradient(
//                   colors: [AppColors.gold, AppColors.goldDark],
//                 ),
//                 borderRadius: BorderRadius.circular(28),
//                 boxShadow: [
//                   BoxShadow(
//                     color: AppColors.gold.withOpacity(0.3),
//                     blurRadius: 20,
//                   ),
//                 ],
//               ),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   const Icon(
//                     Icons.auto_awesome,
//                     color: AppColors.background,
//                     size: 20,
//                   ),
//                   const SizedBox(width: 8),
//                   Text(
//                     'START GAME',
//                     softWrap: true,
//                     overflow: TextOverflow.visible,
//                     style: GoogleFonts.inter(
//                       fontSize: 15,
//                       fontWeight: FontWeight.bold,
//                       letterSpacing: 2,
//                       color: AppColors.background,
//                       fontFeatures: const [FontFeature.enable('kern')],
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'Select at least one destination',
//               textAlign: TextAlign.center,
//               softWrap: true,
//               overflow: TextOverflow.visible,
//               style: GoogleFonts.inter(
//                 fontSize: 12,
//                 color: AppColors.secondary,
//                 fontFeatures: const [FontFeature.enable('kern')],
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }
class _StickyStartArea extends StatelessWidget {
  const _StickyStartArea({
    required this.selectedCount,
    this.onStart,
  });

  final int selectedCount;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: onStart,
              child: Opacity(
                opacity: selectedCount > 0 ? 1.0 : 0.4,
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.gold, AppColors.goldDark],
                    ),
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withOpacity(0.3),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: AppColors.background,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'START GAME',
                        softWrap: true,
                        overflow: TextOverflow.visible,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                          color: AppColors.background,
                          fontFeatures: const [FontFeature.enable('kern')],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              selectedCount == 0
                  ? 'Select at least one destination'
                  : '$selectedCount destination(s) locked — Ready!',
              textAlign: TextAlign.center,
              softWrap: true,
              overflow: TextOverflow.visible,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: selectedCount == 0
                    ? AppColors.secondary
                    : AppColors.gold,
                fontFeatures: const [FontFeature.enable('kern')],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 40,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.statCard,
        ),
        child: Icon(icon, color: AppColors.text, size: 20),
      ),
    );
  }
}
