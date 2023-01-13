import 'package:shared_preferences/shared_preferences.dart';

abstract class AppOptionsProvider {
  bool containsKey(String key);

  T? get<T>(String key);

  T? getOrNull<T>(String key);

  Future<bool> set(String key, Object value);

  Set<String> getKeys();

  Future<bool> remove(String key);
}

class SharedPreferencesOptionsProvider extends AppOptionsProvider {
  final SharedPreferences sharedPreferences;

  SharedPreferencesOptionsProvider(this.sharedPreferences);

  @override
  bool containsKey(String key) => sharedPreferences.containsKey(key);

  @override
  Future<bool> set(String key, Object value) {
    if (value is String) {
      return sharedPreferences.setString(key, value);
    }

    if (value is bool) {
      return sharedPreferences.setBool(key, value);
    }

    if (value is double) {
      return sharedPreferences.setDouble(key, value);
    }

    if (value is int) {
      return sharedPreferences.setInt(key, value);
    }

    if (value is num) {
      return sharedPreferences.setDouble(key, value.toDouble());
    }

    if (value is List<String>) {
      return sharedPreferences.setStringList(key, value);
    }

    return sharedPreferences.setString(key, value.toString());
  }

  @override
  T? get<T>(String key) {
    return sharedPreferences.get(key) as T?;
  }

  @override
  T? getOrNull<T>(String key) {
    if (containsKey(key)) {
      var val = sharedPreferences.get(key);

      if (val is T) {
        return val;
      } else {
        return null;
      }
    }

    return null;
  }

  @override
  Set<String> getKeys() => sharedPreferences.getKeys();

  @override
  Future<bool> remove(String key) => sharedPreferences.remove(key);
}
