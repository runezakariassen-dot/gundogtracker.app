import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:jakthund_app/data/hive_boxes.dart';
import 'package:jakthund_app/domain/domain_bootstrap.dart';
import 'package:jakthund_app/services/hive_lifecycle_service.dart';

void main() {
  late Directory hiveRoot;

  setUp(() async {
    hiveRoot = await Directory.systemTemp.createTemp('media_lifecycle_');
    HiveLifecycleService.resetForTesting();
    registerDomainAdapters();
  });

  tearDown(() async {
    await Hive.close();
    HiveLifecycleService.resetForTesting();
    if (await hiveRoot.exists()) await hiveRoot.delete(recursive: true);
  });

  test('production lifecycle opens HuntEvent media boxes with typed access',
      () async {
    await HiveLifecycleService.init(overridePath: hiveRoot.path);

    expect(HiveLifecycleService.isReady, isTrue);
    expect(Hive.isBoxOpen(dogMediaAssetsBoxName), isTrue);
    expect(Hive.isBoxOpen(huntEventMediaLinksBoxName), isTrue);
    expect(dogMediaAssetsBox().isOpen, isTrue);
    expect(huntEventMediaLinksBox().isOpen, isTrue);
  });
}
