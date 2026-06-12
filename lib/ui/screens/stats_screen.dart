// ignore_for_file: depend_on_referenced_packages

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';

import '../../data/hive_boxes.dart';
import '../../models/hunt_session.dart';
import '../../services/hive_lifecycle_service.dart';
import '../components/app_scaffold.dart';
import '../components/meta_chip.dart';
import 'stats_trend_calculator.dart';
import '../theme/app_theme.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late final Box<HuntSession> _sessionsBox;
  StatsTrendResult? _trendResult;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _sessionsBox = HiveLifecycleService.getBox<HuntSession>(sessionsBoxName);
    _computeTrend();
  }

  void _computeTrend() {
    final result = StatsTrendCalculator.calculate(_sessionsBox.values);
    setState(() {
      _trendResult = result;
      _loading = false;
    });
  }

  String _bucketLabel(StatsTrendBucket bucket, AppLocalizations l10n) {
    switch (bucket) {
      case StatsTrendBucket.daily:
        return l10n.stats_period_daily;
      case StatsTrendBucket.weekly:
        return l10n.stats_period_weekly;
      case StatsTrendBucket.monthly:
        return l10n.stats_period_monthly;
    }
  }

  String _periodLabel(AppLocalizations l10n) {
    if (_trendResult == null) return l10n.stats_no_sessions_registered;
    final startLabel = DateFormat('dd.MM.yyyy').format(_trendResult!.start);
    final endLabel = DateFormat('dd.MM.yyyy').format(DateTime.now());
    return l10n.stats_period_range(startLabel, endLabel);
  }

  int _labelStep(int total) {
    if (total > 12) return 3;
    if (total > 6) return 2;
    return 1;
  }

  String _formatPointLabel(StatsTrendPoint point, StatsTrendBucket bucket) {
    switch (bucket) {
      case StatsTrendBucket.daily:
        return DateFormat('d. MMM', 'nb_NO').format(point.start);
      case StatsTrendBucket.weekly:
        final week = _weekNumberDigits(point.start);
        return week.isEmpty
            ? 'Uke ${DateFormat('w', 'nb_NO').format(point.start)}'
            : 'Uke $week';
      case StatsTrendBucket.monthly:
        return DateFormat.MMM('nb_NO').format(point.start);
    }
  }

  String _weekNumberDigits(DateTime date) {
    try {
      final raw = DateFormat('w', 'nb_NO').format(date);
      return raw.replaceAll(RegExp(r'[^0-9]'), '');
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      appBar: AppBar(title: Text(l10n.stats_screen_title)),
      body: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                MetaChip(label: l10n.stats_filter_all_dogs),
                const SizedBox(width: AppSpacing.sm),
                MetaChip(label: l10n.stats_filter_dynamic_period),
              ],
            ),
            const SizedBox(height: AppSpacing.lg),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: _loading
                    ? const SizedBox(
                        height: 160,
                        child: Center(child: CircularProgressIndicator()),
                      )
                    : _buildTrendContent(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendContent(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (_trendResult == null) {
      return SizedBox(
        height: 200,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bar_chart_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.stats_no_sessions_registered,
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              l10n.stats_no_sessions_empty_body,
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    final points = _trendResult!.points;
    final labelStep = _labelStep(points.length);
    final labelIndexes = <int>[];
    for (var i = 0; i < points.length; i++) {
      if (i % labelStep == 0 || i == points.length - 1) {
        labelIndexes.add(i);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.stats_trendline_title,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(_periodLabel(l10n)),
        const SizedBox(height: AppSpacing.xs),
        Text(
          l10n.stats_bucket_title(_bucketLabel(_trendResult!.bucket, l10n)),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Text(l10n.stats_buckets_count(points.length)),
            const SizedBox(width: AppSpacing.sm),
            if (points.isNotEmpty)
              Text(l10n.stats_total_label(
                  points.map((p) => p.count).reduce((a, b) => a + b)))
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: labelIndexes.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, idx) {
              final point = points[labelIndexes[idx]];
              final label = _formatPointLabel(point, _trendResult!.bucket);
              return Chip(
                label: Text(
                  l10n.stats_trend_point_label(label, point.count),
                ),
              );
            },
          ),
        ),
        if (labelIndexes.length < points.length)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              l10n.stats_more_points(points.length - labelIndexes.length),
            ),
          ),
      ],
    );
  }
}
