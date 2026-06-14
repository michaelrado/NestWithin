import 'package:flutter/material.dart';

import '../data/nest_scope.dart';
import '../data/nest_store.dart';
import '../theme/app_theme.dart';

/// Connection without social media. No likes, no followers, no algorithms —
/// just anonymous reflections and a quiet "Me too."
class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = NestScope.of(context);
    final text = Theme.of(context).textTheme;
    final reflections = store.reflections;

    return Container(
      decoration: const BoxDecoration(gradient: NestTheme.calmGradient),
      child: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              sliver: SliverList.list(
                children: [
                  Text(
                    'Together',
                    style: text.headlineMedium?.copyWith(
                      color: NestColors.blueDeep,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Belonging, not performance. Share anonymously, or '
                    'simply offer a “me too.”',
                    style: text.bodyMedium?.copyWith(
                      color: NestColors.inkSoft,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ShareCard(store: store),
                  const SizedBox(height: 8),
                ],
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
              sliver: SliverList.separated(
                itemCount: reflections.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, i) =>
                    _ReflectionCard(reflection: reflections[i], store: store),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareCard extends StatefulWidget {
  final NestStore store;
  const _ShareCard({required this.store});

  @override
  State<_ShareCard> createState() => _ShareCardState();
}

class _ShareCardState extends State<_ShareCard> {
  final _controller = TextEditingController();
  bool _expanded = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final t = _controller.text.trim();
    if (t.isEmpty) return;
    await widget.store.shareReflection(t);
    _controller.clear();
    setState(() => _expanded = false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Shared anonymously. Thank you.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_expanded)
            InkWell(
              onTap: () => setState(() => _expanded = true),
              child: Row(
                children: [
                  const Icon(Icons.edit_note_rounded, color: NestColors.blue),
                  const SizedBox(width: 12),
                  Text(
                    'Share a thought, gratitude, or struggle…',
                    style: text.bodyMedium?.copyWith(color: NestColors.inkSoft),
                  ),
                ],
              ),
            )
          else ...[
            TextField(
              controller: _controller,
              autofocus: true,
              maxLines: 3,
              maxLength: 240,
              style: text.bodyLarge?.copyWith(color: NestColors.ink),
              decoration: const InputDecoration(
                hintText: 'What’s present for you right now?',
                border: InputBorder.none,
                counterStyle: TextStyle(color: NestColors.inkSoft),
              ),
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => setState(() {
                    _expanded = false;
                    _controller.clear();
                  }),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _submit,
                  child: const Text('Share anonymously'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ReflectionCard extends StatelessWidget {
  final Reflection reflection;
  final NestStore store;
  const _ReflectionCard({required this.reflection, required this.store});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: reflection.mine
            ? Border.all(color: NestColors.blueMist, width: 1.5)
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (reflection.mine)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'You shared',
                style: text.labelSmall?.copyWith(
                  color: NestColors.blue,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          Text(
            reflection.text,
            style: text.bodyLarge?.copyWith(
              color: NestColors.ink,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _MeTooButton(reflection: reflection, store: store),
              const Spacer(),
              Text(
                '${reflection.meToo} felt this too',
                style: text.bodySmall?.copyWith(color: NestColors.inkSoft),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MeTooButton extends StatelessWidget {
  final Reflection reflection;
  final NestStore store;
  const _MeTooButton({required this.reflection, required this.store});

  @override
  Widget build(BuildContext context) {
    final active = reflection.didMeToo;
    return Material(
      color: active ? NestColors.blue : NestColors.blueMist,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => store.toggleMeToo(reflection.id),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.favorite_rounded,
                size: 16,
                color: active ? Colors.white : NestColors.blue,
              ),
              const SizedBox(width: 6),
              Text(
                'Me too',
                style: TextStyle(
                  color: active ? Colors.white : NestColors.blueDeep,
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
