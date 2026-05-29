import 'package:shared_preferences/shared_preferences.dart';

Future<SharedPreferences> setUpTestPrefs([
  Map<String, Object> values = const <String, Object>{},
]) async {
  SharedPreferences.setMockInitialValues(values);
  return SharedPreferences.getInstance();
}
