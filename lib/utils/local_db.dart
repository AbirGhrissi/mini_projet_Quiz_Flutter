import 'package:hive/hive.dart';
import 'package:mini_projet/utils/utils.dart';
import '../model/user.dart';

class LocalDB {
  static late Box<User> _userBox;
  static late Box _metaBox;
  static late Box<List> _quizHistoryBox;

  static const String _userBoxName = 'usersBox';
  static const String _metaBoxName = 'metaBox';
  static const String _currentUserKey = 'current_user';
  static const String _quizHistoryBoxName = 'quizHistoryBox';

  static Future<void> init() async {
    printIfDebug('Initializing Hive ..********');
    _userBox = await Hive.openBox<User>(_userBoxName);
    _metaBox = await Hive.openBox(_metaBoxName); // boîte non typée pour stocker des données génériques comme des String
    _quizHistoryBox = await Hive.openBox<List>(_quizHistoryBoxName);
    printIfDebug('Hive initialized successfully **********');
    printIfDebug('Current user key: ${_metaBox.get(_currentUserKey)}');
    printIfDebug('Users in DB: ${_userBox.keys.join(', ')}');
  }

  static Future<void> saveUser(User user) async {
    try {
      printIfDebug('Saving user: ${user.name}');
      await _userBox.put(user.name, user);
      await _metaBox.put(_currentUserKey, user.name);
      await _userBox.flush();
      await _metaBox.flush();
      printIfDebug('User saved and set as current user');
      printIfDebug('Current user is now: ${_metaBox.get(_currentUserKey)}');
    } catch (e) {
      printIfDebug('Error saving user: $e');
      rethrow;
    }
  }

  static User? getCurrentUser() {
    final currentName = _metaBox.get(_currentUserKey);
    if (currentName != null && currentName is String) {
      final user = _userBox.get(currentName);
      if (user != null) {
        return user;
      } else {
        // Option 1 : ignorer la suppression
        return null;

        // Option 2 : marquer une suppression à faire plus tard
        // on pourrait ajouter un flag, ou logguer un message
      }
    }
    return null;
  }

  static List<User> getAllUsers() {
    final users = <User>[];
    for (var key in _userBox.keys) {
      final user = _userBox.get(key);
      if (user is User) {
        users.add(user);
      }
    }
    return users;
  }

  static Future<void> logoutUser() async {
    await _metaBox.delete(_currentUserKey);
  }

  static Future<void> deleteUser(String name) async {
    await _userBox.delete(name);
  }

  static Future<void> deleteAllUsers() async {
    await _userBox.clear();
    await _metaBox.clear();
  }

  static bool isUserExists(String name) {
    return _userBox.containsKey(name);
  }
 }
