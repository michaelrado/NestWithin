import 'package:flutter/material.dart';

import 'data/nest_scope.dart';
import 'data/nest_store.dart';
import 'theme/app_theme.dart';
import 'screens/splash_screen.dart';
import 'screens/root_nav.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = NestStore();
  await store.init();
  runApp(NestApp(store: store));
}

class NestApp extends StatelessWidget {
  final NestStore store;
  const NestApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return NestScope(
      store: store,
      child: MaterialApp(
        title: 'The Nest',
        debugShowCheckedModeBanner: false,
        theme: NestTheme.light(),
        home: const _Entry(),
      ),
    );
  }
}

/// Shows the welcome/splash until the user has crossed the threshold once,
/// then the main app.
class _Entry extends StatelessWidget {
  const _Entry();

  @override
  Widget build(BuildContext context) {
    final store = NestScope.of(context);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      child: store.onboarded ? const RootNav() : const SplashScreen(),
    );
  }
}
