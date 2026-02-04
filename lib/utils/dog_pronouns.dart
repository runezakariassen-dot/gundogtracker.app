import '../models/dog_sex.dart';

class DogPronouns {
  static String subject(DogSex sex) {
    return sex == DogSex.male ? 'han' : 'hun';
  }

  static String object(DogSex sex) {
    return sex == DogSex.male ? 'ham' : 'henne';
  }

  static String possessive(DogSex sex) {
    return sex == DogSex.male ? 'hans' : 'hennes';
  }
}
