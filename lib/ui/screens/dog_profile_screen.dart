import 'package:flutter/material.dart';

import '../components/app_scaffold.dart';
import 'package:jakthund_app/l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class DogProfileScreen extends StatelessWidget {
  const DogProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppScaffold(
      appBar: AppBar(title: Text(l10n.dog_profile_title)),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: SizedBox(
              height: 220,
              child: Center(
                child: Icon(
                  Icons.pets,
                  size: 64,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          const Text(
            'Navn (placeholder)',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.dog_profile_subtitle_breed_age,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: AppSpacing.lg),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.link),
            label: const Text('Åpne stamtavle'),
          ),
        ],
      ),
    );
  }
}
