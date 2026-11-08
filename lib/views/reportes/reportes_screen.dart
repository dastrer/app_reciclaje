import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../viewmodels/dashboard_viewmodel.dart';
import '../../utils/constants.dart';

class ReportesScreen extends StatelessWidget {
  const ReportesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _EnDesarrollo(
      titulo: 'Reportes',
      icono: Icons.insights,
    );
  }
}

// ─────────────────────────────────────────────
// Widget reutilizable (cópialo en cada archivo o
// muévelo a un archivo común si prefieres DRY).
// ─────────────────────────────────────────────
class _EnDesarrollo extends StatelessWidget {
  final String titulo;
  final IconData icono;

  const _EnDesarrollo({required this.titulo, required this.icono});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icono, size: 64, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            Text(
              titulo,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Módulo en desarrollo',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                fontSize: 14,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context
                  .read<DashboardViewModel>()
                  .changeModule(DashboardModule.inicio),
              icon: const Icon(Icons.home),
              label: const Text('Volver al inicio'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}