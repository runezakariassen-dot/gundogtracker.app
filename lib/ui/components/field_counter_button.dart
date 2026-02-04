import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class FieldCounterButton extends StatelessWidget {
  const FieldCounterButton({
    super.key,
    required this.label,
    required this.count,
    required this.icon,
    this.onPressed,
    this.height = 72,
    this.style,
  });

  final String label;
  final int count;
  final IconData icon;
  final VoidCallback? onPressed;
  final double height;
  final ButtonStyle? style;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: style ??
            OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            ),
        child: Row(
          children: [
            Icon(icon, size: 24),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                label,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              count.toString(),
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
            ),
            const SizedBox(width: AppSpacing.md),
            const Icon(Icons.add_circle_outline, size: 22),
          ],
        ),
      ),
    );
  }
}
