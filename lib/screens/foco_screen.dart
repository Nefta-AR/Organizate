import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vibration/vibration.dart';

import 'package:organizate/screens/settings_screen.dart';
import 'package:organizate/services/notification_service.dart';
import 'package:organizate/services/pomodoro_service.dart';
import 'package:organizate/services/streak_service.dart';
import 'package:organizate/utils/date_time_helper.dart';
import 'package:organizate/utils/emergency_contact_helper.dart';
import 'package:organizate/utils/reminder_helper.dart';
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
  late final Stream<QuerySnapshot<Map<String, dynamic>>> _focusTasksStream;
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _userDocStream;

  final DateFormat _dateFormatter = DateFormat('dd MMM, HH:mm', 'es_ES');
  final AudioPlayer _audioPlayer = AudioPlayer();
  bool _pomodoroSoundEnabled = true;
  bool _pomodoroVibrationEnabled = false;
  String _pomodoroSoundKey = 'bell';
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _userSettingsSubscription;

  final List<Duration> _quickDurations = const [
    Duration(minutes: 5),
    Duration(minutes: 15),
    Duration(minutes: 25),
    Duration(minutes: 50),
  ];
  Duration _selectedDuration = const Duration(minutes: 25);

  PomodoroStatus _lastPomodoroStatus = PomodoroStatus.idle;
  PomodoroService? _pomodoroService;

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
    _userDocStream = userDocRef.snapshots();
    _focusTasksStream = tasksCollection
        .where('category', isEqualTo: 'Foco')
        .orderBy('done')
        .orderBy('createdAt', descending: true)
        .snapshots();
    _userSettingsSubscription = userDocRef.snapshots().listen((snapshot) {
      final data = snapshot.data() ?? {};
      if (!mounted) return;
      setState(() {
        _pomodoroSoundEnabled = (data['pomodoroSoundEnabled'] as bool?) ?? true;
        _pomodoroVibrationEnabled =
            (data['pomodoroVibrationEnabled'] as bool?) ?? false;
        _pomodoroSoundKey = (data['pomodoroSound'] as String?) ?? 'bell';
      });
    });

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );
    _breathAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.0), weight: 4),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 4),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.7), weight: 6),
    ]).animate(
        CurvedAnimation(parent: _breathController, curve: Curves.easeInOut));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attachPomodoroListener();
      _requestPermissions();
    });
  }

  Future<void> _requestPermissions() async {
    await NotificationService.requestPermissions();
  }

  void _attachPomodoroListener() {
    _pomodoroService = context.read<PomodoroService>();
    _lastPomodoroStatus = _pomodoroService!.status;
    _pomodoroService!.addListener(_onPomodoroStatusChanged);
  }

  @override
  void dispose() {
    _breathingTimer?.cancel();
    _breathController.dispose();
    _audioPlayer.dispose();
    _userSettingsSubscription?.cancel();
    _pomodoroService?.removeListener(_onPomodoroStatusChanged);
    super.dispose();
  }

  void _onPomodoroStatusChanged() {
    final service = _pomodoroService;
    if (service == null) return;
    if (_lastPomodoroStatus != PomodoroStatus.finished &&
        service.status == PomodoroStatus.finished) {
      _handlePomodoroFinished(service);
    }
    _lastPomodoroStatus = service.status;
  }

  Future<void> _handlePomodoroFinished(PomodoroService service) async {
    if (_pomodoroSoundEnabled) {
      final String assetPath = _pomodoroSoundKey == 'notificacion1'
          ? 'sounds/Notificacion1.mp3'
          : 'sounds/bell.mp3';
      try {
        await _audioPlayer.play(AssetSource(assetPath));
      } catch (error) {
        debugPrint('[FOCO] Error al reproducir sonido Pomodoro: $error');
      }
    }
    if (_pomodoroVibrationEnabled) {
      try {
        final hasVibrator = await Vibration.hasVibrator();
        if (hasVibrator == true) {
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
              FieldValue.increment(service.totalDuration.inMinutes),
        },
        SetOptions(merge: true),
      );
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tiempo finalizado. ¡Toma un descanso!')),
      );
    }
  }

  void _selectDuration(Duration duration, PomodoroService pomodoro) {
    if (pomodoro.status == PomodoroStatus.running ||
        pomodoro.status == PomodoroStatus.paused) {
      return;
    }
    setState(() {
      _selectedDuration = duration;
    });
  }

  Future<void> _startPomodoro(PomodoroService pomodoro) async {
    await pomodoro.start(_selectedDuration);
  }

  Future<void> _pauseOrResume(PomodoroService pomodoro) async {
    if (pomodoro.status == PomodoroStatus.running) {
      await pomodoro.pause();
    } else if (pomodoro.status == PomodoroStatus.paused) {
      await pomodoro.resume();
    }
  }

  Future<void> _cancelPomodoro(PomodoroService pomodoro) async {
    await pomodoro.cancel();
  }

  String _formattedRemaining(PomodoroService pomodoro) {
    final Duration current = pomodoro.status == PomodoroStatus.idle
        ? _selectedDuration
        : (pomodoro.remaining > Duration.zero
            ? pomodoro.remaining
            : const Duration());
    final minutes = current.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = current.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double _pomodoroProgress(PomodoroService pomodoro) {
    if (pomodoro.totalDuration.inSeconds == 0) return 0;
    final remaining = pomodoro.remaining.inSeconds;
    final total = pomodoro.totalDuration.inSeconds;
    return 1 - (remaining / total);
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
    final pomodoro = context.watch<PomodoroService>();
    final bool isPaused = pomodoro.status == PomodoroStatus.paused;

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
            stream: _userDocStream,
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
            const Text(
              'Modo Foco',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildPomodoroCard(pomodoro, isPaused),
            const SizedBox(height: 24),
            _buildBreathingCard(),
            const SizedBox(height: 24),
            const Text(
              'Tareas de Foco',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _buildTasksStream(),
            const SizedBox(height: 24),
            _buildEmergencyQuickButton(),
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

  Widget _buildPomodoroCard(PomodoroService pomodoro, bool isPaused) {
    final String pauseResumeLabel = isPaused ? 'Reanudar' : 'Pausar';

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
            'Sesiones Pomodoro',
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
                    onSelected: (_) => _selectDuration(duration, pomodoro),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          Center(
            child: Column(
              children: [
                Text(
                  _formattedRemaining(pomodoro),
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 160,
                  width: 160,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(
                          begin: 0,
                          end: _pomodoroProgress(pomodoro),
                        ),
                        duration: const Duration(milliseconds: 400),
                        builder: (context, value, child) {
                          return CircularProgressIndicator(
                            value: value,
                            strokeWidth: 10,
                            backgroundColor: Colors.white,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.purple.shade400,
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Expanded(
                child: _buildPomodoroButton(
                  label: 'Iniciar',
                  icon: Icons.play_arrow,
                  color: Colors.green,
                  onTap: () => _startPomodoro(pomodoro),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPomodoroButton(
                  label: pauseResumeLabel,
                  icon: isPaused ? Icons.play_arrow : Icons.pause,
                  color: Colors.orange,
                  onTap: () => _pauseOrResume(pomodoro),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPomodoroButton(
                  label: 'Reiniciar',
                  icon: Icons.refresh,
                  color: Colors.redAccent,
                  onTap: () => _cancelPomodoro(pomodoro),
                ),
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
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color.withValues(alpha: 0.15),
        foregroundColor: color,
        minimumSize: const Size(120, 72),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 0,
      ),
      onPressed: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 22),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              maxLines: 1,
              softWrap: false,
              overflow: TextOverflow.visible,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
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
                  _breathingActive ? _breathingInstruction : 'Pulsa iniciar',
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
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
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
      stream: _focusTasksStream,
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
            final int? reminderMinutes = extractReminderMinutes(taskData);
            return GestureDetector(
              onLongPress: () => _showTaskOptionsDialog(
                  context, taskId, text, 'Foco', dueDate, reminderMinutes),
              child: _buildGoalItem(
                icon: Icons.psychology,
                iconColor: Colors.purple,
                text: text,
                isDone: isDone,
                dueDate: dueDate,
                onDonePressed: () async {
                  final pointsChange = isDone ? -10 : 10;
                  final batch = FirebaseFirestore.instance.batch();
                  batch.update(docs[index].reference, {'done': !isDone});
                  batch.update(userDocRef, {
                    'points': FieldValue.increment(pointsChange),
                  });
                  try {
                    await batch.commit();
                    if (!isDone) {
                      await NotificationService.cancelTaskNotification(taskId);
                      await StreakService.updateStreakOnTaskCompletion(
                          userDocRef);
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

  Widget _buildEmergencyQuickButton() {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _userDocStream,
      builder: (context, snapshot) {
        final isLoading = snapshot.connectionState == ConnectionState.waiting;
        final data = snapshot.data?.data();
        final String? emergencyName = data?['emergencyName'] as String?;
        final String? emergencyPhone =
            data?['emergencyPhone'] as String? ?? data?['phone'] as String?;
        final String? trimmedName =
            (emergencyName?.trim().isEmpty ?? true) ? null : emergencyName!.trim();
        final String? trimmedPhone =
            (emergencyPhone?.trim().isEmpty ?? true) ? null : emergencyPhone!.trim();
        final String helperText = isLoading
            ? 'Cargando contacto...'
            : trimmedPhone != null
                ? 'Tu contacto está listo por si necesitas ayuda.'
                : 'Configura un contacto desde tu perfil.';

        return Column(
          children: [
            Text(
              helperText,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 220,
              child: OutlinedButton.icon(
                onPressed: () => handleEmergencyContactAction(
                  context,
                  emergencyName: trimmedName ?? emergencyName,
                  emergencyPhone: trimmedPhone ?? emergencyPhone,
                  onNavigateToProfile: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
                icon: const Icon(Icons.phone_in_talk),
                label: const Text('Necesito ayuda'),
              ),
            ),
          ],
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
              backgroundColor: isDone
                  ? Colors.grey.shade300
                  : Colors.purple.withValues(alpha: 0.2),
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

  Future<void> _showAddTaskDialog(BuildContext context) async {
    final TextEditingController taskController = TextEditingController();
    DateTime? selectedDueDate;
    const String fixedCategory = 'Foco';
    final int? defaultReminder = await fetchDefaultReminderMinutes(userDocRef);
    int? selectedReminderMinutes = defaultReminder;
    if (!context.mounted) return;

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
                    DropdownButtonFormField<int?>(
                      key: ValueKey(selectedReminderMinutes),
                      decoration: const InputDecoration(
                        labelText: 'Recordatorio',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: selectedReminderMinutes,
                      items: kReminderOptions
                          .map(
                            (option) => DropdownMenuItem<int?>(
                              value: option['minutes'] as int?,
                              child: Text(option['label'] as String),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setDialogState(() => selectedReminderMinutes = value),
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
                      'reminderMinutes': selectedReminderMinutes,
                      if (selectedDueDate != null)
                        'dueDate': Timestamp.fromDate(selectedDueDate!),
                    };
                    final docRef = await tasksCollection.add(data);
                    await NotificationService.scheduleReminderIfNeeded(
                      userDocRef: userDocRef,
                      taskId: docRef.id,
                      taskTitle: taskController.text,
                      dueDate: selectedDueDate,
                      reminderMinutes: selectedReminderMinutes,
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
    int? reminderMinutes,
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
                      currentCategory, currentDueDate, reminderMinutes);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete),
                title: const Text('Eliminar'),
                onTap: () async {
                  final navigator = Navigator.of(dialogContext);
                  final messenger = ScaffoldMessenger.of(dialogContext);
                  try {
                    await tasksCollection.doc(taskId).delete();
                    try {
                      await NotificationService.cancelTaskNotification(taskId);
                    } catch (_) {}
                    if (navigator.mounted) {
                      navigator.pop();
                    }
                    messenger.showSnackBar(
                      SnackBar(content: Text('"$currentText" eliminada')),
                    );
                  } catch (error) {
                    if (navigator.mounted) {
                      navigator.pop();
                    }
                    messenger.showSnackBar(
                      SnackBar(content: Text('Error al eliminar: $error')),
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
    int? currentReminderMinutes,
  ) {
    final TextEditingController taskController =
        TextEditingController(text: currentText);
    DateTime? selectedDueDate = currentDueDate?.toDate();
    int? selectedReminderMinutes = currentReminderMinutes;

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
                    DropdownButtonFormField<int?>(
                      key: ValueKey(selectedReminderMinutes),
                      decoration: const InputDecoration(
                        labelText: 'Recordatorio',
                        border: OutlineInputBorder(),
                      ),
                      initialValue: selectedReminderMinutes,
                      items: kReminderOptions
                          .map(
                            (option) => DropdownMenuItem<int?>(
                              value: option['minutes'] as int?,
                              child: Text(option['label'] as String),
                            ),
                          )
                          .toList(),
                      onChanged: (value) =>
                          setDialogState(() => selectedReminderMinutes = value),
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
                      'reminderMinutes': selectedReminderMinutes,
                      'reminderOffsetMinutes': FieldValue.delete(),
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
                        reminderMinutes: selectedReminderMinutes,
                      );
                    } catch (_) {} finally {
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
