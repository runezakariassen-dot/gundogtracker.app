// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';

import '../components/app_scaffold.dart';
import '../components/field_counter_button.dart';
import '../components/note_card.dart';
import '../theme/app_theme.dart';

enum _FieldActionType { stand, sekundering, stokk, fugl }

class ActiveSessionScreen extends StatefulWidget {
  const ActiveSessionScreen({super.key});

  @override
  State<ActiveSessionScreen> createState() => _ActiveSessionScreenState();
}

class _ActiveSessionScreenState extends State<ActiveSessionScreen> {
  int _standCount = 0;
  int _sekunderingCount = 0;
  int _stokkCount = 0;
  int _fuglCount = 0;
  final List<_FieldActionType> _actionHistory = [];

  void _increment(_FieldActionType type) {
    setState(() {
      switch (type) {
        case _FieldActionType.stand:
          _standCount += 1;
          break;
        case _FieldActionType.sekundering:
          _sekunderingCount += 1;
          break;
        case _FieldActionType.stokk:
          _stokkCount += 1;
          break;
        case _FieldActionType.fugl:
          _fuglCount += 1;
          break;
      }
      _actionHistory.add(type);
    });
  }

  void _undoLast() {
    if (_actionHistory.isEmpty) return;

    setState(() {
      final lastAction = _actionHistory.removeLast();
      switch (lastAction) {
        case _FieldActionType.stand:
          if (_standCount > 0) _standCount -= 1;
          break;
        case _FieldActionType.sekundering:
          if (_sekunderingCount > 0) _sekunderingCount -= 1;
          break;
        case _FieldActionType.stokk:
          if (_stokkCount > 0) _stokkCount -= 1;
          break;
        case _FieldActionType.fugl:
          if (_fuglCount > 0) _fuglCount -= 1;
          break;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final hintColor = theme.colorScheme.onSurface.withOpacity(0.5);
    final secondarySurface = theme.colorScheme.surface.withOpacity(0.7);
    final secondaryButtonStyle = OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      side: BorderSide(color: theme.colorScheme.onSurface.withOpacity(0.2)),
      foregroundColor: theme.colorScheme.onSurface.withOpacity(0.85),
      backgroundColor: secondarySurface,
    );

    return AppScaffold(
      appBar: AppBar(
        title: Text(l10n.session_detail_title_active_session),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 160,
                child: NoteCard(
                  hintText: l10n.session_detail_notes_hint,
                  minLines: 3,
                  textStyle: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                  hintStyle: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: hintColor,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                l10n.active_session_hunt_events_title,
                                style: theme.textTheme.titleLarge,
                              ),
                              const SizedBox(height: AppSpacing.md),
                              FieldCounterButton(
                                label: l10n.active_session_action_stand_plus1,
                                count: _standCount,
                                icon: Icons.flag,
                                height: 88,
                                onPressed: () =>
                                    _increment(_FieldActionType.stand),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              FieldCounterButton(
                                label:
                                    l10n.active_session_action_secondary_plus1,
                                count: _sekunderingCount,
                                icon: Icons.assistant_photo,
                                height: 88,
                                onPressed: () =>
                                    _increment(_FieldActionType.sekundering),
                              ),
                              const SizedBox(height: AppSpacing.md),
                              FieldCounterButton(
                                label: l10n.active_session_action_flush_plus1,
                                count: _stokkCount,
                                icon: Icons.outlined_flag,
                                height: 88,
                                onPressed: () =>
                                    _increment(_FieldActionType.stokk),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      FieldCounterButton(
                        label: l10n.active_session_action_bird_plus1,
                        count: _fuglCount,
                        icon: Icons.emoji_nature,
                        height: 72,
                        style: secondaryButtonStyle,
                        onPressed: () => _increment(_FieldActionType.fugl),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton.icon(
                        onPressed: _actionHistory.isEmpty ? null : _undoLast,
                        icon: const Icon(Icons.undo),
                        label: Text(l10n.active_session_action_undo),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(64),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
