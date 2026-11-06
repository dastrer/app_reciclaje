import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class InicioScreen extends StatelessWidget {
  const InicioScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: Center(
        child: Card(
          margin: const EdgeInsets.all(AppSpacing.large),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.home, size: 64, color: AppColors.primary),
                const SizedBox(height: AppSpacing.large),
                Text(
                  "Inicio\nEn Construcción",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading1.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.medium),
                Text(
                  "Este módulo está actualmente en desarrollo y estará disponible pronto.",
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}