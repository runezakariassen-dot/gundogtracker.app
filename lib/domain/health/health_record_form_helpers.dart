import '../../models/health_record.dart';
import 'health_record_date_helpers.dart';

enum NextDueDateMode { unchanged, automatic, manual, removed }

class NextDueDateState {
  const NextDueDateState._(this.mode, this.value);

  const NextDueDateState.forCreate() : this._(NextDueDateMode.automatic, null);

  NextDueDateState.forEdit(DateTime? existingValue)
      : this._(NextDueDateMode.unchanged, existingValue);

  final NextDueDateMode mode;
  final DateTime? value;

  NextDueDateState selectManually(DateTime value) {
    return NextDueDateState._(NextDueDateMode.manual, value);
  }

  NextDueDateState removeManually() {
    return const NextDueDateState._(NextDueDateMode.removed, null);
  }

  NextDueDateState relevantInputChanged({
    required DateTime recordedAt,
    required HealthRepeatInterval? repeatInterval,
  }) {
    if (mode == NextDueDateMode.manual || mode == NextDueDateMode.removed) {
      return this;
    }
    return NextDueDateState._(
      NextDueDateMode.automatic,
      calculateHealthNextDueAt(recordedAt, repeatInterval),
    );
  }

  DateTime? valueForSave({
    required DateTime recordedAt,
    required HealthRepeatInterval? repeatInterval,
  }) {
    switch (mode) {
      case NextDueDateMode.unchanged:
      case NextDueDateMode.manual:
        return value;
      case NextDueDateMode.removed:
        return null;
      case NextDueDateMode.automatic:
        return calculateHealthNextDueAt(recordedAt, repeatInterval);
    }
  }
}

bool validateHealthTitle(String? value) {
  return value != null && value.trim().isNotEmpty;
}

bool validateCustomRepeatDays(HealthRepeatKind kind, String value) {
  if (kind != HealthRepeatKind.customDays) return true;
  final days = int.tryParse(value.trim());
  return days != null && days > 0;
}
