import 'package:flutter/material.dart';

class DashboardViewModel extends ChangeNotifier {
  int _selectedIndex = 0;

  int get selectedIndex => _selectedIndex;

  void changeIndex(int index) {
    if (_selectedIndex == index) return;
    _selectedIndex = index;
    notifyListeners();
  }

  /// 🔄 Reinicia el dashboard al estado inicial.
  /// Se llama justo después del login para que el nuevo usuario
  /// siempre aterrice en la pantalla de inicio (índice 0).
  void restart() {
    _selectedIndex = 0;
    notifyListeners();
  }
}