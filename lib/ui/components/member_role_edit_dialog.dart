import 'package:flutter/material.dart';

import 'package:jakthund_app/l10n/app_localizations.dart';
import 'package:jakthund_app/models/dog_membership.dart';

import 'role_chip.dart';

class MemberRoleEditDialog extends StatefulWidget {
  const MemberRoleEditDialog({
    super.key,
    required this.initialRole,
    required this.availableRoles,
  });

  final Role initialRole;
  final List<Role> availableRoles;

  @override
  State<MemberRoleEditDialog> createState() => _MemberRoleEditDialogState();
}

class _MemberRoleEditDialogState extends State<MemberRoleEditDialog> {
  late Role _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.dog_detail_role_dialog_title),
      content: DropdownButtonFormField<Role>(
        initialValue: _selectedRole,
        decoration: InputDecoration(
          labelText: l10n.dog_detail_role_dialog_label,
        ),
        items: widget.availableRoles
            .map(
              (role) => DropdownMenuItem<Role>(
                value: role,
                child: Text(RoleChip.labelForRole(role, l10n)),
              ),
            )
            .toList(growable: false),
        onChanged: (value) {
          if (value == null) return;
          setState(() => _selectedRole = value);
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(l10n.common_cancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_selectedRole),
          child: Text(l10n.common_save),
        ),
      ],
    );
  }
}
