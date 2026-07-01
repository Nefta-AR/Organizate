// ============================================================
// lib/features/onboarding/screens/super_experto_sheet.dart
// ============================================================
// Bottom sheet de descomposición de tareas con IA (Gemini).
//
// ## Paleta de colores
//
//   Acento principal: #7C5CBF (púrpura).
//   Fondo del sheet: neutral claro para reducir carga visual.
//
// ## Flujo principal
//
//   1. El usuario escribe un texto libre de la tarea a desglosar.
//   2. Al tocar "Generar plan", se llama a [_generarPlan]:
//        → IAService.desglosarEnPasos(texto) → Cloud Function Gemini.
//        → Devuelve lista de pasos (strings).
//   3. Los pasos se muestran en una lista editable.
//   4. Al confirmar, [_guardarSubtareas] hace un batch write a Firestore:
//        users/{uid}/tasks/{parentTaskId}/subtasks/{auto-id}
//
// ## Opciones de tiempo predefinidas
//
//   _opcionesTiempo: ['30 min', '1 hora', 'Medio día', 'Todo el día', 'Una semana']
//   Estas opciones se pasan a Gemini como contexto de duración estimada
//   para que los pasos generados sean coherentes con el tiempo disponible.
//
// ## Apertura
//
//   SuperExpertoSheet.show(context, parentTaskId: taskId)
//   Usa showModalBottomSheet con DraggableScrollableSheet.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../tda_focus/services/ia_service.dart';

// ── Paleta de colores interna ─────────────────────────────────────────────────
class _Palette {
  _Palette._();
  static const background  = Color(0xFFF5F7FA); // Gris muy claro (fondo del sheet)
  static const surface     = Colors.white;        // Fondo de tarjetas
  static const accent      = Color(0xFF7C5CBF);  // Púrpura principal
  static const accentLight = Color(0xFFEDE7F6);  // Púrpura muy claro (fondo de íconos)
  static const textDark    = Color(0xFF2D3748);  // Texto principal
  static const textMuted   = Color(0xFF718096);  // Texto secundario
  static const success     = Color(0xFF48BB78);  // Verde de confirmación
  static const errorBg     = Color(0xFFFFF5F5);  // Fondo del banner de error
  static const errorText   = Color(0xFFE53E3E);  // Texto de error
}

// Opciones de tiempo disponibles que se pasan a Gemini como contexto.
// Gemini ajusta la granularidad de los pasos según el tiempo disponible:
// - "30 minutos" → pasos muy pequeños
// - "Una semana" → pasos de mayor envergadura
const List<String> _opcionesTiempo = [
  '30 minutos',
  '1 hora',
  'Medio día',
  'Todo el día',
  'Una semana',
];

class SuperExpertoSheet extends StatefulWidget {
  const SuperExpertoSheet({super.key});

  // Método estático de apertura: permite abrir el sheet con una sola línea
  // desde cualquier pantalla sin necesitar el constructor directamente
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,  // Permite que el sheet ocupe más del 50% de pantalla
      backgroundColor: Colors.transparent, // Transparente para ver los bordes redondeados
      builder: (_) => const SuperExpertoSheet(),
    );
  }

  @override
  State<SuperExpertoSheet> createState() => _SuperExpertoSheetState();
}

class _SuperExpertoSheetState extends State<SuperExpertoSheet> {
  // ID de Firestore de la tarea padre seleccionada en el Dropdown
  String? _tareaId;

  // Texto descriptivo de la tarea (se pasa a Gemini para el desglose)
  String? _tareaTexto;

  // Tiempo disponible seleccionado (chip); afecta el contexto para Gemini
  String _tiempo = '1 hora';

  // true mientras espera la respuesta de IAService (Cloud Function)
  bool _cargando = false;

  // Mensaje de error de IAService o de Firestore; null si no hay error
  String? _error;

  // Lista de pasos generados por Gemini; cada Map tiene 'titulo' y 'tiempo_estimado'
  List<Map<String, String>>? _pasos;

  // true mientras se hace el batch write de los pasos a Firestore
  bool _guardando = false;

  // true después de guardar exitosamente (muestra banner verde y cierra el sheet)
  bool _guardadoExito = false;

  // Acceso rápido al usuario autenticado (garantizado porque AuthGate protege la ruta)
  User get _usuario => FirebaseAuth.instance.currentUser!;

  // Referencia a la subcolección 'tasks' del usuario actual
  CollectionReference<Map<String, dynamic>> get _tareasRef =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(_usuario.uid)
          .collection('tasks');

  // ── Llamar a Gemini via Cloud Function ───────────────────────────────────────

  Future<void> _generarPlan() async {
    // No hacer nada si no se ha seleccionado una tarea del Dropdown
    if (_tareaTexto == null) return;

    // Activamos el estado de carga y limpiamos resultados anteriores
    setState(() {
      _cargando = true;
      _pasos = null;       // Oculta resultados previos
      _error = null;       // Limpia error previo
      _guardadoExito = false;
    });

    try {
      // IAService.desglosarEnPasos llama a la Cloud Function 'desglosarTarea'
      // que internamente usa Gemini Flash para devolver una lista de pasos JSON
      final pasos = await IAService.desglosarEnPasos(
        tarea: _tareaTexto!,
        tiempoDisponible: _tiempo, // Ej: "1 hora" → Gemini ajusta granularidad
      );

      // Verificamos que el widget siga montado después del await asíncrono
      if (!mounted) return;

      // Guardamos los pasos en el estado para renderizarlos en _buildResultado()
      setState(() => _pasos = pasos);

    } on Exception catch (e) {
      if (!mounted) return;
      // Limpiamos el prefijo "Exception: " del toString() para un mensaje más limpio
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));

    } finally {
      // Siempre apagamos el spinner, incluso si hubo un error
      if (mounted) setState(() => _cargando = false);
    }
  }

  // ── Guardar los pasos generados como subtareas en Firestore ──────────────────

  Future<void> _guardarSubtareas() async {
    final pasos = _pasos;
    if (pasos == null || pasos.isEmpty) return; // Guard: no guardar si no hay pasos

    setState(() => _guardando = true);

    try {
      // Batch write: todos los pasos se crean en una sola operación atómica
      // Si uno falla, ninguno se guarda (consistencia garantizada)
      final batch = FirebaseFirestore.instance.batch();
      final ahora = Timestamp.now(); // Timestamp compartido para createdAt de todos

      for (final paso in pasos) {
        // doc() sin argumento genera un ID aleatorio para cada subtarea
        final docRef = _tareasRef.doc();

        batch.set(docRef, {
          'text': paso['titulo'],    // Nombre del paso generado por Gemini
          'category': 'Foco',        // Categoría predefinida para subtareas de IA
          'iconName': 'psychology',  // Icono cerebro para tareas cognitivas
          'colorName': 'purple',     // Púrpura: color de la sección Foco
          'done': false,             // Subtarea nueva, siempre pendiente
          'createdAt': ahora,        // Para ordenación cronológica
          'reminderMinutes': null,   // Sin recordatorio por defecto
          'parentTaskId': _tareaId,  // Vincula la subtarea con la tarea padre
          'generadoPorIA': true,     // Flag para estadísticas y filtrado
        });
      }

      // Confirma todas las escrituras en paralelo
      await batch.commit();

      if (!mounted) return;

      // Mostramos el banner de éxito brevemente antes de cerrar el sheet
      setState(() {
        _guardando = false;
        _guardadoExito = true;
      });

      // Pequeña pausa para que el usuario lea la confirmación
      await Future.delayed(const Duration(milliseconds: 1400));

      // Cerramos el sheet (pop sin valor de retorno)
      if (mounted) Navigator.of(context).pop();

    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al guardar: $e';
        _guardando = false;
      });
    }
  }

  // ── Construcción del widget principal ────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // DraggableScrollableSheet: permite arrastrar el sheet hacia arriba/abajo
    return DraggableScrollableSheet(
      initialChildSize: 0.72, // Ocupa 72% de la pantalla al abrirse
      minChildSize: 0.50,     // Mínimo 50% (no se puede colapsar más)
      maxChildSize: 0.95,     // Máximo 95% (casi pantalla completa)
      snap: true,             // Hace clic en posiciones fijas al soltar

      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: _Palette.background,
            // Bordes redondeados solo en la parte superior del sheet
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              // Barra drag handle (indicador de que el sheet es arrastrable)
              _buildHandle(),

              // Área scrollable del contenido
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController, // Conectado al DraggableScrollableSheet
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),        // Icono + título "Súper Experto"
                      const SizedBox(height: 28),
                      _buildSelectorTarea(), // Dropdown de tareas pendientes
                      const SizedBox(height: 24),
                      _buildSelectorTiempo(), // Chips de duración
                      const SizedBox(height: 28),
                      _buildBotonGenerar(),  // Botón "Generar Plan"
                      const SizedBox(height: 24),

                      // Sección de resultados (solo uno a la vez):
                      if (_cargando) _buildCargando(),              // Animación de espera
                      if (_error != null && !_cargando) _buildError(), // Banner de error
                      if (_pasos != null && !_cargando) _buildResultado(), // Lista de pasos
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Barra de arrastre del sheet ───────────────────────────────────────────────

  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        width: 40, height: 4,
        decoration: BoxDecoration(
          // Semitransparente para un look discreto
          color: _Palette.textMuted.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // ── Encabezado: icono + título + subtítulo ────────────────────────────────────

  Widget _buildHeader() {
    return Row(
      children: [
        // Contenedor circular con icono de varita mágica (IA)
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _Palette.accent.withValues(alpha: 0.12), // Fondo púrpura muy suave
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.auto_fix_high_rounded, // Varita → representa magia/IA
            color: _Palette.accent,
            size: 26,
          ),
        ),
        const SizedBox(width: 14),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Súper Experto',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _Palette.textDark,
              ),
            ),
            Text(
              'Divide y vencerás, un paso a la vez.',
              style: TextStyle(fontSize: 13, color: _Palette.textMuted),
            ),
          ],
        ),
      ],
    );
  }

  // ── Dropdown de selección de tarea ───────────────────────────────────────────

  Widget _buildSelectorTarea() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '¿Qué tarea quieres desglosar?',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _Palette.textDark,
          ),
        ),
        const SizedBox(height: 10),

        // StreamBuilder: escucha las tareas del usuario en tiempo real
        // El dropdown siempre muestra tareas actualizadas sin necesidad de recargar
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _tareasRef.orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snapshot) {
            // Cargando: spinner pequeño para no bloquear el UI
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }

            // Error de Firestore: banner de error discreto
            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Error al cargar tareas: ${snapshot.error}',
                  style: const TextStyle(color: Color(0xFFE53E3E), fontSize: 12),
                ),
              );
            }

            // Filtramos solo las tareas pendientes (done != true)
            // No tiene sentido desglosar tareas ya completadas
            final docs = (snapshot.data?.docs ?? [])
                .where((doc) => doc.data()['done'] != true)
                .toList();

            // Sin tareas pendientes: mensaje informativo
            if (docs.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _Palette.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _Palette.textMuted.withValues(alpha: 0.25),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: _Palette.textMuted, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'No tienes tareas pendientes.\n'
                        'Crea una desde la pantalla de Tareas.',
                        style: TextStyle(
                          color: _Palette.textMuted,
                          fontSize: 13,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }

            // Dropdown estilizado con borde condicional: gris normal, púrpura al enfocar
            return DropdownButtonFormField<String>(
              initialValue: _tareaId, // Conserva la selección previa si existe
              isExpanded: true,       // Ocupa todo el ancho disponible
              decoration: InputDecoration(
                filled: true,
                fillColor: _Palette.surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _Palette.textMuted.withValues(alpha: 0.3)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: _Palette.textMuted.withValues(alpha: 0.3)),
                ),
                // Borde púrpura al estar enfocado
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: _Palette.accent, width: 1.5),
                ),
              ),
              hint: const Text('Selecciona una tarea...'),

              // Construimos los ítems del dropdown con el texto de cada tarea
              items: docs.map((doc) {
                final texto = (doc.data()['text'] as String?) ?? 'Tarea sin nombre';
                return DropdownMenuItem<String>(
                  value: doc.id, // El valor es el ID de Firestore
                  child: Text(
                    texto,
                    overflow: TextOverflow.ellipsis, // Truncar textos largos
                    style: const TextStyle(fontSize: 14, color: _Palette.textDark),
                  ),
                );
              }).toList(),

              onChanged: (id) {
                if (id == null) return;
                // Buscamos el documento correspondiente al ID seleccionado
                final doc = docs.firstWhere((d) => d.id == id);
                setState(() {
                  _tareaId = id;
                  // Guardamos el texto para enviarlo a Gemini en _generarPlan()
                  _tareaTexto = (doc.data()['text'] as String?) ?? '';
                  // Limpiamos resultados anteriores al cambiar la tarea
                  _pasos = null;
                  _error = null;
                  _guardadoExito = false;
                });
              },
            );
          },
        ),
      ],
    );
  }

  // ── Chips de selección de tiempo disponible ───────────────────────────────────

  Widget _buildSelectorTiempo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '¿Cuánto tiempo tienes?',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: _Palette.textDark,
          ),
        ),
        const SizedBox(height: 10),

        // Wrap: los chips se envuelven automáticamente en múltiples filas si no caben
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _opcionesTiempo.map((opcion) {
            final selected = _tiempo == opcion; // true si este chip está seleccionado

            return ChoiceChip(
              label: Text(opcion),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _tiempo = opcion;
                  // Al cambiar el tiempo, los pasos anteriores ya no son válidos
                  _pasos = null;
                  _error = null;
                });
              },
              // Fondo lila suave cuando está seleccionado
              selectedColor: _Palette.accent.withValues(alpha: 0.15),
              checkmarkColor: _Palette.accent,
              backgroundColor: _Palette.surface,
              labelStyle: TextStyle(
                color: selected ? _Palette.accent : _Palette.textMuted,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
              // Borde púrpura si está seleccionado, gris si no
              side: BorderSide(
                color: selected
                    ? _Palette.accent
                    : _Palette.textMuted.withValues(alpha: 0.3),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Botón "Generar Plan" ─────────────────────────────────────────────────────

  Widget _buildBotonGenerar() {
    // El botón está habilitado solo si hay una tarea seleccionada y no está cargando
    final habilitado = _tareaTexto != null && !_cargando;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: habilitado ? _generarPlan : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _Palette.accent,
          // Color deshabilitado: púrpura semitransparente
          disabledBackgroundColor: _Palette.accent.withValues(alpha: 0.35),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        // Icono cambia a spinner circular mientras carga
        icon: _cargando
            ? SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.9)),
                ),
              )
            : const Icon(Icons.auto_fix_high_rounded, size: 20),
        // Texto cambia para dar feedback del estado
        label: Text(
          _cargando ? 'Generando...' : 'Generar Plan',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ── Animación de carga (mientras espera respuesta de Gemini) ─────────────────

  Widget _buildCargando() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _Palette.accent.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _Palette.accent.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Animación personalizada: anillo punteado que rota + icono central
          SizedBox(
            height: 64, width: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // TweenAnimationBuilder: rota de 0 a 2π en 2 segundos
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(seconds: 2),
                  builder: (context, value, _) => Transform.rotate(
                    angle: value * 2 * 3.14159, // Conversión de [0,1] a [0, 2π]
                    child: CustomPaint(
                      // _DashedRingPainter dibuja un anillo segmentado que rota
                      painter: _DashedRingPainter(
                        color: _Palette.accent.withValues(alpha: 0.2),
                        strokeWidth: 2,
                      ),
                      size: const Size(64, 64),
                    ),
                  ),
                ),
                // Icono central estático sobre el anillo rotatorio
                Container(
                  height: 48, width: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _Palette.accentLight,
                    boxShadow: [
                      BoxShadow(
                        color: _Palette.accent.withValues(alpha: 0.08),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.auto_fix_high_rounded,
                    color: _Palette.accent,
                    size: 24,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Consultando al experto...',
            style: TextStyle(color: _Palette.textMuted, fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 6),
          const Text(
            'Dividiendo tu tarea en pasos simples',
            style: TextStyle(color: _Palette.textMuted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ── Banner de error ───────────────────────────────────────────────────────────

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Palette.errorBg, // Fondo rojo muy claro
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Palette.errorText.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: _Palette.errorText, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _error ?? 'Error desconocido.',
              style: const TextStyle(color: _Palette.errorText, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ── Resultado: lista de pasos generados por Gemini ───────────────────────────

  Widget _buildResultado() {
    final pasos = _pasos!; // Garantizado no-null por el guard en build()
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Encabezado con número total de pasos generados
        Row(
          children: [
            const Icon(Icons.checklist_rounded, color: _Palette.accent, size: 20),
            const SizedBox(width: 8),
            Text(
              '${pasos.length} pasos generados',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: _Palette.textDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Renderizamos cada paso con su número (base-1 con e.key + 1)
        ...pasos.asMap().entries.map((e) => _buildPasoItem(e.key + 1, e.value)),
        const SizedBox(height: 20),

        // Mostramos confirmación de éxito o el botón de guardar
        if (_guardadoExito) _buildConfirmacionExito() else _buildBotonGuardar(),
        const SizedBox(height: 8),
      ],
    );
  }

  // ── Tarjeta de un paso individual ────────────────────────────────────────────

  Widget _buildPasoItem(int numero, Map<String, String> paso) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Número de paso en un círculo púrpura suave
          Container(
            width: 28, height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: _Palette.accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Text(
              '$numero',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: _Palette.accent,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Título del paso y tiempo estimado (si Gemini lo proporcionó)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paso['titulo'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: _Palette.textDark,
                  ),
                ),
                // tiempo_estimado es opcional en la respuesta de Gemini
                if ((paso['tiempo_estimado'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded,
                          size: 12, color: _Palette.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        paso['tiempo_estimado']!,
                        style: const TextStyle(fontSize: 12, color: _Palette.textMuted),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Botón "Guardar subtareas" ─────────────────────────────────────────────────

  Widget _buildBotonGuardar() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        // Deshabilitado durante el guardado para evitar escrituras duplicadas
        onPressed: _guardando ? null : _guardarSubtareas,
        style: ElevatedButton.styleFrom(
          backgroundColor: _Palette.success,
          disabledBackgroundColor: _Palette.success.withValues(alpha: 0.4),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        // Spinner durante el guardado
        icon: _guardando
            ? const SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.save_alt_rounded, size: 20),
        label: Text(
          _guardando ? 'Guardando...' : 'Guardar subtareas en Tareas',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ── Banner de éxito al guardar ────────────────────────────────────────────────

  Widget _buildConfirmacionExito() {
    // Se muestra brevemente antes de que _guardarSubtareas() cierre el sheet
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Palette.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _Palette.success.withValues(alpha: 0.4)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, color: _Palette.success, size: 20),
          SizedBox(width: 10),
          Text(
            '¡Subtareas guardadas exitosamente!',
            style: TextStyle(
              color: _Palette.success,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Painter del anillo punteado animado ───────────────────────────────────────
// Dibuja un anillo formado por arcos separados (efecto de trazo discontinuo).
// Se usa en _buildCargando() con TweenAnimationBuilder para simular rotación.

class _DashedRingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _DashedRingPainter({required this.color, this.strokeWidth = 2});

  @override
  void paint(Canvas canvas, Size size) {
    // Centro del canvas para dibujar el arco circuncentrado
    final center = Offset(size.width / 2, size.height / 2);

    // Radio: la mitad del tamaño del widget, descontando el grosor del trazo
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    // Parámetros del patrón discontinuo (en radianes)
    const dashAngle = 0.12; // Ángulo que ocupa cada segmento visible
    const gapAngle  = 0.08; // Ángulo del hueco entre segmentos
    const step      = dashAngle + gapAngle; // Paso total por iteración

    // Dibujamos arcos de dashAngle con gaps de gapAngle hasta completar 2π
    for (var angle = 0.0; angle < 2 * 3.14159; angle += step) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        angle,     // Ángulo de inicio del arco actual
        dashAngle, // Extensión angular del arco
        false,     // useCenter: false → arco abierto (no relleno de sector)
        paint,
      );
    }
  }

  @override
  // shouldRepaint: false porque los parámetros no cambian durante la animación
  // (el efecto de rotación lo maneja Transform.rotate en el TweenAnimationBuilder)
  bool shouldRepaint(_DashedRingPainter oldDelegate) => false;
}
