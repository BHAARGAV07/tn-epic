import '../models/vector3.dart';
import '../models/quest_node.dart';

class RouteManager {
  /// Corridor width boundary constraints (e.g. wall at +/- 1.5 meters from centerline)
  static const double leftWallX = -1.5;
  static const double rightWallX = 1.5;

  /// Loads the predefined mock college corridor waypoints (ENU: X=right, Y=forward, Z=up)
  static List<Vector3> getCorridorRoute() {
    return const [
      Vector3(0.0, 0.0, -1.6),   // Start of corridor
      Vector3(0.0, 3.0, -1.6),
      Vector3(0.0, 6.0, -1.6),
      Vector3(0.0, 9.0, -1.6),   // Heading to the turn
      Vector3(0.0, 12.0, -1.6),  // Corner of turn (turn right!)
      Vector3(3.0, 12.0, -1.6),
      Vector3(6.0, 12.0, -1.6),
      Vector3(9.0, 12.0, -1.6),
      Vector3(12.0, 12.0, -1.6), // End of corridor destination
    ];
  }

  /// Loads quest nodes aligned to the corridor route in local space
  static List<QuestNode> getCorridorQuestNodes() {
    return [
      QuestNode.local(
        id: 'coin_1',
        name: 'Chola Corridor Gold',
        type: 'coin',
        x: 0.0,
        y: 2.0,
        z: -0.4, // float height
        value: 50,
      ),
      QuestNode.local(
        id: 'coin_2',
        name: 'Heritage Emblem',
        type: 'coin',
        x: 0.0,
        y: 5.0,
        z: -0.4,
        value: 100,
      ),
      QuestNode.local(
        id: 'sp_1',
        name: 'Corridor Checkpoint A',
        type: 'save_point',
        x: 0.0,
        y: 8.0,
        z: -1.6, // floor height
        value: 0,
      ),
      QuestNode.local(
        id: 'coin_3',
        name: 'Temple Relic Shard',
        type: 'coin',
        x: 1.5, // positioned after the right turn
        y: 12.0,
        z: -0.4,
        value: 75,
      ),
      QuestNode.local(
        id: 'coin_4',
        name: 'Golden Lotus',
        type: 'coin',
        x: 5.5,
        y: 12.0,
        z: -0.4,
        value: 120,
      ),
      QuestNode.local(
        id: 'sp_2',
        name: 'Maratha Durbar checkpoint B',
        type: 'save_point',
        x: 8.5,
        y: 12.0,
        z: -1.6,
        value: 0,
      ),
      QuestNode.local(
        id: 'beacon_1',
        name: 'Chola Sanctuary Beacon',
        type: 'beacon',
        x: 12.0,
        y: 12.0,
        z: -1.6,
        value: 200,
      ),
    ];
  }

  /// Determines the closest route waypoint segment and calculates progress.
  /// Used to guide the user in local space.
  static Map<String, dynamic> getProgress(Vector3 userPos, List<Vector3> route) {
    if (route.isEmpty) return {'segmentIndex': 0, 'distanceToNext': 0.0};

    int nearestIdx = 0;
    double minDistance = double.infinity;

    for (int i = 0; i < route.length; i++) {
      double d = userPos.distanceTo(route[i]);
      if (d < minDistance) {
        minDistance = d;
        nearestIdx = i;
      }
    }

    int nextIdx = (nearestIdx + 1).clamp(0, route.length - 1);
    double distToNext = userPos.distanceTo(route[nextIdx]);

    return {
      'segmentIndex': nearestIdx,
      'nextWaypoint': route[nextIdx],
      'distanceToNext': distToNext,
      'isAtEnd': nearestIdx == route.length - 1,
    };
  }
}
