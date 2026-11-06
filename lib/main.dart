import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// 🧠 VIEWMODELS
import 'viewmodels/dashboard_viewmodel.dart';
import 'viewmodels/login_viewmodel.dart';

// 🎨 CONSTANTES
import 'utils/constants.dart';

// 🖥 PANTALLAS
import 'views/dashboard/dashboard_screen.dart' as dash;
import 'views/auth/login_screen.dart' as auth;

// 🗄️ BASE DE DATOS
import 'data/database_helper.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await DatabaseHelper.instance.database;
    debugPrint('✅ BASE DE DATOS DEL MANUAL LISTA');
  } catch (e) {
    debugPrint('❌ ERROR AL CREAR/ABRIR LA BASE DE DATOS: $e');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => DashboardViewModel()),
        ChangeNotifierProvider(create: (_) => LoginViewModel()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Manual del Sistema Web',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: AppColors.primary,
            primary: AppColors.primary,
            secondary: AppColors.accent,
            background: AppColors.background,
          ),
          scaffoldBackgroundColor: AppColors.background,
          appBarTheme: const AppBarTheme(
            backgroundColor: AppColors.primary,
            elevation: 0,
            centerTitle: true,
            titleTextStyle: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        home: const Root(),
      ),
    );
  }
}

class Root extends StatefulWidget {
  const Root({super.key});

  @override
  State<Root> createState() => _RootState();
}

class _RootState extends State<Root> {
  bool _loggedIn = false;

  /// 🧑 Usuario autenticado
  UsuarioActual? _usuario;

  // ==========================================
  // ✅ LOGIN OK
  // ==========================================
  void _handleLoggedIn(UsuarioActual usuario) {
    final dashboardVM = context.read<DashboardViewModel>();
    dashboardVM.restart();

    setState(() {
      _usuario = usuario;
      _loggedIn = true;
    });
  }

  // ==========================================
  // 🚪 LOGOUT
  // ==========================================
  void _handleLogout() {
    final loginVM = context.read<LoginViewModel>();
    loginVM.logout();

    setState(() {
      _usuario = null;
      _loggedIn = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return _loggedIn
        ? dash.DashboardScreen(
            usuario: _usuario,
            onLogout: _handleLogout,
          )
        : auth.LoginScreen(
            onLoggedIn: _handleLoggedIn,
          );
  }
}