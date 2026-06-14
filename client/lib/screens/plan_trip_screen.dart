// 'FontFeature' is available through Flutter's material exports.
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
  static const LatLng _fallbackLocation = LatLng(10.7828, 79.1318);

  int _days = 1;
  LatLng? _currentLocation;
  bool _locationDeniedForever = false;
  final List<Destination> _selectedDestinations = [];

  @override
  void initState() {
    super.initState();
    _loadCurrentLocation();
  }

  Future<void> _loadCurrentLocation() async {
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          setState(() {
            _locationDeniedForever = true;
          });
        }
        return;
      }

      if (permission == LocationPermission.denied) {
        return;
      }

      final position = await Geolocator.getCurrentPosition();
      if (mounted) {
        setState(() {
          _currentLocation = LatLng(position.latitude, position.longitude);
          _locationDeniedForever = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _locationDeniedForever = true;
        });
      }
    }
  }

  Set<Marker> _buildMarkers() {
    final markers = <Marker>{};

    for (var i = 0; i < _selectedDestinations.length; i++) {
      final destination = _selectedDestinations[i];
      markers.add(
        Marker(
          markerId: MarkerId('dest_$i'),
          position: LatLng(destination.lat, destination.lng),
          icon: BitmapDescriptor.defaultMarkerWithHue(45),
          infoWindow: InfoWindow(title: '${i + 1}. ${destination.name}'),
        ),
      );
    }

    return markers;
  }

  Set<Polyline> _buildRoutePolyline() {
    if (_currentLocation == null || _selectedDestinations.isEmpty) {
      return {};
    }

    final points = <LatLng>[_currentLocation!];
    points.addAll(
      _selectedDestinations.map((destination) {
        return LatLng(destination.lat, destination.lng);
      }),
    );

    return {
      const Polyline(polylineId: PolylineId('route')).copyWith(
        pointsParam: points,
        colorParam: AppColors.gold,
        widthParam: 4,
        patternsParam: [PatternItem.dash(20), PatternItem.gap(10)],
      ),
    };
  }

  Future<void> _openMapSearch() async {
    final result = await Navigator.push<Map<String, Object?>>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            MapSearchScreen(currentLocation: _currentLocation),
      ),
    );

    if (result == null || _selectedDestinations.length >= 10) {
      return;
    }

    final name = result['name'] as String?;
    final lat = result['lat'] as double?;
    final lng = result['lng'] as double?;

    if (name == null || lat == null || lng == null) {
      return;
    }

    setState(() {
      _selectedDestinations.add(Destination(name: name, lat: lat, lng: lng));
    });
  }

  void _removeDestination(int index) {
    setState(() {
      _selectedDestinations.removeAt(index);
    });
  }

  void _startGame() {
    if (_selectedDestinations.isEmpty) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const RoadViewScreen()),
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
                    currentLocation: _currentLocation,
                    fallbackLocation: _fallbackLocation,
                    locationDeniedForever: _locationDeniedForever,
                    selectedDestinations: _selectedDestinations,
                    markers: _buildMarkers(),
                    polylines: _buildRoutePolyline(),
                    onSearchTap: _openMapSearch,
                    onRemoveDestination: _removeDestination,
                  ),
                ],
              ),
            ),
          ),
          _StickyStartArea(
            selectedCount: _selectedDestinations.length,
            onStart: _selectedDestinations.isEmpty ? null : _startGame,
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
              overlayColor: AppColors.gold.withValues(alpha: 0.2),
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

class _DestinationsMapCard extends StatelessWidget {
  const _DestinationsMapCard({
    required this.currentLocation,
    required this.fallbackLocation,
    required this.locationDeniedForever,
    required this.selectedDestinations,
    required this.markers,
    required this.polylines,
    required this.onSearchTap,
    required this.onRemoveDestination,
  });

  final LatLng? currentLocation;
  final LatLng fallbackLocation;
  final bool locationDeniedForever;
  final List<Destination> selectedDestinations;
  final Set<Marker> markers;
  final Set<Polyline> polylines;
  final VoidCallback onSearchTap;
  final ValueChanged<int> onRemoveDestination;

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
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.text,
                      fontFeatures: const [FontFeature.enable('kern')],
                    ),
                  ),
                  Text(
                    '${selectedDestinations.length}/10 selected',
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
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 220,
              child: GoogleMap(
                initialCameraPosition: CameraPosition(
                  target: currentLocation ?? fallbackLocation,
                  zoom: 14,
                ),
                myLocationEnabled: currentLocation != null,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                style: darkMapStyle,
                markers: markers,
                polylines: polylines,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (locationDeniedForever)
            const _InlineInfoMessage(
              text: 'Enable location access to see your position',
            )
          else if (selectedDestinations.isEmpty)
            const _InlineInfoMessage(
              text: "Tap 'Search on Map' to add destinations",
            )
          else
            Column(
              children: [
                for (var i = 0; i < selectedDestinations.length; i++)
                  _DestinationRow(
                    index: i,
                    destination: selectedDestinations[i],
                    onRemove: () => onRemoveDestination(i),
                  ),
              ],
            ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: selectedDestinations.length >= 10 ? null : onSearchTap,
            child: Opacity(
              opacity: selectedDestinations.length >= 10 ? 0.5 : 1,
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.statCard,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.gold.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.map_rounded,
                      color: AppColors.gold,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Search on Map',
                      softWrap: true,
                      overflow: TextOverflow.visible,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: AppColors.gold,
                        fontFeatures: const [FontFeature.enable('kern')],
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

class _InlineInfoMessage extends StatelessWidget {
  const _InlineInfoMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.info_outline, color: AppColors.secondary, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            softWrap: true,
            overflow: TextOverflow.visible,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.secondary,
              fontFeatures: const [FontFeature.enable('kern')],
            ),
          ),
        ),
      ],
    );
  }
}

class _DestinationRow extends StatelessWidget {
  const _DestinationRow({
    required this.index,
    required this.destination,
    required this.onRemove,
  });

  final int index;
  final Destination destination;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
            alignment: Alignment.center,
            child: Text(
              '${index + 1}',
              softWrap: true,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: AppColors.background,
                fontFeatures: const [FontFeature.enable('kern')],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              destination.name,
              softWrap: true,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.text,
                fontFeatures: const [FontFeature.enable('kern')],
              ),
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: const Icon(
              Icons.close_rounded,
              color: AppColors.secondary,
              size: 18,
            ),
          ),
        ],
      ),
    );
  }
}

class _StickyStartArea extends StatelessWidget {
  const _StickyStartArea({required this.selectedCount, required this.onStart});

  final int selectedCount;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final hasDestinations = selectedCount > 0;

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
                opacity: hasDestinations ? 1 : 0.4,
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
                        color: AppColors.gold.withValues(alpha: 0.3),
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
              hasDestinations
                  ? '$selectedCount destination(s) locked - Ready!'
                  : 'Select at least one destination',
              textAlign: TextAlign.center,
              softWrap: true,
              overflow: TextOverflow.visible,
              style: GoogleFonts.inter(
                fontSize: 12,
                color: hasDestinations ? AppColors.gold : AppColors.secondary,
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
