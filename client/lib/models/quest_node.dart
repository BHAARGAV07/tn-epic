import 'dart:math';

class QuestNode {
  final String id;
  final String name;
  final String type; // 'coin' | 'save_point' | 'beacon'
  final double latitude;
  final double longitude;
  final double altitude; // height offset for float effect
  final int value;
  bool isCollected;

  // Local space coordinates for indoor VIO navigation
  final double? localX;
  final double? localY;
  final double? localZ;

  QuestNode({
    required this.id,
    required this.name,
    required this.type,
    required this.latitude,
    required this.longitude,
    this.altitude = 0.0,
    required this.value,
    this.isCollected = false,
    this.localX,
    this.localY,
    this.localZ,
  });

  factory QuestNode.local({
    required String id,
    required String name,
    required String type,
    required double x,
    required double y,
    required double z,
    required int value,
  }) {
    return QuestNode(
      id: id,
      name: name,
      type: type,
      latitude: 0.0,
      longitude: 0.0,
      altitude: z,
      value: value,
      localX: x,
      localY: y,
      localZ: z,
    );
  }

  factory QuestNode.fromJson(Map<String, dynamic> json) {
    return QuestNode(
      id: json['id'] as String,
      name: json['name'] as String,
      type: json['type'] as String,
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      altitude: (json['altitude'] as num?)?.toDouble() ?? 0.0,
      value: json['value'] as int? ?? 0,
      isCollected: json['isCollected'] as bool? ?? false,
      localX: (json['localX'] as num?)?.toDouble(),
      localY: (json['localY'] as num?)?.toDouble(),
      localZ: (json['localZ'] as num?)?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'latitude': latitude,
      'longitude': longitude,
      'altitude': altitude,
      'value': value,
      'isCollected': isCollected,
      'localX': localX,
      'localY': localY,
      'localZ': localZ,
    };
  }

  /// Calculates the distance in meters in local coordinate space.
  double localDistanceTo(double lx, double ly, double lz) {
    final dx = (localX ?? 0.0) - lx;
    final dy = (localY ?? 0.0) - ly;
    final dz = (localZ ?? 0.0) - lz;
    return sqrt(dx * dx + dy * dy + dz * dz);
  }

  /// Calculates the O(1) distance in meters to another coordinate using the Haversine formula.
  double distanceTo(double destLat, double destLng) {
    const double earthRadius = 6371000.0; // in meters
    final double dLat = _toRadians(destLat - latitude);
    final double dLng = _toRadians(destLng - longitude);

    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(latitude)) *
            cos(_toRadians(destLat)) *
            sin(dLng / 2) *
            sin(dLng / 2);

    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return earthRadius * c;
  }

  static double _toRadians(double degree) {
    return degree * pi / 180.0;
  }
}
