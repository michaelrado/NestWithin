import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// A guided breathing cadence, in seconds per phase. Any phase may be 0.
class BreathPattern {
  final String name;
  final int inhale;
  final int holdIn;
  final int exhale;
  final int holdOut;

  const BreathPattern(
    this.name, {
    required this.inhale,
    this.holdIn = 0,
    required this.exhale,
    this.holdOut = 0,
  });

  int get cycleSeconds => inhale + holdIn + exhale + holdOut;
}

enum PracticeKind { breath, meditation, sound, movement, reflection, rest }

extension PracticeKindX on PracticeKind {
  String get label => switch (this) {
    PracticeKind.breath => 'Breath',
    PracticeKind.meditation => 'Meditation',
    PracticeKind.sound => 'Sound healing',
    PracticeKind.movement => 'Gentle movement',
    PracticeKind.reflection => 'Reflection',
    PracticeKind.rest => 'Rest',
  };

  IconData get icon => switch (this) {
    PracticeKind.breath => Icons.air_rounded,
    PracticeKind.meditation => Icons.self_improvement_rounded,
    PracticeKind.sound => Icons.graphic_eq_rounded,
    PracticeKind.movement => Icons.accessibility_new_rounded,
    PracticeKind.reflection => Icons.edit_note_rounded,
    PracticeKind.rest => Icons.nightlight_round,
  };
}

/// A short, highly effective experience — a 2/5/10-minute reset.
class Practice {
  final String id;
  final String title;
  final String subtitle;
  final int minutes;
  final PracticeKind kind;
  final String iconAsset; // a wellness_icons/ asset name (no extension)
  final String invitation; // the warm opening line shown when it begins
  final List<String> steps; // guided cues, paced across the duration
  final BreathPattern? breath;

  const Practice({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.minutes,
    required this.kind,
    required this.iconAsset,
    required this.invitation,
    required this.steps,
    this.breath,
  });
}

/// One of the simple needs surfaced on the home screen.
class Need {
  final String id;
  final String label;
  final String blurb;
  final String iconAsset;
  final List<Color> gradient;
  final List<String> practiceIds;

  const Need({
    required this.id,
    required this.label,
    required this.blurb,
    required this.iconAsset,
    required this.gradient,
    required this.practiceIds,
  });
}

/// A daily check-in option: "How are you arriving today?"
class Mood {
  final String id;
  final String label;
  final String iconAsset;
  final Color color;

  const Mood({
    required this.id,
    required this.label,
    required this.iconAsset,
    required this.color,
  });
}

class MonthlyTheme {
  final String sanskrit;
  final String english;
  final String month;
  final String intention;
  final String teaching;
  final String journalPrompt;
  final List<String> practiceIds;

  const MonthlyTheme({
    required this.sanskrit,
    required this.english,
    required this.month,
    required this.intention,
    required this.teaching,
    required this.journalPrompt,
    required this.practiceIds,
  });
}

class StudioOffering {
  final String title;
  final String when;
  final String teacher;
  final String kind; // Class / Workshop / Livestream / Event
  final IconData icon;

  const StudioOffering({
    required this.title,
    required this.when,
    required this.teacher,
    required this.kind,
    required this.icon,
  });
}

/// ── Seed content ──────────────────────────────────────────────────────────
/// All static for now; the experience is meant to be self-contained and to
/// work fully offline, on phone and web alike.
class NestContent {
  NestContent._();

  static const List<Practice> practices = [
    Practice(
      id: 'grounding',
      title: '5-4-3-2-1 Grounding',
      subtitle: 'Come back to the present moment',
      minutes: 3,
      kind: PracticeKind.rest,
      iconAsset: 'relaxation',
      invitation: 'Let’s gently arrive, using your senses as an anchor.',
      steps: [
        'Notice five things you can see around you.',
        'Notice four things you can feel — the chair, the floor, your breath.',
        'Notice three things you can hear.',
        'Notice two things you can smell.',
        'Notice one thing you can taste, or one thing you’re grateful for.',
        'Rest here a moment. You are here. You are safe.',
      ],
    ),
    Practice(
      id: 'box-breath',
      title: 'Box Breath',
      subtitle: 'Steady the nervous system',
      minutes: 3,
      kind: PracticeKind.breath,
      iconAsset: 'meditation',
      invitation:
          'Follow the circle. In, hold, out, hold — even and unhurried.',
      steps: [
        'Soften your shoulders and unclench your jaw.',
        'Let the breath move all the way down into your belly.',
        'Keep the four counts even and gentle.',
        'If your mind wanders, simply return to the circle.',
      ],
      breath: BreathPattern('Box', inhale: 4, holdIn: 4, exhale: 4, holdOut: 4),
    ),
    Practice(
      id: 'sigh',
      title: 'Physiological Sigh',
      subtitle: 'Fastest way to calm',
      minutes: 2,
      kind: PracticeKind.breath,
      iconAsset: 'stress_management',
      invitation: 'A double inhale, then a long release. Let it all go.',
      steps: [
        'Inhale through the nose, then sip in a little more air.',
        'Let the exhale be long, slow, and complete.',
        'Feel your body settle a little more with each round.',
      ],
      breath: BreathPattern(
        'Sigh',
        inhale: 4,
        holdIn: 1,
        exhale: 7,
        holdOut: 0,
      ),
    ),
    Practice(
      id: 'four78',
      title: '4 · 7 · 8 for Sleep',
      subtitle: 'Drift toward rest',
      minutes: 5,
      kind: PracticeKind.breath,
      iconAsset: 'good_sleep',
      invitation: 'A longer exhale tells your body it is safe to rest.',
      steps: [
        'Let your eyes close. Rest your tongue behind your top teeth.',
        'Breathe in for four, hold for seven, release for eight.',
        'There is nowhere to be and nothing to do but breathe.',
      ],
      breath: BreathPattern(
        '4-7-8',
        inhale: 4,
        holdIn: 7,
        exhale: 8,
        holdOut: 0,
      ),
    ),
    Practice(
      id: 'coherent',
      title: 'Coherent Breathing',
      subtitle: 'Find your center',
      minutes: 5,
      kind: PracticeKind.breath,
      iconAsset: 'yoga',
      invitation: 'Five in, five out. A smooth, balanced rhythm.',
      steps: [
        'Breathe in a soft, continuous stream for five counts.',
        'Release just as smoothly for five.',
        'Let the breath become a quiet wave, in and out.',
      ],
      breath: BreathPattern(
        'Coherent',
        inhale: 5,
        holdIn: 0,
        exhale: 5,
        holdOut: 0,
      ),
    ),
    Practice(
      id: 'bodyscan',
      title: 'Gentle Body Scan',
      subtitle: 'Release held tension',
      minutes: 10,
      kind: PracticeKind.meditation,
      iconAsset: 'spa',
      invitation: 'We’ll travel slowly through the body, softening as we go.',
      steps: [
        'Bring attention to your feet. Let them grow heavy.',
        'Move up through the legs and hips, releasing any holding.',
        'Soften the belly, the chest, the shoulders.',
        'Unclench the hands. Loosen the jaw and the brow.',
        'Rest in the whole body, breathing, at ease.',
      ],
    ),
    Practice(
      id: 'soundbath',
      title: 'Sound Healing Bath',
      subtitle: 'Let resonance hold you',
      minutes: 10,
      kind: PracticeKind.sound,
      iconAsset: 'aromatherapy',
      invitation: 'Close your eyes and let the tones wash over you.',
      steps: [
        'Settle into a comfortable position.',
        'Let sound arrive without needing to listen for anything.',
        'Allow each tone to soften a little more of the day.',
        'Float here. There is nothing to do.',
      ],
    ),
    Practice(
      id: 'lovingkindness',
      title: 'Loving-Kindness',
      subtitle: 'Warm the heart',
      minutes: 7,
      kind: PracticeKind.meditation,
      iconAsset: 'relationship',
      invitation: 'We’ll offer simple, kind wishes — first to yourself.',
      steps: [
        'May I be safe. May I be well. May I be at ease.',
        'Picture someone you love. Offer them the same wishes.',
        'Picture someone neutral — a stranger. Offer it to them too.',
        'Widen it to everyone, everywhere. May all beings be at ease.',
      ],
    ),
    Practice(
      id: 'shake',
      title: 'Shake It Off',
      subtitle: 'Move the energy through',
      minutes: 2,
      kind: PracticeKind.movement,
      iconAsset: 'exercise',
      invitation: 'Let the body do what it naturally knows — discharge stress.',
      steps: [
        'Stand and gently bounce through your knees.',
        'Let your hands, arms, and shoulders shake loose.',
        'Add a sigh or a sound on the exhale if it feels good.',
        'Slow to stillness and feel the aliveness settle.',
      ],
    ),
    Practice(
      id: 'gratitude',
      title: 'Three Good Things',
      subtitle: 'Tilt toward the good',
      minutes: 3,
      kind: PracticeKind.reflection,
      iconAsset: 'gratitude',
      invitation: 'Let’s gently notice what went right today, however small.',
      steps: [
        'Recall one small thing that went well today.',
        'Recall a second — a moment of ease, beauty, or kindness.',
        'Recall a third. Let yourself feel it, not just name it.',
        'Notice how it feels to rest your attention here.',
      ],
    ),
    Practice(
      id: 'restore',
      title: 'Legs Up the Wall',
      subtitle: 'Restorative stillness',
      minutes: 8,
      kind: PracticeKind.rest,
      iconAsset: 'massage',
      invitation: 'A deeply restful shape — let gravity do the work.',
      steps: [
        'Rest your back on the floor, legs up a wall or a couch.',
        'Let your arms fall open, palms up.',
        'Soften the breath and let the body grow heavy.',
        'Stay as long as feels nourishing.',
      ],
    ),
    Practice(
      id: 'intention',
      title: 'Set an Intention',
      subtitle: 'Begin on purpose',
      minutes: 2,
      kind: PracticeKind.reflection,
      iconAsset: 'achievable_goals',
      invitation: 'One word or phrase to carry gently through your day.',
      steps: [
        'Take a slow breath and ask: how do I want to feel today?',
        'Let a single word arise — calm, open, steady, kind.',
        'Breathe it in. Let it settle.',
        'Carry it lightly. You can return to it any time.',
      ],
    ),
  ];

  static Practice practiceById(String id) =>
      practices.firstWhere((p) => p.id == id);

  static const List<Need> needs = [
    Need(
      id: 'calm',
      label: 'Calm Me',
      blurb: 'Soothe a racing mind',
      iconAsset: 'relaxation',
      gradient: [NestColors.blueSoft, NestColors.blue],
      practiceIds: ['grounding', 'box-breath', 'soundbath', 'coherent'],
    ),
    Need(
      id: 'sleep',
      label: 'Help Me Sleep',
      blurb: 'Soften into rest',
      iconAsset: 'good_sleep',
      gradient: [NestColors.blueDeep, Color(0xFF55709C)],
      practiceIds: ['four78', 'bodyscan', 'restore', 'soundbath'],
    ),
    Need(
      id: 'stress',
      label: 'Reduce Stress',
      blurb: 'Let the pressure ease',
      iconAsset: 'stress_management',
      gradient: [NestColors.clay, Color(0xFFC98A66)],
      practiceIds: ['box-breath', 'sigh', 'shake', 'soundbath'],
    ),
    Need(
      id: 'mood',
      label: 'Lift My Mood',
      blurb: 'Invite a little light',
      iconAsset: 'optimistic_outlook',
      gradient: [Color(0xFFE0A878), NestColors.clay],
      practiceIds: ['gratitude', 'shake', 'lovingkindness', 'intention'],
    ),
    Need(
      id: 'focus',
      label: 'Find Focus',
      blurb: 'Gather a scattered mind',
      iconAsset: 'achievable_goals',
      gradient: [NestColors.sage, Color(0xFF7A977A)],
      practiceIds: ['box-breath', 'coherent', 'intention', 'bodyscan'],
    ),
    Need(
      id: 'reconnect',
      label: 'Reconnect',
      blurb: 'Come back to yourself',
      iconAsset: 'sense_of_belonging',
      gradient: [NestColors.blueSoft, NestColors.sage],
      practiceIds: ['lovingkindness', 'gratitude', 'bodyscan', 'intention'],
    ),
    Need(
      id: 'energy',
      label: 'Restore Energy',
      blurb: 'Replenish what’s depleted',
      iconAsset: 'wellbeing',
      gradient: [Color(0xFFE0A878), NestColors.sage],
      practiceIds: ['shake', 'coherent', 'intention', 'sigh'],
    ),
    Need(
      id: 'supported',
      label: 'Feel Supported',
      blurb: 'Be held for a moment',
      iconAsset: 'self_care',
      gradient: [NestColors.blue, NestColors.blueDeep],
      practiceIds: ['lovingkindness', 'soundbath', 'grounding', 'restore'],
    ),
  ];

  static const List<Mood> moods = [
    Mood(
      id: 'anxious',
      label: 'Anxious',
      iconAsset: 'stress_management',
      color: NestColors.clay,
    ),
    Mood(
      id: 'overwhelmed',
      label: 'Overwhelmed',
      iconAsset: 'aromatherapy',
      color: Color(0xFFC98A66),
    ),
    Mood(
      id: 'tired',
      label: 'Tired',
      iconAsset: 'good_sleep',
      color: NestColors.blueDeep,
    ),
    Mood(
      id: 'disconnected',
      label: 'Disconnected',
      iconAsset: 'sense_of_belonging',
      color: NestColors.blueSoft,
    ),
    Mood(
      id: 'content',
      label: 'Content',
      iconAsset: 'wellbeing',
      color: NestColors.sage,
    ),
    Mood(
      id: 'joyful',
      label: 'Joyful',
      iconAsset: 'gratitude',
      color: Color(0xFFE0A878),
    ),
  ];

  static Mood moodById(String id) => moods.firstWhere((m) => m.id == id);

  static const MonthlyTheme currentTheme = MonthlyTheme(
    sanskrit: 'Santosha',
    english: 'Contentment',
    month: 'June',
    intention:
        'This month we practice contentment — meeting this moment as enough.',
    teaching:
        'Santosha is not the absence of wanting, but the gentle art of arriving '
        'here, with what is, and finding it sufficient. Contentment is a practice, '
        'not a personality. We return to it, again and again, one breath at a time.',
    journalPrompt: 'Where, in this ordinary day, is there already enough?',
    practiceIds: ['gratitude', 'coherent', 'bodyscan'],
  );

  /// Anonymous community reflections — no likes, no names, just "me too".
  static const List<(String, int)> seedReflections = [
    (
      'I almost skipped my practice today, but two minutes of breathing changed the whole afternoon.',
      41,
    ),
    ('Trying to remember that rest is not something I have to earn.', 88),
    ('Today I’m grateful for my morning tea and a quiet window.', 27),
    (
      'Feeling stretched thin. Reminding myself I don’t need fixing — just a moment to land.',
      63,
    ),
    ('The 4-7-8 breath actually helped me fall back asleep last night.', 35),
    ('Letting today be enough, exactly as it is.', 52),
  ];

  static const List<StudioOffering> studioOfferings = [
    StudioOffering(
      title: 'Slow Flow & Sound',
      when: 'Mon · 6:00 PM',
      teacher: 'with Maya',
      kind: 'Class',
      icon: Icons.self_improvement_rounded,
    ),
    StudioOffering(
      title: 'Nervous System Reset Workshop',
      when: 'Sat · 10:00 AM',
      teacher: 'with Dr. Lena',
      kind: 'Workshop',
      icon: Icons.spa_rounded,
    ),
    StudioOffering(
      title: 'Yoga Nidra Livestream',
      when: 'Wed · 8:30 PM',
      teacher: 'with Theo',
      kind: 'Livestream',
      icon: Icons.nightlight_round,
    ),
    StudioOffering(
      title: 'New Moon Restorative',
      when: 'Jun 25 · 7:00 PM',
      teacher: 'with Maya',
      kind: 'Event',
      icon: Icons.brightness_3_rounded,
    ),
  ];
}
