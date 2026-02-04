enum SessionType { training, hunting }

SessionType sessionTypeFromString(String? value) {
  return SessionType.values.firstWhere(
    (type) => type.name == value,
    orElse: () => SessionType.training,
  );
}
