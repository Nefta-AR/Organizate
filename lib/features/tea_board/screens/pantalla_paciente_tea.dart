import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vibration/vibration.dart';

import 'package:flutter_tts/flutter_tts.dart';

import '../../../core/services/pictogram_service.dart';
import '../../../core/widgets/custom_nav_bar.dart';
import 'crear_pictograma_sheet.dart';

// ─── Modelo unificado de pictograma ──────────────────────────────────────────
class PictogramaDisplay {
  final String id;
  final String? rutaSvg;
  final String? imageUrl;
  final String etiqueta;
  final String textoTts;
  final String categoria;
  final bool esPersonalizado;

  const PictogramaDisplay._({
    required this.id,
    this.rutaSvg,
    this.imageUrl,
    required this.etiqueta,
    required this.textoTts,
    required this.categoria,
    required this.esPersonalizado,
  });

  factory PictogramaDisplay.fromLocal(Pictograma p) {
    return PictogramaDisplay._(
      id: p.id,
      rutaSvg: p.rutaSvg,
      etiqueta: p.etiqueta,
      textoTts: p.textoTts,
      categoria: p.categoria,
      esPersonalizado: false,
    );
  }

  factory PictogramaDisplay.fromCustom(PictogramaPersonalizado p) {
    return PictogramaDisplay._(
      id: 'custom_${p.id}',
      imageUrl: p.imageUrl,
      etiqueta: p.etiqueta,
      textoTts: p.textoTts,
      categoria: p.categoria,
      esPersonalizado: true,
    );
  }
}

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

// ─── Banco de pictogramas ─────────────────────────────────────────────────────
const List<Pictograma> _banco = [
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
  Pictograma(
    id: 'n1',
    rutaSvg: 'assets/images/pictogramas/desayuno.svg',
    etiqueta: 'CENA',
    textoTts: 'Es hora de cenar',
    categoria: 'Noche',
  ),
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

class _PantallaPacienteTEAState extends State<PantallaPacienteTEA>
    with TickerProviderStateMixin {
  late final FlutterTts _tts;

  final Map<String, String> _localOverrides = {};

  bool _transicionNotificada = false;

  Stream<List<PictogramaDisplay>>? _pictogramasStream;

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _initTts();
    _pictogramasStream = _buildPictogramasStream();
  }

  Future<void> _initTts() async {
    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.42);
    await _tts.setPitch(0.92);
    await _tts.setLanguage('es-ES');

    // Intentar seleccionar la mejor voz española disponible (neural/enhanced)
    try {
      final rawVoices = await _tts.getVoices;
      if (rawVoices != null) {
        final voices = (rawVoices as List)
            .map((v) => Map<String, String>.from(v as Map))
            .where((v) =>
                (v['locale'] ?? '').toLowerCase().startsWith('es') ||
                (v['name'] ?? '').toLowerCase().contains('spanish') ||
                (v['name'] ?? '').toLowerCase().contains('español'))
            .toList();

        if (voices.isNotEmpty) {
          // Priorizar voces neural/enhanced/wavenet
          final best = voices.firstWhere(
            (v) {
              final n = (v['name'] ?? '').toLowerCase();
              return n.contains('neural') ||
                  n.contains('enhanced') ||
                  n.contains('wavenet') ||
                  n.contains('quality#enhanced');
            },
            orElse: () => voices.first,
          );
          await _tts.setVoice({
            'name': best['name'] ?? '',
            'locale': best['locale'] ?? 'es-ES',
          });
        }
      }
    } catch (_) {}
  }

  Stream<List<PictogramaDisplay>> _buildPictogramasStream() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value(_banco.map(PictogramaDisplay.fromLocal).toList());
    }

    final customStream = PictogramService.getCustomPictogramsStream();

    return customStream.map((customList) {
      final all = _banco.map(PictogramaDisplay.fromLocal).toList();
      final customs = customList.map(PictogramaDisplay.fromCustom).toList();
      return [...all, ...customs];
    });
  }

  Future<void> _crearPictograma() async {
    final result = await CrearPictogramaSheet.show(context);
    if (result != null && mounted) {
      setState(() => _pictogramasStream = _buildPictogramasStream());
    }
  }

  Future<void> _hablar(String texto) async {
    await _tts.stop();
    await _tts.speak(texto);
  }

  void _hablarPictograma(PictogramaDisplay picto) {
    HapticFeedback.lightImpact();
    final texto = _localOverrides[picto.id] ?? picto.textoTts;
    _hablar(texto);
  }

  Future<void> _editarTexto(PictogramaDisplay picto) async {
    final currentText = _localOverrides[picto.id] ?? picto.textoTts;
    final controller = TextEditingController(text: currentText);

    final newText = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('¿Qué dirá este pictograma?'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Escribe lo que dirá'),
          textCapitalization: TextCapitalization.sentences,
          onSubmitted: (v) => Navigator.of(ctx).pop(v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(null),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (newText == null || newText.isEmpty || !mounted) return;

    if (picto.esPersonalizado) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;
      final firestoreId = picto.id.replaceFirst('custom_', '');
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('pictograms')
          .doc(firestoreId)
          .update({'textoTts': newText});
    } else {
      if (mounted) setState(() => _localOverrides[picto.id] = newText);
    }
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

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

  String get _siguienteActividad {
    final h = DateTime.now().hour;
    if (h < 12) return 'la Tarde';
    if (h < 18) return 'la Noche';
    return 'la Mañana';
  }

  List<PictogramaDisplay> _filtrarPorCategoria(
      List<PictogramaDisplay> todos, String cat) {
    return todos.where((p) => p.categoria == cat).toList();
  }

  void _onTransicionCercana() {
    if (_transicionNotificada) return;
    _transicionNotificada = true;

    HapticFeedback.mediumImpact();

    try {
      Vibration.vibrate(duration: 300);
    } catch (_) {}

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.hourglass_bottom_rounded,
                  color: Colors.white.withValues(alpha: 0.9), size: 20),
              const SizedBox(width: 10),
              Text(
                'Pronto cambiaremos a $_siguienteActividad',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          backgroundColor: Colors.black.withValues(alpha: 0.85),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      );
    }
  }

  void _resetTransicionFlag() {
    _transicionNotificada = false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

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
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: colors.primary,
                  letterSpacing: 2.0,
                ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.add_photo_alternate_rounded),
              tooltip: 'Crear pictograma',
              onPressed: _crearPictograma,
            ),
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: ContadorTransicion(
                onTransicionCercana: _onTransicionCercana,
                onReset: _resetTransicionFlag,
                siguienteActividad: _siguienteActividad,
              ),
            ),
          ],
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
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<PictogramaDisplay>>(
                stream: _pictogramasStream,
                builder: (context, snapshot) {
                  final todos = snapshot.data ?? [];

                  return TabBarView(
                    children: [
                      _GridCategoriaDisplay(
                        key: const PageStorageKey('tab_rutina'),
                        pictogramas: _filtrarPorCategoria(todos, _catHoraria),
                        onTap: _hablarPictograma,
                        onLongPress: _editarTexto,
                        nombreRutina: _nombreRutina,
                        iconoRutina: _iconoRutina,
                      ),
                      _GridCategoriaDisplay(
                        key: const PageStorageKey('tab_comida'),
                        pictogramas: _filtrarPorCategoria(todos, 'Comida'),
                        onTap: _hablarPictograma,
                        onLongPress: _editarTexto,
                      ),
                      _GridCategoriaDisplay(
                        key: const PageStorageKey('tab_emociones'),
                        pictogramas: _filtrarPorCategoria(todos, 'Emociones'),
                        onTap: _hablarPictograma,
                        onLongPress: _editarTexto,
                      ),
                      _GridCategoriaDisplay(
                        key: const PageStorageKey('tab_acciones'),
                        pictogramas: _filtrarPorCategoria(todos, 'Acciones'),
                        onTap: _hablarPictograma,
                        onLongPress: _editarTexto,
                      ),
                    ],
                  );
                },
              ),
            ),
            _buildAyudaRow(colors),
          ],
        ),
        bottomNavigationBar: const CustomNavBar(initialIndex: 2),
      ),
    );
  }

  Widget _buildAyudaRow(ColorScheme colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _hablar('Necesito ayuda, por favor'),
          style: ElevatedButton.styleFrom(
            backgroundColor: colors.errorContainer,
            foregroundColor: colors.onErrorContainer,
            elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
          ),
          icon: Icon(Icons.warning_rounded,
              color: colors.onErrorContainer, size: 20),
          label: Text(
            'AYUDA',
            style: TextStyle(
              color: colors.onErrorContainer,
              fontWeight: FontWeight.w800,
              fontSize: 13,
              letterSpacing: 1.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Cuenta Regresiva Visual (Semáforo de Ansiedad) ───────────────────────────

enum _EstadoUrgencia { tranquilo, atento, urgente }

class ContadorTransicion extends StatefulWidget {
  final VoidCallback onTransicionCercana;
  final VoidCallback onReset;
  final String siguienteActividad;

  const ContadorTransicion({
    super.key,
    required this.onTransicionCercana,
    required this.onReset,
    required this.siguienteActividad,
  });

  @override
  State<ContadorTransicion> createState() => _ContadorTransicionState();
}

class _ContadorTransicionState extends State<ContadorTransicion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;
  Timer? _tickTimer;

  _EstadoUrgencia _estadoActual = _EstadoUrgencia.tranquilo;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.05).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    _pulseController.repeat(reverse: true);

    _startTimer();
  }

  @override
  void didUpdateWidget(ContadorTransicion oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.siguienteActividad != oldWidget.siguienteActividad) {
      widget.onReset();
      setState(() => _estadoActual = _EstadoUrgencia.tranquilo);
    }
  }

  void _startTimer() {
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;

      final minutosRestantes = _minutosRestantes();

      _EstadoUrgencia nuevoEstado;
      if (minutosRestantes <= 1) {
        nuevoEstado = _EstadoUrgencia.urgente;
      } else if (minutosRestantes <= 5) {
        nuevoEstado = _EstadoUrgencia.atento;
      } else {
        nuevoEstado = _EstadoUrgencia.tranquilo;
      }

      if (nuevoEstado != _estadoActual) {
        setState(() => _estadoActual = nuevoEstado);
      }

      if (minutosRestantes <= 1 && minutosRestantes > 0) {
        widget.onTransicionCercana();
      }
    });
  }

  double _minutosRestantes() {
    final ahora = DateTime.now();
    final h = ahora.hour;

    DateTime finBloque;
    if (h < 12) {
      finBloque = DateTime(ahora.year, ahora.month, ahora.day, 12, 0, 0);
    } else if (h < 18) {
      finBloque = DateTime(ahora.year, ahora.month, ahora.day, 18, 0, 0);
    } else {
      finBloque = DateTime(ahora.year, ahora.month, ahora.day + 1, 6, 0, 0);
    }

    final diff = finBloque.difference(ahora).inSeconds;
    return diff / 60.0;
  }

  double _progreso() {
    final ahora = DateTime.now();
    final h = ahora.hour;

    DateTime inicioBloque;
    DateTime finBloque;

    if (h < 12) {
      inicioBloque = DateTime(ahora.year, ahora.month, ahora.day, 6, 0, 0);
      finBloque = DateTime(ahora.year, ahora.month, ahora.day, 12, 0, 0);
    } else if (h < 18) {
      inicioBloque = DateTime(ahora.year, ahora.month, ahora.day, 12, 0, 0);
      finBloque = DateTime(ahora.year, ahora.month, ahora.day, 18, 0, 0);
    } else {
      inicioBloque = DateTime(ahora.year, ahora.month, ahora.day, 18, 0, 0);
      finBloque = DateTime(ahora.year, ahora.month, ahora.day + 1, 6, 0, 0);
    }

    final total = finBloque.difference(inicioBloque).inSeconds;
    final transcurrido = ahora.difference(inicioBloque).inSeconds;

    return (total - transcurrido) / total;
  }

  Color _colorArco(ColorScheme colors) {
    switch (_estadoActual) {
      case _EstadoUrgencia.tranquilo:
        return const Color(0xFF8FAF8C);
      case _EstadoUrgencia.atento:
        return const Color(0xFFD4A853);
      case _EstadoUrgencia.urgente:
        return const Color(0xFFD97070);
    }
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final progreso = _progreso().clamp(0.0, 1.0);
    final color = _colorArco(colors);
    final esUrgente = _estadoActual == _EstadoUrgencia.urgente;

    return Tooltip(
      message: 'Pronto: ${widget.siguienteActividad}',
      child: GestureDetector(
        onTap: () {
          final mins = _minutosRestantes();
          if (mins > 0 && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  mins < 1
                      ? '¡Casi es hora de ${widget.siguienteActividad}!'
                      : 'Quedan ${mins.ceil()} min para ${widget.siguienteActividad}',
                  style: const TextStyle(fontSize: 13),
                ),
                backgroundColor: Colors.black.withValues(alpha: 0.85),
                behavior: SnackBarBehavior.floating,
                duration: const Duration(seconds: 3),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            );
          }
        },
        child: SizedBox(
          width: 44,
          height: 44,
          child: esUrgente
              ? AnimatedBuilder(
                  animation: _pulseAnimation,
                  builder: (context, child) => Transform.scale(
                    scale: _pulseAnimation.value,
                    child: child,
                  ),
                  child: _buildArc(progreso, color, colors),
                )
              : _buildArc(progreso, color, colors),
        ),
      ),
    );
  }

  Widget _buildArc(double progreso, Color color, ColorScheme colors) {
    return CustomPaint(
      painter: _ArcoProgresoPainter(
        progreso: progreso,
        color: color,
        trackColor: colors.outlineVariant.withValues(alpha: 0.2),
        strokeWidth: 4,
      ),
      size: const Size(44, 44),
    );
  }
}

class _ArcoProgresoPainter extends CustomPainter {
  final double progreso;
  final Color color;
  final Color trackColor;
  final double strokeWidth;

  _ArcoProgresoPainter({
    required this.progreso,
    required this.color,
    required this.trackColor,
    this.strokeWidth = 4,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi,
      false,
      trackPaint,
    );

    if (progreso > 0.001) {
      final progressPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * pi * progreso;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ArcoProgresoPainter oldDelegate) =>
      oldDelegate.progreso != progreso || oldDelegate.color != color;
}

// ─── Grid por categoría ───────────────────────────────────────────────────────
class _GridCategoriaDisplay extends StatefulWidget {
  final List<PictogramaDisplay> pictogramas;
  final void Function(PictogramaDisplay) onTap;
  final void Function(PictogramaDisplay) onLongPress;
  final String? nombreRutina;
  final IconData? iconoRutina;

  const _GridCategoriaDisplay({
    super.key,
    required this.pictogramas,
    required this.onTap,
    required this.onLongPress,
    this.nombreRutina,
    this.iconoRutina,
  });

  @override
  State<_GridCategoriaDisplay> createState() => _GridCategoriaDisplayState();
}

class _GridCategoriaDisplayState extends State<_GridCategoriaDisplay>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final colors = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.nombreRutina != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: colors.primaryContainer.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(widget.iconoRutina, color: colors.primary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'RUTINA DE ${widget.nombreRutina}',
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
          child: widget.pictogramas.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 48,
                        color: colors.onSurfaceVariant.withValues(alpha: 0.3),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Sin pictogramas en esta categoría',
                        style: TextStyle(
                          color: colors.onSurfaceVariant.withValues(alpha: 0.4),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 0.82,
                  ),
                  itemCount: widget.pictogramas.length,
                  itemBuilder: (_, i) {
                    final picto = widget.pictogramas[i];
                    return _TarjetaPictogramaDisplay(
                      pictograma: picto,
                      onTap: () => widget.onTap(picto),
                      onLongPress: () => widget.onLongPress(picto),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

// ─── Tarjeta de pictograma ────────────────────────────────────────────────────
class _TarjetaPictogramaDisplay extends StatefulWidget {
  final PictogramaDisplay pictograma;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _TarjetaPictogramaDisplay({
    required this.pictograma,
    this.onTap,
    this.onLongPress,
  });

  @override
  State<_TarjetaPictogramaDisplay> createState() =>
      _TarjetaPictogramaDisplayState();
}

class _TarjetaPictogramaDisplayState extends State<_TarjetaPictogramaDisplay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pressController;
  late final Animation<double> _scaleAnimation;

  Timer? _progressTimer;
  bool _isLongPressing = false;
  double _longPressProgress = 0.0;

  static const _longPressDurationMs = 5000;
  static const _tickMs = 50;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
      duration: const Duration(milliseconds: 100),
      reverseDuration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.92).animate(
      CurvedAnimation(
        parent: _pressController,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _pressController.dispose();
    super.dispose();
  }

  void _startLongPress(LongPressStartDetails _) {
    if (widget.onLongPress == null) return;

    int elapsed = 0;
    setState(() {
      _isLongPressing = true;
      _longPressProgress = 0.0;
    });

    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: _tickMs), (t) {
      elapsed += _tickMs;
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _longPressProgress = elapsed / _longPressDurationMs);
      if (elapsed >= _longPressDurationMs) {
        t.cancel();
        _triggerLongPress();
      }
    });
  }

  void _cancelLongPress() {
    _progressTimer?.cancel();
    _progressTimer = null;
    if (!mounted) return;
    setState(() {
      _isLongPressing = false;
      _longPressProgress = 0.0;
    });
  }

  void _triggerLongPress() {
    _progressTimer?.cancel();
    _progressTimer = null;
    if (!mounted) return;
    setState(() {
      _isLongPressing = false;
      _longPressProgress = 0.0;
    });
    HapticFeedback.mediumImpact();
    widget.onLongPress?.call();
  }

  Widget _buildImagen(ColorScheme colors) {
    if (widget.pictograma.esPersonalizado &&
        widget.pictograma.imageUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: Image.network(
          widget.pictograma.imageUrl!,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                  color: colors.primary,
                ),
              ),
            );
          },
          errorBuilder: (_, __, ___) => Center(
            child: Icon(
              Icons.broken_image_rounded,
              color: colors.outlineVariant,
              size: 32,
            ),
          ),
        ),
      );
    }

    return SvgPicture.asset(
      widget.pictograma.rutaSvg ?? '',
      fit: BoxFit.contain,
      placeholderBuilder: (_) => Center(
        child: Icon(
          Icons.image_not_supported_rounded,
          color: colors.outlineVariant,
          size: 32,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTap: () {
        _pressController.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _pressController.reverse(),
      onLongPressStart: _startLongPress,
      onLongPressEnd: (_) => _cancelLongPress(),
      onLongPressCancel: _cancelLongPress,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: widget.pictograma.esPersonalizado
                  ? colors.secondary.withValues(alpha: 0.35)
                  : colors.outlineVariant.withValues(alpha: 0.4),
              width: widget.pictograma.esPersonalizado ? 1.5 : 1.0,
            ),
            boxShadow: [
              BoxShadow(
                color: colors.shadow.withValues(alpha: 0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Stack(
              children: [
                Column(
                  children: [
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
                        child: _buildImagen(colors),
                      ),
                    ),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          vertical: 7, horizontal: 6),
                      decoration: BoxDecoration(
                        color: widget.pictograma.esPersonalizado
                            ? colors.secondaryContainer.withValues(alpha: 0.2)
                            : colors.primaryContainer.withValues(alpha: 0.15),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.pictograma.esPersonalizado)
                            Icon(
                              Icons.photo_camera_rounded,
                              size: 8,
                              color: colors.secondary.withValues(alpha: 0.6),
                            ),
                          if (widget.pictograma.esPersonalizado)
                            const SizedBox(width: 3),
                          Flexible(
                            child: Text(
                              widget.pictograma.etiqueta,
                              textAlign: TextAlign.center,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize:
                                    widget.pictograma.esPersonalizado ? 8 : 9,
                                fontWeight: FontWeight.w800,
                                color: widget.pictograma.esPersonalizado
                                    ? colors.secondary
                                    : colors.primary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (_isLongPressing)
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: LinearProgressIndicator(
                      value: _longPressProgress,
                      minHeight: 3,
                      backgroundColor: colors.outlineVariant.withValues(alpha: 0.2),
                      color: colors.primary,
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
