// Dev-only harness to eyeball the membership hub (ProfileScreen) with seeded
// data. Build with an unreachable API so signup/activity stay local:
//   flutter build web -t lib/membership_preview.dart -o build/mpreview \
//     --dart-define=NEST_API=http://127.0.0.1:9/api
import 'package:flutter/material.dart';

import 'data/nest_scope.dart';
import 'data/nest_store.dart';
import 'theme/app_theme.dart';
import 'screens/profile_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = NestStore();
  await store.init();
  // Seed a rich local state (API is unreachable, so this stays on-device).
  await store.signUp(
    name: 'Sarita Rocco',
    email: 'sarita@thenest.example',
    password: 'previewpass',
    referral: 'A friend',
    rating: 5,
    anonymous: false,
  );
  for (final id in [
    'box-breath',
    'box-breath',
    'box-breath',
    'grounding',
    'grounding',
    'soundbath',
    'bodyscan',
    'gratitude',
    'four78',
  ]) {
    await store.markCompleted(id);
  }
  await store.markHoldMeComplete();
  await store.markHoldMeComplete();
  await store.recordCheckIn('content');

  runApp(
    NestScope(
      store: store,
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: NestTheme.light(),
        home: const ProfileScreen(),
      ),
    ),
  );
}
