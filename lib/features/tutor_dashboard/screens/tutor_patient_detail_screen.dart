import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:simple/core/services/activity_log_service.dart';
import 'package:simple/core/services/pictogram_service.dart';

class TutorPatientDetailScreen extends StatelessWidget {
  final String patientId;
  final String patientName;
  final String? patientAvatar;
  final String? patientEmail;

  const TutorPatientDetailScreen({
    super.key,
    required this.patientId,
    required this.patientName,
    this.patientAvatar,
    this.patientEmail,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text(patientName),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.task_alt), text: 'Tareas'),
              Tab(icon: Icon(Icons.image), text: 'Pictogramas'),
              Tab(icon: Icon(Icons.history), text: 'Registros'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _TasksTab(patientId: patientId, patientName: patientName),
            _PictogramsTab(patientId: patientId),
            _ActivityLogTab(patientId: patientId),
          ],
        ),
      ),
    );
  }
}

// ─── TAB TAREAS ───────────────────────────────────────────────────────────────

class _TasksTab extends StatefulWidget {
  final String patientId;
  final String patientName;
  const _TasksTab({required this.patientId, required this.patientName});

  @override
  State<_TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<_TasksTab> {
  late final CollectionReference<Map<String, dynamic>> _tasksRef;

  static const _categories = [
    _Cat('Estudios', Icons.menu_book, Colors.orange),
    _Cat('Hogar', Icons.cottage, Colors.green),
    _Cat('Meds', Icons.medication, Colors.red),
    _Cat('Foco', Icons.self_improvement, Colors.purple),
    _Cat('General', Icons.task_alt, Colors.blueGrey),
  ];

  @override
  void initState() {
    super.initState();
    _tasksRef = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.patientId)
        .collection('tasks');
  }

  Future<void> _toggleDone(String taskId, bool current) async {
    await _tasksRef.doc(taskId).update({'done': !current});
  }

  Future<void> _deleteTask(String taskId, String taskText) async {
    await _tasksRef.doc(taskId).delete();
  }

  Future<void> _addTask() async {
    final textCtrl = TextEditingController();
    String selectedCategory = 'General';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((c) {
                  final selected = selectedCategory == c.label;
                  return ChoiceChip(
                    label: Text(c.label),
                    avatar: Icon(c.icon, size: 16,
                        color: selected ? Colors.white : c.color),
                    selected: selected,
                    selectedColor: c.color,
                    labelStyle: TextStyle(
                        color: selected ? Colors.white : Colors.black87),
                    onSelected: (_) => setS(() => selectedCategory = c.label),
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
        'category': selectedCategory,
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
        stream: _tasksRef.orderBy('createdAt', descending: true).snapshots(),
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
                  Text('Sin tareas. Agrega una.', style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final pending = docs.where((d) => d.data()['done'] != true).toList();
          final done = docs.where((d) => d.data()['done'] == true).toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            children: [
              if (pending.isNotEmpty) ...[
                _sectionHeader('Pendientes', Colors.blueAccent),
                ...pending.map((d) => _TaskTile(
                  doc: d,
                  onToggle: () => _toggleDone(d.id, d.data()['done'] == true),
                  onDelete: () => _deleteTask(d.id, d.data()['text'] ?? ''),
                )),
                const SizedBox(height: 16),
              ],
              if (done.isNotEmpty) ...[
                _sectionHeader('Completadas', Colors.green),
                ...done.map((d) => _TaskTile(
                  doc: d,
                  onToggle: () => _toggleDone(d.id, d.data()['done'] == true),
                  onDelete: () => _deleteTask(d.id, d.data()['text'] ?? ''),
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
      child: Text(
        label,
        style: TextStyle(
            fontWeight: FontWeight.bold, color: color, fontSize: 13),
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _TaskTile({
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
                  style: const TextStyle(fontSize: 12, color: Colors.grey)),
              if (byTutor) ...[
                const SizedBox(width: 6),
                const Icon(Icons.person_pin, size: 12, color: Colors.blue),
                const Text(' Tutor',
                    style: TextStyle(fontSize: 11, color: Colors.blue)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ─── TAB PICTOGRAMAS ──────────────────────────────────────────────────────────

class _PictogramsTab extends StatelessWidget {
  final String patientId;
  const _PictogramsTab({required this.patientId});

  static const _builtinPictos = [
    _BuiltinPicto('assets/images/pictogramas/ayuda.svg', 'AYUDA', 'Necesito ayuda', 'Emergencia'),
    _BuiltinPicto('assets/images/pictogramas/alto.svg', 'ALTO', 'Por favor, para', 'Emergencia'),
    _BuiltinPicto('assets/images/pictogramas/cepillar-dientes.svg', 'DIENTES', 'Debo cepillarme los dientes', 'Mañana'),
    _BuiltinPicto('assets/images/pictogramas/colegio.svg', 'COLEGIO', 'Es hora de ir al colegio', 'Mañana'),
    _BuiltinPicto('assets/images/pictogramas/baño.svg', 'BAÑO', 'Quiero ir al baño', 'General'),
    _BuiltinPicto('assets/images/pictogramas/almuerzo.svg', 'ALMUERZO', 'Tengo hambre, quiero almorzar', 'Tarde'),
    _BuiltinPicto('assets/images/pictogramas/calle.svg', 'CALLE', 'Quiero salir a la calle', 'Tarde'),
    _BuiltinPicto('assets/images/pictogramas/beber.svg', 'AGUA', 'Tengo sed, quiero agua', 'General'),
    _BuiltinPicto('assets/images/pictogramas/casa.svg', 'CASA', 'Quiero ir a casa', 'Noche'),
    _BuiltinPicto('assets/images/pictogramas/cansado.svg', 'CANSADO', 'Estoy cansado', 'Noche'),
  ];

  Future<void> _addPictogram(BuildContext context) async {
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
            top: 16,
            left: 16,
            right: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Agregar pictograma',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text('Selecciona un pictograma:',
                  style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 8),
              SizedBox(
                height: 120,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _builtinPictos.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final p = _builtinPictos[i];
                    final isSelected = selected == p;
                    return GestureDetector(
                      onTap: () => setS(() {
                        selected = p;
                        labelCtrl.text = p.label;
                        ttsCtrl.text = p.tts;
                      }),
                      child: Container(
                        width: 90,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isSelected
                                ? Colors.blue
                                : Colors.grey.shade300,
                            width: isSelected ? 2.5 : 1,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: isSelected
                              ? Colors.blue.shade50
                              : Colors.grey.shade50,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
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
                                    fontSize: 10,
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
                decoration: const InputDecoration(
                  labelText: 'Etiqueta',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: ttsCtrl,
                decoration: const InputDecoration(
                  labelText: 'Texto que se lee en voz alta',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selected == null || labelCtrl.text.trim().isEmpty
                      ? null
                      : () async {
                          Navigator.pop(ctx);
                          await PictogramService.createPictogramFor(
                            userId: patientId,
                            etiqueta: labelCtrl.text.trim(),
                            textoTts: ttsCtrl.text.trim(),
                            imageUrl: selected!.asset,
                            categoria: selected!.categoria,
                          );
                        },
                  child: const Text('Agregar pictograma'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _addPictogram(context),
        icon: const Icon(Icons.add),
        label: const Text('Agregar'),
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
                  Icon(Icons.image_not_supported, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Sin pictogramas. Agrega uno.',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 0.85,
            ),
            itemCount: pictos.length,
            itemBuilder: (context, i) {
              final p = pictos[i];
              return _PictoCard(
                picto: p,
                onDelete: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Eliminar pictograma'),
                      content: Text('¿Eliminar "${p.etiqueta}"?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancelar'),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red),
                          child: const Text('Eliminar'),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await PictogramService.deletePictogramFor(patientId, p.id);
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

class _PictoCard extends StatelessWidget {
  final PictogramaPersonalizado picto;
  final VoidCallback onDelete;
  const _PictoCard({required this.picto, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isAsset = picto.imageUrl.startsWith('assets/');

    return GestureDetector(
      onLongPress: onDelete,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: isAsset
                    ? Image.asset(picto.imageUrl,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) =>
                            const Icon(Icons.image, size: 40))
                    : picto.imageUrl.isNotEmpty
                        ? Image.network(picto.imageUrl, fit: BoxFit.contain)
                        : const Icon(Icons.image, size: 40, color: Colors.grey),
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
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
    );
  }
}

// ─── TAB REGISTROS ────────────────────────────────────────────────────────────

class _ActivityLogTab extends StatelessWidget {
  final String patientId;
  const _ActivityLogTab({required this.patientId});

  IconData _iconForType(String type) {
    return switch (type) {
      ActivityType.taskCompleted => Icons.check_circle_rounded,
      ActivityType.taskCreated => Icons.add_task,
      ActivityType.taskDeleted => Icons.delete_outline,
      ActivityType.pictogramCreated => Icons.image,
      ActivityType.pictogramDeleted => Icons.image_not_supported,
      _ => Icons.info_outline,
    };
  }

  Color _colorForType(String type) {
    return switch (type) {
      ActivityType.taskCompleted => Colors.green,
      ActivityType.taskCreated => Colors.blue,
      ActivityType.taskDeleted => Colors.red,
      ActivityType.pictogramCreated => Colors.purple,
      ActivityType.pictogramDeleted => Colors.orange,
      _ => Colors.grey,
    };
  }

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
            final color = _colorForType(type);

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
                    child: Icon(_iconForType(type), color: color, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(description,
                            style: const TextStyle(
                                fontWeight: FontWeight.w500, fontSize: 14)),
                        if (date != null)
                          Text(
                            DateFormat('dd/MM/yyyy HH:mm', 'es_ES').format(date),
                            style: TextStyle(
                                fontSize: 11, color: Colors.grey.shade600),
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

// ─── Helpers ──────────────────────────────────────────────────────────────────

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
