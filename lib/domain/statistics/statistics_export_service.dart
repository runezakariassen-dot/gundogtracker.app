import 'dart:io';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/dog.dart';
import '../../models/hunt_session.dart';
import 'advanced_statistics_models.dart';
import 'advanced_statistics_service.dart';

/// Tjeneste for eksport av statistikkrapporter
class StatisticsExportService {
  /// Eksporter statistikker som CSV
  static Future<String> exportToCsv(
    List<Dog> dogs,
    List<HuntSession> allSessions,
  ) async {
    final comparisonStats = AdvancedStatisticsService.calculateDogComparison(dogs, allSessions);

    final csvData = <List<String>>[];

    // Header
    csvData.add([
      'Hund',
      'Totale økter',
      'Aktiv tid (timer)',
      'Totale poeng',
      'Totale flushes',
      'Fuglkontakter',
      'Fugl skutt',
      'Gj.snitt poeng/time',
      'Gj.snitt fuglkontakter/økt',
      'Gj.snitt flushes/økt',
      'Suksessrate (%)',
    ]);

    // Data for hver hund
    for (final dogStats in comparisonStats.dogStats) {
      csvData.add([
        dogStats.dogName,
        dogStats.totalSessions.toString(),
        (dogStats.totalActiveTime.inMinutes / 60.0).toStringAsFixed(1),
        dogStats.totalPoints.toString(),
        dogStats.totalFlushes.toString(),
        dogStats.totalBirdContacts.toString(),
        dogStats.totalBirdsShot.toString(),
        dogStats.averagePointsPerHour.toStringAsFixed(1),
        dogStats.averageBirdContactsPerSession.toStringAsFixed(1),
        dogStats.averageFlushesPerSession.toStringAsFixed(1),
        (dogStats.successRate * 100).toStringAsFixed(1),
      ]);
    }

    final csvString = const ListToCsvConverter().convert(csvData);
    return csvString;
  }

  /// Eksporter detaljerte økt-data som CSV
  static Future<String> exportSessionsToCsv(
    List<HuntSession> sessions,
    List<Dog> dogs,
  ) async {
    final dogMap = {for (final dog in dogs) dog.id: dog.name};

    final csvData = <List<String>>[];

    // Header
    csvData.add([
      'Dato',
      'Hund',
      'Sted',
      'Varighet (min)',
      'Fugl sett',
      'Poeng',
      'Flushes',
      'Sekundære poeng',
      'Fugl skutt',
      'Fuglart skutt',
      'Notater',
      'Økttype',
    ]);

    // Data for hver økt
    for (final session in sessions) {
      csvData.add([
        session.dateTime.toIso8601String().split('T')[0],
        dogMap[session.dogId] ?? 'Ukjent',
        session.location,
        session.durationMinutes.toString(),
        session.birdsSeen.toString(),
        session.points.toString(),
        session.flushes.toString(),
        session.secondaryPoints.toString(),
        session.birdsShotCount.toString(),
        session.birdsShotSpecies ?? '',
        session.notes,
        session.sessionType.toString().split('.').last,
      ]);
    }

    final csvString = const ListToCsvConverter().convert(csvData);
    return csvString;
  }

  /// Lagre CSV-fil og del den
  static Future<void> saveAndShareCsv(
    String csvContent,
    String fileName,
  ) async {
    try {
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$fileName.csv');
      await file.writeAsString(csvContent);

      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Jakthund statistikkrapporter',
      );
    } catch (e) {
      throw Exception('Kunne ikke eksportere rapport: $e');
    }
  }

  /// Generer tekst-basert rapport
  static String generateTextReport(
    AdvancedDogStats stats,
    List<SeasonalStats> seasonalStats,
  ) {
    final buffer = StringBuffer();

    buffer.writeln('🐕 JAKTHUND STATISTIKKRAPPORT');
    buffer.writeln('=' * 50);
    buffer.writeln();
    buffer.writeln('Hund: ${stats.dogName}');
    buffer.writeln('Rapport generert: ${DateTime.now().toIso8601String().split('T')[0]}');
    buffer.writeln();

    buffer.writeln('📊 SAMMENDRAG');
    buffer.writeln('-' * 20);
    buffer.writeln('Totale økter: ${stats.totalSessions}');
    buffer.writeln('Aktiv tid: ${_formatDuration(stats.totalActiveTime)}');
    buffer.writeln('Totale poeng: ${stats.totalPoints}');
    buffer.writeln('Totale flushes: ${stats.totalFlushes}');
    buffer.writeln('Fuglkontakter: ${stats.totalBirdContacts}');
    buffer.writeln('Fugl skutt: ${stats.totalBirdsShot}');
    buffer.writeln();

    buffer.writeln('📈 GJENNOMSNITTLIG YTEELSE');
    buffer.writeln('-' * 30);
    buffer.writeln('Poeng per time: ${stats.averagePointsPerHour.toStringAsFixed(1)}');
    buffer.writeln('Fuglkontakter per økt: ${stats.averageBirdContactsPerSession.toStringAsFixed(1)}');
    buffer.writeln('Flushes per økt: ${stats.averageFlushesPerSession.toStringAsFixed(1)}');
    buffer.writeln('Suksessrate: ${(stats.successRate * 100).toStringAsFixed(1)}%');
    buffer.writeln();

    if (seasonalStats.isNotEmpty) {
      buffer.writeln('🌤️ SESONGANALYSE');
      buffer.writeln('-' * 15);
      for (final season in seasonalStats) {
        buffer.writeln('${season.season}:');
        buffer.writeln('  Økter: ${season.sessions}');
        buffer.writeln('  Aktiv tid: ${_formatDuration(season.activeTime)}');
        buffer.writeln('  Poeng: ${season.points}');
        buffer.writeln('  Gj.snitt poeng/time: ${season.averagePointsPerHour.toStringAsFixed(1)}');
        buffer.writeln();
      }
    }

    return buffer.toString();
  }

  /// Formater varighet som lesbar tekst
  static String _formatDuration(Duration duration) {
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
}
