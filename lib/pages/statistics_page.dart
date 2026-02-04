// lib/pages/statistics_page.dart
import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../data/hive_boxes.dart';
import '../models/dog.dart';
import '../models/hunt_session.dart';
import '../services/hive_lifecycle_service.dart';
import '../utils/dog_label_resolver.dart';
import '../l10n/app_localizations.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

enum _V1Period { days30, days90 }

class _StatisticsPageState extends State<StatisticsPage> {
  static const _lastDogKey = 'statistics_last_dog_id';

  late final Box<HuntSession> _sessionsBox;
  late final Box<Dog> _dogsBox;
  late final Box<dynamic> _settingsBox;

  String? _selectedDogId;
  _V1Period _v1Period = _V1Period.days30;
  int? _selectedYear;
  int? _touchedSpeciesIndex;
  String? _speciesTooltipText;

  @override
  void initState() {
    super.initState();
    _sessionsBox = HiveLifecycleService.getBox<HuntSession>(sessionsBoxName);
    _dogsBox = HiveLifecycleService.getBox<Dog>(dogsBoxName);
    _settingsBox = HiveLifecycleService.getBox<dynamic>(appSettingsBoxName);
    _selectedDogId = _settingsBox.get(_lastDogKey) as String?;
  }

  void _updateSelectedDog(String? dogId) {
    if (_selectedDogId == dogId) return;
    setState(() {
      _selectedDogId = dogId;
    });
    if (dogId == null) {
      _settingsBox.delete(_lastDogKey);
    } else {
      _settingsBox.put(_lastDogKey, dogId);
    }
  }

  void _setPeriod(_V1Period period) {
    if (_v1Period == period) return;
    setState(() {
      _v1Period = period;
    });
  }

  int get _chartDays => _v1Period == _V1Period.days30 ? 30 : 90;

  List<HuntSession> _sessionsForDog(String dogId, Box<HuntSession> box) {
    return box.values
        .where((session) => session.dogId == dogId)
        .toList(growable: false);
  }

  DateTime _weekStart(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    final offset = normalized.weekday - DateTime.monday;
    return normalized.subtract(Duration(days: offset));
  }

  /// Robust uke-nummer (kun sifre).
  String _weekNumberDigits(DateTime date) {
    try {
      final raw = DateFormat('w', 'nb_NO').format(date);
      return raw.replaceAll(RegExp(r'[^0-9]'), '');
    } catch (_) {
      return '';
    }
  }

  List<_WeekStats> _weekStats(List<HuntSession> sessions, int days) {
    if (sessions.isEmpty) return <_WeekStats>[];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final startBoundary = today.subtract(Duration(days: days - 1));
    final firstWeek = _weekStart(startBoundary);
    final lastWeek = _weekStart(today);

    final weeks = <DateTime, _WeekStats>{};
    var cursor = firstWeek;
    while (!cursor.isAfter(lastWeek)) {
      weeks[cursor] = _WeekStats(weekStart: cursor);
      cursor = cursor.add(const Duration(days: 7));
    }

    for (final session in sessions) {
      if (session.durationMinutes < 0) continue;
      final sessionWeek = _weekStart(session.dateTime);
      if (sessionWeek.isBefore(firstWeek) || sessionWeek.isAfter(lastWeek)) {
        continue;
      }
      final stats = weeks.putIfAbsent(
          sessionWeek, () => _WeekStats(weekStart: sessionWeek));
      stats.sessions += 1;
      stats.totalMinutes += session.durationMinutes;
    }

    final positiveWeeks = weeks.values.where((w) => w.sessions > 0).toList()
      ..sort((a, b) => a.weekStart.compareTo(b.weekStart));

    for (var i = 0; i < positiveWeeks.length; i++) {
      positiveWeeks[i].index = i;
    }
    return positiveWeeks;
  }

  String _formatDurationMinutes(int minutes) {
    if (minutes <= 0) return '0 min';
    final hours = minutes ~/ 60;
    final rem = minutes % 60;
    if (hours == 0) return '$rem min';
    if (rem == 0) return '$hours t';
    return '$hours t $rem min';
  }

  String _formatDecimal(double value) {
    final formatter = NumberFormat('0.0', 'nb_NO');
    return formatter.format(value.isNaN ? 0 : value);
  }

  String _weekDisplayLabel(_WeekStats week, AppLocalizations l10n) {
    final digits = _weekNumberDigits(week.weekStart);
    final weekNumber = digits.isNotEmpty ? int.parse(digits) : 1;
    return l10n.stats_week_label(weekNumber);
  }

  String _weekTooltip(_WeekStats week, AppLocalizations l10n) {
    final hours = week.totalMinutes ~/ 60;
    final minutes = week.totalMinutes % 60;
    final timeLabel = minutes > 0 ? '$hours t $minutes min' : '$hours t';
    return l10n.stats_week_tooltip(
      _weekDisplayLabel(week, l10n),
      week.sessions,
      timeLabel,
    );
  }

  // ---------- Monthly helpers ----------
  List<int> _monthCountsForYear(List<HuntSession> sessions, int year) {
    final counts = List<int>.filled(12, 0);
    for (final s in sessions) {
      if (s.dateTime.year != year) continue;
      final idx = s.dateTime.month - 1;
      if (idx < 0 || idx >= 12) continue;
      counts[idx] += 1;
    }
    return counts;
  }

  List<int> _standsByMonthForYear(List<HuntSession> sessions, int year) {
    final counts = List<int>.filled(12, 0);
    for (final s in sessions) {
      if (s.dateTime.year != year) continue;
      final idx = s.dateTime.month - 1;
      if (idx < 0 || idx >= 12) continue;
      counts[idx] += s.points;
    }
    return counts;
  }

  List<int> _flushesByMonthForYear(List<HuntSession> sessions, int year) {
    final counts = List<int>.filled(12, 0);
    for (final s in sessions) {
      if (s.dateTime.year != year) continue;
      final idx = s.dateTime.month - 1;
      if (idx < 0 || idx >= 12) continue;
      counts[idx] += s.flushes;
    }
    return counts;
  }

  List<int> _availableYearsForDog(List<HuntSession> sessions) {
    final years = <int>{};
    for (final s in sessions) {
      years.add(s.dateTime.year);
    }
    final sorted = years.toList()..sort((a, b) => b.compareTo(a));
    return sorted;
  }

  String _monthName(int index) {
    final locale = Localizations.localeOf(context);
    return DateFormat.MMM(locale.toString())
        .format(DateTime(2000, index + 1, 1));
  }

  int _axisLabelStep(int total) {
    if (total > 12) return 3;
    if (total > 6) return 2;
    return 1;
  }

  Map<int, int> _birdsPerYear(List<HuntSession> sessions) {
    final counts = <int, int>{};
    for (final session in sessions) {
      final birdCount = session.birdsShotCount;
      if (birdCount <= 0) continue;
      final year = session.dateTime.year;
      counts[year] = (counts[year] ?? 0) + birdCount;
    }
    return counts;
  }

  Map<String, int> _birdsBySpeciesForYear({
    required List<HuntSession> sessions,
    required int year,
    required AppLocalizations l10n,
  }) {
    final counts = <String, int>{};
    for (final session in sessions) {
      if (session.dateTime.year != year) continue;
      if (session.birdsShotCount <= 0) continue;
      final species = (session.birdsShotSpecies ?? '').trim();
      final label = species.isEmpty ? l10n.stats_unknown_species : species;
      counts[label] = (counts[label] ?? 0) + session.birdsShotCount;
    }
    return counts;
  }

  List<FlSpot> _bucketSpots(List<num> values) {
    return values.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.toDouble());
    }).toList();
  }

  Widget _buildWeekAxisLabel(
    double value,
    TitleMeta meta,
    List<_WeekStats> weeklyStats,
    Color textColor,
    AppLocalizations l10n,
  ) {
    final idx = value.toInt();
    if (idx < 0 || idx >= weeklyStats.length) return const SizedBox.shrink();
    final step = _axisLabelStep(weeklyStats.length);
    if (idx % step != 0 && idx != weeklyStats.length - 1) {
      return const SizedBox.shrink();
    }
    final label = _weekDisplayLabel(weeklyStats[idx], l10n);
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: meta.axisSide == AxisSide.bottom
            ? TextStyle(color: textColor, fontSize: 10)
            : TextStyle(color: textColor),
      ),
    );
  }

  Widget _buildMonthAxisLabel(
    double value,
    TitleMeta meta,
    Color textColor,
  ) {
    final idx = value.toInt();
    if (idx < 0 || idx >= 12) return const SizedBox.shrink();
    final step = _axisLabelStep(12);
    if (idx % step != 0 && idx != 11) return const SizedBox.shrink();
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        _monthName(idx),
        style: TextStyle(color: textColor, fontSize: 10),
      ),
    );
  }

  Widget _buildYearAxisLabel(
    double value,
    TitleMeta meta,
    List<int> years,
    Color textColor,
  ) {
    if (years.isEmpty) return const SizedBox.shrink();
    final idx = value.toInt();
    if (idx < 0 || idx >= years.length) return const SizedBox.shrink();
    final step = _axisLabelStep(years.length);
    if (idx % step != 0 && idx != years.length - 1) {
      return const SizedBox.shrink();
    }
    return SideTitleWidget(
      axisSide: meta.axisSide,
      child: Text(
        years[idx].toString(),
        style: TextStyle(color: textColor, fontSize: 10),
      ),
    );
  }

  // --- counts only from first month with activity (for trend arrow) ---
  List<int> _countsFromFirstActivity(List<int> counts) {
    final firstIndex = counts.indexWhere((c) => c > 0);
    if (firstIndex == -1) return const <int>[];
    return counts.sublist(firstIndex);
  }

  double _linearTrendSlope(List<int> counts) {
    if (counts.length < 2) return 0;

    final n = counts.length;
    double sumX = 0, sumY = 0, sumXY = 0, sumX2 = 0;

    for (var i = 0; i < n; i++) {
      final x = i.toDouble();
      final y = counts[i].toDouble();
      sumX += x;
      sumY += y;
      sumXY += x * y;
      sumX2 += x * x;
    }

    final denom = n * sumX2 - sumX * sumX;
    if (denom.abs() < 1e-6) return 0;
    return (n * sumXY - sumX * sumY) / denom;
  }

  String _trendSymbol(double slope) {
    const threshold = 0.1;
    if (slope > threshold) return '↑';
    if (slope < -threshold) return '↓';
    return '→';
  }

  void _showGraphInfoSheet({
    required String title,
    required String emoji,
    required List<String> lines,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: false,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        title,
                        style: theme.textTheme.titleMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                for (final line in lines) ...[
                  Text(line, style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 6),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.statistics)),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ValueListenableBuilder(
          valueListenable: _dogsBox.listenable(),
          builder: (context, Box<Dog> dogBox, _) {
            final dogs = dogBox.values.toList()
              ..sort((a, b) =>
                  a.name.toLowerCase().compareTo(b.name.toLowerCase()));

            if (dogs.isEmpty) {
              return Center(child: Text(l10n.home_no_dogs_title));
            }

            final labelResolver = DogLabelResolver(dogs);

            var currentDogId = _selectedDogId;
            if (currentDogId == null ||
                dogs.every((d) => d.id != currentDogId)) {
              currentDogId = dogs.first.id;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _updateSelectedDog(currentDogId);
              });
            }

            return ValueListenableBuilder(
              valueListenable: _sessionsBox.listenable(),
              builder: (context, Box<HuntSession> sessionsBox, _) {
                final sessions = currentDogId == null
                    ? <HuntSession>[]
                    : _sessionsForDog(currentDogId, sessionsBox);

                final totalSessions = sessions.length;
                final totalPoints =
                    sessions.fold<int>(0, (sum, s) => sum + s.points);
                final totalMinutes =
                    sessions.fold<int>(0, (sum, s) => sum + s.durationMinutes);

                final now = DateTime.now();
                final periodDays = _chartDays;
                final periodCutoff = now.subtract(Duration(days: periodDays));
                final last30Cutoff = now.subtract(const Duration(days: 30));

                final last30Sessions = sessions
                    .where((s) => !s.dateTime.isBefore(last30Cutoff))
                    .toList();
                final last30Points =
                    last30Sessions.fold<int>(0, (sum, s) => sum + s.points);

                final sessionsInPeriod = sessions
                    .where((s) => !s.dateTime.isBefore(periodCutoff))
                    .toList();

                if (kDebugMode) {
                  debugPrint(
                    'Statistics|dog=$_selectedDogId sessionsBox=${sessionsBox.length} '
                    'totalForDog=$totalSessions period=${sessionsInPeriod.length} days=$periodDays',
                  );
                }

                final overviewCards = <Widget>[];
                if (totalSessions > 0) {
                  overviewCards.add(_StatisticCard(
                    title: l10n.stats_subtitle_session_count,
                    value: l10n.stats_overview_sessions_value(totalSessions),
                  ));
                }
                if (totalPoints > 0) {
                  overviewCards.add(_StatisticCard(
                    title: l10n.stats_title_points_and_flushes,
                    value: l10n.stats_overview_points_value(totalPoints),
                  ));
                }
                if (totalMinutes > 0) {
                  overviewCards.add(
                    _StatisticCard(
                      title: l10n.stats_subtitle_active_time,
                      value: _formatDurationMinutes(totalMinutes),
                    ),
                  );
                }
                if (totalSessions > 0 && totalPoints > 0) {
                  overviewCards.add(
                    _StatisticCard(
                      title: l10n.stats_avg_points_per_session_title,
                      value: _formatDecimal(
                          totalPoints.toDouble() / totalSessions),
                    ),
                  );
                }
                if (totalSessions > 0 && totalMinutes > 0) {
                  final avgMin = (totalMinutes / totalSessions).round();
                  if (avgMin > 0) {
                    overviewCards.add(
                      _StatisticCard(
                        title: l10n.stats_avg_time_per_session_title,
                        value: _formatDurationMinutes(avgMin),
                      ),
                    );
                  }
                }
                if (last30Sessions.isNotEmpty) {
                  overviewCards.add(
                    _StatisticCard(
                      title: l10n.stats_last_30_days_sessions_title,
                      value: l10n.stats_last_30_days_sessions_value(
                        last30Sessions.length,
                      ),
                    ),
                  );
                }
                if (last30Points > 0) {
                  overviewCards.add(
                    _StatisticCard(
                      title: l10n.stats_last_30_days_points_title,
                      value: l10n.stats_last_30_days_points_value(
                        last30Points,
                      ),
                    ),
                  );
                }

                final weeklyStats = _weekStats(sessions, periodDays);
                final availableYears = _availableYearsForDog(sessions);

                int? activeYear = _selectedYear;
                if (activeYear == null ||
                    !availableYears.contains(activeYear)) {
                  activeYear =
                      availableYears.isNotEmpty ? availableYears.first : null;
                  if (activeYear != _selectedYear) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (!mounted) return;
                      setState(() => _selectedYear = activeYear);
                    });
                  }
                }

                final monthCounts = activeYear != null
                    ? _monthCountsForYear(sessions, activeYear)
                    : List<int>.filled(12, 0);
                final standCounts = activeYear != null
                    ? _standsByMonthForYear(sessions, activeYear)
                    : List<int>.filled(12, 0);
                final flushCounts = activeYear != null
                    ? _flushesByMonthForYear(sessions, activeYear)
                    : List<int>.filled(12, 0);

                final monthlyHasData =
                    activeYear != null && monthCounts.any((c) => c > 0);
                final standFlushHasData = activeYear != null &&
                    (standCounts.any((c) => c > 0) ||
                        flushCounts.any((c) => c > 0));
                final hasGraphs = weeklyStats.length >= 2 ||
                    monthlyHasData ||
                    standFlushHasData;

                return ListView(
                  children: [
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: currentDogId,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: l10n.chooseDog,
                      ),
                      isExpanded: true,
                      items: dogs
                          .map(
                            (dog) => DropdownMenuItem<String>(
                              value: dog.id,
                              child: Text(labelResolver.labelForDog(dog)),
                            ),
                          )
                          .toList(),
                      onChanged: (value) => _updateSelectedDog(value),
                    ),
                    const SizedBox(height: 16),
                    if (overviewCards.isNotEmpty) ...[
                      Text(l10n.stats_title_development,
                          style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 12),
                      Wrap(
                          spacing: 12, runSpacing: 12, children: overviewCards),
                      const SizedBox(height: 24),
                    ],
                    if (hasGraphs)
                      _buildGraphsSection(
                        l10n: l10n,
                        sessions: sessions,
                        weeklyStats: weeklyStats,
                        availableYears: availableYears,
                        selectedYear: activeYear,
                        monthCounts: monthCounts,
                        standCounts: standCounts,
                        flushCounts: flushCounts,
                      ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildGraphsSection({
    required AppLocalizations l10n,
    required List<HuntSession> sessions,
    required List<_WeekStats> weeklyStats,
    required List<int> availableYears,
    required int? selectedYear,
    required List<int> monthCounts,
    required List<int> standCounts,
    required List<int> flushCounts,
  }) {
    final theme = Theme.of(context);

    final isAppLight = theme.brightness == Brightness.light;
    final panelColor = isAppLight ? Colors.grey.shade900 : Colors.grey.shade50;
    final panelTextColor =
        isAppLight ? Colors.white : theme.colorScheme.onSurface;
    final panelSubTextColor =
        isAppLight ? Colors.white70 : theme.colorScheme.primary;
    final panelBorderColor = isAppLight ? Colors.black26 : Colors.grey.shade300;

    final barColor = isAppLight
        ? Colors.lightBlueAccent.shade200
        : theme.colorScheme.primary;
    final lineColor =
        isAppLight ? Colors.orangeAccent : theme.colorScheme.secondary;

    final standColor =
        isAppLight ? Colors.lightGreenAccent.shade700 : Colors.green;
    final flushColor =
        isAppLight ? Colors.deepOrangeAccent.shade200 : Colors.deepOrange;

    final gridColor = isAppLight ? Colors.white24 : Colors.black26;
    final tooltipBgColor =
        isAppLight ? Colors.grey.shade800 : Colors.grey.shade200;
    final tooltipTextColor = isAppLight ? Colors.white : Colors.black;

    final axisLabelColor = panelSubTextColor;

    final maxMinutes = weeklyStats.isEmpty
        ? 0
        : weeklyStats.map((w) => w.totalMinutes).fold<int>(0, math.max);
    final maxHours = (maxMinutes / 60).ceil();
    final maxSessions = weeklyStats.isEmpty
        ? 0
        : weeklyStats.map((w) => w.sessions).fold<int>(0, math.max);

    final weeklyBar = weeklyStats.length >= 2
        ? _buildWeeklyActiveTimeBars(
            weeklyStats,
            maxHours,
            barColor,
            tooltipBgColor,
            tooltipTextColor,
            gridColor,
            axisLabelColor,
            l10n,
          )
        : null;

    final weeklyLine = weeklyStats.length >= 2
        ? _buildWeeklySessionsLine(
            weeklyStats,
            maxSessions,
            lineColor,
            gridColor,
          )
        : null;

    final hasMonthlySessions = monthCounts.any((c) => c > 0);
    final hasStandFlush =
        standCounts.any((c) => c > 0) || flushCounts.any((c) => c > 0);

    final yearlyBirdsMap = _birdsPerYear(sessions);
    final nonZeroEntries = yearlyBirdsMap.entries
        .where((entry) => entry.value > 0)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final hasYearlyBirds = nonZeroEntries.isNotEmpty;
    final yearlyYears = nonZeroEntries.map((entry) => entry.key).toList();
    final yearlyCounts = nonZeroEntries.map((entry) => entry.value).toList();
    final speciesCounts = selectedYear != null
        ? _birdsBySpeciesForYear(
            sessions: sessions,
            year: selectedYear,
            l10n: l10n,
          )
        : <String, int>{};
    final speciesEntries = speciesCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final speciesPalette = [
      Colors.deepOrangeAccent,
      Colors.lightBlueAccent,
      Colors.greenAccent,
      Colors.amber,
      Colors.purpleAccent,
      Colors.tealAccent,
      Colors.pinkAccent,
      Colors.indigoAccent,
      Colors.brown,
      Colors.cyanAccent,
    ];

    final totalYearSessions = monthCounts.fold<int>(0, (a, b) => a + b);
    final totalYearStand = standCounts.fold<int>(0, (a, b) => a + b);
    final totalYearFlush = flushCounts.fold<int>(0, (a, b) => a + b);

    Widget _sectionWrap({
      required Widget child,
      required bool isAppLight,
      required Color panelBorderColor,
    }) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: panelBorderColor.withOpacity(isAppLight ? 0.35 : 0.6),
          ),
          color: isAppLight
              ? Colors.white.withOpacity(0.06)
              : Colors.black.withOpacity(0.04),
        ),
        child: child,
      );
    }

    final graphSections = <Widget>[];

    void addSection(Widget child, {bool highlight = false}) {
      if (highlight) {
        graphSections.add(_sectionWrap(
          child: child,
          isAppLight: isAppLight,
          panelBorderColor: panelBorderColor,
        ));
      } else {
        graphSections.add(child);
      }
    }

    if (selectedYear != null && hasStandFlush) {
      addSection(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Text(
                    l10n.stats_title_points_and_flushes,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: panelTextColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 20,
                  tooltip: l10n.stats_info_explanation_tooltip,
                  onPressed: () => _showGraphInfoSheet(
                    title: l10n.stats_info_points_flushes_title,
                    emoji: '🐕',
                    lines: [
                      l10n.stats_info_points_flushes_body_1,
                      l10n.stats_info_points_flushes_body_2,
                    ],
                  ),
                  icon: Icon(Icons.info_outline, color: panelSubTextColor),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.stats_per_month_suffix(selectedYear),
              style:
                  theme.textTheme.bodySmall?.copyWith(color: panelSubTextColor),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.stats_total_points_flushes_prefix(
                totalYearStand,
                totalYearFlush,
              ),
              style:
                  theme.textTheme.bodySmall?.copyWith(color: panelSubTextColor),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _legendDot(standColor, panelTextColor),
                    const SizedBox(width: 6),
                    Text(l10n.stats_points_label,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: panelSubTextColor)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _legendDot(flushColor, panelTextColor),
                    const SizedBox(width: 6),
                    Text(l10n.stats_flushes_label,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: panelSubTextColor)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _legendLine(standColor),
                    const SizedBox(width: 6),
                    _legendLine(flushColor),
                    const SizedBox(width: 6),
                    Text(l10n.stats_legend_line,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: panelSubTextColor)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(l10n.stats_legend_bars,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: panelSubTextColor)),
                const SizedBox(width: 16),
                Text(l10n.stats_legend_line,
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: panelSubTextColor)),
              ],
            ),
            SizedBox(
              height: 220,
              child: Stack(
                children: [
                  BarChart(
                    _buildStandFlushBars(
                      standCounts: standCounts,
                      flushCounts: flushCounts,
                      year: selectedYear,
                      standColor: standColor,
                      flushColor: flushColor,
                      gridColor: gridColor,
                      tooltipBgColor: tooltipBgColor,
                      tooltipTextColor: tooltipTextColor,
                      axisLabelColor: axisLabelColor,
                      theme: theme,
                      l10n: l10n,
                    ),
                  ),
                  LineChart(
                    _buildStandFlushTrendLines(
                      standCounts: standCounts,
                      flushCounts: flushCounts,
                      standColor: standColor,
                      flushColor: flushColor,
                      gridColor: gridColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        highlight: true,
      );
    }

    if (weeklyBar != null && weeklyLine != null) {
      addSection(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              runSpacing: 8,
              children: [
                Text(
                  l10n.stats_title_development,
                  style: theme.textTheme.titleMedium
                      ?.copyWith(color: panelTextColor),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _periodToggleButton(l10n.stats_period_30_days,
                        _V1Period.days30, panelTextColor, panelSubTextColor),
                    const SizedBox(width: 8),
                    _periodToggleButton(l10n.stats_period_90_days,
                        _V1Period.days90, panelTextColor, panelSubTextColor),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _legendDot(barColor, panelTextColor),
                const SizedBox(width: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.stats_legend_active_time,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: panelTextColor)),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      iconSize: 18,
                      tooltip: l10n.stats_info_explanation_tooltip,
                      onPressed: () => _showGraphInfoSheet(
                        title: l10n.stats_info_active_time_title,
                        emoji: '⏱',
                        lines: [
                          l10n.stats_info_active_time_body_1,
                          l10n.stats_info_active_time_body_2,
                        ],
                      ),
                      icon: Icon(Icons.info_outline, color: panelSubTextColor),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                _legendLine(lineColor),
                const SizedBox(width: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.stats_legend_sessions,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: panelTextColor)),
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      iconSize: 18,
                      tooltip: l10n.stats_info_explanation_tooltip,
                      onPressed: () => _showGraphInfoSheet(
                        title: l10n.stats_info_session_count_title,
                        emoji: '📅',
                        lines: [
                          l10n.stats_info_session_count_body_1,
                          l10n.stats_info_session_count_body_2,
                        ],
                      ),
                      icon: Icon(Icons.info_outline, color: panelSubTextColor),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: Stack(
                children: [
                  BarChart(weeklyBar),
                  LineChart(weeklyLine),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (selectedYear != null && hasMonthlySessions) {
      addSection(
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.stats_title_sessions,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: panelTextColor,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  iconSize: 20,
                  tooltip: l10n.stats_info_explanation_tooltip,
                  onPressed: () => _showGraphInfoSheet(
                    title: l10n.stats_info_sessions_title,
                    emoji: '📅',
                    lines: [
                      l10n.stats_info_sessions_body_1,
                      l10n.stats_info_sessions_body_2,
                    ],
                  ),
                  icon: Icon(Icons.info_outline, color: panelSubTextColor),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              l10n.stats_per_month_suffix(selectedYear),
              style:
                  theme.textTheme.bodySmall?.copyWith(color: panelSubTextColor),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.stats_total_sessions_prefix(totalYearSessions),
              style:
                  theme.textTheme.bodySmall?.copyWith(color: panelSubTextColor),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _legendDot(barColor, panelTextColor),
                    const SizedBox(width: 6),
                    Text(l10n.stats_legend_bars,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: panelSubTextColor)),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _legendLine(lineColor),
                    const SizedBox(width: 6),
                    Text(l10n.stats_legend_line,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: panelSubTextColor)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              l10n.stats_trend_label(_trendSymbol(
                  _linearTrendSlope(_countsFromFirstActivity(monthCounts)))),
              style: theme.textTheme.bodySmall?.copyWith(color: lineColor),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 200,
              child: Stack(
                children: [
                  BarChart(
                    _buildMonthlySessionsBars(
                      monthCounts: monthCounts,
                      year: selectedYear,
                      barColor: barColor,
                      gridColor: gridColor,
                      tooltipBgColor: tooltipBgColor,
                      tooltipTextColor: tooltipTextColor,
                      axisLabelColor: axisLabelColor,
                      theme: theme,
                      l10n: l10n,
                    ),
                  ),
                  LineChart(
                    _buildMonthlyTrendLine(
                      monthCounts: monthCounts,
                      lineColor: lineColor,
                      gridColor: gridColor,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        highlight: true,
      );
    }

    final pieSections = speciesEntries.asMap().entries.map((entry) {
      final idx = entry.key;
      final pair = entry.value;
      final isSelected = _touchedSpeciesIndex == idx;
      return PieChartSectionData(
        value: pair.value.toDouble(),
        color: speciesPalette[idx % speciesPalette.length],
        radius: isSelected ? 70 : 60,
        title: '',
        showTitle: false,
      );
    }).toList();

    addSection(
      Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.stats_title_birds_down_per_year,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: panelTextColor,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                iconSize: 20,
                tooltip: l10n.stats_info_explanation_tooltip,
                onPressed: () => _showGraphInfoSheet(
                  title: l10n.stats_info_birds_down_title,
                  emoji: '🦆',
                  lines: [
                    l10n.stats_info_birds_down_body_1,
                    l10n.stats_info_birds_down_body_2,
                  ],
                ),
                icon: Icon(Icons.info_outline, color: panelSubTextColor),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (hasYearlyBirds) ...[
            SizedBox(
              height: 220,
              child: BarChart(
                _buildYearlyBirdsChart(
                  years: yearlyYears,
                  counts: yearlyCounts,
                  barColor: lineColor,
                  gridColor: gridColor,
                  tooltipBgColor: tooltipBgColor,
                  tooltipTextColor: tooltipTextColor,
                  axisLabelColor: axisLabelColor,
                ),
              ),
            ),
            if (speciesEntries.isNotEmpty && selectedYear != null) ...[
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      l10n.stats_birds_distribution_title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: panelTextColor,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    iconSize: 18,
                    tooltip: l10n.stats_birds_pie_hint,
                    onPressed: () => _showGraphInfoSheet(
                      title: l10n.stats_birds_distribution_title,
                      emoji: '📊',
                      lines: [
                        l10n.stats_info_birds_distribution_body_1,
                        l10n.stats_info_birds_distribution_body_2,
                      ],
                    ),
                    icon: Icon(Icons.info_outline, color: panelSubTextColor),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 220,
                child: PieChart(
                  PieChartData(
                    sections: pieSections,
                    sectionsSpace: 4,
                    centerSpaceRadius: 32,
                    pieTouchData: PieTouchData(
                      touchCallback: (event, response) {
                        // Ikke-interessant event eller ingen treff -> nullstill
                        if (!event.isInterestedForInteractions ||
                            response == null ||
                            response.touchedSection == null) {
                          setState(() {
                            _touchedSpeciesIndex = -1;
                            _speciesTooltipText = null;
                          });
                          return;
                        }

                        final idx =
                            response.touchedSection!.touchedSectionIndex;

                        // Sikkerhet: idx må være innenfor entries
                        if (idx < 0 || idx >= speciesEntries.length) {
                          setState(() {
                            _touchedSpeciesIndex = -1;
                            _speciesTooltipText = null;
                          });
                          return;
                        }

                        // Oppdater kun på “slipp”-event (så det ikke spammer)
                        if (event is FlTapUpEvent || event is FlLongPressEnd) {
                          final entry = speciesEntries[idx];
                          setState(() {
                            _touchedSpeciesIndex = idx;
                            _speciesTooltipText =
                                '${entry.key}: ${entry.value}';
                          });
                        }
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _speciesTooltipText ?? l10n.stats_birds_pie_hint,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: panelSubTextColor),
              ),
              const SizedBox(height: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var i = 0; i < speciesEntries.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: speciesPalette[i % speciesPalette.length],
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${speciesEntries[i].key} – ${speciesEntries[i].value}',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: panelSubTextColor),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ] else ...[
            Text(
              l10n.stats_no_birds_down_yet,
              style:
                  theme.textTheme.bodySmall?.copyWith(color: panelSubTextColor),
            ),
          ],
        ],
      ),
      highlight: true,
    );

    final yearPicker = (availableYears.isNotEmpty && selectedYear != null)
        ? DropdownButtonFormField<int>(
            value: selectedYear,
            decoration: InputDecoration(
              border:
                  OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              labelText: l10n.stats_label_year,
              labelStyle: TextStyle(color: panelTextColor),
              filled: true,
              fillColor: panelColor,
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: panelBorderColor),
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            style: TextStyle(color: panelTextColor),
            dropdownColor: panelColor,
            isExpanded: true,
            items: availableYears
                .map(
                  (year) => DropdownMenuItem<int>(
                    value: year,
                    child: Text(year.toString(),
                        style: TextStyle(color: panelTextColor)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() {
                _selectedYear = value;
              });
            },
          )
        : null;

    final children = <Widget>[];
    if (yearPicker != null) {
      children.add(yearPicker);
      children.add(const SizedBox(height: 16));
    }
    for (var i = 0; i < graphSections.length; i++) {
      children.add(graphSections[i]);
      if (i != graphSections.length - 1) {
        children.add(const SizedBox(height: 24));
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: panelColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: panelBorderColor),
        boxShadow: [
          BoxShadow(
            color: isAppLight ? Colors.black45 : Colors.black12,
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: DefaultTextStyle.merge(
        style: TextStyle(color: panelTextColor),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }

  // ---------- Small UI bits ----------
  Widget _legendDot(Color color, Color borderColor) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: borderColor.withOpacity(0.6)),
      ),
    );
  }

  Widget _legendLine(Color color) {
    return Container(width: 12, height: 2, color: color);
  }

  Widget _periodToggleButton(
    String label,
    _V1Period period,
    Color panelTextColor,
    Color panelSubTextColor,
  ) {
    final selected = _v1Period == period;
    final theme = Theme.of(context);
    return SizedBox(
      height: 36,
      child: OutlinedButton(
        onPressed: () => _setPeriod(period),
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? theme.colorScheme.primaryContainer : null,
          foregroundColor: selected
              ? theme.colorScheme.onPrimaryContainer
              : panelSubTextColor,
          side: BorderSide(
            color: selected
                ? theme.colorScheme.primary
                : panelSubTextColor.withOpacity(0.8),
          ),
        ),
        child: Text(label),
      ),
    );
  }

  // ---------- Weekly charts ----------
  BarChartData _buildWeeklyActiveTimeBars(
    List<_WeekStats> weeklyStats,
    int maxHours,
    Color barColor,
    Color tooltipBgColor,
    Color tooltipTextColor,
    Color gridColor,
    Color axisLabelColor,
    AppLocalizations l10n,
  ) {
    final bars = weeklyStats.map((week) {
      final hours = week.totalMinutes / 60;
      return BarChartGroupData(
        x: week.index,
        barRods: [
          BarChartRodData(
            toY: hours,
            color: hours <= 0 ? barColor.withOpacity(0.25) : barColor,
            width: 14,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      );
    }).toList();

    return BarChartData(
      barGroups: bars,
      alignment: BarChartAlignment.spaceBetween,
      groupsSpace: 12,
      maxY: math.max(maxHours.toDouble(), 1) + 1,
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 32,
            getTitlesWidget: (value, meta) => _buildWeekAxisLabel(
                value, meta, weeklyStats, axisLabelColor, l10n),
          ),
        ),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: gridColor, strokeWidth: 0.5),
      ),
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          tooltipRoundedRadius: 8,
          getTooltipColor: (group) => tooltipBgColor,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final week = weeklyStats[groupIndex];
            return BarTooltipItem(
                _weekTooltip(week, l10n), TextStyle(color: tooltipTextColor));
          },
        ),
      ),
    );
  }

  LineChartData _buildWeeklySessionsLine(
    List<_WeekStats> weeklyStats,
    int maxSessions,
    Color lineColor,
    Color gridColor,
  ) {
    final spots = weeklyStats
        .map((w) => FlSpot(w.index.toDouble(), w.sessions.toDouble()))
        .toList();

    return LineChartData(
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: false,
          color: lineColor.withOpacity(0.85),
          barWidth: 2,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(color: lineColor, radius: 3, strokeWidth: 0),
          ),
          belowBarData:
              BarAreaData(show: true, color: lineColor.withOpacity(0.2)),
        ),
      ],
      minY: 0,
      maxY: math.max(maxSessions.toDouble(), 1) + 1,
      titlesData: FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: gridColor, strokeWidth: 0.4),
      ),
      lineTouchData: LineTouchData(enabled: false),
    );
  }

  // ---------- Monthly sessions chart ----------
  BarChartData _buildMonthlySessionsBars({
    required List<int> monthCounts,
    required int year,
    required Color barColor,
    required Color gridColor,
    required Color tooltipBgColor,
    required Color tooltipTextColor,
    required Color axisLabelColor,
    required ThemeData theme,
    required AppLocalizations l10n,
  }) {
    final bars = monthCounts.asMap().entries.map((e) {
      final idx = e.key;
      final count = e.value;
      return BarChartGroupData(
        x: idx,
        barRods: [
          BarChartRodData(
            toY: count.toDouble(),
            color: count <= 0 ? barColor.withOpacity(0.25) : barColor,
            width: 10,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      );
    }).toList();

    return BarChartData(
      barGroups: bars,
      alignment: BarChartAlignment.spaceBetween,
      maxY: math.max(monthCounts.fold<int>(0, math.max).toDouble(), 1) + 1,
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            getTitlesWidget: (value, meta) =>
                _buildMonthAxisLabel(value, meta, axisLabelColor),
          ),
        ),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: gridColor, strokeWidth: 0.4),
      ),
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          tooltipRoundedRadius: 8,
          getTooltipColor: (group) => tooltipBgColor,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final idx = group.x.toInt();
            final count = monthCounts[idx];
            final month = _monthName(idx);
            final msg = count > 0
                ? l10n.stats_monthly_sessions_tooltip(month, year, count)
                : l10n.stats_monthly_sessions_tooltip_empty(month, year);
            return BarTooltipItem(msg, TextStyle(color: tooltipTextColor));
          },
        ),
      ),
    );
  }

  BarChartData _buildYearlyBirdsChart({
    required List<int> years,
    required List<int> counts,
    required Color barColor,
    required Color gridColor,
    required Color tooltipBgColor,
    required Color tooltipTextColor,
    required Color axisLabelColor,
  }) {
    final filteredEntries = <int, int>{};
    for (var i = 0; i < years.length; i++) {
      if (counts[i] > 0) {
        filteredEntries[years[i]] = counts[i];
      }
    }
    final filteredYears = filteredEntries.keys.toList();
    final filteredCounts = filteredEntries.values.toList();
    if (filteredCounts.isEmpty) {
      return BarChartData(
        barGroups: [],
        alignment: BarChartAlignment.spaceBetween,
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        borderData: FlBorderData(show: false),
        gridData: FlGridData(show: false),
      );
    }
    final maxValue = filteredCounts.fold<int>(0, math.max);
    final bars = List<BarChartGroupData>.generate(filteredYears.length, (idx) {
      final value = filteredCounts[idx];
      return BarChartGroupData(
        x: idx,
        showingTooltipIndicators: value > 0 ? [0] : [],
        barRods: [
          BarChartRodData(
            toY: value.toDouble(),
            color: barColor,
            width: 14,
            borderRadius: BorderRadius.circular(6),
          ),
        ],
      );
    });

    return BarChartData(
      barGroups: bars,
      alignment: BarChartAlignment.spaceBetween,
      groupsSpace: 12,
      maxY: math.max(maxValue.toDouble(), 1) + 3,
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 36,
            getTitlesWidget: (value, meta) =>
                _buildYearAxisLabel(value, meta, filteredYears, axisLabelColor),
          ),
        ),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: gridColor, strokeWidth: 0.4),
      ),
      barTouchData: BarTouchData(
        enabled: true,
        handleBuiltInTouches: false,
        touchTooltipData: BarTouchTooltipData(
          tooltipRoundedRadius: 6,
          tooltipMargin: 8,
          tooltipPadding:
              const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          getTooltipColor: (_) => Colors.transparent,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final count =
                filteredCounts[math.min(groupIndex, filteredCounts.length - 1)];
            if (count <= 0) return null;
            return BarTooltipItem(
              '$count',
              TextStyle(
                color: tooltipTextColor,
                fontWeight: FontWeight.bold,
              ),
            );
          },
        ),
      ),
    );
  }

  LineChartData _buildMonthlyTrendLine({
    required List<int> monthCounts,
    required Color lineColor,
    required Color gridColor,
  }) {
    final spots = _bucketSpots(monthCounts);
    final maxCount = monthCounts.fold<int>(0, math.max).toDouble();
    final trendMax =
        spots.fold<double>(0, (prev, spot) => math.max(prev, spot.y));

    return LineChartData(
      lineBarsData: [
        LineChartBarData(
          spots: spots,
          isCurved: false,
          color: lineColor.withOpacity(0.85),
          barWidth: 2,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(color: lineColor, radius: 3, strokeWidth: 0),
          ),
        ),
      ],
      minY: 0,
      maxY: math.max(maxCount, trendMax) + 1,
      titlesData: FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: gridColor, strokeWidth: 0.35),
      ),
      lineTouchData: LineTouchData(enabled: false),
    );
  }

  // ---------- Stand/Flush chart ----------
  BarChartData _buildStandFlushBars({
    required List<int> standCounts,
    required List<int> flushCounts,
    required int year,
    required Color standColor,
    required Color flushColor,
    required Color gridColor,
    required Color tooltipBgColor,
    required Color tooltipTextColor,
    required Color axisLabelColor,
    required ThemeData theme,
    required AppLocalizations l10n,
  }) {
    final maxValue = math.max(
      standCounts.fold<int>(0, math.max),
      flushCounts.fold<int>(0, math.max),
    );

    final groups = List<BarChartGroupData>.generate(12, (idx) {
      final stand = standCounts[idx];
      final flush = flushCounts[idx];
      return BarChartGroupData(
        x: idx,
        barsSpace: 4,
        barRods: [
          BarChartRodData(
            toY: stand.toDouble(),
            color: stand <= 0 ? standColor.withOpacity(0.25) : standColor,
            width: 9,
            borderRadius: BorderRadius.circular(4),
          ),
          BarChartRodData(
            toY: flush.toDouble(),
            color: flush <= 0 ? flushColor.withOpacity(0.25) : flushColor,
            width: 9,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      );
    });

    return BarChartData(
      barGroups: groups,
      alignment: BarChartAlignment.spaceBetween,
      groupsSpace: 14,
      maxY: math.max(maxValue.toDouble(), 1) + 1,
      titlesData: FlTitlesData(
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 28,
            getTitlesWidget: (value, meta) =>
                _buildMonthAxisLabel(value, meta, axisLabelColor),
          ),
        ),
        leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: gridColor, strokeWidth: 0.35),
      ),
      barTouchData: BarTouchData(
        enabled: true,
        touchTooltipData: BarTouchTooltipData(
          tooltipRoundedRadius: 8,
          getTooltipColor: (group) => tooltipBgColor,
          getTooltipItem: (group, groupIndex, rod, rodIndex) {
            final idx = group.x.toInt();
            final month = _monthName(idx);
            final stand = standCounts[idx];
            final flush = flushCounts[idx];
            final standLabel = stand > 0 ? stand.toString() : l10n.stats_none;
            final flushLabel = flush > 0 ? flush.toString() : l10n.stats_none;
            final msg = l10n.stats_stand_flush_tooltip(
              month,
              year,
              standLabel,
              flushLabel,
            );
            return BarTooltipItem(msg, TextStyle(color: tooltipTextColor));
          },
        ),
      ),
    );
  }

  LineChartData _buildStandFlushTrendLines({
    required List<int> standCounts,
    required List<int> flushCounts,
    required Color standColor,
    required Color flushColor,
    required Color gridColor,
  }) {
    final standTrend = _bucketSpots(standCounts);
    final flushTrend = _bucketSpots(flushCounts);

    final maxVal = math.max(
      standCounts.fold<int>(0, math.max).toDouble(),
      flushCounts.fold<int>(0, math.max).toDouble(),
    );

    final lineBars = <LineChartBarData>[
      if (standTrend.isNotEmpty)
        LineChartBarData(
          spots: standTrend,
          isCurved: false,
          color: standColor.withOpacity(0.85),
          barWidth: 2,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
                    color: standColor, radius: 3, strokeWidth: 0),
          ),
        ),
      if (flushTrend.isNotEmpty)
        LineChartBarData(
          spots: flushTrend,
          isCurved: false,
          color: flushColor.withOpacity(0.85),
          barWidth: 2,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) =>
                FlDotCirclePainter(
                    color: flushColor, radius: 3, strokeWidth: 0),
          ),
        ),
    ];

    return LineChartData(
      lineBarsData: lineBars,
      minY: 0,
      maxY: maxVal + 1,
      titlesData: FlTitlesData(show: false),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(
        show: true,
        drawVerticalLine: false,
        getDrawingHorizontalLine: (value) =>
            FlLine(color: gridColor, strokeWidth: 0.25),
      ),
      lineTouchData: LineTouchData(enabled: false),
    );
  }
}

class _WeekStats {
  _WeekStats({required this.weekStart});

  final DateTime weekStart;
  int index = 0;
  int sessions = 0;
  int totalMinutes = 0;
}

class _StatisticCard extends StatelessWidget {
  const _StatisticCard({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .titleSmall
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
