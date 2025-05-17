import 'package:hive/hive.dart';

part 'user.g.dart';

@HiveType(typeId: 0)
class User extends HiveObject {
  @HiveField(0)
  final String name;

  @HiveField(1)
  final List<double> array;

  @HiveField(2)
  final String imageBase64;

  User({
    required this.name,
    required this.array,
    required this.imageBase64,
  });
}
