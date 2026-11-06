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
    await _seedDemoUsuarios(db);
  }

  // ==========================================
  // MIGRACIONES
  // ==========================================
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _runDDLv2(db);
      await _seedRoles(db); // agrega MAESTRO, PADRE, NIÑO si faltan
      await _seedEstadisticasIniciales(db);
      await _seedDemoUsuarios(db);
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
      "nombres": "Ruth Carina",
      "ap_paterno": "Jimenez",
      "ap_materno": "Huaypara",
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
  // HELPERS INTERNOS PARA SEEDERS
  // ==========================================
  Future<int?> _getRolId(Database db, String nombreRol) async {
    final rows = await db.query(
      'rol',
      columns: ['id'],
      where: 'UPPER(nombre) = UPPER(?)',
      whereArgs: [nombreRol],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['id'] as int;
  }

  Future<int?> _getUsuarioIdByUsername(Database db, String username) async {
    final rows = await db.query(
      'usuario',
      columns: ['id'],
      where: 'LOWER(nombre_usuario) = LOWER(?)',
      whereArgs: [username],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['id'] as int;
  }

  Future<int?> _getUsuarioIdByCorreo(Database db, String correo) async {
    final rows = await db.query(
      'usuario',
      columns: ['id'],
      where: 'LOWER(correo) = LOWER(?)',
      whereArgs: [correo],
      limit: 1,
    );
    return rows.isEmpty ? null : rows.first['id'] as int;
  }

  // ==========================================
  // SEEDER DEMO: USUARIOS (MAESTROS, PADRES, NIÑOS)
  // Idempotente: no duplica si ya existen.
  // ==========================================
  Future<void> _seedDemoUsuarios(Database db) async {
    final rolMaestroId = await _getRolId(db, 'MAESTRO');
    final rolPadreId = await _getRolId(db, 'PADRE');
    final rolNinoId = await _getRolId(db, 'NIÑO');

    if (rolMaestroId == null || rolPadreId == null || rolNinoId == null) {
      // ignore: avoid_print
      print('⚠️ Seeder demo: faltan roles, se omite.');
      return;
    }

    final now = DateTime.now().toIso8601String();

    // ---- Datos de maestros ----
    final maestros = [
      {
        'username': 'maestro_ana',
        'nombres': 'Ana María',
        'ap_paterno': 'López',
        'ap_materno': 'García',
        'correo': 'ana.lopez@escuela.com',
        'contrasena': '1234',
      },
      {
        'username': 'maestro_carlos',
        'nombres': 'Carlos',
        'ap_paterno': 'Hernández',
        'ap_materno': 'Ruiz',
        'correo': 'carlos.hernandez@escuela.com',
        'contrasena': '1234',
      },
    ];

    // ---- Datos de padres ----
    final padres = [
      {
        'username': 'padre_maria',
        'nombres': 'María Fernanda',
        'ap_paterno': 'Torres',
        'ap_materno': 'Silva',
        'correo': 'maria.torres@gmail.com',
        'contrasena': '1234',
      },
      {
        'username': 'padre_jose',
        'nombres': 'José Luis',
        'ap_paterno': 'Ramírez',
        'ap_materno': 'Castro',
        'correo': 'jose.ramirez@gmail.com',
        'contrasena': '1234',
      },
      {
        'username': 'padre_lucia',
        'nombres': 'Lucía',
        'ap_paterno': 'Mendoza',
        'ap_materno': 'Vargas',
        'correo': 'lucia.mendoza@gmail.com',
        'contrasena': '1234',
      },
    ];

    // ---- Datos de niños ----
    final ninos = [
      {
        'username': 'nino_diego',
        'nombres': 'Diego',
        'ap_paterno': 'Torres',
        'ap_materno': 'Silva',
        'correo': 'diego.torres@kids.com',
        'contrasena': '1234',
      },
      {
        'username': 'nino_sofia',
        'nombres': 'Sofía',
        'ap_paterno': 'Ramírez',
        'ap_materno': 'Castro',
        'correo': 'sofia.ramirez@kids.com',
        'contrasena': '1234',
      },
      {
        'username': 'nino_mateo',
        'nombres': 'Mateo',
        'ap_paterno': 'Mendoza',
        'ap_materno': 'Vargas',
        'correo': 'mateo.mendoza@kids.com',
        'contrasena': '1234',
      },
      {
        'username': 'nino_valentina',
        'nombres': 'Valentina',
        'ap_paterno': 'López',
        'ap_materno': 'García',
        'correo': 'valentina.lopez@kids.com',
        'contrasena': '1234',
      },
    ];

    // Insertar maestros
    final maestroIds = <String, int>{};
    for (final m in maestros) {
      final existente = await _getUsuarioIdByUsername(db, m['username']!);
      if (existente != null) {
        maestroIds[m['username']!] = existente;
        continue;
      }
      final id = await db.insert('usuario', {
        'rol_id': rolMaestroId,
        'nombre_usuario': m['username'],
        'nombres': m['nombres'],
        'ap_paterno': m['ap_paterno'],
        'ap_materno': m['ap_materno'],
        'correo': m['correo'],
        'contrasena': m['contrasena'],
        'estado': 'ACTIVO',
        'avatar_ruta': null,
        'fecha_creacion': now,
        'fecha_actualizacion': now,
      });
      maestroIds[m['username']!] = id;
      await db.rawInsert('''
        INSERT OR IGNORE INTO usuario_estadistica
          (usuario_id, total_estrellas, total_monedas, eco_nivel, fecha_actualizacion)
        VALUES (?, 0, 0, 1, ?)
      ''', [id, now]);
    }

    // Insertar padres
    final padreIds = <String, int>{};
    for (final p in padres) {
      final existente = await _getUsuarioIdByUsername(db, p['username']!);
      if (existente != null) {
        padreIds[p['username']!] = existente;
        continue;
      }
      final id = await db.insert('usuario', {
        'rol_id': rolPadreId,
        'nombre_usuario': p['username'],
        'nombres': p['nombres'],
        'ap_paterno': p['ap_paterno'],
        'ap_materno': p['ap_materno'],
        'correo': p['correo'],
        'contrasena': p['contrasena'],
        'estado': 'ACTIVO',
        'avatar_ruta': null,
        'fecha_creacion': now,
        'fecha_actualizacion': now,
      });
      padreIds[p['username']!] = id;
      await db.rawInsert('''
        INSERT OR IGNORE INTO usuario_estadistica
          (usuario_id, total_estrellas, total_monedas, eco_nivel, fecha_actualizacion)
        VALUES (?, 0, 0, 1, ?)
      ''', [id, now]);
    }

    // Insertar niños
    final ninoIds = <String, int>{};
    for (final n in ninos) {
      final existente = await _getUsuarioIdByUsername(db, n['username']!);
      if (existente != null) {
        ninoIds[n['username']!] = existente;
        continue;
      }
      final id = await db.insert('usuario', {
        'rol_id': rolNinoId,
        'nombre_usuario': n['username'],
        'nombres': n['nombres'],
        'ap_paterno': n['ap_paterno'],
        'ap_materno': n['ap_materno'],
        'correo': n['correo'],
        'contrasena': n['contrasena'],
        'estado': 'ACTIVO',
        'avatar_ruta': null,
        'fecha_creacion': now,
        'fecha_actualizacion': now,
      });
      ninoIds[n['username']!] = id;
      await db.rawInsert('''
        INSERT OR IGNORE INTO usuario_estadistica
          (usuario_id, total_estrellas, total_monedas, eco_nivel, fecha_actualizacion)
        VALUES (?, 0, 0, 1, ?)
      ''', [id, now]);
      await _seedInventarioInicial(db, id);
    }

    // ---- VINCULOS TUTOR ↔ ALUMNO ----
    // padre_maria → nino_diego
    // padre_jose → nino_sofia
    // padre_lucia → nino_mateo
    // maestro_ana → todos (guía)
    // maestro_carlos → nino_valentina
    final vinculos = [
      {'tutor': 'padre_maria', 'alumno': 'nino_diego', 'parentesco': 'Madre'},
      {'tutor': 'padre_jose', 'alumno': 'nino_sofia', 'parentesco': 'Padre'},
      {'tutor': 'padre_lucia', 'alumno': 'nino_mateo', 'parentesco': 'Madre'},
      {'tutor': 'maestro_ana', 'alumno': 'nino_diego', 'parentesco': 'Maestra'},
      {'tutor': 'maestro_ana', 'alumno': 'nino_sofia', 'parentesco': 'Maestra'},
      {'tutor': 'maestro_ana', 'alumno': 'nino_mateo', 'parentesco': 'Maestra'},
      {'tutor': 'maestro_carlos', 'alumno': 'nino_valentina', 'parentesco': 'Maestro'},
    ];

    for (final v in vinculos) {
      final tutorId = padreIds[v['tutor']] ?? maestroIds[v['tutor']];
      final alumnoId = ninoIds[v['alumno']];
      if (tutorId == null || alumnoId == null) continue;
      await db.rawInsert('''
        INSERT OR IGNORE INTO tutor_alumno (tutor_id, alumno_id, parentesco, fecha)
        VALUES (?, ?, ?, ?)
      ''', [tutorId, alumnoId, v['parentesco'], now]);
    }

    // ---- ESTADÍSTICAS DEMO PARA NIÑOS ----
    final statsNinos = {
      'nino_diego': {'estrellas': 45, 'monedas': 120, 'eco_nivel': 5},
      'nino_sofia': {'estrellas': 32, 'monedas': 80, 'eco_nivel': 4},
      'nino_mateo': {'estrellas': 18, 'monedas': 45, 'eco_nivel': 2},
      'nino_valentina': {'estrellas': 60, 'monedas': 150, 'eco_nivel': 7},
    };
    for (final entry in statsNinos.entries) {
      final uid = ninoIds[entry.key];
      if (uid == null) continue;
      await db.rawUpdate('''
        UPDATE usuario_estadistica
        SET total_estrellas = ?, total_monedas = ?, eco_nivel = ?, fecha_actualizacion = ?
        WHERE usuario_id = ?
      ''', [
        entry.value['estrellas'],
        entry.value['monedas'],
        entry.value['eco_nivel'],
        now,
        uid,
      ]);
    }

    // ---- PUNTAJES DE JUEGO DEMO ----
    const juegos = ['reciclaje', 'memoria', 'clasificacion', 'eco_craft'];
    final puntajesDemo = <String, List<Map<String, int>>>{
      'nino_diego': [
        {'mejor': 850, 'ultimo': 720, 'partidas': 12},
        {'mejor': 640, 'ultimo': 580, 'partidas': 9},
        {'mejor': 910, 'ultimo': 890, 'partidas': 15},
        {'mejor': 300, 'ultimo': 250, 'partidas': 4},
      ],
      'nino_sofia': [
        {'mejor': 700, 'ultimo': 650, 'partidas': 8},
        {'mejor': 520, 'ultimo': 500, 'partidas': 6},
        {'mejor': 780, 'ultimo': 750, 'partidas': 10},
        {'mejor': 180, 'ultimo': 150, 'partidas': 2},
      ],
      'nino_mateo': [
        {'mejor': 400, 'ultimo': 380, 'partidas': 4},
        {'mejor': 350, 'ultimo': 340, 'partidas': 3},
        {'mejor': 420, 'ultimo': 400, 'partidas': 5},
        {'mejor': 90, 'ultimo': 80, 'partidas': 1},
      ],
      'nino_valentina': [
        {'mejor': 980, 'ultimo': 950, 'partidas': 20},
        {'mejor': 880, 'ultimo': 860, 'partidas': 18},
        {'mejor': 990, 'ultimo': 970, 'partidas': 22},
        {'mejor': 450, 'ultimo': 420, 'partidas': 7},
      ],
    };

    for (final entry in puntajesDemo.entries) {
      final uid = ninoIds[entry.key];
      if (uid == null) continue;
      for (var i = 0; i < juegos.length; i++) {
        final data = entry.value[i];
        await db.rawInsert('''
          INSERT OR IGNORE INTO puntaje_juego
            (usuario_id, juego_id, mejor_puntaje, ultimo_puntaje, partidas, fecha_ultima)
          VALUES (?, ?, ?, ?, ?, ?)
        ''', [
          uid, juegos[i], data['mejor'], data['ultimo'], data['partidas'], now,
        ]);
      }
    }

    // ---- INVENTARIO EXTRA DEMO ----
    final inventarioExtra = {
      'nino_diego': {'PET': 35, 'Tela': 22, 'Papel': 28, 'Vidrio': 18, 'Orgánico': 30},
      'nino_sofia': {'PET': 18, 'Tela': 12, 'Papel': 20, 'Vidrio': 10, 'Orgánico': 15},
      'nino_mateo': {'PET': 8, 'Tela': 6, 'Papel': 10, 'Vidrio': 5, 'Orgánico': 9},
      'nino_valentina': {'PET': 50, 'Tela': 40, 'Papel': 45, 'Vidrio': 30, 'Orgánico': 48},
    };
    for (final entry in inventarioExtra.entries) {
      final uid = ninoIds[entry.key];
      if (uid == null) continue;
      for (final mat in entry.value.entries) {
        await db.rawUpdate('''
          UPDATE inventario_materia
          SET cantidad = ?, fecha_actualizacion = ?
          WHERE usuario_id = ? AND materia = ?
        ''', [mat.value, now, uid, mat.key]);
      }
    }

    // ---- EVALUACIONES DEMO ----
    final evaluacionesDemo = [
      {'nino': 'nino_diego', 'ref': 'eval_basico_1', 'punt': 8, 'total': 10},
      {'nino': 'nino_diego', 'ref': 'eval_basico_2', 'punt': 9, 'total': 10},
      {'nino': 'nino_sofia', 'ref': 'eval_basico_1', 'punt': 7, 'total': 10},
      {'nino': 'nino_mateo', 'ref': 'eval_basico_1', 'punt': 5, 'total': 10},
      {'nino': 'nino_valentina', 'ref': 'eval_basico_1', 'punt': 10, 'total': 10},
      {'nino': 'nino_valentina', 'ref': 'eval_basico_2', 'punt': 9, 'total': 10},
    ];
    for (final e in evaluacionesDemo) {
      final uid = ninoIds[e['nino']];
      if (uid == null) continue;
      final punt = e['punt'] as int;
      final total = e['total'] as int;
      final pct = (punt * 100.0) / total;
      await db.insert('evaluacion_intento', {
        'usuario_id': uid,
        'evaluacion_ref': e['ref'],
        'puntuacion': punt,
        'total_preguntas': total,
        'porcentaje': pct,
        'fecha': now,
      });
    }

    // ---- CONTENIDO VISTO DEMO ----
    final contenidoDemo = [
      {'nino': 'nino_diego', 'tipo': 'video', 'ref': 'vid_reciclaje_1'},
      {'nino': 'nino_diego', 'tipo': 'articulo', 'ref': 'art_planeta'},
      {'nino': 'nino_sofia', 'tipo': 'video', 'ref': 'vid_reciclaje_1'},
      {'nino': 'nino_valentina', 'tipo': 'video', 'ref': 'vid_reciclaje_1'},
      {'nino': 'nino_valentina', 'tipo': 'articulo', 'ref': 'art_planeta'},
      {'nino': 'nino_valentina', 'tipo': 'juego', 'ref': 'eco_craft'},
    ];
    for (final c in contenidoDemo) {
      final uid = ninoIds[c['nino']];
      if (uid == null) continue;
      await db.rawInsert('''
        INSERT OR IGNORE INTO contenido_visto (usuario_id, tipo, ref_id, fecha)
        VALUES (?, ?, ?, ?)
      ''', [uid, c['tipo'], c['ref'], now]);
    }

    // ---- TICKETS SOPORTE DEMO ----
    final ticketsDemo = [
      {
        'nino': 'nino_diego',
        'asunto': 'No puedo iniciar el juego de reciclaje',
        'categoria': 'JUEGO',
        'descripcion': 'Al presionar el botón de jugar la pantalla se queda en blanco.',
        'estado': 'ABIERTO',
      },
      {
        'nino': 'nino_sofia',
        'asunto': 'Duda sobre mi inventario',
        'categoria': 'INVENTARIO',
        'descripcion': 'Creo que perdí materiales después de la última actualización.',
        'estado': 'ABIERTO',
      },
      {
        'nino': 'nino_valentina',
        'asunto': 'Solicitud de nuevo avatar',
        'categoria': 'CUENTA',
        'descripcion': 'Quisiera poder cambiar mi avatar desde el perfil.',
        'estado': 'CERRADO',
      },
    ];
    for (final t in ticketsDemo) {
      final uid = ninoIds[t['nino']];
      if (uid == null) continue;
      await db.insert('ticket_soporte', {
        'usuario_id': uid,
        'asunto': t['asunto'],
        'categoria': t['categoria'],
        'descripcion': t['descripcion'],
        'estado': t['estado'],
        'fecha_creacion': now,
        'fecha_cierre': t['estado'] == 'CERRADO' ? now : null,
      });
    }

    // ---- PROGRESO Y FAVORITOS DEMO ----
    final progresoDemo = [
      {'nino': 'nino_diego', 'paso': 1},
      {'nino': 'nino_diego', 'paso': 2},
      {'nino': 'nino_diego', 'paso': 3},
      {'nino': 'nino_sofia', 'paso': 1},
      {'nino': 'nino_sofia', 'paso': 2},
      {'nino': 'nino_valentina', 'paso': 1},
      {'nino': 'nino_valentina', 'paso': 2},
      {'nino': 'nino_valentina', 'paso': 3},
      {'nino': 'nino_valentina', 'paso': 4},
    ];
    for (final p in progresoDemo) {
      final uid = ninoIds[p['nino']];
      if (uid == null) continue;
      await db.rawInsert('''
        INSERT OR IGNORE INTO progreso_usuario (usuario_id, paso_id, completado, fecha)
        VALUES (?, ?, 1, ?)
      ''', [uid, p['paso'], now]);
    }

    final favoritosDemo = [
      {'nino': 'nino_diego', 'paso': 1},
      {'nino': 'nino_diego', 'paso': 3},
      {'nino': 'nino_sofia', 'paso': 2},
      {'nino': 'nino_valentina', 'paso': 1},
      {'nino': 'nino_valentina', 'paso': 4},
    ];
    for (final f in favoritosDemo) {
      final uid = ninoIds[f['nino']];
      if (uid == null) continue;
      await db.rawInsert('''
        INSERT OR IGNORE INTO favorito (usuario_id, paso_id, fecha)
        VALUES (?, ?, ?)
      ''', [uid, f['paso'], now]);
    }

    // ignore: avoid_print
    print('✅ Seeder demo: MAESTROS, PADRES y NIÑOS insertados con datos de prueba.');
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