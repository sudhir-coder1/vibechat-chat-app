import 'package:shared_preferences/shared_preferences.dart';

Future<String?> getPreferences(String key) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.getString(key);
}
Future<dynamic> removePreferences(String key) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return prefs.remove(key);
}

Future<void> setPreferences(String key,String value) async {
  SharedPreferences pref = await SharedPreferences.getInstance();
  await pref.setString(key, value);
}

