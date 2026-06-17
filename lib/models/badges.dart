import 'package:flutter/material.dart';

import '../data/nest_store.dart';
import '../theme/app_theme.dart';

/// A small reward for showing up. Badges are pure derivations of the local
/// state — earning one is just a predicate over the [NestStore].
class Badge {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final bool Function(NestStore) test;

  const Badge({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.test,
  });
}

class Badges {
  Badges._();

  static final List<Badge> all = [
    Badge(
      id: 'first_breath',
      title: 'First Breath',
      description: 'Completed your first practice',
      icon: Icons.spa_rounded,
      color: NestColors.blue,
      test: (s) => s.totalPractices >= 1,
    ),
    Badge(
      id: 'taking_root',
      title: 'Taking Root',
      description: 'A 3-day check-in streak',
      icon: Icons.local_florist_rounded,
      color: NestColors.sage,
      test: (s) => s.checkInStreak >= 3,
    ),
    Badge(
      id: 'steady_week',
      title: 'Steady Week',
      description: 'Checked in 7 days in a row',
      icon: Icons.calendar_month_rounded,
      color: NestColors.clay,
      test: (s) => s.checkInStreak >= 7,
    ),
    Badge(
      id: 'finding_rhythm',
      title: 'Finding Rhythm',
      description: 'Completed 10 practices',
      icon: Icons.waves_rounded,
      color: NestColors.blueSoft,
      test: (s) => s.totalPractices >= 10,
    ),
    Badge(
      id: 'devoted',
      title: 'Devoted',
      description: 'Completed 30 practices',
      icon: Icons.auto_awesome_rounded,
      color: NestColors.blueDeep,
      test: (s) => s.totalPractices >= 30,
    ),
    Badge(
      id: 'sound_bather',
      title: 'Sound Bather',
      description: 'Soaked in a sound healing bath',
      icon: Icons.graphic_eq_rounded,
      color: NestColors.blue,
      test: (s) => s.completionsOf('soundbath') >= 1,
    ),
    Badge(
      id: 'deep_rest',
      title: 'Deep Rest',
      description: 'Practiced for sleep or restoration',
      icon: Icons.nightlight_round,
      color: NestColors.blueDeep,
      test: (s) =>
          s.distinctCompleted.contains('four78') ||
          s.distinctCompleted.contains('restore') ||
          s.distinctCompleted.contains('bodyscan'),
    ),
    Badge(
      id: 'held',
      title: 'Held',
      description: 'Let the Nest hold you for five minutes',
      icon: Icons.favorite_rounded,
      color: NestColors.clay,
      test: (s) => s.holdMeCount >= 1,
    ),
    Badge(
      id: 'explorer',
      title: 'Explorer',
      description: 'Tried 6 different practices',
      icon: Icons.explore_rounded,
      color: NestColors.sage,
      test: (s) => s.distinctCompleted.length >= 6,
    ),
  ];

  static Badge byId(String id) => all.firstWhere((b) => b.id == id);

  static List<String> earnedIds(NestStore s) =>
      all.where((b) => b.test(s)).map((b) => b.id).toList();

  static List<Badge> earned(NestStore s) =>
      all.where((b) => b.test(s)).toList();
}
