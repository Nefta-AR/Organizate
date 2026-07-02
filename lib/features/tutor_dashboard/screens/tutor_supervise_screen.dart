// lib/features/tutor_dashboard/screens/tutor_supervise_screen.dart
//
// Panel de supervisión del tutor. Muestra datos en tiempo real del usuario
// seleccionado, organizado en seis tabs:
//
//   1. **Tareas** [_TutorTasksTab]: lista de tareas con tres secciones
//      (Pendientes / Completadas / Eliminadas por el usuario). Las tareas
//      eliminadas usan soft-delete (`deletedByUser: true`) para que el tutor
//      conserve el registro aunque el usuario ya no las vea en su pantalla.
//
//   2. **Pictogramas** [_TutorPictogramsTab]: grid de pictogramas personalizados
//      del usuario. El tutor puede agregar del banco SVG predefinido o abrir
//      el gestor completo [PictogramManagerScreen].
//
//   3. **Progreso** [ProgresoScreen]: dashboard con tres gráficos en tiempo real
//      (tareas por categoría, uso de pictogramas, sesiones Pomodoro semanales).
//
//   4. **Historial** [_TutorHistorialTab]: tarjeta de estadísticas en tiempo
//      real ([_StatsCard]) + log de actividad de las últimas 100 entradas
//      (tareas completadas, pictogramas usados, sesiones Pomodoro).
//
//   5. **Ajustes** [_TutorConfigTab]: toggles para habilitar/deshabilitar las
//      pestañas de Inicio, Tareas, Pictogramas y Foco en la app del usuario.
//      También configura el contacto de emergencia.
//      Los flags se persisten en `pictogramSettings/_features` (subcolección
//      con permisos de tutor ya establecidos en las reglas, sin deploy extra).
//
// ## Manejo de múltiples usuarios
//
// El selector de usuario usa un [Stream] de [AuthService.getLinkedPatientsStream].
// Al cambiar de usuario activo, [IndexedStack] usa [ValueKey(patientId)] en
// cada tab para forzar su reconstrucción completa y limpiar el estado previo.

import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:simple/core/services/activity_log_service.dart';
import 'package:simple/core/services/auth_service.dart';
import 'package:simple/core/services/pictogram_service.dart';
import 'package:simple/features/tea_board/screens/pictogram_manager_screen.dart';
import 'package:simple/features/tda_focus/screens/progreso_screen.dart';
import 'package:simple/features/tutor_dashboard/screens/settings_screen.dart';

// ─── Pantalla principal del tutor ─────────────────────────────────────────────

class TutorSupervisarScreen extends StatefulWidget {
  const TutorSupervisarScreen({super.key});

  @override
  State<TutorSupervisarScreen> createState() => _TutorSupervisarScreenState();
}

class _TutorSupervisarScreenState extends State<TutorSupervisarScreen> {
  int _currentIndex = 0;
  List<Map<String, dynamic>> _patients = [];
  Map<String, dynamic>? _selectedPatient;
  bool _loading = true;
  late final StreamSubscription<List<Map<String, dynamic>>> _patientsSub;

  @override
  void initState() {
    super.initState();
    _patientsSub = AuthService.getLinkedPatientsStream().listen((patients) {
      if (!mounted) return;
      setState(() {
        _patients = patients;
        _loading = false;
        if (_selectedPatient == null && patients.isNotEmpty) {
          _selectedPatient = patients.first;
        } else if (_selectedPatient != null) {
          final stillExists =
              patients.any((p) => p['id'] == _selectedPatient!['id']);
          if (!stillExists) {
            _selectedPatient = patients.isNotEmpty ? patients.first : null;
          }
        }
      });
    });
  }

  @override
  void dispose() {
    _patientsSub.cancel();
    super.dispose();
  }

  String get _patientId => _selectedPatient?['id'] as String? ?? '';
  String get _patientName =>
      _selectedPatient?['name'] as String? ?? 'Usuario';
  String? get _patientAvatar => _selectedPatient?['avatar'] as String?;

  void _switchPatient(Map<String, dynamic> patient) {
    setState(() {
      _selectedPatient = patient;
      _currentIndex = 0;
    });
  }

  void _showPatientPicker() {
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
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(
                'Cambiar usuario',
                style: Theme.of(ctx)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            ..._patients.map((p) {
              final isSelected = p['id'] == _selectedPatient?['id'];
              final name = p['name'] as String? ?? 'Usuario';
              final email = p['email'] as String? ?? '';
              final avatar = p['avatar'] as String?;
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey.shade200,
                  backgroundImage: avatar != null
                      ? AssetImage('assets/avatars/$avatar.png')
                      : null,
                  child: avatar == null
                      ? const Icon(Icons.person)
                      : null,
                ),
                title: Text(name,
                    style: const TextStyle(fontWeight: FontWeight.w500)),
                subtitle: Text(email,
                    style: const TextStyle(fontSize: 12)),
                trailing: isSelected
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : const Icon(Icons.radio_button_unchecked,
                        color: Colors.grey),
                onTap: () {
                  Navigator.pop(ctx);
                  _switchPatient(p);
                },
              );
            }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_patients.isEmpty) {
      return _buildNoPatients();
    }

    final pk = _patientId;

    return Scaffold(
      appBar: _buildAppBar(),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          _TutorTasksTab(
            key: ValueKey('tasks_$pk'),
            patientId: pk,
            patientName: _patientName,
          ),
          _TutorPictogramsTab(
            key: ValueKey('pictos_$pk'),
            patientId: pk,
            patientName: _patientName,
          ),
          ProgresoScreen(
            key: ValueKey('progreso_$pk'),
            userId: pk,
          ),
          _TutorHistorialTab(
            key: ValueKey('history_$pk'),
            patientId: pk,
          ),
          _TutorConfigTab(
            key: ValueKey('config_$pk'),
            patientId: pk,
            patientName: _patientName,
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.task_alt_outlined),
            selectedIcon: Icon(Icons.task_alt),
            label: 'Tareas',
          ),
          NavigationDestination(
            icon: Icon(Icons.image_outlined),
            selectedIcon: Icon(Icons.image_rounded),
            label: 'Pictogramas',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Progreso',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: 'Historial',
          ),
          NavigationDestination(
            icon: Icon(Icons.tune_outlined),
            selectedIcon: Icon(Icons.tune_rounded),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      leadingWidth: 56,
      leading: Padding(
        padding: const EdgeInsets.only(left: 12),
        child: CircleAvatar(
          radius: 18,
          backgroundColor: Colors.grey.shade200,
          backgroundImage: _patientAvatar != null
              ? AssetImage('assets/avatars/$_patientAvatar.png')
              : null,
          child: _patientAvatar == null
              ? const Icon(Icons.person, size: 18)
              : null,
        ),
      ),
      title: _patients.length > 1
          ? GestureDetector(
              onTap: _showPatientPicker,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _patientName,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            )
          : Text(
              _patientName,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
      actions: [
        IconButton(
          icon: const Icon(Icons.settings_outlined),
          tooltip: 'Configuración',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const SettingsScreen(showNavBar: false)),
          ),
        ),
      ],
    );
  }

  Widget _buildNoPatients() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Supervisión'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen(showNavBar: false)),
            ),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.people_outline,
                  size: 80, color: Colors.grey.shade300),
              const SizedBox(height: 20),
              const Text(
                'Sin usuarios vinculados',
                style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Ve a Configuración y genera un código de invitación para vincular un usuario.',
                style: TextStyle(color: Colors.grey.shade600),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SettingsScreen()),
                ),
                icon: const Icon(Icons.settings),
                label: const Text('Ir a Configuración'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── TAB TAREAS ───────────────────────────────────────────────────────────────

class _TutorTasksTab extends StatefulWidget {
  final String patientId;
  final String patientName;

  const _TutorTasksTab({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<_TutorTasksTab> createState() => _TutorTasksTabState();
}

class _TutorTasksTabState extends State<_TutorTasksTab> {
  late final CollectionReference<Map<String, dynamic>> _tasksRef;

  static const _categories = [
    _Cat('General', Icons.task_alt, Colors.blueGrey),
    _Cat('Estudios', Icons.menu_book, Colors.orange),
    _Cat('Hogar', Icons.cottage, Colors.green),
    _Cat('Meds', Icons.medication, Colors.red),
    _Cat('Foco', Icons.self_improvement, Colors.purple),
  ];

  @override
  void initState() {
    super.initState();
    _tasksRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.patientId)
        .collection('tasks');
  }

  Future<void> _toggleDone(String taskId, bool current) =>
      _tasksRef.doc(taskId).update({'done': !current});

  Future<void> _deleteTask(String taskId) =>
      _tasksRef.doc(taskId).delete();

  Future<void> _addTask() async {
    final textCtrl = TextEditingController();
    final noteCtrl = TextEditingController();
    String selectedCat = 'General';
    bool repeatEnabled = false;
    String recurrence = 'daily';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Nueva tarea para ${widget.patientName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: textCtrl,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Descripción de la tarea',
                  border: OutlineInputBorder(),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Categoría',
                    style: TextStyle(
                        color: Colors.grey.shade600, fontSize: 13)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((c) {
                  final sel = selectedCat == c.label;
                  return ChoiceChip(
                    label: Text(c.label),
                    avatar: Icon(c.icon,
                        size: 16,
                        color: sel ? Colors.white : c.color),
                    selected: sel,
                    selectedColor: c.color,
                    labelStyle: TextStyle(
                        color: sel ? Colors.white : Colors.black87),
                    onSelected: (_) =>
                        setS(() => selectedCat = c.label),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: noteCtrl,
                decoration: InputDecoration(
                  hintText: 'Nota para el usuario (opcional)',
                  hintStyle: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.sticky_note_2_outlined, size: 18),
                  isDense: true,
                  contentPadding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                ),
                maxLines: 2,
                maxLength: 120,
              ),
              SwitchListTile.adaptive(
                title: const Text('Repetir tarea', style: TextStyle(fontSize: 14)),
                value: repeatEnabled,
                onChanged: (v) => setS(() => repeatEnabled = v),
                contentPadding: EdgeInsets.zero,
                dense: true,
              ),
              if (repeatEnabled)
                DropdownButtonFormField<String>(
                  initialValue: recurrence,
                  decoration: const InputDecoration(
                      labelText: 'Frecuencia', border: OutlineInputBorder()),
                  items: const [
                    DropdownMenuItem(value: 'daily', child: Text('Diaria')),
                    DropdownMenuItem(value: 'weekly', child: Text('Semanal')),
                    DropdownMenuItem(value: 'monthly', child: Text('Mensual')),
                  ],
                  onChanged: (v) => setS(() => recurrence = v ?? 'daily'),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Agregar'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true && textCtrl.text.trim().isNotEmpty) {
      final note = noteCtrl.text.trim();
      await _tasksRef.add({
        'text': textCtrl.text.trim(),
        'category': selectedCat,
        'done': false,
        'createdAt': FieldValue.serverTimestamp(),
        'addedByTutor': true,
        if (note.isNotEmpty) 'note': note,
        if (repeatEnabled) 'recurrence': recurrence,
      });
    }
    textCtrl.dispose();
    noteCtrl.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addTask,
        icon: const Icon(Icons.add),
        label: const Text('Agregar tarea'),
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream:
            _tasksRef.orderBy('createdAt', descending: true).snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.task_alt, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Sin tareas. Agrega una con el botón +.',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final pending = docs
              .where((d) =>
                  d.data()['done'] != true &&
                  d.data()['deletedByUser'] != true)
              .toList();
          final done = docs
              .where((d) =>
                  d.data()['done'] == true &&
                  d.data()['deletedByUser'] != true)
              .toList();
          final deleted = docs
              .where((d) => d.data()['deletedByUser'] == true)
              .toList();

          return ListView(
            padding:
                const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              if (pending.isNotEmpty) ...[
                _sectionHeader(
                    'Pendientes (${pending.length})', Colors.blueAccent),
                ...pending.map((d) => _SupervisionTaskTile(
                      doc: d,
                      onToggle: () =>
                          _toggleDone(d.id, d.data()['done'] == true),
                      onDelete: () => _deleteTask(d.id),
                    )),
                const SizedBox(height: 16),
              ],
              if (done.isNotEmpty) ...[
                _sectionHeader(
                    'Completadas (${done.length})', Colors.green),
                ...done.map((d) => _SupervisionTaskTile(
                      doc: d,
                      onToggle: () =>
                          _toggleDone(d.id, d.data()['done'] == true),
                      onDelete: () => _deleteTask(d.id),
                    )),
                const SizedBox(height: 16),
              ],
              if (deleted.isNotEmpty) ...[
                _sectionHeader(
                    'Eliminadas por el usuario (${deleted.length})',
                    Colors.grey),
                ...deleted.map((d) => _DeletedTaskTile(
                      doc: d,
                      onDelete: () => _deleteTask(d.id),
                    )),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String label, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(label,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 13)),
    );
  }
}

// ─── TAB PICTOGRAMAS ──────────────────────────────────────────────────────────

class _TutorPictogramsTab extends StatelessWidget {
  final String patientId;
  final String patientName;

  const _TutorPictogramsTab({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  void _openManager(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PictogramManagerScreen(
          userId: patientId,
          userName: patientName,
          builtins: kBancoBuiltins,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        heroTag: 'organizar_$patientId',
        onPressed: () => _openManager(context),
        tooltip: 'Organizar pictogramas',
        backgroundColor: Colors.orange.shade400,
        child: const Icon(Icons.tune_rounded),
      ),
      body: StreamBuilder<List<PictogramaPersonalizado>>(
        stream: PictogramService.getCustomPictogramsStreamFor(patientId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final pictos = snap.data ?? [];
          if (pictos.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.image_not_supported,
                      size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Sin pictogramas. Agrega uno con el botón +.',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return GridView.builder(
            padding:
                const EdgeInsets.fromLTRB(16, 16, 16, 100),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemCount: pictos.length,
            itemBuilder: (context, i) {
              final p = pictos[i];
              return _SupervisionPictoCard(
                picto: p,
                onDelete: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Eliminar pictograma'),
                      content: Text('¿Eliminar "${p.etiqueta}"?'),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(ctx, false),
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          onPressed: () =>
                              Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          child: const Text('Eliminar'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await PictogramService.deletePictogramFor(
                        patientId, p.id);
                  }
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ─── TAB HISTORIAL ────────────────────────────────────────────────────────────

class _TutorHistorialTab extends StatelessWidget {
  final String patientId;

  const _TutorHistorialTab({super.key, required this.patientId});

  IconData _icon(String type) => switch (type) {
        ActivityType.taskCompleted => Icons.check_circle_rounded,
        ActivityType.taskCreated => Icons.add_task,
        ActivityType.taskDeleted => Icons.delete_outline,
        ActivityType.pictogramCreated => Icons.image,
        ActivityType.pictogramDeleted => Icons.image_not_supported,
        ActivityType.pictogramUsed => Icons.record_voice_over_rounded,
        ActivityType.pomodoroCompleted => Icons.timer_rounded,
        _ => Icons.info_outline,
      };

  Color _color(String type) => switch (type) {
        ActivityType.taskCompleted => Colors.green,
        ActivityType.taskCreated => Colors.blue,
        ActivityType.taskDeleted => Colors.red,
        ActivityType.pictogramCreated => Colors.purple,
        ActivityType.pictogramDeleted => Colors.orange,
        ActivityType.pictogramUsed => Colors.teal,
        ActivityType.pomodoroCompleted => Colors.deepOrange,
        _ => Colors.grey,
      };

  String _label(String type) => switch (type) {
        ActivityType.taskCompleted => 'Tarea completada',
        ActivityType.taskCreated => 'Tarea creada',
        ActivityType.taskDeleted => 'Tarea eliminada',
        ActivityType.pictogramCreated => 'Pictograma creado',
        ActivityType.pictogramDeleted => 'Pictograma eliminado',
        ActivityType.pictogramUsed => 'Pictograma usado',
        ActivityType.pomodoroCompleted => 'Sesión de foco',
        _ => 'Actividad',
      };

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _StatsCard(patientId: patientId),
        ),
        SliverToBoxAdapter(
          child: _DailySummaryCard(patientId: patientId),
        ),
        StreamBuilder<List<Map<String, dynamic>>>(
          stream: ActivityLogService.getStream(patientId),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const SliverFillRemaining(
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final logs = snap.data ?? [];
            if (logs.isEmpty) {
              return const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('Sin actividad registrada aún.',
                          style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                ),
              );
            }
            return SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
              sliver: SliverList.separated(
                itemCount: logs.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final log = logs[i];
                  final type = log['type'] as String? ?? '';
                  final description = log['description'] as String? ?? '';
                  final ts = log['timestamp'] as Timestamp?;
                  final date = ts?.toDate();
                  final color = _color(type);

                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: color.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_icon(type), color: color, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _label(type),
                                style: TextStyle(
                                    fontSize: 11,
                                    color: color,
                                    fontWeight: FontWeight.w600),
                              ),
                              Text(description,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14)),
                              if (date != null)
                                Text(
                                  DateFormat('dd/MM/yyyy HH:mm', 'es_ES')
                                      .format(date),
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade600),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}

// ─── TARJETA RESUMEN DEL DÍA ─────────────────────────────────────────────────

class _DailySummaryCard extends StatelessWidget {
  final String patientId;
  const _DailySummaryCard({required this.patientId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ActivityLogService.getStream(patientId),
      builder: (context, snap) {
        // Mientras carga, ocupa espacio mínimo para no saltar el layout
        if (!snap.hasData) return const SizedBox(height: 8);

        final today = DateTime.now();
        final todayLogs = snap.data!.where((log) {
          final ts = log['timestamp'] as Timestamp?;
          if (ts == null) return false;
          final d = ts.toDate();
          return d.year == today.year &&
              d.month == today.month &&
              d.day == today.day;
        }).toList();

        final tasks = todayLogs
            .where((l) => l['type'] == ActivityType.taskCompleted)
            .length;
        final pictos = todayLogs
            .where((l) => l['type'] == ActivityType.pictogramUsed)
            .length;
        final minutes = todayLogs
            .where((l) => l['type'] == ActivityType.pomodoroCompleted)
            .fold<int>(0, (total, l) {
          final meta = l['metadata'] as Map<String, dynamic>?;
          return total + ((meta?['minutes'] as num?)?.toInt() ?? 0);
        });

        return Container(
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
          decoration: BoxDecoration(
            color: const Color(0xFFEBF2FF),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFB8D0F5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.today_rounded,
                      size: 15, color: Color(0xFF3D6BAD)),
                  const SizedBox(width: 6),
                  Text(
                    'Hoy · ${DateFormat('d \'de\' MMMM', 'es_ES').format(today)}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF3D6BAD),
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MetricItem(
                    value: tasks,
                    label: 'tareas',
                    icon: Icons.check_circle_rounded,
                    color: Colors.green.shade600,
                  ),
                  Container(width: 1, height: 36, color: const Color(0xFFB8D0F5)),
                  _MetricItem(
                    value: pictos,
                    label: 'pictogramas',
                    icon: Icons.record_voice_over_rounded,
                    color: Colors.teal.shade600,
                  ),
                  Container(width: 1, height: 36, color: const Color(0xFFB8D0F5)),
                  _MetricItem(
                    value: minutes,
                    label: 'min foco',
                    icon: Icons.timer_rounded,
                    color: Colors.deepOrange.shade500,
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MetricItem extends StatelessWidget {
  final int value;
  final String label;
  final IconData icon;
  final Color color;

  const _MetricItem({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 5),
            Text(
              '$value',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
                height: 1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}

// ─── TAB CONFIGURACIÓN ───────────────────────────────────────────────────────

class _TutorConfigTab extends StatefulWidget {
  final String patientId;
  final String patientName;

  const _TutorConfigTab({
    super.key,
    required this.patientId,
    required this.patientName,
  });

  @override
  State<_TutorConfigTab> createState() => _TutorConfigTabState();
}

class _TutorConfigTabState extends State<_TutorConfigTab> {
  bool? _featureInicio;
  bool? _featureTareas;
  bool? _featurePictogramas;
  bool? _featureFoco;
  bool? _featurePerfil;
  late final StreamSubscription<DocumentSnapshot<Map<String, dynamic>>> _sub;

  final _emergencyNameCtrl  = TextEditingController();
  final _emergencyPhoneCtrl = TextEditingController();
  bool _emergencyDirty   = false;
  bool _emergencySaving  = false;

  static const _featuresDocId = '_features';

  CollectionReference<Map<String, dynamic>> get _settingsRef =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(widget.patientId)
          .collection('pictogramSettings');

  DocumentReference<Map<String, dynamic>> get _patientDoc =>
      FirebaseFirestore.instance.collection('users').doc(widget.patientId);

  @override
  void initState() {
    super.initState();
    _sub = _settingsRef.doc(_featuresDocId).snapshots().listen((snap) {
      if (!mounted) return;
      final data = snap.data() ?? {};
      setState(() {
        _featureInicio      = data['featureInicio']      as bool? ?? true;
        _featureTareas      = data['featureTareas']      as bool? ?? true;
        _featurePictogramas = data['featurePictogramas'] as bool? ?? false;
        _featureFoco        = data['featureFoco']        as bool? ?? true;
        _featurePerfil      = data['featurePerfil']      as bool? ?? true;
      });
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    _emergencyNameCtrl.dispose();
    _emergencyPhoneCtrl.dispose();
    super.dispose();
  }

  int get _activeCount => [
        _featureInicio,
        _featureTareas,
        _featurePictogramas,
        _featureFoco,
        _featurePerfil,
      ].where((v) => v == true).length;

  Future<void> _toggle(String field, bool current) async {
    if (current && _activeCount <= 1) return;
    await _settingsRef.doc(_featuresDocId).set(
      {field: !current},
      SetOptions(merge: true),
    );
  }

  Future<void> _saveEmergency() async {
    setState(() => _emergencySaving = true);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await _patientDoc.set({
        'emergencyName':
            _emergencyNameCtrl.text.trim().isEmpty
                ? FieldValue.delete()
                : _emergencyNameCtrl.text.trim(),
        'emergencyPhone':
            _emergencyPhoneCtrl.text.trim().isEmpty
                ? FieldValue.delete()
                : _emergencyPhoneCtrl.text.trim(),
      }, SetOptions(merge: true));
      setState(() => _emergencyDirty = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Contacto de emergencia guardado')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo guardar')),
      );
    } finally {
      if (mounted) setState(() => _emergencySaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_featureInicio == null || _featurePerfil == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final ac = _activeCount;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _patientDoc.snapshots(),
      builder: (context, patSnap) {
        final patData = patSnap.data?.data() ?? {};
        if (!_emergencyDirty) {
          _emergencyNameCtrl.text =
              (patData['emergencyName'] as String?) ?? '';
          _emergencyPhoneCtrl.text =
              (patData['emergencyPhone'] as String?) ??
              (patData['phone'] as String?) ?? '';
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          children: [
            // ── Pestañas ────────────────────────────────────────────
            Text(
              'Pestañas de ${widget.patientName}',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Activa o desactiva las secciones visibles en la app del usuario.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 20),
            _FeatureToggleTile(
              icon: Icons.home_rounded,
              color: Colors.blue,
              title: 'Pestaña de Inicio',
              subtitle: 'Pantalla principal con frases y resumen',
              value: _featureInicio!,
              onChanged: (_featureInicio! && ac <= 1)
                  ? null
                  : (_) => _toggle('featureInicio', _featureInicio!),
            ),
            const SizedBox(height: 12),
            _FeatureToggleTile(
              icon: Icons.task_alt,
              color: Colors.green,
              title: 'Pestaña de Tareas',
              subtitle: 'El usuario puede ver y gestionar sus tareas',
              value: _featureTareas!,
              onChanged: (_featureTareas! && ac <= 1)
                  ? null
                  : (_) => _toggle('featureTareas', _featureTareas!),
            ),
            const SizedBox(height: 12),
            _FeatureToggleTile(
              icon: Icons.image_rounded,
              color: Colors.purple,
              title: 'Pestaña de Pictogramas',
              subtitle: 'Tablero de comunicación aumentativa',
              value: _featurePictogramas!,
              onChanged: (_featurePictogramas! && ac <= 1)
                  ? null
                  : (_) => _toggle('featurePictogramas', _featurePictogramas!),
            ),
            const SizedBox(height: 12),
            _FeatureToggleTile(
              icon: Icons.self_improvement,
              color: Colors.deepOrange,
              title: 'Pestaña de Foco',
              subtitle: 'Temporizador Pomodoro y respiración guiada',
              value: _featureFoco!,
              onChanged: (_featureFoco! && ac <= 1)
                  ? null
                  : (_) => _toggle('featureFoco', _featureFoco!),
            ),
            const SizedBox(height: 12),
            _FeatureToggleTile(
              icon: Icons.person_rounded,
              color: const Color(0xFF607D8B),
              title: 'Pestaña de Perfil',
              subtitle: 'Configuración y estadísticas personales',
              value: _featurePerfil!,
              onChanged: (_featurePerfil! && ac <= 1)
                  ? null
                  : (_) => _toggle('featurePerfil', _featurePerfil!),
            ),
            const SizedBox(height: 32),
            // ── Contacto de emergencia ───────────────────────────────
            Text(
              'Contacto de emergencia',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              'Número al que llamar si ${widget.patientName} necesita ayuda.',
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _emergencyNameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre del contacto',
                hintText: 'Ej: Mamá, Tutor, Médico',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) {
                if (!_emergencyDirty) setState(() => _emergencyDirty = true);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emergencyPhoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                hintText: 'Ej: +56 9 1234 5678',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) {
                if (!_emergencyDirty) setState(() => _emergencyDirty = true);
              },
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _emergencyDirty && !_emergencySaving
                    ? _saveEmergency
                    : null,
                icon: _emergencySaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text('Guardar'),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FeatureToggleTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  const _FeatureToggleTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value ? color.withValues(alpha: 0.3) : Colors.grey.shade200,
          width: value ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.06),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SwitchListTile(
        value: value,
        onChanged: onChanged,
        activeThumbColor: color,
        secondary: Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: color.withValues(alpha: value ? 0.12 : 0.06),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: value ? color : Colors.grey, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: value ? Colors.black87 : Colors.grey.shade600,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade500,
          ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}

// ─── Tarjeta de stats del usuario ────────────────────────────────────────────

class _StatsCard extends StatelessWidget {
  final String patientId;
  const _StatsCard({required this.patientId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(patientId)
          .snapshots(),
      builder: (context, snap) {
        final data = snap.data?.data() ?? {};
        final sessions = data['focusSessionsCompleted'] as int? ?? 0;
        final minutes = data['totalFocusMinutes'] as int? ?? 0;
        final points = data['points'] as int? ?? 0;
        final streak = data['streak'] as int? ?? 0;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              _StatChip(
                icon: Icons.timer_rounded,
                color: Colors.deepOrange,
                label: '$sessions sesiones',
                sub: 'Pomodoro',
              ),
              const SizedBox(width: 10),
              _StatChip(
                icon: Icons.access_time_rounded,
                color: Colors.indigo,
                label: '$minutes min',
                sub: 'Foco total',
              ),
              const SizedBox(width: 10),
              _StatChip(
                icon: Icons.local_fire_department_rounded,
                color: Colors.orange,
                label: '$streak días',
                sub: 'Racha',
              ),
              const SizedBox(width: 10),
              _StatChip(
                icon: Icons.star_rounded,
                color: Colors.amber,
                label: '$points pts',
                sub: 'Puntos',
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String sub;

  const _StatChip({
    required this.icon,
    required this.color,
    required this.label,
    required this.sub,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: color)),
            Text(sub,
                style: TextStyle(
                    fontSize: 9, color: Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }
}

// ─── Widgets compartidos ──────────────────────────────────────────────────────

class _SupervisionTaskTile extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _SupervisionTaskTile({
    required this.doc,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final done = data['done'] == true;
    final text = data['text'] as String? ?? '';
    final category = data['category'] as String? ?? 'General';
    final byTutor = data['addedByTutor'] == true;

    return Dismissible(
      key: Key(doc.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: done ? Colors.grey.shade100 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: ListTile(
          leading: Checkbox(
            value: done,
            onChanged: (_) => onToggle(),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4)),
          ),
          title: Text(
            text,
            style: TextStyle(
              decoration: done ? TextDecoration.lineThrough : null,
              color: done ? Colors.grey : Colors.black87,
            ),
          ),
          subtitle: Row(
            children: [
              Text(category,
                  style: const TextStyle(
                      fontSize: 12, color: Colors.grey)),
              if (byTutor) ...[
                const SizedBox(width: 6),
                const Icon(Icons.person_pin,
                    size: 12, color: Colors.blue),
                const Text(' Tutor',
                    style: TextStyle(
                        fontSize: 11, color: Colors.blue)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _DeletedTaskTile extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final VoidCallback onDelete;

  const _DeletedTaskTile({required this.doc, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final text = data['text'] as String? ?? '';
    final category = data['category'] as String? ?? 'General';
    final byTutor = data['addedByTutor'] == true;

    return Dismissible(
      key: Key('del_${doc.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade400,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_forever, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: ListTile(
          leading: Icon(Icons.delete_outline,
              color: Colors.grey.shade400, size: 22),
          title: Text(
            text,
            style: TextStyle(
              decoration: TextDecoration.lineThrough,
              color: Colors.grey.shade500,
            ),
          ),
          subtitle: Row(
            children: [
              Text(category,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey.shade400)),
              if (byTutor) ...[
                const SizedBox(width: 6),
                Icon(Icons.person_pin,
                    size: 12, color: Colors.grey.shade400),
                Text(' Tutor',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade400)),
              ],
              const SizedBox(width: 6),
              Icon(Icons.person_remove_outlined,
                  size: 11, color: Colors.grey.shade400),
              Text(' Eliminada por usuario',
                  style: TextStyle(
                      fontSize: 10, color: Colors.grey.shade400)),
            ],
          ),
        ),
      ),
    );
  }
}

class _SupervisionPictoCard extends StatelessWidget {
  final PictogramaPersonalizado picto;
  final VoidCallback onDelete;

  const _SupervisionPictoCard(
      {required this.picto, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isAsset = picto.imageUrl.startsWith('assets/');

    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.grey.shade200),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 20, 8, 4),
                  child: isAsset
                      ? (picto.imageUrl.endsWith('.svg')
                          ? SvgPicture.asset(picto.imageUrl,
                              fit: BoxFit.contain)
                          : Image.asset(picto.imageUrl,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.image, size: 40)))
                      : picto.imageUrl.isNotEmpty
                          ? Image.network(picto.imageUrl,
                              fit: BoxFit.contain)
                          : const Icon(Icons.image,
                              size: 40, color: Colors.grey),
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    vertical: 6, horizontal: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(11),
                    bottomRight: Radius.circular(11),
                  ),
                ),
                child: Text(
                  picto.etiqueta,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 11, fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        Positioned(
          top: 2,
          right: 2,
          child: GestureDetector(
            onTap: onDelete,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.red.shade400,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close,
                  size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Modelos de datos locales ─────────────────────────────────────────────────

class _Cat {
  final String label;
  final IconData icon;
  final Color color;
  const _Cat(this.label, this.icon, this.color);
}


