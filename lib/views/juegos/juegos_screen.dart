import 'dart:async';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:confetti/confetti.dart';
import 'package:flame/components.dart'
    hide Timer, Icon, Positioned, Text, Container, Image, Vector2;
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:lottie/lottie.dart';
import 'package:provider/provider.dart';

import '../../utils/constants.dart';

// ============================================================================
// 📦 MODELOS Y ESTADO GLOBAL
// ============================================================================

class EcoGameInfo {
  final String id;
  final String title;
  final String subtitle;
  final String description;
  final IconData icon;
  final List<Color> gradient;
  final List<String> instructions;

  const EcoGameInfo({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.icon,
    required this.gradient,
    required this.instructions,
  });
}

class EcoGamesProvider extends ChangeNotifier {
  int _totalStars = 0;
  int _totalCoins = 0;
  int _ecoLevel = 1;
  final Map<String, int> _highScores = {};

  int get totalStars => _totalStars;
  int get totalCoins => _totalCoins;
  int get ecoLevel => _ecoLevel;
  Map<String, int> get highScores => _highScores;

  String get ecoRank {
    if (_ecoLevel < 3) return 'Aprendiz Verde';
    if (_ecoLevel < 6) return 'Guardián Eco';
    if (_ecoLevel < 10) return 'Héroe del Reciclaje';
    return 'Maestro Circular';
  }

  void addStars(int stars) {
    _totalStars += stars;
    final newLevel = (_totalStars ~/ 10) + 1;
    if (newLevel > _ecoLevel) _ecoLevel = newLevel;
    notifyListeners();
  }

  void addCoins(int coins) {
    _totalCoins += coins;
    notifyListeners();
  }

  void registerScore(String gameId, int score) {
    final prev = _highScores[gameId] ?? 0;
    if (score > prev) {
      _highScores[gameId] = score;
      addStars(1);
    }
    notifyListeners();
  }
}

// ============================================================================
// 🎮 PANTALLA PRINCIPAL
// ============================================================================

class JuegosScreen extends StatelessWidget {
  const JuegosScreen({super.key});

  static const List<EcoGameInfo> _games = [
    EcoGameInfo(
      id: 'eco_factory',
      title: 'Eco-Factory',
      subtitle: 'El Gran Clasificador',
      description:
          'Los residuos avanzan por una cinta transportadora. ¡Clasifícalos antes de que caigan!',
      icon: Icons.factory_rounded,
      gradient: [Color(0xFF43A047), Color(0xFF1B5E20)],
      instructions: [
        '🏭 Los residuos aparecen sobre la cinta transportadora.',
        '👆 Toca un residuo y luego el tacho del color correcto.',
        '🟢 Verde = Orgánico · 🔵 Azul = Papel · 🟡 Amarillo = Plástico · 🔴 Rojo = Especiales',
        '❤️ Tienes 3 vidas. Si un residuo llega al final, pierdes una.',
        '⚡ Los aciertos consecutivos suben tu combo y multiplican puntos.',
        '🚀 La velocidad aumenta a medida que sumas puntos.',
      ],
    ),
    EcoGameInfo(
      id: 'barrio_limpio',
      title: 'Barrio Limpio',
      subtitle: 'Misión Cotidiana',
      description:
          'Explora 3 escenas cotidianas y resuelve situaciones reales aplicando las 3R.',
      icon: Icons.home_work_rounded,
      gradient: [Color(0xFF29B6F6), Color(0xFF0277BD)],
      instructions: [
        '🏠 Visitarás 3 escenarios: La Cocina, El Parque y La Escuela.',
        '👆 Toca los objetos desordenados para descubrir las opciones.',
        '🧠 Elige la acción correcta aplicando Reducir, Reutilizar y Reciclar.',
        '❤️ Tienes 3 vidas. Cada respuesta incorrecta te resta una.',
        '✅ Cada respuesta correcta te da 15 puntos.',
        '🌍 Completa todos los objetos de cada escena para avanzar.',
      ],
    ),
    EcoGameInfo(
      id: 'eco_craft',
      title: 'Eco-Craft',
      subtitle: 'Taller de Reciclaje',
      description:
          'Combina materias primas recicladas para fabricar nuevos productos y ganar monedas.',
      icon: Icons.construction_rounded,
      gradient: [Color(0xFFFFB300), Color(0xFFEF6C00)],
      instructions: [
        '📦 Tienes un inventario de materias primas recicladas.',
        '⚙️ Elige una receta y pulsa "Crear" si tienes los insumos.',
        '🪙 Cada crafteo recompensa monedas según los insumos gastados.',
        '🌱 Los productos más elaborados otorgan más monedas.',
        '♻️ Así funciona la economía circular: transformar residuos en recursos.',
      ],
    ),
    EcoGameInfo(
      id: 'eco_runner',
      title: 'Eco-Runner',
      subtitle: 'Limpieza Urbana',
      description:
          'Atrapa solo los residuos del tipo indicado en cada ronda. ¡Reflejos al límite!',
      icon: Icons.directions_run_rounded,
      gradient: [Color(0xFFAB47BC), Color(0xFF6A1B9A)],
      instructions: [
        '🎯 Cada ronda tiene un tipo de residuo objetivo (se mantiene fijo).',
        '👆 Toca solo los residuos del tipo indicado.',
        '❌ Si tocas un distractor, pierdes una vida.',
        '💧 Si un residuo objetivo llega al fondo, pierdes una vida.',
        '❤️ Tienes 3 vidas.',
        '⏱️ Tienes 30 segundos para conseguir la mayor puntuación.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EcoGamesProvider>(
      create: (_) => EcoGamesProvider(),
      child: const _EcoGamesHome(),
    );
  }
}

class _EcoGamesHome extends StatelessWidget {
  const _EcoGamesHome();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EcoGamesProvider>();
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            // 🌿 Fondo decorativo
            Positioned.fill(
              child: CustomPaint(painter: _HomeBackgroundPainter()),
            ),
            Column(
              children: [
                _EcoHeader(provider: provider),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.all(AppSpacing.large),
                    gridDelegate:
                        const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 380,
                      mainAxisSpacing: 18,
                      crossAxisSpacing: 18,
                      childAspectRatio: 0.82,
                    ),
                    itemCount: JuegosScreen._games.length,
                    itemBuilder: (context, index) {
                      final game = JuegosScreen._games[index];
                      return _GameCard(
                        game: game,
                        highScore: provider.highScores[game.id] ?? 0,
                        onPlay: () => _openGame(context, game),
                        onInstructions: () =>
                            _showInstructions(context, game),
                      );
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openGame(BuildContext context, EcoGameInfo game) {
    Widget screen;
    switch (game.id) {
      case 'eco_factory':
        screen = const EcoFactoryGame();
        break;
      case 'barrio_limpio':
        screen = const BarrioLimpioGame();
        break;
      case 'eco_craft':
        screen = const EcoCraftWidget();
        break;
      case 'eco_runner':
        screen = const EcoRunnerGame();
        break;
      default:
        return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ChangeNotifierProvider.value(
          value: context.read<EcoGamesProvider>(),
          child: screen,
        ),
      ),
    );
  }

  void _showInstructions(BuildContext context, EcoGameInfo game) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _InstructionsSheet(game: game),
    );
  }
}

// 🌿 Fondo animado decorativo del home
class _HomeBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Gradiente base
    final bg = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE8F5E9), Color(0xFFC8E6C9), Color(0xFFDCEDC8)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    // Burbujas decorativas
    final bubble = Paint()
      ..color = Colors.green.withOpacity(0.06)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.15), 120, bubble);
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.4), 160, bubble);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.75), 100, bubble);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.9), 140, bubble);

    // Hojas flotantes
    final leaf = Paint()
      ..color = Colors.green.withOpacity(0.08)
      ..style = PaintingStyle.fill;
    for (int i = 0; i < 6; i++) {
      final x = size.width * (0.15 + i * 0.15);
      final y = size.height * (0.25 + (i % 3) * 0.22);
      final path = Path()
        ..moveTo(x, y)
        ..quadraticBezierTo(x + 18, y - 12, x + 26, y + 4)
        ..quadraticBezierTo(x + 12, y + 14, x, y)
        ..close();
      canvas.drawPath(path, leaf);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ============================================================================
// 📖 INSTRUCCIONES
// ============================================================================

class _InstructionsSheet extends StatelessWidget {
  final EcoGameInfo game;
  const _InstructionsSheet({required this.game});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: game.gradient),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(game.icon, color: Colors.white, size: 26),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(game.title,
                          style: const TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w800)),
                      Text(game.subtitle,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(game.description,
                style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                    height: 1.4)),
            const SizedBox(height: 16),
            const Text('Cómo jugar',
                style:
                    TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            ...game.instructions.map((ins) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 2),
                        child: Icon(Icons.arrow_right_rounded,
                            size: 18, color: Colors.green),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(ins,
                            style: const TextStyle(
                                fontSize: 13, height: 1.35)),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// 🏷️ HEADER MEJORADO
// ============================================================================

class _EcoHeader extends StatelessWidget {
  final EcoGamesProvider provider;
  const _EcoHeader({required this.provider});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2E7D32), Color(0xFF66BB6A), Color(0xFF9CCC65)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.green.withOpacity(0.4),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decoración circular dentro del header
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.12),
              ),
            ),
          ),
          Positioned(
            left: 120,
            bottom: -30,
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Row(
            children: [
              _PulsingEcoBadge(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Eco-Games',
                        style: AppTextStyles.heading2.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5)),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text('Nv ${provider.ecoLevel}',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(provider.ecoRank,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.body.copyWith(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 12)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _StatChip(
                      icon: Icons.star_rounded,
                      color: const Color(0xFFFFD54F),
                      value: '${provider.totalStars}'),
                  const SizedBox(height: 4),
                  _StatChip(
                      icon: Icons.monetization_on_rounded,
                      color: const Color(0xFFFFB300),
                      value: '${provider.totalCoins}'),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PulsingEcoBadge extends StatefulWidget {
  @override
  State<_PulsingEcoBadge> createState() => _PulsingEcoBadgeState();
}

class _PulsingEcoBadgeState extends State<_PulsingEcoBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final scale = 1.0 + _ctrl.value * 0.08;
        return Transform.scale(
          scale: scale,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Colors.white.withOpacity(0.35), width: 1.5),
            ),
            child: const Icon(Icons.eco_rounded,
                color: Colors.white, size: 30),
          ),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  const _StatChip({
    required this.icon,
    required this.color,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 3),
          Text(value,
              style: const TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 12)),
        ],
      ),
    );
  }
}

// ============================================================================
// 🃏 TARJETA MEJORADA
// ============================================================================

class _GameCard extends StatefulWidget {
  final EcoGameInfo game;
  final int highScore;
  final VoidCallback onPlay;
  final VoidCallback onInstructions;

  const _GameCard({
    required this.game,
    required this.highScore,
    required this.onPlay,
    required this.onInstructions,
  });

  @override
  State<_GameCard> createState() => _GameCardState();
}

class _GameCardState extends State<_GameCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final game = widget.game;
    return AnimatedScale(
      scale: _pressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: game.gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: game.gradient.last.withOpacity(0.45),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                top: -30,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.12)),
                ),
              ),
              Positioned(
                right: 10,
                bottom: -40,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08)),
                ),
              ),
              Positioned(
                left: -20,
                bottom: 40,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.06)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.25),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                                width: 1),
                          ),
                          child: Icon(game.icon,
                              color: Colors.white, size: 26),
                        ),
                        const Spacer(),
                        if (widget.highScore > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.25),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.emoji_events,
                                    color: Colors.amber, size: 14),
                                const SizedBox(width: 4),
                                Text('${widget.highScore}',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const Spacer(),
                    Text(game.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3)),
                    const SizedBox(height: 4),
                    Text(game.subtitle,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 13)),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTapDown: (_) =>
                                setState(() => _pressed = true),
                            onTapUp: (_) {
                              setState(() => _pressed = false);
                              widget.onPlay();
                            },
                            onTapCancel: () =>
                                setState(() => _pressed = false),
                            child: Container(
                              padding:
                                  const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                      color:
                                          Colors.black.withOpacity(0.15),
                                      blurRadius: 6,
                                      offset: const Offset(0, 3)),
                                ],
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.play_arrow_rounded,
                                      size: 18, color: game.gradient.last),
                                  const SizedBox(width: 4),
                                  Text('Jugar',
                                      style: TextStyle(
                                          color: game.gradient.last,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: widget.onInstructions,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.22),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.4),
                                  width: 1),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.info_outline_rounded,
                                    color: Colors.white, size: 16),
                                SizedBox(width: 4),
                                Text('Info',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11)),
                              ],
                            ),
                          ),
                        ),
                      ],
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
}

// ============================================================================
// 🔧 BARRA SUPERIOR DE JUEGO
// ============================================================================

class _GameScaffoldBar extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const _GameScaffoldBar({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_ios_new_rounded,
                color: Colors.black87),
          ),
          Expanded(
            child: Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87),
                overflow: TextOverflow.ellipsis),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _HudPill extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  const _HudPill({
    required this.icon,
    required this.color,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 4),
          Text(value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
    );
  }
}

// ============================================================================
// 🔊 SFX
// ============================================================================

class _Sfx {
  static final _player = AudioPlayer();
  static Future<void> click() async {
    try {
      await _player.play(AssetSource('sounds/click.mp3'));
    } catch (_) {}
  }

  static Future<void> correct() async {
    try {
      await _player.play(AssetSource('sounds/correct.mp3'));
    } catch (_) {}
  }

  static Future<void> wrong() async {
    try {
      await _player.play(AssetSource('sounds/wrong.mp3'));
    } catch (_) {}
  }

  static Future<void> win() async {
    try {
      await _player.play(AssetSource('sounds/win.mp3'));
    } catch (_) {}
  }
}

// ============================================================================
// 🎯 MINIJUEGO 1: ECO-FACTORY (MÁS LARGO Y LENTO + BASURA COTIDIANA)
// ============================================================================

enum WasteCategory { organic, paper, plastic, special }

class _WasteItem {
  final String name;
  final IconData icon;
  final WasteCategory category;
  final Color color;
  final Color bg;

  const _WasteItem({
    required this.name,
    required this.icon,
    required this.category,
    required this.color,
    required this.bg,
  });
}

// 🗑️ Basura cotidiana real que encontramos en casa/calle
const List<_WasteItem> _allWaste = [
  // ORGÁNICOS
  _WasteItem(
      name: 'Cáscara plátano',
      icon: Icons.eco,
      category: WasteCategory.organic,
      color: Color(0xFF2E7D32),
      bg: Color(0xFFC8E6C9)),
  _WasteItem(
      name: 'Restos manzana',
      icon: Icons.apple,
      category: WasteCategory.organic,
      color: Color(0xFF388E3C),
      bg: Color(0xFFDCEDC8)),
  _WasteItem(
      name: 'Bolsa té',
      icon: Icons.emoji_food_beverage,
      category: WasteCategory.organic,
      color: Color(0xFF558B2F),
      bg: Color(0xFFF1F8E9)),
  _WasteItem(
      name: 'Cáscara huevo',
      icon: Icons.egg_alt,
      category: WasteCategory.organic,
      color: Color(0xFF6D4C41),
      bg: Color(0xFFEFEBE9)),
  // PLÁSTICOS
  _WasteItem(
      name: 'Botella PET',
      icon: Icons.local_drink,
      category: WasteCategory.plastic,
      color: Color(0xFF0277BD),
      bg: Color(0xFFB3E5FC)),
  _WasteItem(
      name: 'Bolsa supermercado',
      icon: Icons.shopping_bag,
      category: WasteCategory.plastic,
      color: Color(0xFF0288D1),
      bg: Color(0xFFE1F5FE)),
  _WasteItem(
      name: 'Envase yogur',
      icon: Icons.icecream,
      category: WasteCategory.plastic,
      color: Color(0xFF0097A7),
      bg: Color(0xFFE0F7FA)),
  _WasteItem(
      name: 'Botella detergente',
      icon: Icons.cleaning_services,
      category: WasteCategory.plastic,
      color: Color(0xFF00838F),
      bg: Color(0xFFE0F2F1)),
  _WasteItem(
      name: 'Lata refresco',
      icon: Icons.local_drink_outlined,
      category: WasteCategory.plastic,
      color: Color(0xFFEF6C00),
      bg: Color(0xFFFFE0B2)),
  // PAPEL / CARTÓN
  _WasteItem(
      name: 'Periódico',
      icon: Icons.article,
      category: WasteCategory.paper,
      color: Color(0xFF5D4037),
      bg: Color(0xFFD7CCC8)),
  _WasteItem(
      name: 'Caja cereal',
      icon: Icons.inventory_2,
      category: WasteCategory.paper,
      color: Color(0xFF6D4C41),
      bg: Color(0xFFEFEBE9)),
  _WasteItem(
      name: 'Revista',
      icon: Icons.menu_book,
      category: WasteCategory.paper,
      color: Color(0xFF795548),
      bg: Color(0xFFEFEBE9)),
  _WasteItem(
      name: 'Tetra Brik',
      icon: Icons.inventory,
      category: WasteCategory.paper,
      color: Color(0xFF455A64),
      bg: Color(0xFFCFD8DC)),
  _WasteItem(
      name: 'Sobre carta',
      icon: Icons.mail,
      category: WasteCategory.paper,
      color: Color(0xFF8D6E63),
      bg: Color(0xFFFBE9E7)),
  // ESPECIALES
  _WasteItem(
      name: 'Pilas AA',
      icon: Icons.battery_alert,
      category: WasteCategory.special,
      color: Color(0xFFC62828),
      bg: Color(0xFFFFCDD2)),
  _WasteItem(
      name: 'Bombilla',
      icon: Icons.lightbulb,
      category: WasteCategory.special,
      color: Color(0xFFF9A825),
      bg: Color(0xFFFFF9C4)),
  _WasteItem(
      name: 'Medicamento',
      icon: Icons.medication,
      category: WasteCategory.special,
      color: Color(0xFFAD1457),
      bg: Color(0xFFFCE4EC)),
  _WasteItem(
      name: 'Ropa vieja',
      icon: Icons.checkroom,
      category: WasteCategory.special,
      color: Color(0xFF880E4F),
      bg: Color(0xFFF8BBD0)),
    _WasteItem(
      name: 'Aerosol',
      icon: Icons.sanitizer,      // ✅ válido (frasco/atomizador)
      category: WasteCategory.special,
      color: Color(0xFFD32F2F),
      bg: Color(0xFFFFEBEE)),
];

class _FactoryItem {
  final _WasteItem waste;
  double progress;
  _FactoryItem({required this.waste, required this.progress});
}

class EcoFactoryGame extends StatefulWidget {
  const EcoFactoryGame({super.key});
  @override
  State<EcoFactoryGame> createState() => _EcoFactoryGameState();
}

class _EcoFactoryGameState extends State<EcoFactoryGame>
    with SingleTickerProviderStateMixin {
  final math.Random _rnd = math.Random();
  late Ticker _ticker;
  Duration _last = Duration.zero;
  bool _tickerActive = false;

  Timer? _spawnTimer;
  final List<_FactoryItem> _items = [];
  int _lives = 3;
  int _score = 0;
  int _combo = 0;
  double _speed = 1.0;
  bool _gameOver = false;
  _WasteItem? _selected;

  // 🐢 Más lento: 11 segundos base de recorrido
  static const double _travelSeconds = 11.0;
  // 🕐 Spawn cada 2.4 segundos (más espaciado)
  static const int _spawnMs = 2400;

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    _items.clear();
    _lives = 3;
    _score = 0;
    _combo = 0;
    _speed = 1.0;
    _gameOver = false;
    _selected = null;
    _spawnTimer?.cancel();
    _last = Duration.zero;
    if (_tickerActive) {
      _ticker.stop();
    }
    _ticker = createTicker(_onTick)..start();
    _tickerActive = true;
    _spawnTimer = Timer.periodic(const Duration(milliseconds: _spawnMs), (_) {
      if (_gameOver) return;
      _spawnItem();
      // 🐢 la velocidad sube MUY lento (máx 1.5)
      _speed = 1.0 + (_score / 60.0).clamp(0.0, 0.5);
    });
    setState(() {});
  }

  void _onTick(Duration elapsed) {
    if (_gameOver) return;
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (dt <= 0) return;
    const baseProgressPerSec = 1.0 / _travelSeconds;
    final remove = <_FactoryItem>[];
    for (final it in _items) {
      it.progress += dt * baseProgressPerSec * _speed;
      if (it.progress >= 1.0) remove.add(it);
    }
    if (remove.isNotEmpty) {
      setState(() {
        for (final r in remove) {
          if (_selected == r.waste) _selected = null;
          _items.remove(r);
          _lives--;
          _combo = 0;
        }
        if (_lives <= 0) _endGame();
      });
      _Sfx.wrong();
    } else if (_items.isNotEmpty) {
      setState(() {});
    }
  }

  void _spawnItem() {
    final waste = _allWaste[_rnd.nextInt(_allWaste.length)];
    setState(() {
      _items.add(_FactoryItem(waste: waste, progress: 0.0));
    });
  }

  void _selectItem(_FactoryItem it) {
    _Sfx.click();
    setState(() => _selected = it.waste);
  }

  void _classify(WasteCategory category) {
    if (_gameOver || _selected == null) return;
    final target = _items.firstWhere(
      (it) => it.waste == _selected,
      orElse: () => _FactoryItem(waste: _allWaste.first, progress: -1),
    );
    if (target.progress < 0) {
      setState(() => _selected = null);
      return;
    }
    if (target.waste.category == category) {
      _Sfx.correct();
      setState(() {
        _score += 10 + (_combo * 2);
        _combo++;
        _items.remove(target);
        _selected = null;
      });
    } else {
      _Sfx.wrong();
      setState(() {
        _lives--;
        _combo = 0;
        _items.remove(target);
        _selected = null;
      });
      if (_lives <= 0) _endGame();
    }
  }

  void _endGame() {
    _gameOver = true;
    _spawnTimer?.cancel();
    if (_tickerActive) {
      _ticker.stop();
      _tickerActive = false;
    }
    final provider = context.read<EcoGamesProvider>();
    provider.registerScore('eco_factory', _score);
    provider.addStars(2 + (_combo ~/ 5));
    _Sfx.win();
    setState(() {});
  }

  Color _catColor(WasteCategory c) {
    switch (c) {
      case WasteCategory.organic:
        return const Color(0xFF43A047);
      case WasteCategory.paper:
        return const Color(0xFF1E88E5);
      case WasteCategory.plastic:
        return const Color(0xFFFFB300);
      case WasteCategory.special:
        return const Color(0xFFE53935);
    }
  }

  String _catLabel(WasteCategory c) {
    switch (c) {
      case WasteCategory.organic:
        return 'Orgánico';
      case WasteCategory.paper:
        return 'Papel';
      case WasteCategory.plastic:
        return 'Plástico';
      case WasteCategory.special:
        return 'Especial';
    }
  }

  IconData _catIcon(WasteCategory c) {
    switch (c) {
      case WasteCategory.organic:
        return Icons.eco;
      case WasteCategory.paper:
        return Icons.article;
      case WasteCategory.plastic:
        return Icons.local_drink;
      case WasteCategory.special:
        return Icons.battery_alert;
    }
  }

  @override
  void dispose() {
    _spawnTimer?.cancel();
    if (_tickerActive) _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8F5E9),
      body: SafeArea(
        child: Column(
          children: [
            _GameScaffoldBar(
              title: 'Eco-Factory',
              trailing: Row(
                children: [
                  _HudPill(
                      icon: Icons.favorite,
                      color: Colors.red,
                      value: '$_lives'),
                  const SizedBox(width: 8),
                  _HudPill(
                      icon: Icons.star,
                      color: Colors.amber,
                      value: '$_score'),
                ],
              ),
            ),
            Expanded(
              flex: 3,
              child: Container(
                margin: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF455A64), Color(0xFF263238)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 16,
                        offset: const Offset(0, 8)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                            painter: _FactoryBackgroundPainter()),
                      ),
                      Positioned(
                        left: 0,
                        right: 0,
                        top: 8,
                        bottom: 60,
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [
                                Color(0xFF9E9E9E),
                                Color(0xFF616161),
                              ],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                                color: Colors.black26, width: 3),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              children: [
                                Positioned.fill(
                                  child: CustomPaint(
                                    painter: _ConveyorPainter(
                                        _last.inMicroseconds / 1e6),
                                  ),
                                ),
                                ..._items.map((it) {
                                  final w = MediaQuery.of(context)
                                          .size
                                          .width -
                                      80;
                                  return Positioned(
                                    left: 8 + it.progress * w,
                                    top: 16 +
                                        (it.waste.name.hashCode % 40)
                                            .toDouble(),
                                    child: _DraggableWasteChip(
                                      waste: it.waste,
                                      selected: _selected == it.waste,
                                      onTap: () => _selectItem(it),
                                    ),
                                  );
                                }),
                                if (_items.isEmpty)
                                  const Center(
                                    child: Text(
                                      'Esperando residuos...',
                                      style: TextStyle(
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 14,
                        left: 14,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.bolt,
                                  color: Colors.deepOrange, size: 16),
                              const SizedBox(width: 4),
                              Text('Combo x$_combo',
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                      ),
                      if (_selected != null)
                        Positioned(
                          top: 14,
                          right: 14,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: _selected!.bg,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                Icon(_selected!.icon,
                                    color: _selected!.color, size: 16),
                                const SizedBox(width: 4),
                                Text(_selected!.name,
                                    style: TextStyle(
                                        color: _selected!.color,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                _selected == null
                    ? 'Toca un residuo y luego el tacho correcto'
                    : 'Ahora toca el tacho correcto 👇',
                style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 13,
                    fontWeight: FontWeight.w600),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Row(
                  children: WasteCategory.values.map((cat) {
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: _BinButton(
                          label: _catLabel(cat),
                          icon: _catIcon(cat),
                          color: _catColor(cat),
                          onTap: () => _classify(cat),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DraggableWasteChip extends StatelessWidget {
  final _WasteItem waste;
  final bool selected;
  final VoidCallback onTap;
  const _DraggableWasteChip({
    required this.waste,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: selected ? waste.bg : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
              color: selected ? waste.color : Colors.black12,
              width: selected ? 3 : 1),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: selected ? 10 : 4,
                offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(waste.icon, color: waste.color, size: 28),
            const SizedBox(height: 2),
            SizedBox(
              width: 60,
              child: Text(waste.name,
                  textAlign: TextAlign.center,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                  style: const TextStyle(
                      fontSize: 7.5,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _BinButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _BinButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.65)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.45),
                blurRadius: 10,
                offset: const Offset(0, 5)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConveyorPainter extends CustomPainter {
  final double t;
  _ConveyorPainter(this.t);
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.18)
      ..strokeWidth = 3;
    const step = 45.0;
    final offset = (t * 60) % step;
    for (double x = -step + offset; x < size.width + step; x += step) {
      canvas.drawLine(
        Offset(x, size.height * 0.15),
        Offset(x + 22, size.height * 0.85),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ConveyorPainter old) => old.t != t;
}

class _FactoryBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final pipe = Paint()
      ..color = Colors.grey.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round;
    final path = Path()
      ..moveTo(0, 30)
      ..lineTo(size.width * 0.35, 30)
      ..lineTo(size.width * 0.4, 60)
      ..lineTo(size.width, 60);
    canvas.drawPath(path, pipe);

    final rivet = Paint()..color = Colors.grey.shade500;
    for (double x = 12; x < size.width; x += 40) {
      canvas.drawCircle(Offset(x, 12), 3, rivet);
    }

    final light = Paint()..color = const Color(0xFFFFEB3B);
    for (double x = 60; x < size.width; x += 120) {
      canvas.drawCircle(Offset(x, 100), 5, light);
      canvas.drawCircle(
          Offset(x, 100),
          14,
          Paint()
            ..color = const Color(0xFFFFEB3B).withOpacity(0.15)
            ..style = PaintingStyle.fill);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => false;
}

// ============================================================================
// 🎯 MINIJUEGO 2: BARRIO LIMPIO (CON VIDAS)
// ============================================================================

class _SceneObject {
  final String id;
  final String name;
  final IconData icon;
  final Alignment position;
  final Color color;
  final List<_ActionOption> options;
  bool resolved = false;

  _SceneObject({
    required this.id,
    required this.name,
    required this.icon,
    required this.position,
    required this.color,
    required this.options,
  });
}

class _ActionOption {
  final String label;
  final bool isCorrect;
  final String feedback;
  const _ActionOption({
    required this.label,
    required this.isCorrect,
    required this.feedback,
  });
}

enum _SceneType { kitchen, park, school }

class BarrioLimpioGame extends StatefulWidget {
  const BarrioLimpioGame({super.key});
  @override
  State<BarrioLimpioGame> createState() => _BarrioLimpioGameState();
}

class _BarrioLimpioGameState extends State<BarrioLimpioGame> {
  int _score = 0;
  int _lives = 3;
  bool _gameOver = false;
  int _sceneIndex = 0;

  final List<_SceneType> _sceneTypes = [
    _SceneType.kitchen,
    _SceneType.park,
    _SceneType.school,
  ];

  final List<List<_SceneObject>> _scenes = [
    [
      _SceneObject(
        id: 'frasco',
        name: 'Frasco de vidrio',
        icon: Icons.wine_bar,
        position: const Alignment(-0.7, -0.5),
        color: const Color(0xFF66BB6A),
        options: const [
          _ActionOption(
              label: 'Tirarlo a la basura común',
              isCorrect: false,
              feedback:
                  'El vidrio es 100% reciclable. ¡Mejor reutilizarlo!'),
          _ActionOption(
              label: 'Reutilizarlo como portalápices',
              isCorrect: true,
              feedback: '¡Excelente! Reutilizar es mejor que reciclar.'),
          _ActionOption(
              label: 'Enterrarlo en el jardín',
              isCorrect: false,
              feedback: 'El vidrio tarda miles de años en degradarse.'),
        ],
      ),
      _SceneObject(
        id: 'cascara',
        name: 'Cáscaras de fruta',
        icon: Icons.apple,
        position: const Alignment(0.5, 0.1),
        color: const Color(0xFF8D6E63),
        options: const [
          _ActionOption(
              label: 'Hacer compost orgánico',
              isCorrect: true,
              feedback: '¡Perfecto! Las cáscaras son abono natural.'),
          _ActionOption(
              label: 'Tirarlas al inodoro',
              isCorrect: false,
              feedback: 'No, eso tapa las tuberías.'),
          _ActionOption(
              label: 'Quemarlas',
              isCorrect: false,
              feedback: 'Quemar genera contaminación del aire.'),
        ],
      ),
      _SceneObject(
        id: 'bolsa',
        name: 'Bolsa de plástico',
        icon: Icons.shopping_bag,
        position: const Alignment(0.7, -0.6),
        color: const Color(0xFFFFA726),
        options: const [
          _ActionOption(
              label: 'Lavarla y reutilizarla',
              isCorrect: true,
              feedback: '¡Muy bien! Reutilizar reduce el consumo.'),
          _ActionOption(
              label: 'Tirarla al mar',
              isCorrect: false,
              feedback: '¡Nunca! Daña la fauna marina.'),
        ],
      ),
    ],
    [
      _SceneObject(
        id: 'lata',
        name: 'Lata de refresco',
        icon: Icons.local_drink,
        position: const Alignment(-0.6, 0.2),
        color: const Color(0xFFEF5350),
        options: const [
          _ActionOption(
              label: 'Reciclarla en tacho amarillo',
              isCorrect: true,
              feedback:
                  '¡Correcto! Las latas van al contenedor amarillo.'),
          _ActionOption(
              label: 'Dejarla en el pasto',
              isCorrect: false,
              feedback: 'Nunca dejes basura en espacios públicos.'),
        ],
      ),
      _SceneObject(
        id: 'papel',
        name: 'Periódico viejo',
        icon: Icons.article,
        position: const Alignment(0.4, -0.3),
        color: const Color(0xFF795548),
        options: const [
          _ActionOption(
              label: 'Reciclarlo en el azul',
              isCorrect: true,
              feedback: '¡Perfecto! Papel y cartón van al azul.'),
          _ActionOption(
              label: 'Quemarlo',
              isCorrect: false,
              feedback: 'Genera contaminación. Mejor reciclar.'),
        ],
      ),
    ],
    [
      _SceneObject(
        id: 'cuaderno',
        name: 'Cuaderno usado',
        icon: Icons.menu_book,
        position: const Alignment(-0.4, 0.2),
        color: const Color(0xFF42A5F5),
        options: const [
          _ActionOption(
              label: 'Usar las hojas sobrantes',
              isCorrect: true,
              feedback:
                  '¡Bien! Reutilizar el papel reduce el consumo.'),
          _ActionOption(
              label: 'Tirarlo todo a la basura',
              isCorrect: false,
              feedback: 'Mejor separa las hojas para reciclar.'),
        ],
      ),
      _SceneObject(
        id: 'botella',
        name: 'Botella PET',
        icon: Icons.local_drink,
        position: const Alignment(0.6, -0.1),
        color: const Color(0xFF26C6DA),
        options: const [
          _ActionOption(
              label: 'Reutilizarla como botella',
              isCorrect: true,
              feedback: '¡Genial! Reutilizar es la mejor opción.'),
          _ActionOption(
              label: 'Tirarla al piso',
              isCorrect: false,
              feedback: '¡Nunca! Busca un tacho para reciclarla.'),
        ],
      ),
    ],
  ];

  List<_SceneObject> get _currentScene => _scenes[_sceneIndex];
  int get _resolvedCount =>
      _currentScene.where((o) => o.resolved).length;
  int get _totalObjects => _currentScene.length;

  void _openObject(_SceneObject obj) {
    if (obj.resolved || _gameOver) return;
    _Sfx.click();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _ActionSheet(
        object: obj,
        onSelected: (opt) {
          Navigator.of(context).pop();
          if (!mounted || _gameOver) return;
          setState(() {
            obj.resolved = true;
            if (opt.isCorrect) {
              _score += 15;
              _Sfx.correct();
            } else {
              _lives--;
              _Sfx.wrong();
            }
          });
          _showFeedback(opt.feedback, opt.isCorrect);
          if (_lives <= 0) {
            _endGame();
            return;
          }
          if (_resolvedCount == _totalObjects) _nextScene();
        },
      ),
    );
  }

  void _showFeedback(String text, bool success) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(success ? Icons.check_circle : Icons.error,
                color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(text)),
          ],
        ),
        backgroundColor:
            success ? Colors.green.shade700 : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _nextScene() {
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted || _gameOver) return;
      if (_sceneIndex < _scenes.length - 1) {
        setState(() => _sceneIndex++);
      } else {
        final provider = context.read<EcoGamesProvider>();
        provider.registerScore('barrio_limpio', _score);
        provider.addStars(3);
        _Sfx.win();
        _showWinDialog();
      }
    });
  }

  void _endGame() {
    _gameOver = true;
    final provider = context.read<EcoGamesProvider>();
    provider.registerScore('barrio_limpio', _score);
    _Sfx.wrong();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.heart_broken,
                size: 64, color: Colors.red),
            const SizedBox(height: 8),
            const Text('¡Sin vidas!',
                style: TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Puntuación: $_score'),
            const SizedBox(height: 8),
            Text('Las 3R requieren práctica. ¡Inténtalo de nuevo!',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.grey.shade700, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Menú'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _restart();
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  void _restart() {
    setState(() {
      _score = 0;
      _lives = 3;
      _gameOver = false;
      _sceneIndex = 0;
      for (final scene in _scenes) {
        for (final obj in scene) {
          obj.resolved = false;
        }
      }
    });
  }

  void _showWinDialog() {
    final controller =
        ConfettiController(duration: const Duration(seconds: 3));
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Stack(
        alignment: Alignment.topCenter,
        children: [
          AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  height: 120,
                  child: Lottie.network(
                    'https://assets10.lottiefiles.com/packages/lf20_kkflmtur.json',
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.emoji_events,
                        size: 80,
                        color: Colors.amber),
                  ),
                ),
                const SizedBox(height: 8),
                const Text('¡Misión Cumplida!',
                    style: TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Puntuación: $_score',
                    style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 4),
                Text('Vidas restantes: $_lives',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 12)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  controller.dispose();
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('Volver al menú'),
              ),
            ],
          ),
          ConfettiWidget(
            confettiController: controller,
            blastDirectionality: BlastDirectionality.explosive,
            numberOfParticles: 30,
            colors: const [
              Colors.green,
              Colors.blue,
              Colors.amber,
              Colors.orange,
            ],
          ),
        ],
      ),
    );
    controller.play();
  }

  @override
  Widget build(BuildContext context) {
    const names = ['La Cocina', 'El Parque', 'La Escuela'];
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        child: Column(
          children: [
            _GameScaffoldBar(
              title: 'Barrio Limpio · ${names[_sceneIndex]}',
              trailing: Row(
                children: [
                  _HudPill(
                      icon: Icons.favorite,
                      color: Colors.red,
                      value: '$_lives'),
                  const SizedBox(width: 6),
                  _HudPill(
                      icon: Icons.star,
                      color: Colors.amber,
                      value: '$_score'),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Text('Resuelve $_totalObjects situaciones',
                      style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('$_resolvedCount / $_totalObjects',
                        style: TextStyle(
                            color: Colors.green.shade800,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 14,
                        offset: const Offset(0, 6)),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: CustomPaint(
                          painter: _SceneBackgroundPainter(
                              _sceneTypes[_sceneIndex]),
                        ),
                      ),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          return Stack(
                            children: _currentScene.map((obj) {
                              final dx = (obj.position.x + 1) /
                                  2 *
                                  (constraints.maxWidth - 100);
                              final dy = (obj.position.y + 1) /
                                  2 *
                                  (constraints.maxHeight - 100);
                              return Positioned(
                                left: dx,
                                top: dy,
                                child: _SceneItemWidget(
                                  obj: obj,
                                  onTap: () => _openObject(obj),
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SceneBackgroundPainter extends CustomPainter {
  final _SceneType type;
  _SceneBackgroundPainter(this.type);

  @override
  void paint(Canvas canvas, Size size) {
    switch (type) {
      case _SceneType.kitchen:
        _paintKitchen(canvas, size);
        break;
      case _SceneType.park:
        _paintPark(canvas, size);
        break;
      case _SceneType.school:
        _paintSchool(canvas, size);
        break;
    }
  }

  void _paintKitchen(Canvas canvas, Size size) {
    final wall = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFFFF3E0), Color(0xFFFFE0B2)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), wall);

    final floorY = size.height * 0.68;
    final floor = Paint()..color = const Color(0xFFBCAAA4);
    canvas.drawRect(
        Rect.fromLTWH(0, floorY, size.width, size.height - floorY),
        floor);
    final tile = Paint()..color = const Color(0xFFA1887F);
    for (double x = 0; x < size.width; x += 40) {
      for (double y = floorY; y < size.height; y += 30) {
        if (((x / 40).floor() + (y / 30).floor()) % 2 == 0) {
          canvas.drawRect(Rect.fromLTWH(x, y, 40, 30), tile);
        }
      }
    }

    final win = Paint()..color = const Color(0xFFB3E5FC);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.15, 40, size.width * 0.3, 90),
        const Radius.circular(10),
      ),
      win,
    );
    final frame = Paint()
      ..color = const Color(0xFF8D6E63)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.15, 40, size.width * 0.3, 90),
        const Radius.circular(10),
      ),
      frame,
    );
    canvas.drawLine(
        Offset(size.width * 0.3, 40),
        Offset(size.width * 0.3, 130),
        frame);

    final shelf = Paint()..color = const Color(0xFF6D4C41);
    canvas.drawRect(
        Rect.fromLTWH(size.width * 0.6, 80, size.width * 0.3, 8),
        shelf);

    final fridge = Paint()..color = const Color(0xFFECEFF1);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.75, 100, 60, 120),
        const Radius.circular(8),
      ),
      fridge,
    );
    final fridgeLine = Paint()
      ..color = Colors.grey.shade400
      ..strokeWidth = 2;
    canvas.drawLine(Offset(size.width * 0.75, 140),
        Offset(size.width * 0.75 + 60, 140), fridgeLine);
  }

  void _paintPark(Canvas canvas, Size size) {
    final sky = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF81D4FA), Color(0xFFB3E5FC)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height * 0.55));
    canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height * 0.55), sky);

    canvas.drawCircle(Offset(size.width * 0.85, 50), 26,
        Paint()..color = const Color(0xFFFFEB3B));
    canvas.drawCircle(
        Offset(size.width * 0.85, 50),
        40,
        Paint()
          ..color = const Color(0xFFFFEB3B).withOpacity(0.3));

    final cloud = Paint()..color = Colors.white;
    for (double x = 40; x < size.width; x += 120) {
      canvas.drawCircle(Offset(x, 60), 18, cloud);
      canvas.drawCircle(Offset(x + 22, 60), 24, cloud);
      canvas.drawCircle(Offset(x + 44, 60), 16, cloud);
    }

    final trunk = Paint()..color = const Color(0xFF5D4037);
    final leaves = Paint()..color = const Color(0xFF388E3C);
    for (double x = 40; x < size.width; x += 140) {
      canvas.drawRect(
          Rect.fromLTWH(x, size.height * 0.42, 12, size.height * 0.2),
          trunk);
      canvas.drawCircle(
          Offset(x + 6, size.height * 0.4), 30, leaves);
    }

    final grass = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFF8BC34A), Color(0xFF558B2F)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(
          0, size.height * 0.6, size.width, size.height * 0.4));
    canvas.drawRect(
        Rect.fromLTWH(0, size.height * 0.6, size.width,
            size.height * 0.4),
        grass);

    final path = Paint()..color = const Color(0xFFBCAAA4);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(size.width * 0.5, size.height * 0.85),
        width: size.width * 0.7,
        height: size.height * 0.25,
      ),
      path,
    );
  }

  void _paintSchool(Canvas canvas, Size size) {
    final wall = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), wall);

    final floorY = size.height * 0.7;
    canvas.drawRect(
        Rect.fromLTWH(0, floorY, size.width, size.height - floorY),
        Paint()..color = const Color(0xFFFFF59D));

    final board = Paint()..color = const Color(0xFF2E7D32);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.1, 30, size.width * 0.5, 100),
        const Radius.circular(6),
      ),
      board,
    );
    final boardFrame = Paint()
      ..color = const Color(0xFF5D4037)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 6;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.1, 30, size.width * 0.5, 100),
        const Radius.circular(6),
      ),
      boardFrame,
    );

    final chalk = Paint()
      ..color = Colors.white70
      ..strokeWidth = 2;
    for (int i = 0; i < 3; i++) {
      canvas.drawLine(
        Offset(size.width * 0.15, 55.0 + i * 22),
        Offset(size.width * 0.45, 55.0 + i * 22),
        chalk,
      );
    }

    final desk = Paint()..color = const Color(0xFF8D6E63);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.65, 120, size.width * 0.28, 40),
        const Radius.circular(6),
      ),
      desk,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.7, 20, 80, 70),
        const Radius.circular(6),
      ),
      Paint()..color = const Color(0xFFB3E5FC),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.7, 20, 80, 70),
        const Radius.circular(6),
      ),
      Paint()
        ..color = const Color(0xFF795548)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3,
    );
  }

  @override
  bool shouldRepaint(covariant _SceneBackgroundPainter old) =>
      old.type != type;
}

class _SceneItemWidget extends StatelessWidget {
  final _SceneObject obj;
  final VoidCallback onTap;
  const _SceneItemWidget({required this.obj, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        opacity: obj.resolved ? 0.35 : 1,
        duration: const Duration(milliseconds: 300),
        child: Column(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: obj.resolved ? Colors.grey.shade300 : obj.color,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
                boxShadow: [
                  BoxShadow(
                      color: obj.color.withOpacity(0.5),
                      blurRadius: 14,
                      offset: const Offset(0, 6)),
                ],
              ),
              child: Icon(
                obj.resolved ? Icons.check : obj.icon,
                color: Colors.white,
                size: 34,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4),
                ],
              ),
              child: Text(obj.name,
                  style: const TextStyle(
                      fontSize: 10, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionSheet extends StatelessWidget {
  final _SceneObject object;
  final Function(_ActionOption) onSelected;
  const _ActionSheet({required this.object, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(object.icon, color: object.color, size: 30),
              const SizedBox(width: 10),
              Expanded(
                child: Text(object.name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text('¿Qué harías con este residuo?',
              style: TextStyle(fontSize: 14, color: Colors.black54)),
          const SizedBox(height: 12),
          ...object.options.map(
            (opt) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => onSelected(opt),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    child: Row(
                      children: [
                        const Icon(Icons.arrow_forward_ios,
                            size: 14, color: Colors.black45),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(opt.label,
                              style: const TextStyle(fontSize: 14)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 🎯 MINIJUEGO 3: ECO-CRAFT
// ============================================================================

class _Recipe {
  final String name;
  final IconData icon;
  final Map<String, int> inputs;
  final Color color;
  const _Recipe({
    required this.name,
    required this.icon,
    required this.inputs,
    required this.color,
  });

  int get coinReward {
    int total = 0;
    for (final q in inputs.values) {
      total += q * 5;
    }
    total += (inputs.length - 1) * 8;
    return total;
  }
}

class EcoCraftWidget extends StatefulWidget {
  const EcoCraftWidget({super.key});
  @override
  State<EcoCraftWidget> createState() => _EcoCraftWidgetState();
}

class _EcoCraftWidgetState extends State<EcoCraftWidget> {
  final Map<String, int> _inventory = {
    'PET': 20,
    'Tela': 14,
    'Papel': 16,
    'Vidrio': 12,
    'Orgánico': 18,
  };

  int _score = 0;
  String? _crafting;
  String? _resultName;
  IconData? _resultIcon;
  Timer? _craftTimer;

  static const List<_Recipe> _recipes = [
    _Recipe(
      name: 'Mochila Ecológica',
      icon: Icons.backpack,
      inputs: {'PET': 5, 'Tela': 4},
      color: Color(0xFF43A047),
    ),
    _Recipe(
      name: 'Hilo Sintético',
      icon: Icons.linear_scale,
      inputs: {'PET': 3},
      color: Color(0xFF29B6F6),
    ),
    _Recipe(
      name: 'Abono Orgánico',
      icon: Icons.eco,
      inputs: {'Orgánico': 5},
      color: Color(0xFF8BC34A),
    ),
    _Recipe(
      name: 'Cuaderno Reciclado',
      icon: Icons.book,
      inputs: {'Papel': 4},
      color: Color(0xFFFFB300),
    ),
    _Recipe(
      name: 'Vaso Artesanal',
      icon: Icons.local_drink,
      inputs: {'Vidrio': 3},
      color: Color(0xFF7E57C2),
    ),
    _Recipe(
      name: 'Maceta Decorada',
      icon: Icons.yard,
      inputs: {'Vidrio': 2, 'Tela': 2, 'Orgánico': 3},
      color: Color(0xFF26A69A),
    ),
  ];

  bool _canCraft(_Recipe r) {
    return r.inputs.entries
        .every((e) => (_inventory[e.key] ?? 0) >= e.value);
  }

  void _craft(_Recipe r) {
    if (!_canCraft(r)) return;
    _Sfx.click();
    setState(() {
      for (final e in r.inputs.entries) {
        _inventory[e.key] = (_inventory[e.key] ?? 0) - e.value;
      }
      _crafting = r.name;
    });
    _craftTimer?.cancel();
    _craftTimer = Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      setState(() {
        _crafting = null;
        _resultName = r.name;
        _resultIcon = r.icon;
        _score += 20;
      });
      final coins = r.coinReward;
      final provider = context.read<EcoGamesProvider>();
      provider.registerScore('eco_craft', _score);
      provider.addStars(1);
      provider.addCoins(coins);
      _Sfx.correct();
      _showProductDialog(r, coins);
    });
  }

  void _showProductDialog(_Recipe r, int coins) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(r.icon, size: 64, color: r.color),
            const SizedBox(height: 12),
            Text('¡${r.name} fabricado!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFD54F), Color(0xFFFFB300)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.monetization_on_rounded,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 6),
                  Text('+$coins monedas',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Has transformado residuos en un nuevo producto. ¡Así funciona la economía circular!',
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _craftTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EcoGamesProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8E1),
      body: SafeArea(
        child: Column(
          children: [
            _GameScaffoldBar(
              title: 'Eco-Craft',
              trailing: Row(
                children: [
                  _HudPill(
                      icon: Icons.star,
                      color: Colors.amber,
                      value: '$_score'),
                  const SizedBox(width: 8),
                  _HudPill(
                      icon: Icons.monetization_on_rounded,
                      color: Colors.orange,
                      value: '${provider.totalCoins}'),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  const Text('📦 Materias Primas',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: _inventory.entries
                        .map((e) =>
                            _InventoryChip(name: e.key, count: e.value))
                        .toList(),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFCC80), Color(0xFFFFB74D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.orange.withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 8)),
                      ],
                    ),
                    child: SizedBox(
                      height: 100,
                      child: Center(
                        child: _crafting != null
                            ? Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  const CircularProgressIndicator(
                                      color: Colors.white),
                                  const SizedBox(height: 8),
                                  Text('Procesando $_crafting...',
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight:
                                              FontWeight.bold)),
                                ],
                              )
                            : _resultName != null
                                ? Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(_resultIcon,
                                          size: 44,
                                          color: Colors.white),
                                      const SizedBox(height: 4),
                                      Text(_resultName!,
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight:
                                                  FontWeight.bold)),
                                    ],
                                  )
                                : const Text(
                                    '🏭 Máquina de Procesamiento\nSelecciona una receta 👇',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600),
                                  ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('⚙️ Recetas Disponibles',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 10),
                  ..._recipes.map((r) {
                    final can = _canCraft(r);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: r.color.withOpacity(0.3), width: 2),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: r.color.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child:
                                  Icon(r.icon, color: r.color, size: 28),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(r.name,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14)),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 6,
                                    runSpacing: 4,
                                    children: [
                                      ...r.inputs.entries.map((e) =>
                                          Container(
                                            padding: const EdgeInsets
                                                .symmetric(
                                                horizontal: 6,
                                                vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.grey.shade200,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      8),
                                            ),
                                            child: Text(
                                                '${e.value}x ${e.key}',
                                                style: const TextStyle(
                                                    fontSize: 10)),
                                          )),
                                      Container(
                                        padding: const EdgeInsets
                                            .symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color:
                                              Colors.orange.shade100,
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          mainAxisSize:
                                              MainAxisSize.min,
                                          children: [
                                            Icon(
                                                Icons
                                                    .monetization_on_rounded,
                                                size: 10,
                                                color: Colors
                                                    .orange.shade800),
                                            const SizedBox(width: 2),
                                            Text(
                                                '+${r.coinReward}',
                                                style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.bold,
                                                    color: Colors
                                                        .orange.shade800)),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            ElevatedButton(
                              onPressed:
                                  can && _crafting == null
                                      ? () => _craft(r)
                                      : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: r.color,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor:
                                    Colors.grey.shade300,
                                shape: RoundedRectangleBorder(
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text('Crear'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InventoryChip extends StatelessWidget {
  final String name;
  final int count;
  const _InventoryChip({required this.name, required this.count});

  @override
  Widget build(BuildContext context) {
    final colors = {
      'PET': Colors.blue,
      'Tela': Colors.pink,
      'Papel': Colors.brown,
      'Vidrio': Colors.teal,
      'Orgánico': Colors.green,
    };
    final c = colors[name] ?? Colors.grey;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: c.withOpacity(0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: c.withOpacity(0.3), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inventory_2, color: c, size: 16),
          const SizedBox(width: 6),
          Text('$name: $count',
              style: TextStyle(
                  color: c,
                  fontWeight: FontWeight.bold,
                  fontSize: 13)),
        ],
      ),
    );
  }
}

// ============================================================================
// 🎯 MINIJUEGO 4: ECO-RUNNER (CORREGIDO)
// ============================================================================

class _RunnerItem {
  final WasteCategory category;
  final IconData icon;
  final int lane;
  double y;
  final double speed;
  _RunnerItem({
    required this.category,
    required this.icon,
    required this.lane,
    required this.y,
    required this.speed,
  });
}

class EcoRunnerGame extends StatefulWidget {
  const EcoRunnerGame({super.key});
  @override
  State<EcoRunnerGame> createState() => _EcoRunnerGameState();
}

class _EcoRunnerGameState extends State<EcoRunnerGame>
    with SingleTickerProviderStateMixin {
  final math.Random _rnd = math.Random();
  late Ticker _ticker;
  Duration _last = Duration.zero;
  Timer? _spawn;
  Timer? _timeLeft;
  Timer? _targetTimer;

  final List<_RunnerItem> _items = [];
  int _score = 0;
  int _lives = 3;
  int _timeLeftSec = 30;
  WasteCategory? _target;
  bool _gameOver = false;
  bool _tickerActive = false;

  // 🐢 Más lento para que el jugador pueda reaccionar
  static const double _baseSpeed = 0.22;
  static const int _spawnMs = 950;

  static const Map<WasteCategory, _WasteItem> _targetWaste = {
    WasteCategory.plastic: _WasteItem(
        name: 'Plástico',
        icon: Icons.local_drink,
        category: WasteCategory.plastic,
        color: Color(0xFFFFB300),
        bg: Color(0xFFFFF8E1)),
    WasteCategory.paper: _WasteItem(
        name: 'Papel',
        icon: Icons.article,
        category: WasteCategory.paper,
        color: Color(0xFF1E88E5),
        bg: Color(0xFFE3F2FD)),
    WasteCategory.organic: _WasteItem(
        name: 'Orgánico',
        icon: Icons.eco,
        category: WasteCategory.organic,
        color: Color(0xFF43A047),
        bg: Color(0xFFE8F5E9)),
    WasteCategory.special: _WasteItem(
        name: 'Especial',
        icon: Icons.battery_alert,
        category: WasteCategory.special,
        color: Color(0xFFE53935),
        bg: Color(0xFFFFEBEE)),
  };

  @override
  void initState() {
    super.initState();
    _startGame();
  }

  void _startGame() {
    _items.clear();
    _score = 0;
    _lives = 3;
    _timeLeftSec = 30;
    _gameOver = false;
    _last = Duration.zero;
    _spawn?.cancel();
    _timeLeft?.cancel();
    _targetTimer?.cancel();
    if (_tickerActive) {
      _ticker.stop();
    }
    _ticker = createTicker(_onTick)..start();
    _tickerActive = true;

    _newTarget();

    // 🎯 Cambia de objetivo cada 10 segundos (no al azar) para que sea justo
    _targetTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_gameOver) return;
      setState(() {
        _newTarget();
        // Limpia items para dar respiro al jugador cuando cambia target
        _items.removeWhere((it) => it.category != _target);
      });
    });

    _spawn = Timer.periodic(const Duration(milliseconds: _spawnMs), (_) {
      if (_gameOver) return;
      _spawnItem();
    });
    _timeLeft = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_gameOver) return;
      setState(() {
        _timeLeftSec--;
        if (_timeLeftSec <= 0) _endGame(win: true);
      });
    });

    setState(() {});
  }

  void _newTarget() {
    _target =
        WasteCategory.values[_rnd.nextInt(WasteCategory.values.length)];
  }

  void _spawnItem() {
    final cat =
        WasteCategory.values[_rnd.nextInt(WasteCategory.values.length)];
    final lane = _rnd.nextInt(3);
    final iconPool = {
      WasteCategory.plastic: [Icons.local_drink, Icons.shopping_bag],
      WasteCategory.paper: [Icons.article, Icons.menu_book],
      WasteCategory.organic: [Icons.apple, Icons.eco],
      WasteCategory.special: [
        Icons.battery_alert,
        Icons.medical_services
      ],
    };
    final icons = iconPool[cat]!;
    setState(() {
      _items.add(_RunnerItem(
        category: cat,
        icon: icons[_rnd.nextInt(icons.length)],
        lane: lane,
        y: -0.1,
        speed: _baseSpeed + _rnd.nextDouble() * 0.06,
      ));
    });
  }

  void _onTick(Duration elapsed) {
    if (_gameOver) return;
    final dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (dt <= 0 || dt > 0.2) return;

    final remove = <_RunnerItem>[];
    for (final it in _items) {
      it.y += it.speed * dt;
      if (it.y >= 1.0) remove.add(it);
    }
    if (remove.isNotEmpty) {
      // ⚠️ SOLO pierdes vida si DEJAS PASAR un residuo OBJETIVO.
      // Los distractores que caen NO te penalizan (son irrelevantes).
      int penalties = 0;
      setState(() {
        for (final r in remove) {
          _items.remove(r);
          if (r.category == _target) {
            _lives--;
            penalties++;
          }
        }
      });
      if (penalties > 0) {
        _Sfx.wrong();
        if (_lives <= 0) _endGame(win: false);
      }
    } else if (_items.isNotEmpty) {
      setState(() {});
    }
  }

  void _tapItem(_RunnerItem it) {
    if (_gameOver) return;
    if (it.category == _target) {
      _Sfx.correct();
      setState(() {
        _score += 10;
        _items.remove(it);
      });
    } else {
      // ❌ Tocar un distractor SÍ penaliza
      _Sfx.wrong();
      setState(() {
        _lives--;
        _items.remove(it);
      });
      if (_lives <= 0) _endGame(win: false);
    }
  }

  void _endGame({required bool win}) {
    _gameOver = true;
    _spawn?.cancel();
    _timeLeft?.cancel();
    _targetTimer?.cancel();
    if (_tickerActive) {
      _ticker.stop();
      _tickerActive = false;
    }

    final provider = context.read<EcoGamesProvider>();
    provider.registerScore('eco_runner', _score);
    if (win) {
      provider.addStars(2 + (_score ~/ 30));
      _Sfx.win();
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              height: 100,
              child: Lottie.network(
                win
                    ? 'https://assets10.lottiefiles.com/packages/lf20_kkflmtur.json'
                    : 'https://assets2.lottiefiles.com/packages/lf20_ci3vpxsn.json',
                errorBuilder: (_, __, ___) => Icon(
                  win ? Icons.emoji_events : Icons.sentiment_dissatisfied,
                  size: 64,
                  color: win ? Colors.amber : Colors.grey,
                ),
              ),
            ),
            Text(win ? '¡Ronda completada!' : '¡Game Over!',
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('Puntuación: $_score'),
            const SizedBox(height: 4),
            Text('Vidas restantes: $_lives',
                style: TextStyle(
                    color: Colors.grey.shade600, fontSize: 12)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Menú'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              _startGame();
            },
            child: const Text('Reintentar'),
          ),
        ],
      ),
    );
  }

  Color _catColor(WasteCategory c) {
    switch (c) {
      case WasteCategory.organic:
        return const Color(0xFF43A047);
      case WasteCategory.paper:
        return const Color(0xFF1E88E5);
      case WasteCategory.plastic:
        return const Color(0xFFFFB300);
      case WasteCategory.special:
        return const Color(0xFFE53935);
    }
  }

  @override
  void dispose() {
    _spawn?.cancel();
    _timeLeft?.cancel();
    _targetTimer?.cancel();
    if (_tickerActive) _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE3F2FD),
      body: SafeArea(
        child: Column(
          children: [
            _GameScaffoldBar(
              title: 'Eco-Runner',
              trailing: Row(
                children: [
                  _HudPill(
                      icon: Icons.favorite,
                      color: Colors.red,
                      value: '$_lives'),
                  const SizedBox(width: 6),
                  _HudPill(
                      icon: Icons.timer,
                      color: Colors.blue,
                      value: '${_timeLeftSec}s'),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 8),
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _catColor(_target ?? WasteCategory.plastic),
                    _catColor(_target ?? WasteCategory.plastic)
                        .withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                      color:
                          _catColor(_target ?? WasteCategory.plastic)
                              .withOpacity(0.4),
                      blurRadius: 12,
                      offset: const Offset(0, 6)),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                      _targetWaste[_target]?.icon ?? Icons.eco,
                      color: Colors.white,
                      size: 28),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Recolecta solo:',
                            style: TextStyle(
                                color: Colors.white70, fontSize: 11)),
                        Text(
                          _targetWaste[_target]?.name ?? '',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14)),
                    child: Text('$_score',
                        style: TextStyle(
                            color: _catColor(
                                _target ?? WasteCategory.plastic),
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF90CAF9), Color(0xFF42A5F5)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final laneW = constraints.maxWidth / 3;
                      return RepaintBoundary(
                        child: Stack(
                          children: [
                            for (int i = 1; i < 3; i++)
                              Positioned(
                                left: laneW * i - 1,
                                top: 0,
                                bottom: 0,
                                child: Container(
                                  width: 2,
                                  color:
                                      Colors.white.withOpacity(0.35),
                                ),
                              ),
                            ..._items.map((it) {
                              final x =
                                  it.lane * laneW + laneW / 2 - 24;
                              final y = it.y *
                                  (constraints.maxHeight - 48);
                              final isTarget =
                                  it.category == _target;
                              return Positioned(
                                left: x,
                                top: y,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () => _tapItem(it),
                                  child: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: isTarget
                                          ? _catColor(it.category)
                                          : Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                            color: Colors.black
                                                .withOpacity(0.15),
                                            blurRadius: 6,
                                            offset:
                                                const Offset(0, 3)),
                                      ],
                                    ),
                                    child: Icon(
                                      it.icon,
                                      color: isTarget
                                          ? Colors.white
                                          : _catColor(it.category),
                                      size: 26,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}