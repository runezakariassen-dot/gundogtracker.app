import 'package:hive/hive.dart';

import '../../data/hive_boxes.dart';
import 'season.dart';

class SeasonThemeController {
  SeasonThemeController(this.settingsBox);

  final Box<dynamic> settingsBox;

  Season getResolvedSeason(DateTime now) {
    final value =
        settingsBox.get(themeSeasonOverrideKey, defaultValue: 'auto') as String;
    switch (value) {
      case 'spring':
        return Season.spring;
      case 'summer':
        return Season.summer;
      case 'autumn':
        return Season.autumn;
      case 'winter':
        return Season.winter;
      default:
        return SeasonX.fromDate(now);
    }
  }

  Future<void> setOverride(String value) async {
    await settingsBox.put(themeSeasonOverrideKey, value);
  }

  String getOverride() {
    return settingsBox.get(themeSeasonOverrideKey, defaultValue: 'auto')
        as String;
  }
}
