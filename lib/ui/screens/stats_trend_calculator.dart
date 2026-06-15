import 'dart:math' as math;

import 'package:jakthund_app/models/hunt_session.dart';

enum StatsTrendBucket { daily, weekly, monthly }

class StatsTrendResult {
  const StatsTrendResult({
    required this.start,
    required this.bucket,
    required this.points,
  });

  final DateTime start;
  final StatsTrendBucket bucket;
  final List<StatsTrendPoint> points;
}

class StatsTrendPoint {
  const StatsTrendPoint({
    required this.start,
    required this.count,
  });

  final DateTime start;
  final int count;
}

class StatsTrendCalculator {
  const StatsTrendCalculator._();

  static StatsTrendResult? calculate(
    Iterable<HuntSession> sessions, {
    DateTime Function()? now,
  }) {
    final visibleSessions =
        sessions.where((session) => !session.isDeleted).toList(growable: false);
    if (visibleSessions.isEmpty) return null;

    final sortedSessions = List<HuntSession>.from(visibleSessions)
      ..sort((a, b) => a.dateTime.compareTo(b.dateTime));

    final currentTime = (now ?? DateTime.now)();
    final earliest = DateTime(
      sortedSessions.first.dateTime.year,
      sortedSessions.first.dateTime.month,
      sortedSessions.first.dateTime.day,
    );
    if (earliest.isAfter(currentTime)) return null;

    final span = currentTime.difference(earliest);
    final bucket = _selectBucket(span);
    final bucketStarts = _bucketStarts(earliest, currentTime, bucket);
    if (bucketStarts.isEmpty) return null;

    final counts = List<int>.filled(bucketStarts.length, 0);
    for (final session in sortedSessions) {
      final idx = bucketStarts.lastIndexWhere(
        (bucketStart) => !session.dateTime.isBefore(bucketStart),
      );
      if (idx >= 0) {
        counts[idx] += 1;
      }
    }

    return StatsTrendResult(
      start: earliest,
      bucket: bucket,
      points: [
        for (var i = 0; i < bucketStarts.length; i++)
          StatsTrendPoint(start: bucketStarts[i], count: counts[i]),
      ],
    );
  }

  static StatsTrendBucket _selectBucket(Duration span) {
    final days = span.inDays;
    if (days <= 60) return StatsTrendBucket.daily;
    if (days <= 30 * 18) return StatsTrendBucket.weekly;
    return StatsTrendBucket.monthly;
  }

  static List<DateTime> _bucketStarts(
    DateTime start,
    DateTime end,
    StatsTrendBucket bucket,
  ) {
    final starts = <DateTime>[];
    var cursor = _normalizeToBucket(start, bucket);
    while (!cursor.isAfter(end)) {
      starts.add(cursor);
      cursor = _advanceCursor(cursor, bucket);
    }
    return starts;
  }

  static DateTime _normalizeToBucket(DateTime date, StatsTrendBucket bucket) {
    switch (bucket) {
      case StatsTrendBucket.daily:
      case StatsTrendBucket.weekly:
      case StatsTrendBucket.monthly:
        return DateTime(date.year, date.month, date.day);
    }
  }

  static DateTime _advanceCursor(DateTime cursor, StatsTrendBucket bucket) {
    switch (bucket) {
      case StatsTrendBucket.daily:
        return cursor.add(const Duration(days: 1));
      case StatsTrendBucket.weekly:
        return cursor.add(const Duration(days: 7));
      case StatsTrendBucket.monthly:
        return _addMonths(cursor, 1);
    }
  }

  static DateTime _addMonths(DateTime snapshot, int months) {
    final totalMonths = snapshot.month - 1 + months;
    final year = snapshot.year + totalMonths ~/ 12;
    final month = totalMonths % 12 + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = math.min(snapshot.day, lastDay);
    return DateTime(year, month, day);
  }
}
