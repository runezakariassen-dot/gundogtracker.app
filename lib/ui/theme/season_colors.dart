import 'package:flutter/material.dart';

import 'season.dart';

class SeasonColors {
  static const spring = Color(0xFF9FB8A0);
  static const summer = Color(0xFFD6CFC2);
  static const autumn = Color(0xFFA35A3A);
  static const winter = Color(0xFF6E8796);
}

Color seasonColor(Season season) {
  switch (season) {
    case Season.spring:
      return SeasonColors.spring;
    case Season.summer:
      return SeasonColors.summer;
    case Season.autumn:
      return SeasonColors.autumn;
    case Season.winter:
      return SeasonColors.winter;
  }
}
