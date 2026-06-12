class BirthdayGreeting {
  static bool isBirthdayToday({
    required DateTime? birthDate,
    required DateTime today,
  }) {
    if (birthDate == null) {
      return false;
    }
    return birthDate.day == today.day && birthDate.month == today.month;
  }

  static bool shouldShow({
    required DateTime? birthDate,
    required DateTime today,
    required DateTime? lastShownDate,
  }) {
    if (!isBirthdayToday(birthDate: birthDate, today: today)) {
      return false;
    }
    if (lastShownDate == null) {
      return true;
    }
    return !_isSameDate(lastShownDate, today);
  }

  static String resolveMessage({
    required String? name,
    required Iterable<String> dogNames,
    required String andWord,
    required String genericMessage,
    required String Function(String name) namedMessage,
    required String Function(String dogs) dogsGenericMessage,
    required String Function(String name, String dogs) dogsNamedMessage,
  }) {
    final trimmedName = name?.trim();
    final hasName = trimmedName != null && trimmedName.isNotEmpty;
    final formattedDogs = formatDogNames(dogNames: dogNames, andWord: andWord);

    if (formattedDogs == null) {
      return hasName ? namedMessage(trimmedName) : genericMessage;
    }

    return hasName
        ? dogsNamedMessage(trimmedName, formattedDogs)
        : dogsGenericMessage(formattedDogs);
  }

  static String? formatDogNames({
    required Iterable<String> dogNames,
    required String andWord,
  }) {
    final names = dogNames
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .toList();
    if (names.isEmpty) {
      return null;
    }
    if (names.length == 1) {
      return names.first;
    }
    if (names.length == 2) {
      return '${names.first} $andWord ${names.last}';
    }
    return '${names.sublist(0, names.length - 1).join(', ')} '
        '$andWord ${names.last}';
  }

  static bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
