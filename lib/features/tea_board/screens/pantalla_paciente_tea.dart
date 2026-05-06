import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_tts/flutter_tts.dart';

// ─── Modelo ──────────────────────────────────────────────────────────────────
class Pictograma {
  final String id;
  final String rutaSvg;
  final String etiqueta;
  final String textoTts;
  final String categoria;

  const Pictograma({
    required this.id,
    required this.rutaSvg,
    required this.etiqueta,
    required this.textoTts,
    required this.categoria,
  });
}

// ─── Banco de pictogramas (sin duplicados entre categorías) ───────────────────
//
// SVGs disponibles en assets/images/pictogramas/ mapeados 1:1 a cada categoría.
// Cada archivo SVG aparece en una sola categoría.
const List<Pictograma> _banco = [
  // ── MAÑANA (06:00 – 11:59) ──────────────────────────────────────────────
  Pictograma(
    id: 'm1',
    rutaSvg: 'assets/images/pictogramas/ducha.svg',
    etiqueta: 'DESPERTAR',
    textoTts: 'Es hora de despertar',
    categoria: 'Mañana',
  ),
  Pictograma(
    id: 'm2',
    rutaSvg: 'assets/images/pictogramas/lavar-manos.svg',
    etiqueta: 'LAVAR CARA',
    textoTts: 'Voy a lavarme la cara',
    categoria: 'Mañana',
  ),
  Pictograma(
    id: 'm3',
    rutaSvg: 'assets/images/pictogramas/cepillar-dientes.svg',
    etiqueta: 'DIENTES',
    textoTts: 'Debo lavarme los dientes',
    categoria: 'Mañana',
  ),
  Pictograma(
    id: 'm4',
    rutaSvg: 'assets/images/pictogramas/colegio.svg',
    etiqueta: 'COLEGIO',
    textoTts: 'Es hora de ir al colegio',
    categoria: 'Mañana',
  ),

  // ── TARDE (12:00 – 17:59) ───────────────────────────────────────────────
  Pictograma(
    id: 't1',
    rutaSvg: 'assets/images/pictogramas/almuerzo.svg',
    etiqueta: 'ALMORZAR',
    textoTts: 'Tengo hambre, quiero almorzar',
    categoria: 'Tarde',
  ),
  Pictograma(
    id: 't2',
    rutaSvg: 'assets/images/pictogramas/computador.svg',
    etiqueta: 'TAREAS TECH',
    textoTts: 'Es hora de hacer mis tareas de Tecnología',
    categoria: 'Tarde',
  ),
  Pictograma(
    id: 't3',
    rutaSvg: 'assets/images/pictogramas/once.svg',
    etiqueta: 'MERIENDA',
    textoTts: 'Quiero merendar algo rico',
    categoria: 'Tarde',
  ),
  Pictograma(
    id: 't4',
    rutaSvg: 'assets/images/pictogramas/pasear.svg',
    etiqueta: 'JUGAR',
    textoTts: 'Quiero salir a jugar',
    categoria: 'Tarde',
  ),

  // ── NOCHE (18:00 – 05:59) ───────────────────────────────────────────────
  Pictograma(
    id: 'n1',
    rutaSvg: 'assets/images/pictogramas/desayuno.svg',
    etiqueta: 'CENA',
    textoTts: 'Es hora de cenar',
    categoria: 'Noche',
  ),
  // "Baño (Taza)" → TTS dice "Quiero ir al baño", no "ducharme"
  Pictograma(
    id: 'n2',
    rutaSvg: 'assets/images/pictogramas/baño.svg',
    etiqueta: 'BAÑO',
    textoTts: 'Quiero ir al baño',
    categoria: 'Noche',
  ),
  Pictograma(
    id: 'n3',
    rutaSvg: 'assets/images/pictogramas/vestir.svg',
    etiqueta: 'PIJAMA',
    textoTts: 'Voy a ponerme el pijama',
    categoria: 'Noche',
  ),
  Pictograma(
    id: 'n4',
    rutaSvg: 'assets/images/pictogramas/casa.svg',
    etiqueta: 'DORMIR',
    textoTts: 'Es hora de dormir, buenas noches',
    categoria: 'Noche',
  ),

  // ── COMIDA ──────────────────────────────────────────────────────────────
  Pictograma(
    id: 'c1',
    rutaSvg: 'assets/images/pictogramas/beber.svg',
    etiqueta: 'AGUA',
    textoTts: 'Tengo sed, quiero agua',
    categoria: 'Comida',
  ),
  Pictograma(
    id: 'c2',
    rutaSvg: 'assets/images/pictogramas/mochila.svg',
    etiqueta: 'LONCHERA',
    textoTts: 'Quiero preparar mi lonchera',
    categoria: 'Comida',
  ),
  Pictograma(
    id: 'c3',
    rutaSvg: 'assets/images/pictogramas/comprar.svg',
    etiqueta: 'COMPRAR',
    textoTts: 'Quiero comprar comida',
    categoria: 'Comida',
  ),

  // ── EMOCIONES ───────────────────────────────────────────────────────────
  Pictograma(
    id: 'e1',
    rutaSvg: 'assets/images/pictogramas/feliz.svg',
    etiqueta: 'FELIZ',
    textoTts: 'Me siento feliz',
    categoria: 'Emociones',
  ),
  Pictograma(
    id: 'e2',
    rutaSvg: 'assets/images/pictogramas/cansado.svg',
    etiqueta: 'CANSADO',
    textoTts: 'Estoy cansado',
    categoria: 'Emociones',
  ),
  Pictograma(
    id: 'e3',
    rutaSvg: 'assets/images/pictogramas/estoy-bien.svg',
    etiqueta: 'BIEN',
    textoTts: 'Me siento bien',
    categoria: 'Emociones',
  ),
  Pictograma(
    id: 'e4',
    rutaSvg: 'assets/images/pictogramas/ayuda.svg',
    etiqueta: 'AYUDA',
    textoTts: 'Necesito ayuda',
    categoria: 'Emociones',
  ),
  Pictograma(
    id: 'e5',
    rutaSvg: 'assets/images/pictogramas/alto.svg',
    etiqueta: 'NO',
    textoTts: 'Quiero que pares, no me gusta esto',
    categoria: 'Emociones',
  ),

  // ── ACCIONES ────────────────────────────────────────────────────────────
  Pictograma(
    id: 'a1',
    rutaSvg: 'assets/images/pictogramas/calle.svg',
    etiqueta: 'SALIR',
    textoTts: 'Quiero salir a la calle',
    categoria: 'Acciones',
  ),
  Pictograma(
    id: 'a2',
    rutaSvg: 'assets/images/pictogramas/limpiar.svg',
    etiqueta: 'LIMPIAR',
    textoTts: 'Voy a limpiar mi cuarto',
    categoria: 'Acciones',
  ),
  Pictograma(
    id: 'a3',
    rutaSvg: 'assets/images/pictogramas/doctor.svg',
    etiqueta: 'DOCTOR',
    textoTts: 'Quiero ir al doctor',
    categoria: 'Acciones',
  ),
  Pictograma(
    id: 'a4',
    rutaSvg: 'assets/images/pictogramas/estudiar.svg',
    etiqueta: 'ESTUDIAR',
    textoTts: 'Quiero estudiar',
    categoria: 'Acciones',
  ),
  Pictograma(
    id: 'a5',
    rutaSvg: 'assets/images/pictogramas/libro.svg',
    etiqueta: 'LEER',
    textoTts: 'Quiero leer un libro',
    categoria: 'Acciones',
  ),
  Pictograma(
    id: 'a6',
    rutaSvg: 'assets/images/pictogramas/detente.svg',
    etiqueta: 'DETENTE',
    textoTts: 'Por favor, detente',
    categoria: 'Acciones',
  ),
  Pictograma(
    id: 'a7',
    rutaSvg: 'assets/images/pictogramas/hospital.svg',
    etiqueta: 'HOSPITAL',
    textoTts: 'Quiero ir al hospital',
    categoria: 'Acciones',
  ),
  Pictograma(
    id: 'a8',
    rutaSvg: 'assets/images/pictogramas/perro.svg',
    etiqueta: 'PERRO',
    textoTts: 'Quiero ver al perro',
    categoria: 'Acciones',
  ),
  Pictograma(
    id: 'a9',
    rutaSvg: 'assets/images/pictogramas/compras.svg',
    etiqueta: 'COMPRAS',
    textoTts: 'Quiero ir de compras',
    categoria: 'Acciones',
  ),
];

// ─── Widget principal ─────────────────────────────────────────────────────────
class PantallaPacienteTEA extends StatefulWidget {
  const PantallaPacienteTEA({super.key});

  @override
  State<PantallaPacienteTEA> createState() => _PantallaPacienteTEAState();
}

class _PantallaPacienteTEAState extends State<PantallaPacienteTEA> {
  late final FlutterTts _tts;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _initTts();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('es-ES');
    await _tts.setSpeechRate(0.45);
    await _tts.setVolume(1.0);
  }

  Future<void> _hablar(String texto) async {
    await _tts.stop();
    await _tts.speak(texto);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  // Detecta el periodo del día según hora local
  String get _catHoraria {
    final h = DateTime.now().hour;
    if (h >= 6 && h < 12) return 'Mañana';
    if (h >= 12 && h < 18) return 'Tarde';
    return 'Noche';
  }

  String get _nombreRutina {
    final h = DateTime.now().hour;
    if (h >= 6 && h < 12) return 'MAÑANA';
    if (h >= 12 && h < 18) return 'TARDE';
    return 'NOCHE';
  }

  IconData get _iconoRutina {
    final h = DateTime.now().hour;
    if (h >= 6 && h < 12) return Icons.wb_sunny_rounded;
    if (h >= 12 && h < 18) return Icons.wb_cloudy_rounded;
    return Icons.nights_stay_rounded;
  }

  List<Pictograma> _porCategoria(String cat) =>
      _banco.where((p) => p.categoria == cat).toList();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          backgroundColor: colors.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          title: Text(
            'MI DÍA',
            style: text.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: colors.primary,
              letterSpacing: 2.0,
            ),
          ),
          bottom: TabBar(
            indicatorColor: colors.primary,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: colors.primary,
            unselectedLabelColor: colors.onSurfaceVariant,
            labelStyle: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.8,
            ),
            tabs: const [
              Tab(text: 'MI RUTINA'),
              Tab(text: 'COMIDA'),
              Tab(text: 'EMOCIONES'),
              Tab(text: 'ACCIONES'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _GridCategoria(
              pictogramas: _porCategoria(_catHoraria),
              onTap: _hablar,
              nombreRutina: _nombreRutina,
              iconoRutina: _iconoRutina,
            ),
            _GridCategoria(
              pictogramas: _porCategoria('Comida'),
              onTap: _hablar,
            ),
            _GridCategoria(
              pictogramas: _porCategoria('Emociones'),
              onTap: _hablar,
            ),
            _GridCategoria(
              pictogramas: _porCategoria('Acciones'),
              onTap: _hablar,
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          heroTag: 'fab_ayuda_tea',
          onPressed: () => _hablar('Necesito ayuda, por favor'),
          backgroundColor: colors.errorContainer,
          label: Text(
            'AYUDA',
            style: TextStyle(
              color: colors.onErrorContainer,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 1.5,
            ),
          ),
          icon: Icon(Icons.warning_rounded, color: colors.onErrorContainer),
        ),
      ),
    );
  }
}

// ─── Grid por categoría ───────────────────────────────────────────────────────
class _GridCategoria extends StatelessWidget {
  final List<Pictograma> pictogramas;
  final Future<void> Function(String) onTap;
  final String? nombreRutina;
  final IconData? iconoRutina;

  const _GridCategoria({
    required this.pictogramas,
    required this.onTap,
    this.nombreRutina,
    this.iconoRutina,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Banner horario — solo visible en "MI RUTINA"
        if (nombreRutina != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withOpacity(0.35),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(iconoRutina, color: colors.primary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'RUTINA DE $nombreRutina',
                    style: text.labelMedium?.copyWith(
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),

        Expanded(
          child: GridView.builder(
            // Padding inferior deja espacio al FAB
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.82,
            ),
            itemCount: pictogramas.length,
            itemBuilder: (_, i) => _TarjetaPictograma(
              pictograma: pictogramas[i],
              onTap: () => onTap(pictogramas[i].textoTts),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Tarjeta de pictograma (Soft UI Premium) ──────────────────────────────────
class _TarjetaPictograma extends StatelessWidget {
  final Pictograma pictograma;
  final VoidCallback onTap;

  const _TarjetaPictograma({required this.pictograma, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: colors.outlineVariant.withOpacity(0.4),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.shadow.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        // ClipRRect asegura que el label inferior respete el borderRadius de la tarjeta
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 6),
                  child: SvgPicture.asset(
                    pictograma.rutaSvg,
                    fit: BoxFit.contain,
                    placeholderBuilder: (_) => Center(
                      child: Icon(
                        Icons.image_not_supported_rounded,
                        color: colors.outlineVariant,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
              // Etiqueta en base de tarjeta con fondo primaryContainer (0.15)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 6),
                decoration: BoxDecoration(
                  color: colors.primaryContainer.withOpacity(0.15),
                ),
                child: Text(
                  pictograma.etiqueta,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    color: colors.primary,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
