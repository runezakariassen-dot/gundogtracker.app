import 'package:flutter_map_tile_caching/flutter_map_tile_caching.dart';

import '../map_tile_sources.dart';

class TileCacheService {
  static bool _backendReady = false;
  static final Map<String, FMTCTileProvider> _providers = {};

  static Future<void> ensureBackendReady() async {
    if (_backendReady) return;
    try {
      await FMTCObjectBoxBackend().initialise();
    } on RootAlreadyInitialised {
      // Already initialised elsewhere (e.g. app startup).
    }
    _backendReady = true;
  }

  static FMTCStore storeFor(MapTileSource source) {
    return FMTCStore(source.storeName);
  }

  static Future<void> ensureStoreReady(MapTileSource source) async {
    await ensureBackendReady();
    final store = storeFor(source);
    final ready = await store.manage.ready;
    if (!ready) {
      await store.manage.create();
    }
  }

  static Future<void> ensureStoreReadyByName(String storeName) async {
    await ensureBackendReady();
    final store = FMTCStore(storeName);
    final ready = await store.manage.ready;
    if (!ready) {
      await store.manage.create();
    }
  }

  static FMTCTileProvider tileProviderFor(
    MapTileSource source, {
    List<String> extraStores = const [],
  }) {
    final stores = <String, BrowseStoreStrategy?>{
      source.storeName: BrowseStoreStrategy.readUpdateCreate,
    };
    final sorted = List<String>.from(extraStores)..sort();
    for (final store in sorted) {
      if (store == source.storeName) continue;
      stores[store] = BrowseStoreStrategy.read;
    }
    return _providers.putIfAbsent(
      '${source.storeName}:${sorted.join(",")}',
      () => FMTCTileProvider(
        stores: stores,
      ),
    );
  }

  static Future<void> resetStore(MapTileSource source) async {
    await ensureBackendReady();
    final store = storeFor(source);
    final ready = await store.manage.ready;
    if (!ready) return;
    await store.manage.reset();
  }
}
