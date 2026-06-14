import 'package:flutter/material.dart';

/// Renders one of the sliced wellness icons (from assets/wellness_icons/).
/// These are the brand's blue iconography, lifted from the icon sheet.
class WellnessIcon extends StatelessWidget {
  final String name;
  final double size;
  final Color? tint;

  const WellnessIcon(this.name, {super.key, this.size = 48, this.tint});

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      'assets/wellness_icons/$name.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      color: tint,
    );
    return SizedBox(width: size, height: size, child: image);
  }
}
