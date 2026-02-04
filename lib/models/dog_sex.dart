import 'package:hive/hive.dart';

part 'dog_sex.g.dart';

@HiveType(typeId: 222)
enum DogSex {
  @HiveField(0)
  male,

  @HiveField(1)
  female,
}
