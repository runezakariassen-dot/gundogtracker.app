import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path/path.dart' as p;

import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/domain/sessions/session_visibility.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/models/hunt_session.dart';
import 'package:jakthund_app/models/session_type.dart';
import 'package:jakthund_app/pages/session_detail_page.dart';
import 'package:jakthund_app/pages/session_media_image_helper.dart';
import 'package:jakthund_app/pages/session_media_video_helper.dart';
import 'package:jakthund_app/services/hive_lifecycle_service.dart';
import 'package:jakthund_app/services/media_storage.dart';

enum _DogMediaFilter { all, images, videos }

class DogMediaLibraryPage extends StatefulWidget {
  const DogMediaLibraryPage({
    super.key,
    required this.dog,
  });

  final Dog dog;

  @override
  State<DogMediaLibraryPage> createState() => _DogMediaLibraryPageState();
}

class _DogMediaLibraryPageState extends State<DogMediaLibraryPage> {
  late final Box<HuntSession> _sessionsBox;
  _DogMediaFilter _filter = _DogMediaFilter.all;

  @override
  void initState() {
    super.initState();
    _sessionsBox = HiveLifecycleService.getBox<HuntSession>(sessionsBoxName);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: MediaStorage.ensureDocumentDirectoryReady(),
      builder: (context, _) {
        return ValueListenableBuilder(
          valueListenable: _sessionsBox.listenable(),
          builder: (context, Box<HuntSession> box, __) {
            final items = collectDogMediaItems(
              dog: widget.dog,
              sessions: box.values,
            );
            final filteredItems = _filterItems(items);

            return Scaffold(
              appBar: AppBar(
                title: Text('${widget.dog.displayName} – Media'),
              ),
              body: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildFilters(items),
                  const SizedBox(height: 16),
                  if (items.isEmpty)
                    const _DogMediaEmptyState()
                  else
                    _buildGrid(filteredItems),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<DogMediaItem> _filterItems(List<DogMediaItem> items) {
    switch (_filter) {
      case _DogMediaFilter.all:
        return items;
      case _DogMediaFilter.images:
        return items.where((item) => !item.isVideo).toList(growable: false);
      case _DogMediaFilter.videos:
        return items.where((item) => item.isVideo).toList(growable: false);
    }
  }

  Widget _buildFilters(List<DogMediaItem> items) {
    final imageCount = items.where((item) => !item.isVideo).length;
    final videoCount = items.where((item) => item.isVideo).length;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        FilterChip(
          label: Text('Alle (${items.length})'),
          selected: _filter == _DogMediaFilter.all,
          onSelected: (_) => setState(() => _filter = _DogMediaFilter.all),
        ),
        FilterChip(
          label: Text('Bilder ($imageCount)'),
          selected: _filter == _DogMediaFilter.images,
          onSelected: (_) => setState(() => _filter = _DogMediaFilter.images),
        ),
        FilterChip(
          label: Text('Video ($videoCount)'),
          selected: _filter == _DogMediaFilter.videos,
          onSelected: (_) => setState(() => _filter = _DogMediaFilter.videos),
        ),
      ],
    );
  }

  Widget _buildGrid(List<DogMediaItem> items) {
    if (items.isEmpty) {
      return const _DogMediaEmptyState(
        title: 'Ingen media i dette filteret',
        subtitle: 'Velg et annet filter for å se flere elementer.',
      );
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemBuilder: (context, index) {
        final item = items[index];
        return _DogMediaTile(
          item: item,
          onTap: () => _showPreview(item),
        );
      },
    );
  }

  Future<void> _showPreview(DogMediaItem item) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        final theme = Theme.of(sheetContext);
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: 4 / 3,
                      child: _DogMediaPreview(item: item),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    item.isVideo ? 'Video' : 'Bilde',
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  _PreviewMetaRow(
                    icon: Icons.calendar_today,
                    label: _formatDateTime(item.session.dateTime),
                  ),
                  _PreviewMetaRow(
                    icon: item.session.sessionType == SessionType.hunting
                        ? Icons.forest
                        : Icons.school,
                    label: item.session.sessionType == SessionType.hunting
                        ? 'Jakt'
                        : 'Trening',
                  ),
                  if (item.session.location.trim().isNotEmpty)
                    _PreviewMetaRow(
                      icon: Icons.place,
                      label: item.session.location.trim(),
                    ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      _openMedia(item);
                    },
                    icon: Icon(
                        item.isVideo ? Icons.play_arrow : Icons.open_in_full),
                    label: Text(item.isVideo ? 'Spill av' : 'Åpne bilde'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: item.sessionKey == null
                        ? null
                        : () {
                            Navigator.of(sheetContext).pop();
                            _openSession(item);
                          },
                    icon: const Icon(Icons.arrow_forward),
                    label: const Text('Gå til økt'),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _openMedia(DogMediaItem item) async {
    if (item.isVideo) {
      await openSessionVideo(
        context: context,
        storedPath: item.path,
        displayName: p.basename(item.path),
      );
      return;
    }

    await openSessionImage(
      context: context,
      storedPath: item.path,
      displayName: p.basename(item.path),
      watermarkDogTitle: widget.dog.title,
      watermarkDogOfficialName: widget.dog.name,
      watermarkDogNickname: widget.dog.nickname,
      watermarkShowTitle: widget.dog.watermarkShowTitle,
      watermarkShowOfficialName: widget.dog.watermarkShowOfficialName,
      watermarkShowNickname: widget.dog.watermarkShowNickname,
      watermarkUseDarkText: widget.dog.watermarkUseDarkText,
      dogId: widget.dog.id,
    );
  }

  void _openSession(DogMediaItem item) {
    final sessionKey = item.sessionKey;
    if (sessionKey == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => SessionDetailPage(
          showNewSessionSection: false,
          showSessionList: false,
          editSessionKey: sessionKey,
          detailMode: true,
          pageTitle: 'Økt',
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    final day = twoDigits(dateTime.day);
    final month = twoDigits(dateTime.month);
    final hour = twoDigits(dateTime.hour);
    final minute = twoDigits(dateTime.minute);
    return '$day.$month.${dateTime.year} $hour:$minute';
  }
}

@visibleForTesting
List<DogMediaItem> collectDogMediaItems({
  required Dog dog,
  required Iterable<HuntSession> sessions,
}) {
  final visibleSessions = filterVisibleSessionsForDog(
    sessions: sessions,
    dogId: dog.id,
    dogs: [dog],
  )..sort((a, b) => b.dateTime.compareTo(a.dateTime));

  final items = <DogMediaItem>[];
  for (final session in visibleSessions) {
    for (final path in session.mediaPaths) {
      final trimmed = path.trim();
      if (trimmed.isEmpty) continue;
      items.add(
        DogMediaItem(
          path: trimmed,
          session: session,
          sessionKey: session.key is int ? session.key as int : null,
          isVideo: isDogMediaVideoPath(trimmed),
        ),
      );
    }
  }
  return items;
}

@visibleForTesting
bool isDogMediaVideoPath(String path) {
  const videoExtensions = {
    '.mp4',
    '.mov',
    '.m4v',
    '.avi',
    '.mkv',
    '.webm',
    '.flv',
    '.3gp',
  };
  return videoExtensions.contains(p.extension(path).toLowerCase());
}

@visibleForTesting
class DogMediaItem {
  const DogMediaItem({
    required this.path,
    required this.session,
    required this.sessionKey,
    required this.isVideo,
  });

  final String path;
  final HuntSession session;
  final int? sessionKey;
  final bool isVideo;
}

class _DogMediaTile extends StatelessWidget {
  const _DogMediaTile({
    required this.item,
    required this.onTap,
  });

  final DogMediaItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.hardEdge,
      child: InkWell(
        onTap: onTap,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _DogMediaPreview(item: item),
            if (item.isVideo)
              const Center(
                child: Icon(
                  Icons.play_circle_fill,
                  color: Colors.white,
                  size: 42,
                  shadows: [Shadow(blurRadius: 8)],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DogMediaPreview extends StatelessWidget {
  const _DogMediaPreview({required this.item});

  final DogMediaItem item;

  @override
  Widget build(BuildContext context) {
    final validation = MediaStorage.resolveAndValidateMedia(item.path);
    final resolvedPath = validation?.resolvedPath;
    final exists = validation?.exists ?? false;

    if (!exists || resolvedPath == null) {
      return ColoredBox(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: const Center(
          child: Icon(Icons.broken_image),
        ),
      );
    }

    if (item.isVideo) {
      return ColoredBox(
        color: Colors.black87,
        child: Center(
          child: Icon(
            Icons.play_arrow,
            color: Theme.of(context).colorScheme.onInverseSurface,
            size: 56,
          ),
        ),
      );
    }

    return Image.file(
      File(resolvedPath),
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => const Center(
        child: Icon(Icons.broken_image),
      ),
    );
  }
}

class _PreviewMetaRow extends StatelessWidget {
  const _PreviewMetaRow({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class _DogMediaEmptyState extends StatelessWidget {
  const _DogMediaEmptyState({
    this.title = 'Ingen bilder eller videoer ennå',
    this.subtitle =
        'Media du legger til i økter for denne hunden vil vises her.',
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 48,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
