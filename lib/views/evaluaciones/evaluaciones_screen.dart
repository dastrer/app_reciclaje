import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class EvaluacionesScreen extends StatefulWidget {
  const EvaluacionesScreen({super.key});

  @override
  State<EvaluacionesScreen> createState() =>
      _EvaluacionesScreenState();
}

class _EvaluacionesScreenState extends State<EvaluacionesScreen> {
  int preguntaActual = 0;
  int puntuacion = 0;
  int? respuestaSeleccionada;
  bool respondida = false;
  bool finalizado = false;

  final List<Map<String, dynamic>> preguntas = [
    {
      'pregunta': '¿Cuál de estos residuos es orgánico?',
      'opciones': [
        'Botella de plástico',
        'Cáscara de plátano',
        'Lata de refresco',
        'Bolsa de plástico'
      ],
      'correcta': 1,
      'explicacion':
          'La cáscara de plátano es orgánica porque proviene de una planta y puede descomponerse naturalmente.'
    },
    {
      'pregunta': '¿Cuál de estos residuos es inorgánico?',
      'opciones': [
        'Cáscara de naranja',
        'Hojas secas',
        'Botella de vidrio',
        'Restos de verduras'
      ],
      'correcta': 2,
      'explicacion':
          'El vidrio es inorgánico y puede reciclarse para fabricar nuevos objetos.'
    },
    {
      'pregunta': '¿Dónde debemos colocar los restos de comida?',
      'opciones': [
        'Con los residuos orgánicos',
        'Con los plásticos',
        'Con los metales',
        'En cualquier lugar'
      ],
      'correcta': 0,
      'explicacion':
          'Los restos de comida son orgánicos y pueden aprovecharse para elaborar compost.'
    },
    {
      'pregunta':
          'Después de tomar agua, ¿qué hacemos con la botella de plástico?',
      'opciones': [
        'Enterrarla',
        'Tirarla al río',
        'Separarla para reciclarla',
        'Quemarla'
      ],
      'correcta': 2,
      'explicacion':
          'Las botellas de plástico pueden reciclarse. Debemos depositarlas en el recipiente correspondiente.'
    },
    {
      'pregunta': '¿Cuál de estos residuos puede convertirse en compost?',
      'opciones': [
        'Cáscaras de frutas',
        'Pilas usadas',
        'Vidrios rotos',
        'Latas'
      ],
      'correcta': 0,
      'explicacion':
          'Las cáscaras de frutas pueden aprovecharse para producir compost.'
    },
    {
      'pregunta':
          'En tu escuela encuentras una hoja de papel usada. ¿Qué debes hacer?',
      'opciones': [
        'Tirarla al suelo',
        'Quemarla',
        'Separarla para su reciclaje',
        'Mezclarla con restos de comida'
      ],
      'correcta': 2,
      'explicacion':
          'El papel limpio y seco puede separarse para su reciclaje.'
    },
    {
      'pregunta': '¿Cuál de estos residuos es orgánico?',
      'opciones': [
        'Una lata',
        'Una cáscara de huevo',
        'Una botella de vidrio',
        'Una bolsa plástica'
      ],
      'correcta': 1,
      'explicacion':
          'La cáscara de huevo proviene de un ser vivo y es biodegradable.'
    },
    {
      'pregunta':
          '¿Qué sucede cuando mezclamos todos los residuos?',
      'opciones': [
        'Es más fácil reciclar',
        'No pasa nada',
        'Dificultamos su aprovechamiento',
        'Todos desaparecen'
      ],
      'correcta': 2,
      'explicacion':
          'Separar los residuos facilita el reciclaje y el aprovechamiento de los residuos orgánicos.'
    },
    {
      'pregunta':
          'En el mercado compras frutas y quedan cáscaras. ¿Qué tipo de residuo son?',
      'opciones': [
        'Orgánicos',
        'Metálicos',
        'Plásticos',
        'De vidrio'
      ],
      'correcta': 0,
      'explicacion':
          'Las cáscaras de frutas son residuos orgánicos porque provienen de plantas.'
    },
    {
      'pregunta': '¿Por qué debemos separar la basura?',
      'opciones': [
        'Para producir más basura',
        'Para cuidar el medio ambiente',
        'Para ensuciar las calles',
        'Para desperdiciar materiales'
      ],
      'correcta': 1,
      'explicacion':
          'Separar los residuos ayuda a reducir la contaminación y aprovechar los materiales.'
    },
  ];

  void seleccionarRespuesta(int indice) {
    if (respondida) return;

    setState(() {
      respuestaSeleccionada = indice;
      respondida = true;

      if (indice == preguntas[preguntaActual]['correcta']) {
        puntuacion++;
      }
    });
  }

  void siguientePregunta() {
    setState(() {
      if (preguntaActual < preguntas.length - 1) {
        preguntaActual++;
        respuestaSeleccionada = null;
        respondida = false;
      } else {
        finalizado = true;
      }
    });
  }

  void reiniciarEvaluacion() {
    setState(() {
      preguntaActual = 0;
      puntuacion = 0;
      respuestaSeleccionada = null;
      respondida = false;
      finalizado = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background,
      child: finalizado
          ? pantallaResultado()
          : pantallaPregunta(),
    );
  }

  Widget pantallaPregunta() {
    final pregunta = preguntas[preguntaActual];
    final opciones = pregunta['opciones'] as List<String>;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.large),
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.medium),
        ),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.large),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Icon(
                Icons.quiz,
                size: 55,
                color: AppColors.primary,
              ),

              const SizedBox(height: AppSpacing.medium),

              Text(
                'Evaluación ambiental',
                textAlign: TextAlign.center,
                style: AppTextStyles.heading1.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: AppSpacing.medium),

              Text(
                'Pregunta ${preguntaActual + 1} de ${preguntas.length}',
                textAlign: TextAlign.center,
                style: AppTextStyles.body.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: AppSpacing.medium),

              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (preguntaActual + 1) / preguntas.length,
                  minHeight: 10,
                  color: AppColors.primary,
                  backgroundColor: AppColors.background,
                ),
              ),

              const SizedBox(height: AppSpacing.large),

              Text(
                pregunta['pregunta'],
                textAlign: TextAlign.center,
                style: AppTextStyles.heading1.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 20,
                ),
              ),

              const SizedBox(height: AppSpacing.large),

              ...List.generate(opciones.length, (index) {
                return construirOpcion(
                  opciones[index],
                  index,
                  pregunta['correcta'],
                );
              }),

              if (respondida) ...[
                const SizedBox(height: AppSpacing.medium),

                Container(
                  padding: const EdgeInsets.all(AppSpacing.medium),
                  decoration: BoxDecoration(
                    color: respuestaSeleccionada ==
                            pregunta['correcta']
                        ? Colors.green.withOpacity(0.12)
                        : Colors.orange.withOpacity(0.12),
                    borderRadius:
                        BorderRadius.circular(AppRadius.medium),
                  ),
                  child: Column(
                    children: [
                      Text(
                        respuestaSeleccionada ==
                                pregunta['correcta']
                            ? '¡Muy bien! 🎉'
                            : '¡Sigue aprendiendo! 🌱',
                        style: AppTextStyles.heading1.copyWith(
                          color: respuestaSeleccionada ==
                                  pregunta['correcta']
                              ? Colors.green
                              : Colors.orange,
                          fontSize: 19,
                        ),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        pregunta['explicacion'],
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: AppSpacing.large),

                ElevatedButton(
                  onPressed: siguientePregunta,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppRadius.medium),
                    ),
                  ),
                  child: Text(
                    preguntaActual == preguntas.length - 1
                        ? 'Ver resultados'
                        : 'Siguiente pregunta',
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget construirOpcion(
    String texto,
    int indice,
    int correcta,
  ) {
    Color colorFondo = AppColors.background;
    Color colorBorde = Colors.transparent;
    IconData? icono;

    if (respondida) {
      if (indice == correcta) {
        colorFondo = Colors.green.withOpacity(0.15);
        colorBorde = Colors.green;
        icono = Icons.check_circle;
      } else if (indice == respuestaSeleccionada) {
        colorFondo = Colors.red.withOpacity(0.12);
        colorBorde = Colors.red;
        icono = Icons.cancel;
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.medium),
      child: InkWell(
        onTap: () => seleccionarRespuesta(indice),
        borderRadius: BorderRadius.circular(AppRadius.medium),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.medium),
          decoration: BoxDecoration(
            color: colorFondo,
            borderRadius: BorderRadius.circular(AppRadius.medium),
            border: Border.all(
              color: colorBorde,
              width: 2,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Text(
                  String.fromCharCode(65 + indice),
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(width: 12),

              Expanded(
                child: Text(
                  texto,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ),

              if (icono != null)
                Icon(
                  icono,
                  color: indice == correcta
                      ? Colors.green
                      : Colors.red,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget pantallaResultado() {
    double porcentaje =
        (puntuacion / preguntas.length) * 100;

    String mensaje;
    IconData icono;

    if (puntuacion >= 9) {
      mensaje = '¡Excelente! Eres un guardián del planeta.';
      icono = Icons.emoji_events;
    } else if (puntuacion >= 6) {
      mensaje = '¡Muy bien! Sigue practicando y aprendiendo.';
      icono = Icons.star;
    } else {
      mensaje = '¡No te rindas! Cada intento te ayuda a mejorar.';
      icono = Icons.eco;
    }

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.large),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icono,
                  size: 85,
                  color: AppColors.primary,
                ),

                const SizedBox(height: AppSpacing.large),

                Text(
                  '¡Evaluación terminada!',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading1.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: AppSpacing.large),

                Text(
                  '$puntuacion / ${preguntas.length}',
                  style: AppTextStyles.heading1.copyWith(
                    color: AppColors.primary,
                    fontSize: 40,
                  ),
                ),

                Text(
                  '${porcentaje.toStringAsFixed(0)}% de respuestas correctas',
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: AppSpacing.large),

                Text(
                  mensaje,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: AppSpacing.large),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: reiniciarEvaluacion,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Volver a intentar'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.all(16),
                    ),
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