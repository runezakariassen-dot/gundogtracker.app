import 'package:flutter/material.dart';

class DogAccessRolesCard extends StatelessWidget {
  const DogAccessRolesCard({
    super.key,
    required this.myRoleText,
    required this.hasMembers,
    required this.memberChildren,
    required this.emptyText,
    required this.invitesContent,
    required this.shareContent,
  });

  final String? myRoleText;
  final bool hasMembers;
  final List<Widget> memberChildren;
  final String emptyText;
  final Widget invitesContent;
  final Widget shareContent;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[
      Text(
        'Tilgang og roller',
        style: Theme.of(context).textTheme.titleMedium,
      ),
      const SizedBox(height: 4),
      Text(
        'Access section v2',
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 12),
    ];

    if (myRoleText != null && myRoleText!.isNotEmpty) {
      children.add(
        Text(
          myRoleText!,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
      children.add(const SizedBox(height: 16));
    }

    if (hasMembers) {
      children.add(
        Text(
          'Medlemmer',
          style: Theme.of(context).textTheme.titleSmall,
        ),
      );
      children.add(const SizedBox(height: 8));
      children.addAll(memberChildren);
    } else {
      children.add(
        Text(
          emptyText,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      );
    }

    children.add(const SizedBox(height: 16));
    children.add(
      Text(
        'Invitasjoner',
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
    children.add(const SizedBox(height: 8));
    children.add(invitesContent);
    children.add(const SizedBox(height: 16));
    children.add(shareContent);

    return Card(
      key: const ValueKey('dog-detail-access-section'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: children,
        ),
      ),
    );
  }
}
