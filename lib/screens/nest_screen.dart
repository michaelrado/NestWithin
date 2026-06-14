import 'package:flutter/material.dart';

import '../models/content.dart';
import '../theme/app_theme.dart';
import '../version.dart';

/// Integration with the physical Nest community — classes, workshops,
/// livestreams, events. The app deepens engagement; it doesn't replace it.
class NestScreen extends StatelessWidget {
  const NestScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
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
                  Row(
                    children: [
                      Image.asset('assets/brand/logo_mark_blue.png', width: 40),
                      const SizedBox(width: 10),
                      Text(
                        'The Nest',
                        style: text.headlineMedium?.copyWith(
                          color: NestColors.blueDeep,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Come be with us in person, too.',
                    style: text.bodyMedium?.copyWith(color: NestColors.inkSoft),
                  ),
                  const SizedBox(height: 20),
                  const _MembershipBanner(),
                  const SizedBox(height: 22),
                  Text(
                    'Upcoming',
                    style: text.titleLarge?.copyWith(
                      color: NestColors.blueDeep,
                    ),
                  ),
                  const SizedBox(height: 12),
                  for (final o in NestContent.studioOfferings) ...[
                    _OfferingCard(offering: o),
                    const SizedBox(height: 12),
                  ],
                  const SizedBox(height: 10),
                  _AboutCard(),
                  const SizedBox(height: 18),
                  Center(
                    child: Text(
                      '$kAppName · $kAppVersionLabel',
                      style: text.labelSmall?.copyWith(
                        color: NestColors.inkSoft,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MembershipBanner extends StatelessWidget {
  const _MembershipBanner();
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: NestTheme.sanctuaryGradient,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Nest Member',
            style: text.labelMedium?.copyWith(
              color: Colors.white.withValues(alpha: 0.8),
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your membership unlocks every practice,\nlivestream, and studio benefit.',
            style: text.titleMedium?.copyWith(color: Colors.white, height: 1.4),
          ),
          const SizedBox(height: 16),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: NestColors.blueDeep,
            ),
            onPressed: () =>
                _toast(context, 'Membership management coming soon.'),
            child: const Text('Manage membership'),
          ),
        ],
      ),
    );
  }
}

class _OfferingCard extends StatelessWidget {
  final StudioOffering offering;
  const _OfferingCard({required this.offering});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => _toast(
          context,
          'Registration for “${offering.title}” coming soon.',
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: NestColors.blueMist,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(offering.icon, color: NestColors.blue, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            offering.title,
                            style: text.titleSmall?.copyWith(
                              color: NestColors.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _KindBadge(kind: offering.kind),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${offering.when}  ·  ${offering.teacher}',
                      style: text.bodySmall?.copyWith(
                        color: NestColors.inkSoft,
                      ),
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

class _KindBadge extends StatelessWidget {
  final String kind;
  const _KindBadge({required this.kind});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: NestColors.clay.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        kind,
        style: const TextStyle(
          color: NestColors.clay,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _AboutCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
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
          Text(
            'Come home to yourself.',
            style: text.titleMedium?.copyWith(color: NestColors.blueDeep),
          ),
          const SizedBox(height: 8),
          Text(
            'The Nest is a personal sanctuary for nervous system care and '
            'emotional well-being. Not the largest wellness app — the most '
            'trusted daily companion.',
            style: text.bodyMedium?.copyWith(
              color: NestColors.ink,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

void _toast(BuildContext context, String msg) {
  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
}
