import 'package:flutter/material.dart';

import 'package:jakthund_app/l10n/app_localizations.dart';

import '../../models/dog_membership.dart';
import 'meta_chip.dart';

class RoleChip extends StatelessWidget {
  const RoleChip({
    super.key,
    required this.role,
  });

  final Role role;

  factory RoleChip.fromMembership(DogMembership membership, {Key? key}) {
    return RoleChip(
      key: key,
      role: membership.role,
    );
  }

  static String labelForRole(Role role, AppLocalizations l10n) {
    switch (role) {
      case Role.owner:
        return l10n.role_owner;
      case Role.editor:
        return l10n.role_editor;
      case Role.viewer:
        return l10n.role_viewer;
      case Role.admin:
        return l10n.role_admin;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return MetaChip(label: labelForRole(role, l10n));
  }
}
