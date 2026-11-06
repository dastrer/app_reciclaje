import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class SoporteScreen extends StatelessWidget {
  const SoporteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Encabezado del módulo
            Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.large),
                child: Column(
                  children: [
                    Icon(
                      Icons.support_agent,
                      size: 65,
                      color: AppColors.primary,
                    ),

                    const SizedBox(height: AppSpacing.medium),

                    Text(
                      'Centro de ayuda',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.heading1.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.medium),

                    Text(
                      '¡Hola! 🌱 Aquí encontrarás ayuda para utilizar la aplicación y aprender a separar correctamente los residuos.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.large),

            Text(
              'Preguntas frecuentes',
              style: AppTextStyles.heading1.copyWith(
                color: AppColors.textPrimary,
                fontSize: 21,
              ),
            ),

            const SizedBox(height: AppSpacing.medium),

            // Cómo utilizar la aplicación
            construirAyuda(
              icono: Icons.phone_android,
              titulo: '¿Cómo utilizar la aplicación?',
              descripcion: 'Aprende a navegar por los módulos.',
              pasos: [
                'Ingresa al menú principal de la aplicación.',
                'Selecciona el módulo que deseas utilizar.',
                'Explora las actividades y aprende sobre los residuos.',
                'Puedes regresar al menú principal para elegir otro módulo.',
              ],
            ),

            // Evaluaciones
            construirAyuda(
              icono: Icons.quiz,
              titulo: '¿Cómo realizar las evaluaciones?',
              descripcion: 'Aprende a responder las preguntas.',
              pasos: [
                'Ingresa al módulo de Evaluaciones.',
                'Lee cuidadosamente cada pregunta.',
                'Selecciona la respuesta que consideres correcta.',
                'Observa la explicación que aparece después de responder.',
                'Presiona Siguiente pregunta para continuar.',
                'Al finalizar podrás conocer tu puntuación.',
              ],
            ),

            // Residuos orgánicos
            construirAyuda(
              icono: Icons.eco,
              titulo: '¿Qué son los residuos orgánicos?',
              descripcion: 'Conoce los residuos que provienen de seres vivos.',
              pasos: [
                'Son residuos que provienen de plantas y animales.',
                'Algunos ejemplos son las cáscaras de frutas.',
                'También las hojas secas y los restos de verduras.',
                'Pueden descomponerse naturalmente.',
                'Algunos pueden aprovecharse para elaborar compost.',
              ],
            ),

            // Residuos inorgánicos
            construirAyuda(
              icono: Icons.recycling,
              titulo: '¿Qué son los residuos inorgánicos?',
              descripcion: 'Aprende a reconocer diferentes materiales.',
              pasos: [
                'Son residuos como el plástico, el vidrio y los metales.',
                'Una botella de plástico es un ejemplo de residuo inorgánico.',
                'También encontramos latas y frascos de vidrio.',
                'Algunos materiales pueden reciclarse y convertirse en nuevos productos.',
              ],
            ),

            // Separación de residuos
            construirAyuda(
              icono: Icons.delete_sweep,
              titulo: '¿Cómo separar los residuos?',
              descripcion: 'Aprende a clasificar la basura correctamente.',
              pasos: [
                'Primero identifica qué tipo de residuo tienes.',
                'Si proviene de restos de frutas, verduras u hojas, es orgánico.',
                'Si es plástico, vidrio o metal, es inorgánico.',
                'Coloca cada residuo en el recipiente correspondiente.',
                'No mezcles los residuos y ayuda a mantener limpios los espacios.',
              ],
            ),

            // Dudas y errores
            construirAyuda(
              icono: Icons.lightbulb,
              titulo: '¿Qué hago si me equivoco?',
              descripcion: '¡No te preocupes! Todos podemos aprender.',
              pasos: [
                'Lee la explicación que aparece después de responder.',
                'Recuerda qué característica tiene cada tipo de residuo.',
                'Intenta nuevamente la actividad.',
                'Pide ayuda a tu profesor o a un adulto si tienes dudas.',
              ],
            ),

            // Recomendaciones de seguridad
            construirAyuda(
              icono: Icons.health_and_safety,
              titulo: 'Consejos importantes',
              descripcion: 'Cuida tu salud mientras cuidas el planeta.',
              pasos: [
                'No recojas objetos desconocidos de la calle.',
                'No manipules vidrios rotos ni pilas usadas.',
                'Pide ayuda a un adulto cuando encuentres residuos peligrosos.',
                'Lávate las manos después de manipular residuos.',
                'Mantén limpios tu hogar, escuela y comunidad.',
              ],
            ),

            const SizedBox(height: AppSpacing.large),

            // Mensaje final
            Card(
              elevation: 4,
              color: AppColors.primary.withOpacity(0.10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.medium),
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.large),
                child: Column(
                  children: [
                    Icon(
                      Icons.public,
                      size: 45,
                      color: AppColors.primary,
                    ),

                    const SizedBox(height: AppSpacing.medium),

                    Text(
                      '¡Juntos cuidamos el planeta! 🌎',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.heading1.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 19,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.medium),

                    Text(
                      'Recuerda: separar los residuos es una pequeña acción que puede generar un gran cambio.',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Construcción de cada sección de ayuda
  Widget construirAyuda({
    required IconData icono,
    required String titulo,
    required String descripcion,
    required List<String> pasos,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.medium),
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.medium),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.12),
          child: Icon(
            icono,
            color: AppColors.primary,
          ),
        ),

        title: Text(
          titulo,
          style: AppTextStyles.body.copyWith(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),

        subtitle: Text(
          descripcion,
          style: AppTextStyles.body.copyWith(
            color: AppColors.textSecondary,
          ),
        ),

        iconColor: AppColors.primary,
        collapsedIconColor: AppColors.textSecondary,

        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.large,
              0,
              AppSpacing.large,
              AppSpacing.large,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: pasos.map((paso) {
                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: AppSpacing.medium,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        color: AppColors.primary,
                        size: 20,
                      ),

                      const SizedBox(width: 10),

                      Expanded(
                        child: Text(
                          paso,
                          style: AppTextStyles.body.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}