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

class DashboardScreen extends StatelessWidget {
  /// 🧑 Usuario autenticado
  final UsuarioActual? usuario;

  /// 🔓 Callback para que el árbol superior (Root) gestione la sesión
  final VoidCallback? onLogout;

  const DashboardScreen({
    super.key,
    this.usuario,
    this.onLogout,
  });

  // Índices centralizados
  static const int _idxJuegos = 0;
  static const int _idxEvaluaciones = 1;
  static const int _idxInicio = 2;
  static const int _idxSoporte = 3;
  static const int _idxMultimedia = 4;

  @override
  Widget build(BuildContext context) {
    final dashboardVM = Provider.of<DashboardViewModel>(context);

    final List<Widget> pages = const [
      JuegosScreen(),
      EvaluacionesScreen(),
      InicioScreen(),
      SoporteScreen(),
      EcoEncartaScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.dashboard),
        centerTitle: true,
        elevation: 4,
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
      ),
      drawer: _buildDrawer(context, dashboardVM),
      body: pages[dashboardVM.selectedIndex],
      bottomNavigationBar: _buildResponsiveBottomNavigationBar(
        dashboardVM,
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
      usuario?.nombreCompleto ?? 'Usuario Ejemplo';

  String _correo() =>
      usuario?.correo ?? 'usuario@correo.com';

  String? _avatarRuta() => usuario?.avatarRuta;

  String? _rolNombre() => usuario?.rolNombre;

  // ==========================================
  // 🖼️ DRAWER
  // ==========================================
  Drawer _buildDrawer(BuildContext context, DashboardViewModel dashboardVM) {
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
          _buildDrawerItem(
            context, Icons.home, "Inicio", _idxInicio, dashboardVM,
          ),
          _buildDrawerItem(
            context, Icons.sports_esports, "Juegos", _idxJuegos, dashboardVM,
          ),
          _buildDrawerItem(
            context, Icons.quiz, "Evaluaciones", _idxEvaluaciones, dashboardVM,
          ),
          _buildDrawerItem(
            context, Icons.perm_media, "Multimedia", _idxMultimedia, dashboardVM,
          ),
          _buildDrawerItem(
            context, Icons.support_agent, "Soporte", _idxSoporte, dashboardVM,
          ),
          const Spacer(),
          const Divider(height: 1, color: AppColors.textSecondary),
          ListTile(
            leading: Icon(Icons.logout, color: AppColors.error),
            title: Text(
              AppStrings.logout,
              style: AppTextStyles.body.copyWith(color: AppColors.error),
            ),
            onTap: () {
              Navigator.pop(context);
              onLogout?.call();
            },
          ),
        ],
      ),
    );
  }

  ListTile _buildDrawerItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
    DashboardViewModel dashboardVM,
  ) {
    final bool isSelected = dashboardVM.selectedIndex == index;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : AppColors.textSecondary,
      ),
      title: Text(
        label,
        style: AppTextStyles.body.copyWith(
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primary.withOpacity(0.1),
      onTap: () {
        dashboardVM.changeIndex(index);
        Navigator.pop(context);
      },
    );
  }

  // ==========================================
  // 📱 BOTTOM NAV RESPONSIVO
  // ==========================================
  Widget _buildResponsiveBottomNavigationBar(
    DashboardViewModel dashboardVM,
    BuildContext context,
  ) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 600) {
      return _buildMobileBottomNavigationBar(dashboardVM, context);
    } else if (screenWidth < 1200) {
      return _buildTabletBottomNavigationBar(dashboardVM, context);
    } else {
      return _buildDesktopBottomNavigationBar(dashboardVM, context);
    }
  }

  // ─────────────────────────────────────────────
  // MOBILE
  // ─────────────────────────────────────────────
  Widget _buildMobileBottomNavigationBar(
    DashboardViewModel dashboardVM,
    BuildContext context,
  ) {
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
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildNavItem(
                Icons.sports_esports, "Juegos", _idxJuegos, dashboardVM,
                isMobile: true,
              ),
              _buildNavItem(
                Icons.quiz, "Evaluaciones", _idxEvaluaciones, dashboardVM,
                isMobile: true,
              ),
              _buildNavItemInicio(dashboardVM, isMobile: true),
              _buildNavItem(
                Icons.perm_media, "Multimedia", _idxMultimedia, dashboardVM,
                isMobile: true,
              ),
              _buildNavItem(
                Icons.support_agent, "Soporte", _idxSoporte, dashboardVM,
                isMobile: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TABLET
  // ─────────────────────────────────────────────
  Widget _buildTabletBottomNavigationBar(
    DashboardViewModel dashboardVM,
    BuildContext context,
  ) {
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
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.medium),
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      Icons.sports_esports, "Juegos", _idxJuegos, dashboardVM,
                      isTablet: true,
                    ),
                    _buildNavItem(
                      Icons.quiz, "Evaluaciones", _idxEvaluaciones,
                      dashboardVM, isTablet: true,
                    ),
                  ],
                ),
              ),
              _buildNavItemInicio(dashboardVM, isTablet: true),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(
                      Icons.perm_media, "Multimedia", _idxMultimedia,
                      dashboardVM, isTablet: true,
                    ),
                    _buildNavItem(
                      Icons.support_agent, "Soporte", _idxSoporte,
                      dashboardVM, isTablet: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // DESKTOP
  // ─────────────────────────────────────────────
  Widget _buildDesktopBottomNavigationBar(
    DashboardViewModel dashboardVM,
    BuildContext context,
  ) {
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
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.large),
          height: 90,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(
                      Icons.sports_esports, "Juegos", _idxJuegos,
                      dashboardVM, isDesktop: true,
                    ),
                    _buildNavItem(
                      Icons.quiz, "Evaluaciones", _idxEvaluaciones,
                      dashboardVM, isDesktop: true,
                    ),
                  ],
                ),
              ),
              _buildNavItemInicio(dashboardVM, isDesktop: true),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildNavItem(
                      Icons.perm_media, "Multimedia", _idxMultimedia,
                      dashboardVM, isDesktop: true,
                    ),
                    _buildNavItem(
                      Icons.support_agent, "Soporte Técnico", _idxSoporte,
                      dashboardVM, isDesktop: true,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    int index,
    DashboardViewModel dashboardVM, {
    bool isMobile = false,
    bool isTablet = false,
    bool isDesktop = false,
  }) {
    final bool isSelected = dashboardVM.selectedIndex == index;

    return MaterialButton(
      minWidth: isMobile
          ? 40
          : isTablet
          ? 60
          : 80,
      onPressed: () => dashboardVM.changeIndex(index),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
            size: isMobile
                ? 20
                : isTablet
                ? 24
                : 28,
          ),
          const SizedBox(height: 4),
          Flexible(
            child: Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: isSelected ? AppColors.primary : AppColors.textSecondary,
                fontSize: isMobile
                    ? 10
                    : isTablet
                    ? 12
                    : 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
              textAlign: TextAlign.center,
              maxLines: isTablet ? 2 : 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItemInicio(
    DashboardViewModel dashboardVM, {
    bool isMobile = false,
    bool isTablet = false,
    bool isDesktop = false,
  }) {
    final bool isSelected = dashboardVM.selectedIndex == _idxInicio;

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? AppSpacing.medium : AppSpacing.large,
      ),
      child: GestureDetector(
        onTap: () => dashboardVM.changeIndex(_idxInicio),
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
          width: isMobile
              ? 56
              : isTablet
              ? 64
              : 72,
          height: isMobile
              ? 56
              : isTablet
              ? 64
              : 72,
          child: Icon(
            Icons.home,
            color: Colors.white,
            size: isMobile
                ? 24
                : isTablet
                ? 28
                : 32,
          ),
        ),
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