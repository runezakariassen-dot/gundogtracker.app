import 'package:flutter_test/flutter_test.dart';
import 'package:jakthund_app/models/dog_membership.dart';
import 'package:jakthund_app/ui/components/role_chip.dart';

import '../test_app.dart';

void main() {
  testWidgets('RoleChip shows Norwegian label for Owner (Eier)',
      (tester) async {
    await pumpApp(
      tester,
      child: const RoleChip(
        role: Role.owner,
      ),
    );

    expect(find.text('Eier'), findsOneWidget);
    expect(find.text('Owner'), findsNothing);
  });
}
