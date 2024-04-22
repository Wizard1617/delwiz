import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeData _themeData;

  ThemeProvider(this._themeData) {
    loadTheme();
  }

  ThemeData getTheme() => _themeData;

  void setTheme(ThemeData themeData) {
    _themeData = themeData;
    notifyListeners();
    saveTheme(themeData.brightness == Brightness.dark);
  }

  void setLightTheme() {
    _themeData = ThemeData.light();
    notifyListeners();
    saveTheme(false);
  }

  void setDarkTheme() {
    _themeData = ThemeData.dark();
    notifyListeners();
    saveTheme(true);
  }

  Future<void> saveTheme(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', isDarkMode);
  }

  Future<void> loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    bool isDarkMode = prefs.getBool('darkMode') ?? false;
    _themeData = isDarkMode ? ThemeData.dark() : ThemeData.light();
    notifyListeners();
  }
}
