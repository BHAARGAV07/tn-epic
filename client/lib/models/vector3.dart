import 'dart:math';

class Vector3 {
  final double x; // Horizontal axis: left (-) / right (+)
  final double y; // Depth axis: forward (+) / backward (-)
  final double z; // Altitude axis: up (+) / down (-) (floor at z = -1.6)

  const Vector3(this.x, this.y, this.z);

  double distanceTo(Vector3 other) {
    final dx = other.x - x;
    final dy = other.y - y;
    final dz = other.z - z;
    return sqrt(dx * dx + dy * dy + dz * dz);
  }

  @override
  String toString() => 'Vector3(${x.toStringAsFixed(2)}, ${y.toStringAsFixed(2)}, ${z.toStringAsFixed(2)})';
}
