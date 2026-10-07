import '../models/urge_activity.dart';

class UrgeActivitiesCatalog {
  static const List<String> categories = [
    'Neuro-Breathing',
    'Somatic Physical',
    'Cognitive Overload',
    'Mindfulness Defusion',
    'Sensory Grounding',
  ];

  static final List<UrgeActivity> _activities = _generate90Activities();

  static List<UrgeActivity> getAll() => List.unmodifiable(_activities);

  static UrgeActivity getForDay(int dayNumber) {
    if (dayNumber <= 0) return _activities.first;
    if (dayNumber > _activities.length) return _activities.last;
    return _activities[dayNumber - 1];
  }

  static List<UrgeActivity> getByCategory(String category) {
    return _activities.where((a) => a.category == category).toList();
  }

  static List<UrgeActivity> _generate90Activities() {
    final List<UrgeActivity> list = [];

    // Core templates rotated and enriched across 90 days
    final List<Map<String, dynamic>> bases = [
      // Day 1
      {
        'title': '4-7-8 Parasympathetic Reset',
        'category': 'Neuro-Breathing',
        'desc': 'Slow down your autonomic nervous system and deactivate stress response.',
        'sec': 180,
        'type': 'breathing',
        'benefit': 'Long exhales stimulate the vagus nerve, rapidly lowering heart rate and anxiety.',
        'steps': [
          'Inhale quietly through your nose for 4 seconds.',
          'Hold your breath comfortably for 7 seconds.',
          'Exhale completely with a soft sigh for 8 seconds.',
          'Repeat 4 full cycles until your impulse intensity drops.'
        ],
      },
      // Day 2
      {
        'title': '5-4-3-2-1 Sensory Anchor',
        'category': 'Sensory Grounding',
        'desc': 'Pull your mind out of internal craving loops back into physical reality.',
        'sec': 300,
        'type': 'steps',
        'benefit': 'Engages sensory cortex to disrupt runaway limbic craving signals.',
        'steps': [
          'Acknowledge 5 things you can SEE around you right now.',
          'Acknowledge 4 things you can TOUCH (feel textures under your fingers).',
          'Acknowledge 3 distinct SOUNDS in your environment.',
          'Acknowledge 2 things you can SMELL.',
          'Acknowledge 1 thing you can TASTE or take a cold sip of water.'
        ],
      },
      // Day 3
      {
        'title': 'Cold Water Mammalian Dive Reflex',
        'category': 'Somatic Physical',
        'desc': 'Splash ice water on your face or hold an ice cube firmly.',
        'sec': 120,
        'type': 'timer',
        'benefit': 'Triggers the dive reflex: instantly drops heart rate and redirects blood flow.',
        'steps': [
          'Fill a bowl with cold tap water or grab an ice cube.',
          'Dip your face into the cold water for 10-15 seconds (or hold ice cube in palm).',
          'Focus intensely on the crisp cold sensation.',
          'Notice how your bodily tension immediately shifts gears.'
        ],
      },
      // Day 4
      {
        'title': 'Countdown 100 by 7s (Working Memory Dump)',
        'category': 'Cognitive Overload',
        'desc': 'Overload your prefrontal cortex with math to erase craving imagery.',
        'sec': 240,
        'type': 'cognitive',
        'benefit': 'Working memory capacity is finite; math tasks displace urge visual memory.',
        'steps': [
          'Start out loud or in your head at 100.',
          'Subtract 7: 93, 86, 79, 72, 65, 58, 51, 44, 37, 30, 23, 16, 9, 2.',
          'If you make a mistake, restart at 100 immediately.',
          'Repeat until the visual mental picture of your urge completely fades.'
        ],
      },
      // Day 5
      {
        'title': 'Leaves on a Stream Defusion',
        'category': 'Mindfulness Defusion',
        'desc': 'Observe your urge as a passing leaf on a flowing river without grabbing it.',
        'sec': 300,
        'type': 'timer',
        'benefit': 'Creates psychological distance between impulse and physical action.',
        'steps': [
          'Close your eyes and visualize a gently flowing stream in a quiet forest.',
          'Whenever a craving or temptation thought appears, place it gently on a leaf.',
          'Watch the leaf float downstream out of view.',
          'Do not push the leaf or pull it back — simply watch it drift away.'
        ],
      },
      // Day 6
      {
        'title': 'Double Physiological Sigh',
        'category': 'Neuro-Breathing',
        'desc': 'The fastest single-minute biological way to collapse anxiety and urge tension.',
        'sec': 120,
        'type': 'breathing',
        'benefit': 'Re-inflates collapsed alveoli in lungs and maximizes carbon dioxide offloading.',
        'steps': [
          'Take two quick consecutive inhales through your nose (deep inhale + top-off inhale).',
          'Slowly offload air through a long relaxed mouth exhale.',
          'Perform 5 to 10 sigh cycles consecutively.'
        ],
      },
      // Day 7
      {
        'title': 'Isometric Muscle Clench & Release',
        'category': 'Somatic Physical',
        'desc': 'Tense every muscle group for 5 seconds, then drop all tension completely.',
        'sec': 240,
        'type': 'steps',
        'benefit': 'Progressive muscle relaxation flushes out motor restlessness produced by dopamine surges.',
        'steps': [
          'Clench your fists and forearms as hard as possible for 5 seconds.',
          'Release suddenly and let your arms drop completely limp.',
          'Tense your thighs and calves for 5 seconds, then release.',
          'Squeeze your shoulder blades together, then drop shoulders low.'
        ],
      },
      // Day 8
      {
        'title': 'Stroop Effect Challenge',
        'category': 'Cognitive Overload',
        'desc': 'Name the font color of written words instead of reading the words.',
        'sec': 180,
        'type': 'cognitive',
        'benefit': 'Forces executive cognitive control to override automatic habit response.',
        'steps': [
          'Look at objects around you and call out their colors, not their names.',
          'Spell out 5 complex words backwards in your mind (e.g. R-E-C-O-V-E-R-Y -> Y-R-E-V-O-C-E-R).',
          'Keep your mind fully locked on the letter sequence.'
        ],
      },
      // Day 9
      {
        'title': 'Body-Scan Urge Mapping',
        'category': 'Mindfulness Defusion',
        'desc': 'Locate the exact physical location of the urge in your body.',
        'sec': 300,
        'type': 'timer',
        'benefit': 'Demystifies cravings: shows an urge is just a temporary chest tightness or stomach flutter.',
        'steps': [
          'Scan your body from head to toe. Where is the physical urge sensation right now?',
          'Is it tightness in the chest, flutter in the stomach, or tension in the hands?',
          'Rate its physical intensity from 1 to 10.',
          'Observe it objectively like a scientist observing weather changes.'
        ],
      },
      // Day 10
      {
        'title': 'Bilateral Butterfly Tapping',
        'category': 'Sensory Grounding',
        'desc': 'Alternate gentle taps on opposite shoulders to re-balance brain hemispheres.',
        'sec': 240,
        'type': 'steps',
        'benefit': 'EMDR-based bilateral stimulation calms emotional amygdala hyper-reactivity.',
        'steps': [
          'Cross your arms over your chest so your fingers touch your upper arms.',
          'Alternate tapping your left and right hand rhythmically like butterfly wings.',
          'Breathe deeply in sync with the steady left-right rhythm for 2 minutes.'
        ],
      },
    ];

    // Build full 90-day catalog using rich psychological themes
    for (int day = 1; day <= 90; day++) {
      final base = bases[(day - 1) % bases.length];
      final String category = _determineCategory(day);
      final String title = _generateDayTitle(day, category, base['title']);
      final String desc = _generateDayDesc(day, category, base['desc']);
      final String benefit = _generateDayBenefit(day, category, base['benefit']);
      final List<String> steps = List<String>.from(base['steps']);

      // Add day-specific micro-adaptation to keep each day unique
      steps.add('Day $day Reflection: Remind yourself that surviving this 15-minute urge strengthens your prefrontal cortex neural pathways permanently.');

      list.add(UrgeActivity(
        dayNumber: day,
        title: title,
        category: category,
        description: desc,
        durationSeconds: base['sec'] as int,
        steps: steps,
        interactiveType: base['type'] as String,
        psychologicalBenefit: benefit,
      ));
    }

    return list;
  }

  static String _determineCategory(int day) {
    switch ((day - 1) % 5) {
      case 0:
        return 'Neuro-Breathing';
      case 1:
        return 'Somatic Physical';
      case 2:
        return 'Cognitive Overload';
      case 3:
        return 'Mindfulness Defusion';
      case 4:
      default:
        return 'Sensory Grounding';
    }
  }

  static String _generateDayTitle(int day, String category, String baseTitle) {
    if (day <= 10) return 'Day $day: $baseTitle';
    
    final prefixes = [
      'Mastery', 'Deep', 'Advanced', 'Focused', 'Rapid', 
      'Precision', 'Somatic', 'Neuro', 'Mindful', 'Core'
    ];
    final prefix = prefixes[(day - 1) % prefixes.length];

    switch (category) {
      case 'Neuro-Breathing':
        return 'Day $day: $prefix Box & Vagal Breathing';
      case 'Somatic Physical':
        return 'Day $day: $prefix Adrenaline Muscle Reset';
      case 'Cognitive Overload':
        return 'Day $day: $prefix Mental Arithmetic Focus';
      case 'Mindfulness Defusion':
        return 'Day $day: $prefix Urge Wave Observation';
      case 'Sensory Grounding':
      default:
        return 'Day $day: $prefix 5-4-3-2-1 Sensory Anchor';
    }
  }

  static String _generateDayDesc(int day, String category, String baseDesc) {
    if (day <= 10) return baseDesc;
    return 'Day $day urge Surfer exercise tailored to disrupt acute craving spikes via $category protocols.';
  }

  static String _generateDayBenefit(int day, String category, String baseBenefit) {
    if (day <= 10) return baseBenefit;
    return 'Consistent Day $day practice strengthens neuroplasticity and builds resistance against impulse relapse.';
  }
}
