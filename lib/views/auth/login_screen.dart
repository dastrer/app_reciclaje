import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../utils/constants.dart'; // 🎨 Colores y estilos
import '../../viewmodels/login_viewmodel.dart'; // 🔐 ViewModel + UsuarioActual

class LoginScreen extends StatefulWidget {
  /// 🔐 Callback que recibe el usuario autenticado cuando el login es exitoso.
  final void Function(UsuarioActual usuario)? onLoggedIn;

  const LoginScreen({super.key, this.onLoggedIn});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  @override
  Widget build(BuildContext context) {
    final vm = context.watch<LoginViewModel>();

    final emailCtrl = vm.emailController;
    final passCtrl = vm.passwordController;
    final loading = vm.isLoading;
    final errorText = vm.errorMessage;

    return Scaffold(
      body: Stack(
        children: [
          // ======== FONDO ========
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/images/fondo_calzados.jpg"),
                fit: BoxFit.cover,
              ),
            ),
          ),

          // ======== CAPA BLUR ========
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 7, sigmaY: 7),
              child: Container(
                color: Colors.white.withOpacity(0.55),
              ),
            ),
          ),

          // ======== CONTENIDO ========
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: 420,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // HEADER
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: 22,
                        horizontal: 16,
                      ),
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            Colors.black87,
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(18),
                          topRight: Radius.circular(18),
                        ),
                      ),
                      child: Column(
                        children: [
                          Image.asset(
                            "assets/images/logo.png",
                            height: 140,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.eco,
                              size: 100,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "MUNDO VERDE",
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "Acceso al Sistema",
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.accent.withOpacity(0.9),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // BODY
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 28,
                      ),
                      child: Column(
                        children: [
                          // MENSAJE DE ERROR
                          if (errorText != null)
                            Container(
                              padding: const EdgeInsets.all(12),
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: Colors.red.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: Colors.red.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error,
                                    color: Colors.red,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      errorText,
                                      style: const TextStyle(
                                        color: Colors.red,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                          // EMAIL INPUT
                          TextField(
                            controller: emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            onChanged: (_) => vm.clearError(),
                            decoration: InputDecoration(
                              labelText: "Correo electrónico",
                              prefixIcon: const Icon(Icons.email_outlined),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),

                          // PASSWORD INPUT
                          TextField(
                            controller: passCtrl,
                            obscureText: true,
                            onChanged: (_) => vm.clearError(),
                            decoration: InputDecoration(
                              labelText: "Contraseña",
                              prefixIcon: const Icon(Icons.lock_outline),
                              filled: true,
                              fillColor: Colors.white,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),

                          const SizedBox(height: 28),

                          // BOTÓN LOGIN
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                shadowColor:
                                    AppColors.primary.withOpacity(.35),
                                elevation: 6,
                              ),
                              onPressed: loading ? null : _login,
                              child: loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.4,
                                      ),
                                    )
                                  : const Text(
                                      "Iniciar Sesión",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // FOOTER
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.only(
                          bottomLeft: Radius.circular(18),
                          bottomRight: Radius.circular(18),
                        ),
                      ),
                      child: Text(
                        "© Incos - El Alto • ${DateTime.now().year}",
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  // ==========================================
  // 🔐 FUNCIÓN LOGIN USANDO LoginViewModel
  // ==========================================
  Future<void> _login() async {
    final vm = context.read<LoginViewModel>();

    vm.clearError();

    final success = await vm.login();

    if (!mounted) return;

    if (success) {
      // 🔎 Recuperamos el usuario tipado desde el VM
      final usuario = vm.usuarioActual;

      if (usuario == null) {
        debugPrint(
          '⚠️ Login OK pero LoginViewModel.usuarioActual es null. '
          'Revisa el login() del ViewModel.',
        );
        return;
      }

      widget.onLoggedIn?.call(usuario); // ⬅️ UsuarioActual
    } else {
      if (vm.errorMessage != null && vm.errorMessage!.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vm.errorMessage!),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}