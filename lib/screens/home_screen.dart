import 'package:flutter/material.dart';

import '../data/nest_scope.dart';
import '../models/content.dart';
import '../theme/app_theme.dart';
import '../widgets/wellness_icon.dart';
import 'need_screen.dart';
import 'hold_me_screen.dart';
import 'theme_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final store = NestScope.of(context);
    final text = Theme.of(context).textTheme;
    final checkedIn = store.todaysCheckIn != null;

    return Container(
      decoration: const BoxDecoration(gradient: NestTheme.calmGradient),
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
              sliver: SliverList.list(
                children: [
                  Row(
                    children: [
                      Image.asset(
                        'assets/brand/logo_mark_blue.png',
                        width: 44,
                        height: 44,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _greeting(),
                              style: text.bodyMedium?.copyWith(
                                color: NestColors.inkSoft,
                              ),
                            ),
                            Text(
                              'The Nest',
                              style: text.titleLarge?.copyWith(
                                color: NestColors.blueDeep,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (store.checkInStreak > 0)
                        _StreakChip(days: store.checkInStreak),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'What do you need\nright now?',
                    style: text.headlineMedium?.copyWith(height: 1.15),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Choose a feeling. We’ll meet you there.',
                    style: text.bodyMedium?.copyWith(color: NestColors.inkSoft),
                  ),
                  const SizedBox(height: 20),
                  _NeedsGrid(),
                  const SizedBox(height: 24),
                  const _HoldMeCard(),
                  const SizedBox(height: 16),
                  if (!checkedIn) const _CheckInNudge(),
                  if (!checkedIn) const SizedBox(height: 16),
                  const _ThemeCard(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StreakChip extends StatelessWidget {
  final int days;
  const _StreakChip({required this.days});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.local_florist_rounded,
            size: 16,
            color: NestColors.sage,
          ),
          const SizedBox(width: 5),
          Text(
            '$days day${days == 1 ? '' : 's'}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: NestColors.ink,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _NeedsGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 14,
      childAspectRatio: 1.55,
      children: [for (final n in NestContent.needs) _NeedTile(need: n)],
    );
  }
}

class _NeedTile extends StatelessWidget {
  final Need need;
  const _NeedTile({required this.need});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => NeedScreen(need: need))),
        child: Ink(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: need.gradient,
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: need.gradient.last.withValues(alpha: 0.30),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    WellnessIcon(need.iconAsset, size: 38, tint: Colors.white),
                    const SizedBox(height: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          need.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          need.blurb,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.85),
                            fontSize: 12,
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

class _HoldMeCard extends StatelessWidget {
  const _HoldMeCard();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const HoldMeScreen())),
        child: Ink(
          decoration: BoxDecoration(
            gradient: NestTheme.sanctuaryGradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                color: NestColors.blueDeep.withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(22),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hold Me For Five Minutes',
                      style: text.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'When life feels too heavy, let us hold you.',
                      style: text.bodySmall?.copyWith(
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckInNudge extends StatelessWidget {
  const _CheckInNudge();
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          const Icon(Icons.wb_sunny_rounded, color: NestColors.clay),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'How are you arriving today?',
              style: text.titleSmall?.copyWith(color: NestColors.ink),
            ),
          ),
          Text(
            'Today tab →',
            style: text.bodySmall?.copyWith(color: NestColors.blue),
          ),
        ],
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  const _ThemeCard();
  @override
  Widget build(BuildContext context) {
    final t = NestContent.currentTheme;
    final text = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ThemeScreen())),
        child: Ink(
          decoration: BoxDecoration(
            color: NestColors.creamDeep,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: NestColors.sand),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${t.month} · Monthly Theme',
                style: text.labelMedium?.copyWith(
                  color: NestColors.clay,
                  letterSpacing: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${t.sanskrit} — ${t.english}',
                style: text.titleLarge?.copyWith(color: NestColors.blueDeep),
              ),
              const SizedBox(height: 6),
              Text(
                t.intention,
                style: text.bodyMedium?.copyWith(
                  color: NestColors.ink,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
