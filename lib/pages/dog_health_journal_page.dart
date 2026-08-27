import 'package:flutter/material.dart';

import '../data/local/local_health_record_repository.dart';
import '../domain/health/health_record_date_helpers.dart';
import '../l10n/app_localizations.dart';
import '../models/dog.dart';
import '../models/health_record.dart';
import 'health_record_ui_labels.dart';
import 'health_record_form_page.dart';

class DogHealthJournalPage extends StatefulWidget {
  const DogHealthJournalPage({
    super.key,
    required this.dog,
    this.repository,
  });

  final Dog dog;
  final LocalHealthRecordRepository? repository;

  @override
  State<DogHealthJournalPage> createState() => _DogHealthJournalPageState();
}

class _DogHealthJournalPageState extends State<DogHealthJournalPage> {
  late final LocalHealthRecordRepository _repository;
  late Future<List<HealthRecord>> _records;
  bool _openingForm = false;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? LocalHealthRecordRepository();
    _reload();
  }

  void _reload() {
    _records = Future<List<HealthRecord>>.sync(
      () => _repository.listByDogId(widget.dog.id),
    );
  }

  Future<void> _openForm([HealthRecord? record]) async {
    if (_openingForm) return;
    _openingForm = true;
    try {
      final changed = await Navigator.of(context).push<bool>(
        MaterialPageRoute(
          builder: (_) => HealthRecordFormPage(
            dog: widget.dog,
            repository: _repository,
            initialRecord: record,
          ),
        ),
      );
      if (changed == true && mounted) setState(_reload);
    } finally {
      _openingForm = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.healthJournalTitle),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(24),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(widget.dog.displayName),
          ),
        ),
      ),
      body: FutureBuilder<List<HealthRecord>>(
        future: _records,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(l10n.healthJournalLoadError),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => setState(_reload),
                      child: Text(l10n.common_retry),
                    ),
                  ],
                ),
              ),
            );
          }
          final records = snapshot.data ?? const <HealthRecord>[];
          if (records.isEmpty) {
            return _HealthEmptyState(onAdd: _openForm);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: records.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final record = records[index];
              return _HealthRecordCard(
                key: ValueKey(record.id),
                record: record,
                onTap: () => _openForm(record),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: Text(l10n.healthJournalNewRecord),
      ),
    );
  }
}

class _HealthEmptyState extends StatelessWidget {
  const _HealthEmptyState({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.medical_information_outlined, size: 64),
            const SizedBox(height: 16),
            Text(l10n.healthJournalEmptyTitle,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(l10n.healthJournalEmptyBody, textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add),
              label: Text(l10n.healthJournalAddRecord),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthRecordCard extends StatelessWidget {
  const _HealthRecordCard({
    super.key,
    required this.record,
    required this.onTap,
  });

  final HealthRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final formatter = MaterialLocalizations.of(context).formatMediumDate;
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: const Icon(Icons.medical_services_outlined),
        title: Text(record.title),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
                '${healthRecordTypeLabel(l10n, record.type)} · ${formatter(record.recordedAt)}'),
            if (record.productName?.isNotEmpty == true)
              Text('${l10n.healthJournalProduct}: ${record.productName}'),
            if (record.dose?.isNotEmpty == true)
              Text('${l10n.healthJournalDose}: ${record.dose}'),
            if (record.nextDueAt != null)
              Text(
                dueStatusLabel(
                    l10n, record.nextDueAt!, DateTime.now(), formatter),
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}

String dueStatusLabel(
  AppLocalizations l10n,
  DateTime dueAt,
  DateTime now,
  String Function(DateTime) formatter,
) {
  final status = healthDueStatus(dueAt, now);
  switch (status.kind) {
    case HealthDueStatusKind.overdue:
      return l10n.healthJournalOverdueDays(status.days);
    case HealthDueStatusKind.today:
      return l10n.healthJournalToday;
    case HealthDueStatusKind.future:
      if (status.days <= 30) return l10n.healthJournalInDays(status.days);
      return l10n.healthJournalNextDate(formatter(dueAt));
  }
}
