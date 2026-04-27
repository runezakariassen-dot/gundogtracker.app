// ignore_for_file: depend_on_referenced_packages

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';

import '../../data/hive_boxes.dart';
import '../../models/hunt_session.dart';
import '../../services/hive_lifecycle_service.dart';
import '../components/app_scaffold.dart';
import '../components/meta_chip.dart';
import '../theme/app_theme.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  late final Box<HuntSession> _sessionsBox;
  _TrendResult? _trendResult;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _sessionsBox = HiveLifecycleService.getBox<HuntSession>(sessionsBoxName);
    _computeTrend();
  }

  void _computeTrend() {
    final sessions = _sessionsBox.values
        .where((session) => !session.isDeleted)
        .toList(growable: false);
    final result = _buildTrendResult(sessions);
    setState(() {
      _trendResult = result;
      _loading = false;
    });
  }

  _TrendResult? _buildTrendResult(List<HuntSession> sessions) {
    if (sessions.isEmpty) return null;
    sessions.sort((a, b) => a.dateTime.compareTo(b.dateTime));
    final now = DateTime.now();
    final earliest = DateTime(
      sessions.first.dateTime.year,
      sessions.first.dateTime.month,
      sessions.first.dateTime.day,
    );
    if (earliest.isAfter(now)) return null;

    final span = now.difference(earliest);
    final bucket = _selectBucket(span);
    final bucketStarts = _bucketStarts(earliest, now, bucket);
    if (bucketStarts.isEmpty) return null;

    final points = bucketStarts
        .map((start) => _TrendPoint(start: start, count: 0))
        .toList();

    for (final session in sessions) {
      final idx = bucketStarts.lastIndexWhere(
        (bucketStart) => !session.dateTime.isBefore(bucketStart),
      );
      if (idx >= 0) {
        points[idx].count += 1;
      }
    }

    return _TrendResult(
      start: earliest,
      bucket: bucket,
      points: points,
    );
  }

  _Bucket _selectBucket(Duration span) {
    final days = span.inDays;
    if (days <= 60) return _Bucket.daily;
    if (days <= 30 * 18) return _Bucket.weekly;
    return _Bucket.monthly;
  }

  List<DateTime> _bucketStarts(DateTime start, DateTime end, _Bucket bucket) {
    final starts = <DateTime>[];
    var cursor = _normalizeToBucket(start, bucket);
    while (!cursor.isAfter(end)) {
      starts.add(cursor);
      cursor = _advanceCursor(cursor, bucket);
    }
    return starts;
  }

  DateTime _normalizeToBucket(DateTime date, _Bucket bucket) {
    switch (bucket) {
      case _Bucket.daily:
      case _Bucket.weekly:
      case _Bucket.monthly:
        return DateTime(date.year, date.month, date.day);
    }
  }

  DateTime _advanceCursor(DateTime cursor, _Bucket bucket) {
    switch (bucket) {
      case _Bucket.daily:
        return cursor.add(const Duration(days: 1));
      case _Bucket.weekly:
        return cursor.add(const Duration(days: 7));
      case _Bucket.monthly:
        return _addMonths(cursor, 1);
    }
  }

  DateTime _addMonths(DateTime snapshot, int months) {
    final totalMonths = snapshot.month - 1 + months;
    final year = snapshot.year + totalMonths ~/ 12;
    final month = totalMonths % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = math.min(snapshot.day, lastDay);
    return DateTime(year, month, day);
  }

  String _bucketLabel(_Bucket bucket, AppLocalizations l10n) {
    switch (bucket) {
      case _Bucket.daily:
        return l10n.stats_period_daily;
      case _Bucket.weekly:
        return l10n.stats_period_weekly;
      case _Bucket.monthly:
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

  String _formatPointLabel(_TrendPoint point, _Bucket bucket) {
    switch (bucket) {
      case _Bucket.daily:
        return DateFormat('d. MMM', 'nb_NO').format(point.start);
      case _Bucket.weekly:
        final week = _weekNumberDigits(point.start);
        return week.isEmpty
            ? 'Uke ${DateFormat('w', 'nb_NO').format(point.start)}'
            : 'Uke $week';
      case _Bucket.monthly:
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
        height: 160,
        child: Center(
            child: Text(
          l10n.stats_no_sessions_registered,
        )),
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

enum _Bucket { daily, weekly, monthly }

class _TrendResult {
  const _TrendResult({
    required this.start,
    required this.bucket,
    required this.points,
  });

  final DateTime start;
  final _Bucket bucket;
  final List<_TrendPoint> points;
}

class _TrendPoint {
  _TrendPoint({
    required this.start,
    required this.count,
  });

  final DateTime start;
  int count;
}
