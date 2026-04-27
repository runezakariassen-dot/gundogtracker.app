import 'package:flutter/material.dart';

import 'season.dart';

class SeasonColors {
  // Vår - Grønt tema med fuglelyden i bakgrunnen
  static const spring = Color(0xFF2D7D3B);      // Dyp skoggrønn
  static const springLight = Color(0xFF4CAF50);  // Lysere grønn
  static const springAccent = Color(0xFFFFD700); // Gull (sol, fugler som synger)
  
  // Sommer - Varmt gult/gyllent tema
  static const summer = Color(0xFFF57C00);       // Dyp oransje
  static const summerLight = Color(0xFFFF9800);  // Lysere oransje
  static const summerAccent = Color(0xFFFFC107); // Gull (varme, lys)
  
  // Høst - Rustbrunt og mørkt grønt tema
  static const autumn = Color(0xFF8B4513);       // Saddle brown (jaktfarve)
  static const autumnLight = Color(0xFFD2691E);  // Chocolate
  static const autumnAccent = Color(0xFFFF6F00); // Dyp oransje (bladene)
  
  // Vinter - Blågrå og snøitt tema
  static const winter = Color(0xFF37474F);       // Blue grey (snø, is)
  static const winterLight = Color(0xFF546E7A);  // Lysere blue grey
  static const winterAccent = Color(0xFF64B5F6); // Lyseblå (snø refleksjon)
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

Color seasonColorLight(Season season) {
  switch (season) {
    case Season.spring:
      return SeasonColors.springLight;
    case Season.summer:
      return SeasonColors.summerLight;
    case Season.autumn:
      return SeasonColors.autumnLight;
    case Season.winter:
      return SeasonColors.winterLight;
  }
}

Color seasonAccentColor(Season season) {
  switch (season) {
    case Season.spring:
      return SeasonColors.springAccent;
    case Season.summer:
      return SeasonColors.summerAccent;
    case Season.autumn:
      return SeasonColors.autumnAccent;
    case Season.winter:
      return SeasonColors.winterAccent;
  }
}
