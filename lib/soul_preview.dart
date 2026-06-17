// Dev-only harness to eyeball the 3D SoulOrb in isolation (not part of the
// app). Build:  flutter build web -t lib/soul_preview.dart -o build/soul_preview
import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'theme/app_theme.dart';
import 'widgets/soul_orb.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SoulOrb.warmUp();
  runApp(const _PreviewApp());
}

class _PreviewApp extends StatefulWidget {
  const _PreviewApp();
  @override
  State<_PreviewApp> createState() => _PreviewAppState();
}

class _PreviewAppState extends State<_PreviewApp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 6),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: NestTheme.sanctuaryGradient,
          ),
          child: Center(
            child: AnimatedBuilder(
              animation: _c,
              builder: (context, _) {
                final breath = (math.sin(_c.value * 2 * math.pi) + 1) / 2;
                return Wrap(
                  spacing: 24,
                  runSpacing: 24,
                  alignment: WrapAlignment.center,
                  children: [
                    SoulOrb(
                      breath: breath,
                      size: 300,
                      colorA: const Color(0xFF8FB0E0),
                      colorB: const Color(0xFFEAF2FF),
                    ),
                    SoulOrb(
                      breath: 1 - breath,
                      size: 200,
                      colorA: NestColors.clay,
                      colorB: const Color(0xFFF3DCCB),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
