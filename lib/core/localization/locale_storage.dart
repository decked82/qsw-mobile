import 'package:shared_preferences/shared_preferences.dart';

class LocaleStorage {
  static const String _localeKey = 'app_locale';

  Future<String?> getSavedLocale() async {
    final preferences = await SharedPreferences.getInstance();
    return preferences.getString(_localeKey);
  }

  Future<void> saveLocale(String languageCode) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_localeKey, languageCode);
  }
}
