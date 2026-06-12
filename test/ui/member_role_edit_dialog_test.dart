import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';
import 'package:jakthund_app/models/dog_membership.dart';
import 'package:jakthund_app/ui/components/member_role_edit_dialog.dart';
import 'package:jakthund_app/ui/components/role_chip.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('role dialog shows all provided role options', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('nb'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MemberRoleEditDialog(
            initialRole: Role.editor,
            availableRoles: <Role>[
              Role.owner,
              Role.admin,
              Role.editor,
              Role.viewer,
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(DropdownButtonFormField<Role>));
    await tester.pumpAndSettle();

    expect(find.text('Eier').last, findsOneWidget);
    expect(find.text('Administrator').last, findsOneWidget);
    expect(find.text('Redaktør').last, findsOneWidget);
    expect(find.text('Leser').last, findsOneWidget);
  });

  testWidgets('role dialog keeps current role selected initially', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('nb'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MemberRoleEditDialog(
            initialRole: Role.admin,
            availableRoles: <Role>[
              Role.owner,
              Role.admin,
              Role.editor,
              Role.viewer,
            ],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Administrator'), findsOneWidget);
  });

  testWidgets('UI shows updated role after saving from role dialog',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('nb'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: _RoleDialogHarness(),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Leser'), findsOneWidget);

    await tester.tap(find.text('Endre rolle'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.byType(DropdownButtonFormField<Role>));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.text('Administrator').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.widgetWithText(FilledButton, 'Lagre').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    await tester.tap(find.widgetWithText(FilledButton, 'Lagre').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Leser'), findsNothing);
    expect(find.text('Administrator'), findsOneWidget);
  });
}

class _RoleDialogHarness extends StatefulWidget {
  const _RoleDialogHarness();

  @override
  State<_RoleDialogHarness> createState() => _RoleDialogHarnessState();
}

class _RoleDialogHarnessState extends State<_RoleDialogHarness> {
  Role _role = Role.viewer;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(RoleChip.labelForRole(_role, l10n)),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () async {
                final updatedRole = await showDialog<Role>(
                  context: context,
                  builder: (_) => const MemberRoleEditDialog(
                    initialRole: Role.viewer,
                    availableRoles: <Role>[
                      Role.owner,
                      Role.admin,
                      Role.editor,
                      Role.viewer,
                    ],
                  ),
                );
                if (!mounted || updatedRole == null || updatedRole == _role) {
                  return;
                }
                if (updatedRole == Role.admin) {
                  final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (dialogContext) => AlertDialog(
                          title: Text(l10n.dog_detail_role_confirm_admin_title),
                          content: Text(
                            l10n.dog_detail_role_confirm_admin_message,
                          ),
                          actions: [
                            TextButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(false),
                              child: Text(l10n.common_cancel),
                            ),
                            FilledButton(
                              onPressed: () =>
                                  Navigator.of(dialogContext).pop(true),
                              child: Text(l10n.common_save),
                            ),
                          ],
                        ),
                      ) ??
                      false;
                  if (!confirmed) return;
                }
                setState(() => _role = updatedRole);
              },
              child: const Text('Endre rolle'),
            ),
          ],
        ),
      ),
    );
  }
}
