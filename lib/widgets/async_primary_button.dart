import 'package:flutter/material.dart';

import '../utils/async_action_guard.dart';

class AsyncPrimaryButton extends StatelessWidget {
  const AsyncPrimaryButton({
    super.key,
    required this.guard,
    required this.label,
    this.busyLabel,
    required this.onPressed,
    this.icon,
  });

  final AsyncActionGuard guard;
  final String label;
  final String? busyLabel;
  final Future<void> Function() onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: guard,
      builder: (context, _) {
        final busy = guard.isBusy;
        final text = busy ? (guard.label ?? busyLabel ?? label) : label;

        return SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton.icon(
            onPressed: busy ? null : () => onPressed(),
            icon: busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(icon ?? Icons.check),
            label: Text(text),
          ),
        );
      },
    );
  }
}
