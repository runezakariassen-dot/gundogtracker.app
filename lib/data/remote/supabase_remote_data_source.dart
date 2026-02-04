import 'sync_contracts.dart';

class SupabaseRemoteDataSource {
  SupabaseRemoteDataSource();

  Future<List<RemoteDogWithRole>> listAccessibleDogs() async {
    // TODO(supabase): call RPC and parse via RemoteDogWithRole.fromJson.
    throw UnimplementedError('Remote sync disabled');
  }

  Future<PullDogDeltaResponse> pullDogDelta({
    required String dogId,
    required DateTime since,
  }) async {
    final data = await _callRpc('pull_dog_delta', {
      'p_dog_id': dogId,
      'p_since': since.toIso8601String(),
    });
    return PullDogDeltaResponse.fromJson(data);
  }

  Future<void> pushBatch({
    required List<RemoteChange> changes,
    required String clientId,
  }) async {
    // TODO(supabase): implement push_batch RPC once sync engine is ready.
    throw UnimplementedError('Remote sync disabled');
  }

  Future<void> acceptInvite(String token) async {
    throw UnimplementedError('Remote sync disabled');
  }

  Future<void> acceptTransfer(String token) async {
    throw UnimplementedError('Remote sync disabled');
  }

  Future<Map<String, dynamic>> _callRpc(
    String name,
    Map<String, dynamic> params,
  ) async {
    // TODO(supabase): implement RPC call via Supabase client wrapper.
    throw UnimplementedError('Remote sync disabled');
  }
}
