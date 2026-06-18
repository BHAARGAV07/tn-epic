import 'package:flutter_test/flutter_test.dart';
import 'package:client/models/quest_node.dart';
import 'package:client/models/vector3.dart';
import 'package:client/services/route_manager.dart';

void main() {
  group('VIO Indoor AR Math and Logic Tests', () {
    test('Vector3 Distance calculation Test', () {
      const v1 = Vector3(0.0, 0.0, 0.0);
      const v2 = Vector3(3.0, 4.0, 0.0); // 3-4-5 triangle in horizontal plane

      final distance = v1.distanceTo(v2);
      expect(distance, equals(5.0));
    });

    test('Vector3 Zero Distance Test', () {
      const v1 = Vector3(1.5, 4.2, -1.6);
      final distance = v1.distanceTo(v1);
      expect(distance, equals(0.0));
    });

    test('QuestNode Local Distance calculations', () {
      final node = QuestNode.local(
        id: 'test_local',
        name: 'Test Local Node',
        type: 'coin',
        x: 0.0,
        y: 10.0,
        z: -0.4,
        value: 100,
      );

      final distance = node.localDistanceTo(0.0, 10.0, -0.4);
      expect(distance, equals(0.0));

      final distOffset = node.localDistanceTo(0.0, 10.0, -1.6); // 1.2 meters below
      expect(distOffset, closeTo(1.2, 0.0001));
    });

    test('RouteManager Telemetry Progress calculation', () {
      final route = RouteManager.getCorridorRoute();
      
      // User stands at origin (0, 0, 0)
      const userPos = Vector3(0.0, 0.0, 0.0);
      
      final progress = RouteManager.getProgress(userPos, route);
      
      // Nearest index is 0 (Vector3(0,0,-1.6))
      expect(progress['segmentIndex'], equals(0));
      
      // Next waypoint is index 1 (Vector3(0,3,-1.6))
      final nextWp = progress['nextWaypoint'] as Vector3;
      expect(nextWp.y, equals(3.0));
      
      // Distance to next waypoint in 3D: (0, 3, -1.6) relative to (0, 0, 0)
      // distance = sqrt(0^2 + 3^2 + (-1.6)^2) = sqrt(9 + 2.56) = sqrt(11.56) = 3.4
      final distance = progress['distanceToNext'] as double;
      expect(distance, closeTo(3.4, 0.001));
      
      expect(progress['isAtEnd'], isFalse);
    });
  });
}
