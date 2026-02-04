import 'milestone_id.dart';
import 'milestone_models.dart';

/// Fast katalog (vanlige terskler)
const List<MilestoneConfig> milestoneCatalog = [
  MilestoneConfig(
    def: MilestoneDef(
      id: MilestoneId.stands1,
      category: MilestoneCategory.firsts,
      title: 'Første stand',
      subtitle: '{dogName} har registrert sin første stand.',
      icon: 'point',
      sortOrder: 10,
    ),
    rule: MilestoneRule(MilestoneRuleType.firstPointEver),
  ),
  MilestoneConfig(
    def: MilestoneDef(
      id: MilestoneId.firstFlush,
      category: MilestoneCategory.firsts,
      title: 'Første støkk',
      subtitle: '{dogName} har registrert sitt første støkk.',
      icon: 'flush',
      sortOrder: 20,
    ),
    rule: MilestoneRule(MilestoneRuleType.firstFlushEver),
  ),
  MilestoneConfig(
    def: MilestoneDef(
      id: MilestoneId.sessions1,
      category: MilestoneCategory.sessions,
      title: 'Første økt',
      subtitle: '{dogName} har logget sin første økt.',
      icon: 'sessions',
      sortOrder: 30,
    ),
    rule: MilestoneRule(
      MilestoneRuleType.totalSessionsAtLeast,
      threshold: 1,
    ),
  ),
  MilestoneConfig(
    def: MilestoneDef(
      id: MilestoneId.sessions10,
      category: MilestoneCategory.sessions,
      title: '10 økter',
      subtitle: '{dogName} har logget 10 økter.',
      icon: 'sessions',
      sortOrder: 40,
    ),
    rule: MilestoneRule(
      MilestoneRuleType.totalSessionsAtLeast,
      threshold: 10,
    ),
  ),
  MilestoneConfig(
    def: MilestoneDef(
      id: MilestoneId.sessions25,
      category: MilestoneCategory.sessions,
      title: '25 økter',
      subtitle: '{dogName} har logget 25 økter.',
      icon: 'sessions',
      sortOrder: 50,
    ),
    rule: MilestoneRule(
      MilestoneRuleType.totalSessionsAtLeast,
      threshold: 25,
    ),
  ),
  MilestoneConfig(
    def: MilestoneDef(
      id: MilestoneId.sessions50,
      category: MilestoneCategory.sessions,
      title: '50 økter',
      subtitle: '{dogName} har logget 50 økter.',
      icon: 'sessions',
      sortOrder: 60,
    ),
    rule: MilestoneRule(
      MilestoneRuleType.totalSessionsAtLeast,
      threshold: 50,
    ),
  ),
  MilestoneConfig(
    def: MilestoneDef(
      id: MilestoneId.sessions100,
      category: MilestoneCategory.sessions,
      title: '100 økter',
      subtitle: '{dogName} har logget 100 økter.',
      icon: 'sessions',
      sortOrder: 70,
    ),
    rule: MilestoneRule(
      MilestoneRuleType.totalSessionsAtLeast,
      threshold: 100,
    ),
  ),
  MilestoneConfig(
    def: MilestoneDef(
      id: MilestoneId.sessions200,
      category: MilestoneCategory.sessions,
      title: '200 økter',
      subtitle: '{dogName} har logget 200 økter.',
      icon: 'sessions',
      sortOrder: 80,
    ),
    rule: MilestoneRule(
      MilestoneRuleType.totalSessionsAtLeast,
      threshold: 200,
    ),
  ),
  MilestoneConfig(
    def: MilestoneDef(
      id: MilestoneId.sessions300,
      category: MilestoneCategory.sessions,
      title: '300 økter',
      subtitle: '{dogName} har logget 300 økter.',
      icon: 'sessions',
      sortOrder: 90,
    ),
    rule: MilestoneRule(
      MilestoneRuleType.totalSessionsAtLeast,
      threshold: 300,
    ),
  ),

  // --- Stander ---
  MilestoneConfig(
    def: MilestoneDef(
      id: MilestoneId.stands10,
      category: MilestoneCategory.points,
      title: '10 stander',
      subtitle: '{dogName} har registrert 10 stander.',
      icon: 'point',
      sortOrder: 100,
    ),
    rule: MilestoneRule(
      MilestoneRuleType.totalPointsAtLeast,
      threshold: 10,
    ),
  ),
  MilestoneConfig(
    def: MilestoneDef(
      id: MilestoneId.stands25,
      category: MilestoneCategory.points,
      title: '25 stander',
      subtitle: '{dogName} har registrert 25 stander.',
      icon: 'point',
      sortOrder: 110,
    ),
    rule: MilestoneRule(
      MilestoneRuleType.totalPointsAtLeast,
      threshold: 25,
    ),
  ),
  MilestoneConfig(
    def: MilestoneDef(
      id: MilestoneId.stands50,
      category: MilestoneCategory.points,
      title: '50 stander',
      subtitle: '{dogName} har registrert 50 stander.',
      icon: 'point',
      sortOrder: 120,
    ),
    rule: MilestoneRule(
      MilestoneRuleType.totalPointsAtLeast,
      threshold: 50,
    ),
  ),
  MilestoneConfig(
    def: MilestoneDef(
      id: MilestoneId.stands100,
      category: MilestoneCategory.points,
      title: '100 stander',
      subtitle: '{dogName} har registrert 100 stander.',
      icon: 'point',
      sortOrder: 130,
    ),
    rule: MilestoneRule(
      MilestoneRuleType.totalPointsAtLeast,
      threshold: 100,
    ),
  ),
  MilestoneConfig(
    def: MilestoneDef(
      id: MilestoneId.stands200,
      category: MilestoneCategory.points,
      title: '200 stander',
      subtitle: '{dogName} har registrert 200 stander.',
      icon: 'point',
      sortOrder: 140,
    ),
    rule: MilestoneRule(
      MilestoneRuleType.totalPointsAtLeast,
      threshold: 200,
    ),
  ),
  MilestoneConfig(
    def: MilestoneDef(
      id: MilestoneId.stands300,
      category: MilestoneCategory.points,
      title: '300 stander',
      subtitle: '{dogName} har registrert 300 stander.',
      icon: 'point',
      sortOrder: 150,
    ),
    rule: MilestoneRule(
      MilestoneRuleType.totalPointsAtLeast,
      threshold: 300,
    ),
  ),

  MilestoneConfig(
    def: MilestoneDef(
      id: MilestoneId.stands400,
      category: MilestoneCategory.points,
      title: '400 stander',
      subtitle: '{dogName} har registrert 400 stander.',
      icon: 'point',
      sortOrder: 160,
    ),
    rule: MilestoneRule(
      MilestoneRuleType.totalPointsAtLeast,
      threshold: 400,
    ),
  ),
  MilestoneConfig(
    def: MilestoneDef(
      id: MilestoneId.stands500,
      category: MilestoneCategory.points,
      title: '500 stander',
      subtitle: '{dogName} har registrert 500 stander.',
      icon: 'point',
      sortOrder: 170,
    ),
    rule: MilestoneRule(
      MilestoneRuleType.totalPointsAtLeast,
      threshold: 500,
    ),
  ),
  MilestoneConfig(
    def: MilestoneDef(
      id: MilestoneId.stands600,
      category: MilestoneCategory.points,
      title: '600 stander',
      subtitle: '{dogName} har registrert 600 stander.',
      icon: 'point',
      sortOrder: 180,
    ),
    rule: MilestoneRule(
      MilestoneRuleType.totalPointsAtLeast,
      threshold: 600,
    ),
  ),
  MilestoneConfig(
    def: MilestoneDef(
      id: MilestoneId.stands700,
      category: MilestoneCategory.points,
      title: '700 stander',
      subtitle: '{dogName} har registrert 700 stander.',
      icon: 'point',
      sortOrder: 190,
    ),
    rule: MilestoneRule(
      MilestoneRuleType.totalPointsAtLeast,
      threshold: 700,
    ),
  ),
  MilestoneConfig(
    def: MilestoneDef(
      id: MilestoneId.stands800,
      category: MilestoneCategory.points,
      title: '800 stander',
      subtitle: '{dogName} har registrert 800 stander.',
      icon: 'point',
      sortOrder: 200,
    ),
    rule: MilestoneRule(
      MilestoneRuleType.totalPointsAtLeast,
      threshold: 800,
    ),
  ),
  MilestoneConfig(
    def: MilestoneDef(
      id: MilestoneId.stands900,
      category: MilestoneCategory.points,
      title: '900 stander',
      subtitle: '{dogName} har registrert 900 stander.',
      icon: 'point',
      sortOrder: 210,
    ),
    rule: MilestoneRule(
      MilestoneRuleType.totalPointsAtLeast,
      threshold: 900,
    ),
  ),
  MilestoneConfig(
    def: MilestoneDef(
      id: MilestoneId.stands1000,
      category: MilestoneCategory.points,
      title: '1000 stander',
      subtitle: '{dogName} har registrert 1000 stander.',
      icon: 'point',
      sortOrder: 220,
    ),
    rule: MilestoneRule(
      MilestoneRuleType.totalPointsAtLeast,
      threshold: 1000,
    ),
  ),

  // --- Fuglefelte ---
  MilestoneConfig(
    def: MilestoneDef(
      id: MilestoneId.birdsFelled1,
      category: MilestoneCategory.points,
      title: 'Første fugl',
      subtitle: '{dogName} har felt sin første fugl.',
      icon: 'bird',
      sortOrder: 235,
    ),
    rule: MilestoneRule(
      MilestoneRuleType.totalBirdsAtLeast,
      threshold: 1,
    ),
  ),
  MilestoneConfig(
    def: MilestoneDef(
      id: MilestoneId.birdsFelled10,
      category: MilestoneCategory.points,
      title: '10 fugl felt',
      subtitle: '{dogName} har felt 10 fugl.',
      icon: 'bird',
      sortOrder: 240,
    ),
    rule: MilestoneRule(
      MilestoneRuleType.totalBirdsAtLeast,
      threshold: 10,
    ),
  ),
  MilestoneConfig(
    def: MilestoneDef(
      id: MilestoneId.birdsFelled25,
      category: MilestoneCategory.points,
      title: '25 fugl felt',
      subtitle: '{dogName} har felt 25 fugl.',
      icon: 'bird',
      sortOrder: 250,
    ),
    rule: MilestoneRule(
      MilestoneRuleType.totalBirdsAtLeast,
      threshold: 25,
    ),
  ),
  MilestoneConfig(
    def: MilestoneDef(
      id: MilestoneId.birdsFelled50,
      category: MilestoneCategory.points,
      title: '50 fugl felt',
      subtitle: '{dogName} har felt 50 fugl.',
      icon: 'bird',
      sortOrder: 260,
    ),
    rule: MilestoneRule(
      MilestoneRuleType.totalBirdsAtLeast,
      threshold: 50,
    ),
  ),
  MilestoneConfig(
    def: MilestoneDef(
      id: MilestoneId.birdsFelled100,
      category: MilestoneCategory.points,
      title: '100 fugl felt',
      subtitle: '{dogName} har felt 100 fugl.',
      icon: 'bird',
      sortOrder: 270,
    ),
    rule: MilestoneRule(
      MilestoneRuleType.totalBirdsAtLeast,
      threshold: 100,
    ),
  ),
  MilestoneConfig(
    def: MilestoneDef(
      id: MilestoneId.birdsFelled200,
      category: MilestoneCategory.points,
      title: '200 fugl felt',
      subtitle: '{dogName} har felt 200 fugl.',
      icon: 'bird',
      sortOrder: 280,
    ),
    rule: MilestoneRule(
      MilestoneRuleType.totalBirdsAtLeast,
      threshold: 200,
    ),
  ),
  MilestoneConfig(
    def: MilestoneDef(
      id: MilestoneId.birdsFelled300,
      category: MilestoneCategory.points,
      title: '300 fugl felt',
      subtitle: '{dogName} har felt 300 fugl.',
      icon: 'bird',
      sortOrder: 290,
    ),
    rule: MilestoneRule(
      MilestoneRuleType.totalBirdsAtLeast,
      threshold: 300,
    ),
  ),
  MilestoneConfig(
    def: MilestoneDef(
      id: MilestoneId.birdsFelled400,
      category: MilestoneCategory.points,
      title: '400 fugl felt',
      subtitle: '{dogName} har felt 400 fugl.',
      icon: 'bird',
      sortOrder: 300,
    ),
    rule: MilestoneRule(
      MilestoneRuleType.totalBirdsAtLeast,
      threshold: 400,
    ),
  ),
  MilestoneConfig(
    def: MilestoneDef(
      id: MilestoneId.birdsFelled500,
      category: MilestoneCategory.points,
      title: '500 fugl felt',
      subtitle: '{dogName} har felt 500 fugl.',
      icon: 'bird',
      sortOrder: 310,
    ),
    rule: MilestoneRule(
      MilestoneRuleType.totalBirdsAtLeast,
      threshold: 500,
    ),
  ),
  MilestoneConfig(
    def: MilestoneDef(
      id: MilestoneId.birdsFelled600,
      category: MilestoneCategory.points,
      title: '600 fugl felt',
      subtitle: '{dogName} har felt 600 fugl.',
      icon: 'bird',
      sortOrder: 320,
    ),
    rule: MilestoneRule(
      MilestoneRuleType.totalBirdsAtLeast,
      threshold: 600,
    ),
  ),
  MilestoneConfig(
    def: MilestoneDef(
      id: MilestoneId.birdsFelled700,
      category: MilestoneCategory.points,
      title: '700 fugl felt',
      subtitle: '{dogName} har felt 700 fugl.',
      icon: 'bird',
      sortOrder: 330,
    ),
    rule: MilestoneRule(
      MilestoneRuleType.totalBirdsAtLeast,
      threshold: 700,
    ),
  ),
  MilestoneConfig(
    def: MilestoneDef(
      id: MilestoneId.birdsFelled800,
      category: MilestoneCategory.points,
      title: '800 fugl felt',
      subtitle: '{dogName} har felt 800 fugl.',
      icon: 'bird',
      sortOrder: 340,
    ),
    rule: MilestoneRule(
      MilestoneRuleType.totalBirdsAtLeast,
      threshold: 800,
    ),
  ),
  MilestoneConfig(
    def: MilestoneDef(
      id: MilestoneId.birdsFelled900,
      category: MilestoneCategory.points,
      title: '900 fugl felt',
      subtitle: '{dogName} har felt 900 fugl.',
      icon: 'bird',
      sortOrder: 350,
    ),
    rule: MilestoneRule(
      MilestoneRuleType.totalBirdsAtLeast,
      threshold: 900,
    ),
  ),
  MilestoneConfig(
    def: MilestoneDef(
      id: MilestoneId.birdsFelled1000,
      category: MilestoneCategory.points,
      title: '1000 fugl felt',
      subtitle: '{dogName} har felt 1000 fugl.',
      icon: 'bird',
      sortOrder: 360,
    ),
    rule: MilestoneRule(
      MilestoneRuleType.totalBirdsAtLeast,
      threshold: 1000,
    ),
  ),

  // --- Tid ---
  MilestoneConfig(
    def: MilestoneDef(
      id: MilestoneId.activeHours10,
      category: MilestoneCategory.time,
      title: '10 timer aktiv',
      subtitle: '{dogName} har passert 10 timer aktiv tid.',
      icon: 'time',
      sortOrder: 230,
    ),
    rule: MilestoneRule(
      MilestoneRuleType.totalActiveSecondsAtLeast,
      threshold: 10 * 60 * 60,
    ),
  ),
];

MilestoneDef? milestoneDefById(String id) {
  // 1) Sjekk først fast katalog (så 100/200/300 bruker de pene, faste definisjonene)
  for (final config in milestoneCatalog) {
    if (config.def.id == id) return config.def;
  }

  // 2) Deretter “century” (dynamiske, typ 400/500/600...)
  final century = _centuryFromId(id);
  if (century != null) return _centuryDef(century);

  return null;
}

String milestoneSubtitle(MilestoneDef def, String dogName) {
  return def.subtitle.replaceAll('{dogName}', dogName);
}

bool isCenturyMilestoneId(String id) {
  return _centuryFromId(id) != null;
}

MilestoneDef centuryMilestoneDef(int stands) {
  return _centuryDef(stands);
}

int? _centuryFromId(String id) {
  if (!id.startsWith('stands_')) return null;

  final value = int.tryParse(id.substring('stands_'.length));
  if (value == null) return null;

  // Vi vil helst bruke faste defs for 100/200/300. Dynamiske starter på 400.
  if (value < 400) return null;

  if (value % 100 != 0) return null;
  return value;
}

MilestoneDef _centuryDef(int stands) {
  final title = stands == 1 ? '1 stand' : '$stands stander';

  return MilestoneDef(
    id: 'stands_$stands',
    category: MilestoneCategory.points,
    title: title,
    subtitle: '{dogName} har passert $stands stander.',
    icon: 'century',
    sortOrder: 1000 + stands,
  );
}
