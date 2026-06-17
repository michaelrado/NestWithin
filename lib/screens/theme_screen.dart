import 'package:flutter/material.dart';

import '../data/nest_scope.dart';
import '../models/content.dart';
import '../theme/app_theme.dart';
import '../widgets/wellness_icon.dart';
import 'practice_screen.dart';
import 'signup_screen.dart';

/// The monthly theme — living the teachings, not just consuming content.
class ThemeScreen extends StatelessWidget {
  const ThemeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final t = NestContent.currentTheme;
    final text = Theme.of(context).textTheme;
    final practices = t.practiceIds.map(NestContent.practiceById).toList();

    return Scaffold(
      backgroundColor: NestColors.cream,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 220,
            backgroundColor: NestColors.blueDeep,
            foregroundColor: Colors.white,
            flexibleSpace: FlexibleSpaceBar(
              centerTitle: true,
              titlePadding: const EdgeInsets.symmetric(
                horizontal: 56,
                vertical: 14,
              ),
              title: Text(
                '${t.sanskrit} · ${t.english}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              background: Container(
                decoration: const BoxDecoration(
                  gradient: NestTheme.sanctuaryGradient,
                ),
                child: const Center(
                  child: Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: WellnessIcon(
                      'spirituality',
                      size: 72,
                      tint: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 40),
            sliver: SliverList.list(
              children: [
                Text(
                  '${t.month}’s Theme',
                  style: text.labelMedium?.copyWith(
                    color: NestColors.clay,
                    letterSpacing: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  t.intention,
                  style: text.titleLarge?.copyWith(
                    color: NestColors.ink,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                _Block(title: 'The teaching', body: t.teaching),
                const SizedBox(height: 16),
                _PromptCard(prompt: t.journalPrompt),
                const SizedBox(height: 24),
                Text(
                  'Practices for this month',
                  style: text.titleMedium?.copyWith(color: NestColors.blueDeep),
                ),
                const SizedBox(height: 12),
                for (final (idx, p) in practices.indexed) ...[
                  _ThemePractice(
                    practice: p,
                    locked: !NestScope.of(context).isUnlocked(idx),
                  ),
                  const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  final String title;
  final String body;
  const _Block({required this.title, required this.body});
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: text.titleSmall?.copyWith(
              color: NestColors.blueDeep,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            body,
            style: text.bodyMedium?.copyWith(
              color: NestColors.ink,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}

class _PromptCard extends StatelessWidget {
  final String prompt;
  const _PromptCard({required this.prompt});
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NestColors.creamDeep,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: NestColors.sand),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit_note_rounded, color: NestColors.clay),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Journal prompt',
                  style: text.labelMedium?.copyWith(
                    color: NestColors.clay,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  prompt,
                  style: text.bodyLarge?.copyWith(
                    color: NestColors.ink,
                    height: 1.4,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ThemePractice extends StatelessWidget {
  final Practice practice;
  final bool locked;
  const _ThemePractice({required this.practice, this.locked = false});
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => locked
                ? const SignupScreen(
                    reason: 'Create a free account to unlock this practice',
                  )
                : PracticeScreen(practice: practice),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: NestColors.blueMist,
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.all(6),
                child: WellnessIcon(practice.iconAsset, size: 36),
              ),
              const SizedBox(width: 12),
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
                    Text(
                      '${practice.kind.label} · ${practice.minutes} min',
                      style: text.bodySmall?.copyWith(
                        color: NestColors.inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                locked
                    ? Icons.lock_outline_rounded
                    : Icons.play_circle_fill_rounded,
                color: locked ? NestColors.inkSoft : NestColors.blue,
                size: locked ? 24 : 30,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
