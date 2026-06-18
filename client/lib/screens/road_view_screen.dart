import 'dart:async';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:lottie/lottie.dart';

import '../constants/app_colors.dart';
import '../models/destination.dart';
import '../models/quest_node.dart';
import '../models/vector3.dart';
import '../services/route_manager.dart';
import '../state/app_state.dart';
import '../widgets/ar_viewport.dart';

class RoadViewScreen extends StatefulWidget {
  final LatLng startLocation;
  final List<Destination> destinations;

  const RoadViewScreen({
    super.key,
    required this.startLocation,
    required this.destinations,
  });

  @override
  State<RoadViewScreen> createState() => _RoadViewScreenState();
}

class _RoadViewScreenState extends State<RoadViewScreen> with TickerProviderStateMixin {
  CameraController? _cameraController;
  Future<void>? _initializeCameraFuture;

  // VIO Cartesian coordinates
  Vector3 _userPosition = const Vector3(0.0, 0.0, 0.0);
  final List<Vector3> _routeWaypoints = RouteManager.getCorridorRoute();
  final List<QuestNode> _questNodes = RouteManager.getCorridorQuestNodes();

  // Floor scanning simulator
  bool _isFloorDetected = false;
  double _scanProgress = 0.0;
  Timer? _scanTimer;

  bool _isLoading = true;
  String _loadingStatus = "Initializing Camera & Gyro bindings...";

  // UI state for coin collection feedback
  bool _showCollectBanner = false;
  QuestNode? _lastCollectedNode;
  late AnimationController _bannerAnimationController;

  @override
  void initState() {
    super.initState();
    _bannerAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _initCamera();
    _startFloorScanning();
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        setState(() {
          _loadingStatus = "No cameras found";
        });
        return;
      }

      _cameraController = CameraController(
        cameras.first,
        ResolutionPreset.high,
        enableAudio: false,
      );

      _initializeCameraFuture = _cameraController!.initialize();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Camera Init Error: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _startFloorScanning() {
    // Simulate floor scan radar
    _scanTimer = Timer.periodic(const Duration(milliseconds: 30), (timer) {
      setState(() {
        _scanProgress += 0.04;
        if (_scanProgress >= 1.0) {
          _isFloorDetected = true;
          _scanTimer?.cancel();
        }
      });
    });
  }

  void _onCollectNode(QuestNode node) {
    setState(() {
      _lastCollectedNode = node;
      _showCollectBanner = true;
      
      // Update global game scores
      if (node.type == 'coin') {
        AppState.totalTokens += node.value;
        AppState.dharmaScore += (node.value * 1.5).round();
      } else if (node.type == 'save_point') {
        AppState.dharmaScore += 120;
      } else if (node.type == 'beacon') {
        AppState.totalTokens += node.value;
        AppState.dharmaScore += (node.value * 2.0).round();
        AppState.tripsCompleted += 1;
      }
    });

    _bannerAnimationController.forward(from: 0.0);

    // Fade out collected overlay banner after 2.5 seconds
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        setState(() {
          _showCollectBanner = false;
        });
      }
    });
  }

  void _onLocationChanged(Vector3 newPosition) {
    setState(() {
      _userPosition = newPosition;
    });
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _scanTimer?.cancel();
    _bannerAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: AppColors.gold),
              const SizedBox(height: 24),
              Text(
                _loadingStatus,
                style: GoogleFonts.inter(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      body: Stack(
        children: [
          // 1. Full-screen Camera Stream
          Positioned.fill(
            child: FutureBuilder<void>(
              future: _initializeCameraFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done &&
                    _cameraController != null &&
                    _cameraController!.value.isInitialized) {
                  return CameraPreview(_cameraController!);
                }
                return Container(
                  color: Colors.black87,
                  child: const Center(
                    child: Icon(Icons.camera_enhance, color: AppColors.secondary, size: 64),
                  ),
                );
              },
            ),
          ),

          // 2. AR Viewport Core Canvas overlay
          Positioned.fill(
            child: ArViewport(
              userPosition: _userPosition,
              roadWaypoints: _routeWaypoints,
              questNodes: _questNodes,
              onCollectQuestNode: _onCollectNode,
              onLocationChanged: _onLocationChanged,
              isFloorDetected: _isFloorDetected,
              scanProgress: _scanProgress,
            ),
          ),

          // 3. Sci-Fi HUD overlays
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _buildHUDHeader(context),
          ),

          // 4. Proximity Collection Celebration Popup
          if (_showCollectBanner && _lastCollectedNode != null)
            Positioned.fill(
              child: _buildRewardPopup(_lastCollectedNode!),
            ),
        ],
      ),
    );
  }

  Widget _buildHUDHeader(BuildContext context) {
    // Calculate distance remaining to final waypoint
    final endPoint = _routeWaypoints.isNotEmpty ? _routeWaypoints.last : const Vector3(12.0, 12.0, -1.6);
    final distRemaining = _userPosition.distanceTo(endPoint);
    
    // Count collected save points
    final checkpointsCollected = _questNodes.where((n) => n.type == 'save_point' && n.isCollected).length;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black.withOpacity(0.8),
            Colors.transparent,
          ],
        ),
      ),
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        bottom: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Exit button
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.background.withOpacity(0.75),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.navBorder, width: 1.5),
                  ),
                  child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                ),
              ),

              // VIO Status HUD Card
              Expanded(
                child: Container(
                  height: 44,
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: AppColors.background.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.navBorder, width: 1.5),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _isFloorDetected ? Icons.check_circle_outline_rounded : Icons.sync,
                        color: _isFloorDetected ? Colors.cyanAccent : AppColors.gold,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _isFloorDetected ? 'FLOOR TRACKED • INDOOR AR' : 'CALIBRATING AR VIO...',
                        style: GoogleFonts.inter(
                          color: _isFloorDetected ? Colors.cyanAccent : AppColors.gold,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Dharma & Tokens Score
              Container(
                height: 44,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.background.withOpacity(0.75),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.navBorder, width: 1.5),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.monetization_on_rounded, color: AppColors.gold, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '${AppState.totalTokens}',
                      style: GoogleFonts.jetBrainsMono(
                        color: AppColors.text,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.offline_bolt_rounded, color: Colors.cyanAccent, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      '${AppState.dharmaScore}',
                      style: GoogleFonts.jetBrainsMono(
                        color: AppColors.text,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Additional Corridor navigation telemetry overlay
          if (_isFloorDetected) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Distance to Destination
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.background.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.navBorder, width: 1.0),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.flag_outlined, color: Colors.cyanAccent, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Destination: ${distRemaining.toStringAsFixed(1)}m',
                        style: GoogleFonts.inter(
                          color: AppColors.text,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                // Checkpoint progress
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.background.withOpacity(0.75),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.navBorder, width: 1.0),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.security, color: AppColors.gold, size: 14),
                      const SizedBox(width: 6),
                      Text(
                        'Checkpoints: $checkpointsCollected/2',
                        style: GoogleFonts.inter(
                          color: AppColors.text,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRewardPopup(QuestNode node) {
    final isCoin = node.type == 'coin';
    final isBeacon = node.type == 'beacon';
    
    String titleText = 'CHOLA GOLD DISCOVERED!';
    if (node.type == 'save_point') {
      titleText = 'CHECKPOINT SECURED!';
    } else if (isBeacon) {
      titleText = 'SANCTUARY REACHED!';
    }

    Color glowColor = AppColors.gold;
    if (node.type == 'save_point') {
      glowColor = Colors.cyan;
    } else if (isBeacon) {
      glowColor = Colors.cyanAccent;
    }

    return Container(
      color: Colors.black.withOpacity(0.4),
      child: Center(
        child: ScaleTransition(
          scale: CurvedAnimation(
            parent: _bannerAnimationController,
            curve: Curves.elasticOut,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Lottie Animation Burst (network loader with offline canvas placeholder)
              SizedBox(
                width: 200,
                height: 200,
                child: Lottie.network(
                  isBeacon
                      ? 'https://lottie.host/17b9b7e7-3b96-48ee-a616-24faea9f6c04/Oshf4FzIsk.json' // Trophy/Success burst
                      : (isCoin 
                          ? 'https://lottie.host/5a0928be-c6e0-4a81-bd56-c73ceb7f14b6/3qUa4FpZ3A.json' // Coin explosion
                          : 'https://lottie.host/461751db-043e-46cf-abfb-94f4d2f07fa1/3sD3X3o25i.json'), // Checkpoint blast
                  errorBuilder: (context, error, stackTrace) {
                    return Center(
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: glowColor.withOpacity(0.2),
                          border: Border.all(
                            color: glowColor,
                            width: 2.5,
                          ),
                        ),
                        child: Icon(
                          isBeacon
                              ? Icons.flag_circle_rounded
                              : (isCoin ? Icons.monetization_on : Icons.security),
                          color: glowColor,
                          size: 48,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),
              
              // Glassmorphism Reward Banner
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: AppColors.background.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: glowColor,
                    width: 2.0,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: glowColor.withOpacity(0.3),
                      blurRadius: 24,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      titleText,
                      style: GoogleFonts.inter(
                        color: glowColor,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      node.name,
                      style: GoogleFonts.inter(
                        color: AppColors.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (node.value > 0) ...[
                          const Icon(Icons.monetization_on_rounded, color: AppColors.gold, size: 20),
                          const SizedBox(width: 6),
                          Text(
                            '+${node.value} Tokens',
                            style: GoogleFonts.jetBrainsMono(
                              color: AppColors.text,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 16),
                        ],
                        const Icon(Icons.offline_bolt_rounded, color: Colors.cyanAccent, size: 20),
                        const SizedBox(width: 6),
                        Text(
                          isBeacon
                              ? '+${(node.value * 2.0).round()} Dharma'
                              : (isCoin ? '+${(node.value * 1.5).round()} Dharma' : '+120 Dharma'),
                          style: GoogleFonts.jetBrainsMono(
                            color: AppColors.text,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
