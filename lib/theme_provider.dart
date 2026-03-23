import 'package:flutter/material.dart';

class ThemeProvider extends ChangeNotifier {
  // පටන් ගනිද්දීම Dark Mode එකේ පටන් ගන්න අපි මෙහෙම දෙමු
  ThemeMode _themeMode = ThemeMode.dark;

  ThemeMode get themeMode => _themeMode;

  // මෙතනින් තමයි මාරු කරන්නේ
  void toggleTheme(bool isDark) {
    _themeMode = isDark ? ThemeMode.dark : ThemeMode.light;
    notifyListeners(); // ඇප් එකේ සේරම පිටුවලට ඒ බව දන්වනවා
  }
}
