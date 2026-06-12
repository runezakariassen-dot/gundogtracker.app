import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/ui/components/dog_access_roles_card.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('owner sees Tilgang og roller and visible Endre rolle',
      (tester) async {
    await _pumpSection(
      tester,
      myRoleText: 'Din rolle: Eier',
      memberChildren: const [
        _MemberRow(
          name: 'Adminbruker',
          role: 'Administrator',
          showChangeRole: true,
        ),
      ],
    );

    expect(find.text('Tilgang og roller'), findsOneWidget);
    expect(find.text('Din rolle: Eier'), findsOneWidget);
    expect(find.text('Endre rolle'), findsWidgets);
  });

  testWidgets('admin sees Tilgang og roller and visible Endre rolle',
      (tester) async {
    await _pumpSection(
      tester,
      myRoleText: 'Din rolle: Administrator',
      memberChildren: const [
        _MemberRow(
          name: 'Vanlig bruker',
          role: 'Leser',
          showChangeRole: true,
        ),
      ],
    );

    expect(find.text('Tilgang og roller'), findsOneWidget);
    expect(find.text('Din rolle: Administrator'), findsOneWidget);
    expect(find.text('Endre rolle'), findsWidgets);
  });

  testWidgets('regular user sees Tilgang og roller as read-only',
      (tester) async {
    await _pumpSection(
      tester,
      myRoleText: 'Din rolle: Bruker',
      memberChildren: const [
        _MemberRow(
          name: 'Eier',
          role: 'Eier',
          showChangeRole: false,
        ),
      ],
    );

    expect(find.text('Tilgang og roller'), findsOneWidget);
    expect(find.text('Din rolle: Bruker'), findsOneWidget);
    expect(find.text('Endre rolle'), findsNothing);
  });
}

Future<void> _pumpSection(
  WidgetTester tester, {
  required String myRoleText,
  required List<Widget> memberChildren,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const SizedBox(height: 24, child: Text('Hero')),
            const SizedBox(height: 16),
            DogAccessRolesCard(
              myRoleText: myRoleText,
              hasMembers: memberChildren.isNotEmpty,
              memberChildren: memberChildren,
              emptyText: 'Ingen deling enda.',
              invitesContent: const Text('Ingen invitasjoner'),
              shareContent: const Text('Read only'),
            ),
          ],
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 100));
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.name,
    required this.role,
    required this.showChangeRole,
  });

  final String name;
  final String role;
  final bool showChangeRole;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(name),
      subtitle: Text(role),
      trailing: showChangeRole ? const Text('Endre rolle') : null,
    );
  }
}
