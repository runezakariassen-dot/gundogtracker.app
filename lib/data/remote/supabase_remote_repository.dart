import 'supabase_remote_data_source.dart';
import 'sync_contracts.dart';

class SupabaseRemoteRepository {
  SupabaseRemoteRepository({required SupabaseRemoteDataSource dataSource})
      : _dataSource = dataSource;

  final SupabaseRemoteDataSource _dataSource;

  Future<List<RemoteDogWithRole>> listAccessibleDogs() async {
    return _dataSource.listAccessibleDogs();
  }

  Future<PullDogDeltaResponse> pullDogDelta({
    required String dogId,
    required DateTime since,
  }) async {
    return _dataSource.pullDogDelta(dogId: dogId, since: since);
  }

  Future<void> pushBatch({
    required List<RemoteChange> changes,
    required String clientId,
  }) async {
    return _dataSource.pushBatch(changes: changes, clientId: clientId);
  }

  Future<void> acceptInvite(String token) async {
    return _dataSource.acceptInvite(token);
  }

  Future<void> acceptTransfer(String token) async {
    return _dataSource.acceptTransfer(token);
  }
}
