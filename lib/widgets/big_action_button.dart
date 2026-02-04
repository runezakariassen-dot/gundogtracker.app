import 'package:flutter/material.dart';

class BigActionButton extends StatelessWidget {
  const BigActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isDestructive = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = ElevatedButton.styleFrom(
      minimumSize: const Size.fromHeight(52),
      backgroundColor: isDestructive ? scheme.error : null,
      foregroundColor: isDestructive ? scheme.onError : null,
      textStyle: Theme.of(context).textTheme.titleMedium,
    );

    return SizedBox(
      width: double.infinity,
      child: icon == null
          ? ElevatedButton(
              onPressed: onPressed,
              style: style,
              child: Text(label),
            )
          : ElevatedButton.icon(
              onPressed: onPressed,
              style: style,
              icon: Icon(icon),
              label: Text(label),
            ),
    );
  }
}
