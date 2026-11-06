import 'dart:async';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_live/sqflite_live.dart';

class DatabaseHelper {
  // ==========================================
  // SINGLETON
  // ==========================================
  DatabaseHelper._internal();
  static final DatabaseHelper instance = DatabaseHelper._internal();

  static const String _dbName = 'manual_sistema_web.db';
  static const int _dbVersion = 2;

  static Database? _database;
  static Future<Database>? _opening;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _opening ??= _initDatabase();
    _database = await _opening!;
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    final db = await openDatabase(
      path,
      version: _dbVersion,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onOpen: (db) async {
        await _ensureTables(db);
      },
    );

    // SQFLITE LIVE – SOLO DESARROLLO
    if (!kReleaseMode) {
      try {
        await db.live(port: 8888);
        // ignore: avoid_print
        print('✅ SQFLITE LIVE → http://localhost:8888');
        // ignore: avoid_print
        print('💡 adb reverse tcp:8888 tcp:8888');
      } catch (e) {
        // ignore: avoid_print
        print('⚠️ No se pudo iniciar sqflite_live: $e');
      }
    }

    return db;
  }

  // ==========================================
  // CREACIÓN INICIAL (v1 + v2)
  // ==========================================
  Future<void> _onCreate(Database db, int version) async {
    await _runDDLv1(db);
    await _runDDLv2(db);
    await _seedRoles(db);
    await _seedAdmin(db);
    await _seedEstadisticasIniciales(db);
  }

  // ==========================================
  // MIGRACIONES
  // ==========================================
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _runDDLv2(db);
      await _seedRoles(db); // agrega MAESTRO, PADRE, NIÑO si faltan
      await _seedEstadisticasIniciales(db);
    }
  }

  // ==========================================
  // REFUERZO IDEMPOTENTE
  // ==========================================
  Future<void> _ensureTables(Database db) async {
    await _runDDLv1(db);
    await _runDDLv2(db);
  }

  // ==========================================
  // DDL v1 (INTACTO)
  // ==========================================
  Future<void> _runDDLv1(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS rol (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        nombre      TEXT NOT NULL UNIQUE,
        descripcion TEXT
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS usuario (
        id                  INTEGER PRIMARY KEY AUTOINCREMENT,
        rol_id              INTEGER NOT NULL,
        nombre_usuario      TEXT NOT NULL UNIQUE,
        nombres             TEXT NOT NULL,
        ap_paterno          TEXT,
        ap_materno          TEXT,
        correo              TEXT NOT NULL UNIQUE,
        contrasena          TEXT NOT NULL,
        estado              TEXT NOT NULL DEFAULT 'ACTIVO',
        avatar_ruta         TEXT,
        fecha_creacion      TEXT NOT NULL,
        fecha_actualizacion TEXT NOT NULL,
        FOREIGN KEY (rol_id)
          REFERENCES rol (id)
          ON DELETE RESTRICT
          ON UPDATE CASCADE
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS progreso_usuario (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id  INTEGER NOT NULL,
        paso_id     INTEGER NOT NULL,
        completado  INTEGER NOT NULL DEFAULT 0,
        fecha       TEXT NOT NULL,
        FOREIGN KEY (usuario_id)
          REFERENCES usuario (id)
          ON DELETE CASCADE,
        UNIQUE (usuario_id, paso_id)
      );
    ''');

    await db.execute('''
      CREATE TABLE IF NOT EXISTS favorito (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id  INTEGER NOT NULL,
        paso_id     INTEGER NOT NULL,
        fecha       TEXT NOT NULL,
        FOREIGN KEY (usuario_id)
          REFERENCES usuario (id)
          ON DELETE CASCADE,
        UNIQUE (usuario_id, paso_id)
      );
    ''');
  }

  // ==========================================
  // DDL v2 (NUEVO)
  // ==========================================
  Future<void> _runDDLv2(Database db) async {
    // 5. ESTADÍSTICA GLOBAL POR USUARIO (1:1)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS usuario_estadistica (
        usuario_id           INTEGER PRIMARY KEY,
        total_estrellas      INTEGER NOT NULL DEFAULT 0,
        total_monedas        INTEGER NOT NULL DEFAULT 0,
        eco_nivel            INTEGER NOT NULL DEFAULT 1,
        fecha_actualizacion  TEXT NOT NULL,
        FOREIGN KEY (usuario_id)
          REFERENCES usuario (id)
          ON DELETE CASCADE
      );
    ''');

    // 6. PUNTAJE POR JUEGO
    await db.execute('''
      CREATE TABLE IF NOT EXISTS puntaje_juego (
        id             INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id     INTEGER NOT NULL,
        juego_id       TEXT NOT NULL,
        mejor_puntaje  INTEGER NOT NULL DEFAULT 0,
        ultimo_puntaje INTEGER NOT NULL DEFAULT 0,
        partidas       INTEGER NOT NULL DEFAULT 0,
        fecha_ultima   TEXT NOT NULL,
        FOREIGN KEY (usuario_id)
          REFERENCES usuario (id)
          ON DELETE CASCADE,
        UNIQUE (usuario_id, juego_id)
      );
    ''');

    // 7. INVENTARIO ECO-CRAFT
    await db.execute('''
      CREATE TABLE IF NOT EXISTS inventario_materia (
        id                   INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id           INTEGER NOT NULL,
        materia              TEXT NOT NULL,
        cantidad             INTEGER NOT NULL DEFAULT 0,
        fecha_actualizacion  TEXT NOT NULL,
        FOREIGN KEY (usuario_id)
          REFERENCES usuario (id)
          ON DELETE CASCADE,
        UNIQUE (usuario_id, materia)
      );
    ''');

    // 8. INTENTO DE EVALUACIÓN
    await db.execute('''
      CREATE TABLE IF NOT EXISTS evaluacion_intento (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id       INTEGER NOT NULL,
        evaluacion_ref   TEXT NOT NULL,
        puntuacion       INTEGER NOT NULL,
        total_preguntas  INTEGER NOT NULL,
        porcentaje       REAL NOT NULL,
        fecha            TEXT NOT NULL,
        FOREIGN KEY (usuario_id)
          REFERENCES usuario (id)
          ON DELETE CASCADE
      );
    ''');

    // 9. CONTENIDO VISTO (ECOENCARTA)
    await db.execute('''
      CREATE TABLE IF NOT EXISTS contenido_visto (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id  INTEGER NOT NULL,
        tipo        TEXT NOT NULL,
        ref_id      TEXT NOT NULL,
        fecha       TEXT NOT NULL,
        FOREIGN KEY (usuario_id)
          REFERENCES usuario (id)
          ON DELETE CASCADE,
        UNIQUE (usuario_id, tipo, ref_id)
      );
    ''');

    // 10. TICKET SOPORTE
    await db.execute('''
      CREATE TABLE IF NOT EXISTS ticket_soporte (
        id              INTEGER PRIMARY KEY AUTOINCREMENT,
        usuario_id      INTEGER NOT NULL,
        asunto          TEXT NOT NULL,
        categoria       TEXT,
        descripcion     TEXT NOT NULL,
        estado          TEXT NOT NULL DEFAULT 'ABIERTO',
        fecha_creacion  TEXT NOT NULL,
        fecha_cierre    TEXT,
        FOREIGN KEY (usuario_id)
          REFERENCES usuario (id)
          ON DELETE CASCADE
      );
    ''');

    // 11. VÍNCULO TUTOR / MAESTRO ↔ ALUMNO
    await db.execute('''
      CREATE TABLE IF NOT EXISTS tutor_alumno (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        tutor_id    INTEGER NOT NULL,
        alumno_id   INTEGER NOT NULL,
        parentesco  TEXT,
        fecha       TEXT NOT NULL,
        FOREIGN KEY (tutor_id)
          REFERENCES usuario (id)
          ON DELETE CASCADE,
        FOREIGN KEY (alumno_id)
          REFERENCES usuario (id)
          ON DELETE CASCADE,
        UNIQUE (tutor_id, alumno_id)
      );
    ''');
  }

  // ==========================================
  // SEEDER ROLES (IDEMPOTENTE)
  // ==========================================
  Future<void> _seedRoles(Database db) async {
    const roles = [
      {'nombre': 'ADMIN', 'descripcion': 'Administrador del sistema'},
      {'nombre': 'MAESTRO', 'descripcion': 'Docente que guía a los niños'},
      {'nombre': 'PADRE', 'descripcion': 'Padre/madre/tutor de un niño'},
      {'nombre': 'NIÑO', 'descripcion': 'Usuario infantil de la app'},
    ];

    for (final r in roles) {
      await db.rawInsert(
        'INSERT OR IGNORE INTO rol (nombre, descripcion) VALUES (?, ?)',
        [r['nombre'], r['descripcion']],
      );
    }

    // ignore: avoid_print
    print('✅ Seeder: ROLES verificados (ADMIN, MAESTRO, PADRE, NIÑO).');
  }

  // ==========================================
  // SEEDER ADMIN DEMO (SOLO SI NO HAY USUARIOS)
  // ==========================================
  Future<void> _seedAdmin(Database db) async {
    final result = await db.rawQuery("SELECT COUNT(*) as total FROM usuario");
    final count = (result.first["total"] as int?) ?? 0;
    if (count > 0) return;

    final now = DateTime.now().toIso8601String();

    final rolResult = await db.query(
      'rol',
      where: 'UPPER(nombre) = UPPER(?)',
      whereArgs: ['ADMIN'],
      limit: 1,
    );

    int rolAdminId;
    if (rolResult.isEmpty) {
      rolAdminId = await db.insert('rol', {
        'nombre': 'ADMIN',
        'descripcion': 'Administrador del sistema (auto-creado en seeder)',
      });
    } else {
      rolAdminId = rolResult.first['id'] as int;
    }

    await db.insert("usuario", {
      "rol_id": rolAdminId,
      "nombre_usuario": "admin",
      "nombres": "Juan Pablo",
      "ap_paterno": "Ramirez",
      "ap_materno": "Aguilar",
      "correo": "admin@gmail.com",
      "contrasena": "1234",
      "estado": "ACTIVO",
      "avatar_ruta": null,
      "fecha_creacion": now,
      "fecha_actualizacion": now,
    });

    // ignore: avoid_print
    print("✅ Seeder: ADMIN creado (id=$rolAdminId).");
  }

  // ==========================================
  // SEEDER ESTADÍSTICA INICIAL
  // Crea fila en usuario_estadistica para
  // cada usuario que aún no la tenga.
  // ==========================================
  Future<void> _seedEstadisticasIniciales(Database db) async {
    final now = DateTime.now().toIso8601String();
    await db.rawInsert('''
      INSERT OR IGNORE INTO usuario_estadistica
        (usuario_id, total_estrellas, total_monedas, eco_nivel, fecha_actualizacion)
      SELECT id, 0, 0, 1, ?
      FROM usuario
      WHERE id NOT IN (SELECT usuario_id FROM usuario_estadistica)
    ''', [now]);
  }

  // ==========================================
  // SEEDER INVENTARIO INICIAL (para NIÑOS)
  // ==========================================
  Future<void> _seedInventarioInicial(Database db, int usuarioId) async {
    const inventarioBase = {
      'PET': 20,
      'Tela': 14,
      'Papel': 16,
      'Vidrio': 12,
      'Orgánico': 18,
    };
    final now = DateTime.now().toIso8601String();
    for (final entry in inventarioBase.entries) {
      await db.rawInsert('''
        INSERT OR IGNORE INTO inventario_materia
          (usuario_id, materia, cantidad, fecha_actualizacion)
        VALUES (?, ?, ?, ?)
      ''', [usuarioId, entry.key, entry.value, now]);
    }
  }

  // ==========================================
  // CIERRE
  // ==========================================
  Future<void> close() async {
    final db = _database;
    if (db != null && db.isOpen) {
      await db.close();
      _database = null;
      _opening = null;
    }
  }

  // ==========================================
  // CRUD BAJO NIVEL
  // ==========================================
  Future<List<Map<String, Object?>>> rawQuery(
    String sql, [
    List<Object?>? args,
  ]) async {
    final db = await database;
    return db.rawQuery(sql, args ?? const []);
  }

  Future<int> rawInsert(
    String sql, [
    List<Object?>? args,
  ]) async {
    final db = await database;
    return db.rawInsert(sql, args ?? const []);
  }

  Future<int> rawUpdate(
    String sql, [
    List<Object?>? args,
  ]) async {
    final db = await database;
    return db.rawUpdate(sql, args ?? const []);
  }

  Future<int> rawDelete(
    String sql, [
    List<Object?>? args,
  ]) async {
    final db = await database;
    return db.rawDelete(sql, args ?? const []);
  }

  // ==========================================
  // HELPERS: USUARIO
  // ==========================================
  Future<Map<String, Object?>?> buscarUsuarioPorCredenciales({
    required String identificador, // username o correo
    required String contrasena,
  }) async {
    final rows = await rawQuery('''
      SELECT u.*, r.nombre AS rol_nombre
      FROM usuario u
      JOIN rol r ON r.id = u.rol_id
      WHERE (LOWER(u.nombre_usuario) = LOWER(?) OR LOWER(u.correo) = LOWER(?))
        AND u.contrasena = ?
        AND u.estado = 'ACTIVO'
      LIMIT 1
    ''', [identificador, identificador, contrasena]);
    return rows.isEmpty ? null : rows.first;
  }

  Future<int> crearUsuario({
    required int rolId,
    required String nombreUsuario,
    required String nombres,
    String? apPaterno,
    String? apMaterno,
    required String correo,
    required String contrasena,
    String estado = 'ACTIVO',
    String? avatarRuta,
  }) async {
    final now = DateTime.now().toIso8601String();
    final id = await rawInsert('''
      INSERT INTO usuario
        (rol_id, nombre_usuario, nombres, ap_paterno, ap_materno, correo,
         contrasena, estado, avatar_ruta, fecha_creacion, fecha_actualizacion)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
    ''', [
      rolId, nombreUsuario, nombres, apPaterno, apMaterno, correo,
      contrasena, estado, avatarRuta, now, now,
    ]);

    // Toda cuenta nueva recibe su fila de estadística
    await rawInsert('''
      INSERT OR IGNORE INTO usuario_estadistica
        (usuario_id, total_estrellas, total_monedas, eco_nivel, fecha_actualizacion)
      VALUES (?, 0, 0, 1, ?)
    ''', [id, now]);

    // Si es NIÑO, sembrar inventario
    final rol = await rawQuery(
      'SELECT nombre FROM rol WHERE id = ? LIMIT 1', [rolId]);
    if (rol.isNotEmpty && (rol.first['nombre'] as String?) == 'NIÑO') {
      final db = await database;
      await _seedInventarioInicial(db, id);
    }

    return id;
  }

  // ==========================================
  // HELPERS: ESTADÍSTICA GLOBAL
  // ==========================================
  Future<Map<String, Object?>?> obtenerEstadistica(int usuarioId) async {
    final rows = await rawQuery(
      'SELECT * FROM usuario_estadistica WHERE usuario_id = ? LIMIT 1',
      [usuarioId],
    );
    return rows.isEmpty ? null : rows.first;
  }

  Future<void> sumarEstrellas(int usuarioId, int estrellas) async {
    final now = DateTime.now().toIso8601String();
    await rawUpdate('''
      UPDATE usuario_estadistica
      SET total_estrellas = total_estrellas + ?,
          eco_nivel = ((total_estrellas + ?) / 10) + 1,
          fecha_actualizacion = ?
      WHERE usuario_id = ?
    ''', [estrellas, estrellas, now, usuarioId]);
  }

  Future<void> sumarMonedas(int usuarioId, int monedas) async {
    final now = DateTime.now().toIso8601String();
    await rawUpdate('''
      UPDATE usuario_estadistica
      SET total_monedas = total_monedas + ?,
          fecha_actualizacion = ?
      WHERE usuario_id = ?
    ''', [monedas, now, usuarioId]);
  }

  // ==========================================
  // HELPERS: PUNTAJE JUEGO
  // ==========================================
  Future<List<Map<String, Object?>>> obtenerPuntajesJuego(int usuarioId) async {
    return rawQuery(
      'SELECT * FROM puntaje_juego WHERE usuario_id = ?',
      [usuarioId],
    );
  }

  Future<int> registrarPuntajeJuego({
    required int usuarioId,
    required String juegoId,
    required int puntaje,
  }) async {
    final now = DateTime.now().toIso8601String();
    return rawInsert('''
      INSERT INTO puntaje_juego
        (usuario_id, juego_id, mejor_puntaje, ultimo_puntaje, partidas, fecha_ultima)
      VALUES (?, ?, ?, ?, 1, ?)
      ON CONFLICT(usuario_id, juego_id) DO UPDATE SET
        mejor_puntaje = MAX(puntaje_juego.mejor_puntaje, excluded.mejor_puntaje),
        ultimo_puntaje = excluded.ultimo_puntaje,
        partidas = puntaje_juego.partidas + 1,
        fecha_ultima = excluded.fecha_ultima
    ''', [usuarioId, juegoId, puntaje, puntaje, now]);
  }

  // ==========================================
  // HELPERS: INVENTARIO
  // ==========================================
  Future<List<Map<String, Object?>>> obtenerInventario(int usuarioId) async {
    return rawQuery(
      'SELECT materia, cantidad FROM inventario_materia WHERE usuario_id = ?',
      [usuarioId],
    );
  }

  Future<void> actualizarInventario({
    required int usuarioId,
    required String materia,
    required int delta, // + suma, - resta
  }) async {
    final now = DateTime.now().toIso8601String();
    await rawInsert('''
      INSERT INTO inventario_materia
        (usuario_id, materia, cantidad, fecha_actualizacion)
      VALUES (?, ?, MAX(?, 0), ?)
      ON CONFLICT(usuario_id, materia) DO UPDATE SET
        cantidad = MAX(inventario_materia.cantidad + ?, 0),
        fecha_actualizacion = excluded.fecha_actualizacion
    ''', [usuarioId, materia, delta < 0 ? 0 : delta, now, delta]);
  }

  // ==========================================
  // HELPERS: EVALUACIÓN
  // ==========================================
  Future<int> registrarIntentoEvaluacion({
    required int usuarioId,
    required String evaluacionRef,
    required int puntuacion,
    required int totalPreguntas,
  }) async {
    final now = DateTime.now().toIso8601String();
    final porcentaje = totalPreguntas == 0
        ? 0.0
        : (puntuacion * 100.0) / totalPreguntas;
    return rawInsert('''
      INSERT INTO evaluacion_intento
        (usuario_id, evaluacion_ref, puntuacion, total_preguntas, porcentaje, fecha)
      VALUES (?, ?, ?, ?, ?, ?)
    ''', [
      usuarioId, evaluacionRef, puntuacion, totalPreguntas, porcentaje, now,
    ]);
  }

  Future<List<Map<String, Object?>>> obtenerIntentosEvaluacion(
    int usuarioId, {
    String? evaluacionRef,
  }) async {
    if (evaluacionRef == null) {
      return rawQuery(
        'SELECT * FROM evaluacion_intento WHERE usuario_id = ? ORDER BY fecha DESC',
        [usuarioId],
      );
    }
    return rawQuery(
      'SELECT * FROM evaluacion_intento WHERE usuario_id = ? AND evaluacion_ref = ? ORDER BY fecha DESC',
      [usuarioId, evaluacionRef],
    );
  }

  Future<Map<String, Object?>?> mejorIntentoEvaluacion(
    int usuarioId,
    String evaluacionRef,
  ) async {
    final rows = await rawQuery('''
      SELECT * FROM evaluacion_intento
      WHERE usuario_id = ? AND evaluacion_ref = ?
      ORDER BY puntuacion DESC, fecha ASC
      LIMIT 1
    ''', [usuarioId, evaluacionRef]);
    return rows.isEmpty ? null : rows.first;
  }

  // ==========================================
  // HELPERS: CONTENIDO VISTO
  // ==========================================
  Future<void> marcarContenidoVisto({
    required int usuarioId,
    required String tipo,
    required String refId,
  }) async {
    final now = DateTime.now().toIso8601String();
    await rawInsert('''
      INSERT OR IGNORE INTO contenido_visto (usuario_id, tipo, ref_id, fecha)
      VALUES (?, ?, ?, ?)
    ''', [usuarioId, tipo, refId, now]);
  }

  Future<bool> esContenidoVisto({
    required int usuarioId,
    required String tipo,
    required String refId,
  }) async {
    final rows = await rawQuery('''
      SELECT 1 FROM contenido_visto
      WHERE usuario_id = ? AND tipo = ? AND ref_id = ?
      LIMIT 1
    ''', [usuarioId, tipo, refId]);
    return rows.isNotEmpty;
  }

  // ==========================================
  // HELPERS: TICKET SOPORTE
  // ==========================================
  Future<int> crearTicketSoporte({
    required int usuarioId,
    required String asunto,
    String? categoria,
    required String descripcion,
  }) async {
    final now = DateTime.now().toIso8601String();
    return rawInsert('''
      INSERT INTO ticket_soporte
        (usuario_id, asunto, categoria, descripcion, estado, fecha_creacion)
      VALUES (?, ?, ?, ?, 'ABIERTO', ?)
    ''', [usuarioId, asunto, categoria, descripcion, now]);
  }

  Future<List<Map<String, Object?>>> obtenerTickets(int usuarioId) async {
    return rawQuery(
      'SELECT * FROM ticket_soporte WHERE usuario_id = ? ORDER BY fecha_creacion DESC',
      [usuarioId],
    );
  }

  Future<void> actualizarEstadoTicket(int ticketId, String nuevoEstado) async {
    final now = DateTime.now().toIso8601String();
    await rawUpdate('''
      UPDATE ticket_soporte
      SET estado = ?, fecha_cierre = ?
      WHERE id = ?
    ''', [
      nuevoEstado,
      nuevoEstado == 'CERRADO' ? now : null,
      ticketId,
    ]);
  }

  // ==========================================
  // HELPERS: TUTOR ↔ ALUMNO
  // ==========================================
  Future<int> vincularTutorAlumno({
    required int tutorId,
    required int alumnoId,
    String? parentesco,
  }) async {
    final now = DateTime.now().toIso8601String();
    return rawInsert('''
      INSERT OR IGNORE INTO tutor_alumno (tutor_id, alumno_id, parentesco, fecha)
      VALUES (?, ?, ?, ?)
    ''', [tutorId, alumnoId, parentesco, now]);
  }

  Future<List<Map<String, Object?>>> obtenerAlumnosDeTutor(int tutorId) async {
    return rawQuery('''
      SELECT u.*, t.parentesco
      FROM tutor_alumno t
      JOIN usuario u ON u.id = t.alumno_id
      WHERE t.tutor_id = ?
    ''', [tutorId]);
  }

  Future<List<Map<String, Object?>>> obtenerTutoresDeAlumno(int alumnoId) async {
    return rawQuery('''
      SELECT u.*, t.parentesco
      FROM tutor_alumno t
      JOIN usuario u ON u.id = t.tutor_id
      WHERE t.alumno_id = ?
    ''', [alumnoId]);
  }

  // ==========================================
  // 🔄 RESET (SOLO DESARROLLO)
  // ==========================================
  static Future<void> resetDevDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);
    await deleteDatabase(path);
    _database = null;
    _opening = null;
    await instance.database;
  }
}