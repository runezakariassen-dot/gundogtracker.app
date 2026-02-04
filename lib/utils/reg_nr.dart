final RegExp _regNrRegex = RegExp(r'^NO\d{1,6}[/-]\d{2}$');

String normalizeRegNr(String input) {
  final trimmed = input.trim().toUpperCase();
  final replaced = trimmed.replaceAll('/', '-').replaceAll(' ', '');
  return replaced;
}

bool validateRegNr(String input) {
  return _regNrRegex.hasMatch(normalizeRegNr(input));
}
