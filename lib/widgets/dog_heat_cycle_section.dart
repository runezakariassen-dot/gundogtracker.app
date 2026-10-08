import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../domain/dogs/dog_heat_cycle_repository.dart';
import '../l10n/app_localizations.dart';
import '../models/dog.dart';
import '../models/dog_heat_cycle_log.dart';
import '../models/dog_sex.dart';

bool shouldShowHeatCycleSection(Dog dog) => dog.sex == DogSex.female;

class DogHeatCycleSection extends StatefulWidget {
  const DogHeatCycleSection({
    super.key,
    required this.dog,
    this.repository,
  });

  final Dog dog;
  final DogHeatCycleRepository? repository;

  @override
  State<DogHeatCycleSection> createState() => _DogHeatCycleSectionState();
}

class _DogHeatCycleSectionState extends State<DogHeatCycleSection> {
  late final DogHeatCycleRepository _repository;
  late Future<List<DogHeatCycleLog>> _entries;

  @override
  void initState() {
    super.initState();
    _repository = widget.repository ?? DogHeatCycleRepository();
    _reload();
  }

  void _reload() {
    _entries = _repository.listForDog(widget.dog.id);
  }

  String _formatPeriod(DogHeatCycleLog entry) {
    final l10n = AppLocalizations.of(context)!;
    final start = DateFormat('dd.MM.yyyy').format(entry.startDate);
    final end = entry.endDate == null
        ? l10n.dog_heat_cycle_end_not_set
        : DateFormat('dd.MM.yyyy').format(entry.endDate!);
    return l10n.dog_heat_cycle_period_value(start, end);
  }

  Future<void> _showInfoDialog() async {
    final l10n = AppLocalizations.of(context)!;
    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.dog_heat_cycle_info_title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.dog_heat_cycle_info_line_1),
                const SizedBox(height: 8),
                Text(l10n.dog_heat_cycle_info_line_2),
                const SizedBox(height: 8),
                Text(l10n.dog_heat_cycle_info_line_3),
                const SizedBox(height: 8),
                Text(l10n.dog_heat_cycle_info_line_4),
                const SizedBox(height: 8),
                Text(l10n.dog_heat_cycle_info_line_5),
                const SizedBox(height: 8),
                Text(l10n.dog_heat_cycle_info_line_6),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n.common_ok),
            ),
          ],
        );
      },
    );
  }

  Future<void> _openEditor([DogHeatCycleLog? initial]) async {
    final l10n = AppLocalizations.of(context)!;
    var selectedStartDate = initial?.startDate ?? DateTime.now();
    DateTime? selectedEndDate = initial?.endDate;
    final noteController = TextEditingController(text: initial?.note ?? '');

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                initial == null
                    ? l10n.dog_heat_cycle_add_title
                    : l10n.dog_heat_cycle_edit_title,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.dog_heat_cycle_start_date_label),
                      subtitle: Text(
                        DateFormat('dd.MM.yyyy').format(selectedStartDate),
                      ),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedStartDate,
                          firstDate: DateTime(1950),
                          lastDate: DateTime.now().add(
                            const Duration(days: 3650),
                          ),
                        );
                        if (picked == null) return;
                        setDialogState(() {
                          selectedStartDate = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                          );
                          if (selectedEndDate != null &&
                              selectedEndDate!.isBefore(selectedStartDate)) {
                            selectedEndDate = null;
                          }
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(l10n.dog_heat_cycle_end_date_label),
                      subtitle: Text(
                        selectedEndDate == null
                            ? l10n.dog_heat_cycle_end_not_set
                            : DateFormat('dd.MM.yyyy').format(selectedEndDate!),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (selectedEndDate != null)
                            IconButton(
                              icon: const Icon(Icons.close),
                              onPressed: () {
                                setDialogState(() => selectedEndDate = null);
                              },
                            ),
                          const Icon(Icons.calendar_today),
                        ],
                      ),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: selectedEndDate ?? selectedStartDate,
                          firstDate: selectedStartDate,
                          lastDate: DateTime.now().add(
                            const Duration(days: 3650),
                          ),
                        );
                        if (picked == null) return;
                        setDialogState(() {
                          selectedEndDate = DateTime(
                            picked.year,
                            picked.month,
                            picked.day,
                          );
                        });
                      },
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: noteController,
                      minLines: 2,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: l10n.dog_heat_cycle_note_label,
                        hintText: l10n.dog_heat_cycle_note_hint,
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n.dog_detail_button_cancel),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(l10n.common_save),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) {
      _disposeAfterDialogCloses(noteController);
      return;
    }

    final now = DateTime.now();
    final trimmedNote = noteController.text.trim();
    await _repository.saveForDog(
      DogHeatCycleLog(
        dogId: widget.dog.id,
        startDate: selectedStartDate,
        endDate: selectedEndDate,
        note: trimmedNote.isEmpty ? null : trimmedNote,
        createdAt: initial?.createdAt ?? now,
        updatedAt: now,
      ),
    );
    _disposeAfterDialogCloses(noteController);
    if (mounted) setState(_reload);
  }

  void _disposeAfterDialogCloses(TextEditingController controller) {
    Future<void>.delayed(
      const Duration(milliseconds: 300),
      controller.dispose,
    );
  }

  Future<void> _delete(DogHeatCycleLog entry) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(l10n.dog_heat_cycle_delete_title),
          content: Text(l10n.dog_heat_cycle_delete_body),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(l10n.dog_detail_button_cancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(l10n.dog_editor_button_delete),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;

    await _repository.deleteForDog(
      dogId: widget.dog.id,
      createdAt: entry.createdAt,
    );
    if (mounted) setState(_reload);
  }

  @override
  Widget build(BuildContext context) {
    if (!shouldShowHeatCycleSection(widget.dog)) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context)!;
    return Card(
      key: const Key('dog_heat_cycle_section'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.dog_heat_cycle_section_title,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  tooltip: l10n.dog_heat_cycle_info_title,
                  onPressed: _showInfoDialog,
                  icon: const Icon(Icons.info_outline),
                ),
              ],
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              key: const Key('dog_heat_cycle_add'),
              onPressed: _openEditor,
              icon: const Icon(Icons.add),
              label: Text(l10n.dog_heat_cycle_add_button),
            ),
            const SizedBox(height: 12),
            FutureBuilder<List<DogHeatCycleLog>>(
              future: _entries,
              builder: (context, snapshot) {
                final entries = snapshot.data ?? const <DogHeatCycleLog>[];
                if (entries.isEmpty) {
                  return Text(
                    l10n.dog_heat_cycle_empty,
                    style: Theme.of(context).textTheme.bodyMedium,
                  );
                }
                return Column(
                  children: entries.map((entry) {
                    final note = entry.note?.trim();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                _formatPeriod(entry),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                              if (note != null && note.isNotEmpty) ...[
                                const SizedBox(height: 8),
                                Text(note),
                              ],
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => _openEditor(entry),
                                      icon: const Icon(Icons.edit),
                                      label: Text(
                                        l10n.dog_heat_cycle_edit_button,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: FilledButton.icon(
                                      onPressed: () => _delete(entry),
                                      icon: const Icon(Icons.delete),
                                      label: Text(
                                        l10n.dog_heat_cycle_delete_button,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(growable: false),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
