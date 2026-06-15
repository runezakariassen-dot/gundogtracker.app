import 'dart:async';

import 'package:flutter/material.dart';

import '../../../domain/models/active_session_draft.dart';
import '../../../domain/repositories/active_session_draft_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../models/dog.dart';

class ActiveSessionRestoreBanner extends StatefulWidget {
  const ActiveSessionRestoreBanner({
    super.key,
    required this.repository,
    required this.onContinue,
    this.onDiscard,
    this.dogLookup,
  });

  final ActiveSessionDraftRepository repository;
  final ValueChanged<ActiveSessionDraft> onContinue;
  final VoidCallback? onDiscard;
  final Dog? Function(String dogId)? dogLookup;

  @override
  State<ActiveSessionRestoreBanner> createState() =>
      _ActiveSessionRestoreBannerState();
}

class _ActiveSessionRestoreBannerState
    extends State<ActiveSessionRestoreBanner> {
  ActiveSessionDraft? _draft;
  StreamSubscription<ActiveSessionDraft?>? _subscription;

  @override
  void initState() {
    super.initState();
    _subscription = widget.repository.watch().listen(_handleDraftUpdate);
    _loadInitialDraft();
  }

  Future<void> _loadInitialDraft() async {
    final draft = await widget.repository.load();
    if (!mounted) return;
    setState(() => _draft = draft);
  }

  void _handleDraftUpdate(ActiveSessionDraft? draft) {
    if (!mounted) return;
    setState(() => _draft = draft);
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = _draft;
    if (draft == null) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    if (l10n == null) return const SizedBox.shrink();

    final dog = widget.dogLookup?.call(draft.dogId);
    final title = dog != null
        ? l10n.home_continueActiveSessionTitle
        : l10n.home_continueActiveSessionMissingDogTitle;
    final subtitle = dog != null
        ? l10n.home_continueActiveSessionSubtitle(dog.name)
        : l10n.home_continueActiveSessionMissingDogSubtitle;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: () => widget.onContinue(draft),
                      child: Text(l10n.home_continueActiveSessionButton),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: widget.onDiscard,
                    child: Text(l10n.home_discardActiveSessionButton),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
