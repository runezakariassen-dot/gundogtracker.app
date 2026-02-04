import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/domain/milestones/milestone_id.dart';
import 'package:jakthund_app/domain/repositories/dog_milestone_state_repository.dart';
import 'package:jakthund_app/domain/services/dog_milestone_display_service.dart';
import 'package:jakthund_app/models/dog_milestone_state.dart';
import 'package:jakthund_app/models/hunt_session.dart';

class FakeDogMilestoneStateRepository implements DogMilestoneStateRepository {
  FakeDogMilestoneStateRepository({DogMilestoneState? initialState})
      : _state = initialState;

  DogMilestoneState? _state;

  @override
  Future<BackfillResult> backfillFromSessionHistory({
    required Iterable<String> dogIds,
    Box<HuntSession>? sessions,
  }) async {
    return BackfillResult(
      dogsProcessed: dogIds.length,
      sessionsProcessed: 0,
    );
  }

  @override
  Future<DogMilestoneState> getOrCreate(String dogId) async {
    _state ??= DogMilestoneState(dogId: dogId);
    return _state!;
  }

  @override
  Future<void> save(DogMilestoneState state) async {
    _state = state;
  }

  @override
  Future<void> delete(String dogId) async {
    if (_state?.dogId == dogId) {
      _state = null;
    }
  }
}

void main() {
  test('DogMilestoneDisplayService sorts by catalog order', () async {
    final state = DogMilestoneState(
      dogId: 'dog-1',
      achievedIds: [
        MilestoneId.sessions10,
        MilestoneId.stands1,
        MilestoneId.sessions25,
      ],
      lastEvaluatedAt: DateTime(2024, 1, 1),
      achievedAt: {
        MilestoneId.sessions10: DateTime(2024, 2, 1),
        MilestoneId.stands1: DateTime(2024, 1, 1),
        MilestoneId.sessions25: DateTime(2024, 3, 1),
      },
    );
    final repo = FakeDogMilestoneStateRepository(initialState: state);
    final service = DogMilestoneDisplayService(stateRepository: repo);

    final displays = await service.listForDog('dog-1');
    final sortOrders = displays.map((d) => d.def.sortOrder).toList();

    expect(
        displays.map((d) => d.def.id),
        containsAll([
          MilestoneId.stands1,
          MilestoneId.sessions10,
          MilestoneId.sessions25,
        ]));
    expect(
        sortOrders,
        equals(sortOrders
          ..toList()
          ..sort()));
    final stands1 =
        displays.firstWhere((display) => display.id == MilestoneId.stands1);
    expect(
      stands1.achievedAt,
      equals(state.achievedAt[MilestoneId.stands1]),
    );
  });
}
