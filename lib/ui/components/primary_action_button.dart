import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    super.key,
    required this.label,
    this.subtitle,
    this.icon,
    this.onPressed,
    this.height = 60,
  });

  final String label;
  final String? subtitle;
  final IconData? icon;
  final VoidCallback? onPressed;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final labelWidget = icon == null
        ? Text(label,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w600))
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22),
              const SizedBox(width: AppSpacing.sm),
              Text(label,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w600)),
            ],
          );
    final child = subtitle == null
        ? labelWidget
        : Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              labelWidget,
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ],
          );

    final double effectiveHeight =
        (subtitle == null ? height : (height < 72 ? 72 : height)).toDouble();
    return SizedBox(
      width: double.infinity,
      height: effectiveHeight,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: colorScheme.tertiary,
          foregroundColor: colorScheme.onTertiary,
        ),
        onPressed: onPressed,
        child: child,
      ),
    );
  }
}
