import '../milestones/milestone_catalog.dart';
import '../milestones/milestone_models.dart';
import '../repositories/dog_milestone_state_repository.dart';

class DogMilestoneDisplay {
  const DogMilestoneDisplay({
    required this.id,
    required this.def,
    required this.achievedAt,
  });

  final String id;
  final MilestoneDef def;

  /// Hvis vi ikke lagrer per-milepæl dato enda, er denne null.
  /// (MilestoneListSection håndterer null fint.)
  final DateTime? achievedAt;
}

class DogMilestoneDisplayService {
  DogMilestoneDisplayService({
    required DogMilestoneStateRepository stateRepository,
  }) : _stateRepository = stateRepository;

  final DogMilestoneStateRepository _stateRepository;

  Future<List<DogMilestoneDisplay>> listForDog(String dogId) async {
    final state = await _stateRepository.getOrCreate(dogId);

    // Defs finnes i catalog + “century” (points_100, 200, ...)
    final displays = <DogMilestoneDisplay>[];
    for (final id in state.achievedIds) {
      final def = milestoneDefById(id);
      final achievedAt = state.achievedAt[id];
      if (def == null || achievedAt == null) continue;

      displays.add(
        DogMilestoneDisplay(
          id: id,
          def: def,
          achievedAt: achievedAt,
        ),
      );
    }

    // Stabil sortering (brukes også i UI)
    displays.sort((a, b) {
      final byOrder = a.def.sortOrder.compareTo(b.def.sortOrder);
      if (byOrder != 0) return byOrder;
      return a.def.title.compareTo(b.def.title);
    });

    return displays;
  }
}
