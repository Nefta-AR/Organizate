import 'package:flutter/material.dart';
import 'package:simple/core/services/pictogram_service.dart';

// Categorías disponibles para asignar
const kCategoriasAsignables = [
  _CatOption('Mañana', Icons.wb_sunny_rounded, Color(0xFFFFA726)),
  _CatOption('Tarde', Icons.wb_cloudy_rounded, Color(0xFF42A5F5)),
  _CatOption('Noche', Icons.nights_stay_rounded, Color(0xFF5C6BC0)),
  _CatOption('Comida', Icons.restaurant_rounded, Color(0xFF66BB6A)),
  _CatOption('Emociones', Icons.emoji_emotions_rounded, Color(0xFFEC407A)),
  _CatOption('Acciones', Icons.directions_run_rounded, Color(0xFF26C6DA)),
];

class _CatOption {
  final String label;
  final IconData icon;
  final Color color;
  const _CatOption(this.label, this.icon, this.color);
}

// ─── Banco de pictogramas predeterminados (compartido con paciente y tutor) ───

const List<PictoEntry> kBancoBuiltins = [
  PictoEntry(id: 'm1', svgPath: 'assets/images/pictogramas/ducha.svg',          etiqueta: 'DESPERTAR',    defaultCategoria: 'Mañana',   esPersonalizado: false),
  PictoEntry(id: 'm2', svgPath: 'assets/images/pictogramas/lavar-manos.svg',    etiqueta: 'LAVAR CARA',   defaultCategoria: 'Mañana',   esPersonalizado: false),
  PictoEntry(id: 'm3', svgPath: 'assets/images/pictogramas/cepillar-dientes.svg',etiqueta: 'DIENTES',     defaultCategoria: 'Mañana',   esPersonalizado: false),
  PictoEntry(id: 'm4', svgPath: 'assets/images/pictogramas/colegio.svg',         etiqueta: 'COLEGIO',     defaultCategoria: 'Mañana',   esPersonalizado: false),
  PictoEntry(id: 't1', svgPath: 'assets/images/pictogramas/almuerzo.svg',        etiqueta: 'ALMORZAR',    defaultCategoria: 'Tarde',    esPersonalizado: false),
  PictoEntry(id: 't2', svgPath: 'assets/images/pictogramas/computador.svg',      etiqueta: 'TAREAS TECH', defaultCategoria: 'Tarde',    esPersonalizado: false),
  PictoEntry(id: 't3', svgPath: 'assets/images/pictogramas/once.svg',            etiqueta: 'MERIENDA',    defaultCategoria: 'Tarde',    esPersonalizado: false),
  PictoEntry(id: 't4', svgPath: 'assets/images/pictogramas/pasear.svg',          etiqueta: 'JUGAR',       defaultCategoria: 'Tarde',    esPersonalizado: false),
  PictoEntry(id: 'n1', svgPath: 'assets/images/pictogramas/desayuno.svg',        etiqueta: 'CENA',        defaultCategoria: 'Noche',    esPersonalizado: false),
  PictoEntry(id: 'n2', svgPath: 'assets/images/pictogramas/baño.svg',            etiqueta: 'BAÑO',        defaultCategoria: 'Noche',    esPersonalizado: false),
  PictoEntry(id: 'n3', svgPath: 'assets/images/pictogramas/vestir.svg',          etiqueta: 'PIJAMA',      defaultCategoria: 'Noche',    esPersonalizado: false),
  PictoEntry(id: 'n4', svgPath: 'assets/images/pictogramas/casa.svg',            etiqueta: 'DORMIR',      defaultCategoria: 'Noche',    esPersonalizado: false),
  PictoEntry(id: 'c1', svgPath: 'assets/images/pictogramas/beber.svg',           etiqueta: 'AGUA',        defaultCategoria: 'Comida',   esPersonalizado: false),
  PictoEntry(id: 'c2', svgPath: 'assets/images/pictogramas/mochila.svg',         etiqueta: 'LONCHERA',    defaultCategoria: 'Comida',   esPersonalizado: false),
  PictoEntry(id: 'c3', svgPath: 'assets/images/pictogramas/comprar.svg',         etiqueta: 'COMPRAR',     defaultCategoria: 'Comida',   esPersonalizado: false),
  PictoEntry(id: 'e1', svgPath: 'assets/images/pictogramas/feliz.svg',           etiqueta: 'FELIZ',       defaultCategoria: 'Emociones',esPersonalizado: false),
  PictoEntry(id: 'e2', svgPath: 'assets/images/pictogramas/cansado.svg',         etiqueta: 'CANSADO',     defaultCategoria: 'Emociones',esPersonalizado: false),
  PictoEntry(id: 'e3', svgPath: 'assets/images/pictogramas/estoy-bien.svg',      etiqueta: 'BIEN',        defaultCategoria: 'Emociones',esPersonalizado: false),
  PictoEntry(id: 'e4', svgPath: 'assets/images/pictogramas/ayuda.svg',           etiqueta: 'AYUDA',       defaultCategoria: 'Emociones',esPersonalizado: false),
  PictoEntry(id: 'e5', svgPath: 'assets/images/pictogramas/alto.svg',            etiqueta: 'NO',          defaultCategoria: 'Emociones',esPersonalizado: false),
  PictoEntry(id: 'a1', svgPath: 'assets/images/pictogramas/calle.svg',           etiqueta: 'SALIR',       defaultCategoria: 'Acciones', esPersonalizado: false),
  PictoEntry(id: 'a2', svgPath: 'assets/images/pictogramas/limpiar.svg',         etiqueta: 'LIMPIAR',     defaultCategoria: 'Acciones', esPersonalizado: false),
  PictoEntry(id: 'a3', svgPath: 'assets/images/pictogramas/doctor.svg',          etiqueta: 'DOCTOR',      defaultCategoria: 'Acciones', esPersonalizado: false),
  PictoEntry(id: 'a4', svgPath: 'assets/images/pictogramas/estudiar.svg',        etiqueta: 'ESTUDIAR',    defaultCategoria: 'Acciones', esPersonalizado: false),
  PictoEntry(id: 'a5', svgPath: 'assets/images/pictogramas/libro.svg',           etiqueta: 'LEER',        defaultCategoria: 'Acciones', esPersonalizado: false),
  PictoEntry(id: 'a6', svgPath: 'assets/images/pictogramas/detente.svg',         etiqueta: 'DETENTE',     defaultCategoria: 'Acciones', esPersonalizado: false),
  PictoEntry(id: 'a7', svgPath: 'assets/images/pictogramas/hospital.svg',        etiqueta: 'HOSPITAL',    defaultCategoria: 'Acciones', esPersonalizado: false),
  PictoEntry(id: 'a8', svgPath: 'assets/images/pictogramas/perro.svg',           etiqueta: 'PERRO',       defaultCategoria: 'Acciones', esPersonalizado: false),
  PictoEntry(id: 'a9', svgPath: 'assets/images/pictogramas/compras.svg',         etiqueta: 'COMPRAS',     defaultCategoria: 'Acciones', esPersonalizado: false),
];

// ─── Modelo mínimo para que el manager pueda mostrar cualquier pictograma ─────

class PictoEntry {
  final String id;           // 'm1', 't2', 'custom_abc'
  final String? svgPath;     // asset path para built-in
  final String? imageUrl;    // URL para custom
  final String etiqueta;
  final String defaultCategoria;
  final bool esPersonalizado;

  const PictoEntry({
    required this.id,
    this.svgPath,
    this.imageUrl,
    required this.etiqueta,
    required this.defaultCategoria,
    required this.esPersonalizado,
  });
}

// ─── Pantalla principal ───────────────────────────────────────────────────────

class PictogramManagerScreen extends StatefulWidget {
  final String userId;
  final String userName;
  final List<PictoEntry> builtins;   // banco de pictogramas del paciente

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
  // settings cargados desde Firestore: pictoId -> {categoria, visible}
  Map<String, Map<String, dynamic>> _settings = {};
  bool _loadingSettings = true;

  // custom pictograms del paciente
  List<PictogramaPersonalizado> _customs = [];
  bool _loadingCustoms = true;

  // tab seleccionada en el filtro superior
  String? _filterCat; // null = todas

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadCustoms();
  }

  void _loadSettings() {
    PictogramService.getPictogramSettingsStreamFor(widget.userId).listen(
      (s) {
        if (!mounted) return;
        setState(() {
          _settings = s;
          _loadingSettings = false;
        });
      },
      onError: (_) {
        if (mounted) setState(() => _loadingSettings = false);
      },
    );
  }

  void _loadCustoms() {
    PictogramService.getCustomPictogramsStreamFor(widget.userId).listen(
      (list) {
        if (!mounted) return;
        setState(() {
          _customs = list;
          _loadingCustoms = false;
        });
      },
      onError: (_) {
        if (mounted) setState(() => _loadingCustoms = false);
      },
    );
  }

  // Devuelve la categoría efectiva (override o default)
  String _efectiva(String id, String defaultCat) =>
      _settings[id]?['categoria'] as String? ?? defaultCat;

  // Devuelve si el picto es visible (default true)
  bool _visible(String id) => _settings[id]?['visible'] != false;

  Future<void> _setCategoria(String id, String newCat) async {
    setState(() => _settings[id] = {...?_settings[id], 'categoria': newCat});
    await PictogramService.updatePictogramSettingFor(
      userId: widget.userId,
      pictoId: id,
      categoria: newCat,
    );
  }

  Future<void> _toggleVisible(String id) async {
    final current = _visible(id);
    setState(() => _settings[id] = {...?_settings[id], 'visible': !current});
    await PictogramService.updatePictogramSettingFor(
      userId: widget.userId,
      pictoId: id,
      visible: !current,
    );
  }

  // Construye la lista combinada de todos los pictos
  List<PictoEntry> get _allEntries {
    final builtins = widget.builtins;
    final customs = _customs.map((p) => PictoEntry(
          id: 'custom_${p.id}',
          imageUrl: p.imageUrl,
          etiqueta: p.etiqueta,
          defaultCategoria: p.categoria,
          esPersonalizado: true,
        ));
    return [...builtins, ...customs];
  }

  List<PictoEntry> get _filtered {
    final all = _allEntries;
    if (_filterCat == null) return all;
    return all
        .where((e) => _efectiva(e.id, e.defaultCategoria) == _filterCat)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final loading = _loadingSettings || _loadingCustoms;

    return Scaffold(
      appBar: AppBar(
        title: Text('Pictogramas de ${widget.userName}'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (!loading)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: TextButton.icon(
                onPressed: _resetAll,
                icon: const Icon(Icons.restore, size: 18),
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
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildFilterBar(),
                _buildLegend(),
                Expanded(child: _buildList()),
              ],
            ),
    );
  }

  Widget _buildFilterBar() {
    final cats = [null, ...kCategoriasAsignables.map((c) => c.label)];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemCount: cats.length,
        itemBuilder: (_, i) {
          final cat = cats[i];
          final selected = _filterCat == cat;
          final opt = cat == null
              ? null
              : kCategoriasAsignables.firstWhere((c) => c.label == cat);
          return GestureDetector(
            onTap: () => setState(() => _filterCat = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: selected
                    ? (opt?.color ?? Colors.blueGrey).withValues(alpha: 0.15)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: selected
                      ? (opt?.color ?? Colors.blueGrey)
                      : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (opt != null) ...[
                    Icon(opt.icon,
                        size: 13,
                        color: selected ? opt.color : Colors.grey.shade600),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    cat ?? 'Todos',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight:
                          selected ? FontWeight.w600 : FontWeight.normal,
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

  Widget _buildLegend() {
    final hidden = _allEntries.where((e) => !_visible(e.id)).length;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        children: [
          Text(
            '${_allEntries.length} pictogramas · $hidden ocultos',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
          const Spacer(),
          const Icon(Icons.touch_app, size: 13, color: Colors.grey),
          const SizedBox(width: 4),
          Text(
            'Toca la categoría para cambiarla',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    final entries = _filtered;
    if (entries.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.image_search, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 8),
            Text('Sin pictogramas en esta sección',
                style: TextStyle(color: Colors.grey.shade500)),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 6),
      itemBuilder: (context, i) => _PictoManagerTile(
        entry: entries[i],
        settings: _settings[entries[i].id] ?? {},
        categoriaEfectiva:
            _efectiva(entries[i].id, entries[i].defaultCategoria),
        isVisible: _visible(entries[i].id),
        onCategoryTap: () => _showCategoryPicker(entries[i]),
        onToggleVisible: () => _toggleVisible(entries[i].id),
      ),
    );
  }

  void _showCategoryPicker(PictoEntry entry) {
    final current = _efectiva(entry.id, entry.defaultCategoria);
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
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Text(
                    'Sección para "${entry.etiqueta}"',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            const Divider(),
            ...kCategoriasAsignables.map((opt) {
              final isSelected = opt.label == current;
              return ListTile(
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: opt.color.withValues(alpha: 0.12),
                  child: Icon(opt.icon, color: opt.color, size: 18),
                ),
                title: Text(opt.label,
                    style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal)),
                trailing: isSelected
                    ? const Icon(Icons.check, color: Colors.green)
                    : null,
                onTap: () async {
                  Navigator.pop(ctx);
                  await _setCategoria(entry.id, opt.label);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _resetAll() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Restablecer configuración'),
        content: const Text(
            'Se restablecerán todas las categorías y visibilidades al estado original.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Restablecer'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final ref = PictogramService.getPictogramSettingsStreamFor(widget.userId);
    // Eliminar todos los docs de settings para este usuario
    final docsToDelete = _settings.keys.toList();
    for (final id in docsToDelete) {
      await PictogramService.updatePictogramSettingFor(
        userId: widget.userId,
        pictoId: id,
        categoria: null,
        visible: true,
      );
    }
    // Limpiar localmente
    if (mounted) {
      setState(() => _settings = {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Configuración restablecida')),
      );
    }
    // ignore: unused_local_variable
    ref; // suppress unused warning
  }
}

// ─── Tile de un pictograma en el manager ──────────────────────────────────────

class _PictoManagerTile extends StatelessWidget {
  final PictoEntry entry;
  final Map<String, dynamic> settings;
  final String categoriaEfectiva;
  final bool isVisible;
  final VoidCallback onCategoryTap;
  final VoidCallback onToggleVisible;

  const _PictoManagerTile({
    required this.entry,
    required this.settings,
    required this.categoriaEfectiva,
    required this.isVisible,
    required this.onCategoryTap,
    required this.onToggleVisible,
  });

  @override
  Widget build(BuildContext context) {
    final catOpt = kCategoriasAsignables
        .where((c) => c.label == categoriaEfectiva)
        .firstOrNull;
    final catColor = catOpt?.color ?? Colors.grey;
    final isModified = settings.containsKey('categoria') || settings['visible'] == false;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: isVisible ? 1.0 : 0.45,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isModified
                ? Colors.blue.withValues(alpha: 0.3)
                : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 64,
              height: 64,
              margin: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              clipBehavior: Clip.antiAlias,
              child: _buildImage(),
            ),

            // Label + category badge
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            entry.etiqueta,
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: isVisible
                                  ? Colors.black87
                                  : Colors.grey,
                              decoration: isVisible
                                  ? null
                                  : TextDecoration.lineThrough,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isModified) ...[
                          const SizedBox(width: 4),
                          const Icon(Icons.edit,
                              size: 11, color: Colors.blue),
                        ],
                      ],
                    ),
                    const SizedBox(height: 5),
                    // Category chip (tappable)
                    GestureDetector(
                      onTap: onCategoryTap,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: catColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (catOpt != null)
                              Icon(catOpt.icon,
                                  size: 11, color: catColor),
                            const SizedBox(width: 4),
                            Text(
                              categoriaEfectiva,
                              style: TextStyle(
                                  fontSize: 11,
                                  color: catColor,
                                  fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(width: 3),
                            Icon(Icons.arrow_drop_down,
                                size: 13, color: catColor),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Visibility toggle
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Icon(
                  isVisible
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: isVisible
                      ? Colors.blueGrey
                      : Colors.grey.shade400,
                ),
                tooltip: isVisible ? 'Ocultar' : 'Mostrar',
                onPressed: onToggleVisible,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    if (entry.svgPath != null) {
      return Image.asset(
        entry.svgPath!,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) =>
            const Icon(Icons.image, color: Colors.grey),
      );
    }
    if (entry.imageUrl != null && entry.imageUrl!.isNotEmpty) {
      final isAsset = entry.imageUrl!.startsWith('assets/');
      if (isAsset) {
        return Image.asset(entry.imageUrl!,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.image, color: Colors.grey));
      }
      return Image.network(entry.imageUrl!,
          fit: BoxFit.contain,
          errorBuilder: (_, __, ___) =>
              const Icon(Icons.image, color: Colors.grey));
    }
    return const Icon(Icons.image, color: Colors.grey);
  }
}
