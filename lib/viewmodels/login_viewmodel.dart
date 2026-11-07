import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/database_helper.dart';

/// =======================================
/// 🧑‍💼 MODELO SIMPLE DE USUARIO ACTUAL
/// =======================================
class UsuarioActual {
  final int id;
  final int rolId;
  final String rolNombre;
  final String nombreUsuario;
  final String nombres;
  final String apPaterno;
  final String apMaterno;
  final String correo;
  final String estado;
  final String? avatarRuta;

  const UsuarioActual({
    required this.id,
    required this.rolId,
    required this.rolNombre,
    required this.nombreUsuario,
    required this.nombres,
    required this.apPaterno,
    required this.apMaterno,
    required this.correo,
    required this.estado,
    this.avatarRuta,
  });

  /// Nombre corto, útil para saludos: "Juan Pablo Ramirez"
  String get nombreCorto => '$nombres $apPaterno'.trim();

  /// Nombre completo para mostrar en el Drawer, encabezados, etc.
  String get nombreCompleto => '$nombres $apPaterno $apMaterno'.trim();

  /// Texto amigable de rol ("ADMIN", "MAESTRO", "PADRE", "NIÑO")
  String get rolLabel => rolNombre;

  factory UsuarioActual.fromMap(Map<String, Object?> map) {
    return UsuarioActual(
      id: map['id'] as int,
      rolId: map['rol_id'] as int,
      rolNombre: (map['rol_nombre'] as String?) ?? '',
      nombreUsuario: (map['nombre_usuario'] as String?) ?? '',
      nombres: (map['nombres'] as String?) ?? '',
      apPaterno: (map['ap_paterno'] as String?) ?? '',
      apMaterno: (map['ap_materno'] as String?) ?? '',
      correo: (map['correo'] as String?) ?? '',
      estado: (map['estado'] as String?) ?? 'ACTIVO',
      avatarRuta: map['avatar_ruta'] as String?,
    );
  }

  /// 🧩 Útil para pasar a otras capas si algún día lo necesitas como Map
  Map<String, Object?> toMap() => {
        'id': id,
        'rol_id': rolId,
        'rol_nombre': rolNombre,
        'nombre_usuario': nombreUsuario,
        'nombres': nombres,
        'ap_paterno': apPaterno,
        'ap_materno': apMaterno,
        'correo': correo,
        'estado': estado,
        'avatar_ruta': avatarRuta,
      };

  // =====================================
  // 💾 SERIALIZACIÓN PARA PERSISTENCIA
  // =====================================
  Map<String, Object?> toJson() => toMap();

  factory UsuarioActual.fromJson(Map<String, dynamic> json) {
    return UsuarioActual.fromMap(Map<String, Object?>.from(json));
  }
}

/// =======================================
/// 🔐 LOGIN VIEWMODEL — CONECTADO A SQLITE
/// =======================================
class LoginViewModel extends ChangeNotifier {
  // Controladores para el formulario
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  UsuarioActual? _usuarioActual;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UsuarioActual? get usuarioActual => _usuarioActual;

  /// Para mostrar si hay usuario logueado
  bool get isLoggedIn => _usuarioActual != null;

  // 🔑 Clave de SharedPreferences
  static const _kUserKey = 'sesion_usuario';

  /// 🔄 LIMPIAR ERRORES
  void clearError() {
    if (_errorMessage == null) return;
    _errorMessage = null;
    notifyListeners();
  }

  /// =======================================
  /// 🔑 LOGIN CONTRA LA TABLA `usuario` + `rol`
  /// Acepta correo O nombre de usuario como identificador.
  /// =======================================
  Future<bool> login() async {
    final identificador = emailController.text.trim();
    final password = passwordController.text.trim();

    if (identificador.isEmpty || password.isEmpty) {
      _errorMessage = 'Ingrese su correo (o usuario) y contraseña.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 🔎 Reutilizamos el helper del DatabaseHelper
      final row = await DatabaseHelper.instance
          .buscarUsuarioPorCredenciales(
        identificador: identificador,
        contrasena: password,
      );

      if (row == null) {
        _usuarioActual = null;
        _errorMessage =
            'Credenciales incorrectas o el usuario está inactivo.';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      _usuarioActual = UsuarioActual.fromMap(row);

      // 💾 PERSISTIR SESIÓN
      await _guardarSesion(_usuarioActual!);

      _errorMessage = null;
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _usuarioActual = null;
      _errorMessage = 'Error al acceder a la base de datos: $e';
      notifyListeners();
      return false;
    }
  }

  /// =======================================
  /// 💾 GUARDAR SESIÓN EN DISCO
  /// =======================================
  Future<void> _guardarSesion(UsuarioActual user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserKey, jsonEncode(user.toJson()));
  }

  /// =======================================
  /// 🔁 RESTAURAR SESIÓN AL ARRANCAR LA APP
  /// Devuelve true si había una sesión válida guardada.
  /// =======================================
  Future<bool> restaurarSesion() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_kUserKey);
      if (raw == null) return false;

      final json = jsonDecode(raw) as Map<String, dynamic>;
      _usuarioActual = UsuarioActual.fromJson(json);
      notifyListeners();
      return true;
    } catch (_) {
      // Datos corruptos → limpiamos y forzamos login
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_kUserKey);
      _usuarioActual = null;
      notifyListeners();
      return false;
    }
  }

  /// 🚪 LOGOUT
  Future<void> logout() async {
    _usuarioActual = null;
    emailController.clear();
    passwordController.clear();
    _errorMessage = null;

    // 🗑️ Borrar sesión persistida
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUserKey);

    notifyListeners();
  }

  /// 🧹 LIMPIAR RECURSOS
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}