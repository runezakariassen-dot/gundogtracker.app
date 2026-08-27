import 'package:flutter/material.dart';

import '../data/local/local_health_record_repository.dart';
import '../domain/health/health_record_form_helpers.dart';
import '../l10n/app_localizations.dart';
import '../models/dog.dart';
import '../models/health_record.dart';
import 'health_record_ui_labels.dart';

class HealthRecordFormPage extends StatefulWidget {
  const HealthRecordFormPage({
    super.key,
    required this.dog,
    required this.repository,
    this.initialRecord,
  });

  final Dog dog;
  final LocalHealthRecordRepository repository;
  final HealthRecord? initialRecord;

  @override
  State<HealthRecordFormPage> createState() => _HealthRecordFormPageState();
}

class _HealthRecordFormPageState extends State<HealthRecordFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _product;
  late final TextEditingController _dose;
  late final TextEditingController _description;
  late final TextEditingController _customDays;
  late HealthRecordType _type;
  late HealthRepeatKind _repeatKind;
  late DateTime _recordedAt;
  late NextDueDateState _nextDueDateState;
  bool _saving = false;

  bool get _editing => widget.initialRecord != null;

  @override
  void initState() {
    super.initState();
    final record = widget.initialRecord;
    _title = TextEditingController(text: record?.title ?? '');
    _product = TextEditingController(text: record?.productName ?? '');
    _dose = TextEditingController(text: record?.dose ?? '');
    _description = TextEditingController(text: record?.description ?? '');
    _customDays = TextEditingController(
      text: record?.repeatInterval?.customDays?.toString() ?? '',
    );
    _type = record?.type ?? HealthRecordType.other;
    _repeatKind = record?.repeatInterval?.kind ?? HealthRepeatKind.none;
    _recordedAt = record?.recordedAt ?? DateTime.now();
    _nextDueDateState = record == null
        ? const NextDueDateState.forCreate()
        : NextDueDateState.forEdit(record.nextDueAt);
  }

  @override
  void dispose() {
    _title.dispose();
    _product.dispose();
    _dose.dispose();
    _description.dispose();
    _customDays.dispose();
    super.dispose();
  }

  HealthRepeatInterval? _repeatInterval() {
    switch (_repeatKind) {
      case HealthRepeatKind.none:
        return const HealthRepeatInterval.none();
      case HealthRepeatKind.monthly:
        return const HealthRepeatInterval.monthly();
      case HealthRepeatKind.everyThreeMonths:
        return const HealthRepeatInterval.everyThreeMonths();
      case HealthRepeatKind.everySixMonths:
        return const HealthRepeatInterval.everySixMonths();
      case HealthRepeatKind.yearly:
        return const HealthRepeatInterval.yearly();
      case HealthRepeatKind.customDays:
        final days = int.tryParse(_customDays.text.trim());
        return days != null && days > 0
            ? HealthRepeatInterval.customDays(days)
            : null;
    }
  }

  void _updateCalculatedDueDate() {
    _nextDueDateState = _nextDueDateState.relevantInputChanged(
      recordedAt: _recordedAt,
      repeatInterval: _repeatInterval(),
    );
  }

  Future<void> _pickRecordedAt() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _recordedAt,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (!mounted) return;
    if (selected != null) {
      setState(() {
        _recordedAt = selected;
        _updateCalculatedDueDate();
      });
    }
  }

  Future<void> _pickNextDueAt() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _nextDueDateState.value ?? _recordedAt,
      firstDate: DateTime(1900),
      lastDate: DateTime.now().add(const Duration(days: 36500)),
    );
    if (!mounted) return;
    if (selected != null) {
      setState(() {
        _nextDueDateState = _nextDueDateState.selectManually(selected);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      final repeat = _repeatInterval();
      final dueAt = _nextDueDateState.valueForSave(
        recordedAt: _recordedAt,
        repeatInterval: repeat,
      );
      final existing = widget.initialRecord;
      if (existing == null) {
        await widget.repository.create(
          dogId: widget.dog.id,
          dogKey: widget.dog.dogKey.isEmpty ? null : widget.dog.dogKey,
          type: _type,
          title: _title.text.trim(),
          description: _optional(_description.text),
          productName: _optional(_product.text),
          dose: _optional(_dose.text),
          recordedAt: _recordedAt,
          nextDueAt: dueAt,
          repeatInterval: repeat,
        );
      } else {
        await widget.repository.upsert(existing.copyWith(
          type: _type,
          title: _title.text.trim(),
          description: _optional(_description.text),
          productName: _optional(_product.text),
          dose: _optional(_dose.text),
          recordedAt: _recordedAt,
          nextDueAt: dueAt,
          repeatInterval: repeat,
        ));
      }
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text(AppLocalizations.of(context)!.healthJournalSaveError)),
        );
      }
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.healthJournalDeleteTitle),
        content: Text(l10n.healthJournalDeleteBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(l10n.common_cancel)),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            child: Text(l10n.healthJournalDeleteRecord),
          ),
        ],
      ),
    );
    if (!mounted) return;
    if (confirmed != true || _saving) return;
    setState(() => _saving = true);
    try {
      // Missing/already deleted is an idempotent success for this local UI.
      await widget.repository.softDelete(widget.initialRecord!.id);
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.healthJournalDeleteError)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final formatter = MaterialLocalizations.of(context).formatMediumDate;
    return Scaffold(
      appBar: AppBar(
          title: Text(_editing
              ? l10n.healthJournalEditRecord
              : l10n.healthJournalNewRecord)),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<HealthRecordType>(
              initialValue: _type,
              decoration: InputDecoration(labelText: l10n.healthJournalType),
              items: HealthRecordType.values
                  .map((type) => DropdownMenuItem(
                      value: type,
                      child: Text(healthRecordTypeLabel(l10n, type))))
                  .toList(),
              onChanged:
                  _saving ? null : (value) => setState(() => _type = value!),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _title,
              enabled: !_saving,
              decoration:
                  InputDecoration(labelText: l10n.healthJournalRecordTitle),
              validator: (value) => validateHealthTitle(value)
                  ? null
                  : l10n.healthJournalTitleRequired,
            ),
            const SizedBox(height: 12),
            _DateTile(
                label: l10n.healthJournalRecordedAt,
                value: formatter(_recordedAt),
                onTap: _saving ? null : _pickRecordedAt),
            _DateTile(
              label: l10n.healthJournalNextDueAt,
              value: _nextDueDateState.value == null
                  ? l10n.healthJournalNotSet
                  : formatter(_nextDueDateState.value!),
              onTap: _saving ? null : _pickNextDueAt,
              onClear: _nextDueDateState.value == null || _saving
                  ? null
                  : () => setState(() {
                        _nextDueDateState = _nextDueDateState.removeManually();
                      }),
            ),
            DropdownButtonFormField<HealthRepeatKind>(
              initialValue: _repeatKind,
              decoration: InputDecoration(labelText: l10n.healthJournalRepeat),
              items: HealthRepeatKind.values
                  .map((kind) => DropdownMenuItem(
                      value: kind,
                      child: Text(healthRepeatKindLabel(l10n, kind))))
                  .toList(),
              onChanged: _saving
                  ? null
                  : (value) => setState(() {
                        _repeatKind = value!;
                        _updateCalculatedDueDate();
                      }),
            ),
            if (_repeatKind == HealthRepeatKind.customDays) ...[
              const SizedBox(height: 12),
              TextFormField(
                controller: _customDays,
                enabled: !_saving,
                keyboardType: TextInputType.number,
                decoration:
                    InputDecoration(labelText: l10n.healthJournalCustomDays),
                validator: (_) =>
                    validateCustomRepeatDays(_repeatKind, _customDays.text)
                        ? null
                        : l10n.healthJournalCustomDaysError,
                onChanged: (_) => setState(_updateCalculatedDueDate),
              ),
            ],
            const SizedBox(height: 12),
            TextFormField(
                controller: _product,
                enabled: !_saving,
                decoration:
                    InputDecoration(labelText: l10n.healthJournalProduct)),
            const SizedBox(height: 12),
            TextFormField(
                controller: _dose,
                enabled: !_saving,
                decoration: InputDecoration(labelText: l10n.healthJournalDose)),
            const SizedBox(height: 12),
            TextFormField(
                controller: _description,
                enabled: !_saving,
                minLines: 3,
                maxLines: 6,
                decoration: InputDecoration(labelText: l10n.healthJournalNote)),
            const SizedBox(height: 24),
            FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(l10n.common_save)),
            if (_editing) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: _saving ? null : _delete,
                style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error),
                icon: const Icon(Icons.delete_outline),
                label: Text(l10n.healthJournalDeleteRecord),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String? _optional(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

class _DateTile extends StatelessWidget {
  const _DateTile(
      {required this.label, required this.value, this.onTap, this.onClear});
  final String label;
  final String value;
  final VoidCallback? onTap;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(value),
      trailing: onClear == null
          ? const Icon(Icons.calendar_today_outlined)
          : IconButton(onPressed: onClear, icon: const Icon(Icons.clear)),
      onTap: onTap,
    );
  }
}
