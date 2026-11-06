import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../utils/constants.dart';

// ═══════════════════════════════════════════════════════════════════════════
//  PALETA ECO-INFANTIL
// ═══════════════════════════════════════════════════════════════════════════
class EcoPalette {
  static const grassGreen = Color(0xFF4CAF50);
  static const skyBlue = Color(0xFF42A5F5);
  static const sunnyYellow = Color(0xFFFFC107);
  static const warmOrange = Color(0xFFFF7043);
  static const earthBrown = Color(0xFF8D6E63);
  static const softPurple = Color(0xFFAB47BC);
  static const bgCream = Color(0xFFF7FBF5);
  static const tealAccent = Color(0xFF26A69A);
  static const pinkAccent = Color(0xFFEC407A);
}

// ═══════════════════════════════════════════════════════════════════════════
//  HELPERS DE RESPONSIVIDAD
// ═══════════════════════════════════════════════════════════════════════════
class _Responsive {
  static bool isSmallPhone(BuildContext c) =>
      MediaQuery.sizeOf(c).width < 360;

  static double hPad(BuildContext c) => isSmallPhone(c) ? 12.0 : 16.0;

  static int gridColumns(BuildContext c) {
    final w = MediaQuery.sizeOf(c).width;
    if (w < 600) return 2;
    if (w < 900) return 3;
    return 4;
  }

  static double gridAspectRatio(BuildContext c) {
    final w = MediaQuery.sizeOf(c).width;
    if (w < 360) return 0.62;
    if (w < 600) return 0.66;
    return 0.72;
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  MODELOS
// ═══════════════════════════════════════════════════════════════════════════
class EcoMaterial {
  final String name;
  final String emoji;
  final Color color;
  final String imageUrl;
  final String funFact;
  final String decompositionTime;
  final double decompositionScore;
  final IconData icon;

  const EcoMaterial({
    required this.name,
    required this.emoji,
    required this.color,
    required this.imageUrl,
    required this.funFact,
    required this.decompositionTime,
    required this.decompositionScore,
    required this.icon,
  });
}

class TimelineEntry {
  final String label;
  final String emoji;
  final String timeText;
  final Color color;
  final String impact;
  final String imageUrl;

  const TimelineEntry({
    required this.label,
    required this.emoji,
    required this.timeText,
    required this.color,
    required this.impact,
    required this.imageUrl,
  });
}

/// Tarjeta de descubrimiento: abre una URL externa (video, audio, artículo...)
class DiscoveryItem {
  final String title;
  final String subtitle;
  final String thumbnailUrl;
  final String externalUrl; // 👈 tú enlazas aquí tus videos/audios reales
  final Color color;
  final DiscoveryKind kind;

  const DiscoveryItem({
    required this.title,
    required this.subtitle,
    required this.thumbnailUrl,
    required this.externalUrl,
    required this.color,
    required this.kind,
  });
}

enum DiscoveryKind { video, audio, article }

class GlossaryTerm {
  final String term;
  final String emoji;
  final String analogy;
  final String definition;
  final Color color;

  const GlossaryTerm({
    required this.term,
    required this.emoji,
    required this.analogy,
    required this.definition,
    required this.color,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
//  DATOS
// ═══════════════════════════════════════════════════════════════════════════
const _materials = <EcoMaterial>[
  EcoMaterial(
    name: 'Plástico',
    emoji: '🧴',
    color: EcoPalette.skyBlue,
    icon: Icons.local_drink_rounded,
    imageUrl:
        'https://images.unsplash.com/photo-1605600659908-0ef719419d41?w=600',
    funFact:
        '¡Una sola botella de plástico puede tardar más de 500 años en desaparecer! '
        'Reciclarla ahorra energía para encender un bombillo por 3 horas.',
    decompositionTime: '500+ años',
    decompositionScore: 0.95,
  ),
  EcoMaterial(
    name: 'Papel y Cartón',
    emoji: '📦',
    color: EcoPalette.sunnyYellow,
    icon: Icons.description_rounded,
    imageUrl:
        'https://images.unsplash.com/photo-1607166452427-7e4477079cb9?w=600',
    funFact:
        'Reciclar 1 tonelada de papel salva 17 árboles. '
        '¡Y el papel puede reciclarse hasta 7 veces!',
    decompositionTime: '2 - 6 meses',
    decompositionScore: 0.2,
  ),
  EcoMaterial(
    name: 'Vidrio',
    emoji: '🍾',
    color: EcoPalette.grassGreen,
    icon: Icons.wine_bar_rounded,
    imageUrl:
        'https://images.unsplash.com/photo-1567696911980-2eed69a46042?w=600',
    funFact:
        'El vidrio es 100% reciclable infinitas veces sin perder calidad. '
        '¡Es como un superhéroe que se regenera siempre!',
    decompositionTime: '4,000+ años',
    decompositionScore: 1.0,
  ),
  EcoMaterial(
    name: 'Orgánicos',
    emoji: '🍌',
    color: EcoPalette.earthBrown,
    icon: Icons.eco_rounded,
    imageUrl:
        'https://images.unsplash.com/photo-1610832958506-aa56368176cf?w=600',
    funFact:
        'Los restos de comida se convierten en compost: ¡el alimento de las plantas! '
        'Es reciclar con la naturaleza.',
    decompositionTime: '2 - 5 semanas',
    decompositionScore: 0.05,
  ),
  EcoMaterial(
    name: 'Electrónicos',
    emoji: '🔋',
    color: EcoPalette.warmOrange,
    icon: Icons.battery_charging_full_rounded,
    imageUrl:
        'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?w=600',
    funFact:
        'Una pila puede contaminar 600,000 litros de agua. '
        '¡Llévalas a puntos especiales, no a la basura normal!',
    decompositionTime: '1,000+ años',
    decompositionScore: 0.98,
  ),
];

const _timelineEntries = <TimelineEntry>[
  TimelineEntry(
    label: 'Cáscara de plátano',
    emoji: '🍌',
    timeText: '2 - 5 semanas',
    color: EcoPalette.earthBrown,
    impact:
        'Se descompone rápido y se convierte en abono natural. '
        '¡Es la comida favorita de los microorganismos del suelo!',
    imageUrl:
        'https://images.unsplash.com/photo-1603833665858-e61d17a86224?w=800',
  ),
  TimelineEntry(
    label: 'Hoja de papel',
    emoji: '📄',
    timeText: '2 - 6 meses',
    color: EcoPalette.sunnyYellow,
    impact:
        'El papel se recicla fácilmente. Reciclarlo ahorra árboles y agua.',
    imageUrl:
        'https://images.unsplash.com/photo-1586075010923-2dd4570fb338?w=800',
  ),
  TimelineEntry(
    label: 'Lata de aluminio',
    emoji: '🥫',
    timeText: '80 - 200 años',
    color: EcoPalette.skyBlue,
    impact:
        'El aluminio es infinitamente reciclable. '
        'Reciclar una lata ahorra energía para escuchar música 3 horas.',
    imageUrl:
        'https://images.unsplash.com/photo-1595246140625-573b715d11dc?w=800',
  ),
  TimelineEntry(
    label: 'Botella de plástico',
    emoji: '🧴',
    timeText: '500+ años',
    color: EcoPalette.skyBlue,
    impact:
        '¡Sobrevive a tus bisnietos! Por eso debemos reciclar cada botella. '
        'Con 25 botellas se hace una camiseta.',
    imageUrl:
        'https://images.unsplash.com/photo-1605600659908-0ef719419d41?w=800',
  ),
  TimelineEntry(
    label: 'Pila / batería',
    emoji: '🔋',
    timeText: '1,000+ años',
    color: EcoPalette.warmOrange,
    impact:
        'Contiene metales pesados. Nunca va a la basura común: '
        'busca un punto de recolección especial.',
    imageUrl:
        'https://images.unsplash.com/photo-1619641805634-b867f535071c?w=800',
  ),
];

// ═══════════════════════════════════════════════════════════════════════════
//  DESCUBRIMIENTO — 4 videos de YouTube (tú pegas los links reales)
// ═══════════════════════════════════════════════════════════════════════════
const _discoveryItems = <DiscoveryItem>[
  DiscoveryItem(
    title: '¿Cómo funciona una planta de reciclaje?',
    subtitle: 'Video educativo · YouTube',
    thumbnailUrl:
        'https://images.unsplash.com/photo-1532996122724-e3c354a0b15b?w=600',
    // 👇 PEGA AQUÍ EL LINK DEL VIDEO 1
    externalUrl: 'https://www.youtube.com/watch?v=Enlmw0NL67c&list=PLTywNBit0lFA1ygWHgnlIyBHATeHYdYB8',
    color: EcoPalette.grassGreen,
    kind: DiscoveryKind.video,
  ),
  DiscoveryItem(
    title: 'El viaje de una botella de plástico',
    subtitle: 'Video animado · YouTube',
    thumbnailUrl:
        'https://images.unsplash.com/photo-1605600659908-0ef719419d41?w=600',
    // 👇 PEGA AQUÍ EL LINK DEL VIDEO 2
    externalUrl: 'https://www.youtube.com/watch?v=17v70o0QkbM',
    color: EcoPalette.skyBlue,
    kind: DiscoveryKind.video,
  ),
  DiscoveryItem(
    title: 'De botella a camiseta',
    subtitle: 'Cápsula educativa · YouTube',
    thumbnailUrl:
        'https://images.unsplash.com/photo-1523381210434-271e8be1f52b?w=600',
    // 👇 PEGA AQUÍ EL LINK DEL VIDEO 3
    externalUrl: 'https://www.youtube.com/watch?v=qvw5Fm1KCeo',
    color: EcoPalette.warmOrange,
    kind: DiscoveryKind.video,
  ),
  DiscoveryItem(
    title: 'Del orgánico al compost',
    subtitle: 'Cápsula educativa · YouTube',
    thumbnailUrl:
        'https://images.unsplash.com/photo-1416879595882-3373a0480b5b?w=600',
    // 👇 PEGA AQUÍ EL LINK DEL VIDEO 4
    externalUrl: 'https://www.youtube.com/watch?v=cIOkj7sMrPo',
    color: EcoPalette.earthBrown,
    kind: DiscoveryKind.video,
  ),
];

// ═══════════════════════════════════════════════════════════════════════════
//  GLOSARIO AMPLIADO (12 términos)
// ═══════════════════════════════════════════════════════════════════════════
const _glossaryTerms = <GlossaryTerm>[
  GlossaryTerm(
    term: 'Compostaje',
    emoji: '🌱',
    color: EcoPalette.earthBrown,
    analogy:
        'Es como hacerle una receta de cocina a la tierra: mezclas restos de '
        'frutas y verduras, y con el tiempo se convierte en un abono nutritivo '
        'que hace crecer plantas felices.',
    definition:
        'Proceso natural donde los restos orgánicos se transforman en abono '
        'para las plantas.',
  ),
  GlossaryTerm(
    term: 'Biodegradable',
    emoji: '🍃',
    color: EcoPalette.grassGreen,
    analogy:
        'Es como un superpoder: un objeto biodegradable puede "desaparecer" '
        'naturalmente porque los microorganismos se lo comen sin dejar basura.',
    definition:
        'Material que puede descomponerse naturalmente gracias a la acción de '
        'bacterias y hongos.',
  ),
  GlossaryTerm(
    term: 'Reutilizar',
    emoji: '♻️',
    color: EcoPalette.skyBlue,
    analogy:
        'Antes de tirar algo, ¡piensa como inventor! Una botella puede ser un '
        'macetero, un lapicero o una regadera. Darle una segunda vida es '
        'reutilizar.',
    definition:
        'Volver a usar un objeto para un propósito distinto en lugar de '
        'desecharlo.',
  ),
  GlossaryTerm(
    term: 'Economía Circular',
    emoji: '🔄',
    color: EcoPalette.softPurple,
    analogy:
        'Es como un juego sin final donde nada se pierde: lo que ya no usas se '
        'convierte en algo nuevo. Así los recursos giran y giran sin gastarse.',
    definition:
        'Modelo donde los materiales se reutilizan y reciclan continuamente, '
        'evitando generar basura.',
  ),
  GlossaryTerm(
    term: 'Reciclaje',
    emoji: '🔁',
    color: EcoPalette.tealAccent,
    analogy:
        'Es como darle una segunda oportunidad a las cosas: transformar una '
        'botella vieja en una nueva botella o en una camiseta, en lugar de '
        'tirarla.',
    definition:
        'Proceso de transformar residuos en nuevos materiales u objetos '
        'útiles.',
  ),
  GlossaryTerm(
    term: 'Reducir',
    emoji: '📉',
    color: EcoPalette.skyBlue,
    analogy:
        'Es como cargar una mochila ligera: si compras solo lo que necesitas '
        'y evitas envoltorios innecesarios, generas menos basura.',
    definition:
        'Disminuir la cantidad de residuos que producimos consumiendo de '
        'forma consciente.',
  ),
  GlossaryTerm(
    term: 'Huella de Carbono',
    emoji: '👣',
    color: EcoPalette.warmOrange,
    analogy:
        'Es como dejar huellas en la arena: cada cosa que usamos (transporte, '
        'comida, luz) deja una "huella" de gases que calientan el planeta. '
        'Menos huella = planeta más fresco.',
    definition:
        'Cantidad de gases de efecto invernadero que genera una persona, '
        'producto o actividad.',
  ),
  GlossaryTerm(
    term: 'Energía Renovable',
    emoji: '☀️',
    color: EcoPalette.sunnyYellow,
    analogy:
        'Es como cargar tu tablet con el sol: la energía del sol, el viento o '
        'el agua se renueva sola y no contamina como el carbón o el petróleo.',
    definition:
        'Energía que proviene de fuentes naturales inagotables como el sol, '
        'el viento o el agua.',
  ),
  GlossaryTerm(
    term: 'Biodiversidad',
    emoji: '🦋',
    color: EcoPalette.pinkAccent,
    analogy:
        'Es como un equipo de fútbol donde cada jugador es distinto: plantas, '
        'animales y hongos forman un equipo donde todos son importantes para '
        'que el ecosistema funcione.',
    definition:
        'Variedad de seres vivos que habitan en un lugar y sus interacciones.',
  ),
  GlossaryTerm(
    term: 'Contaminación',
    emoji: '🚯',
    color: EcoPalette.warmOrange,
    analogy:
        'Es como echarle sal al jugo en vez de azúcar: algo que no debería '
        'estar ahí arruina el resultado. La basura en el río o el humo en el '
        'aire son "sal" para el planeta.',
    definition:
        'Presencia de sustancias o elementos dañinos en el agua, el aire o '
        'el suelo.',
  ),
  GlossaryTerm(
    term: 'Ecosistema',
    emoji: '🌳',
    color: EcoPalette.grassGreen,
    analogy:
        'Es como una gran ciudad natural: los árboles son casas, los ríos son '
        'calles y los animales son vecinos. Si un vecino se va, todos lo '
        'notan.',
    definition:
        'Conjunto de seres vivos y el ambiente físico donde interactúan.',
  ),
  GlossaryTerm(
    term: 'Desarrollo Sostenible',
    emoji: '🌍',
    color: EcoPalette.tealAccent,
    analogy:
        'Es como jugar con un videojuego sin que se acaben las vidas: usamos '
        'los recursos pensando en que las próximas generaciones también '
        'puedan disfrutarlos.',
    definition:
        'Forma de desarrollo que satisface las necesidades actuales sin '
        'comprometer las futuras.',
  ),
];

// ═══════════════════════════════════════════════════════════════════════════
//  PANTALLA PRINCIPAL
// ═══════════════════════════════════════════════════════════════════════════
class EcoEncartaScreen extends StatefulWidget {
  const EcoEncartaScreen({super.key});

  @override
  State<EcoEncartaScreen> createState() => _EcoEncartaScreenState();
}

class _EcoEncartaScreenState extends State<EcoEncartaScreen>
    with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: EcoPalette.bgCream,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context),
            _buildTabBar(context),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const BouncingScrollPhysics(),
                children: const [
                  _EcoSearcherTab(),
                  _TimelineTab(),
                  _DiscoveryCornerTab(),
                  _GlossaryTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final isSmall = _Responsive.isSmallPhone(context);
    final pad = _Responsive.hPad(context);
    return Padding(
      padding: EdgeInsets.fromLTRB(pad, AppSpacing.small, pad, 4),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isSmall ? 8 : 10),
            decoration: BoxDecoration(
              color: EcoPalette.grassGreen.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.eco_rounded,
              color: EcoPalette.grassGreen,
              size: isSmall ? 22 : 28,
            ),
          ),
          SizedBox(width: isSmall ? 8 : 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'EcoEncarta',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.heading1.copyWith(
                    color: EcoPalette.grassGreen,
                    fontSize: isSmall ? 20 : 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '¡Aprende reciclando!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.body.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: isSmall ? 11 : 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final isSmall = _Responsive.isSmallPhone(context);
    final pad = _Responsive.hPad(context);
    final tabs = [
      _TabData('Buscador', 'Eco-Buscador', Icons.search_rounded),
      _TabData('Tiempo', 'Línea del Tiempo', Icons.timeline_rounded),
      _TabData('Descubre', 'Descubrimiento', Icons.play_circle_fill_rounded),
      _TabData('Glosario', 'Glosario', Icons.menu_book_rounded),
    ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: pad, vertical: 6),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicator: BoxDecoration(
          color: EcoPalette.grassGreen,
          borderRadius: BorderRadius.circular(12),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: AppColors.textSecondary,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: isSmall ? 11 : 12,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: isSmall ? 11 : 12,
        ),
        dividerColor: Colors.transparent,
        padding: EdgeInsets.zero,
        labelPadding: EdgeInsets.symmetric(horizontal: isSmall ? 8 : 10),
        tabs: tabs
            .map(
              (t) => Tab(
                height: 38,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(t.icon, size: isSmall ? 14 : 16),
                    const SizedBox(width: 5),
                    Text(isSmall ? t.shortLabel : t.label),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TabData {
  final String shortLabel;
  final String label;
  final IconData icon;
  const _TabData(this.shortLabel, this.label, this.icon);
}

// ═══════════════════════════════════════════════════════════════════════════
//  TAB 1 — ECO-BUSCADOR
// ═══════════════════════════════════════════════════════════════════════════
class _EcoSearcherTab extends StatelessWidget {
  const _EcoSearcherTab();

  @override
  Widget build(BuildContext context) {
    final cols = _Responsive.gridColumns(context);
    final pad = _Responsive.hPad(context);

    return AnimationLimiter(
      child: GridView.builder(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(pad),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: cols,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: _Responsive.gridAspectRatio(context),
        ),
        itemCount: _materials.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 450),
            columnCount: cols,
            child: ScaleAnimation(
              child: FadeInAnimation(
                child: _EcoCardWidget(material: _materials[index]),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _EcoCardWidget extends StatelessWidget {
  final EcoMaterial material;
  const _EcoCardWidget({required this.material});

  @override
  Widget build(BuildContext context) {
    final isSmall = _Responsive.isSmallPhone(context);
    return GestureDetector(
      onTap: () => _showMaterialDetail(context, material),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: material.color.withOpacity(0.18),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 5,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: material.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: material.color.withOpacity(0.15),
                        child: Center(
                          child: SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: material.color,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: material.color.withOpacity(0.2),
                        child: Icon(
                          material.icon,
                          size: 38,
                          color: material.color,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.92),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          material.emoji,
                          style: TextStyle(fontSize: isSmall ? 13 : 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                flex: 4,
                child: Padding(
                  padding: EdgeInsets.all(isSmall ? 7 : 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Flexible(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              material.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: isSmall ? 12 : 14,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              material.decompositionTime,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: material.color,
                                fontSize: isSmall ? 9.5 : 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(
                        height: isSmall ? 26 : 30,
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: material.color,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.zero,
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          onPressed: () =>
                              _showMaterialDetail(context, material),
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Explorar',
                              style: TextStyle(
                                fontSize: isSmall ? 11 : 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showMaterialDetail(BuildContext context, EcoMaterial material) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MaterialDetailSheet(material: material),
    );
  }
}

class _MaterialDetailSheet extends StatelessWidget {
  final EcoMaterial material;
  const _MaterialDetailSheet({required this.material});

  @override
  Widget build(BuildContext context) {
    final pad = _Responsive.hPad(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      minChildSize: 0.5,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: SafeArea(
            top: false,
            child: ListView(
              controller: controller,
              padding: EdgeInsets.fromLTRB(pad, 12, pad, pad),
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: material.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        material.emoji,
                        style: const TextStyle(fontSize: 24),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        material.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.heading1.copyWith(
                          fontSize: 20,
                          color: material.color,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AspectRatio(
                    aspectRatio: 16 / 9,
                    child: CachedNetworkImage(
                      imageUrl: material.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: material.color.withOpacity(0.15),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: material.color.withOpacity(0.2),
                        child: Icon(
                          material.icon,
                          size: 50,
                          color: material.color,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _infoBlock(
                  '¿Sabías que...?',
                  material.funFact,
                  Icons.lightbulb_rounded,
                  material.color,
                ),
                const SizedBox(height: 14),
                _infoBlock(
                  'Tiempo de descomposición',
                  material.decompositionTime,
                  Icons.hourglass_bottom_rounded,
                  material.color,
                ),
                const SizedBox(height: 14),
                _decompositionMeter(material),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _infoBlock(String title, String content, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            content,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textPrimary,
              height: 1.4,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _decompositionMeter(EcoMaterial material) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_rounded, color: material.color, size: 18),
              const SizedBox(width: 6),
              const Flexible(
                child: Text(
                  'Indicador de descomposición',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: material.decompositionScore),
              duration: const Duration(milliseconds: 900),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) {
                return LinearProgressIndicator(
                  value: value,
                  minHeight: 16,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation(material.color),
                );
              },
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rápido',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
              Text(
                '¡Casi eterno!',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  TAB 2 — LÍNEA DE TIEMPO VERTICAL PREMIUM
// ═══════════════════════════════════════════════════════════════════════════
class _TimelineTab extends StatelessWidget {
  const _TimelineTab();

  @override
  Widget build(BuildContext context) {
    final pad = _Responsive.hPad(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(pad, 4, pad, 4),
          child: Text(
            '¿Cuánto tarda en desaparecer?',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.heading1.copyWith(
              fontSize: _Responsive.isSmallPhone(context) ? 15 : 18,
              color: AppColors.textPrimary,
            ),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: pad),
          child: Text(
            'Desliza hacia abajo y compara los tiempos de degradación 👇',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              fontSize: _Responsive.isSmallPhone(context) ? 11 : 13,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: AnimationLimiter(
            child: ListView.builder(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.fromLTRB(pad, 8, pad, 24),
              itemCount: _timelineEntries.length,
              itemBuilder: (context, index) {
                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 500),
                  child: SlideAnimation(
                    verticalOffset: 60,
                    child: FadeInAnimation(
                      child: _TimelineCardVertical(
                        entry: _timelineEntries[index],
                        index: index,
                        isLast: index == _timelineEntries.length - 1,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

class _TimelineCardVertical extends StatelessWidget {
  final TimelineEntry entry;
  final int index;
  final bool isLast;

  const _TimelineCardVertical({
    required this.entry,
    required this.index,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final isSmall = _Responsive.isSmallPhone(context);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: entry.color,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: entry.color.withOpacity(0.4),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    entry.emoji,
                    style: TextStyle(fontSize: isSmall ? 13 : 15),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 3,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          entry.color.withOpacity(0.6),
                          _timelineEntries[index + 1]
                              .color
                              .withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(width: isSmall ? 10 : 14),
          Expanded(
            child: GestureDetector(
              onTap: () => _showImpactDialog(context, entry),
              child: Container(
                margin: EdgeInsets.only(bottom: isLast ? 0 : 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: entry.color.withOpacity(0.12),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: isSmall ? 110 : 130,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CachedNetworkImage(
                              imageUrl: entry.imageUrl,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: entry.color.withOpacity(0.1),
                                child: Center(
                                  child: SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: entry.color,
                                    ),
                                  ),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: entry.color.withOpacity(0.15),
                                child: Icon(
                                  Icons.image_not_supported_rounded,
                                  color: entry.color,
                                  size: 36,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 8,
                              left: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.55),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '#${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w800,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(isSmall ? 11 : 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    entry.label,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: isSmall ? 14 : 16,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: entry.color.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    entry.timeText,
                                    style: TextStyle(
                                      color: entry.color,
                                      fontWeight: FontWeight.w800,
                                      fontSize: isSmall ? 10 : 11,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              entry.impact,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: isSmall ? 11.5 : 13,
                                height: 1.35,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Icon(
                                  Icons.touch_app_rounded,
                                  size: 14,
                                  color: entry.color,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'Toca para saber más',
                                  style: TextStyle(
                                    fontSize: isSmall ? 10 : 11,
                                    color: entry.color,
                                    fontWeight: FontWeight.w600,
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
            ),
          ),
        ],
      ),
    );
  }

  void _showImpactDialog(BuildContext context, TimelineEntry entry) {
    try {
      final player = AudioPlayer();
      player.setVolume(0.4);
      player.play(AssetSource('audio/pop.mp3'));
      Future.delayed(const Duration(seconds: 2), () => player.dispose());
    } catch (_) {}

    showDialog(
      context: context,
      builder: (_) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.85, end: 1.0),
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: entry.color.withOpacity(0.3),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.sizeOf(context).height * 0.7,
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(entry.emoji,
                          style: const TextStyle(fontSize: 54)),
                      const SizedBox(height: 10),
                      Text(
                        entry.label,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.heading1.copyWith(
                          fontSize: 18,
                          color: entry.color,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: entry.color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          entry.timeText,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            color: entry.color,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        entry.impact,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.body.copyWith(
                          color: AppColors.textPrimary,
                          height: 1.45,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: entry.color,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('¡Entendido!'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  TAB 3 — DESCUBRIMIENTO (4 videos de YouTube con url_launcher)
// ═══════════════════════════════════════════════════════════════════════════
class _DiscoveryCornerTab extends StatelessWidget {
  const _DiscoveryCornerTab();

  @override
  Widget build(BuildContext context) {
    final pad = _Responsive.hPad(context);
    return AnimationLimiter(
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(pad),
        itemCount: _discoveryItems.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 450),
            child: SlideAnimation(
              verticalOffset: 35,
              child: FadeInAnimation(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _DiscoveryCardWidget(item: _discoveryItems[index]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DiscoveryCardWidget extends StatelessWidget {
  final DiscoveryItem item;
  const _DiscoveryCardWidget({required this.item});

  @override
  Widget build(BuildContext context) {
    final isSmall = _Responsive.isSmallPhone(context);
    final thumbSize = isSmall ? 88.0 : 104.0;

    return GestureDetector(
      onTap: () => _launchExternal(context),
      child: Container(
        // 👇 altura fija: evita el "hasSize is not true"
        height: thumbSize,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: item.color.withOpacity(0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          // 👇 ya no usamos stretch; la altura la da el Container
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Miniatura + overlay con icono según tipo
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(18),
              ),
              child: SizedBox(
                width: thumbSize,
                height: thumbSize,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: item.thumbnailUrl,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: item.color.withOpacity(0.15),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: item.color.withOpacity(0.15),
                        child: Icon(_iconFor(item.kind), color: item.color),
                      ),
                    ),
                    Container(
                      color: Colors.black.withOpacity(0.35),
                      child: Icon(
                        _iconFor(item.kind),
                        color: Colors.white,
                        size: isSmall ? 32 : 40,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: isSmall ? 9 : 12,
                  vertical: 8,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: item.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        _labelFor(item.kind),
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: item.color,
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: isSmall ? 12.5 : 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isSmall ? 10 : 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(right: isSmall ? 8 : 12),
              child: Icon(
                Icons.open_in_new_rounded,
                size: isSmall ? 16 : 18,
                color: item.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _iconFor(DiscoveryKind kind) {
    switch (kind) {
      case DiscoveryKind.video:
        return Icons.play_circle_fill_rounded;
      case DiscoveryKind.audio:
        return Icons.headphones_rounded;
      case DiscoveryKind.article:
        return Icons.article_rounded;
    }
  }

  String _labelFor(DiscoveryKind kind) {
    switch (kind) {
      case DiscoveryKind.video:
        return 'VIDEO';
      case DiscoveryKind.audio:
        return 'AUDIO';
      case DiscoveryKind.article:
        return 'ARTÍCULO';
    }
  }

  Future<void> _launchExternal(BuildContext context) async {
    final uri = Uri.tryParse(item.externalUrl);
    if (uri == null) {
      _toast(context, 'Enlace inválido.');
      return;
    }
    // 👇 Si el link sigue siendo el placeholder, avisa en vez de fallar
    if (item.externalUrl.contains('XXXXXXXXXXX')) {
      _toast(context, 'Aún no hay link asignado para este video.');
      return;
    }
    try {
      final ok = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!ok && context.mounted) {
        _toast(context, 'No se pudo abrir el enlace.');
      }
    } catch (_) {
      if (context.mounted) {
        _toast(context, 'No se pudo abrir el enlace.');
      }
    }
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  TAB 4 — GLOSARIO AMPLIADO
// ═══════════════════════════════════════════════════════════════════════════
class _GlossaryTab extends StatelessWidget {
  const _GlossaryTab();

  @override
  Widget build(BuildContext context) {
    final pad = _Responsive.hPad(context);
    return AnimationLimiter(
      child: ListView.builder(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(pad),
        itemCount: _glossaryTerms.length,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 450),
            child: SlideAnimation(
              verticalOffset: 35,
              child: FadeInAnimation(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _GlossaryCard(term: _glossaryTerms[index]),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GlossaryCard extends StatefulWidget {
  final GlossaryTerm term;
  const _GlossaryCard({required this.term});

  @override
  State<_GlossaryCard> createState() => _GlossaryCardState();
}

class _GlossaryCardState extends State<_GlossaryCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final term = widget.term;
    final isSmall = _Responsive.isSmallPhone(context);

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.all(isSmall ? 12 : 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _expanded ? term.color.withOpacity(0.5) : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (_expanded ? term.color : Colors.black)
                  .withOpacity(_expanded ? 0.15 : 0.05),
              blurRadius: _expanded ? 14 : 9,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: isSmall ? 42 : 48,
                  height: isSmall ? 42 : 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: term.color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Text(
                    term.emoji,
                    style: TextStyle(fontSize: isSmall ? 20 : 24),
                  ),
                ),
                SizedBox(width: isSmall ? 10 : 12),
                Expanded(
                  child: Text(
                    term.term,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.heading1.copyWith(
                      fontSize: isSmall ? 14 : 16,
                      color: term.color,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 300),
                  child: Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: term.color,
                  ),
                ),
              ],
            ),
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: _expanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(11),
                            decoration: BoxDecoration(
                              color: term.color.withOpacity(0.08),
                              borderRadius: BorderRadius.circular(13),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.auto_awesome_rounded,
                                      size: 15,
                                      color: term.color,
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        'Como en tu vida diaria',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11,
                                          color: term.color,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 7),
                                Text(
                                  term.analogy,
                                  style: AppTextStyles.body.copyWith(
                                    color: AppColors.textPrimary,
                                    height: 1.4,
                                    fontSize: isSmall ? 12 : 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.menu_book_rounded,
                                size: 15,
                                color: term.color,
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: Text(
                                  term.definition,
                                  style: AppTextStyles.body.copyWith(
                                    color: AppColors.textSecondary,
                                    fontStyle: FontStyle.italic,
                                    fontSize: isSmall ? 11 : 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}