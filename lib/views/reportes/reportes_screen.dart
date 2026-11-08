import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/database_helper.dart';
import '../../viewmodels/login_viewmodel.dart';
import '../../utils/constants.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;

  bool _loading = true;
  String? _error;

  _ResumenSistema? _resumen;
  List<_ProgresoNino> _ninos = [];
  Map<String, int> _ticketsPorEstado = {};
  int? _ninoSeleccionadoId;

  @override
  void initState() {
    super.initState();
    _cargarTodo();
  }

  Future<void> _cargarTodo() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final resumen = await _cargarResumen();
      final ninos = await _cargarNinos();
      final tickets = await _cargarTicketsPorEstado();
      if (!mounted) return;
      setState(() {
        _resumen = resumen;
        _ninos = ninos;
        _ticketsPorEstado = tickets;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al cargar reportes: $e';
        _loading = false;
      });
    }
  }

  // ─────────────────────────────────────────
  // 📊 RESUMEN GLOBAL
  // ─────────────────────────────────────────
  Future<_ResumenSistema> _cargarResumen() async {
    final totalUsuarios = await _scalarInt(
      "SELECT COUNT(*) AS c FROM usuario WHERE estado = 'ACTIVO'",
    );
    final totalNinos = await _scalarInt(
      "SELECT COUNT(*) AS c FROM usuario u JOIN rol r ON r.id = u.rol_id "
          "WHERE UPPER(r.nombre) IN ('NIÑO','NINO')",
    );
    final totalMaestros = await _scalarInt(
      "SELECT COUNT(*) AS c FROM usuario u JOIN rol r ON r.id = u.rol_id "
          "WHERE UPPER(r.nombre) IN ('MAESTRO','DOCENTE')",
    );
    final totalPadres = await _scalarInt(
      "SELECT COUNT(*) AS c FROM usuario u JOIN rol r ON r.id = u.rol_id "
          "WHERE UPPER(r.nombre) = 'PADRE'",
    );
    final totalEvaluaciones = await _scalarInt(
      "SELECT COUNT(DISTINCT evaluacion_ref) AS c FROM evaluacion_intento",
    );
    final totalIntentos = await _scalarInt(
      "SELECT COUNT(*) AS c FROM evaluacion_intento",
    );
    final totalJuegos = await _scalarInt(
      "SELECT COALESCE(SUM(partidas), 0) AS c FROM puntaje_juego",
    );
    final totalTicketsAbiertos = await _scalarInt(
      "SELECT COUNT(*) AS c FROM ticket_soporte WHERE estado = 'ABIERTO'",
    );
    final prom = await _db.rawQuery(
      "SELECT COALESCE(AVG(porcentaje), 0) AS p FROM evaluacion_intento",
    );
    final promedio = (prom.first['p'] as num?)?.toDouble() ?? 0.0;

    return _ResumenSistema(
      totalUsuarios: totalUsuarios,
      totalNinos: totalNinos,
      totalMaestros: totalMaestros,
      totalPadres: totalPadres,
      totalEvaluaciones: totalEvaluaciones,
      totalIntentos: totalIntentos,
      totalJuegosJugados: totalJuegos,
      totalTicketsAbiertos: totalTicketsAbiertos,
      promedioGeneralPct: promedio,
    );
  }

  // ─────────────────────────────────────────
  // 👦 PROGRESO POR NIÑO
  // ─────────────────────────────────────────
  Future<List<_ProgresoNino>> _cargarNinos() async {
    final rows = await _db.rawQuery('''
      SELECT
        u.id                AS uid,
        u.nombre_usuario    AS username,
        u.nombres           AS nombres,
        u.ap_paterno        AS ap_paterno,
        u.ap_materno        AS ap_materno,
        u.correo            AS correo,
        COALESCE(e.total_estrellas, 0)  AS estrellas,
        COALESCE(e.total_monedas, 0)    AS monedas,
        COALESCE(e.eco_nivel, 1)        AS eco_nivel,
        (SELECT COUNT(*) FROM evaluacion_intento ei WHERE ei.usuario_id = u.id) AS total_intentos,
        (SELECT COALESCE(AVG(porcentaje),0) FROM evaluacion_intento ei WHERE ei.usuario_id = u.id) AS promedio_pct,
        (SELECT COALESCE(MAX(porcentaje),0) FROM evaluacion_intento ei WHERE ei.usuario_id = u.id) AS mejor_pct,
        (SELECT COUNT(*) FROM puntaje_juego pj WHERE pj.usuario_id = u.id AND pj.partidas > 0) AS juegos_jugados,
        (SELECT COALESCE(MAX(mejor_puntaje),0) FROM puntaje_juego pj WHERE pj.usuario_id = u.id) AS mejor_puntaje,
        (SELECT COUNT(*) FROM contenido_visto cv WHERE cv.usuario_id = u.id) AS contenidos_vistos,
        (SELECT COUNT(*) FROM progreso_usuario pu WHERE pu.usuario_id = u.id AND pu.completado = 1) AS pasos,
        (SELECT COUNT(*) FROM favorito f WHERE f.usuario_id = u.id) AS favoritos,
        (SELECT COUNT(*) FROM ticket_soporte ts WHERE ts.usuario_id = u.id AND ts.estado = 'ABIERTO') AS tickets_abiertos
      FROM usuario u
      JOIN rol r ON r.id = u.rol_id
      LEFT JOIN usuario_estadistica e ON e.usuario_id = u.id
      WHERE UPPER(r.nombre) IN ('NIÑO','NINO')
      ORDER BY estrellas DESC, promedio_pct DESC
    ''');

    return rows.map((r) {
      final nombres = (r['nombres'] as String?) ?? '';
      final apPat = (r['ap_paterno'] as String?) ?? '';
      final apMat = (r['ap_materno'] as String?) ?? '';
      final full = '$nombres $apPat $apMat'.trim();

      return _ProgresoNino(
        usuarioId: r['uid'] as int,
        nombreCompleto: full,
        nombreUsuario: (r['username'] as String?) ?? '',
        correo: (r['correo'] as String?) ?? '',
        estrellas: (r['estrellas'] as num?)?.toInt() ?? 0,
        monedas: (r['monedas'] as num?)?.toInt() ?? 0,
        ecoNivel: (r['eco_nivel'] as num?)?.toInt() ?? 1,
        totalIntentos: (r['total_intentos'] as num?)?.toInt() ?? 0,
        promedioPct: (r['promedio_pct'] as num?)?.toDouble() ?? 0.0,
        mejorPct: (r['mejor_pct'] as num?)?.toDouble() ?? 0.0,
        juegosJugados: (r['juegos_jugados'] as num?)?.toInt() ?? 0,
        mejorPuntajeGlobal: (r['mejor_puntaje'] as num?)?.toInt() ?? 0,
        contenidosVistos: (r['contenidos_vistos'] as num?)?.toInt() ?? 0,
        pasosCompletados: (r['pasos'] as num?)?.toInt() ?? 0,
        favoritos: (r['favoritos'] as num?)?.toInt() ?? 0,
        ticketsAbiertos: (r['tickets_abiertos'] as num?)?.toInt() ?? 0,
      );
    }).toList();
  }

  // ─────────────────────────────────────────
  // 🎫 TICKETS POR ESTADO
  // ─────────────────────────────────────────
  Future<Map<String, int>> _cargarTicketsPorEstado() async {
    final rows = await _db.rawQuery(
      "SELECT estado, COUNT(*) AS c FROM ticket_soporte GROUP BY estado",
    );
    final map = <String, int>{};
    for (final r in rows) {
      map[(r['estado'] as String?) ?? 'DESCONOCIDO'] =
          (r['c'] as num?)?.toInt() ?? 0;
    }
    return map;
  }

  Future<int> _scalarInt(String sql, [List<Object?>? args]) async {
    final rows = await _db.rawQuery(sql, args);
    if (rows.isEmpty) return 0;
    final v = rows.first.values.first;
    return (v as num?)?.toInt() ?? 0;
  }

  // ─────────────────────────────────────────
  // 🖼️ UI
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final usuario = context.watch<LoginViewModel>().usuarioActual;

    return RefreshIndicator(
      onRefresh: _cargarTodo,
      color: AppColors.primary,
      child: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : _buildContenido(usuario),
    );
  }

  Widget _buildError() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        Icon(Icons.error_outline, size: 64, color: AppColors.error),
        const SizedBox(height: 16),
        Text(
          _error!,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(
            color: AppColors.error,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            onPressed: _cargarTodo,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar', style: TextStyle(fontSize: 15)),
          ),
        ),
      ],
    );
  }

  Widget _buildContenido(UsuarioActual? usuario) {
    final resumen = _resumen!;
    final ninos = _ninos;

    final ranking = [...ninos]
      ..sort((a, b) => b.estrellas.compareTo(a.estrellas));

    _ProgresoNino? ninoSel;
    if (_ninoSeleccionadoId != null) {
      for (final n in ninos) {
        if (n.usuarioId == _ninoSeleccionadoId) {
          ninoSel = n;
          break;
        }
      }
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        // ─── Encabezado ───
        if (usuario != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary,
                  AppColors.primary.withOpacity(0.75),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                const Icon(Icons.insights, color: Colors.white, size: 36),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola, ${usuario.nombreCompleto.split(' ').first}',
                        style: AppTextStyles.body.copyWith(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Resumen del avance de tus estudiantes',
                        style: AppTextStyles.body.copyWith(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: _cargarTodo,
                  icon: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 26,
                  ),
                  tooltip: 'Actualizar',
                ),
              ],
            ),
          ),
        const SizedBox(height: 18),

        // ─── KPIs ───
        _SeccionTitulo(
          icono: Icons.dashboard,
          titulo: 'Resumen general',
          subtitulo: 'Métricas globales del sistema',
        ),
        GridView.count(
          crossAxisCount: MediaQuery.of(context).size.width < 600 ? 2 : 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.25,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _KpiCard(
              icono: Icons.child_care,
              label: 'Niños activos',
              valor: '${resumen.totalNinos}',
              color: AppColors.success,
            ),
            _KpiCard(
              icono: Icons.school,
              label: 'Maestros',
              valor: '${resumen.totalMaestros}',
              color: const Color(0xFF1565C0),
            ),
            _KpiCard(
              icono: Icons.family_restroom,
              label: 'Padres/Tutores',
              valor: '${resumen.totalPadres}',
              color: const Color(0xFFEF6C00),
            ),
            _KpiCard(
              icono: Icons.people,
              label: 'Total usuarios',
              valor: '${resumen.totalUsuarios}',
              color: const Color(0xFF6A1B9A),
            ),
            _KpiCard(
              icono: Icons.quiz,
              label: 'Evaluaciones',
              valor: '${resumen.totalEvaluaciones}',
              color: const Color(0xFF0277BD),
            ),
            _KpiCard(
              icono: Icons.assignment_turned_in,
              label: 'Intentos',
              valor: '${resumen.totalIntentos}',
              color: const Color(0xFF00695C),
            ),
            _KpiCard(
              icono: Icons.sports_esports,
              label: 'Partidas jugadas',
              valor: '${resumen.totalJuegosJugados}',
              color: const Color(0xFFF9A825),
            ),
            _KpiCard(
              icono: Icons.support_agent,
              label: 'Tickets abiertos',
              valor: '${resumen.totalTicketsAbiertos}',
              color: AppColors.error,
            ),
          ],
        ),
        const SizedBox(height: 18),

        // ─── Promedio general ───
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child:
                    Icon(Icons.analytics, color: AppColors.primary, size: 32),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Promedio general de evaluaciones',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${resumen.promedioGeneralPct.toStringAsFixed(1)}%',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primary,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 22),

        // ─── Ranking top 5 ───
        _SeccionTitulo(
          icono: Icons.emoji_events,
          titulo: 'Top exploradores',
          subtitulo: 'Ranking por estrellas',
        ),
        if (ranking.isEmpty)
          _vacio('Aún no hay niños registrados')
        else
          Column(
            children: ranking.take(5).toList().asMap().entries.map((entry) {
              final i = entry.key;
              final n = entry.value;
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.textSecondary.withOpacity(0.15),
                  ),
                ),
                child: Row(
                  children: [
                    _medalla(i),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            n.nombreCompleto,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          Text(
                            '@${n.nombreUsuario} · Nv ${n.ecoNivel}',
                            style: AppTextStyles.body.copyWith(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _pill(
                      Icons.star,
                      '${n.estrellas}',
                      const Color(0xFFF9A825),
                    ),
                    const SizedBox(width: 6),
                    _pill(
                      Icons.monetization_on,
                      '${n.monedas}',
                      const Color(0xFF2E7D32),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        const SizedBox(height: 22),

        // ─── Tickets por estado ───
        if (_ticketsPorEstado.isNotEmpty) ...[
          _SeccionTitulo(
            icono: Icons.support_agent,
            titulo: 'Tickets de soporte',
            subtitulo: 'Distribución por estado',
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _ticketsPorEstado.entries.map((e) {
              final color = e.key == 'ABIERTO'
                  ? AppColors.error
                  : (e.key == 'CERRADO'
                      ? AppColors.success
                      : AppColors.primary);
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: color.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.confirmation_number, size: 18, color: color),
                    const SizedBox(width: 6),
                    Text(
                      e.key,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 13.5,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${e.value}',
                        style: AppTextStyles.body.copyWith(
                          fontSize: 12.5,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 22),
        ],

        // ─── Progreso por niño ───
        _SeccionTitulo(
          icono: Icons.trending_up,
          titulo: 'Progreso por niño',
          subtitulo: 'Toca un niño para ver su detalle',
          trailing: _ninoSeleccionadoId != null
              ? TextButton.icon(
                  onPressed: () =>
                      setState(() => _ninoSeleccionadoId = null),
                  icon: const Icon(Icons.close, size: 18),
                  label: const Text(
                    'Cerrar detalle',
                    style: TextStyle(fontSize: 13.5),
                  ),
                )
              : null,
        ),
        if (ninos.isEmpty)
          _vacio('Aún no hay niños registrados')
        else if (ninoSel != null)
          _detalleNino(ninoSel)
        else
          ...ninos.map((n) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _NinoProgresoCard(
                nino: n,
                onTap: () => setState(() => _ninoSeleccionadoId = n.usuarioId),
              ),
            );
          }),
      ],
    );
  }

  // ─────────────────────────────────────────
  // 🔎 DETALLE DE UN NIÑO
  // ─────────────────────────────────────────
  Widget _detalleNino(_ProgresoNino n) {
    final pct = (n.promedioPct / 100).clamp(0.0, 1.0);
    final colorPct = pct >= 0.8
        ? AppColors.success
        : (pct >= 0.5 ? AppColors.primary : AppColors.error);

    Widget fila(String label, String valor, IconData icono) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            Icon(icono, size: 20, color: AppColors.primary),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.body.copyWith(
                  fontSize: 14.5,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            Text(
              valor,
              style: AppTextStyles.body.copyWith(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary.withOpacity(0.15),
                child: Text(
                  n.nombreCompleto.isNotEmpty
                      ? n.nombreCompleto[0].toUpperCase()
                      : '?',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      n.nombreCompleto,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      n.correo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        fontSize: 13.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: colorPct.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(Icons.assessment, color: colorPct, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Promedio: ${n.promedioPct.toStringAsFixed(1)}% '
                    '· Mejor: ${n.mejorPct.toStringAsFixed(1)}%',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 14,
                      color: colorPct,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 10,
              backgroundColor: colorPct.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation(colorPct),
            ),
          ),
          const Divider(height: 26),
          fila('Estrellas', '${n.estrellas}', Icons.star),
          fila('Monedas', '${n.monedas}', Icons.monetization_on),
          fila('Nivel eco', 'Nv ${n.ecoNivel}', Icons.eco),
          fila('Intentos de evaluación', '${n.totalIntentos}', Icons.quiz),
          fila('Juegos jugados', '${n.juegosJugados}', Icons.sports_esports),
          fila(
            'Mejor puntaje (global)',
            '${n.mejorPuntajeGlobal}',
            Icons.emoji_events,
          ),
          fila(
            'Contenidos vistos',
            '${n.contenidosVistos}',
            Icons.perm_media,
          ),
          fila(
            'Pasos completados',
            '${n.pasosCompletados}',
            Icons.check_circle,
          ),
          fila('Favoritos', '${n.favoritos}', Icons.favorite),
          fila('Tickets abiertos', '${n.ticketsAbiertos}', Icons.support_agent),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // 🧩 HELPERS UI
  // ─────────────────────────────────────────
  Widget _vacio(String msg) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
        child: Center(
          child: Text(
            msg,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              fontSize: 14.5,
            ),
          ),
        ),
      );

  Widget _medalla(int index) {
    const colores = [
      Color(0xFFFFD700), // oro
      Color(0xFFC0C0C0), // plata
      Color(0xFFCD7F32), // bronce
    ];
    final color = index < 3 ? colores[index] : AppColors.textSecondary;
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        shape: BoxShape.circle,
        border: Border.all(color: color, width: 1.5),
      ),
      child: Text(
        '${index + 1}',
        style: AppTextStyles.body.copyWith(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Widget _pill(IconData icono, String valor, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 15, color: color),
          const SizedBox(width: 4),
          Text(
            valor,
            style: AppTextStyles.body.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 📦 MODELOS PRIVADOS
// ==========================================
class _ResumenSistema {
  final int totalUsuarios;
  final int totalNinos;
  final int totalMaestros;
  final int totalPadres;
  final int totalEvaluaciones;
  final int totalIntentos;
  final int totalJuegosJugados;
  final int totalTicketsAbiertos;
  final double promedioGeneralPct;

  const _ResumenSistema({
    required this.totalUsuarios,
    required this.totalNinos,
    required this.totalMaestros,
    required this.totalPadres,
    required this.totalEvaluaciones,
    required this.totalIntentos,
    required this.totalJuegosJugados,
    required this.totalTicketsAbiertos,
    required this.promedioGeneralPct,
  });
}

class _ProgresoNino {
  final int usuarioId;
  final String nombreCompleto;
  final String nombreUsuario;
  final String correo;
  final int estrellas;
  final int monedas;
  final int ecoNivel;
  final int totalIntentos;
  final double promedioPct;
  final double mejorPct;
  final int juegosJugados;
  final int mejorPuntajeGlobal;
  final int contenidosVistos;
  final int pasosCompletados;
  final int favoritos;
  final int ticketsAbiertos;

  const _ProgresoNino({
    required this.usuarioId,
    required this.nombreCompleto,
    required this.nombreUsuario,
    required this.correo,
    required this.estrellas,
    required this.monedas,
    required this.ecoNivel,
    required this.totalIntentos,
    required this.promedioPct,
    required this.mejorPct,
    required this.juegosJugados,
    required this.mejorPuntajeGlobal,
    required this.contenidosVistos,
    required this.pasosCompletados,
    required this.favoritos,
    required this.ticketsAbiertos,
  });
}

// ==========================================
// 🧩 WIDGETS PRIVADOS
// ==========================================
class _KpiCard extends StatelessWidget {
  final IconData icono;
  final String label;
  final String valor;
  final Color color;

  const _KpiCard({
    required this.icono,
    required this.label,
    required this.valor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.10),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icono, color: color, size: 22),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            valor,
            style: AppTextStyles.body.copyWith(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SeccionTitulo extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String? subtitulo;
  final Widget? trailing;

  const _SeccionTitulo({
    required this.icono,
    required this.titulo,
    this.subtitulo,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 4, 8),
      child: Row(
        children: [
          Icon(icono, color: AppColors.primary, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  titulo,
                  style: AppTextStyles.body.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (subtitulo != null)
                  Text(
                    subtitulo!,
                    style: AppTextStyles.body.copyWith(
                      fontSize: 13.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _NinoProgresoCard extends StatelessWidget {
  final _ProgresoNino nino;
  final VoidCallback? onTap;

  const _NinoProgresoCard({required this.nino, this.onTap});

  @override
  Widget build(BuildContext context) {
    final pct = (nino.promedioPct / 100).clamp(0.0, 1.0);
    final colorPct = pct >= 0.8
        ? AppColors.success
        : (pct >= 0.5 ? AppColors.primary : AppColors.error);

    Widget chip(IconData icon, String label, Color color) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                fontSize: 12.5,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.textSecondary.withOpacity(0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    child: Text(
                      nino.nombreCompleto.isNotEmpty
                          ? nino.nombreCompleto[0].toUpperCase()
                          : '?',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nino.nombreCompleto,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.body.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '@${nino.nombreUsuario}',
                          style: AppTextStyles.body.copyWith(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  chip(Icons.eco, 'Nv ${nino.ecoNivel}', AppColors.success),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    'Promedio evaluaciones',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${nino.promedioPct.toStringAsFixed(1)}%',
                    style: AppTextStyles.body.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colorPct,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 9,
                  backgroundColor: colorPct.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation(colorPct),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  chip(Icons.star, '${nino.estrellas}',
                      const Color(0xFFF9A825)),
                  chip(Icons.monetization_on, '${nino.monedas}',
                      const Color(0xFF2E7D32)),
                  chip(Icons.sports_esports, '${nino.juegosJugados}',
                      AppColors.primary),
                  chip(Icons.quiz, '${nino.totalIntentos}',
                      const Color(0xFF6A1B9A)),
                  chip(Icons.perm_media, '${nino.contenidosVistos}',
                      const Color(0xFF0277BD)),
                  if (nino.ticketsAbiertos > 0)
                    chip(Icons.support_agent, '${nino.ticketsAbiertos}',
                        AppColors.error),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}