import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_colors.dart';
import 'onboarding_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;

  void _goOnboarding() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const OnboardingScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    children: [
                      Expanded(
                        child: Container(
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                AppColors.topGradientStart,
                                AppColors.background,
                              ],
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'TN-EPIC',
                                style: GoogleFonts.cinzel(
                                  fontSize: 40,
                                  color: AppColors.gold,
                                  letterSpacing: 8,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Your Quest Awaits',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: AppColors.teal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      _LoginCard(
                        obscurePassword: _obscurePassword,
                        onTogglePassword: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                        onNavigate: _goOnboarding,
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _LoginCard extends StatelessWidget {
  const _LoginCard({
    required this.obscurePassword,
    required this.onTogglePassword,
    required this.onNavigate,
  });

  final bool obscurePassword;
  final VoidCallback onTogglePassword;
  final VoidCallback onNavigate;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border(
          top: BorderSide(
            color: AppColors.gold.withOpacity(0.3),
            width: 1.5,
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _QuestTextField(
            label: 'Email',
            hint: 'explorer@email.com',
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
          ),
          const SizedBox(height: 16),
          _QuestTextField(
            label: 'Mobile',
            hint: '+91 00000 00000',
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
          ),
          const SizedBox(height: 16),
          _QuestTextField(
            label: 'Password',
            hint: '\u2022\u2022\u2022\u2022\u2022\u2022\u2022\u2022',
            obscureText: obscurePassword,
            keyboardType: TextInputType.visiblePassword,
            prefixIcon: Icons.lock_outlined,
            suffixIcon: IconButton(
              onPressed: onTogglePassword,
              icon: Icon(
                obscurePassword ? Icons.visibility : Icons.visibility_off,
                color: AppColors.gold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onNavigate,
              style: TextButton.styleFrom(
                foregroundColor: AppColors.teal,
                padding: EdgeInsets.zero,
                minimumSize: const Size(0, 32),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: Text(
                'Forgot Password?',
                style: GoogleFonts.inter(fontSize: 12, color: AppColors.teal),
              ),
            ),
          ),
          const SizedBox(height: 18),
          _GradientButton(onPressed: onNavigate),
          const SizedBox(height: 24),
          const _OrDivider(),
          const SizedBox(height: 20),
          _SocialButton(
            onPressed: onNavigate,
            leading: Text(
              'G',
              style: GoogleFonts.inter(
                fontSize: 19,
                fontWeight: FontWeight.w800,
                color: const Color(0xFFEA4335),
              ),
            ),
            label: 'Continue with Google',
          ),
          const SizedBox(height: 12),
          _SocialButton(
            onPressed: onNavigate,
            leading: const Icon(Icons.apple, color: Colors.white, size: 24),
            label: 'Continue with Apple',
          ),
          const SizedBox(height: 24),
          const _BottomText(),
        ],
      ),
    );
  }
}

class _QuestTextField extends StatelessWidget {
  const _QuestTextField({
    required this.label,
    required this.hint,
    required this.keyboardType,
    required this.prefixIcon,
    this.obscureText = false,
    this.suffixIcon,
  });

  final String label;
  final String hint;
  final TextInputType keyboardType;
  final IconData prefixIcon;
  final bool obscureText;
  final Widget? suffixIcon;

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide(color: AppColors.gold.withOpacity(0.25)),
    );

    return TextField(
      keyboardType: keyboardType,
      obscureText: obscureText,
      cursorColor: AppColors.accent,
      style: GoogleFonts.inter(color: AppColors.text),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: GoogleFonts.inter(color: AppColors.hint),
        hintStyle: GoogleFonts.inter(
          color: AppColors.hint.withOpacity(0.65),
        ),
        prefixIcon: Icon(prefixIcon, color: AppColors.accent),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: AppColors.accent.withOpacity(0.08),
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent),
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.accent, AppColors.buttonEnd],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.4),
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
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          child: Text(
            'Begin Quest \u2192',
            style: GoogleFonts.cinzel(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.background,
            ),
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _DividerLine()),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'OR',
            style: GoogleFonts.inter(
              fontSize: 12,
              color: AppColors.hint,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(child: _DividerLine()),
      ],
    );
  }
}

class _DividerLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(height: 1, color: AppColors.gold.withOpacity(0.2));
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.onPressed,
    required this.leading,
    required this.label,
  });

  final VoidCallback onPressed;
  final Widget leading;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.06),
          side: BorderSide(color: Colors.white.withOpacity(0.15)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(width: 28, child: Center(child: leading)),
            const SizedBox(width: 10),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: 14, color: AppColors.text),
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomText extends StatelessWidget {
  const _BottomText();

  @override
  Widget build(BuildContext context) {
    return RichText(
      textAlign: TextAlign.center,
      text: TextSpan(
        style: GoogleFonts.inter(fontSize: 13, color: AppColors.text),
        children: [
          const TextSpan(text: "Don't have an account?  "),
          TextSpan(
            text: 'Sign Up',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppColors.accent,
              decoration: TextDecoration.underline,
              decorationColor: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }
}
