import '../l10n/app_localizations.dart';
import '../models/health_record.dart';

String healthRecordTypeLabel(AppLocalizations l10n, HealthRecordType type) {
  switch (type) {
    case HealthRecordType.tickTreatment:
      return l10n.healthTypeTickTreatment;
    case HealthRecordType.deworming:
      return l10n.healthTypeDeworming;
    case HealthRecordType.vaccination:
      return l10n.healthTypeVaccination;
    case HealthRecordType.medication:
      return l10n.healthTypeMedication;
    case HealthRecordType.veterinaryVisit:
      return l10n.healthTypeVeterinaryVisit;
    case HealthRecordType.allergy:
      return l10n.healthTypeAllergy;
    case HealthRecordType.injury:
      return l10n.healthTypeInjury;
    case HealthRecordType.surgery:
      return l10n.healthTypeSurgery;
    case HealthRecordType.weight:
      return l10n.healthTypeWeight;
    case HealthRecordType.hipElbowXray:
      return l10n.healthTypeHipElbowXray;
    case HealthRecordType.eyeExamination:
      return l10n.healthTypeEyeExamination;
    case HealthRecordType.dnaTest:
      return l10n.healthTypeDnaTest;
    case HealthRecordType.insurance:
      return l10n.healthTypeInsurance;
    case HealthRecordType.other:
      return l10n.healthTypeOther;
  }
}

String healthRepeatKindLabel(AppLocalizations l10n, HealthRepeatKind kind) {
  switch (kind) {
    case HealthRepeatKind.none:
      return l10n.healthRepeatNone;
    case HealthRepeatKind.monthly:
      return l10n.healthRepeatMonthly;
    case HealthRepeatKind.everyThreeMonths:
      return l10n.healthRepeatEveryThreeMonths;
    case HealthRepeatKind.everySixMonths:
      return l10n.healthRepeatEverySixMonths;
    case HealthRepeatKind.yearly:
      return l10n.healthRepeatYearly;
    case HealthRepeatKind.customDays:
      return l10n.healthRepeatCustomDays;
  }
}
