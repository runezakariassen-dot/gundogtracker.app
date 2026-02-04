import 'package:jakthund_app/domain/milestones/milestone_catalog.dart'
    as catalog;
import 'package:jakthund_app/domain/milestones/milestone_models.dart';
import 'package:jakthund_app/domain/repositories/dog_milestone_state_repository.dart';

class DogMilestoneDisplay {
  const DogMilestoneDisplay({
    required this.def,
    required this.achievedAt,
  });

  final MilestoneDef def;
  final DateTime? achievedAt;
}

final Map<String, MilestoneDef> _milestoneDefByKey = _buildMilestoneLookup();

Map<String, MilestoneDef> _buildMilestoneLookup() {
  final result = <String, MilestoneDef>{};
  final dynamic list = catalog.milestoneCatalog;
  if (list is! Iterable) return result;

  for (final cfg in list) {
    final def = _extractMilestoneDef(cfg);
    if (def == null) continue;
    final keys = _collectKeys(cfg, def);
    for (final key in keys) {
      if (key.isNotEmpty) {
        result[key] = def;
      }
    }
  }
  return result;
}

Set<String> _collectKeys(dynamic cfg, MilestoneDef def) {
  final keys = <String>{};
  keys.addAll(_normalizeKey(def.id));
  final alt = _extractKeyFromConfig(cfg);
  if (alt != null) {
    keys.addAll(_normalizeKey(alt));
  }
  return keys;
}

Set<String> _normalizeKey(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return {};
  final set = <String>{trimmed};
  final dot = trimmed.lastIndexOf('.');
  if (dot != -1 && dot < trimmed.length - 1) {
    set.add(trimmed.substring(dot + 1).trim());
  }
  return set;
}

String? _extractKeyFromConfig(dynamic cfg) {
  if (cfg == null) return null;
  try {
    final dynamic candidate = cfg.def;
    if (candidate != null) {
      final dynamic alt = candidate.id;
      if (alt != null) {
        return alt is String ? alt : alt.toString();
      }
    }
  } catch (_) {}

  for (final field in ['milestoneId', 'id']) {
    try {
      final dynamic value = cfg.toJson != null ? cfg.toJson()[field] : null;
      if (value != null) {
        return value is String ? value : value.toString();
      }
    } catch (_) {}
    try {
      final dynamic value = cfg.toMap != null ? cfg.toMap()[field] : null;
      if (value != null) {
        return value is String ? value : value.toString();
      }
    } catch (_) {}
  }

  try {
    final dynamic value = cfg.milestoneId;
    if (value != null) {
      return value is String ? value : value.toString();
    }
  } catch (_) {}
  try {
    final dynamic value = cfg.id;
    if (value != null) {
      return value is String ? value : value.toString();
    }
  } catch (_) {}

  return null;
}

MilestoneDef? _extractMilestoneDef(dynamic cfg) {
  if (cfg == null) return null;
  try {
    final dynamic def = cfg.def;
    if (def is MilestoneDef) return def;
  } catch (_) {}
  try {
    final dynamic def = cfg.definition;
    if (def is MilestoneDef) return def;
  } catch (_) {}
  try {
    final dynamic def = cfg.milestoneDef;
    if (def is MilestoneDef) return def;
  } catch (_) {}
  return null;
}

MilestoneDef? _lookup(String rawKey) {
  final trimmed = rawKey.trim();
  if (trimmed.isEmpty) return null;
  final direct = _milestoneDefByKey[trimmed];
  if (direct != null) return direct;
  final dot = trimmed.lastIndexOf('.');
  if (dot != -1 && dot < trimmed.length - 1) {
    final shortened = trimmed.substring(dot + 1).trim();
    return _milestoneDefByKey[shortened];
  }
  return null;
}

class DogMilestoneDisplayService {
  DogMilestoneDisplayService({
    required DogMilestoneStateRepository stateRepository,
  }) : _stateRepository = stateRepository;

  final DogMilestoneStateRepository _stateRepository;

  Future<List<DogMilestoneDisplay>> listForDog(String dogId) async {
    final state = await _stateRepository.getOrCreate(dogId);
    final displays = <DogMilestoneDisplay>[];

    for (final rawKey in state.achievedIds) {
      final def = _lookup(rawKey);
      if (def == null) continue;
      displays.add(
          DogMilestoneDisplay(def: def, achievedAt: state.lastEvaluatedAt));
    }

    displays.sort((a, b) {
      final byOrder = a.def.sortOrder.compareTo(b.def.sortOrder);
      if (byOrder != 0) return byOrder;
      return a.def.title.compareTo(b.def.title);
    });
    return displays;
  }
}
