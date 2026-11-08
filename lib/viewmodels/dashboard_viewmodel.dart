import 'package:flutter/material.dart';

enum DashboardModule {
  inicio,
  juegos,
  evaluaciones,
  multimedia,
  soporte,
  gestionUsuarios,
  registroEvaluaciones,
  seguimientoEvaluaciones, // NUEVO (para PADRE)
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

  /// Normaliza el rol: mayúsculas + sin acentos + sin espacios.
  /// Así "Niño", "NIÑO", "nino " y "NINO" caen en la misma rama.
  String _normalizarRol(String? rol) {
    if (rol == null) return '';
    const conAcento = 'ÁÉÍÓÚÜÑ';
    const sinAcento = 'AEIOUUN';
    var out = rol.toUpperCase();
    for (var i = 0; i < conAcento.length; i++) {
      out = out.replaceAll(conAcento[i], sinAcento[i]);
    }
    return out.trim();
  }

  /// Módulos permitidos según el rol (en el orden en que se muestran).
  List<DashboardModule> get modulosVisibles {
    switch (_normalizarRol(_rolActual)) {
      // ─────────────────────────────────────────
      // ADMIN y DOCENTE/MAESTRO comparten módulos
      // ─────────────────────────────────────────
      case 'ADMIN':
      case 'DOCENTE':
      case 'MAESTRO':
        return const [
          DashboardModule.reportesAdmin,
          DashboardModule.gestionUsuarios,
          DashboardModule.multimedia,
          DashboardModule.juegos,
          DashboardModule.inicio,
          DashboardModule.evaluaciones,
          DashboardModule.soporte,
          DashboardModule.registroEvaluaciones,
          DashboardModule.configuracion,
        ];

      // ─────────────────────────────────────────
      // PADRE
      // ─────────────────────────────────────────
      case 'PADRE':
        return const [
          DashboardModule.seguimientoEvaluaciones,
          DashboardModule.multimedia,
          DashboardModule.inicio,
          DashboardModule.soporte,
          DashboardModule.controlParental,
        ];

      // ─────────────────────────────────────────
      // NIÑO (con o sin tilde)
      // ─────────────────────────────────────────
      case 'NIÑO':
      case 'NINO':
        return const [
          DashboardModule.multimedia,
          DashboardModule.juegos,
          DashboardModule.inicio,
          DashboardModule.evaluaciones,
          DashboardModule.soporte,
        ];

      default:
        return const [DashboardModule.inicio];
    }
  }

  /// Llamar al iniciar sesión / montar el dashboard.
  void configurarPorRol(String? rol) {
    _rolActual = rol;
    // Si el módulo actual ya no es visible para el nuevo rol, resetea a inicio.
    if (!modulosVisibles.contains(_selected)) {
      _selected = DashboardModule.inicio;
    }
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