// ============================================================
// lib/features/tea_board/screens/pictogram_manager_screen.dart
// ============================================================
// Gestor de pictogramas para el tutor. Permite reorganizar y configurar
// el banco completo de pictogramas del usuario TEA seleccionado.
//
// ## Separación de datos vs. configuración
//
// El banco predefinido ([kBancoBuiltins]) es estático en el código.
// La configuración personalizada (categoría, visibilidad) se almacena en
// `pictogramSettings/{pictoId}` en Firestore. Este diseño permite que
// múltiples usuarios compartan el banco SVG sin duplicar datos, y que
// el tutor personalice la experiencia sin modificar datos maestros.
//
// La función `_efectiva()` aplica el override de categoría si existe,
// o devuelve la categoría por defecto del pictograma. El merge se hace
// en cliente para evitar un join en Firestore.
//
// ## Modelo [PictoEntry]
//
// Unifica pictogramas predefinidos (con `svgPath`) y personalizados
// (con `imageUrl`) bajo una misma interfaz para que la cuadrícula de
// gestión pueda renderizar ambos tipos con el mismo widget [_PictoManagerCard].
//
// ## Persistencia de la configuración
//
// [_setCategoria] y [_toggleVisible] aplican el cambio localmente en
// `_settings` para feedback inmediato (optimistic UI), luego escriben a
// Firestore. Si la escritura falla, el stream de [_loadSettings] revertirá
// el estado al próximo snapshot.
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:simple/core/services/pictogram_service.dart';
import 'package:simple/features/tea_board/screens/crear_pictograma_sheet.dart';

// ─── Opciones de categoría asignable ─────────────────────────────────────────

/// Lista de las 6 categorías posibles para clasificar pictogramas.
/// El tutor las usa desde [_showCategoryPicker] para reasignar un picto.
const kCategoriasAsignables = [
  _CatOption('Mañana',      Icons.wb_sunny_rounded,          Color(0xFFFFA726)),
  _CatOption('Tarde',       Icons.wb_cloudy_rounded,         Color(0xFF42A5F5)),
  _CatOption('Noche',       Icons.nights_stay_rounded,       Color(0xFF5C6BC0)),
  _CatOption('Comida',      Icons.restaurant_rounded,        Color(0xFF66BB6A)),
  _CatOption('Emociones',   Icons.emoji_emotions_rounded,    Color(0xFFEC407A)),
  _CatOption('Acciones',    Icons.directions_run_rounded,    Color(0xFF26C6DA)),
  _CatOption('Necesidades', Icons.medical_services_rounded,  Color(0xFFEF5350)),
  _CatOption('Familia',     Icons.family_restroom_rounded,   Color(0xFFAB47BC)),
];

/// Modelo de datos de una opción de categoría: etiqueta, ícono y color.
class _CatOption {
  final String label;    // Nombre de la categoría mostrado en UI
  final IconData icon;   // Ícono representativo de la categoría
  final Color color;     // Color de acento asociado a la categoría
  const _CatOption(this.label, this.icon, this.color);
}

// ─── Banco de pictogramas predeterminados ─────────────────────────────────────

/// Banco de pictogramas incluidos con la app (SVG + imágenes propias).
///
/// Prefijos de ID: m=Mañana, t=Tarde, n=Noche, c=Comida,
/// e=Emociones, a=Acciones, nec=Necesidades, per=Familia, sal=Saludos.
/// Estos IDs se usan como clave en `pictogramSettings/{pictoId}` en Firestore.
const List<PictoEntry> kBancoBuiltins = [
  // --- Mañana ---
  PictoEntry(id: 'm1', svgPath: 'assets/images/pictogramas/Ducha.svg',            etiqueta: 'DESPERTAR',    defaultCategoria: 'Mañana',      esPersonalizado: false),
  PictoEntry(id: 'm2', svgPath: 'assets/images/pictogramas/Lavar Manos.svg',      etiqueta: 'LAVAR CARA',   defaultCategoria: 'Mañana',      esPersonalizado: false),
  PictoEntry(id: 'm3', svgPath: 'assets/images/pictogramas/Cepillar Dientes.svg', etiqueta: 'DIENTES',      defaultCategoria: 'Mañana',      esPersonalizado: false),
  PictoEntry(id: 'm4', svgPath: 'assets/images/pictogramas/Colegio.svg',          etiqueta: 'COLEGIO',      defaultCategoria: 'Mañana',      esPersonalizado: false),
  // --- Tarde ---
  PictoEntry(id: 't1', svgPath: 'assets/images/pictogramas/Almuerzo.svg',         etiqueta: 'ALMORZAR',     defaultCategoria: 'Tarde',       esPersonalizado: false),
  PictoEntry(id: 't2', svgPath: 'assets/images/pictogramas/Computador.svg',       etiqueta: 'COMPUTADOR',   defaultCategoria: 'Tarde',       esPersonalizado: false),
  PictoEntry(id: 't3', svgPath: 'assets/images/pictogramas/Once.svg',             etiqueta: 'MERIENDA',     defaultCategoria: 'Tarde',       esPersonalizado: false),
  PictoEntry(id: 't4', svgPath: 'assets/images/pictogramas/Pasear.svg',           etiqueta: 'JUGAR',        defaultCategoria: 'Tarde',       esPersonalizado: false),
  // --- Noche ---
  PictoEntry(id: 'n1', svgPath: 'assets/images/pictogramas/Desayuno.svg',         etiqueta: 'CENA',         defaultCategoria: 'Noche',       esPersonalizado: false),
  PictoEntry(id: 'n2', svgPath: 'assets/images/pictogramas/Baño.svg',             etiqueta: 'BAÑO',         defaultCategoria: 'Necesidades', esPersonalizado: false),
  PictoEntry(id: 'n3', svgPath: 'assets/images/pictogramas/Vestir.svg',           etiqueta: 'PIJAMA',       defaultCategoria: 'Noche',       esPersonalizado: false),
  PictoEntry(id: 'n4', svgPath: 'assets/images/pictogramas/Casa.svg',             etiqueta: 'DORMIR',       defaultCategoria: 'Noche',       esPersonalizado: false),
  // --- Comida ---
  PictoEntry(id: 'c1', svgPath: 'assets/images/pictogramas/Beber.svg',            etiqueta: 'AGUA',         defaultCategoria: 'Comida',      esPersonalizado: false),
  PictoEntry(id: 'c2', svgPath: 'assets/images/pictogramas/Mochila.svg',          etiqueta: 'LONCHERA',     defaultCategoria: 'Comida',      esPersonalizado: false),
  // --- Emociones (SVG base) ---
  PictoEntry(id: 'e1', svgPath: 'assets/images/pictogramas/Feliz.svg',            etiqueta: 'FELIZ',        defaultCategoria: 'Emociones',   esPersonalizado: false),
  PictoEntry(id: 'e2', svgPath: 'assets/images/pictogramas/Cansado.svg',          etiqueta: 'CANSADO',      defaultCategoria: 'Emociones',   esPersonalizado: false),
  PictoEntry(id: 'e3', svgPath: 'assets/images/pictogramas/Estoy Bien.svg',       etiqueta: 'BIEN',         defaultCategoria: 'Emociones',   esPersonalizado: false),
  PictoEntry(id: 'e4', svgPath: 'assets/images/pictogramas/Ayuda.svg',            etiqueta: 'AYUDA',        defaultCategoria: 'Emociones',   esPersonalizado: false),
  PictoEntry(id: 'e5', svgPath: 'assets/images/pictogramas/Alto.svg',             etiqueta: 'STOP',         defaultCategoria: 'Emociones',   esPersonalizado: false),
  // --- Acciones ---
  PictoEntry(id: 'a1', svgPath: 'assets/images/pictogramas/Calle.svg',            etiqueta: 'SALIR',        defaultCategoria: 'Acciones',    esPersonalizado: false),
  PictoEntry(id: 'a2', svgPath: 'assets/images/pictogramas/Limpiar.svg',          etiqueta: 'LIMPIAR',      defaultCategoria: 'Acciones',    esPersonalizado: false),
  PictoEntry(id: 'a3', svgPath: 'assets/images/pictogramas/Doctor.svg',           etiqueta: 'DOCTOR',       defaultCategoria: 'Acciones',    esPersonalizado: false),
  PictoEntry(id: 'a4', svgPath: 'assets/images/pictogramas/Estudiar.svg',         etiqueta: 'ESTUDIAR',     defaultCategoria: 'Acciones',    esPersonalizado: false),
  PictoEntry(id: 'a5', svgPath: 'assets/images/pictogramas/Libro.svg',            etiqueta: 'LEER',         defaultCategoria: 'Acciones',    esPersonalizado: false),
  PictoEntry(id: 'a6', svgPath: 'assets/images/pictogramas/Detente.svg',          etiqueta: 'DETENTE',      defaultCategoria: 'Acciones',    esPersonalizado: false),
  PictoEntry(id: 'a7', svgPath: 'assets/images/pictogramas/Hospital.svg',         etiqueta: 'HOSPITAL',     defaultCategoria: 'Acciones',    esPersonalizado: false),
  PictoEntry(id: 'a8', svgPath: 'assets/images/pictogramas/Perro.svg',            etiqueta: 'PERRO',        defaultCategoria: 'Acciones',    esPersonalizado: false),
  PictoEntry(id: 'a9', svgPath: 'assets/images/pictogramas/Compras.svg',          etiqueta: 'COMPRAS',      defaultCategoria: 'Acciones',    esPersonalizado: false),
  // --- Emociones adicionales (imágenes propias) ---
  PictoEntry(id: 'e6',  svgPath: 'assets/images/pictogramas/Triste.png',          etiqueta: 'TRISTE',       defaultCategoria: 'Emociones',   esPersonalizado: false),
  PictoEntry(id: 'e7',  svgPath: 'assets/images/pictogramas/Enojado.jpg',         etiqueta: 'ENOJADO',      defaultCategoria: 'Emociones',   esPersonalizado: false),
  PictoEntry(id: 'e8',  svgPath: 'assets/images/pictogramas/Asustado.jpg',        etiqueta: 'ASUSTADO',     defaultCategoria: 'Emociones',   esPersonalizado: false),
  PictoEntry(id: 'e9',  svgPath: 'assets/images/pictogramas/Aburrido.png',        etiqueta: 'ABURRIDO',     defaultCategoria: 'Emociones',   esPersonalizado: false),
  PictoEntry(id: 'e10', svgPath: 'assets/images/pictogramas/Frustrado.png',       etiqueta: 'FRUSTRADO',    defaultCategoria: 'Emociones',   esPersonalizado: false),
  PictoEntry(id: 'e11', svgPath: 'assets/images/pictogramas/Ansioso.png',         etiqueta: 'ANSIOSO',      defaultCategoria: 'Emociones',   esPersonalizado: false),
  PictoEntry(id: 'e12', svgPath: 'assets/images/pictogramas/Solo.png',               etiqueta: 'SOLO/A',   defaultCategoria: 'Emociones',   esPersonalizado: false),
  // --- Necesidades (imágenes propias) ---
  PictoEntry(id: 'nec1', svgPath: 'assets/images/pictogramas/Tengo Dolor.png',    etiqueta: 'TENGO DOLOR',  defaultCategoria: 'Necesidades', esPersonalizado: false),
  PictoEntry(id: 'nec2', svgPath: 'assets/images/pictogramas/Tengo Frío.jpg',     etiqueta: 'TENGO FRÍO',   defaultCategoria: 'Necesidades', esPersonalizado: false),
  PictoEntry(id: 'nec3', svgPath: 'assets/images/pictogramas/Tengo Calor.png',    etiqueta: 'TENGO CALOR',  defaultCategoria: 'Necesidades', esPersonalizado: false),
  PictoEntry(id: 'nec4', svgPath: 'assets/images/pictogramas/Estoy Enfermo.jpg',  etiqueta: 'ESTOY ENFERMO',defaultCategoria: 'Necesidades', esPersonalizado: false),
  PictoEntry(id: 'nec5', svgPath: 'assets/images/pictogramas/Mucho Ruido.png',    etiqueta: 'MUCHO RUIDO',  defaultCategoria: 'Necesidades', esPersonalizado: false),
  PictoEntry(id: 'nec6', svgPath: 'assets/images/pictogramas/Mucha Luz.jpg',      etiqueta: 'MUCHA LUZ',    defaultCategoria: 'Necesidades', esPersonalizado: false),
  PictoEntry(id: 'nec7', svgPath: 'assets/images/pictogramas/Descansar.png',      etiqueta: 'DESCANSO',     defaultCategoria: 'Necesidades', esPersonalizado: false),
  // --- Familia (imágenes propias) ---
  PictoEntry(id: 'per1', svgPath: 'assets/images/pictogramas/Mamá.png',           etiqueta: 'MAMÁ',         defaultCategoria: 'Familia',     esPersonalizado: false),
  PictoEntry(id: 'per2', svgPath: 'assets/images/pictogramas/Papá.png',           etiqueta: 'PAPÁ',         defaultCategoria: 'Familia',     esPersonalizado: false),
  PictoEntry(id: 'per3', svgPath: 'assets/images/pictogramas/Amigo.png',          etiqueta: 'AMIGO/A',      defaultCategoria: 'Familia',     esPersonalizado: false),
  // --- Saludos (imágenes propias) ---
  PictoEntry(id: 'sal1', svgPath: 'assets/images/pictogramas/Hola.png',           etiqueta: 'HOLA',         defaultCategoria: 'Acciones',    esPersonalizado: false),
  PictoEntry(id: 'sal2', svgPath: 'assets/images/pictogramas/Adiós.png',          etiqueta: 'ADIÓS',        defaultCategoria: 'Acciones',    esPersonalizado: false),
  PictoEntry(id: 'sal3', svgPath: 'assets/images/pictogramas/Gracias.png',        etiqueta: 'GRACIAS',      defaultCategoria: 'Acciones',    esPersonalizado: false),
  PictoEntry(id: 'sal4', svgPath: 'assets/images/pictogramas/Por Favor.png',      etiqueta: 'POR FAVOR',    defaultCategoria: 'Acciones',    esPersonalizado: false),
  PictoEntry(id: 'sal5', svgPath: 'assets/images/pictogramas/Lo Siento.png',      etiqueta: 'LO SIENTO',    defaultCategoria: 'Acciones',    esPersonalizado: false),
];

// ─── Modelo unificado PictoEntry ──────────────────────────────────────────────

/// Modelo mínimo para que el manager pueda mostrar cualquier pictograma.
///
/// Un [PictoEntry] puede representar:
/// - Un pictograma del banco predefinido: tiene [svgPath], no tiene [imageUrl].
/// - Un pictograma personalizado del usuario: tiene [imageUrl], no tiene [svgPath].
///
/// Esta unificación permite que [_PictoManagerCard] maneje ambos casos
/// con el mismo widget y lógica de renderizado.
class PictoEntry {
  final String id;              // Identificador único: 'm1', 'custom_abc123'
  final String? svgPath;        // Path de asset SVG (solo predefinidos con imagen)
  final String? imageUrl;       // URL de Storage o asset (personalizados)
  final IconData? iconData;     // Icono Material (vocabulario extendido sin SVG)
  final Color? iconColor;       // Color del icono
  final String etiqueta;        // Texto visible bajo el pictograma
  final String defaultCategoria;// Categoría original del pictograma (sin overrides)
  final bool esPersonalizado;   // true = subido por el usuario, false = banco predefinido

  const PictoEntry({
    required this.id,
    this.svgPath,
    this.imageUrl,
    this.iconData,
    this.iconColor,
    required this.etiqueta,
    required this.defaultCategoria,
    required this.esPersonalizado,
  });
}

// ─── Pantalla principal ───────────────────────────────────────────────────────

class PictogramManagerScreen extends StatefulWidget {
  final String userId;              // UID del usuario TEA cuyo banco se gestiona
  final String userName;            // Nombre para el AppBar ("Pictogramas de …")
  final List<PictoEntry> builtins;  // Banco de pictogramas predefinidos del usuario

  const PictogramManagerScreen({
    super.key,
    required this.userId,
    required this.userName,
    required this.builtins,
  });

  @override
  State<PictogramManagerScreen> createState() =>
      _PictogramManagerScreenState();
}

class _PictogramManagerScreenState extends State<PictogramManagerScreen> {
  // Mapa de configuración cargado de Firestore: pictoId → {categoria, visible}
  Map<String, Map<String, dynamic>> _settings = {};
  bool _loadingSettings = true; // true mientras no llega el primer snapshot de settings

  // Lista de pictogramas personalizados del usuario
  List<PictogramaPersonalizado> _customs = [];
  bool _loadingCustoms = true; // true mientras no llega el primer snapshot de customs

  // Categoría seleccionada en la barra de filtros. null = mostrar todas
  String? _filterCat;

  @override
  void initState() {
    super.initState();
    // Iniciamos ambos streams en paralelo. Cuando ambos entreguen su primer dato,
    // se activará el cuerpo de la pantalla (loading flag → false)
    _loadSettings();
    _loadCustoms();
  }

  /// Escucha el stream de configuración de pictogramas para este usuario.
  /// Cada snapshot actualiza [_settings] y quita el spinner de carga.
  void _loadSettings() {
    PictogramService.getPictogramSettingsStreamFor(widget.userId).listen(
      (s) {
        if (!mounted) return; // Guard: el widget puede haberse desmontado
        setState(() {
          _settings        = s;
          _loadingSettings = false; // Ya no mostramos el spinner de settings
        });
      },
      onError: (_) {
        // En caso de error de red o permisos, quitamos el spinner igual
        if (mounted) setState(() => _loadingSettings = false);
      },
    );
  }

  /// Escucha el stream de pictogramas personalizados para este usuario.
  /// Cada snapshot actualiza [_customs] y quita el spinner de carga.
  void _loadCustoms() {
    PictogramService.getCustomPictogramsStreamFor(widget.userId).listen(
      (list) {
        if (!mounted) return;
        setState(() {
          _customs        = list;
          _loadingCustoms = false;
        });
      },
      onError: (_) {
        if (mounted) setState(() => _loadingCustoms = false);
      },
    );
  }

  // ─── Accesores de configuración ──────────────────────────────────────────

  /// Retorna la categoría efectiva de un pictograma.
  /// Si el tutor asignó una categoría override → la devuelve.
  /// Si no → devuelve la [defaultCat] del banco estático.
  String _efectiva(String id, String defaultCat) =>
      _settings[id]?['categoria'] as String? ?? defaultCat;

  /// Retorna si el pictograma es visible en el tablero del usuario.
  /// Por defecto (sin override) todos los pictogramas son visibles.
  bool _visible(String id) => _settings[id]?['visible'] != false;

  // ─── Mutaciones (Optimistic UI) ──────────────────────────────────────────

  /// Cambia la categoría de un pictograma.
  ///
  /// Aplica el cambio localmente de inmediato (UI sin latencia) y luego
  /// persiste en Firestore. Si falla la escritura, el próximo snapshot del
  /// stream revertirá el estado al valor guardado en Firestore.
  Future<void> _setCategoria(String id, String newCat) async {
    // Optimistic update: actualiza el mapa local fusionando solo el campo 'categoria'
    setState(() => _settings[id] = {...?_settings[id], 'categoria': newCat});

    // Persiste en Firestore asíncronamente (no awaited en setState para no bloquear UI)
    await PictogramService.updatePictogramSettingFor(
      userId:    widget.userId,
      pictoId:   id,
      categoria: newCat,
    );
  }

  /// Alterna la visibilidad de un pictograma en el tablero del usuario.
  ///
  /// Usa el mismo patrón de optimistic UI que [_setCategoria]:
  /// actualiza localmente, luego persiste en Firestore.
  Future<void> _toggleVisible(String id) async {
    final current = _visible(id); // Estado actual antes de alternar
    // Optimistic: invertimos la visibilidad en el mapa local
    setState(() => _settings[id] = {...?_settings[id], 'visible': !current});

    // Persistimos el nuevo valor en Firestore
    await PictogramService.updatePictogramSettingFor(
      userId:  widget.userId,
      pictoId: id,
      visible: !current, // Enviamos el valor invertido
    );
  }

  // ─── Listas derivadas ────────────────────────────────────────────────────

  /// Combina los pictogramas del banco predefinido con los personalizados del usuario.
  ///
  /// Los pictogramas personalizados se mapean a [PictoEntry] con prefijo `custom_`
  /// en el ID para que no colisionen con los IDs del banco ('m1', 'a9', etc.).
  List<PictoEntry> get _allEntries {
    final builtins = widget.builtins; // Banco estático pasado por parámetro

    // Convertimos cada PictogramaPersonalizado a PictoEntry con id prefijado
    final customs = _customs.map((p) => PictoEntry(
          id:               'custom_${p.id}', // Prefijo para evitar colisión de IDs
          imageUrl:         p.imageUrl,        // URL de Storage
          etiqueta:         p.etiqueta,
          defaultCategoria: p.categoria,       // La categoría elegida al crearlo
          esPersonalizado:  true,
        ));

    // Combinamos: primero los predefinidos, luego los personalizados al final
    return [...builtins, ...customs];
  }

  /// Lista filtrada por la categoría seleccionada en la barra de filtros.
  /// Si [_filterCat] es null, retorna todos los pictogramas.
  List<PictoEntry> get _filtered {
    final all = _allEntries;
    if (_filterCat == null) return all; // Sin filtro activo → todos

    // Filtramos por la categoría efectiva (con posibles overrides del tutor)
    return all
        .where((e) => _efectiva(e.id, e.defaultCategoria) == _filterCat)
        .toList();
  }

  // ─── Build principal ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Mostramos spinner si alguno de los dos streams aún no llegó
    final loading = _loadingSettings || _loadingCustoms;

    return Scaffold(
      appBar: AppBar(
        title: Text('Pictogramas de ${widget.userName}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          // Botón "Restablecer": solo visible cuando ya cargaron los datos
          if (!loading)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _resetAll, // Revierte toda la configuración a valores predeterminados
                icon:  const Icon(Icons.restore, size: 18),
                label: const Text('Restablecer'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red.shade400,
                  textStyle: const TextStyle(fontSize: 12),
                ),
              ),
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator()) // Cargando streams
          : SafeArea(
              top: false,
              child: Column(
                children: [
                  _buildFilterBar(), // Chips horizontales para filtrar por categoría
                  _buildLegend(),    // Contador de pictos totales y ocultos
                  Expanded(child: _buildGrid()), // Cuadrícula de tarjetas
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await CrearPictogramaSheet.show(
            context,
            targetUserId: widget.userId,
          );
        },
        icon: const Icon(Icons.add_a_photo_rounded),
        label: const Text('Nuevo'),
        backgroundColor: Colors.blueGrey,
      ),
    );
  }

  // ─── Barra de filtros por categoría ──────────────────────────────────────

  Widget _buildFilterBar() {
    // Añadimos null al inicio para representar "Todos" (sin filtro)
    final cats = [null, ...kCategoriasAsignables.map((c) => c.label)];

    return SizedBox(
      height: 48, // Altura fija para el scroll horizontal de chips
      child: ListView.separated(
        scrollDirection: Axis.horizontal, // Desplazamiento horizontal
        padding:  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemCount: cats.length,
        itemBuilder: (_, i) {
          final cat      = cats[i]; // null = "Todos"
          final selected = _filterCat == cat; // ¿Este chip está seleccionado?

          // Buscamos la opción de categoría para obtener su ícono y color
          final opt = cat == null
              ? null
              : kCategoriasAsignables.firstWhere((c) => c.label == cat);

          return GestureDetector(
            onTap: () => setState(() => _filterCat = cat), // Cambia el filtro activo
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150), // Transición suave al seleccionar
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                // Fondo con color de categoría al 15% cuando está seleccionado
                color: selected
                    ? (opt?.color ?? Colors.blueGrey).withValues(alpha: 0.15)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  // Borde coloreado cuando está seleccionado, transparente cuando no
                  color: selected
                      ? (opt?.color ?? Colors.blueGrey)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Ícono de la categoría (no aparece en el chip "Todos")
                  if (opt != null) ...[
                    Icon(
                      opt.icon,
                      size:  13,
                      color: selected ? opt.color : Colors.grey.shade600,
                    ),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    cat ?? 'Todos', // "Todos" para el chip sin filtro
                    style: TextStyle(
                      fontSize:   12,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                      color: selected
                          ? (opt?.color ?? Colors.blueGrey)
                          : Colors.grey.shade700,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Leyenda de totales ───────────────────────────────────────────────────

  Widget _buildLegend() {
    // Contamos cuántos pictogramas están ocultos actualmente
    final hidden = _allEntries.where((e) => !_visible(e.id)).length;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          // Contador de totales y ocultos
          Text(
            '${_allEntries.length} pictogramas · $hidden ocultos',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const Spacer(),
          // Instrucción de uso en texto pequeño
          const Icon(Icons.touch_app, size: 13, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            'Toca la sección · 👁 para ocultar',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  // ─── Cuadrícula de tarjetas ───────────────────────────────────────────────

  Widget _buildGrid() {
    final entries = _filtered; // Lista con o sin filtro aplicado

    // Estado vacío: no hay pictogramas en la categoría seleccionada
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_search, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(
              'Sin pictogramas en esta sección',
              style: TextStyle(color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:   3,    // 3 columnas
        crossAxisSpacing: 10,
        mainAxisSpacing:  10,
        childAspectRatio: 0.72, // Tarjetas más altas que anchas (imagen + chip)
      ),
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final e = entries[i];
        return _PictoManagerCard(
          entry:             e,
          settings:          _settings[e.id] ?? {}, // Mapa vacío si no hay overrides
          categoriaEfectiva: _efectiva(e.id, e.defaultCategoria),
          isVisible:         _visible(e.id),
          onCategoryTap:     () => _showCategoryPicker(e), // Abre el picker de categoría
          onToggleVisible:   () => _toggleVisible(e.id),   // Alterna visibilidad
          onEdit:            e.esPersonalizado ? () => _editCustomPictogram(e) : null,
          onDelete:          e.esPersonalizado ? () => _deleteCustomPictogram(e) : null,
        );
      },
    );
  }

  // ─── Bottom sheet: selector de categoría ─────────────────────────────────

  /// Muestra un bottom sheet con las 6 opciones de categoría.
  /// La categoría actual aparece marcada con un check verde.
  void _showCategoryPicker(PictoEntry entry) {
    final current = _efectiva(entry.id, entry.defaultCategoria);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min, // El sheet solo ocupa lo necesario
          children: [
            const SizedBox(height: 12),

            // Handle visual del sheet (barra gris redondeada)
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color:        Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  // Título con la etiqueta del pictograma que se está configurando
                  Text(
                    'Sección para "${entry.etiqueta}"',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            const Divider(),

            // Opciones de categoría: una por cada entrada de kCategoriasAsignables
            ...kCategoriasAsignables.map((opt) {
              final isSelected = opt.label == current; // ¿Es la categoría actual?
              return ListTile(
                leading: CircleAvatar(
                  radius:          18,
                  backgroundColor: opt.color.withValues(alpha: 0.12),
                  child: Icon(opt.icon, color: opt.color, size: 18),
                ),
                title: Text(
                  opt.label,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  ),
                ),
                // Marca de verificación solo en la opción seleccionada
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () async {
                  Navigator.pop(ctx); // Cerramos el sheet antes de mutar
                  await _setCategoria(entry.id, opt.label); // Persistimos el cambio
                },
              );
            }),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ─── Eliminar pictograma personalizado ───────────────────────────────────

  /// Elimina un pictograma personalizado del usuario de Firestore y Storage.
  /// Solo se puede llamar para entries con [esPersonalizado] == true.
  Future<void> _deleteCustomPictogram(PictoEntry entry) async {
    final firestoreId = entry.id.replaceFirst('custom_', '');
    await PictogramService.deletePictogramFor(widget.userId, firestoreId);
  }

  // ─── Editar pictograma personalizado ─────────────────────────────────────

  /// Edita nombre visible y texto de voz de un pictograma personalizado,
  /// conservando la imagen. Un error de escritura en comunicación
  /// aumentativa debe poder corregirse sin eliminar el pictograma.
  Future<void> _editCustomPictogram(PictoEntry entry) async {
    final firestoreId = entry.id.replaceFirst('custom_', '');
    // El PictoEntry no lleva textoTts; lo buscamos en la lista de customs.
    final custom = _customs.where((p) => p.id == firestoreId).firstOrNull;
    if (custom == null) return;

    final etiquetaController = TextEditingController(text: custom.etiqueta);
    final ttsController      = TextEditingController(text: custom.textoTts);

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Editar pictograma'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: etiquetaController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nombre visible',
                hintText: 'Ej: LAVAR MANOS',
              ),
              textCapitalization: TextCapitalization.characters,
              maxLength: 30,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: ttsController,
              decoration: const InputDecoration(
                labelText: 'Texto de voz',
                hintText: 'Lo que dirá al tocarlo',
              ),
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => Navigator.of(ctx).pop(true),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    final newEtiqueta = etiquetaController.text.trim();
    final newTts      = ttsController.text.trim();
    etiquetaController.dispose();
    ttsController.dispose();
    if (saved != true || newEtiqueta.isEmpty || !mounted) return;

    await PictogramService.updatePictogramFor(
      userId:      widget.userId,
      pictogramId: firestoreId,
      etiqueta:    newEtiqueta,
      textoTts:    newTts.isEmpty ? custom.textoTts : newTts,
    );
  }

  // ─── Restablecer toda la configuración ───────────────────────────────────

  /// Revierte todos los overrides de categoría y visibilidad al estado original.
  ///
  /// Muestra un diálogo de confirmación. Si se confirma, limpia todos los documentos
  /// de la colección `pictogramSettings` del usuario.
  Future<void> _resetAll() async {
    // Diálogo de confirmación: acción destructiva irreversible
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:    RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:   const Text('Restablecer configuración'),
        content: const Text(
          'Se restablecerán todas las categorías y visibilidades al estado original.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false), // Cancelar
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true), // Confirmar
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Restablecer'),
          ),
        ],
      ),
    );

    // Si el usuario cancela o cierra el diálogo, no hacemos nada
    if (confirmed != true) return;

    // Guardamos referencia antes de la operación asíncrona (para silenciar el warning)
    final ref = PictogramService.getPictogramSettingsStreamFor(widget.userId);

    // Iteramos sobre todos los IDs con overrides y los restablecemos
    final docsToDelete = _settings.keys.toList();
    for (final id in docsToDelete) {
      // Pasamos visible:true y categoria:null para limpiar el doc sin eliminarlo
      await PictogramService.updatePictogramSettingFor(
        userId:    widget.userId,
        pictoId:   id,
        categoria: null, // null → el servicio no escribe el campo
        visible:   true, // Restablece visibilidad a visible
      );
    }

    // Limpiamos el estado local inmediatamente para no esperar al próximo snapshot
    if (mounted) {
      setState(() => _settings = {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuración restablecida')),
      );
    }

    // Suprime el warning de "unused local variable" del ref del stream
    // ignore: unused_local_variable
    ref;
  }
}

// ─── Tarjeta de pictograma en cuadrícula ─────────────────────────────────────

/// Tarjeta individual para cada pictograma en la cuadrícula del gestor.
///
/// Muestra:
/// - Imagen del pictograma (SVG asset o imagen de red).
/// - Etiqueta bajo la imagen.
/// - Chip de categoría tocable (abre el selector de categoría).
/// - Botón de visibilidad en la esquina superior derecha.
/// - Punto azul en la esquina superior izquierda si tiene overrides activos.
class _PictoManagerCard extends StatelessWidget {
  final PictoEntry entry;           // Datos del pictograma
  final Map<String, dynamic> settings;     // Configuración actual (puede estar vacía)
  final String categoriaEfectiva;   // Categoría calculada (con posibles overrides)
  final bool isVisible;             // Si el pictograma es visible en el tablero
  final VoidCallback onCategoryTap; // Callback al tocar el chip de categoría
  final VoidCallback onToggleVisible; // Callback al tocar el botón de visibilidad
  final VoidCallback? onEdit;       // Solo para personalizados; null = no editable
  final VoidCallback? onDelete;     // Solo para personalizados; null = no se puede eliminar

  const _PictoManagerCard({
    required this.entry,
    required this.settings,
    required this.categoriaEfectiva,
    required this.isVisible,
    required this.onCategoryTap,
    required this.onToggleVisible,
    this.onEdit,
    this.onDelete,
  });

  void _showDeleteSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  entry.etiqueta,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const Divider(),
            if (onEdit != null)
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: Colors.blueGrey),
                title: const Text('Editar nombre y voz'),
                onTap: () {
                  Navigator.pop(ctx);
                  onEdit?.call();
                },
              ),
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title: const Text(
                'Eliminar pictograma',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(ctx);
                _confirmDelete(context);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Eliminar pictograma'),
        content: Text(
          '¿Eliminar "${entry.etiqueta}"? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              onDelete?.call();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Buscamos la opción de categoría para obtener su color e ícono
    final catOpt   = kCategoriasAsignables
        .where((c) => c.label == categoriaEfectiva)
        .firstOrNull;
    final catColor = catOpt?.color ?? Colors.grey; // Gris si la categoría no existe

    // Un pictograma está "modificado" si tiene override de categoría o está oculto.
    // Esto activa el borde azul y el punto indicador.
    final isModified =
        settings.containsKey('categoria') || settings['visible'] == false;

    return GestureDetector(
      // Long-press solo activo en pictogramas personalizados (onDelete != null)
      onLongPress: onDelete != null ? () => _showDeleteSheet(context) : null,
      child: AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      // Opacidad reducida al 45% cuando el pictograma está oculto para el usuario
      opacity: isVisible ? 1.0 : 0.45,
      child: Container(
        decoration: BoxDecoration(
          color:        Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            // Borde azul semitransparente si el picto tiene configuración modificada
            color: isModified
                ? Colors.blue.withValues(alpha: 0.3)
                : Colors.grey.shade200,
            width: isModified ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color:    Colors.grey.withValues(alpha: 0.07),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            // ── Contenido principal (imagen + etiqueta + chip) ────────────────
            Column(
              children: [
                // Área de imagen: ocupa el espacio disponible sobre la etiqueta
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 14, 8, 4),
                    child: _buildImage(), // SVG, asset o red según el tipo de entry
                  ),
                ),

                // Etiqueta del pictograma en negrita
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    entry.etiqueta,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize:   10,
                      fontWeight: FontWeight.bold,
                      // Texto gris con tachado cuando está oculto
                      color:      isVisible ? Colors.black87 : Colors.grey,
                      decoration: isVisible ? null : TextDecoration.lineThrough,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

                const SizedBox(height: 5),

                // Chip de categoría: tocarlo abre el picker de reasignación
                GestureDetector(
                  onTap: onCategoryTap,
                  child: Container(
                    margin:  const EdgeInsets.fromLTRB(6, 0, 6, 8),
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color:        catColor.withValues(alpha: 0.1),   // Fondo tenue del color
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: catColor.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Ícono pequeño de la categoría (si tiene opción válida)
                        if (catOpt != null)
                          Icon(catOpt.icon, size: 9, color: catColor),
                        const SizedBox(width: 3),
                        // Nombre de la categoría (truncado si es largo)
                        Flexible(
                          child: Text(
                            categoriaEfectiva,
                            style: TextStyle(
                              fontSize:   9,
                              color:      catColor,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 2),
                        // Flecha indicadora de que el chip es interactivo
                        Icon(Icons.arrow_drop_down, size: 11, color: catColor),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // ── Botón de visibilidad (esquina superior derecha) ───────────────
            Positioned(
              top: 2, right: 2,
              child: GestureDetector(
                onTap: onToggleVisible, // Llama a _toggleVisible del padre
                child: Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: isVisible
                        ? Colors.blueGrey.withValues(alpha: 0.12)
                        : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    // Ojo abierto = visible; ojo cerrado = oculto
                    isVisible
                        ? Icons.visibility_rounded
                        : Icons.visibility_off_rounded,
                    size:  12,
                    color: isVisible ? Colors.blueGrey : Colors.grey.shade400,
                  ),
                ),
              ),
            ),

            // ── Indicador de modificado (punto azul, esquina superior izquierda) ──
            // Aparece cuando el pictograma tiene alguna configuración personalizada
            if (isModified)
              Positioned(
                top: 4, left: 4,
                child: Container(
                  width: 7, height: 7,
                  decoration: const BoxDecoration(
                    color: Colors.blue, // Punto azul = tiene overrides activos
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    ),    // cierra AnimatedOpacity (child del GestureDetector)
  );     // cierra GestureDetector
  }

  Widget _buildImage() {
    // Caso 1: pictograma basado en icono Material (vocabulario extendido)
    if (entry.iconData != null) {
      final c = entry.iconColor ?? Colors.blueGrey;
      return Container(
        decoration: BoxDecoration(
          color: c.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Center(
          child: Icon(entry.iconData, size: 32, color: c),
        ),
      );
    }

    // Caso 2: pictograma del banco predefinido con SVG o PNG local
    if (entry.svgPath != null) {
      final path = entry.svgPath!;
      if (path.endsWith('.png') || path.endsWith('.jpg')) {
        return Image.asset(path, fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(Icons.image, color: Colors.grey));
      }
      return SvgPicture.asset(path, fit: BoxFit.contain);
    }

    // Caso 3 y 4: pictograma personalizado con URL o path de asset
    if (entry.imageUrl != null && entry.imageUrl!.isNotEmpty) {
      final url = entry.imageUrl!;

      if (url.startsWith('assets/')) {
        return url.endsWith('.svg')
            ? SvgPicture.asset(url, fit: BoxFit.contain)
            : Image.asset(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) => const Icon(Icons.image, color: Colors.grey),
              );
      }

      return Image.network(
        url,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const Icon(Icons.image, color: Colors.grey),
      );
    }

    return const Icon(Icons.image, color: Colors.grey);
  }
}
