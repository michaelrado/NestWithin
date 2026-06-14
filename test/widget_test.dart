import 'package:flutter_test/flutter_test.dart';

import 'package:nest_within/models/content.dart';

void main() {
  test('seed content is internally consistent', () {
    // Every need references practices that actually exist.
    for (final need in NestContent.needs) {
      for (final id in need.practiceIds) {
        expect(
          NestContent.practices.any((p) => p.id == id),
          isTrue,
          reason: 'Need "${need.id}" references unknown practice "$id"',
        );
      }
    }
    expect(NestContent.moods, isNotEmpty);
    for (final id in NestContent.currentTheme.practiceIds) {
      expect(NestContent.practices.any((p) => p.id == id), isTrue);
    }
  });

  test('breath pattern cycle length is positive', () {
    for (final p in NestContent.practices) {
      if (p.breath != null) {
        expect(p.breath!.cycleSeconds, greaterThan(0));
      }
    }
  });
}
