import 'dart:convert';
import 'dart:math';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;

class DirectionsService {
  /// Google Maps Directions API Key. Set this to your API key.
  static String googleMapsApiKey = "";

  /// Fetches the route waypoints between the origin, intermediate waypoints, and the destination.
  /// If the API key is empty or the request fails, it runs a realistic curve-generating fallback.
  static Future<List<LatLng>> getRouteWaypoints({
    required LatLng origin,
    required List<LatLng> destinations,
  }) async {
    if (destinations.isEmpty) {
      return [origin];
    }

    // Attempt to use Google Maps Directions API if API key is set
    if (googleMapsApiKey.isNotEmpty) {
      try {
        final originStr = "${origin.latitude},${origin.longitude}";
        final dest = destinations.last;
        final destStr = "${dest.latitude},${dest.longitude}";
        
        String waypointsStr = "";
        if (destinations.length > 1) {
          final waypoints = destinations.sublist(0, destinations.length - 1);
          waypointsStr = "&waypoints=" +
              waypoints
                  .map((w) => "${w.latitude},${w.longitude}")
                  .join("|");
        }

        final url = Uri.parse(
          "https://maps.googleapis.com/maps/api/directions/json"
          "?origin=$originStr"
          "&destination=$destStr"
          "$waypointsStr"
          "&key=$googleMapsApiKey"
        );

        final response = await http.get(url);
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data['status'] == 'OK' &&
              data['routes'] != null &&
              data['routes'].isNotEmpty) {
            final encodedPolyline =
                data['routes'][0]['overview_polyline']['points'] as String;
            final decoded = decodePolyline(encodedPolyline);
            if (decoded.isNotEmpty) {
              return decoded;
            }
          }
        }
      } catch (_) {
        // Fallback on network error
      }
    }

    // Fallback: Generate an intelligent, curved path connecting all waypoints
    return _generateCurvedFallbackPath(origin, destinations);
  }

  /// Decodes Google Maps Encoded Polyline algorithm string into LatLng list.
  static List<LatLng> decodePolyline(String encoded) {
    List<LatLng> points = [];
    int index = 0, len = encoded.length;
    int lat = 0, lng = 0;

    while (index < len) {
      int b, shift = 0, result = 0;
      do {
        if (index >= len) return points;
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlat = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lat += dlat;

      shift = 0;
      result = 0;
      do {
        if (index >= len) return points;
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);
      int dlng = ((result & 1) != 0 ? ~(result >> 1) : (result >> 1));
      lng += dlng;

      points.add(LatLng(lat / 1E5, lng / 1E5));
    }
    return points;
  }

  /// Generates a realistic route by drawing curvy lines between coordinates.
  static List<LatLng> _generateCurvedFallbackPath(
    LatLng start,
    List<LatLng> dests,
  ) {
    final List<LatLng> path = [];
    LatLng current = start;

    for (final target in dests) {
      final points = _interpolateCurvedSegment(current, target);
      path.addAll(points);
      current = target;
    }

    // De-duplicate points if adjacent are identical
    final List<LatLng> uniquePath = [];
    for (final pt in path) {
      if (uniquePath.isEmpty ||
          (uniquePath.last.latitude - pt.latitude).abs() > 1e-6 ||
          (uniquePath.last.longitude - pt.longitude).abs() > 1e-6) {
        uniquePath.add(pt);
      }
    }
    return uniquePath;
  }

  /// Interpolates a segment between two coordinates with natural offsets.
  static List<LatLng> _interpolateCurvedSegment(LatLng p1, LatLng p2) {
    final List<LatLng> segment = [];
    
    // Estimate distance in meters
    const double earthRadius = 6371000.0;
    final dLat = (p2.latitude - p1.latitude) * pi / 180.0;
    final dLng = (p2.longitude - p1.longitude) * pi / 180.0;
    final latAvg = (p1.latitude + p2.latitude) / 2.0 * pi / 180.0;
    
    final x = earthRadius * dLng * cos(latAvg);
    final y = earthRadius * dLat;
    final distance = sqrt(x * x + y * y);

    // Number of intermediate steps (approx. 1 step every 15 meters)
    final numSteps = max(2, (distance / 15.0).round());

    // Perpendicular vector for introducing curves
    final perpLat = -(p2.longitude - p1.longitude);
    final perpLng = (p2.latitude - p1.latitude);
    final perpLen = sqrt(perpLat * perpLat + perpLng * perpLng);

    // Amplitude of the curve (adds character to simulator roads)
    final curveAmplitude = perpLen > 0 ? 0.08 : 0.0;

    for (int i = 0; i <= numSteps; i++) {
      final t = i / numSteps;
      
      // Linear interpolation
      double lat = p1.latitude + (p2.latitude - p1.latitude) * t;
      double lng = p1.longitude + (p2.longitude - p1.longitude) * t;

      // Add a sine-wave offset perpendicular to the direction
      if (perpLen > 0) {
        // Multi-frequency wave for natural variation
        final offset = sin(t * pi) * curveAmplitude * (0.5 * sin(t * 3 * pi) + 0.5);
        lat += (perpLat / perpLen) * offset;
        lng += (perpLng / perpLen) * offset;
      }

      segment.add(LatLng(lat, lng));
    }

    return segment;
  }
}
