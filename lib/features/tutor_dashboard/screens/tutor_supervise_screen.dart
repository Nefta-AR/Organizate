import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:simple/core/services/activity_log_service.dart';
import 'package:simple/core/services/auth_service.dart';
import 'package:simple/core/services/pictogram_service.dart';
import 'package:simple/features/tea_board/screens/pictogram_manager_screen.dart';
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
      _selectedPatient?['name'] as String? ?? 'Paciente';
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
                'Cambiar paciente',
                style: Theme.of(ctx)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            const Divider(),
            ..._patients.map((p) {
              final isSelected = p['id'] == _selectedPatient?['id'];
              final name = p['name'] as String? ?? 'Paciente';
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
          _TutorHistorialTab(
            key: ValueKey('history_$pk'),
            patientId: pk,
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
            icon: Icon(Icons.history),
            label: 'Historial',
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
                'Sin pacientes vinculados',
                style:
                    TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Ve a Configuración y genera un código de invitación para vincular un paciente.',
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
    String selectedCat = 'General';

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
      await _tasksRef.add({
        'text': textCtrl.text.trim(),
        'category': selectedCat,
        'done': false,
        'createdAt': FieldValue.serverTimestamp(),
        'addedByTutor': true,
      });
    }
    textCtrl.dispose();
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

          final pending =
              docs.where((d) => d.data()['done'] != true).toList();
          final done =
              docs.where((d) => d.data()['done'] == true).toList();

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

  static const _builtins = [
    _BuiltinPicto('assets/images/pictogramas/ayuda.svg', 'AYUDA',
        'Necesito ayuda', 'Emergencia'),
    _BuiltinPicto('assets/images/pictogramas/alto.svg', 'ALTO',
        'Por favor, para', 'Emergencia'),
    _BuiltinPicto('assets/images/pictogramas/cepillar-dientes.svg',
        'DIENTES', 'Cepillarme los dientes', 'Mañana'),
    _BuiltinPicto('assets/images/pictogramas/colegio.svg', 'COLEGIO',
        'Ir al colegio', 'Mañana'),
    _BuiltinPicto(
        'assets/images/pictogramas/baño.svg', 'BAÑO', 'Ir al baño', 'General'),
    _BuiltinPicto('assets/images/pictogramas/almuerzo.svg', 'ALMUERZO',
        'Quiero almorzar', 'Tarde'),
    _BuiltinPicto('assets/images/pictogramas/calle.svg', 'CALLE',
        'Salir a la calle', 'Tarde'),
    _BuiltinPicto('assets/images/pictogramas/beber.svg', 'AGUA',
        'Tengo sed, quiero agua', 'General'),
    _BuiltinPicto('assets/images/pictogramas/casa.svg', 'CASA',
        'Quiero ir a casa', 'Noche'),
    _BuiltinPicto('assets/images/pictogramas/cansado.svg', 'CANSADO',
        'Estoy cansado', 'Noche'),
    _BuiltinPicto('assets/images/pictogramas/desayuno.svg', 'DESAYUNO',
        'Quiero desayunar', 'Mañana'),
    _BuiltinPicto('assets/images/pictogramas/ducha.svg', 'DUCHA',
        'Ducharme', 'Mañana'),
    _BuiltinPicto('assets/images/pictogramas/computador.svg', 'PC',
        'Usar el computador', 'Tarde'),
    _BuiltinPicto('assets/images/pictogramas/feliz.svg', 'FELIZ',
        'Estoy feliz', 'Emociones'),
    _BuiltinPicto('assets/images/pictogramas/estudiar.svg', 'ESTUDIAR',
        'Debo estudiar', 'Tarde'),
  ];

  Future<void> _showAddSheet(BuildContext context) async {
    _BuiltinPicto? selected;
    final labelCtrl = TextEditingController();
    final ttsCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            top: 20,
            left: 16,
            right: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Agregar pictograma',
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Selecciona una imagen y personaliza la etiqueta',
                  style: TextStyle(
                      color: Colors.grey.shade600, fontSize: 13)),
              const SizedBox(height: 12),
              SizedBox(
                height: 110,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _builtins.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final p = _builtins[i];
                    final isSel = selected == p;
                    return GestureDetector(
                      onTap: () => setS(() {
                        selected = p;
                        labelCtrl.text = p.label;
                        ttsCtrl.text = p.tts;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: 85,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSel
                                ? Colors.blue
                                : Colors.grey.shade300,
                            width: isSel ? 2.5 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: isSel
                              ? Colors.blue.shade50
                              : Colors.grey.shade50,
                        ),
                        padding: const EdgeInsets.all(6),
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Image.asset(p.asset,
                                  fit: BoxFit.contain,
                                  errorBuilder: (_, __, ___) =>
                                      const Icon(Icons.image)),
                            ),
                            const SizedBox(height: 4),
                            Text(p.label,
                                style: const TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold),
                                textAlign: TextAlign.center),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: labelCtrl,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: 'Etiqueta (texto visible)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: ttsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Texto de voz',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: selected == null ||
                          labelCtrl.text.trim().isEmpty
                      ? null
                      : () async {
                          final label = labelCtrl.text.trim();
                          final tts = ttsCtrl.text.trim();
                          final s = selected!;
                          Navigator.pop(ctx);
                          await PictogramService.createPictogramFor(
                            userId: patientId,
                            etiqueta: label,
                            textoTts: tts.isEmpty ? label : tts,
                            imageUrl: s.asset,
                            categoria: s.categoria,
                          );
                        },
                  icon: const Icon(Icons.add),
                  label: const Text('Agregar pictograma'),
                  style: ElevatedButton.styleFrom(
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    labelCtrl.dispose();
    ttsCtrl.dispose();
  }

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
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'organizar_$patientId',
            onPressed: () => _openManager(context),
            tooltip: 'Organizar pictogramas',
            backgroundColor: Colors.orange.shade400,
            child: const Icon(Icons.tune_rounded),
          ),
          const SizedBox(height: 12),
          FloatingActionButton.extended(
            heroTag: 'agregar_$patientId',
            onPressed: () => _showAddSheet(context),
            icon: const Icon(Icons.add),
            label: const Text('Agregar'),
          ),
        ],
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
        _ => Icons.info_outline,
      };

  Color _color(String type) => switch (type) {
        ActivityType.taskCompleted => Colors.green,
        ActivityType.taskCreated => Colors.blue,
        ActivityType.taskDeleted => Colors.red,
        ActivityType.pictogramCreated => Colors.purple,
        ActivityType.pictogramDeleted => Colors.orange,
        _ => Colors.grey,
      };

  String _label(String type) => switch (type) {
        ActivityType.taskCompleted => 'Tarea completada',
        ActivityType.taskCreated => 'Tarea creada',
        ActivityType.taskDeleted => 'Tarea eliminada',
        ActivityType.pictogramCreated => 'Pictograma creado',
        ActivityType.pictogramDeleted => 'Pictograma eliminado',
        _ => 'Actividad',
      };

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ActivityLogService.getStream(patientId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final logs = snap.data ?? [];
        if (logs.isEmpty) {
          return const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.history, size: 64, color: Colors.grey),
                SizedBox(height: 12),
                Text('Sin actividad registrada aún.',
                    style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
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
                border: Border.all(
                    color: color.withValues(alpha: 0.2)),
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
        );
      },
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
                      ? Image.asset(picto.imageUrl,
                          fit: BoxFit.contain,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.image, size: 40))
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

class _BuiltinPicto {
  final String asset;
  final String label;
  final String tts;
  final String categoria;
  const _BuiltinPicto(this.asset, this.label, this.tts, this.categoria);
}
