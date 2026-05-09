// lib/screens/super_experto_sheet.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../tda_focus/services/ia_service.dart';

class _Palette {
  _Palette._();
  static const background = Color(0xFFF5F7FA);
  static const surface = Colors.white;
  static const accent = Color(0xFF7C5CBF);
  static const accentLight = Color(0xFFEDE7F6);
  static const textDark = Color(0xFF2D3748);
  static const textMuted = Color(0xFF718096);
  static const success = Color(0xFF48BB78);
  static const errorBg = Color(0xFFFFF5F5);
  static const errorText = Color(0xFFE53E3E);
}

const List<String> _opcionesTiempo = [
  '30 minutos',
  '1 hora',
  'Medio día',
  'Todo el día',
  'Una semana',
];

class SuperExpertoSheet extends StatefulWidget {
  const SuperExpertoSheet({super.key});

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
  String? _tareaId;
  String? _tareaTexto;
  String _tiempo = '1 hora';

  bool _cargando = false;
  String? _error;
  List<Map<String, String>>? _pasos;

  bool _guardando = false;
  bool _guardadoExito = false;

  User get _usuario => FirebaseAuth.instance.currentUser!;

  CollectionReference<Map<String, dynamic>> get _tareasRef =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(_usuario.uid)
          .collection('tasks');

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

  Future<void> _guardarSubtareas() async {
    final pasos = _pasos;
    if (pasos == null || pasos.isEmpty) return;
    setState(() => _guardando = true);
    try {
      final batch = FirebaseFirestore.instance.batch();
      final ahora = Timestamp.now();
      for (final paso in pasos) {
        final docRef = _tareasRef.doc();
        batch.set(docRef, {
          'text': paso['titulo'],
          'category': 'Foco',
          'iconName': 'psychology',
          'colorName': 'purple',
          'done': false,
          'createdAt': ahora,
          'reminderMinutes': null,
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
                      _buildSelectorTarea(),
                      const SizedBox(height: 24),
                      _buildSelectorTiempo(),
                      const SizedBox(height: 28),
                      _buildBotonGenerar(),
                      const SizedBox(height: 24),
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
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              );
            }
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
            final docs = (snapshot.data?.docs ?? [])
                .where((doc) => doc.data()['done'] != true)
                .toList();
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
            return DropdownButtonFormField<String>(
              initialValue: _tareaId,
              isExpanded: true,
              decoration: InputDecoration(
                filled: true,
                fillColor: _Palette.surface,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  borderSide:
                      const BorderSide(color: _Palette.accent, width: 1.5),
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
                    style:
                        const TextStyle(fontSize: 14, color: _Palette.textDark),
                  ),
                );
              }).toList(),
              onChanged: (id) {
                if (id == null) return;
                final doc = docs.firstWhere((d) => d.id == id);
                setState(() {
                  _tareaId = id;
                  _tareaTexto = (doc.data()['text'] as String?) ?? '';
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
                  borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildBotonGenerar() {
    final habilitado = _tareaTexto != null && !_cargando;
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: habilitado ? _generarPlan : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: _Palette.accent,
          disabledBackgroundColor: _cargando
              ? _Palette.accent.withValues(alpha: 0.35)
              : _Palette.accent.withValues(alpha: 0.35),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        icon: _cargando
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withValues(alpha: 0.9)),
                ),
              )
            : const Icon(Icons.auto_fix_high_rounded, size: 20),
        label: Text(
          _cargando ? 'Generando...' : 'Generar Plan',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

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
          SizedBox(
            height: 64,
            width: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: const Duration(seconds: 2),
                  builder: (context, value, _) => Transform.rotate(
                    angle: value * 2 * 3.14159,
                    child: CustomPaint(
                      painter: _DashedRingPainter(
                        color: _Palette.accent.withValues(alpha: 0.2),
                        strokeWidth: 2,
                      ),
                      size: const Size(64, 64),
                    ),
                  ),
                ),
                Container(
                  height: 48,
                  width: 48,
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
          Text(
            'Consultando al experto...',
            style: TextStyle(
              color: _Palette.textMuted,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Dividiendo tu tarea en pasos simples',
            style: TextStyle(
              color: _Palette.textMuted,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _Palette.errorBg,
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

  Widget _buildResultado() {
    final pasos = _pasos!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
        ...pasos.asMap().entries.map((e) => _buildPasoItem(e.key + 1, e.value)),
        const SizedBox(height: 20),
        if (_guardadoExito) _buildConfirmacionExito() else _buildBotonGuardar(),
        const SizedBox(height: 8),
      ],
    );
  }

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
                      const Icon(Icons.schedule_rounded,
                          size: 12, color: _Palette.textMuted),
                      const SizedBox(width: 4),
                      Text(
                        paso['tiempo_estimado']!,
                        style: const TextStyle(
                            fontSize: 12, color: _Palette.textMuted),
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
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        icon: _guardando
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.save_alt_rounded, size: 20),
        label: Text(
          _guardando ? 'Guardando...' : 'Guardar subtareas en Tareas',
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildConfirmacionExito() {
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

class _DashedRingPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;

  _DashedRingPainter({required this.color, this.strokeWidth = 2});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    const dashAngle = 0.12;
    const gapAngle = 0.08;
    const step = dashAngle + gapAngle;

    for (var angle = 0.0; angle < 2 * 3.14159; angle += step) {
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        angle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedRingPainter oldDelegate) => false;
}
