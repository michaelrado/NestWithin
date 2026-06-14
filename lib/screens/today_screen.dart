import 'package:flutter/material.dart';

import '../data/nest_scope.dart';
import '../models/content.dart';
import '../theme/app_theme.dart';
import '../widgets/wellness_icon.dart';
import 'need_screen.dart';

/// "How are you arriving today?" — the daily check-in, plus the Nest
/// Prescription: gentle, personalized insight drawn from your patterns.
class TodayScreen extends StatelessWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = NestScope.of(context);
    final text = Theme.of(context).textTheme;
    final today = store.todaysCheckIn;

    return Container(
      decoration: const BoxDecoration(gradient: NestTheme.calmGradient),
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              sliver: SliverList.list(
                children: [
                  Text(
                    'Today',
                    style: text.headlineMedium?.copyWith(
                      color: NestColors.blueDeep,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'A moment to notice how you are.',
                    style: text.bodyMedium?.copyWith(color: NestColors.inkSoft),
                  ),
                  const SizedBox(height: 24),
                  if (today == null)
                    const _CheckInCard()
                  else
                    _CheckedInCard(mood: NestContent.moodById(today.moodId)),
                  const SizedBox(height: 24),
                  Text(
                    'The Nest Prescription',
                    style: text.titleLarge?.copyWith(
                      color: NestColors.blueDeep,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'What seems to help you most.',
                    style: text.bodySmall?.copyWith(color: NestColors.inkSoft),
                  ),
                  const SizedBox(height: 14),
                  _PrescriptionCard(store: store),
                  const SizedBox(height: 16),
                  _StatsRow(store: store),
                  const SizedBox(height: 16),
                  if (store.moodCounts().isNotEmpty)
                    _MoodTrends(counts: store.moodCounts()),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckInCard extends StatelessWidget {
  const _CheckInCard();

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How are you arriving today?',
            style: text.titleLarge?.copyWith(color: NestColors.ink),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.92,
            children: [for (final m in NestContent.moods) _MoodChoice(mood: m)],
          ),
        ],
      ),
    );
  }
}

class _MoodChoice extends StatelessWidget {
  final Mood mood;
  const _MoodChoice({required this.mood});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: mood.color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () async {
          await NestScope.read(context).recordCheckIn(mood.id);
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Thank you for arriving. Noted: ${mood.label}.'),
              ),
            );
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            WellnessIcon(mood.iconAsset, size: 40),
            const SizedBox(height: 8),
            Text(
              mood.label,
              style: TextStyle(
                color: NestColors.ink,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckedInCard extends StatelessWidget {
  final Mood mood;
  const _CheckedInCard({required this.mood});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [mood.color.withValues(alpha: 0.85), mood.color],
        ),
        borderRadius: BorderRadius.circular(26),
      ),
      child: Row(
        children: [
          WellnessIcon(mood.iconAsset, size: 52, tint: Colors.white),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You arrived ${mood.label.toLowerCase()} today.',
                  style: text.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Thank you for checking in. Be gentle with yourself.',
                  style: text.bodySmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
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

class _PrescriptionCard extends StatelessWidget {
  final dynamic store;
  const _PrescriptionCard({required this.store});

  /// A gentle, recommendation-style insight. With enough data it speaks to the
  /// user's dominant pattern; early on it offers a warm, general suggestion.
  (String, Need) _insight() {
    final counts = store.moodCounts() as Map<String, int>;
    if (counts.isEmpty) {
      return (
        'Check in for a few days and the Nest will begin to notice what helps '
            'you most. For now — a few slow breaths is always a good place to start.',
        NestContent.needs.firstWhere((n) => n.id == 'calm'),
      );
    }
    final top = counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    return switch (top) {
      'anxious' => (
        'You’ve been arriving anxious lately. Breath practices tend to settle '
            'an activated nervous system most quickly.',
        NestContent.needs.firstWhere((n) => n.id == 'calm'),
      ),
      'overwhelmed' => (
        'Overwhelm has been present. A short reset — even two minutes — can '
            'create just enough space to breathe.',
        NestContent.needs.firstWhere((n) => n.id == 'stress'),
      ),
      'tired' => (
        'You’ve been tired. Restorative rest and a longer exhale appear to '
            'serve you right now.',
        NestContent.needs.firstWhere((n) => n.id == 'sleep'),
      ),
      'disconnected' => (
        'You’ve felt disconnected. Loving-kindness and reflection help many '
            'people find their way back to themselves.',
        NestContent.needs.firstWhere((n) => n.id == 'reconnect'),
      ),
      'content' => (
        'You’ve been arriving content. Gratitude practice tends to deepen and '
            'steady that feeling.',
        NestContent.needs.firstWhere((n) => n.id == 'mood'),
      ),
      _ => (
        'You’ve been arriving joyful — beautiful. Movement and gratitude can '
            'help you savor and sustain it.',
        NestContent.needs.firstWhere((n) => n.id == 'energy'),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final (message, need) = _insight();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: NestColors.creamDeep,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: NestColors.sand),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                color: NestColors.clay,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'A gentle observation',
                style: text.labelLarge?.copyWith(
                  color: NestColors.clay,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            message,
            style: text.bodyLarge?.copyWith(color: NestColors.ink, height: 1.5),
          ),
          const SizedBox(height: 16),
          FilledButton.tonal(
            style: FilledButton.styleFrom(
              backgroundColor: NestColors.blue,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => NeedScreen(need: need))),
            child: Text('Try ${need.label}'),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final dynamic store;
  const _StatsRow({required this.store});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(
            value: '${store.checkInStreak}',
            label: 'day streak',
            icon: Icons.local_florist_rounded,
            color: NestColors.sage,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatTile(
            value: '${store.practicesThisWeek}',
            label: 'practices done',
            icon: Icons.spa_rounded,
            color: NestColors.blue,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  const _StatTile({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 10),
          Text(
            value,
            style: text.headlineSmall?.copyWith(
              color: NestColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            label,
            style: text.bodySmall?.copyWith(color: NestColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

class _MoodTrends extends StatelessWidget {
  final Map<String, int> counts;
  const _MoodTrends({required this.counts});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final maxV = counts.values.fold(1, (a, b) => a > b ? a : b);
    final entries = NestContent.moods
        .where((m) => counts.containsKey(m.id))
        .toList();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How you’ve been arriving',
            style: text.titleSmall?.copyWith(
              color: NestColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          for (final m in entries) ...[
            Row(
              children: [
                SizedBox(
                  width: 96,
                  child: Text(
                    m.label,
                    style: text.bodySmall?.copyWith(color: NestColors.ink),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: (counts[m.id] ?? 0) / maxV,
                      minHeight: 10,
                      backgroundColor: NestColors.blueMist,
                      valueColor: AlwaysStoppedAnimation(m.color),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '${counts[m.id]}',
                  style: text.bodySmall?.copyWith(color: NestColors.inkSoft),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}
