import 'package:flutter/material.dart';

import '../data/nest_scope.dart';
import '../theme/app_theme.dart';

/// The threshold — a warm, unhurried welcome. "Come home to yourself."
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: NestTheme.sanctuaryGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                const Spacer(flex: 2),
                ScaleTransition(
                  scale: Tween(begin: 0.96, end: 1.04).animate(
                    CurvedAnimation(parent: _c, curve: Curves.easeInOut),
                  ),
                  child: Image.asset(
                    'assets/brand/logo_mark_white.png',
                    width: 200,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 28),
                Text(
                  'Come home\nto yourself.',
                  textAlign: TextAlign.center,
                  style: text.displaySmall?.copyWith(
                    color: Colors.white,
                    height: 1.15,
                    fontSize: 34,
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'A quiet place to breathe, reconnect, and feel\nsupported — in just a few minutes.',
                  textAlign: TextAlign.center,
                  style: text.bodyLarge?.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.5,
                  ),
                ),
                const Spacer(flex: 3),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: NestColors.blueDeep,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                    ),
                    onPressed: () =>
                        NestScope.read(context).completeOnboarding(),
                    child: const Text('Enter the Nest'),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'You belong here. You are supported.',
                  style: text.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
