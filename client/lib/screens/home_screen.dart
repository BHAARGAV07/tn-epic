import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../state/app_state.dart';
import '../widgets/bottom_nav_bar.dart';
import 'ar_filter_screen.dart';
import 'memories_screen.dart';
import 'plan_trip_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _HomeTab(),
          ArFilterScreen(),
          MemoriesScreen(),
          ProfileScreen(),
        ],
      ),
      bottomNavigationBar: TnEpicBottomNavBar(
        selectedIndex: _selectedIndex,
        onTabSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
      ),
    );
  }
}

class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  int _selectedTripTab = 0;

  @override
  Widget build(BuildContext context) {
    final explorerName = AppState.explorerName.isEmpty
        ? 'Explorer'
        : AppState.explorerName;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _TopBar(explorerName: explorerName),
            const SizedBox(height: 20),
            Text(
              'Welcome Back, $explorerName!',
              softWrap: true,
              overflow: TextOverflow.visible,
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppColors.text,
                fontFeatures: const [FontFeature.enable('kern')],
              ),
            ),
            const SizedBox(height: 16),
            const _StatsCard(),
            const SizedBox(height: 20),
            _TripTabs(
              selectedTab: _selectedTripTab,
              onChanged: (tab) {
                setState(() {
                  _selectedTripTab = tab;
                });
              },
            ),
            const SizedBox(height: 12),
            _selectedTripTab == 0
                ? const _TripEmptyState(
                    icon: Icons.location_on_outlined,
                    title: 'No Active Trip',
                    subtitle: 'Start your heritage journey',
                    showButton: true,
                  )
                : const _TripEmptyState(
                    icon: Icons.check_circle_outline,
                    title: 'No Completed Trips',
                    subtitle: 'Finish a quest to see it here',
                  ),
          ],
        ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.explorerName});

  final String explorerName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Row(
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.statCard,
                    border: Border.all(color: AppColors.gold, width: 2),
                  ),
                  child: const Center(
                    child: Text(
                      '\u{1F9D9}',
                      softWrap: true,
                      overflow: TextOverflow.visible,
                      style: TextStyle(fontSize: 28),
                    ),
                  ),
                ),
                Positioned(
                  left: -2,
                  bottom: -2,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.gold,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Lv${AppState.level}',
                      softWrap: true,
                      overflow: TextOverflow.visible,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: AppColors.background,
                        fontFeatures: const [FontFeature.enable('kern')],
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  explorerName,
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
                  'Level ${AppState.level}',
                  softWrap: true,
                  overflow: TextOverflow.visible,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.gold,
                    fontFeatures: const [FontFeature.enable('kern')],
                  ),
                ),
              ],
            ),
          ],
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.statCard,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.gold.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.monetization_on_rounded,
                color: AppColors.gold,
                size: 18,
              ),
              const SizedBox(width: 4),
              Text(
                '${AppState.totalTokens}',
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
      ],
    );
  }
}

class _StatsCard extends StatelessWidget {
  const _StatsCard();

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
                  Icons.local_fire_department_rounded,
                  color: AppColors.background,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Stats',
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
                    'Civic Karma',
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
          Row(
            children: const [
              Expanded(
                child: _StatBox(
                  value: '0%',
                  label: 'Dharma Score',
                  valueColor: AppColors.gold,
                ),
              ),
              Expanded(
                child: _StatBox(value: '0', label: 'Total Tokens'),
              ),
              Expanded(
                child: _StatBox(value: '0', label: 'Trips\nCompleted'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  const _StatBox({
    required this.value,
    required this.label,
    this.valueColor = AppColors.text,
  });

  final String value;
  final String label;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.statCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            softWrap: true,
            overflow: TextOverflow.visible,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: valueColor,
              fontFeatures: const [FontFeature.enable('kern')],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            softWrap: true,
            overflow: TextOverflow.visible,
            maxLines: label.contains('\n') ? 2 : null,
            style: GoogleFonts.inter(
              fontSize: 11,
              color: AppColors.secondary,
              fontFeatures: const [FontFeature.enable('kern')],
            ),
          ),
        ],
      ),
    );
  }
}

class _TripTabs extends StatelessWidget {
  const _TripTabs({required this.selectedTab, required this.onChanged});

  final int selectedTab;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          _TripTabButton(
            label: 'Current Trip',
            isSelected: selectedTab == 0,
            onTap: () => onChanged(0),
          ),
          _TripTabButton(
            label: 'Completed Trips',
            isSelected: selectedTab == 1,
            onTap: () => onChanged(1),
          ),
        ],
      ),
    );
  }
}

class _TripTabButton extends StatelessWidget {
  const _TripTabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 44,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.gold : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              softWrap: true,
              overflow: TextOverflow.visible,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.background : AppColors.secondary,
                fontFeatures: const [FontFeature.enable('kern')],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TripEmptyState extends StatelessWidget {
  const _TripEmptyState({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.showButton = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool showButton;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.navBorder),
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.statCard,
            ),
            child: Icon(icon, color: AppColors.secondary, size: 28),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            softWrap: true,
            overflow: TextOverflow.visible,
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.text,
              fontFeatures: const [FontFeature.enable('kern')],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            softWrap: true,
            overflow: TextOverflow.visible,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.secondary,
              fontFeatures: const [FontFeature.enable('kern')],
            ),
          ),
          if (showButton) ...[
            const SizedBox(height: 24),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (_) => const PlanTripScreen(),
                  ),
                );
              },
              child: Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.gold, AppColors.goldDark],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.gold.withOpacity(0.3),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.add,
                      color: AppColors.background,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'START NEW TRIP',
                      softWrap: true,
                      overflow: TextOverflow.visible,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: AppColors.background,
                        fontFeatures: const [FontFeature.enable('kern')],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
