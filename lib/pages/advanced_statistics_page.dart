// ignore_for_file: deprecated_member_use, prefer_const_constructors

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../../data/hive_boxes.dart';
import '../../domain/dogs/dog_visibility.dart';
import '../../domain/sessions/session_visibility.dart';
import '../../models/dog.dart';
import '../../models/hunt_session.dart';
import '../../services/hive_lifecycle_service.dart';
import '../../l10n/app_localizations.dart';
import '../../ui/theme/app_theme.dart';
import '../domain/statistics/advanced_statistics_models.dart';
import '../domain/statistics/advanced_statistics_service.dart';
import '../domain/statistics/statistics_export_service.dart';

class AdvancedStatisticsPage extends StatefulWidget {
  const AdvancedStatisticsPage({super.key});

  @override
  State<AdvancedStatisticsPage> createState() => _AdvancedStatisticsPageState();
}

class _AdvancedStatisticsPageState extends State<AdvancedStatisticsPage>
    with SingleTickerProviderStateMixin {
  late final Box<HuntSession> _sessionsBox;
  late final Box<Dog> _dogsBox;

  late TabController _tabController;
  String? _selectedDogId;
  bool _isExporting = false;

  @override
  void initState() {
    super.initState();
    _sessionsBox = HiveLifecycleService.getBox<HuntSession>(sessionsBoxName);
    _dogsBox = HiveLifecycleService.getBox<Dog>(dogsBoxName);
    _tabController = TabController(length: 5, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.advanced_statistics),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: [
            Tab(
                text: l10n.advanced_statistics_overview,
                icon: const Icon(Icons.dashboard)),
            Tab(
                text: l10n.advanced_statistics_progress,
                icon: const Icon(Icons.trending_up)),
            Tab(
                text: l10n.advanced_statistics_season,
                icon: const Icon(Icons.calendar_view_month)),
            Tab(
                text: l10n.advanced_statistics_comparison,
                icon: const Icon(Icons.compare)),
            Tab(
                text: l10n.advanced_statistics_export,
                icon: const Icon(Icons.download)),
          ],
        ),
      ),
      body: ValueListenableBuilder(
        valueListenable: _dogsBox.listenable(),
        builder: (context, Box<Dog> dogBox, _) {
          final dogs = filterActiveDogs(dogBox.values)
            ..sort(
                (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

          if (dogs.isEmpty) {
            return Center(child: Text(l10n.home_no_dogs_title));
          }

          return ValueListenableBuilder(
            valueListenable: _sessionsBox.listenable(),
            builder: (context, Box<HuntSession> sessionsBox, _) {
              final allSessions = filterVisibleSessions(
                sessions: sessionsBox.values,
                dogs: dogs,
              );

              // Sett standard hund hvis ingen er valgt
              if (_selectedDogId == null ||
                  dogs.every((d) => d.id != _selectedDogId)) {
                _selectedDogId = dogs.first.id;
              }

              return Column(
                children: [
                  // Hund-velger
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardColor,
                      border: Border(
                        bottom: BorderSide(
                          color: Theme.of(context).dividerColor,
                          width: 1,
                        ),
                      ),
                    ),
                    child: DropdownButtonFormField<String>(
                      value: _selectedDogId,
                      decoration: InputDecoration(
                        border: const OutlineInputBorder(),
                        labelText: l10n.chooseDog,
                        prefixIcon: const Icon(Icons.pets),
                      ),
                      isExpanded: true,
                      items: dogs
                          .map(
                            (dog) => DropdownMenuItem<String>(
                              value: dog.id,
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.pets,
                                    size: 20,
                                    color:
                                        Theme.of(context).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(dog.name),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setState(() => _selectedDogId = value),
                    ),
                  ),

                  // Tab-innhold
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildOverviewTab(dogs, allSessions, l10n),
                        _buildProgressTab(dogs, allSessions, l10n),
                        _buildSeasonTab(dogs, allSessions, l10n),
                        _buildComparisonTab(dogs, allSessions, l10n),
                        _buildExportTab(dogs, allSessions, l10n),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildOverviewTab(
      List<Dog> dogs, List<HuntSession> allSessions, AppLocalizations l10n) {
    if (_selectedDogId == null) return const SizedBox.shrink();

    final dog = dogs.firstWhere((d) => d.id == _selectedDogId);
    final dogSessions =
        allSessions.where((s) => s.dogId == _selectedDogId).toList();
    final stats = AdvancedStatisticsService.calculateDogStats(
        _selectedDogId!, dog.name, dogSessions);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Hovedstatistikker
          Text(
            l10n.advanced_statistics_key_metrics_for(dog.name),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // Statistikk-kort i grid
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: [
              _buildStatCard(
                l10n.advanced_statistics_stand_rate_per_hour,
                '${stats.averagePointsPerHour.toStringAsFixed(1)} poeng/t',
                Icons.access_time,
                AppColors.brandAccent,
              ),
              _buildStatCard(
                l10n.advanced_statistics_bird_contacts_per_session,
                stats.averageBirdContactsPerSession.toStringAsFixed(1),
                Icons.visibility,
                AppColors.skyBlue,
              ),
              _buildStatCard(
                l10n.advanced_statistics_average_flushes_per_session,
                stats.averageFlushesPerSession.toStringAsFixed(1),
                Icons.flash_on,
                AppColors.brandSuccess,
              ),
              _buildStatCard(
                l10n.advanced_statistics_success_rate,
                '${(stats.successRate * 100).toStringAsFixed(1)}%',
                Icons.percent,
                AppColors.brandError,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Totale statistikker
          Text(
            l10n.advanced_statistics_totals,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 12),

          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.card),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildTotalRow(l10n.advanced_statistics_sessions_total,
                      stats.totalSessions.toString()),
                  const Divider(),
                  _buildTotalRow(l10n.advanced_statistics_active_time,
                      _formatDuration(stats.totalActiveTime)),
                  const Divider(),
                  _buildTotalRow(l10n.advanced_statistics_total_points,
                      stats.totalPoints.toString()),
                  const Divider(),
                  _buildTotalRow(l10n.advanced_statistics_total_flushes,
                      stats.totalFlushes.toString()),
                  const Divider(),
                  _buildTotalRow(l10n.advanced_statistics_bird_contacts,
                      stats.totalBirdContacts.toString()),
                  const Divider(),
                  _buildTotalRow(l10n.advanced_statistics_birds_shot,
                      stats.totalBirdsShot.toString()),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressTab(
      List<Dog> dogs, List<HuntSession> allSessions, AppLocalizations l10n) {
    if (_selectedDogId == null) return const SizedBox.shrink();

    final dog = dogs.firstWhere((d) => d.id == _selectedDogId);
    final dogSessions =
        allSessions.where((s) => s.dogId == _selectedDogId).toList();
    final stats = AdvancedStatisticsService.calculateDogStats(
        _selectedDogId!, dog.name, dogSessions);

    if (stats.progressOverTime.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.trending_up, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              l10n.advanced_statistics_no_progress_data,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.advanced_statistics_progress_over_time(dog.name),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.card),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    l10n.advanced_statistics_average_points_per_session_over_time,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 300,
                    child: LineChart(
                      _buildProgressChart(stats.progressOverTime),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Trend-indikator
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.card),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    l10n.advanced_statistics_trend_analysis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _calculateTrend(stats.progressOverTime) > 0
                            ? Icons.trending_up
                            : _calculateTrend(stats.progressOverTime) < 0
                                ? Icons.trending_down
                                : Icons.trending_flat,
                        size: 48,
                        color: _calculateTrend(stats.progressOverTime) > 0
                            ? AppColors.brandSuccess
                            : _calculateTrend(stats.progressOverTime) < 0
                                ? AppColors.brandError
                                : Colors.grey,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        _calculateTrend(stats.progressOverTime) > 0
                            ? l10n.advanced_statistics_improvement
                            : _calculateTrend(stats.progressOverTime) < 0
                                ? l10n.advanced_statistics_declining
                                : l10n.advanced_statistics_stable,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeasonTab(
      List<Dog> dogs, List<HuntSession> allSessions, AppLocalizations l10n) {
    if (_selectedDogId == null) return const SizedBox.shrink();

    final dog = dogs.firstWhere((d) => d.id == _selectedDogId);
    final seasonalStats = AdvancedStatisticsService.calculateSeasonalStats(
        allSessions, _selectedDogId!);

    if (seasonalStats.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_view_month, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              l10n.advanced_statistics_no_season_data,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.advanced_statistics_seasonal_analysis(dog.name),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          ...seasonalStats.map((season) => Card(
                elevation: 4,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadii.card),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        season.season,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSeasonMetric(
                              l10n.advanced_statistics_sessions,
                              season.sessions.toString(),
                              Icons.event,
                            ),
                          ),
                          Expanded(
                            child: _buildSeasonMetric(
                              l10n.advanced_statistics_active_time,
                              _formatDuration(season.activeTime),
                              Icons.access_time,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildSeasonMetric(
                              l10n.advanced_statistics_points,
                              season.points.toString(),
                              Icons.star,
                            ),
                          ),
                          Expanded(
                            child: _buildSeasonMetric(
                              l10n.advanced_statistics_points_per_hour,
                              season.averagePointsPerHour.toStringAsFixed(1),
                              Icons.trending_up,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildComparisonTab(
      List<Dog> dogs, List<HuntSession> allSessions, AppLocalizations l10n) {
    final comparisonStats =
        AdvancedStatisticsService.calculateDogComparison(dogs, allSessions);

    if (comparisonStats.dogStats.length <= 1) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.compare, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              l10n.advanced_statistics_need_two_dogs,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.advanced_statistics_dog_comparison,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),

          // Stand-rate sammenligning
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.card),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    '⏱️ Stand-rate per time',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      _buildComparisonChart(
                          comparisonStats.averagePointsPerHour, 'poeng/t'),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Fuglkontakter sammenligning
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.card),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    '🐦 Fuglkontakter per økt',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      _buildComparisonChart(
                          comparisonStats.averageBirdContactsPerSession, ''),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Suksessrate sammenligning
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.card),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    l10n.advanced_statistics_success_rate_percent,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 200,
                    child: BarChart(
                      _buildComparisonChart(
                        comparisonStats.successRates.map(
                          (key, value) => MapEntry(key, value * 100),
                        ),
                        '%',
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExportTab(
      List<Dog> dogs, List<HuntSession> allSessions, AppLocalizations l10n) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.advanced_statistics_export_reports,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.card),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    l10n.advanced_statistics_export_statistics_csv,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.advanced_statistics_contains_comparison_all_dogs,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withOpacity(0.7),
                        ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _isExporting
                          ? null
                          : () => _exportStats(dogs, allSessions),
                      icon: _isExporting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.download),
                      label: Text(_isExporting
                          ? l10n.advanced_statistics_exporting
                          : l10n.advanced_statistics_export_stats),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadii.card),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    l10n.advanced_statistics_export_sessions_csv,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.advanced_statistics_sessions_csv_description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withOpacity(0.7),
                        ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isExporting
                          ? null
                          : () => _exportSessions(dogs, allSessions),
                      icon: const Icon(Icons.table_chart),
                      label: Text(l10n.advanced_statistics_export_session_data),
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (_selectedDogId != null) ...[
            const SizedBox(height: 16),
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadii.card),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      l10n.advanced_statistics_text_report_for(
                          _getDogName(dogs, _selectedDogId!)),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.advanced_statistics_generate_readable_text_report,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withOpacity(0.7),
                          ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        onPressed: () => _exportTextReport(dogs, allSessions),
                        icon: const Icon(Icons.description),
                        label:
                            Text(l10n.advanced_statistics_generate_text_report),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Hjelpemetoder for bygging av UI-komponenter

  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadii.card),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodyMedium),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
      ],
    );
  }

  Widget _buildSeasonMetric(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  // Chart byggere
  LineChartData _buildProgressChart(List<ProgressPoint> points) {
    return LineChartData(
      gridData: FlGridData(show: false),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 40,
            getTitlesWidget: (value, meta) => Text(
              value.toStringAsFixed(1),
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < points.length) {
                return Text(
                  points[index].label,
                  style: const TextStyle(fontSize: 10),
                );
              }
              return const Text('');
            },
          ),
        ),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: true),
      lineBarsData: [
        LineChartBarData(
          spots: points.asMap().entries.map((entry) {
            return FlSpot(entry.key.toDouble(), entry.value.value);
          }).toList(),
          isCurved: true,
          color: AppColors.brandAccent,
          barWidth: 3,
          dotData: FlDotData(show: false),
          belowBarData: BarAreaData(
            show: true,
            color: AppColors.brandAccent.withOpacity(0.1),
          ),
        ),
      ],
    );
  }

  BarChartData _buildComparisonChart(Map<String, double> data, String suffix) {
    final entries = data.entries.toList();
    return BarChartData(
      barGroups: entries.asMap().entries.map((entry) {
        return BarChartGroupData(
          x: entry.key,
          barRods: [
            BarChartRodData(
              toY: entry.value.value,
              color: _getBarColor(entry.key),
              width: 20,
            ),
          ],
        );
      }).toList(),
      titlesData: FlTitlesData(
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 50,
            getTitlesWidget: (value, meta) => Text(
              '${value.toStringAsFixed(1)}$suffix',
              style: const TextStyle(fontSize: 10),
            ),
          ),
        ),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              final index = value.toInt();
              if (index >= 0 && index < entries.length) {
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    entries[index].key,
                    style: const TextStyle(fontSize: 10),
                  ),
                );
              }
              return const Text('');
            },
          ),
        ),
        topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
      ),
      borderData: FlBorderData(show: false),
      gridData: FlGridData(show: true, drawVerticalLine: false),
    );
  }

  // Hjelpemetoder
  double _calculateTrend(List<ProgressPoint> points) {
    if (points.length < 2) return 0;

    final firstHalf = points.sublist(0, points.length ~/ 2);
    final secondHalf = points.sublist(points.length ~/ 2);

    final firstAvg = firstHalf.map((p) => p.value).reduce((a, b) => a + b) /
        firstHalf.length;
    final secondAvg = secondHalf.map((p) => p.value).reduce((a, b) => a + b) /
        secondHalf.length;

    return secondAvg - firstAvg;
  }

  Color _getBarColor(int index) {
    final colors = [
      AppColors.brandAccent,
      AppColors.skyBlue,
      AppColors.brandSuccess,
      AppColors.brandError,
      Colors.purple,
      Colors.orange,
    ];
    return colors[index % colors.length];
  }

  String _getDogName(List<Dog> dogs, String dogId) {
    for (final dog in dogs) {
      if (dog.id == dogId) {
        return dog.name;
      }
    }
    return 'Ukjent hund';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);

    if (hours == 0) {
      return '$minutes min';
    } else if (minutes == 0) {
      return '$hours t';
    } else {
      return '$hours t $minutes min';
    }
  }

  // Eksport-metoder
  Future<void> _exportStats(
      List<Dog> dogs, List<HuntSession> allSessions) async {
    setState(() => _isExporting = true);
    try {
      final csvContent =
          await StatisticsExportService.exportToCsv(dogs, allSessions);
      await StatisticsExportService.saveAndShareCsv(
        csvContent,
        'jakthund_statistikk_${DateTime.now().toIso8601String().split('T')[0]}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Statistikker eksportert!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Feil ved eksport: $e')),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportSessions(
      List<Dog> dogs, List<HuntSession> allSessions) async {
    setState(() => _isExporting = true);
    try {
      final csvContent =
          await StatisticsExportService.exportSessionsToCsv(allSessions, dogs);
      await StatisticsExportService.saveAndShareCsv(
        csvContent,
        'jakthund_okter_${DateTime.now().toIso8601String().split('T')[0]}',
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Økt-data eksportert!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Feil ved eksport: $e')),
        );
      }
    } finally {
      setState(() => _isExporting = false);
    }
  }

  Future<void> _exportTextReport(
      List<Dog> dogs, List<HuntSession> allSessions) async {
    if (_selectedDogId == null) return;

    final dog = dogs.firstWhere((d) => d.id == _selectedDogId);
    final dogSessions =
        allSessions.where((s) => s.dogId == _selectedDogId).toList();
    final stats = AdvancedStatisticsService.calculateDogStats(
        _selectedDogId!, dog.name, dogSessions);
    final seasonalStats = AdvancedStatisticsService.calculateSeasonalStats(
        allSessions, _selectedDogId!);

    final report =
        StatisticsExportService.generateTextReport(stats, seasonalStats);

    // Vis rapport i dialog
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Rapport for ${dog.name}'),
          content: SingleChildScrollView(
            child: Text(report),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Lukk'),
            ),
          ],
        ),
      );
    }
  }
}
