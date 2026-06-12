class PersonalStandGoalCelebration {
  static String resolveMessage({
    required String? name,
    required String genericMessage,
    required String Function(String name) namedMessage,
  }) {
    final trimmedName = name?.trim();
    if (trimmedName == null || trimmedName.isEmpty) {
      return genericMessage;
    }
    return namedMessage(trimmedName);
  }
}
