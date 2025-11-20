import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vibration/vibration.dart';

import 'package:organizate/services/notification_service.dart';
import 'package:organizate/services/streak_service.dart';
import 'package:organizate/utils/date_time_helper.dart';
import 'package:organizate/utils/reminder_options.dart';
import 'package:organizate/widgets/custom_nav_bar.dart';

class FocoScreen extends StatefulWidget {
  const FocoScreen({super.key});

  @override
  State<FocoScreen> createState() => _FocoScreenState();
}

class _FocoScreenState extends State<FocoScreen> with TickerProviderStateMixin {
  late final DocumentReference<Map<String, dynamic>> userDocRef;
  late final CollectionReference<Map<String, dynamic>> tasksCollection;

  final DateFormat _dateFormatter = DateFormat('dd MMM, HH:mm', 'es_ES');
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _pomodoroSoundEnabled = true;
  bool _pomodoroVibrationEnabled = false;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _userSettingsSubscription;

  final List<Duration> _quickDurations = const [
    Duration(minutes: 25),
    Duration(minutes: 50),
    Duration(minutes: 15),
  ];

  Duration _selectedDuration = const Duration(minutes: 25);
  int _remainingSeconds = 25 * 60;
  Timer? _pomodoroTimer;
  bool _isRunning = false;
  bool _isPaused = false;

  late final AnimationController _breathController;
  late final Animation<double> _breathAnimation;
  Timer? _breathingTimer;
  bool _breathingActive = false;
  int _breathingSecondsLeft = 60;
  int _breathingPhaseSecond = 0;
  String _breathingInstruction = 'Listo para comenzar';

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    userDocRef = FirebaseFirestore.instance.collection('users').doc(uid);
    tasksCollection = userDocRef.collection('tasks');
    _userSettingsSubscription = userDocRef.snapshots().listen((snapshot) {
      final data = snapshot.data() ?? {};
      if (!mounted) return;
      setState(() {
        _pomodoroSoundEnabled = (data['pomodoroSoundEnabled'] as bool?) ?? true;
        _pomodoroVibrationEnabled =
            (data['pomodoroVibrationEnabled'] as bool?) ?? false;
      });
    });

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );
    _breathAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.0), weight: 4), // inhale
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 4), // hold
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.7), weight: 6), // exhale
    ]).animate(CurvedAnimation(parent: _breathController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pomodoroTimer?.cancel();
    _breathingTimer?.cancel();
    _breathController.dispose();
    _audioPlayer.dispose();
     _userSettingsSubscription?.cancel();
    super.dispose();
  }

  void _selectDuration(Duration duration) {
    if (_isRunning) return;
    setState(() {
      _selectedDuration = duration;
      _remainingSeconds = duration.inSeconds;
    });
  }

  void _startPomodoro() {
    if (_isRunning && !_isPaused) return;
    _pomodoroTimer?.cancel();
    setState(() {
      _isRunning = true;
      _isPaused = false;
    });
    _pomodoroTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _onPomodoroFinished();
        return;
      }
      setState(() {
        _remainingSeconds--;
      });
    });
  }

  void _pausePomodoro() {
    if (!_isRunning) return;
    _pomodoroTimer?.cancel();
    setState(() {
      _isPaused = true;
    });
  }

  void _resetPomodoro() {
    _pomodoroTimer?.cancel();
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _remainingSeconds = _selectedDuration.inSeconds;
    });
  }

  Future<void> _onPomodoroFinished() async {
    setState(() {
      _isRunning = false;
      _isPaused = false;
      _remainingSeconds = _selectedDuration.inSeconds;
    });
    if (_pomodoroSoundEnabled) {
      try {
        await _audioPlayer.play(AssetSource('sounds/bell.mp3'));
      } catch (_) {
        // Ignora fallos al reproducir
      }
    }
    if (_pomodoroVibrationEnabled) {
      try {
        if (await Vibration.hasVibrator() ?? false) {
          Vibration.vibrate(duration: 800);
        }
      } catch (_) {
        // Ignora fallos de vibración
      }
    }
    try {
      await userDocRef.set(
        {
          'focusSessionsCompleted': FieldValue.increment(1),
          'totalFocusMinutes':
              FieldValue.increment(_selectedDuration.inMinutes),
        },
        SetOptions(merge: true),
      );
    } catch (_) {
      // Si falla no se interrumpe el flujo
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tiempo finalizado. ¡Toma un descanso!')),
      );
    }
  }

  double get _pomodoroProgress =>
      1 - (_remainingSeconds / _selectedDuration.inSeconds);

  String get _formattedRemaining {
    final minutes = (_remainingSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_remainingSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _startBreathingExercise() {
    if (_breathingActive) return;
    setState(() {
      _breathingActive = true;
      _breathingSecondsLeft = 60;
      _breathingPhaseSecond = 0;
      _breathingInstruction = 'Inhala 4 s';
    });
    _breathController.repeat();
    _breathingTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_breathingSecondsLeft <= 0) {
        timer.cancel();
        _breathController.reset();
        setState(() {
          _breathingActive = false;
          _breathingInstruction = 'Sesión completada';
        });
        return;
      }

      _breathingPhaseSecond = (_breathingPhaseSecond + 1) % 14;
      _updateBreathingInstruction();
      setState(() {
        _breathingSecondsLeft--;
      });
    });
  }

  void _updateBreathingInstruction() {
    if (_breathingPhaseSecond < 4) {
      _breathingInstruction = 'Inhala profundamente (4 s)';
    } else if (_breathingPhaseSecond < 8) {
      _breathingInstruction = 'Mantén el aire (4 s)';
    } else {
      _breathingInstruction = 'Exhala lentamente (6 s)';
    }
  }

  @override
  Widget build(BuildContext context) {
    const int screenIndex = 4;
    return Scaffold(
      bottomNavigationBar: const CustomNavBar(initialIndex: screenIndex),
      appBar: AppBar(
        title: const Text('Foco'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        automaticallyImplyLeading: false,
        actions: [
          StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: userDocRef.snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) return const SizedBox();
              final userData = snapshot.data?.data() ?? {};
              final int points = (userData['points'] as num?)?.toInt() ?? 0;
              final int streak = (userData['streak'] as num?)?.toInt() ?? 0;
              final String? avatarName = userData['avatar'] as String?;
              return Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0),
                    child: Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '$points',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        const Icon(Icons.local_fire_department,
                            color: Colors.deepOrange, size: 20),
                        const SizedBox(width: 4),
                        Text(
                          '$streak',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (avatarName != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: CircleAvatar(
                        radius: 15,
                        backgroundImage:
                            AssetImage('assets/avatars/$avatarName.png'),
                        onBackgroundImageError: (_, __) {},
                      ),
                    ),
                  if (avatarName == null)
                    const Padding(
                      padding: EdgeInsets.only(right: 12.0),
                      child:
                          CircleAvatar(radius: 15, backgroundColor: Colors.grey),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildPomodoroCard(),
            const SizedBox(height: 20),
            _buildBreathingCard(),
            const SizedBox(height: 24),
            const Text(
              'Tareas de Foco',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildTasksStream(),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        backgroundColor: Colors.purple,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildPomodoroCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.purple.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pomodoro',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _quickDurations
                .map(
                  (duration) => ChoiceChip(
                    label: Text('${duration.inMinutes} min'),
                    selected: _selectedDuration == duration,
                    onSelected: (_) => _selectDuration(duration),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 20),
          Center(
            child: SizedBox(
              height: 220,
              width: 220,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: _pomodoroProgress),
                    duration: const Duration(milliseconds: 400),
                    builder: (context, value, child) {
                      return CircularProgressIndicator(
                        value: value,
                        strokeWidth: 12,
                        backgroundColor: Colors.white,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.purple.shade400,
                        ),
                      );
                    },
                  ),
                  Text(
                    _formattedRemaining,
                    style: const TextStyle(
                        fontSize: 36, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildPomodoroButton(
                label: _isPaused ? 'Continuar' : 'Iniciar',
                icon: Icons.play_arrow,
                color: Colors.green,
                onTap: _startPomodoro,
              ),
              _buildPomodoroButton(
                label: 'Pausar',
                icon: Icons.pause,
                color: Colors.orange,
                onTap: _pausePomodoro,
              ),
              _buildPomodoroButton(
                label: 'Reiniciar',
                icon: Icons.refresh,
                color: Colors.redAccent,
                onTap: _resetPomodoro,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPomodoroButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.15),
        foregroundColor: color,
        minimumSize: const Size(100, 44),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      onPressed: onTap,
      icon: Icon(icon),
      label: Text(label),
    );
  }

  Widget _buildBreathingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Respiración guiada (1 min)',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Text(
            'Inhala 4s – Mantén 4s – Exhala 6s',
            style: TextStyle(color: Colors.blueGrey.shade600),
          ),
          const SizedBox(height: 20),
          Center(
            child: ScaleTransition(
              scale: _breathAnimation,
              child: Container(
                height: 180,
                width: 180,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0xFF7AD2F3), Color(0xFF4B9CD3)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                alignment: Alignment.center,
                child: Text(
                  _breathingActive
                      ? _breathingInstruction
                      : 'Pulsa iniciar',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _breathingActive
                  ? '${_breathingSecondsLeft}s restantes'
                  : '1 minuto total',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                minimumSize: const Size(180, 48),
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _startBreathingExercise,
              icon: const Icon(Icons.self_improvement),
              label: Text(_breathingActive ? 'En progreso' : 'Iniciar'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksStream() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: tasksCollection
          .where('category', isEqualTo: 'Foco')
          .orderBy('done')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(32.0),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return const Padding(
            padding: EdgeInsets.all(32.0),
            child: Text('Error al cargar tareas'),
          );
        }
        final docs = snapshot.data?.docs ?? [];
        if (docs.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32.0),
            child: Text(
              'No tienes tareas de foco.\nCrea una con el botón +',
              textAlign: TextAlign.center,
            ),
          );
        }
        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final taskData = docs[index].data();
            final taskId = docs[index].id;
            final String text = taskData['text'] ?? '';
            final Timestamp? dueDate = taskData['dueDate'] as Timestamp?;
            final bool isDone = taskData['done'] ?? false;
            final int reminderOffset =
                (taskData['reminderOffsetMinutes'] as num?)?.toInt() ?? 0;
            return GestureDetector(
              onLongPress: () =>
                  _showTaskOptionsDialog(context, taskId, text, 'Foco', dueDate, reminderOffset),
              child: _buildGoalItem(
                icon: Icons.psychology,
                iconColor: Colors.purple,
                text: text,
                isDone: isDone,
                dueDate: dueDate,
                onDonePressed: () async {
                  // Reutilizamos la misma receta que en Home para mantener consistencia.
                  final pointsChange = isDone ? -10 : 10;
                  final batch = FirebaseFirestore.instance.batch();
                  batch.update(docs[index].reference, {'done': !isDone});
                  batch.update(userDocRef, {
                    'points': FieldValue.increment(pointsChange),
                  });
                  try {
                    await batch.commit();
                    if (!isDone) {
                      await StreakService.updateStreakOnTaskCompletion(userDocRef);
                    }
                  } catch (error) {
                    debugPrint('Error al actualizar: $error');
                  }
                },
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildGoalItem({
    required IconData icon,
    required Color iconColor,
    required String text,
    required bool isDone,
    required VoidCallback onDonePressed,
    Timestamp? dueDate,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  text,
                  style: TextStyle(
                    fontSize: 16,
                    color: isDone ? Colors.grey : Colors.black87,
                    decoration: isDone
                        ? TextDecoration.lineThrough
                        : TextDecoration.none,
                  ),
                ),
                if (dueDate != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Entrega: ${_dateFormatter.format(dueDate.toDate())}',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          ElevatedButton(
            onPressed: onDonePressed,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  isDone ? Colors.grey.shade300 : Colors.purple.withValues(alpha: 0.2),
              foregroundColor:
                  isDone ? Colors.grey.shade600 : Colors.purple.shade800,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Text(isDone ? 'Deshacer' : 'Hecho'),
          ),
        ],
      ),
    );
  }

  void _showAddTaskDialog(BuildContext context) {
    final TextEditingController taskController = TextEditingController();
    DateTime? selectedDueDate;
    const String fixedCategory = 'Foco';
    int selectedReminderMinutes = 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Nueva tarea de foco'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: taskController,
                      decoration:
                          const InputDecoration(hintText: 'Describe tu práctica'),
                      autofocus: true,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedDueDate == null
                                ? 'Sin fecha'
                                : 'Entrega: ${_dateFormatter.format(selectedDueDate!)}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final picked = await pickDateTime(
                              context: context,
                              initialDate: selectedDueDate,
                            );
                            if (picked != null) {
                              setDialogState(() => selectedDueDate = picked);
                            }
                          },
                        ),
                        if (selectedDueDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () =>
                                setDialogState(() => selectedDueDate = null),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Recordatorio',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: selectedReminderMinutes,
                      items: kReminderOptions
                          .map(
                            (option) => DropdownMenuItem<int>(
                              value: option['minutes'] as int,
                              child: Text(option['label'] as String),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedReminderMinutes = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () async {
                    if (taskController.text.isEmpty) return;
                    final data = {
                      'text': taskController.text,
                      'category': fixedCategory,
                      'iconName': 'psychology',
                      'colorName': 'purple',
                      'done': false,
                      'createdAt': Timestamp.now(),
                      'reminderOffsetMinutes': selectedReminderMinutes,
                      if (selectedDueDate != null)
                        'dueDate': Timestamp.fromDate(selectedDueDate!),
                    };
                    final docRef = await tasksCollection.add(data);
                    await NotificationService.scheduleReminderIfNeeded(
                      userDocRef: userDocRef,
                      taskId: docRef.id,
                      taskTitle: taskController.text,
                      dueDate: selectedDueDate,
                      reminderOffsetMinutes: selectedReminderMinutes,
                    );
                    if (context.mounted) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const Text('Añadir'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showTaskOptionsDialog(
    BuildContext context,
    String taskId,
    String currentText,
    String? currentCategory,
    Timestamp? currentDueDate,
    int? reminderOffsetMinutes,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Opciones:\n"$currentText"'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Editar'),
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  _showEditTaskDialog(context, taskId, currentText,
                      currentCategory, currentDueDate, reminderOffsetMinutes);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Eliminar'),
                onTap: () async {
                  final navigator = Navigator.of(dialogContext);
                  final messenger = ScaffoldMessenger.of(dialogContext);
                  try {
                    await NotificationService.cancelTaskNotification(taskId);
                    await tasksCollection.doc(taskId).delete();
                    navigator.pop();
                    messenger.showSnackBar(
                      SnackBar(content: Text('"$currentText" eliminada')),
                    );
                  } catch (error) {
                    navigator.pop();
                    messenger.showSnackBar(
                      const SnackBar(content: Text('Error al eliminar')),
                    );
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
          ],
        );
      },
    );
  }

  void _showEditTaskDialog(
    BuildContext context,
    String taskId,
    String currentText,
    String? currentCategory,
    Timestamp? currentDueDate,
    int? currentReminderOffset,
  ) {
    final TextEditingController taskController =
        TextEditingController(text: currentText);
    DateTime? selectedDueDate = currentDueDate?.toDate();
    int selectedReminderMinutes = currentReminderOffset ?? 0;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Editar tarea'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: taskController,
                      decoration:
                          const InputDecoration(hintText: 'Nuevo texto'),
                      autofocus: true,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            selectedDueDate == null
                                ? 'Sin fecha'
                                : 'Entrega: ${_dateFormatter.format(selectedDueDate!)}',
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.calendar_today),
                          onPressed: () async {
                            final picked = await pickDateTime(
                              context: context,
                              initialDate: selectedDueDate,
                            );
                            if (picked != null) {
                              setDialogState(() => selectedDueDate = picked);
                            }
                          },
                        ),
                        if (selectedDueDate != null)
                          IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () =>
                                setDialogState(() => selectedDueDate = null),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'Recordatorio',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: selectedReminderMinutes,
                      items: kReminderOptions
                          .map(
                            (option) => DropdownMenuItem<int>(
                              value: option['minutes'] as int,
                              child: Text(option['label'] as String),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setDialogState(() => selectedReminderMinutes = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancelar'),
                ),
                TextButton(
                  onPressed: () async {
                    final navigator = Navigator.of(dialogContext);
                    if (taskController.text.isEmpty) {
                      navigator.pop();
                      return;
                    }
                    final updatedData = {
                      'text': taskController.text,
                      'category': currentCategory ?? 'Foco',
                      'iconName': 'psychology',
                      'colorName': 'purple',
                      'reminderOffsetMinutes': selectedReminderMinutes,
                      'dueDate': selectedDueDate == null
                          ? FieldValue.delete()
                          : Timestamp.fromDate(selectedDueDate!),
                    };
                    try {
                      await tasksCollection.doc(taskId).update(updatedData);
                      await NotificationService.cancelTaskNotification(taskId);
                      await NotificationService.scheduleReminderIfNeeded(
                        userDocRef: userDocRef,
                        taskId: taskId,
                        taskTitle: taskController.text,
                        dueDate: selectedDueDate,
                        reminderOffsetMinutes: selectedReminderMinutes,
                      );
                    } catch (_) {
                      // ignore
                    } finally {
                      navigator.pop();
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
