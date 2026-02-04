import 'package:flutter/material.dart';

import 'package:jakthund_app/l10n/app_localizations.dart';

import '../components/app_scaffold.dart';
import '../components/meta_chip.dart';
import '../components/note_card.dart';
import '../text/text_helpers.dart';
import '../theme/app_theme.dart';

class SessionDetailScreen extends StatelessWidget {
  const SessionDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return AppScaffold(
      appBar: AppBar(title: Text(l10n.session_detail_screen_title)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: NoteCard(hintText: l10n.session_detail_notes_hint),
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              MetaChip(label: l10n.session_detail_meta_time_minutes(90)),
              MetaChip(
                label: l10n.session_detail_meta_birds(birdText(3)),
              ),
              MetaChip(label: l10n.home_top10_points_pointsLabel(2)),
              MetaChip(
                label: l10n.session_detail_meta_secondary_points(1),
              ),
              MetaChip(
                label: l10n.session_detail_meta_flushes(flushText(0)),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.session_detail_media_section_title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(l10n.session_detail_media_empty_placeholder),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
