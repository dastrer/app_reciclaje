import 'package:flutter/material.dart';

/// ===========================
/// 🎨 COLORES DE LA APP (Eco-Infantil)
/// ===========================
class AppColors {
  static const primary = Color(0xFF2E7D32); // Verde hoja vibrante y principal
  static const secondary = Color(0xFF558B2F); // Verde lima suave / secundario
  static const accent = Color(0xFFFFB300); // Amarillo sol brillante (para destacar y llamar la atención)
  static const background = Color(0xFFF1F8E9); // Verde muy claro, fondo suave y fresco
  static const success = Color(0xFF43A047); // Verde éxito natural
  static const error = Color(0xFFE53935); // Rojo error claro
  static const warning = Color(0xFFFB8C00); // Naranja advertencia amigable
  static const textPrimary = Color(0xFF1B5E20); // Verde muy oscuro para textos principales (alta legibilidad)
  static const textSecondary = Color(0xFF4E342E); // Marrón tierra suave para textos secundarios

  static Color? get backgroundVariant => const Color(0xFFDCEDC8);
}

/// ===========================
/// ✍️ ESTILOS DE TEXTO
/// ===========================
class AppTextStyles {
  static const heading1 = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.primary,
  );

  static const heading2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const body = TextStyle(fontSize: 16, color: AppColors.textSecondary);

  static const button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );
}

/// ===========================
/// 📏 ESPACIADOS Y RADIOS
/// ===========================
class AppSpacing {
  static const small = 8.0;
  static const medium = 16.0;
  static const large = 24.0;
}

class AppRadius {
  static const small = 8.0;
  static const medium = 16.0;
  static const large = 24.0;
}

/// ===========================
/// 🖼️ ASSETS / ICONOS
/// ===========================
class AppAssets {
  static const logo = "assets/logo.png";
  static const userPlaceholder = "assets/images/user.png";
}

/// ===========================
/// 🔑 STRINGS COMUNES
/// ===========================
class AppStrings {
  static const appName = "EcoKids App";
  static const login = "Iniciar Sesión";
  static const logout = "Cerrar Sesión";
  static const dashboard = "Mundo Verde";
}

/// ===========================
/// 👤 ROLES DE USUARIO
/// ===========================
class UserRoles {
  static const administrador = 'Administrador';
  static const estudiante = 'EcoAmigo'; // Ajustado a un término más lúdico e infantil
  static const futuroEstudiante = 'NuevoExplorador';
}

/// ===========================
/// 📌 ESTADOS
/// ===========================
class Estados {
  static const activo = 'Activo';
  static const inactivo = 'Inactivo';
  static const pendiente = 'Pendiente';
  static const aprobado = 'Aprobado';
  static const rechazado = 'Rechazado';
  static const inscrito = 'Inscrito';
  static const cancelado = 'Cancelado';
}

/// ===========================
/// 📚 TIPOS DE ACTIVIDAD
/// ===========================
class TiposActividad {
  static const seminario = 'Aventura';
  static const taller = 'Taller Verde';
  static const curso = 'Misión Ecológica';
}

/// ===========================
/// 🗄️ COLECCIONES FIRESTORE
/// ===========================
class Collections {
  static const usuarios = 'usuarios';
  static const docentes = 'guias'; // Cambiado de docentes a guías ambientales
  static const actividades = 'actividades';
  static const seminarios = 'seminarios';
  static const postulaciones = 'postulaciones';
  static const inscripciones = 'inscripciones';
  static const mensajes = 'mensajes';
  static const programasEstudio = 'programas_estudio';
  static const ofertasAcademicas = 'ofertas_academicas';
  static const notificaciones = 'notificaciones';
}

/// ===========================
/// 💬 MENSAJES COMUNES
/// ===========================
class Messages {
  static const loginError = '¡Ups! Usuario o contraseña incorrectos';
  static const campoRequerido = '¡Este campo es necesario!';
  static const correoInvalido = 'Correo electrónico no válido';
  static const passwordCorta = 'La contraseña debe tener al menos 6 caracteres';
}