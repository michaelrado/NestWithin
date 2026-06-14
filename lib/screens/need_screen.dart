import 'package:flutter/material.dart';

import '../models/content.dart';
import '../theme/app_theme.dart';
import '../widgets/wellness_icon.dart';
import 'practice_screen.dart';

/// "We'll meet you there" — the practices recommended for a chosen need.
class NeedScreen extends StatelessWidget {
  final Need need;
  const NeedScreen({super.key, required this.need});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final practices = need.practiceIds.map(NestContent.practiceById).toList();

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
                return _PracticeRow(practice: practices[i - 1]);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PracticeRow extends StatelessWidget {
  final Practice practice;
  const _PracticeRow({required this.practice});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PracticeScreen(practice: practice)),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: NestColors.blueMist,
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.all(8),
                child: WellnessIcon(practice.iconAsset, size: 44),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      practice.title,
                      style: text.titleSmall?.copyWith(
                        color: NestColors.ink,
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
              const Icon(
                Icons.play_circle_fill_rounded,
                color: NestColors.blue,
                size: 34,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
