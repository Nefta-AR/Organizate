import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/ia_service.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Paleta calma — misma base que el resto de la app.
// ─────────────────────────────────────────────────────────────────────────────
class _Palette {
  _Palette._();
  static const background = Color(0xFFF5F7FA);
  static const surface = Colors.white;
  static const accent =
      Color(0xFF7C5CBF); // Púrpura IA (identidad del Súper Experto)
  static const textDark = Color(0xFF2D3748);
  static const textMuted = Color(0xFF718096);
  static const success = Color(0xFF48BB78);
  static const errorBg = Color(0xFFFFF5F5);
  static const errorText = Color(0xFFE53E3E);
}

/// Opciones de tiempo disponible que se presentan al usuario.
const List<String> _opcionesTiempo = [
  '30 minutos',
  '1 hora',
  'Medio día',
  'Todo el día',
  'Una semana',
];

// ─────────────────────────────────────────────────────────────────────────────
/// Modal "Súper Experto": lee las tareas pendientes del usuario, envía la
/// seleccionada a Gemini y muestra el plan de pasos resultante.
///
/// Uso desde cualquier pantalla:
/// ```dart
/// SuperExpertoSheet.show(context);
/// ```
// ─────────────────────────────────────────────────────────────────────────────
class SuperExpertoSheet extends StatefulWidget {
  const SuperExpertoSheet({super.key});

  /// Abre el modal desde cualquier pantalla de la app.
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const SuperExpertoSheet(),
    );
  }

  @override
  State<SuperExpertoSheet> createState() => _SuperExpertoSheetState();
}

class _SuperExpertoSheetState extends State<SuperExpertoSheet> {
  // ── Selección del usuario ─────────────────────────────────────────────────
  String? _tareaId; // ID del documento Firestore seleccionado
  String? _tareaTexto; // Texto de la tarea (se envía a la IA)
  String _tiempo = '1 hora';

  // ── Estado de la IA ───────────────────────────────────────────────────────
  bool _cargando = false;
  String? _error;
  List<Map<String, String>>? _pasos; // null = sin resultado todavía

  // ── Estado del guardado ───────────────────────────────────────────────────
  bool _guardando = false;
  bool _guardadoExito = false;

  // ── Referencias Firebase ──────────────────────────────────────────────────
  User get _usuario => FirebaseAuth.instance.currentUser!;

  CollectionReference<Map<String, dynamic>> get _tareasRef =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(_usuario.uid)
          .collection('tasks');

  // ─────────────────────────────────────────────────────────────────────────
  // LÓGICA
  // ─────────────────────────────────────────────────────────────────────────

  /// Llama a IAService y actualiza el estado con el resultado.
  Future<void> _generarPlan() async {
    if (_tareaTexto == null) return;

    setState(() {
      _cargando = true;
      _pasos = null;
      _error = null;
      _guardadoExito = false;
    });

    try {
      final pasos = await IAService.desglosarEnPasos(
        tarea: _tareaTexto!,
        tiempoDisponible: _tiempo,
      );
      if (!mounted) return;
      setState(() => _pasos = pasos);
    } on Exception catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  /// Escribe todos los pasos como tareas independientes en Firestore (batch write).
  Future<void> _guardarSubtareas() async {
    final pasos = _pasos;
    if (pasos == null || pasos.isEmpty) return;

    setState(() => _guardando = true);

    try {
      final batch = FirebaseFirestore.instance.batch();
      final ahora = Timestamp.now();

      for (final paso in pasos) {
        final docRef = _tareasRef.doc(); // ID automático
        batch.set(docRef, {
          'text': paso['titulo'],
          'category': 'Foco',
          'iconName': 'psychology',
          'colorName': 'purple',
          'done': false,
          'createdAt': ahora,
          'reminderMinutes': null,
          // Metadatos opcionales para filtros o historial futuro.
          'parentTaskId': _tareaId,
          'generadoPorIA': true,
        });
      }

      await batch.commit();
      if (!mounted) return;

      setState(() {
        _guardando = false;
        _guardadoExito = true;
      });

      // Pequeña pausa para que el usuario vea el feedback antes de cerrar.
      await Future.delayed(const Duration(milliseconds: 1400));
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al guardar: $e';
        _guardando = false;
      });
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.72,
      minChildSize: 0.50,
      maxChildSize: 0.95,
      snap: true,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: _Palette.background,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              _buildHandle(),
              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      const SizedBox(height: 28),

                      // Paso 1 — Selección de tarea desde Firestore
                      _buildSelectorTarea(),
                      const SizedBox(height: 24),

                      // Paso 2 — Selección de tiempo disponible
                      _buildSelectorTiempo(),
                      const SizedBox(height: 28),

                      // Paso 3 — Botón de acción
                      _buildBotonGenerar(),
                      const SizedBox(height: 24),

                      // Paso 4 — Estado: cargando / error / resultado
                      if (_cargando) _buildCargando(),
                      if (_error != null && !_cargando) _buildError(),
                      if (_pasos != null && !_cargando) _buildResultado(),
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

  // ── Pastilla de arrastre ──────────────────────────────────────────────────
  Widget _buildHandle() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: _Palette.textMuted.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  // ── Encabezado con ícono y descripción ───────────────────────────────────
  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _Palette.accent.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.auto_fix_high_rounded,
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

  // ── Dropdown de tareas pendientes (StreamBuilder → Firestore) ─────────────
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
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _tareasRef.orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snapshot) {
            // Estado de espera
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }

            // Error de Firestore (ej: índice faltante, permisos)
            if (snapshot.hasError) {
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF5F5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  'Error al cargar tareas: ${snapshot.error}',
                  style:
                      const TextStyle(color: Color(0xFFE53E3E), fontSize: 12),
                ),
              );
            }

            // Filtra en Dart para evitar índice compuesto en Firestore
            final docs = (snapshot.data?.docs ?? [])
                .where((doc) => doc.data()['done'] != true)
                .toList();

            // Sin tareas pendientes
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
                    Icon(Icons.info_outline,
                        color: _Palette.textMuted, size: 20),
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

            // Dropdown con las tareas pendientes
            return DropdownButtonFormField<String>(
              initialValue: _tareaId,
              isExpanded: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: _Palette.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _Palette.textMuted.withValues(alpha: 0.3),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: _Palette.textMuted.withValues(alpha: 0.3),
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: _Palette.accent,
                    width: 1.5,
                  ),
                ),
              ),
              hint: const Text('Selecciona una tarea...'),
              items: docs.map((doc) {
                final texto =
                    (doc.data()['text'] as String?) ?? 'Tarea sin nombre';
                return DropdownMenuItem<String>(
                  value: doc.id,
                  child: Text(
                    texto,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      color: _Palette.textDark,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (id) {
                if (id == null) return;
                final doc = docs.firstWhere((d) => d.id == id);
                setState(() {
                  _tareaId = id;
                  _tareaTexto = (doc.data()['text'] as String?) ?? '';
                  // Resetea el resultado anterior al cambiar de tarea.
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

  // ── ChoiceChips de tiempo ─────────────────────────────────────────────────
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
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _opcionesTiempo.map((opcion) {
            final selected = _tiempo == opcion;
            return ChoiceChip(
              label: Text(opcion),
              selected: selected,
              onSelected: (_) {
                setState(() {
                  _tiempo = opcion;
                  // Resetea el resultado al cambiar parámetros.
                  _pasos = null;
                  _error = null;
                });
              },
              selectedColor: _Palette.accent.withValues(alpha: 0.15),
              checkmarkColor: _Palette.accent,
              backgroundColor: _Palette.surface,
              labelStyle: TextStyle(
                color: selected ? _Palette.accent : _Palette.textMuted,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 13,
              ),
              side: BorderSide(
                color: selected
                    ? _Palette.accent
                    : _Palette.textMuted.withValues(alpha: 0.3),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── Botón principal "Generar Plan" ────────────────────────────────────────
  Widget _buildBotonGenerar() {
    final habilitado = _tareaTexto != null && !_cargando;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: habilitado ? _generarPlan : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _Palette.accent,
          disabledBackgroundColor: _Palette.accent.withValues(alpha: 0.35),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        icon: const Icon(Icons.auto_fix_high_rounded, size: 20),
        label: const Text(
          'Generar Plan',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ── Indicador de carga ────────────────────────────────────────────────────
  Widget _buildCargando() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 36),
      child: Center(
        child: Column(
          children: [
            CircularProgressIndicator(color: _Palette.accent, strokeWidth: 3),
            SizedBox(height: 16),
            Text(
              'Consultando al experto...',
              style: TextStyle(color: _Palette.textMuted, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  // ── Mensaje de error ──────────────────────────────────────────────────────
  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Palette.errorBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _Palette.errorText.withValues(alpha: 0.4),
        ),
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

  // ── Resultado de la IA ────────────────────────────────────────────────────
  Widget _buildResultado() {
    final pasos = _pasos!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabecera del resultado
        Row(
          children: [
            const Icon(Icons.checklist_rounded,
                color: _Palette.accent, size: 20),
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

        // Lista de pasos
        ...pasos.asMap().entries.map(
              (e) => _buildPasoItem(e.key + 1, e.value),
            ),

        const SizedBox(height: 20),

        // Botón guardar o confirmación de éxito
        if (_guardadoExito) _buildConfirmacionExito() else _buildBotonGuardar(),

        const SizedBox(height: 8),
      ],
    );
  }

  // ── Tarjeta de un paso individual ─────────────────────────────────────────
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
          // Número de paso en círculo
          Container(
            width: 28,
            height: 28,
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

          // Título y tiempo estimado
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
                if ((paso['tiempo_estimado'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 12,
                        color: _Palette.textMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        paso['tiempo_estimado']!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: _Palette.textMuted,
                        ),
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

  // ── Botón "Guardar subtareas" ─────────────────────────────────────────────
  Widget _buildBotonGuardar() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _guardando ? null : _guardarSubtareas,
        style: ElevatedButton.styleFrom(
          backgroundColor: _Palette.success,
          disabledBackgroundColor: _Palette.success.withValues(alpha: 0.4),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        icon: _guardando
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
            : const Icon(Icons.save_alt_rounded, size: 20),
        label: Text(
          _guardando ? 'Guardando...' : 'Guardar subtareas en Tareas',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  // ── Confirmación visual tras guardar ──────────────────────────────────────
  Widget _buildConfirmacionExito() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Palette.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _Palette.success.withValues(alpha: 0.4),
        ),
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
