import 'package:flutter/material.dart';

enum DashboardModule {
  inicio,
  juegos,
  evaluaciones,
  multimedia,
  soporte,
  gestionUsuarios,
  registroEvaluaciones,
  controlParental,
  reportesAdmin,
  configuracion,
}

class DashboardViewModel extends ChangeNotifier {
  DashboardModule _selected = DashboardModule.inicio;
  String? _rolActual;

  DashboardModule get selected => _selected;
  String? get rolActual => _rolActual;

  /// Compatibilidad con código viejo: devuelve el índice del módulo actual
  /// dentro de la lista de módulos visibles para el rol.
  int get selectedIndex {
    final visibles = modulosVisibles;
    final idx = visibles.indexOf(_selected);
    return idx < 0 ? 0 : idx;
  }

  /// Módulos permitidos según el rol.
  List<DashboardModule> get modulosVisibles {
    switch ((_rolActual ?? '').toUpperCase()) {
      case 'ADMIN':
        return const [
          DashboardModule.inicio,
          DashboardModule.juegos,
          DashboardModule.evaluaciones,
          DashboardModule.multimedia,
          DashboardModule.soporte,
          DashboardModule.gestionUsuarios,
          DashboardModule.registroEvaluaciones,
          DashboardModule.reportesAdmin,
          DashboardModule.configuracion,
        ];
      case 'MAESTRO':
        return const [
          DashboardModule.inicio,
          DashboardModule.juegos,
          DashboardModule.evaluaciones,
          DashboardModule.multimedia,
          DashboardModule.soporte,
          DashboardModule.gestionUsuarios,
          DashboardModule.registroEvaluaciones,
        ];
      case 'PADRE':
        return const [
          DashboardModule.inicio,
          DashboardModule.juegos,
          DashboardModule.evaluaciones,
          DashboardModule.multimedia,
          DashboardModule.soporte,
          DashboardModule.registroEvaluaciones,
          DashboardModule.controlParental,
        ];
      case 'NIÑO':
      default:
        return const [
          DashboardModule.inicio,
          DashboardModule.juegos,
          DashboardModule.evaluaciones,
          DashboardModule.multimedia,
          DashboardModule.soporte,
        ];
    }
  }

  /// Llamar al iniciar sesión / montar el dashboard.
  void configurarPorRol(String? rol) {
    _rolActual = rol;
    _selected = DashboardModule.inicio;
    notifyListeners();
  }

  void changeModule(DashboardModule module) {
    if (!modulosVisibles.contains(module)) return;
    if (_selected == module) return;
    _selected = module;
    notifyListeners();
  }

  /// Compatibilidad con código viejo que llamaba `changeIndex(int)`.
  void changeIndex(int index) {
    final visibles = modulosVisibles;
    if (index < 0 || index >= visibles.length) return;
    changeModule(visibles[index]);
  }

  void restart() {
    _selected = DashboardModule.inicio;
    notifyListeners();
  }
}