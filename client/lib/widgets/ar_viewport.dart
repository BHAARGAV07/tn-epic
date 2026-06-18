import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../constants/app_colors.dart';
import '../models/quest_node.dart';
import '../models/vector3.dart';
import '../services/route_manager.dart';

class ArViewport extends StatefulWidget {
  final Vector3 userPosition;
  final List<Vector3> roadWaypoints;
  final List<QuestNode> questNodes;
  final Function(QuestNode) onCollectQuestNode;
  final ValueChanged<Vector3> onLocationChanged;
  
  // Floor scanning state
  final bool isFloorDetected;
  final double scanProgress;

  const ArViewport({
    super.key,
    required this.userPosition,
    required this.roadWaypoints,
    required this.questNodes,
    required this.onCollectQuestNode,
    required this.onLocationChanged,
    required this.isFloorDetected,
    required this.scanProgress,
  });

  @override
  State<ArViewport> createState() => _ArViewportState();
}

class _ArViewportState extends State<ArViewport> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  // Camera view angles (VIO coordinate system)
  double _heading = 0.0; // Yaw angle (0 = Straight forward, +90 = turn right, -90 = turn left)
  double _pitch = -35.0; // Pitch angle (starting tilted down so road renders instantly)

  // Simulation parameters
  bool _isSimulatingWalk = false;
  Timer? _simulationTimer;
  int _simulationWaypointIndex = 0;
  double _simulationProgress = 0.0;
  double _speedMps = 1.2; // 1.2 m/s indoor speed

  // Active particle explosions for collected coins
  final List<_ParticleBurst> _particleBursts = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _simulationTimer?.cancel();
    super.dispose();
  }

  void _toggleSimulation() {
    if (!widget.isFloorDetected) return; // Floor must be scanned first!

    setState(() {
      _isSimulatingWalk = !_isSimulatingWalk;
    });

    if (_isSimulatingWalk) {
      final bool completed = _simulationWaypointIndex >= widget.roadWaypoints.length - 1;
      if (completed) {
        setState(() {
          _simulationWaypointIndex = 0;
          _simulationProgress = 0.0;
          for (final node in widget.questNodes) {
            node.isCollected = false;
          }
        });
        if (widget.roadWaypoints.isNotEmpty) {
          widget.onLocationChanged(widget.roadWaypoints[0]);
        }
      }

      // Automatically snap camera view to face down the corridor path
      _snapCameraToPath();

      _simulationTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        _updateSimulation();
      });
    } else {
      _simulationTimer?.cancel();
    }
  }

  void _snapCameraToPath() {
    if (widget.roadWaypoints.isEmpty) return;

    // Determine target heading based on current position and next waypoint
    final int nextIdx = (_simulationWaypointIndex + 1).clamp(0, widget.roadWaypoints.length - 1);
    final currentPos = widget.userPosition;
    final nextPos = widget.roadWaypoints[nextIdx];

    final double dy = nextPos.y - currentPos.y;
    final double dx = nextPos.x - currentPos.x;

    double targetHeading = 0.0;
    if (dy.abs() > 0.01 || dx.abs() > 0.01) {
      targetHeading = atan2(dx, dy) * 180.0 / pi;
    } else if (_simulationWaypointIndex > 0) {
      // If close to next waypoint, look in the direction of the segment leading to it
      final prevPos = widget.roadWaypoints[_simulationWaypointIndex - 1];
      final double prevDy = currentPos.y - prevPos.y;
      final double prevDx = currentPos.x - prevPos.x;
      if (prevDy.abs() > 0.01 || prevDx.abs() > 0.01) {
        targetHeading = atan2(prevDx, prevDy) * 180.0 / pi;
      }
    }

    setState(() {
      _heading = (targetHeading + 360) % 360;
      _pitch = -35.0; // Tilts phone downward so the road renders instantly (gating threshold is 20)
    });
  }

  void _updateSimulation() {
    if (widget.roadWaypoints.isEmpty) return;

    if (_simulationWaypointIndex >= widget.roadWaypoints.length - 1) {
      // Completed the route corridor
      setState(() {
        _isSimulatingWalk = false;
      });
      _simulationTimer?.cancel();
      return;
    }

    final p1 = widget.roadWaypoints[_simulationWaypointIndex];
    final p2 = widget.roadWaypoints[_simulationWaypointIndex + 1];

    final segmentDist = p1.distanceTo(p2);
    if (segmentDist <= 0.1) {
      _simulationWaypointIndex++;
      _simulationProgress = 0.0;
      return;
    }

    // Advance position relative to speed and elapsed time
    final stepDistance = _speedMps * 0.05; // speed * 50ms period
    _simulationProgress += stepDistance / segmentDist;

    if (_simulationProgress >= 1.0) {
      _simulationWaypointIndex++;
      _simulationProgress = 0.0;
      widget.onLocationChanged(p2);
    } else {
      final interpX = p1.x + (p2.x - p1.x) * _simulationProgress;
      final interpY = p1.y + (p2.y - p1.y) * _simulationProgress;
      final interpZ = p1.z + (p2.z - p1.z) * _simulationProgress;
      final newPos = Vector3(interpX, interpY, interpZ);
      widget.onLocationChanged(newPos);

      // Auto-orient camera heading towards next waypoint
      final dy = p2.y - interpY;
      final dx = p2.x - interpX;
      final targetHeading = atan2(dx, dy) * 180.0 / pi;

      // Smooth camera yaw interpolation
      final diff = targetHeading - _heading;
      final shortestDiff = atan2(sin(diff * pi / 180.0), cos(diff * pi / 180.0)) * 180.0 / pi;
      _heading = (_heading + shortestDiff * 0.15 + 360) % 360;
    }

    // Check proximity triggers for quest nodes in local space
    _checkQuestNodeCollection();
  }

  void _checkQuestNodeCollection() {
    final userX = widget.userPosition.x;
    final userY = widget.userPosition.y;
    final userZ = widget.userPosition.z;

    for (final node in widget.questNodes) {
      if (node.isCollected) continue;

      final distance = node.localDistanceTo(userX, userY, userZ);
      if (distance <= 1.8) {
        // Collect!
        node.isCollected = true;
        widget.onCollectQuestNode(node);

        // Spawn visual 3D particle burst
        _spawnParticleBurst(node);
      }
    }
  }

  void _spawnParticleBurst(QuestNode node) {
    setState(() {
      _particleBursts.add(
        _ParticleBurst(
          x: node.localX ?? 0.0,
          y: node.localY ?? 0.0,
          z: node.localZ ?? 0.0,
          color: node.type == 'coin'
              ? AppColors.gold
              : (node.type == 'beacon' ? Colors.cyanAccent : Colors.cyan.shade300),
          spawnTime: DateTime.now(),
        ),
      );
    });

    Timer(const Duration(milliseconds: 1200), () {
      if (mounted) {
        setState(() {
          _particleBursts.removeWhere((b) =>
              b.x == (node.localX ?? 0.0) &&
              b.y == (node.localY ?? 0.0) &&
              b.z == (node.localZ ?? 0.0));
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isFloorDetected && !_isSimulatingWalk) {
      _checkQuestNodeCollection();
    }

    // Calculate camera pitch downward angle to display in warning HUD
    // _pitch is between -60° (looking straight down) and 60° (looking straight up).
    // Pitch downward is positive when tilting the top of the phone towards the ground.
    final pitchDownward = -_pitch;
    final bool isLookingDown = pitchDownward >= 20.0;

    return GestureDetector(
      onPanUpdate: (details) {
        setState(() {
          // Horizontal drag rotates Yaw (Heading)
          _heading = (_heading - details.delta.dx * 0.25 + 360) % 360;
          // Vertical drag rotates Pitch (horizontal to looking down)
          _pitch = (_pitch - details.delta.dy * 0.25).clamp(-60.0, 45.0);
        });
      },
      child: Stack(
        children: [
          // 3D Rendering Layer
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                // Update active particles frame-by-frame
                for (final burst in _particleBursts) {
                  burst.update();
                }

                return CustomPaint(
                  painter: ArPainter(
                    userPosition: widget.userPosition,
                    heading: _heading,
                    pitch: _pitch,
                    roadWaypoints: widget.roadWaypoints,
                    questNodes: widget.questNodes,
                    particleBursts: _particleBursts,
                    animationValue: _animationController.value,
                    isFloorDetected: widget.isFloorDetected,
                  ),
                );
              },
            ),
          ),

          // Scanning Floor Animation overlay
          if (!widget.isFloorDetected)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.35),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Scanner Radar
                      SizedBox(
                        width: 140,
                        height: 140,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            CircularProgressIndicator(
                              value: widget.scanProgress,
                              color: Colors.cyanAccent,
                              strokeWidth: 3.5,
                            ),
                            Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.cyanAccent.withOpacity(0.08),
                                border: Border.all(color: Colors.cyanAccent.withOpacity(0.3), width: 1.5),
                              ),
                              child: const Icon(
                                Icons.center_focus_strong_outlined,
                                color: Colors.cyanAccent,
                                size: 38,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'SCANNING CORRIDOR FLOOR...',
                        style: GoogleFonts.inter(
                          color: Colors.cyanAccent,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Point camera downward and move side to side',
                        style: GoogleFonts.inter(
                          color: AppColors.secondary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Look Down Warning Overlay
          if (widget.isFloorDetected && !isLookingDown)
            Positioned(
              top: 130,
              left: 32,
              right: 32,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade900.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.redAccent, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.25),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.warning_amber_rounded, color: Colors.redAccent, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'ROADWAY HIDDEN',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tilt phone downward (look at the floor) to reveal the path',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        color: AppColors.text,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

          // Predefined Walk controls
          if (widget.isFloorDetected)
            Positioned(
              bottom: 24,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 52,
                      decoration: BoxDecoration(
                        color: AppColors.background.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.navBorder, width: 1.5),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(
                                _isSimulatingWalk ? Icons.directions_walk_rounded : Icons.pause_circle_outline_rounded,
                                color: _isSimulatingWalk ? AppColors.gold : AppColors.secondary,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _isSimulatingWalk
                                    ? 'Walking Corridor: ${_speedMps.toStringAsFixed(1)} m/s'
                                    : 'VIO Session Locked',
                                style: GoogleFonts.inter(
                                  color: AppColors.text,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          if (_isSimulatingWalk)
                            Row(
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove, color: AppColors.secondary, size: 18),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    setState(() {
                                      _speedMps = max(0.4, _speedMps - 0.4);
                                    });
                                  },
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.add, color: AppColors.secondary, size: 18),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    setState(() {
                                      _speedMps = min(6.0, _speedMps + 0.4);
                                    });
                                  },
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _toggleSimulation,
                    child: Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _isSimulatingWalk
                              ? [Colors.redAccent, Colors.red.shade900]
                              : [AppColors.gold, AppColors.goldDark],
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_isSimulatingWalk ? Colors.red : AppColors.gold).withOpacity(0.35),
                            blurRadius: 12,
                          ),
                        ],
                      ),
                      child: Icon(
                        _isSimulatingWalk ? Icons.stop_rounded : Icons.play_arrow_rounded,
                        color: _isSimulatingWalk ? Colors.white : AppColors.background,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Local Coordinate Telemetry Panel
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background.withOpacity(0.8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.navBorder, width: 1.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildTelemetryRow(Icons.explore_outlined, 'Yaw (Yaw)', '${_heading.toStringAsFixed(1)}°'),
                  const SizedBox(height: 6),
                  _buildTelemetryRow(Icons.height_outlined, 'Pitch (Pitch)', '${_pitch.toStringAsFixed(1)}°'),
                  const SizedBox(height: 6),
                  _buildTelemetryRow(
                    Icons.grid_3x3_rounded,
                    'Local XYZ',
                    '${widget.userPosition.x.toStringAsFixed(1)}, ${widget.userPosition.y.toStringAsFixed(1)}, ${widget.userPosition.z.toStringAsFixed(1)}',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTelemetryRow(IconData icon, String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.gold, size: 14),
        const SizedBox(width: 6),
        Text(
          '$label: ',
          style: GoogleFonts.inter(
            color: AppColors.secondary,
            fontSize: 10,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.jetBrainsMono(
            color: AppColors.text,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class ArPainter extends CustomPainter {
  final Vector3 userPosition;
  final double heading;
  final double pitch;
  final List<Vector3> roadWaypoints;
  final List<QuestNode> questNodes;
  final List<_ParticleBurst> particleBursts;
  final double animationValue;
  final bool isFloorDetected;

  ArPainter({
    required this.userPosition,
    required this.heading,
    required this.pitch,
    required this.roadWaypoints,
    required this.questNodes,
    required this.particleBursts,
    required this.animationValue,
    required this.isFloorDetected,
  });

  static const double _fov = 60.0;
  static const double _roadWidth = 2.4; // width of corridor path mesh
  static const double _maxRenderDist = 25.0; // Render range in indoor coordinate space (25 meters)

  @override
  void paint(Canvas canvas, Size size) {
    final double f = (size.width / 2.0) / tan((_fov / 2.0) * pi / 180.0);

    // 1. Draw the floor plane scanning grid if floor is detected
    if (isFloorDetected) {
      _drawFloorPlaneGrid(canvas, size, f);
    }

    // Gating check: calculate road opacity based on camera pitch
    final double pitchDownward = -pitch;
    double roadOpacity = 0.0;
    if (pitchDownward > 20.0) {
      roadOpacity = ((pitchDownward - 20.0) / 15.0).clamp(0.0, 1.0);
    }

    if (isFloorDetected && roadOpacity > 0.0) {
      // 2. Draw the Golden Road Mesh
      _drawCorridorRoad(canvas, size, f, roadOpacity);
      
      // 3. Draw Corridor Wall boundaries
      _drawWallBoundaries(canvas, size, f, roadOpacity);
    }

    if (isFloorDetected) {
      // 4. Draw Save Points & Beacons
      _drawQuestStructures(canvas, size, f);

      // 5. Draw Coins
      _drawCoins(canvas, size, f);

      // 6. Draw collection particle bursts
      _drawParticleBursts(canvas, size, f);
    }
  }

  void _drawFloorPlaneGrid(Canvas canvas, Size size, double f) {
    final gridPaint = Paint()
      ..color = Colors.cyan.withOpacity(0.08)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Generate horizontal and vertical floor lines around the user (z = -1.6)
    // We draw local X lines from -3m to +3m and local Y lines from 0 to +25m relative to user Y
    final double userFloorY = userPosition.y;

    // Horizontal grid lines (parallel to X axis) every 2.0 meters
    final double startY = (userFloorY / 2.0).floor() * 2.0;
    for (double gy = startY; gy <= userFloorY + _maxRenderDist; gy += 2.0) {
      final pA = _enuToCamera(Vector3(-2.5, gy, -1.6), userPosition, heading, pitch);
      final pB = _enuToCamera(Vector3(2.5, gy, -1.6), userPosition, heading, pitch);

      if (pA.dy > 0.1 && pB.dy > 0.1) {
        canvas.drawLine(_project(pA, f, size), _project(pB, f, size), gridPaint);
      }
    }

    // Vertical grid lines (parallel to Y axis) every 1.25 meters
    for (double gx = -2.5; gx <= 2.5; gx += 1.25) {
      final pA = _enuToCamera(Vector3(gx, userFloorY, -1.6), userPosition, heading, pitch);
      final pB = _enuToCamera(Vector3(gx, userFloorY + _maxRenderDist, -1.6), userPosition, heading, pitch);

      if (pA.dy > 0.1 && pB.dy > 0.1) {
        canvas.drawLine(_project(pA, f, size), _project(pB, f, size), gridPaint);
      }
    }
  }

  void _drawCorridorRoad(Canvas canvas, Size size, double f, double roadOpacity) {
    if (roadWaypoints.length < 2) return;

    final List<Offset> leftProjPoints = [];
    final List<Offset> rightProjPoints = [];
    final List<double> segmentDepths = [];

    // Calculate left/right coordinate vertices of corridor centerline
    for (int i = 0; i < roadWaypoints.length; i++) {
      final pt = roadWaypoints[i];
      
      // Interpolate tangent direction
      double perpX = -1.0;
      double perpY = 0.0;
      if (i < roadWaypoints.length - 1) {
        final next = roadWaypoints[i + 1];
        final dx = next.x - pt.x;
        final dy = next.y - pt.y;
        final len = sqrt(dx * dx + dy * dy);
        if (len > 0.1) {
          perpX = -dy / len;
          perpY = dx / len;
        }
      } else if (i > 0) {
        final prev = roadWaypoints[i - 1];
        final dx = pt.x - prev.x;
        final dy = pt.y - prev.y;
        final len = sqrt(dx * dx + dy * dy);
        if (len > 0.1) {
          perpX = -dy / len;
          perpY = dx / len;
        }
      }

      final leftPt = Vector3(
        pt.x + perpX * (_roadWidth / 2.0),
        pt.y + perpY * (_roadWidth / 2.0),
        -1.6, // anchored to floor
      );
      final rightPt = Vector3(
        pt.x - perpX * (_roadWidth / 2.0),
        pt.y - perpY * (_roadWidth / 2.0),
        -1.6,
      );

      final leftCam = _enuToCamera(leftPt, userPosition, heading, pitch);
      final rightCam = _enuToCamera(rightPt, userPosition, heading, pitch);

      final avgDepth = (leftCam.dy + rightCam.dy) / 2.0;
      if (avgDepth > _maxRenderDist) continue;

      leftProjPoints.add(_project(leftCam, f, size));
      rightProjPoints.add(_project(rightCam, f, size));
      segmentDepths.add(avgDepth);
    }

    if (leftProjPoints.length < 2) return;

    // Draw the roadway segments
    for (int i = 0; i < leftProjPoints.length - 1; i++) {
      final depth = segmentDepths[i];
      if (depth < 0.2) continue;

      final p1 = leftProjPoints[i];
      final p2 = rightProjPoints[i];
      final p3 = rightProjPoints[i + 1];
      final p4 = leftProjPoints[i + 1];

      // Poly mesh path
      final path = Path()
        ..moveTo(p1.dx, p1.dy)
        ..lineTo(p2.dx, p2.dy)
        ..lineTo(p3.dx, p3.dy)
        ..lineTo(p4.dx, p4.dy)
        ..close();

      final fade = (1.0 - (depth / _maxRenderDist)).clamp(0.0, 1.0);
      final finalOpacity = roadOpacity * fade;

      final fillPaint = Paint()
        ..color = AppColors.gold.withOpacity(finalOpacity * 0.22)
        ..style = PaintingStyle.fill;
      canvas.drawPath(path, fillPaint);

      // Bright glowing border lines
      final borderPaint = Paint()
        ..shader = LinearGradient(
          colors: [
            AppColors.gold.withOpacity(finalOpacity * 0.85),
            AppColors.goldDark.withOpacity(finalOpacity * 0.4),
          ],
        ).createShader(Rect.fromPoints(p1, p4))
        ..strokeWidth = (5.0 / (depth * 0.2 + 1.0)).clamp(1.5, 4.0)
        ..style = PaintingStyle.stroke;

      canvas.drawLine(p1, p4, borderPaint);
      canvas.drawLine(p2, p3, borderPaint);

      // Animate center line scrolling (scrolling UV overlay)
      final double dashLength = 30.0;
      final double dashOffset = animationValue * dashLength * 2.0;

      final centerStart = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
      final centerEnd = Offset((p3.dx + p4.dx) / 2, (p3.dy + p4.dy) / 2);

      final centerPaint = Paint()
        ..color = AppColors.text.withOpacity(finalOpacity * 0.8)
        ..strokeWidth = (2.0 / (depth * 0.2 + 1.0)).clamp(0.8, 2.0)
        ..style = PaintingStyle.stroke;

      _drawDashedLine(canvas, centerStart, centerEnd, centerPaint, dashLength, dashOffset);
    }
  }

  void _drawWallBoundaries(Canvas canvas, Size size, double f, double roadOpacity) {
    // Left boundary (X = -1.5) and Right boundary (X = 1.5) corridor boundaries
    // We draw columns or panels along the route to represent detected corridor walls
    final wallPaint = Paint()
      ..color = Colors.cyan.withOpacity(roadOpacity * 0.05)
      ..style = PaintingStyle.fill;
    
    final wirePaint = Paint()
      ..color = Colors.cyan.withOpacity(roadOpacity * 0.18)
      ..strokeWidth = 1.0;

    for (int i = 0; i < roadWaypoints.length - 1; i++) {
      final pA = roadWaypoints[i];
      final pB = roadWaypoints[i + 1];

      // Draw left wall panels
      _drawWallPanel(canvas, size, f, pA.x + RouteManager.leftWallX, pA.y, pB.x + RouteManager.leftWallX, pB.y, wallPaint, wirePaint);
      // Draw right wall panels
      _drawWallPanel(canvas, size, f, pA.x + RouteManager.rightWallX, pA.y, pB.x + RouteManager.rightWallX, pB.y, wallPaint, wirePaint);
    }
  }

  void _drawWallPanel(Canvas canvas, Size size, double f, double x1, double y1, double x2, double y2, Paint fill, Paint stroke) {
    // A wall is from Z = -1.6m (floor) to Z = 0.6m (ceiling-height of phone)
    final b1 = _enuToCamera(Vector3(x1, y1, -1.6), userPosition, heading, pitch);
    final t1 = _enuToCamera(Vector3(x1, y1, 0.6), userPosition, heading, pitch);
    final b2 = _enuToCamera(Vector3(x2, y2, -1.6), userPosition, heading, pitch);
    final t2 = _enuToCamera(Vector3(x2, y2, 0.6), userPosition, heading, pitch);

    if (b1.dy <= 0.1 || b2.dy <= 0.1 || t1.dy <= 0.1 || t2.dy <= 0.1) return;
    if (b1.dy > _maxRenderDist || b2.dy > _maxRenderDist) return;

    final pB1 = _project(b1, f, size);
    final pT1 = _project(t1, f, size);
    final pB2 = _project(b2, f, size);
    final pT2 = _project(t2, f, size);

    final panel = Path()
      ..moveTo(pB1.dx, pB1.dy)
      ..lineTo(pT1.dx, pT1.dy)
      ..lineTo(pT2.dx, pT2.dy)
      ..lineTo(pB2.dx, pB2.dy)
      ..close();

    canvas.drawPath(panel, fill);
    canvas.drawLine(pB1, pT1, stroke);
    canvas.drawLine(pB2, pT2, stroke);
    canvas.drawLine(pT1, pT2, stroke);
  }

  void _drawQuestStructures(Canvas canvas, Size size, double f) {
    for (final node in questNodes) {
      if (node.isCollected) continue;

      final double lx = node.localX ?? 0.0;
      final double ly = node.localY ?? 0.0;
      final double lz = node.localZ ?? -1.6;

      final depth = _enuToCamera(Vector3(lx, ly, lz), userPosition, heading, pitch).dy;
      if (depth <= 0.1 || depth > _maxRenderDist) continue;

      if (node.type == 'save_point') {
        _drawObelisk(canvas, size, f, lx, ly, lz, depth);
      } else if (node.type == 'beacon') {
        _drawDestinationBeacon(canvas, size, f, lx, ly, lz, depth);
      }
    }
  }

  void _drawObelisk(Canvas canvas, Size size, double f, double lx, double ly, double lz, double depth) {
    final baseCenter = _enuToCamera(Vector3(lx, ly, lz), userPosition, heading, pitch);
    final baseProj = _project(baseCenter, f, size);

    final double sizeScale = (1.5 / depth).clamp(0.05, 3.0);
    final double baseRadius = 24.0 * sizeScale;

    // Base glowing expanding rings
    final ringCount = 3;
    final baseOpacity = (1.0 - (depth / _maxRenderDist)).clamp(0.0, 1.0) * 0.4;

    for (int r = 0; r < ringCount; r++) {
      final progress = (animationValue + r / ringCount) % 1.0;
      final radius = baseRadius * (1.0 + progress * 1.5);
      final ringOpacity = (1.0 - progress) * baseOpacity;
      final flatHeight = radius * 0.35; // foreshortening

      final ringPaint = Paint()
        ..color = Colors.cyanAccent.withOpacity(ringOpacity)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;

      canvas.drawOval(
        Rect.fromCenter(center: baseProj, width: radius * 2.0, height: flatHeight * 2.0),
        ringPaint,
      );
    }

    // 3D Obelisk points (4 base points, 1 top apex point)
    final double w = 0.3; // obelisk width
    final basePoints = [
      Vector3(lx - w, ly - w, lz),
      Vector3(lx + w, ly - w, lz),
      Vector3(lx + w, ly + w, lz),
      Vector3(lx - w, ly + w, lz),
    ];

    final topEnu = Vector3(lx, ly, lz + 2.0); // 2.0 meters tall
    final topProj = _project(_enuToCamera(topEnu, userPosition, heading, pitch), f, size);

    final List<Offset> baseProjPoints = [];
    for (final bp in basePoints) {
      baseProjPoints.add(_project(_enuToCamera(bp, userPosition, heading, pitch), f, size));
    }

    final visibility = (1.0 - (depth / _maxRenderDist)).clamp(0.0, 1.0);
    final facePaint = Paint()..style = PaintingStyle.fill;
    final edgePaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(visibility)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < 4; i++) {
      final pA = baseProjPoints[i];
      final pB = baseProjPoints[(i + 1) % 4];

      final facePath = Path()
        ..moveTo(topProj.dx, topProj.dy)
        ..lineTo(pA.dx, pA.dy)
        ..lineTo(pB.dx, pB.dy)
        ..close();

      final double shading = 0.2 + 0.15 * sin(animationValue * 2 * pi + i * pi / 2);
      facePaint.color = Color.fromARGB(
        (visibility * 255).round(),
        (0x13 * shading + 0x05).round().clamp(0, 255),
        (0x56 * shading + 0x1A).round().clamp(0, 255),
        (0x8B * shading + 0x30).round().clamp(0, 255),
      );

      canvas.drawPath(facePath, facePaint);
      canvas.drawPath(facePath, edgePaint);
    }

    // Float Core Crystal
    final double floatDispl = sin(animationValue * 4.0 * pi) * 0.1;
    final crystalEnu = Vector3(lx, ly, lz + 2.4 + floatDispl);
    final crystalCam = _enuToCamera(crystalEnu, userPosition, heading, pitch);
    if (crystalCam.dy > 0.1) {
      final crystalProj = _project(crystalCam, f, size);
      final double crystalR = 10.0 * sizeScale;

      final crystalPath = Path()
        ..moveTo(crystalProj.dx, crystalProj.dy - crystalR)
        ..lineTo(crystalProj.dx + crystalR * 0.6, crystalProj.dy)
        ..lineTo(crystalProj.dx, crystalProj.dy + crystalR)
        ..lineTo(crystalProj.dx - crystalR * 0.6, crystalProj.dy)
        ..close();

      final corePaint = Paint()
        ..color = Colors.cyan.shade100.withOpacity(visibility)
        ..style = PaintingStyle.fill;
      final glowPaint = Paint()
        ..color = Colors.cyanAccent.withOpacity(visibility * 0.5)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8.0 * sizeScale);

      canvas.drawPath(crystalPath, glowPaint);
      canvas.drawPath(crystalPath, corePaint);
    }
  }

  void _drawDestinationBeacon(Canvas canvas, Size size, double f, double lx, double ly, double lz, double depth) {
    // A Destination Beacon is a massive glowing beacon of light extending from the floor to the sky!
    final bCam = _enuToCamera(Vector3(lx, ly, lz), userPosition, heading, pitch);
    final tCam = _enuToCamera(Vector3(lx, ly, lz + 8.0), userPosition, heading, pitch); // 8m tall beam

    if (bCam.dy <= 0.1 || tCam.dy <= 0.1) return;

    final pBase = _project(bCam, f, size);
    final pTop = _project(tCam, f, size);

    final double sizeScale = (1.5 / depth).clamp(0.05, 3.0);
    final double beamWidth = 48.0 * sizeScale;
    final double opacity = (1.0 - (depth / _maxRenderDist)).clamp(0.0, 1.0);

    // Glowing core beam
    final corePaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(opacity * 0.75)
      ..strokeWidth = beamWidth * 0.4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    // Outer glow halo
    final glowPaint = Paint()
      ..color = Colors.cyan.shade200.withOpacity(opacity * 0.3)
      ..strokeWidth = beamWidth
      ..strokeCap = StrokeCap.round
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 12.0 * sizeScale)
      ..style = PaintingStyle.stroke;

    canvas.drawLine(pBase, pTop, glowPaint);
    canvas.drawLine(pBase, pTop, corePaint);

    // Draw particle circles orbiting the beacon
    final orbitPaint = Paint()
      ..color = Colors.cyanAccent.withOpacity(opacity * 0.7)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final orbitRadius = beamWidth * 0.8;
    for (int j = 0; j < 3; j++) {
      final double progress = (animationValue * 1.5 + j / 3.0) % 1.0;
      final Offset centerPos = Offset(
        pBase.dx + (pTop.dx - pBase.dx) * (progress * 0.8),
        pBase.dy + (pTop.dy - pBase.dy) * (progress * 0.8),
      );

      final double width = orbitRadius * cos(animationValue * 4.0 * pi + j);
      canvas.drawOval(
        Rect.fromCenter(center: centerPos, width: width, height: orbitRadius * 0.3),
        orbitPaint,
      );
    }
  }

  void _drawCoins(Canvas canvas, Size size, double f) {
    for (final node in questNodes) {
      if (node.type != 'coin' || node.isCollected) continue;

      final double lx = node.localX ?? 0.0;
      final double ly = node.localY ?? 0.0;
      final double lz = node.localZ ?? -0.4; // float height

      final double bob = sin(animationValue * 4.0 * pi + lx) * 0.12;
      final cam = _enuToCamera(Vector3(lx, ly, lz + bob), userPosition, heading, pitch);
      
      final depth = cam.dy;
      if (depth <= 0.1 || depth > _maxRenderDist) continue;

      final proj = _project(cam, f, size);
      final double sizeScale = (1.5 / depth).clamp(0.05, 3.0);
      final double coinR = 26.0 * sizeScale;
      final double opacity = (1.0 - (depth / _maxRenderDist)).clamp(0.0, 1.0);

      // Y-axis spinning width
      final spinAngle = animationValue * 3.5 * pi + lx * 100.0;
      final spinWidth = coinR * 2.0 * cos(spinAngle).abs();
      final isFacingEdge = cos(spinAngle).abs() < 0.15;

      // Outer glow
      final glow = Paint()
        ..color = AppColors.gold.withOpacity(opacity * 0.4)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 10.0 * sizeScale);
      canvas.drawCircle(proj, coinR * 1.3, glow);

      // Coin cylinder body
      final rect = Rect.fromCenter(center: proj, width: spinWidth, height: coinR * 2.0);
      final fill = Paint()
        ..shader = RadialGradient(
          colors: [AppColors.gold, AppColors.goldDark],
          stops: const [0.3, 1.0],
          center: Alignment(sin(spinAngle) * 0.4, -0.4),
        ).createShader(rect)
        ..style = PaintingStyle.fill;
      canvas.drawOval(rect, fill);

      // Coin Inner Ring & details
      if (!isFacingEdge) {
        final innerRect = Rect.fromCenter(center: proj, width: spinWidth * 0.75, height: coinR * 1.5);
        final innerPaint = Paint()
          ..color = AppColors.goldDark.withOpacity(opacity * 0.75)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5 * sizeScale;
        canvas.drawOval(innerRect, innerPaint);

        // Chola Gold symbol 'T'
        final textScale = coinR * 0.4;
        final symbolPath = Path()
          ..moveTo(proj.dx - textScale * cos(spinAngle).abs(), proj.dy - textScale)
          ..lineTo(proj.dx + textScale * cos(spinAngle).abs(), proj.dy - textScale)
          ..lineTo(proj.dx + textScale * cos(spinAngle).abs(), proj.dy - textScale * 0.6)
          ..lineTo(proj.dx + textScale * 0.25 * cos(spinAngle).abs(), proj.dy - textScale * 0.6)
          ..lineTo(proj.dx + textScale * 0.25 * cos(spinAngle).abs(), proj.dy + textScale * 0.9)
          ..lineTo(proj.dx - textScale * 0.25 * cos(spinAngle).abs(), proj.dy + textScale * 0.9)
          ..lineTo(proj.dx - textScale * 0.25 * cos(spinAngle).abs(), proj.dy - textScale * 0.6)
          ..lineTo(proj.dx - textScale * cos(spinAngle).abs(), proj.dy - textScale * 0.6)
          ..close();

        final symPaint = Paint()
          ..color = AppColors.goldDark.withOpacity(opacity * 0.9)
          ..style = PaintingStyle.fill;
        canvas.drawPath(symbolPath, symPaint);
      }
    }
  }

  void _drawParticleBursts(Canvas canvas, Size size, double f) {
    for (final burst in particleBursts) {
      final cam = _enuToCamera(Vector3(burst.x, burst.y, burst.z), userPosition, heading, pitch);
      if (cam.dy <= 0.1 || cam.dy > _maxRenderDist) continue;

      final proj = _project(cam, f, size);
      final double sizeScale = (1.5 / cam.dy).clamp(0.05, 3.0);

      final paint = Paint()..style = PaintingStyle.fill;
      for (final p in burst.particles) {
        paint.color = burst.color.withOpacity(p.opacity);
        canvas.drawCircle(
          Offset(proj.dx + p.dx * sizeScale, proj.dy + p.dy * sizeScale),
          p.radius * sizeScale,
          paint,
        );
      }
    }
  }

  // Math translation matrix (VIO relative)

  _CameraCoord _enuToCamera(Vector3 pt, Vector3 ref, double yawDeg, double pitchDeg) {
    // Relative coordinates
    final double dx = pt.x - ref.x;
    final double dy = pt.y - ref.y;
    final double dz = pt.z - ref.z;

    final double yawRad = yawDeg * pi / 180.0;
    final double pitchRad = pitchDeg * pi / 180.0;

    // Yaw rotation around Z (Yaw)
    final double x1 = dx * cos(yawRad) - dy * sin(yawRad);
    final double y1 = dx * sin(yawRad) + dy * cos(yawRad);
    final double z1 = dz;

    // Pitch rotation around X (Pitch)
    final double camX = x1;
    final double camY = y1 * cos(pitchRad) + z1 * sin(pitchRad);
    final double camZ = -y1 * sin(pitchRad) + z1 * cos(pitchRad);

    return _CameraCoord(camX, camY, camZ);
  }

  Offset _project(_CameraCoord cam, double f, Size size) {
    if (cam.dy <= 0.05) {
      return const Offset(-9999.0, -9999.0);
    }
    final double screenX = size.width / 2.0 + (cam.dx / cam.dy) * f;
    final double screenY = size.height / 2.0 - (cam.dz / cam.dy) * f;
    return Offset(screenX, screenY);
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint, double dashWidth, double offset) {
    final double dx = p2.dx - p1.dx;
    final double dy = p2.dy - p1.dy;
    final double distance = sqrt(dx * dx + dy * dy);
    
    if (distance < 1.0) return;

    final double uX = dx / distance;
    final double uY = dy / distance;

    double currentDist = -offset % (dashWidth * 2);
    while (currentDist < distance) {
      final double start = max(0.0, currentDist);
      final double end = min(distance, currentDist + dashWidth);
      if (start < end) {
        canvas.drawLine(
          Offset(p1.dx + uX * start, p1.dy + uY * start),
          Offset(p1.dx + uX * end, p1.dy + uY * end),
          paint,
        );
      }
      currentDist += dashWidth * 2;
    }
  }

  @override
  bool shouldRepaint(covariant ArPainter oldDelegate) {
    return oldDelegate.heading != heading ||
        oldDelegate.pitch != pitch ||
        oldDelegate.userPosition != userPosition ||
        oldDelegate.animationValue != animationValue ||
        oldDelegate.isFloorDetected != isFloorDetected ||
        oldDelegate.particleBursts.length != particleBursts.length;
  }
}

// Struct containers

class _CameraCoord {
  final double dx;
  final double dy;
  final double dz;
  const _CameraCoord(this.dx, this.dy, this.dz);
}

class _ParticleBurst {
  final double x;
  final double y;
  final double z;
  final Color color;
  final DateTime spawnTime;
  final List<_Particle> particles = [];

  _ParticleBurst({
    required this.x,
    required this.y,
    required this.z,
    required this.color,
    required this.spawnTime,
  }) {
    final random = Random();
    for (int i = 0; i < 24; i++) {
      final angle = random.nextDouble() * 2 * pi;
      final speed = random.nextDouble() * 60.0 + 20.0;
      particles.add(
        _Particle(
          vx: cos(angle) * speed,
          vy: sin(angle) * speed - (random.nextDouble() * 12.0),
          radius: random.nextDouble() * 4.0 + 1.5,
        ),
      );
    }
  }

  void update() {
    final double dt = 0.05;
    for (final p in particles) {
      p.dx += p.vx * dt;
      p.dy += p.vy * dt;
      p.vy += 20.0 * dt;
      p.opacity = max(0.0, p.opacity - 0.045);
    }
  }
}

class _Particle {
  double dx = 0.0;
  double dy = 0.0;
  final double vx;
  double vy;
  final double radius;
  double opacity = 1.0;

  _Particle({
    required this.vx,
    required this.vy,
    required this.radius,
  });
}
