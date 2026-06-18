import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import '../state/app_state.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _nameController = TextEditingController();
  int _currentPage = 0;
  int _selectedAvatar = 0;

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  void _enterQuest() {
    final explorerName = _nameController.text.trim();

    if (explorerName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.card,
          content: Text(
            'Please enter your explorer name!',
            style: GoogleFonts.inter(color: AppColors.accent),
          ),
        ),
      );
      return;
    }

    AppState.explorerName = explorerName;
    AppState.avatarIndex = _selectedAvatar;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const HomeScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.topGradientStart, AppColors.background],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
            child: Column(
              children: [
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (page) {
                      setState(() {
                        _currentPage = page;
                      });
                    },
                    children: [
                      const _WelcomePage(),
                      const _HowItWorksPage(),
                      _ExplorerNamePage(
                        nameController: _nameController,
                        selectedAvatar: _selectedAvatar,
                        onAvatarSelected: (index) {
                          setState(() {
                            _selectedAvatar = index;
                          });
                        },
                      ),
                    ],
                  ),
                ),
                _DotIndicator(currentPage: _currentPage),
                const SizedBox(height: 24),
                _GradientCtaButton(
                  label: _currentPage == 2
                      ? 'Enter the Quest \u2192'
                      : 'Next \u2192',
                  height: _currentPage == 2 ? 56 : 54,
                  radius: _currentPage == 2 ? 16 : 14,
                  shadowOpacity: _currentPage == 2 ? 0.35 : 0,
                  onPressed: _currentPage == 2 ? _enterQuest : _nextPage,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _WelcomePage extends StatelessWidget {
  const _WelcomePage();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text('\u{1F3DB}\uFE0F', style: TextStyle(fontSize: 80)),
        const SizedBox(height: 28),
        Text(
          'Welcome to TN-Epic',
          textAlign: TextAlign.center,
          style: GoogleFonts.cinzel(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.gold,
          ),
        ),
        const SizedBox(height: 18),
        Text(
          "Tamil Nadu's ancient wonders are now\n"
          'your personal quest board.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 15,
            height: 1.6,
            color: AppColors.hint,
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'Walk. Collect. Conquer History.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: AppColors.teal,
            letterSpacing: 3,
          ),
        ),
      ],
    );
  }
}

class _HowItWorksPage extends StatelessWidget {
  const _HowItWorksPage();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'How Your Quest Works',
          textAlign: TextAlign.center,
          style: GoogleFonts.cinzel(fontSize: 24, color: AppColors.gold),
        ),
        const SizedBox(height: 28),
        const _FeatureCard(
          icon: '\u{1F5FA}\uFE0F',
          title: 'Follow the Golden Path',
          description: 'AR arrows guide you through\nancient temple streets.',
        ),
        const SizedBox(height: 16),
        const _FeatureCard(
          icon: '\u26A1',
          title: 'Collect Quest Tokens',
          description: 'Walk to glowing spots and\ncollect digital relics.',
        ),
        const SizedBox(height: 16),
        const _FeatureCard(
          icon: '\u{1F3C6}',
          title: 'Earn Dharma Points',
          description: 'Visit local shops and smart\nbins to boost your score.',
        ),
      ],
    );
  }
}

class _FeatureCard extends StatelessWidget {
  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
  });

  final String icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.gold.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 32)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.cinzel(
                    fontSize: 15,
                    color: AppColors.accent,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  description,
                  style: GoogleFonts.inter(fontSize: 12, color: AppColors.hint),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ExplorerNamePage extends StatelessWidget {
  const _ExplorerNamePage({
    required this.nameController,
    required this.selectedAvatar,
    required this.onAvatarSelected,
  });

  final TextEditingController nameController;
  final int selectedAvatar;
  final ValueChanged<int> onAvatarSelected;

  static const List<({String emoji, String label})> _avatars = [
    (emoji: '\u{1F9ED}', label: 'Explorer'),
    (emoji: '\u2694\uFE0F', label: 'Warrior'),
    (emoji: '\u{1F531}', label: 'Chola'),
    (emoji: '\u{1F30A}', label: 'Sailor'),
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height - 188,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('\u2694\uFE0F', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 18),
            Text(
              'Name Your Explorer',
              textAlign: TextAlign.center,
              style: GoogleFonts.cinzel(fontSize: 26, color: AppColors.gold),
            ),
            const SizedBox(height: 14),
            Text(
              "This is how you'll appear on the\n"
              'leaderboard of Tamil Nadu.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.hint),
            ),
            const SizedBox(height: 30),
            Container(
              height: 58,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: AppColors.gold.withOpacity(0.25),
                ),
              ),
              child: TextField(
                controller: nameController,
                maxLength: 20,
                textAlign: TextAlign.center,
                cursorColor: AppColors.accent,
                style: GoogleFonts.inter(fontSize: 16, color: AppColors.text),
                decoration: InputDecoration(
                  hintText: 'e.g. Chola_Warrior_99',
                  hintStyle: GoogleFonts.inter(
                    color: AppColors.hint.withOpacity(0.5),
                  ),
                  border: InputBorder.none,
                  counterStyle: GoogleFonts.inter(
                    color: AppColors.hint.withOpacity(0.4),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 28),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Pick your avatar',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.hint),
              ),
            ),
            const SizedBox(height: 14),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (var index = 0; index < _avatars.length; index++)
                    Padding(
                      padding: EdgeInsets.only(
                        right: index == _avatars.length - 1 ? 0 : 16,
                      ),
                      child: _AvatarOption(
                        emoji: _avatars[index].emoji,
                        label: _avatars[index].label,
                        isSelected: selectedAvatar == index,
                        onTap: () => onAvatarSelected(index),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarOption extends StatelessWidget {
  const _AvatarOption({
    required this.emoji,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String emoji;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected
                  ? AppColors.accent.withOpacity(0.2)
                  : AppColors.card,
              border: Border.all(
                color: isSelected
                    ? AppColors.accent
                    : AppColors.gold.withOpacity(0.2),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Center(
              child: Text(emoji, style: const TextStyle(fontSize: 30)),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 10, color: AppColors.hint),
          ),
        ],
      ),
    );
  }
}

class _DotIndicator extends StatelessWidget {
  const _DotIndicator({required this.currentPage});

  final int currentPage;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var index = 0; index < 3; index++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.symmetric(horizontal: 4),
            width: currentPage == index ? 24 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: currentPage == index
                  ? AppColors.accent
                  : AppColors.gold.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
      ],
    );
  }
}

class _GradientCtaButton extends StatelessWidget {
  const _GradientCtaButton({
    required this.label,
    required this.height,
    required this.radius,
    required this.shadowOpacity,
    required this.onPressed,
  });

  final String label;
  final double height;
  final double radius;
  final double shadowOpacity;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.accent, AppColors.buttonEnd],
          ),
          borderRadius: BorderRadius.circular(radius),
          boxShadow: shadowOpacity == 0
              ? null
              : [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(shadowOpacity),
                    blurRadius: 20,
                  ),
                ],
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            foregroundColor: AppColors.background,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(radius),
            ),
          ),
          child: Text(
            label,
            style: GoogleFonts.cinzel(
              fontSize: label.startsWith('Enter') ? 16 : 15,
              fontWeight: FontWeight.bold,
              color: AppColors.background,
            ),
          ),
        ),
      ),
    );
  }
}
