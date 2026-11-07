import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../viewmodels/login_viewmodel.dart'; // ⬅️ UsuarioActual
import '../../utils/constants.dart';

// 🔌 Imports de los módulos
import '../juegos/juegos_screen.dart';
import '../evaluaciones/evaluaciones_screen.dart';
import '../inicio/inicio_screen.dart';
import '../soporte/soporte_screen.dart';
import '../multimedia/multimedia_screen.dart';

class DashboardScreen extends StatefulWidget {
  /// 🧑 Usuario autenticado
  final UsuarioActual? usuario;

  /// 🔓 Callback para que el árbol superior (Root) gestione la sesión
  final VoidCallback? onLogout;

  const DashboardScreen({
    super.key,
    this.usuario,
    this.onLogout,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  /// Controlador para centrar el botón Inicio al abrir en mobile.
  final ScrollController _mobileNavScrollController = ScrollController();
  final GlobalKey _inicioKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context
          .read<DashboardViewModel>()
          .configurarPorRol(widget.usuario?.rolNombre);
      _centrarInicioMobile();
    });
  }

  @override
  void dispose() {
    _mobileNavScrollController.dispose();
    super.dispose();
  }

  void _centrarInicioMobile() {
    if (!_mobileNavScrollController.hasClients) return;
    final ctx = _inicioKey.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.5,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  // ==========================================
  // 🗺️ MAPA INTERNO: enum → { label, icon, builder }
  // ==========================================
  Map<DashboardModule, _ModuleConfig> _buildModules(DashboardViewModel vm) {
    return {
      DashboardModule.inicio: _ModuleConfig(
        label: 'Inicio',
        icon: Icons.home,
        builder: (_) => InicioScreen(
          usuario: widget.usuario,
          dashboardVM: vm,
        ),
      ),
      DashboardModule.juegos: const _ModuleConfig(
        label: 'Juegos',
        icon: Icons.sports_esports,
        builder: _buildJuegos,
      ),
      DashboardModule.evaluaciones: const _ModuleConfig(
        label: 'Evaluaciones',
        icon: Icons.quiz,
        builder: _buildEvaluaciones,
      ),
      DashboardModule.multimedia: const _ModuleConfig(
        label: 'Multimedia',
        icon: Icons.perm_media,
        builder: _buildMultimedia,
      ),
      DashboardModule.soporte: const _ModuleConfig(
        label: 'Soporte',
        icon: Icons.support_agent,
        builder: _buildSoporte,
      ),
      DashboardModule.gestionUsuarios: const _ModuleConfig(
        label: 'Gestión de Usuarios',
        icon: Icons.manage_accounts,
        builder: _buildPlaceholderGestionUsuarios,
      ),
      DashboardModule.registroEvaluaciones: const _ModuleConfig(
        label: 'Registro de Evaluaciones',
        icon: Icons.assignment_add,
        builder: _buildPlaceholderRegistroEval,
      ),
      DashboardModule.controlParental: const _ModuleConfig(
        label: 'Control Parental',
        icon: Icons.shield,
        builder: _buildPlaceholderControlParental,
      ),
      DashboardModule.reportesAdmin: const _ModuleConfig(
        label: 'Reportes',
        icon: Icons.insights,
        builder: _buildPlaceholderReportes,
      ),
      DashboardModule.configuracion: const _ModuleConfig(
        label: 'Configuración',
        icon: Icons.settings,
        builder: _buildPlaceholderConfiguracion,
      ),
    };
  }

  // Builders estáticos para poder marcar _ModuleConfig como const
  static Widget _buildJuegos(BuildContext _) => const JuegosScreen();
  static Widget _buildEvaluaciones(BuildContext _) => const EvaluacionesScreen();
  static Widget _buildMultimedia(BuildContext _) => const EcoEncartaScreen();
  static Widget _buildSoporte(BuildContext _) => const SoporteScreen();
  static Widget _buildPlaceholderGestionUsuarios(BuildContext _) =>
      const _PlaceholderScreen(title: 'Gestión de Usuarios');
  static Widget _buildPlaceholderRegistroEval(BuildContext _) =>
      const _PlaceholderScreen(title: 'Registro de Evaluaciones');
  static Widget _buildPlaceholderControlParental(BuildContext _) =>
      const _PlaceholderScreen(title: 'Control Parental');
  static Widget _buildPlaceholderReportes(BuildContext _) =>
      const _PlaceholderScreen(title: 'Reportes');
  static Widget _buildPlaceholderConfiguracion(BuildContext _) =>
      const _PlaceholderScreen(title: 'Configuración');

  @override
  Widget build(BuildContext context) {
    final dashboardVM = context.watch<DashboardViewModel>();
    final modules = _buildModules(dashboardVM);
    final visibles = dashboardVM.modulosVisibles;
    final current = dashboardVM.selected;
    final currentConfig = modules[current]!;

    return Scaffold(
      // ==========================================
      // 🏷️ APPBAR: marca + módulo actual
      // ==========================================
      appBar: AppBar(
        centerTitle: true,
        elevation: 4,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        title: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Mundo Verde',
              style: AppTextStyles.body.copyWith(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
            Text(
              currentConfig.label,
              style: AppTextStyles.body.copyWith(
                color: Colors.white70,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
      drawer: _buildDrawer(context, dashboardVM, modules, visibles),
      body: modules[current]!.builder(context),
      bottomNavigationBar: _buildResponsiveBottomNavigationBar(
        dashboardVM,
        modules,
        visibles,
        context,
      ),
    );
  }

  // ==========================================
  // 🎭 IDENTIDAD VISUAL POR ROL
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
  // 🧩 HELPERS DE PRESENTACIÓN
  // ==========================================
  String _nombreCompleto() =>
      widget.usuario?.nombreCompleto ?? 'Usuario Ejemplo';

  String _correo() =>
      widget.usuario?.correo ?? 'usuario@correo.com';

  String? _avatarRuta() => widget.usuario?.avatarRuta;

  String? _rolNombre() => widget.usuario?.rolNombre;

  // ==========================================
  // 🖼️ DRAWER
  // ==========================================
  Drawer _buildDrawer(
    BuildContext context,
    DashboardViewModel dashboardVM,
    Map<DashboardModule, _ModuleConfig> modules,
    List<DashboardModule> visibles,
  ) {
    final style = _styleForRole(_rolNombre());
    final avatarRuta = _avatarRuta();

    return Drawer(
      child: Column(
        children: [
          UserAccountsDrawerHeader(
            margin: EdgeInsets.zero,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: style.gradient,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            accountName: Text(
              _nombreCompleto(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            accountEmail: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _correo(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
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
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            currentAccountPicture: CircleAvatar(
              radius: 32,
              backgroundColor: Colors.white.withOpacity(0.25),
              backgroundImage:
                  avatarRuta != null ? AssetImage(avatarRuta) : null,
              child: avatarRuta == null
                  ? Icon(style.icon, size: 36, color: Colors.white)
                  : null,
            ),
          ),
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: visibles.map((m) {
                final cfg = modules[m]!;
                final isSelected = dashboardVM.selected == m;
                return ListTile(
                  leading: Icon(
                    cfg.icon,
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                  ),
                  title: Text(
                    cfg.label,
                    style: AppTextStyles.body.copyWith(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                  selected: isSelected,
                  selectedTileColor: AppColors.primary.withOpacity(0.1),
                  onTap: () {
                    dashboardVM.changeModule(m);
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1, color: AppColors.textSecondary),
          ListTile(
            leading: const Icon(Icons.logout, color: AppColors.error),
            title: Text(
              AppStrings.logout,
              style: AppTextStyles.body.copyWith(color: AppColors.error),
            ),
            onTap: () {
              Navigator.pop(context);
              widget.onLogout?.call();
            },
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 📱 BOTTOM NAV RESPONSIVO (Inicio al centro + arrastrable)
  // ==========================================
  Widget _buildResponsiveBottomNavigationBar(
    DashboardViewModel dashboardVM,
    Map<DashboardModule, _ModuleConfig> modules,
    List<DashboardModule> visibles,
    BuildContext context,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 600) {
      return _buildMobileNavBar(dashboardVM, modules, visibles);
    } else if (screenWidth < 1200) {
      return _buildTabletOrDesktopNavBar(
        dashboardVM,
        modules,
        visibles,
        tablet: true,
      );
    } else {
      return _buildTabletOrDesktopNavBar(
        dashboardVM,
        modules,
        visibles,
        desktop: true,
      );
    }
  }

  // ─────────────────────────────────────────────
  // MOBILE: ListView horizontal con Inicio centrado
  // ─────────────────────────────────────────────
  Widget _buildMobileNavBar(
    DashboardViewModel dashboardVM,
    Map<DashboardModule, _ModuleConfig> modules,
    List<DashboardModule> visibles,
  ) {
    final sinInicio =
        visibles.where((m) => m != DashboardModule.inicio).toList();

    final izquierda = <DashboardModule>[];
    final derecha = <DashboardModule>[];
    for (var i = 0; i < sinInicio.length; i++) {
      if (i.isEven) {
        izquierda.add(sinInicio[i]);
      } else {
        derecha.add(sinInicio[i]);
      }
    }

    final orden = <DashboardModule>[
      ...izquierda.reversed,
      DashboardModule.inicio,
      ...derecha,
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 78,
          child: ListView(
            controller: _mobileNavScrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            children: orden.map((m) {
              final isInicio = m == DashboardModule.inicio;
              final item = _navItem(
                m,
                modules[m]!,
                dashboardVM,
                mobile: true,
              );
              return isInicio
                  ? KeyedSubtree(key: _inicioKey, child: item)
                  : item;
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TABLET / DESKTOP: Inicio fijo al centro
  // ─────────────────────────────────────────────
  Widget _buildTabletOrDesktopNavBar(
    DashboardViewModel dashboardVM,
    Map<DashboardModule, _ModuleConfig> modules,
    List<DashboardModule> visibles, {
    bool tablet = false,
    bool desktop = false,
  }) {
    final double height = tablet ? 80.0 : 90.0;

    final sinInicio =
        visibles.where((m) => m != DashboardModule.inicio).toList();

    final izquierda = <DashboardModule>[];
    final derecha = <DashboardModule>[];
    for (var i = 0; i < sinInicio.length; i++) {
      if (i.isEven) {
        izquierda.add(sinInicio[i]);
      } else {
        derecha.add(sinInicio[i]);
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Container(
          height: height,
          padding: EdgeInsets.symmetric(
            horizontal: tablet ? AppSpacing.medium : AppSpacing.large,
          ),
          child: Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  reverse: true,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: izquierda.reversed
                        .map((m) => _navItem(
                              m,
                              modules[m]!,
                              dashboardVM,
                              tablet: tablet,
                              desktop: desktop,
                            ))
                        .toList(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _navItem(
                DashboardModule.inicio,
                modules[DashboardModule.inicio]!,
                dashboardVM,
                tablet: tablet,
                desktop: desktop,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: derecha
                        .map((m) => _navItem(
                              m,
                              modules[m]!,
                              dashboardVM,
                              tablet: tablet,
                              desktop: desktop,
                            ))
                        .toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================
  // 🔘 ITEM DE NAVEGACIÓN
  // ==========================================
  Widget _navItem(
    DashboardModule module,
    _ModuleConfig cfg,
    DashboardViewModel dashboardVM, {
    bool mobile = false,
    bool tablet = false,
    bool desktop = false,
  }) {
    final isSelected = dashboardVM.selected == module;
    final isInicio = module == DashboardModule.inicio;

    if (isInicio) {
      return Padding(
        padding: EdgeInsets.symmetric(
          horizontal: mobile ? AppSpacing.medium : AppSpacing.large,
        ),
        child: GestureDetector(
          onTap: () => dashboardVM.changeModule(module),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : AppColors.success,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            width: mobile ? 56 : (tablet ? 64 : 72),
            height: mobile ? 56 : (tablet ? 64 : 72),
            child: Icon(
              Icons.home,
              color: Colors.white,
              size: mobile ? 24 : (tablet ? 28 : 32),
            ),
          ),
        ),
      );
    }

    return MaterialButton(
      minWidth: mobile ? 40 : (tablet ? 60 : 80),
      onPressed: () => dashboardVM.changeModule(module),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            cfg.icon,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            size: mobile ? 20 : (tablet ? 24 : 28),
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              cfg.label,
              style: AppTextStyles.body.copyWith(
                color: isSelected
                    ? AppColors.primary
                    : AppColors.textSecondary,
                fontSize: mobile ? 10 : (tablet ? 12 : 14),
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: tablet ? 2 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// 🎭 ESTILO POR ROL
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

// ==========================================
// 🧩 CONFIG DE MÓDULO
// ==========================================
class _ModuleConfig {
  final String label;
  final IconData icon;
  final Widget Function(BuildContext) builder;

  const _ModuleConfig({
    required this.label,
    required this.icon,
    required this.builder,
  });
}

// ==========================================
// 🚧 PLACEHOLDER
// ==========================================
class _PlaceholderScreen extends StatelessWidget {
  final String title;
  const _PlaceholderScreen({required this.title});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.construction, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Módulo en construcción',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}