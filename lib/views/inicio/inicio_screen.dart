import 'dart:math';
import 'package:flutter/material.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../viewmodels/login_viewmodel.dart';
import '../../utils/constants.dart';
import '../../data/database_helper.dart';

class InicioScreen extends StatefulWidget {
  /// 🧑 Usuario autenticado
  final UsuarioActual? usuario;

  /// 🧭 ViewModel del dashboard (para navegar a otros módulos)
  final DashboardViewModel? dashboardVM;

  const InicioScreen({
    super.key,
    this.usuario,
    this.dashboardVM,
  });

  @override
  State<InicioScreen> createState() => _InicioScreenState();
}

class _InicioScreenState extends State<InicioScreen> {
  // ==========================================
  // 📊 Estado de estadísticas (desde la BD)
  // ==========================================
  int _totalEstrellas = 0;
  int _totalMonedas = 0;
  int _ecoNivel = 1;
  int _mejorPuntajeGlobal = 0;
  int _intentosEvaluacion = 0;
  int _mejorEvaluacionPorcentaje = 0;
  bool _cargando = true;

  @override
  void initState() {
    super.initState();
    _cargarEstadisticas();
  }

  Future<void> _cargarEstadisticas() async {
    final usuario = widget.usuario;

    // 🎲 Números aleatorios menores a 10 mientras no haya BD
    final rnd = Random();
    int r10() => rnd.nextInt(10); // 0..9

    if (usuario == null) {
      if (mounted) {
        setState(() {
          _totalEstrellas = r10();
          _totalMonedas = r10();
          _ecoNivel = 1 + r10();
          _mejorPuntajeGlobal = r10();
          _intentosEvaluacion = r10();
          _mejorEvaluacionPorcentaje = r10();
          _cargando = false;
        });
      }
      return;
    }

    try {
      final db = DatabaseHelper.instance;

      // 📈 Estadística global
      final est = await db.obtenerEstadistica(usuario.id);
      if (est != null) {
        _totalEstrellas = (est['total_estrellas'] as int?) ?? r10();
        _totalMonedas = (est['total_monedas'] as int?) ?? r10();
        _ecoNivel = (est['eco_nivel'] as int?) ?? (1 + r10());
      } else {
        _totalEstrellas = r10();
        _totalMonedas = r10();
        _ecoNivel = 1 + r10();
      }

      // 🎮 Mejor puntaje global de juegos
      final puntajes = await db.obtenerPuntajesJuego(usuario.id);
      int mejor = 0;
      for (final p in puntajes) {
        final m = (p['mejor_puntaje'] as int?) ?? 0;
        if (m > mejor) mejor = m;
      }
      _mejorPuntajeGlobal = mejor == 0 ? r10() : mejor;

      // 📝 Intentos de evaluación
      final intentos = await db.obtenerIntentosEvaluacion(usuario.id);
      _intentosEvaluacion = intentos.isEmpty ? r10() : intentos.length;
      int mejorPct = 0;
      for (final i in intentos) {
        final pct = ((i['porcentaje'] as num?) ?? 0).toInt();
        if (pct > mejorPct) mejorPct = pct;
      }
      _mejorEvaluacionPorcentaje = mejorPct == 0 ? r10() : mejorPct;
    } catch (e) {
      debugPrint('⚠️ Error cargando estadísticas de inicio: $e');
      // fallback aleatorio
      _totalEstrellas = r10();
      _totalMonedas = r10();
      _ecoNivel = 1 + r10();
      _mejorPuntajeGlobal = r10();
      _intentosEvaluacion = r10();
      _mejorEvaluacionPorcentaje = r10();
    }

    if (mounted) {
      setState(() => _cargando = false);
    }
  }

  // ==========================================
  // 🎭 Estilo por rol
  // ==========================================
  _RoleStyle _styleForRole(String? rol) {
    switch ((rol ?? '').toUpperCase()) {
      case 'ADMIN':
        return const _RoleStyle(
          label: 'Administrador',
          icon: Icons.admin_panel_settings,
          gradient: [Color(0xFF6A1B9A), Color(0xFFAB47BC)],
        );
      case 'MAESTRO':
        return const _RoleStyle(
          label: 'Maestro',
          icon: Icons.school,
          gradient: [Color(0xFF1565C0), Color(0xFF42A5F5)],
        );
      case 'PADRE':
        return const _RoleStyle(
          label: 'Padre / Tutor',
          icon: Icons.family_restroom,
          gradient: [Color(0xFFEF6C00), Color(0xFFFFB74D)],
        );
      case 'NIÑO':
        return const _RoleStyle(
          label: 'Explorador Eco',
          icon: Icons.child_care,
          gradient: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
        );
      default:
        return const _RoleStyle(
          label: 'Usuario',
          icon: Icons.person,
          gradient: [Color(0xFF546E7A), Color(0xFF90A4AE)],
        );
    }
  }

  // ==========================================
  // 🧭 Navegación a otros módulos
  // ==========================================
  void _goTo(int index) {
    widget.dashboardVM?.changeIndex(index);
  }

  // ==========================================
  // BUILD
  // ==========================================
  @override
  Widget build(BuildContext context) {
    final style = _styleForRole(widget.usuario?.rolNombre);
    final rol = (widget.usuario?.rolNombre ?? '').toUpperCase();

    return Container(
      color: AppColors.background,
      child: RefreshIndicator(
        onRefresh: _cargarEstadisticas,
        color: AppColors.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.medium),
          children: [
            // 👋 SALUDO
            _buildSaludo(style),
            const SizedBox(height: AppSpacing.medium),

            // 📊 ESTADÍSTICAS
            _buildEstadisticas(),
            const SizedBox(height: AppSpacing.medium),

            // 🎯 ACCESOS DIRECTOS
            _buildAccesosDirectos(rol),
            const SizedBox(height: AppSpacing.medium),

            // 🖼️ CARRUSEL DE IMÁGENES
            _buildCarrusel(),
            const SizedBox(height: AppSpacing.medium),

            // 💡 TIPS
            _buildTips(rol),
            const SizedBox(height: AppSpacing.medium),

            // 📚 INFO DEL PROYECTO
            _buildInfoProyecto(),
            const SizedBox(height: AppSpacing.large),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // 👋 SALUDO
  // ==========================================
  Widget _buildSaludo(_RoleStyle style) {
    final nombre = widget.usuario?.nombres.trim() ?? 'Visitante';
    final apellido = widget.usuario?.apPaterno.trim() ?? '';
    final nombreCorto = apellido.isNotEmpty ? '$nombre $apellido' : nombre;
    final hora = DateTime.now().hour;
    final saludo = hora < 12
        ? '¡Buenos días'
        : hora < 18
            ? '¡Buenas tardes'
            : '¡Buenas noches';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: style.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        boxShadow: [
          BoxShadow(
            color: style.gradient.last.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white.withOpacity(0.25),
            backgroundImage: widget.usuario?.avatarRuta != null
                ? AssetImage(widget.usuario!.avatarRuta!)
                : null,
            child: widget.usuario?.avatarRuta == null
                ? Icon(style.icon, size: 36, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$saludo, $nombreCorto! 👋',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(style.icon, size: 12, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        style.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 📊 ESTADÍSTICAS
  // ==========================================
  Widget _buildEstadisticas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(Icons.insights, 'Tu progreso'),
        const SizedBox(height: AppSpacing.small),
        if (_cargando)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.medium),
              child: CircularProgressIndicator(),
            ),
          )
        else
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            children: [
              _statCard(
                icon: Icons.star,
                color: const Color(0xFFFFB300),
                value: '$_totalEstrellas',
                label: 'Estrellas',
              ),
              _statCard(
                icon: Icons.monetization_on,
                color: const Color(0xFFFF7043),
                value: '$_totalMonedas',
                label: 'Monedas',
              ),
              _statCard(
                icon: Icons.eco,
                color: const Color(0xFF43A047),
                value: 'Nv $_ecoNivel',
                label: 'Nivel Eco',
              ),
              _statCard(
                icon: Icons.emoji_events,
                color: const Color(0xFF7E57C2),
                value: '$_mejorPuntajeGlobal',
                label: 'Mejor puntaje',
              ),
              _statCard(
                icon: Icons.quiz,
                color: const Color(0xFF29B6F6),
                value: '$_intentosEvaluacion',
                label: 'Evaluaciones',
              ),
              _statCard(
                icon: Icons.school,
                color: const Color(0xFFEC407A),
                value: '$_mejorEvaluacionPorcentaje',
                label: 'Mejor nota',
              ),
            ],
          ),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required Color color,
    required String value,
    required String label,
  }) {
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.small,
        vertical: AppSpacing.medium,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 🎯 ACCESOS DIRECTOS
  // ==========================================
  Widget _buildAccesosDirectos(String rol) {
    // ✅ Todos navegan al módulo real del dashboard
    final accesos = <_Acceso>[
      _Acceso(
        icon: Icons.sports_esports,
        color: const Color(0xFF43A047),
        label: 'Juegos',
        descripcion: 'Aprende jugando',
        onTap: () => _goTo(0),
      ),
      _Acceso(
        icon: Icons.quiz,
        color: const Color(0xFF29B6F6),
        label: 'Evaluaciones',
        descripcion: 'Pon a prueba tu saber',
        onTap: () => _goTo(1),
      ),
      _Acceso(
        icon: Icons.perm_media,
        color: const Color(0xFFFFB300),
        label: 'Multimedia',
        descripcion: 'Explora y aprende',
        onTap: () => _goTo(4),
      ),
      _Acceso(
        icon: Icons.support_agent,
        color: const Color(0xFFEF6C00),
        label: 'Soporte',
        descripcion: 'Centro de ayuda',
        onTap: () => _goTo(3),
      ),
    ];

    // 👑 Extras por rol (todos navegan al módulo correspondiente)
    switch (rol) {
      case 'NIÑO':
        accesos.add(
          _Acceso(
            icon: Icons.emoji_events,
            color: const Color(0xFF7E57C2),
            label: 'Mis logros',
            descripcion: 'Estrellas y nivel',
            onTap: _mostrarLogros,
          ),
        );
        break;
      case 'PADRE':
        accesos.add(
          _Acceso(
            icon: Icons.insights,
            color: const Color(0xFF7E57C2),
            label: 'Progreso hijos',
            descripcion: 'Estadísticas',
            onTap: () => _mostrarDialogoProgreso(context),
          ),
        );
        accesos.add(
          _Acceso(
            icon: Icons.message,
            color: const Color(0xFF00897B),
            label: 'Contactar maestro',
            descripcion: 'Mensajería',
            onTap: () => _goTo(3),
          ),
        );
        break;
      case 'MAESTRO':
        accesos.add(
          _Acceso(
            icon: Icons.insights,
            color: const Color(0xFF7E57C2),
            label: 'Progreso clase',
            descripcion: 'Estadísticas',
            onTap: () => _mostrarDialogoProgreso(context),
          ),
        );
        accesos.add(
          _Acceso(
            icon: Icons.assignment,
            color: const Color(0xFF00897B),
            label: 'Asignar retos',
            descripcion: 'Evaluaciones',
            onTap: () => _goTo(1),
          ),
        );
        break;
      case 'ADMIN':
        accesos.add(
          _Acceso(
            icon: Icons.confirmation_number,
            color: const Color(0xFF00897B),
            label: 'Tickets',
            descripcion: 'Reportes abiertos',
            onTap: () => _goTo(3),
          ),
        );
        accesos.add(
          _Acceso(
            icon: Icons.insights,
            color: const Color(0xFF7E57C2),
            label: 'Estadísticas',
            descripcion: 'Uso global',
            onTap: () => _mostrarDialogoProgreso(context),
          ),
        );
        break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(Icons.grid_view, 'Accesos rápidos'),
        const SizedBox(height: AppSpacing.small),
        LayoutBuilder(
          builder: (context, constraints) {
            final cols = constraints.maxWidth < 500
                ? 2
                : constraints.maxWidth < 900
                    ? 3
                    : 4;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: cols,
                crossAxisSpacing: AppSpacing.small,
                mainAxisSpacing: AppSpacing.small,
                childAspectRatio: 1.15,
              ),
              itemCount: accesos.length,
              itemBuilder: (context, i) => _buildAccesoCard(accesos[i]),
            );
          },
        ),
      ],
    );
  }

  Widget _buildAccesoCard(_Acceso a) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppRadius.medium),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.medium),
        onTap: a.onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.small),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: a.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(a.icon, color: a.color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                a.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                a.descripcion,
                maxLines: 2,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 🖼️ CARRUSEL DE IMÁGENES
  // ==========================================
  Widget _buildCarrusel() {
    const items = [
      _CarruselItem(
        url: 'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?w=800',
        titulo: 'Reciclar transforma',
        subtitulo: 'Cada botella puede tener una segunda vida',
      ),
      _CarruselItem(
        url: 'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=800',
        titulo: 'Composta tu mundo',
        subtitulo: 'Los orgánicos alimentan la tierra',
      ),
      _CarruselItem(
        url: 'https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=800',
        titulo: 'Cuida los bosques',
        subtitulo: 'Reciclar papel salva árboles',
      ),
      _CarruselItem(
        url: 'https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?w=800',
        titulo: 'Un planeta limpio',
        subtitulo: 'Pequeñas acciones, grandes cambios',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(Icons.image, 'Aprende con imágenes'),
        const SizedBox(height: AppSpacing.small),
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: PageController(viewportFraction: 0.88),
            itemCount: items.length,
            itemBuilder: (context, i) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: _carruselCard(items[i]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _carruselCard(_CarruselItem item) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.medium),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.network(
            item.url,
            fit: BoxFit.cover,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return Container(
                color: AppColors.primary.withOpacity(0.1),
                child: const Center(child: CircularProgressIndicator()),
              );
            },
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.primary.withOpacity(0.2),
              child: const Icon(
                Icons.image_not_supported,
                size: 48,
                color: Colors.white,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.75),
                ],
              ),
            ),
          ),
          Positioned(
            left: 16,
            right: 16,
            bottom: 16,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.titulo,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitulo,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 💡 TIPS SEGÚN ROL
  // ==========================================
  Widget _buildTips(String rol) {
    final List<_Tip> tips;
    switch (rol) {
      case 'NIÑO':
        tips = const [
          _Tip(
            emoji: '🌟',
            titulo: '¡Gana estrellas!',
            texto:
                'Completa juegos y evaluaciones para subir de nivel eco y desbloquear nuevos retos.',
          ),
          _Tip(
            emoji: '♻️',
            titulo: 'Aprende a separar',
            texto:
                'Verde = orgánico · Azul = papel · Amarillo = plástico · Rojo = especiales.',
          ),
          _Tip(
            emoji: '🕹️',
            titulo: 'Juega sin miedo',
            texto:
                'Puedes reintentar cualquier juego. Lo importante es aprender.',
          ),
        ];
        break;
      case 'PADRE':
        tips = const [
          _Tip(
            emoji: '👀',
            titulo: 'Sigue el progreso',
            texto:
                'Revisa las estadísticas de tus hijos desde el módulo de Progreso.',
          ),
          _Tip(
            emoji: '🏆',
            titulo: 'Celebra los logros',
            texto:
                'Cuando suba de nivel, anímalo. La motivación acelera el aprendizaje.',
          ),
          _Tip(
            emoji: '📚',
            titulo: 'Refuerza en casa',
            texto:
                'Pregúntale qué aprendió hoy en la app. Conversar fija el conocimiento.',
          ),
        ];
        break;
      case 'MAESTRO':
        tips = const [
          _Tip(
            emoji: '📊',
            titulo: 'Monitorea la clase',
            texto:
                'Consulta el progreso de cada alumno vinculado a tu cuenta.',
          ),
          _Tip(
            emoji: '🎯',
            titulo: 'Asigna retos',
            texto:
                'Usa las evaluaciones para reforzar temas vistos en clase.',
          ),
          _Tip(
            emoji: '🌱',
            titulo: 'Fomenta la reflexión',
            texto:
                'Pide a los alumnos que expliquen por qué clasificaron cada residuo como lo hicieron.',
          ),
        ];
        break;
      case 'ADMIN':
        tips = const [
          _Tip(
            emoji: '👥',
            titulo: 'Gestiona usuarios',
            texto:
                'Puedes crear cuentas para maestros, padres y niños desde la base de datos.',
          ),
          _Tip(
            emoji: '🎫',
            titulo: 'Atiende tickets',
            texto:
                'Revisa los reportes de soporte abiertos en el módulo Soporte.',
          ),
          _Tip(
            emoji: '🛠️',
            titulo: 'Mantén la app',
            texto:
                'Verifica que las estadísticas y el contenido estén actualizados.',
          ),
        ];
        break;
      default:
        tips = const [
          _Tip(
            emoji: '🌍',
            titulo: 'Bienvenido',
            texto:
                'Explora los módulos para aprender sobre reciclaje y medio ambiente.',
          ),
        ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(Icons.lightbulb, 'Consejos para ti'),
        const SizedBox(height: AppSpacing.small),
        ...tips.map((t) => _buildTipCard(t)),
      ],
    );
  }

  Widget _buildTipCard(_Tip tip) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.small),
      padding: const EdgeInsets.all(AppSpacing.medium),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.15),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tip.emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: AppSpacing.small),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tip.titulo,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  tip.texto,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 📚 INFO DEL PROYECTO
  // ==========================================
  Widget _buildInfoProyecto() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.large),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withOpacity(0.08),
            AppColors.accent.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.eco, color: AppColors.primary, size: 22),
              const SizedBox(width: 8),
              Text(
                'Sobre Mundo Verde',
                style: AppTextStyles.body.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.small),
          Text(
            'EcoEncarta es una aplicación educativa para aprender sobre '
            'reciclaje y cuidado del medio ambiente. Combina juegos, '
            'evaluaciones y contenido multimedia para que niños, padres y '
            'maestros aprendan juntos.',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,
              fontSize: 12,
              height: 1.5,
            ),
          ),
          const SizedBox(height: AppSpacing.small),
          Wrap(
            spacing: AppSpacing.small,
            runSpacing: AppSpacing.small,
            children: const [
              _ChipInfo(emoji: '🎮', label: '4 juegos educativos'),
              _ChipInfo(emoji: '📝', label: 'Evaluaciones'),
              _ChipInfo(emoji: '📚', label: 'Glosario'),
              _ChipInfo(emoji: '🎬', label: 'Multimedia'),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 🧩 HELPERS UI
  // ==========================================
  Widget _sectionTitle(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: AppTextStyles.heading1.copyWith(
            color: AppColors.textPrimary,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // 👑 DIÁLOGO "MIS LOGROS" (para NIÑO)
  // ==========================================
  void _mostrarLogros() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        title: Row(
          children: const [
            Icon(Icons.emoji_events, color: Color(0xFFFFB300)),
            SizedBox(width: 8),
            Text('Mis logros'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _logroFila(Icons.star, 'Estrellas', '$_totalEstrellas'),
            _logroFila(Icons.monetization_on, 'Monedas', '$_totalMonedas'),
            _logroFila(Icons.eco, 'Nivel Eco', 'Nv $_ecoNivel'),
            _logroFila(Icons.school, 'Mejor nota', '$_mejorEvaluacionPorcentaje'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  Widget _logroFila(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 📈 DIÁLOGO DE PROGRESO (para PADRE/MAESTRO/ADMIN)
  // ==========================================
  void _mostrarDialogoProgreso(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        title: const Text('Progreso detallado'),
        content: Text(
          'Este módulo se integrará próximamente para mostrar el progreso '
          'de los alumnos vinculados a tu cuenta.',
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 📦 MODELOS INTERNOS
// ==========================================
class _RoleStyle {
  final String label;
  final IconData icon;
  final List<Color> gradient;
  const _RoleStyle({
    required this.label,
    required this.icon,
    required this.gradient,
  });
}

class _Acceso {
  final IconData icon;
  final Color color;
  final String label;
  final String descripcion;
  final VoidCallback onTap;
  const _Acceso({
    required this.icon,
    required this.color,
    required this.label,
    required this.descripcion,
    required this.onTap,
  });
}

class _CarruselItem {
  final String url;
  final String titulo;
  final String subtitulo;
  const _CarruselItem({
    required this.url,
    required this.titulo,
    required this.subtitulo,
  });
}

class _Tip {
  final String emoji;
  final String titulo;
  final String texto;
  const _Tip({
    required this.emoji,
    required this.titulo,
    required this.texto,
  });
}

class _ChipInfo extends StatelessWidget {
  final String emoji;
  final String label;
  const _ChipInfo({required this.emoji, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}