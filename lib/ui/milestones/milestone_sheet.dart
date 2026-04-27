// ignore_for_file: depend_on_referenced_packages, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';

import '../../domain/milestones/milestone_models.dart';
import 'milestone_strings.dart';

Future<void> showMilestoneSheet({
  required BuildContext context,
  required MilestoneDef def,
  required DateTime achievedAt,
  required String dogName,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) {
      final l10n = AppLocalizations.of(ctx)!;
      final dateText = DateFormat('dd.MM.yyyy HH:mm').format(achievedAt);
      final title = milestoneTitleL10n(def, l10n);
      final subtitle = milestoneSubtitleText(ctx, def, dogName);
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(ctx).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: Theme.of(ctx).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            Text(
              dateText,
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color:
                        Theme.of(ctx).colorScheme.onSurface.withOpacity(0.6),
                  ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.of(ctx).pop(),
                child: Text(l10n.milestone_sheet_button_ok),
              ),
            ),
          ],
        ),
      );
    },
  );
}
