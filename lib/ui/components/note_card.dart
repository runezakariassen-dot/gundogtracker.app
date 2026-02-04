import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class NoteCard extends StatelessWidget {
  const NoteCard({
    super.key,
    this.hintText = '',
    this.minLines = 8,
    this.textStyle,
    this.hintStyle,
  });

  final String hintText;
  final int minLines;
  final TextStyle? textStyle;
  final TextStyle? hintStyle;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: TextField(
          minLines: minLines,
          maxLines: null,
          style: textStyle,
          decoration: InputDecoration.collapsed(
            hintText: hintText,
            hintStyle: hintStyle,
          ),
        ),
      ),
    );
  }
}
