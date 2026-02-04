enum Season { spring, summer, autumn, winter }

extension SeasonX on Season {
  static Season fromDate(DateTime date) {
    final m = date.month;
    if (m >= 3 && m <= 5) return Season.spring;
    if (m >= 6 && m <= 8) return Season.summer;
    if (m >= 9 && m <= 11) return Season.autumn;
    return Season.winter;
  }
}
