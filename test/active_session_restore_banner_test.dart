import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jakthund_app/domain/models/active_session_draft.dart';
import 'package:jakthund_app/domain/repositories/active_session_draft_repository.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';
import 'package:jakthund_app/models/dog.dart';
import 'package:jakthund_app/ui/home/widgets/active_session_restore_banner.dart';

void main() {
  late _FakeActiveSessionDraftRepository repository;
  late Dog dog;
  late ActiveSessionDraft draft;

  setUp(() {
    repository = _FakeActiveSessionDraftRepository();
    dog = Dog(name: 'Luna', dogKey: 'key', regNrDisplay: '123');
    draft = ActiveSessionDraft.now(
      sessionId: 'session-1',
      dogId: dog.id,
    );
  });

  tearDown(() {
    repository.dispose();
  });

  testWidgets('shows banner when draft exists', (tester) async {
    repository.emit(draft);

    await tester.pumpWidget(
      _buildApp(
        repository: repository,
        onContinue: (_) {},
        onDiscard: () {},
        dogLookup: (_) => dog,
      ),
    );
    await tester.pump();

    final l10n = await AppLocalizations.delegate.load(const Locale('nb'));
    expect(find.text(l10n.home_continueActiveSessionTitle), findsWidgets);
    expect(find.textContaining(dog.name), findsOneWidget);
  });

  testWidgets('calls onContinue when button tapped', (tester) async {
    repository.emit(draft);
    ActiveSessionDraft? captured;

    await tester.pumpWidget(
      _buildApp(
        repository: repository,
        onContinue: (value) => captured = value,
        onDiscard: () {},
        dogLookup: (_) => dog,
      ),
    );
    await tester.pump();

    final l10n = await AppLocalizations.delegate.load(const Locale('nb'));
    await tester.tap(
      find.widgetWithText(FilledButton, l10n.home_continueActiveSessionButton),
    );
    await tester.pump();

    expect(captured, equals(draft));
  });

  testWidgets('calls onDiscard when button tapped', (tester) async {
    repository.emit(draft);
    var discarded = false;

    await tester.pumpWidget(
      _buildApp(
        repository: repository,
        onContinue: (_) {},
        onDiscard: () => discarded = true,
        dogLookup: (_) => dog,
      ),
    );
    await tester.pump();

    final l10n = await AppLocalizations.delegate.load(const Locale('nb'));
    await tester.tap(
      find.widgetWithText(OutlinedButton, l10n.home_discardActiveSessionButton),
    );
    await tester.pump();

    expect(discarded, isTrue);
  });
}

Widget _buildApp({
  required ActiveSessionDraftRepository repository,
  required ValueChanged<ActiveSessionDraft> onContinue,
  VoidCallback? onDiscard,
  Dog? Function(String dogId)? dogLookup,
}) {
  return MaterialApp(
    locale: const Locale('nb'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: ActiveSessionRestoreBanner(
        repository: repository,
        onContinue: onContinue,
        onDiscard: onDiscard,
        dogLookup: dogLookup,
      ),
    ),
  );
}

class _FakeActiveSessionDraftRepository
    implements ActiveSessionDraftRepository {
  final _controller = StreamController<ActiveSessionDraft?>.broadcast();
  ActiveSessionDraft? _current;

  @override
  Stream<ActiveSessionDraft?> watch() => _controller.stream;

  void emit(ActiveSessionDraft? value) {
    _current = value;
    _controller.add(value);
  }

  @override
  Future<void> clear() async {
    emit(null);
  }

  @override
  Future<ActiveSessionDraft?> load() async => _current;

  @override
  Future<void> save(ActiveSessionDraft draft) async {
    emit(draft);
  }

  void dispose() {
    _controller.close();
  }
}
