import 'package:shared_preferences/shared_preferences.dart';

Future<void> saveTempKey(Map<String, String> keyMap) async {
  final prefs = await SharedPreferences.getInstance();
  for (var entry in keyMap.entries) {
    await prefs.setString(entry.key, entry.value);
  }
}

Future<String?> getTempKey(String key) async {
  final prefs = await SharedPreferences.getInstance();
  return prefs.getString(key);
}

Future<void> removeTempKey(String key) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.remove(key);
}
