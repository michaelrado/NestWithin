import 'package:flutter/material.dart';

import '../data/nest_scope.dart';
import '../data/nest_store.dart';
import '../models/content.dart';
import '../theme/app_theme.dart';
import '../widgets/wellness_icon.dart';
import 'practice_screen.dart';
import 'signup_screen.dart';

/// "We'll meet you there" — the practices recommended for a chosen need.
/// The first [kFreePerCategory] are free; the rest unlock with an account.
class NeedScreen extends StatelessWidget {
  final Need need;
  const NeedScreen({super.key, required this.need});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final store = NestScope.of(context);
    final practices = need.practiceIds.map(NestContent.practiceById).toList();
    final anyLocked = !store.isSignedIn && practices.length > kFreePerCategory;

    return Scaffold(
      backgroundColor: NestColors.cream,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: need.gradient.last,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              titlePadding: const EdgeInsets.symmetric(
                horizontal: 56,
                vertical: 14,
              ),
              centerTitle: true,
              title: Text(
                need.label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: need.gradient,
                  ),
                ),
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 34),
                    child: WellnessIcon(
                      need.iconAsset,
                      size: 64,
                      tint: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            sliver: SliverList.separated(
              itemCount: practices.length + 1,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                if (i == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      'A few ways to ${need.blurb.toLowerCase()}',
                      style: text.titleMedium?.copyWith(
                        color: NestColors.inkSoft,
                      ),
                    ),
                  );
                }
                final idx = i - 1;
                return _PracticeRow(
                  practice: practices[idx],
                  locked: !store.isUnlocked(idx),
                );
              },
            ),
          ),
          if (anyLocked)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                child: _UnlockBanner(needLabel: need.label),
              ),
            ),
        ],
      ),
    );
  }
}

class _PracticeRow extends StatelessWidget {
  final Practice practice;
  final bool locked;
  const _PracticeRow({required this.practice, required this.locked});

  void _open(BuildContext context) {
    if (locked) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const SignupScreen(
            reason: 'Create a free account to unlock this practice',
          ),
        ),
      );
    } else {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => PracticeScreen(practice: practice)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _open(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Opacity(
                opacity: locked ? 0.5 : 1,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: NestColors.blueMist,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: WellnessIcon(practice.iconAsset, size: 44),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      practice.title,
                      style: text.titleSmall?.copyWith(
                        color: locked ? NestColors.inkSoft : NestColors.ink,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      practice.subtitle,
                      style: text.bodySmall?.copyWith(
                        color: NestColors.inkSoft,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          practice.kind.icon,
                          size: 14,
                          color: NestColors.blue,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${practice.kind.label} · ${practice.minutes} min',
                          style: text.labelSmall?.copyWith(
                            color: NestColors.blue,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                locked
                    ? Icons.lock_outline_rounded
                    : Icons.play_circle_fill_rounded,
                color: locked ? NestColors.inkSoft : NestColors.blue,
                size: locked ? 26 : 34,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UnlockBanner extends StatelessWidget {
  final String needLabel;
  const _UnlockBanner({required this.needLabel});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => SignupScreen(
              reason: 'Unlock all of $needLabel and every other practice',
            ),
          ),
        ),
        child: Ink(
          decoration: BoxDecoration(
            color: NestColors.creamDeep,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: NestColors.sand),
          ),
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              const Icon(Icons.lock_open_rounded, color: NestColors.clay),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Enjoying the free practices?',
                      style: text.titleSmall?.copyWith(color: NestColors.ink),
                    ),
                    Text(
                      'Create a free account to unlock the full library.',
                      style: text.bodySmall?.copyWith(
                        color: NestColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: NestColors.inkSoft,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
