// lib/features/tea_board/screens/pantalla_paciente_tea.dart
//
// Tablero de comunicación aumentativa y alternativa (CAA) para usuarios TEA.
//
// ## Modelo de datos unificado
//
// [PictogramaDisplay] unifica dos fuentes de pictogramas:
//   - **Banco estático** (SVG en assets): 25+ pictogramas predefinidos,
//     organizados por categoría (Mañana, Tarde, Noche, Emergencias, etc.).
//   - **Pictogramas personalizados** (JPEG en Firebase Storage): creados por
//     el propio usuario o por el tutor desde el panel de supervisión.
//
// La configuración de categoría y visibilidad se lee de `pictogramSettings/`
// para cada usuario, permitiendo al tutor reorganizar el banco sin modificar
// los datos maestros. Los pictogramas ocultos (`visible: false`) se omiten.
//
// ## Síntesis de voz (TTS)
//
// Se usa `flutter_tts` con voz en español. El primer tap activa el TTS;
// el segundo tap en el mismo pictograma lo selecciona para activar una acción
// extendida (si aplica). La vibración acompaña el audio como feedback háptico
// para usuarios con dificultades auditivas.
//
// ## Registro de actividad
//
// Cada uso de pictograma escribe una entrada en `activityLog` via
// [ActivityLogService] para que el tutor pueda ver los pictogramas más usados
// en el tab de Historial.

import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:vibration/vibration.dart';

import 'package:flutter_tts/flutter_tts.dart';

import 'package:simple/core/services/activity_log_service.dart';
import 'package:simple/core/services/pictogram_service.dart';
import 'package:simple/core/utils/emergency_contact_helper.dart';
import 'package:simple/core/widgets/custom_nav_bar.dart';
import 'package:simple/features/tutor_dashboard/screens/settings_screen.dart';
import 'package:tutorial_coach_mark/tutorial_coach_mark.dart';

import 'package:simple/core/services/tour_service.dart';
import 'package:simple/core/widgets/tour_step_card.dart';
import 'crear_pictograma_sheet.dart';
import 'pictogram_manager_screen.dart';

// ─── Modelo unificado de pictograma ──────────────────────────────────────────
class PictogramaDisplay {
  final String id;
  final String? rutaSvg;
  final String? imageUrl;
  final IconData? iconData;
  final Color? iconColor;
  final String etiqueta;
  final String textoTts;
  final String categoria;
  final bool esPersonalizado;

  const PictogramaDisplay._({
    required this.id,
    this.rutaSvg,
    this.imageUrl,
    this.iconData,
    this.iconColor,
    required this.etiqueta,
    required this.textoTts,
    required this.categoria,
    required this.esPersonalizado,
  });

  // Constructor para vocabulario extendido basado en iconos de Material (sin imagen).
  const PictogramaDisplay.icon({
    required String id,
    required String etiqueta,
    required String textoTts,
    required String categoria,
    required IconData iconData,
    required Color iconColor,
  }) : this._(
          id: id,
          etiqueta: etiqueta,
          textoTts: textoTts,
          categoria: categoria,
          esPersonalizado: false,
          iconData: iconData,
          iconColor: iconColor,
        );

  // Constructor para pictogramas con imagen local (PNG, JPG o SVG en assets/).
  const PictogramaDisplay.asset({
    required String id,
    required String etiqueta,
    required String textoTts,
    required String categoria,
    required String rutaSvg,
  }) : this._(
          id: id,
          etiqueta: etiqueta,
          textoTts: textoTts,
          categoria: categoria,
          esPersonalizado: false,
          rutaSvg: rutaSvg,
        );

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
// TTS cortos: las rutinas y acciones dicen solo la etiqueta para que el usuario
// pueda componer "YO + QUIERO + [acción]" usando el strip de vocabulario core.
// Emociones/necesidades/saludos conservan frases completas (son mensajes en sí).
const List<Pictograma> _banco = [
  Pictograma(id: 'm1', rutaSvg: 'assets/images/pictogramas/Ducha.svg',             etiqueta: 'DUCHA',       textoTts: 'DUCHARME',                categoria: 'Mañana'),
  Pictograma(id: 'm2', rutaSvg: 'assets/images/pictogramas/Lavar Manos.svg',       etiqueta: 'LAVAR CARA',  textoTts: 'Lavar la cara',       categoria: 'Mañana'),
  Pictograma(id: 'm3', rutaSvg: 'assets/images/pictogramas/Cepillar Dientes.svg',  etiqueta: 'DIENTES',     textoTts: 'Cepillar los dientes', categoria: 'Mañana'),
  Pictograma(id: 'm4', rutaSvg: 'assets/images/pictogramas/Colegio.svg',           etiqueta: 'COLEGIO',     textoTts: 'Colegio',             categoria: 'Mañana'),
  Pictograma(id: 't1', rutaSvg: 'assets/images/pictogramas/Almuerzo.svg',          etiqueta: 'ALMORZAR',    textoTts: 'Almorzar',            categoria: 'Tarde'),
  Pictograma(id: 't2', rutaSvg: 'assets/images/pictogramas/Computador.svg',        etiqueta: 'COMPUTADOR',  textoTts: 'Usar el computador',  categoria: 'Tarde'),
  Pictograma(id: 't3', rutaSvg: 'assets/images/pictogramas/Once.svg',              etiqueta: 'MERIENDA',    textoTts: 'Merienda',            categoria: 'Tarde'),
  Pictograma(id: 't4', rutaSvg: 'assets/images/pictogramas/Pasear.svg',            etiqueta: 'JUGAR',       textoTts: 'Jugar',               categoria: 'Tarde'),
  Pictograma(id: 'n1', rutaSvg: 'assets/images/pictogramas/Desayuno.svg',          etiqueta: 'CENA',        textoTts: 'Cenar',               categoria: 'Noche'),
  Pictograma(id: 'n2', rutaSvg: 'assets/images/pictogramas/Baño.svg',              etiqueta: 'BAÑO',        textoTts: 'Ir al baño',          categoria: 'Necesidades'),
  Pictograma(id: 'n3', rutaSvg: 'assets/images/pictogramas/Vestir.svg',            etiqueta: 'PIJAMA',      textoTts: 'Ponerme el pijama',   categoria: 'Noche'),
  Pictograma(id: 'n4', rutaSvg: 'assets/images/pictogramas/Casa.svg',              etiqueta: 'DORMIR',      textoTts: 'Dormir',              categoria: 'Noche'),
  Pictograma(id: 'c1', rutaSvg: 'assets/images/pictogramas/Beber.svg',             etiqueta: 'AGUA',        textoTts: 'Agua',                categoria: 'Comida'),
  Pictograma(id: 'c2', rutaSvg: 'assets/images/pictogramas/Mochila.svg',           etiqueta: 'LONCHERA',    textoTts: 'Lonchera',            categoria: 'Comida'),
  // Emociones: frases completas (reportes de estado, no solicitudes)
  Pictograma(id: 'e1', rutaSvg: 'assets/images/pictogramas/Feliz.svg',             etiqueta: 'FELIZ',       textoTts: 'Me siento feliz',     categoria: 'Emociones'),
  Pictograma(id: 'e2', rutaSvg: 'assets/images/pictogramas/Cansado.svg',           etiqueta: 'CANSADO',     textoTts: 'Estoy cansado',       categoria: 'Emociones'),
  Pictograma(id: 'e3', rutaSvg: 'assets/images/pictogramas/Estoy Bien.svg',        etiqueta: 'BIEN',        textoTts: 'Me siento bien',      categoria: 'Emociones'),
  Pictograma(id: 'e4', rutaSvg: 'assets/images/pictogramas/Ayuda.svg',             etiqueta: 'AYUDA',       textoTts: 'Necesito ayuda',      categoria: 'Emociones'),
  Pictograma(id: 'e5', rutaSvg: 'assets/images/pictogramas/Alto.svg',              etiqueta: 'STOP',        textoTts: 'No, detente por favor', categoria: 'Emociones'),
  // Acciones: TTS cortos para componer con el strip (YO + QUIERO + acción)
  Pictograma(id: 'a1', rutaSvg: 'assets/images/pictogramas/Calle.svg',             etiqueta: 'SALIR',       textoTts: 'Salir',               categoria: 'Acciones'),
  Pictograma(id: 'a2', rutaSvg: 'assets/images/pictogramas/Limpiar.svg',           etiqueta: 'LIMPIAR',     textoTts: 'Limpiar',             categoria: 'Acciones'),
  Pictograma(id: 'a3', rutaSvg: 'assets/images/pictogramas/Doctor.svg',            etiqueta: 'DOCTOR',      textoTts: 'Doctor',              categoria: 'Acciones'),
  Pictograma(id: 'a4', rutaSvg: 'assets/images/pictogramas/Estudiar.svg',          etiqueta: 'ESTUDIAR',    textoTts: 'Estudiar',            categoria: 'Acciones'),
  Pictograma(id: 'a5', rutaSvg: 'assets/images/pictogramas/Libro.svg',             etiqueta: 'LEER',        textoTts: 'Leer',                categoria: 'Acciones'),
  Pictograma(id: 'a6', rutaSvg: 'assets/images/pictogramas/Detente.svg',           etiqueta: 'DETENTE',     textoTts: 'Por favor, detente',  categoria: 'Acciones'),
  Pictograma(id: 'a7', rutaSvg: 'assets/images/pictogramas/Hospital.svg',          etiqueta: 'HOSPITAL',    textoTts: 'Hospital',            categoria: 'Acciones'),
  Pictograma(id: 'a8', rutaSvg: 'assets/images/pictogramas/Perro.svg',             etiqueta: 'PERRO',       textoTts: 'Perro',               categoria: 'Acciones'),
  Pictograma(id: 'a9', rutaSvg: 'assets/images/pictogramas/Compras.svg',           etiqueta: 'COMPRAS',     textoTts: 'Compras',             categoria: 'Acciones'),
];

// ─── Vocabulario core permanente (siempre visible en el strip superior) ───────
class _CoreVocab {
  final String etiqueta;
  final String textoTts;
  final IconData icono;
  final Color color;
  const _CoreVocab(this.etiqueta, this.textoTts, this.icono, this.color);
}

const List<_CoreVocab> _coreVocabItems = [
  _CoreVocab('YO',      'Yo',     Icons.person_rounded,       Color(0xFF9B89C4)), // lavanda suave
  _CoreVocab('QUIERO',  'Quiero', Icons.favorite_border,      Color(0xFFD97070)), // soft pink (paleta app)
  _CoreVocab('SÍ',      'Sí',     Icons.check_circle_outline, Color(0xFF8FAF8C)), // sage green (paleta app)
  _CoreVocab('NO',      'No',     Icons.cancel_rounded,       Color(0xFF9E8080)), // rosa apagado
  _CoreVocab('MÁS',     'Más',    Icons.add_circle_outline,   Color(0xFF7B9EC8)), // azul suave
  _CoreVocab('BASTA',   'Basta',  Icons.pan_tool_rounded,     Color(0xFFD4A853)), // ámbar cálido (paleta app)
  _CoreVocab('ESPERAR', 'Espera', Icons.hourglass_empty,      Color(0xFFB8A070)), // arena dorada
];

// ─── Banco extendido con imágenes propias (vocabulario AAC ampliado) ───────────
const List<PictogramaDisplay> _bancoExtendido = [
  // Emociones adicionales
  PictogramaDisplay.asset(id: 'e6',  etiqueta: 'TRISTE',    textoTts: 'Estoy triste',                           categoria: 'Emociones',   rutaSvg: 'assets/images/pictogramas/Triste.png'),
  PictogramaDisplay.asset(id: 'e7',  etiqueta: 'ENOJADO',   textoTts: 'Estoy enojado',                          categoria: 'Emociones',   rutaSvg: 'assets/images/pictogramas/Enojado.jpg'),
  PictogramaDisplay.asset(id: 'e8',  etiqueta: 'ASUSTADO',  textoTts: 'Tengo miedo, estoy asustado',            categoria: 'Emociones',   rutaSvg: 'assets/images/pictogramas/Asustado.jpg'),
  PictogramaDisplay.asset(id: 'e9',  etiqueta: 'ABURRIDO',  textoTts: 'Estoy aburrido',                         categoria: 'Emociones',   rutaSvg: 'assets/images/pictogramas/Aburrido.png'),
  PictogramaDisplay.asset(id: 'e10', etiqueta: 'FRUSTRADO', textoTts: 'Estoy frustrado',                        categoria: 'Emociones',   rutaSvg: 'assets/images/pictogramas/Frustrado.png'),
  PictogramaDisplay.asset(id: 'e11', etiqueta: 'ANSIOSO',   textoTts: 'Estoy ansioso, necesito calmarme',       categoria: 'Emociones',   rutaSvg: 'assets/images/pictogramas/Ansioso.png'),
  PictogramaDisplay.asset(id: 'e12', etiqueta: 'SOLO/A',    textoTts: 'Me siento solo',                         categoria: 'Emociones',   rutaSvg: 'assets/images/pictogramas/Solo.png'),
  // Necesidades — autorregulación sensorial y seguridad
  PictogramaDisplay.asset(id: 'nec1', etiqueta: 'TENGO DOLOR',   textoTts: 'Tengo dolor',                             categoria: 'Necesidades', rutaSvg: 'assets/images/pictogramas/Tengo Dolor.png'),
  PictogramaDisplay.asset(id: 'nec2', etiqueta: 'TENGO FRÍO',    textoTts: 'Tengo frío',                              categoria: 'Necesidades', rutaSvg: 'assets/images/pictogramas/Tengo Frío.jpg'),
  PictogramaDisplay.asset(id: 'nec3', etiqueta: 'TENGO CALOR',   textoTts: 'Tengo calor',                             categoria: 'Necesidades', rutaSvg: 'assets/images/pictogramas/Tengo Calor.png'),
  PictogramaDisplay.asset(id: 'nec4', etiqueta: 'ESTOY ENFERMO', textoTts: 'Estoy enfermo, necesito ayuda',           categoria: 'Necesidades', rutaSvg: 'assets/images/pictogramas/Estoy Enfermo.jpg'),
  PictogramaDisplay.asset(id: 'nec5', etiqueta: 'MUCHO RUIDO',   textoTts: 'Hay demasiado ruido, necesito silencio',  categoria: 'Necesidades', rutaSvg: 'assets/images/pictogramas/Mucho Ruido.png'),
  PictogramaDisplay.asset(id: 'nec6', etiqueta: 'MUCHA LUZ',     textoTts: 'Hay demasiada luz',                       categoria: 'Necesidades', rutaSvg: 'assets/images/pictogramas/Mucha Luz.jpg'),
  PictogramaDisplay.asset(id: 'nec7', etiqueta: 'DESCANSO',      textoTts: 'Necesito un momento de descanso',         categoria: 'Necesidades', rutaSvg: 'assets/images/pictogramas/Descansar.png'),
  // Familia: TTS corto para componer con strip (YO + QUIERO + MAMÁ)
  PictogramaDisplay.asset(id: 'per1', etiqueta: 'MAMÁ',    textoTts: 'Mamá',  categoria: 'Familia', rutaSvg: 'assets/images/pictogramas/Mamá.png'),
  PictogramaDisplay.asset(id: 'per2', etiqueta: 'PAPÁ',    textoTts: 'Papá',  categoria: 'Familia', rutaSvg: 'assets/images/pictogramas/Papá.png'),
  PictogramaDisplay.asset(id: 'per3', etiqueta: 'AMIGO/A', textoTts: 'Amigo', categoria: 'Familia', rutaSvg: 'assets/images/pictogramas/Amigo.png'),
  // Saludos sociales
  PictogramaDisplay.asset(id: 'sal1', etiqueta: 'HOLA',      textoTts: 'Hola',             categoria: 'Acciones', rutaSvg: 'assets/images/pictogramas/Hola.png'),
  PictogramaDisplay.asset(id: 'sal2', etiqueta: 'ADIÓS',     textoTts: 'Adiós, hasta luego', categoria: 'Acciones', rutaSvg: 'assets/images/pictogramas/Adiós.png'),
  PictogramaDisplay.asset(id: 'sal3', etiqueta: 'GRACIAS',   textoTts: 'Gracias',           categoria: 'Acciones', rutaSvg: 'assets/images/pictogramas/Gracias.png'),
  PictogramaDisplay.asset(id: 'sal4', etiqueta: 'POR FAVOR', textoTts: 'Por favor',         categoria: 'Acciones', rutaSvg: 'assets/images/pictogramas/Por Favor.png'),
  PictogramaDisplay.asset(id: 'sal5', etiqueta: 'LO SIENTO', textoTts: 'Lo siento mucho',  categoria: 'Acciones', rutaSvg: 'assets/images/pictogramas/Lo Siento.png'),
];

// ─── Widget principal ─────────────────────────────────────────────────────────
class PantallaUsuarioTEA extends StatefulWidget {
  const PantallaUsuarioTEA({super.key});

  @override
  State<PantallaUsuarioTEA> createState() => _PantallaUsuarioTEAState();
}

class _PantallaUsuarioTEAState extends State<PantallaUsuarioTEA>
    with TickerProviderStateMixin {
  late final FlutterTts _tts;

  final Map<String, String> _localOverrides = {};
  Map<String, Map<String, dynamic>> _pictoSettings = {};
  StreamSubscription<Map<String, Map<String, dynamic>>>? _settingsSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userSub;

  String? _emergencyName;
  String? _emergencyPhone;
  bool _silentMode = false;

  bool _transicionNotificada = false;

  Stream<List<PictogramaDisplay>>? _pictogramasStream;

  final _stripTourKey = GlobalKey();
  final _tabBarTourKey = GlobalKey();
  final _gridTourKey  = GlobalKey();
  final _ayudaTourKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _tts = FlutterTts();
    _initTts();
    _pictogramasStream = _buildPictogramasStream();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      _settingsSub = PictogramService.getPictogramSettingsStreamFor(uid)
          .listen((s) { if (mounted) setState(() => _pictoSettings = s); });
      _userSub = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots()
          .listen((snap) {
        if (!mounted) return;
        final data = snap.data() ?? {};
        setState(() {
          _emergencyName  = data['emergencyName']  as String?;
          _emergencyPhone = data['emergencyPhone'] as String?;
          _silentMode     = data['pictogramSilentMode'] as bool? ?? false;
        });
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _initTourIfNeeded());
  }

  Future<void> _initTts() async {
    await _tts.setVolume(1.0);
    await _tts.setSpeechRate(0.42);
    await _tts.setPitch(0.92);
    await _tts.setLanguage('es-ES');
    // Silencia los SpeechSynthesisErrorEvent del navegador (ej: "interrupted"
    // al llamar stop() antes de speak()) para no contaminar la consola.
    _tts.setErrorHandler((_) {});

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
      return Stream.value([
        ..._banco.map(PictogramaDisplay.fromLocal),
        ..._bancoExtendido,
      ]);
    }

    final customStream = PictogramService.getCustomPictogramsStream();

    return customStream.map((customList) {
      final all = _banco.map(PictogramaDisplay.fromLocal).toList();
      final customs = customList.map(PictogramaDisplay.fromCustom).toList();
      return [...all, ..._bancoExtendido, ...customs];
    });
  }

  Future<void> _crearPictograma() async {
    final result = await CrearPictogramaSheet.show(context);
    if (result != null && mounted) {
      setState(() => _pictogramasStream = _buildPictogramasStream());
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await ActivityLogService.log(
          userId: uid,
          type: ActivityType.pictogramCreated,
          description: 'Pictograma creado: "${result.etiqueta}"',
          metadata: {'pictogramId': result.id},
        );
      }
    }
  }

  void _abrirManager() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PictogramManagerScreen(
          userId: uid,
          userName: 'mis pictogramas',
          builtins: kBancoBuiltins,
        ),
      ),
    );
  }

  Future<void> _toggleSilentMode() async {
    final newVal = !_silentMode;
    setState(() => _silentMode = newVal);
    if (_silentMode) await _tts.stop();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .update({'pictogramSilentMode': newVal});
  }

  Future<void> _hablar(String texto) async {
    try { await _tts.stop(); } catch (_) {}
    try { await _tts.speak(texto); } catch (_) {}
  }

  // stop() no bloqueante: la cancelación JS es síncrona → limpia la cola
  // inmediatamente sin agregar latencia de await. El SpeechSynthesisErrorEvent
  // que genera queda silenciado por platformDispatcher.onError en main.dart.
  Future<void> _hablarRapido(String texto) async {
    unawaited(_tts.stop());
    try { await _tts.speak(texto); } catch (_) {}
  }

  void _hablarPictograma(PictogramaDisplay picto) {
    HapticFeedback.lightImpact();
    final texto = _localOverrides[picto.id] ?? picto.textoTts;
    if (!_silentMode) _hablarRapido(texto);
    ActivityLogService.log(
      type: ActivityType.pictogramUsed,
      description: 'Pictograma usado: "${picto.etiqueta}"',
      metadata: {'etiqueta': picto.etiqueta, 'texto': texto},
    ).catchError((_) {});
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

  Future<void> _initTourIfNeeded() async {
    if (!mounted) return;
    final needed = await TourService.needsUserTour();
    if (needed && mounted) {
      await Future.delayed(const Duration(milliseconds: 700));
      if (mounted) _startUserTour();
    }
  }

  void _startUserTour() {
    final colors = Theme.of(context).colorScheme;

    final targets = [
      TargetFocus(
        identify: 'strip',
        keyTarget: _stripTourKey,
        shape: ShapeLightFocus.RRect,
        radius: 12,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: TourStepCard(
              icon: Icons.record_voice_over_rounded,
              iconColor: colors.primary,
              title: 'Vocabulario Clave',
              body: 'Toca cualquier palabra para escucharla en voz alta. Arma frases rápidas presionando una tras otra: YO → QUIERO → AGUA.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'tabs',
        keyTarget: _tabBarTourKey,
        shape: ShapeLightFocus.RRect,
        radius: 8,
        contents: [
          TargetContent(
            align: ContentAlign.bottom,
            child: const TourStepCard(
              icon: Icons.tab_rounded,
              iconColor: Colors.teal,
              title: 'Categorías',
              body: 'Desliza entre las pestañas para cambiar de categoría: Rutina, Comida, Emociones, Acciones, Necesidades y Familia.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'grid',
        keyTarget: _gridTourKey,
        shape: ShapeLightFocus.RRect,
        radius: 16,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const TourStepCard(
              icon: Icons.grid_view_rounded,
              iconColor: Colors.deepPurple,
              title: 'Pictogramas',
              body: 'Toca una imagen para escucharla. Mantén presionado para personalizar el texto que se lee en voz alta.',
            ),
          ),
        ],
      ),
      TargetFocus(
        identify: 'ayuda',
        keyTarget: _ayudaTourKey,
        shape: ShapeLightFocus.RRect,
        radius: 14,
        contents: [
          TargetContent(
            align: ContentAlign.top,
            child: const TourStepCard(
              icon: Icons.warning_rounded,
              iconColor: Colors.red,
              title: 'Botón de Ayuda',
              body: 'Presiona aquí cuando necesites ayuda urgente. La App dirá "Necesito ayuda, por favor" en voz alta.',
            ),
          ),
        ],
      ),
    ];

    TutorialCoachMark(
      targets: targets,
      colorShadow: Colors.black,
      opacityShadow: 0.85,
      hideSkip: false,
      textSkip: 'SALTAR',
      textStyleSkip: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
      onFinish: () => TourService.markUserTourDone(),
      onSkip: () { TourService.markUserTourDone(); return true; },
    ).show(context: context);
  }

  @override
  void dispose() {
    _settingsSub?.cancel();
    _userSub?.cancel();
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
    return todos.where((p) {
      final s = _pictoSettings[p.id];
      if (s?['visible'] == false) return false;
      final categoriaEfectiva = s?['categoria'] as String? ?? p.categoria;
      return categoriaEfectiva == cat;
    }).toList();
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
      length: 6,
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: AppBar(
          backgroundColor: colors.surface,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          leading: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: IconButton(
              icon: Icon(
                Icons.health_and_safety,
                color: (_emergencyPhone?.trim().isNotEmpty ?? false)
                    ? const Color(0xFFB05C5C)
                    : Colors.grey.shade400,
                size: 26,
              ),
              tooltip: 'Contacto de emergencia',
              onPressed: () => handleEmergencyContactAction(
                context,
                emergencyName: (_emergencyName?.trim().isNotEmpty ?? false)
                    ? _emergencyName
                    : null,
                emergencyPhone: (_emergencyPhone?.trim().isNotEmpty ?? false)
                    ? _emergencyPhone
                    : null,
                onNavigateToProfile: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen()),
                ),
              ),
            ),
          ),
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
              icon: Icon(
                _silentMode ? Icons.volume_off_rounded : Icons.volume_up_rounded,
                color: _silentMode ? Colors.orange.shade600 : null,
              ),
              tooltip: _silentMode ? 'Modo silencioso activo (toca para activar voz)' : 'Silenciar voz',
              onPressed: _toggleSilentMode,
            ),
            IconButton(
              icon: const Icon(Icons.tune_rounded),
              tooltip: 'Organizar pictogramas',
              onPressed: _abrirManager,
            ),
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
            key: _tabBarTourKey,
            indicatorColor: colors.primary,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: colors.primary,
            unselectedLabelColor: colors.onSurfaceVariant,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
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
              Tab(text: 'NECESIDADES'),
              Tab(text: 'FAMILIA'),
            ],
          ),
        ),
        body: Column(
          children: [
            _buildCoreStrip(colors),
            Expanded(
              key: _gridTourKey,
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
                      _GridCategoriaDisplay(
                        key: const PageStorageKey('tab_necesidades'),
                        pictogramas: _filtrarPorCategoria(todos, 'Necesidades'),
                        onTap: _hablarPictograma,
                        onLongPress: _editarTexto,
                      ),
                      _GridCategoriaDisplay(
                        key: const PageStorageKey('tab_familia'),
                        pictogramas: _filtrarPorCategoria(todos, 'Familia'),
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
        bottomNavigationBar: const CustomNavBar(screen: NavScreen.pictogramas),
      ),
    );
  }

  // Tira horizontal siempre visible con vocabulario CORE (YO, QUIERO, SÍ, NO…).
  // Aparece encima del TabBarView independientemente del tab activo.
  Widget _buildCoreStrip(ColorScheme colors) {
    return Container(
      key: _stripTourKey,
      decoration: BoxDecoration(
        color: colors.primaryContainer.withValues(alpha: 0.07),
        border: Border(
          bottom: BorderSide(
            color: colors.outlineVariant.withValues(alpha: 0.35),
          ),
        ),
      ),
      padding: const EdgeInsets.only(top: 6, bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 0, 4),
            child: Text(
              'VOCABULARIO CLAVE',
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.9,
                color: colors.onSurfaceVariant.withValues(alpha: 0.45),
              ),
            ),
          ),
          SizedBox(
            height: 58,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: _coreVocabItems.length,
              itemBuilder: (_, i) {
                final item = _coreVocabItems[i];
                return _CoreVocabTile(
                  item: item,
                  onPressed: () { if (!_silentMode) _hablarRapido(item.textoTts); },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAyudaRow(ColorScheme colors) {
    return Padding(
      key: _ayudaTourKey,
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            HapticFeedback.mediumImpact();
            if (!_silentMode) _hablar('Necesito ayuda, por favor');
          },
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
    // Pictograma basado en icono Material (vocabulario core/extendido sin SVG)
    if (widget.pictograma.iconData != null) {
      final c = widget.pictograma.iconColor ?? colors.primary;
      return Container(
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Center(
          child: Icon(widget.pictograma.iconData, size: 44, color: c),
        ),
      );
    }

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

    final ruta = widget.pictograma.rutaSvg ?? '';
    final esPng = ruta.endsWith('.png') || ruta.endsWith('.jpg');

    if (esPng) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.asset(
          ruta,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Center(
            child: Icon(
              Icons.image_not_supported_rounded,
              color: colors.outlineVariant,
              size: 32,
            ),
          ),
        ),
      );
    }

    return SvgPicture.asset(
      ruta,
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
      onTapDown: (_) {
        _pressController.forward();
        widget.onTap?.call(); // TTS en primer contacto, sin esperar onTap
      },
      onTap: () => _pressController.reverse(),
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

// ─── Tile animado para el strip de vocabulario core ───────────────────────────
// Usa onTapDown para feedback háptico + escala inmediata (igual que la grilla),
// eliminando el retraso de ~150 ms que tenía el GestureDetector simple anterior.
class _CoreVocabTile extends StatefulWidget {
  final _CoreVocab item;
  final VoidCallback onPressed;

  const _CoreVocabTile({
    required this.item,
    required this.onPressed,
  });

  @override
  State<_CoreVocabTile> createState() => _CoreVocabTileState();
}

class _CoreVocabTileState extends State<_CoreVocabTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      duration: const Duration(milliseconds: 80),
      reverseDuration: const Duration(milliseconds: 130),
      vsync: this,
    );
    _scale = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(
        parent: _ctrl,
        curve: Curves.easeOut,
        reverseCurve: Curves.easeOutBack,
      ),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.lightImpact();
        _ctrl.forward();
        widget.onPressed(); // TTS en primer contacto, sin esperar onTap
      },
      onTap: () => _ctrl.reverse(),
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 58,
          decoration: BoxDecoration(
            color: item.color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: item.color.withValues(alpha: 0.45),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(item.icono, size: 20, color: item.color),
              const SizedBox(height: 2),
              Text(
                item.etiqueta,
                style: TextStyle(
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  color: item.color,
                  letterSpacing: 0.1,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
