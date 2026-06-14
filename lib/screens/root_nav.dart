import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'home_screen.dart';
import 'today_screen.dart';
import 'community_screen.dart';
import 'nest_screen.dart';
import 'hold_me_screen.dart';

class RootNav extends StatefulWidget {
  const RootNav({super.key});

  @override
  State<RootNav> createState() => _RootNavState();
}

class _RootNavState extends State<RootNav> {
  int _index = 0;

  static const _pages = [
    HomeScreen(),
    TodayScreen(),
    CommunityScreen(),
    NestScreen(),
  ];

  void _openHoldMe() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: true,
        transitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (_, _, _) => const HoldMeScreen(),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: IndexedStack(index: _index, children: _pages),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _HoldMeButton(onTap: _openHoldMe),
      bottomNavigationBar: _NestBottomBar(
        index: _index,
        onSelect: (i) => setState(() => _index = i),
      ),
    );
  }
}

class _HoldMeButton extends StatelessWidget {
  final VoidCallback onTap;
  const _HoldMeButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [NestColors.blueSoft, NestColors.blue],
            ),
            boxShadow: [
              BoxShadow(
                color: NestColors.blue.withValues(alpha: 0.45),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(
            Icons.favorite_rounded,
            color: Colors.white,
            size: 30,
          ),
        ),
      ),
    );
  }
}

class _NestBottomBar extends StatelessWidget {
  final int index;
  final ValueChanged<int> onSelect;
  const _NestBottomBar({required this.index, required this.onSelect});

  @override
  Widget build(BuildContext context) {
    return BottomAppBar(
      color: Colors.white,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.08),
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      height: 68,
      padding: EdgeInsets.zero,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _tab(0, Icons.spa_outlined, Icons.spa_rounded, 'Nest'),
          _tab(1, Icons.wb_sunny_outlined, Icons.wb_sunny_rounded, 'Today'),
          const SizedBox(width: 56), // notch gap for the Hold Me button
          _tab(
            2,
            Icons.favorite_border_rounded,
            Icons.favorite_rounded,
            'Together',
          ),
          _tab(
            3,
            Icons.storefront_outlined,
            Icons.storefront_rounded,
            'Studio',
          ),
        ],
      ),
    );
  }

  Widget _tab(int i, IconData off, IconData on, String label) {
    final selected = index == i;
    final color = selected ? NestColors.blue : NestColors.inkSoft;
    return Expanded(
      child: InkResponse(
        onTap: () => onSelect(i),
        radius: 36,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(selected ? on : off, color: color, size: 24),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
