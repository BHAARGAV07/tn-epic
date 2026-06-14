import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import 'road_view_screen.dart';

class PlanTripScreen extends StatefulWidget {
  const PlanTripScreen({super.key});

  @override
  State<PlanTripScreen> createState() => _PlanTripScreenState();
}

class _PlanTripScreenState extends State<PlanTripScreen> {
  int _days = 1;

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
                  const _DestinationsCard(),
                ],
              ),
            ),
          ),
          const _StickyStartArea(),
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

class _DestinationsCard extends StatelessWidget {
  const _DestinationsCard();

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
                    '0/10 selected',
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
          TextField(
            cursorColor: AppColors.gold,
            style: GoogleFonts.inter(
              color: AppColors.text,
              fontFeatures: const [FontFeature.enable('kern')],
            ),
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.statCard,
              hintText: 'Search destinations...',
              hintStyle: GoogleFonts.inter(
                color: AppColors.secondary,
                fontFeatures: const [FontFeature.enable('kern')],
              ),
              prefixIcon: const Icon(Icons.search, color: AppColors.secondary),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.fieldBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.gold),
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Icon(
            Icons.location_on_outlined,
            color: AppColors.secondary,
            size: 40,
          ),
          const SizedBox(height: 8),
          Text(
            'Search and add destinations to your trip',
            textAlign: TextAlign.center,
            softWrap: true,
            overflow: TextOverflow.visible,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.secondary,
              fontFeatures: const [FontFeature.enable('kern')],
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
//                     color: AppColors.gold.withValues(alpha: 0.3),
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
  const _StickyStartArea();

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
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const RoadViewScreen(),
                  ),
                );
              },
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
            const SizedBox(height: 8),
            Text(
              'Select at least one destination',
              textAlign: TextAlign.center,
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
