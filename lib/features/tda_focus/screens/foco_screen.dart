import 'dart:async';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/services/reminder_dispatcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/date_time_helper.dart';
import '../../../core/utils/reminder_helper.dart';
import '../../../core/utils/reminder_options.dart';
import '../../../core/widgets/custom_nav_bar.dart';
import '../services/pomodoro_service.dart';
import '../services/streak_service.dart';

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

    _breathController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 14),
    );
    _breathAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.8, end: 1.0), weight: 4),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.0), weight: 4),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.7), weight: 6),
    ]).animate(
      CurvedAnimation(parent: _breathController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _attachPomodoroListener();
    });
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
    _pomodoroService?.removeListener(_onPomodoroStatusChanged);
    super.dispose();
  }

  void _onPomodoroStatusChanged() {
    final service = _pomodoroService;
    if (service == null) {
      return;
    }
    if (_lastPomodoroStatus != PomodoroStatus.finished &&
        service.status == PomodoroStatus.finished) {
      _handlePomodoroFinished(service);
    }
    _lastPomodoroStatus = service.status;
  }

  Future<void> _handlePomodoroFinished(PomodoroService service) async {
    try {
      await userDocRef.set({
        'focusSessionsCompleted': FieldValue.increment(1),
        'totalFocusMinutes': FieldValue.increment(service.totalDuration.inMinutes),
      }, SetOptions(merge: true));
    } catch (_) {}
    if (mounted) {
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Sesión completada. Buen trabajo.',
            style: AppTheme.getTheme().textTheme.bodyMedium?.copyWith(
                  color: AppTheme.warmCream,
                ),
          ),
          backgroundColor: AppTheme.sageGreen,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
          ),
        ),
      );
    }
  }

  void _selectDuration(Duration duration, PomodoroService pomodoro) {
    if (pomodoro.status == PomodoroStatus.running ||
        pomodoro.status == PomodoroStatus.paused) {
      return;
    }
    HapticFeedback.selectionClick();
    setState(() => _selectedDuration = duration);
  }

  Future<void> _startPomodoro(PomodoroService pomodoro) async {
    HapticFeedback.lightImpact();
    await pomodoro.start(_selectedDuration);
  }

  Future<void> _pauseOrResume(PomodoroService pomodoro) async {
    HapticFeedback.lightImpact();
    if (pomodoro.status == PomodoroStatus.running) {
      await pomodoro.pause();
    } else if (pomodoro.status == PomodoroStatus.paused) {
      await pomodoro.resume();
    }
  }

  Future<void> _cancelPomodoro(PomodoroService pomodoro) async {
    HapticFeedback.lightImpact();
    await pomodoro.cancel();
  }

  String _formattedRemaining(PomodoroService pomodoro) {
    final current = pomodoro.status == PomodoroStatus.idle
        ? _selectedDuration
        : (pomodoro.remaining > Duration.zero
            ? pomodoro.remaining
            : Duration.zero);
    final minutes = current.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = current.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  double _pomodoroProgress(PomodoroService pomodoro) {
    if (pomodoro.totalDuration.inSeconds == 0) return 0;
    return 1 - (pomodoro.remaining.inSeconds / pomodoro.totalDuration.inSeconds);
  }

  void _startBreathingExercise() {
    if (_breathingActive) {
      return;
    }
    HapticFeedback.lightImpact();
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
      setState(() => _breathingSecondsLeft--);
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
    final pomodoro = context.watch<PomodoroService>();

    return Scaffold(
      backgroundColor: AppTheme.warmCream,
      bottomNavigationBar: const CustomNavBar(initialIndex: 2),
      appBar: _buildAppBar(),
      floatingActionButton: _buildFab(),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTimerSection(pomodoro),
            const SizedBox(height: 32),
            _buildBreathingCard(),
            const SizedBox(height: 32),
            _buildTasksSection(),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.warmCream,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      title: Text(
        'Foco',
        style: AppTheme.getTheme().textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTheme.warmCharcoal,
              letterSpacing: 0.5,
            ),
      ),
      actions: [
        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: _userDocStream,
          builder: (context, snapshot) {
            final userData = snapshot.data?.data() ?? {};
            final int points = (userData['points'] as num?)?.toInt() ?? 0;
            final int streak = (userData['streak'] as num?)?.toInt() ?? 0;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildStatBadge(
                    icon: Icons.star_rounded,
                    value: '$points',
                    color: const Color(0xFFD4A853),
                  ),
                  const SizedBox(width: 8),
                  _buildStatBadge(
                    icon: Icons.local_fire_department_rounded,
                    value: '$streak',
                    color: const Color(0xFFBF8060),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppTheme.radiusSmall),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFab() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        boxShadow: [
          BoxShadow(
            color: AppTheme.softBlue.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: FloatingActionButton(
        onPressed: () => _showAddTaskDialog(context),
        backgroundColor: AppTheme.softBlue,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        ),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildTimerSection(PomodoroService pomodoro) {
    final isRunning = pomodoro.status == PomodoroStatus.running;
    final isPaused = pomodoro.status == PomodoroStatus.paused;
    final isFinished = pomodoro.status == PomodoroStatus.finished;
    final progress = _pomodoroProgress(pomodoro);

    return Column(
      children: [
        _buildProgressRing(pomodoro, progress, isFinished),
        const SizedBox(height: 32),
        Text(
          _formattedRemaining(pomodoro),
          style: AppTheme.getTheme().textTheme.displaySmall?.copyWith(
                fontWeight: FontWeight.w300,
                color: isFinished ? AppTheme.sageGreen : AppTheme.warmCharcoal,
                letterSpacing: 2,
              ),
        ),
        if (isFinished) ...[
          const SizedBox(height: 8),
          Text(
            'Sesión completada',
            style: AppTheme.getTheme().textTheme.bodyMedium?.copyWith(
                  color: AppTheme.sageGreen,
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
        const SizedBox(height: 36),
        _buildDurationChips(pomodoro),
        const SizedBox(height: 28),
        _buildControlButtons(pomodoro, isRunning, isPaused, isFinished),
      ],
    );
  }

  Widget _buildProgressRing(
    PomodoroService pomodoro,
    double progress,
    bool isFinished,
  ) {
    return SizedBox(
      height: 260,
      width: 260,
      child: Stack(
        alignment: Alignment.center,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: progress),
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => CustomPaint(
              painter: _ProgressRingPainter(
                progress: value,
                trackColor: AppTheme.outlineVariant.withOpacity(0.3),
                progressColor: isFinished
                    ? AppTheme.sageGreen
                    : AppTheme.softBlue,
                strokeWidth: 12,
              ),
              size: const Size(260, 260),
            ),
          ),
          if (pomodoro.status == PomodoroStatus.running)
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 1.0, end: 1.03),
              duration: const Duration(seconds: 2),
              builder: (context, value, child) => Transform.scale(
                scale: value,
                child: child,
              ),
              child: Container(
                height: 248,
                width: 248,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.softBlue.withOpacity(0.06),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDurationChips(PomodoroService pomodoro) {
    final isDisabled = pomodoro.status == PomodoroStatus.running ||
        pomodoro.status == PomodoroStatus.paused;

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 10,
      runSpacing: 10,
      children: _quickDurations.map((duration) {
        final isSelected = _selectedDuration == duration;
        return GestureDetector(
          onTap: isDisabled ? null : () => _selectDuration(duration, pomodoro),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.softBlueContainer
                  : AppTheme.surfaceVariant,
              borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
              border: Border.all(
                color: isSelected
                    ? AppTheme.softBlue.withOpacity(0.4)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Text(
              '${duration.inMinutes} min',
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? AppTheme.softBlueDark
                    : AppTheme.mutedText,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildControlButtons(
    PomodoroService pomodoro,
    bool isRunning,
    bool isPaused,
    bool isFinished,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildPrimaryButton(
          icon: isRunning
              ? Icons.pause_rounded
              : isFinished
                  ? Icons.replay_rounded
                  : Icons.play_arrow_rounded,
          label: isRunning
              ? 'Pausar'
              : isFinished
                  ? 'Reiniciar'
                  : 'Iniciar',
          onTap: isFinished
              ? () => _cancelPomodoro(pomodoro)
              : isRunning || isPaused
                  ? () => _pauseOrResume(pomodoro)
                  : () => _startPomodoro(pomodoro),
        ),
        const SizedBox(width: 16),
        _buildSecondaryButton(
          icon: Icons.refresh_rounded,
          label: 'Reiniciar',
          onTap: () => _cancelPomodoro(pomodoro),
        ),
      ],
    );
  }

  Widget _buildPrimaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.softBlue,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: AppTheme.softBlue.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 22),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: AppTheme.outlineSoft,
            width: 1,
          ),
        ),
        child: Icon(icon, color: AppTheme.mutedText, size: 22),
      ),
    );
  }

  Widget _buildBreathingCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.surfaceWhite,
        borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
        border: Border.all(
          color: AppTheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.self_improvement_rounded,
                color: AppTheme.softLavender,
                size: 22,
              ),
              const SizedBox(width: 10),
              Text(
                'Respiración guiada',
                style: AppTheme.getTheme().textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.warmCharcoal,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Inhala 4s – Mantén 4s – Exhala 6s',
            style: AppTheme.getTheme().textTheme.bodySmall?.copyWith(
                  color: AppTheme.mutedText,
                ),
          ),
          const SizedBox(height: 24),
          Center(
            child: ScaleTransition(
              scale: _breathAnimation,
              child: Container(
                height: 140,
                width: 140,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.softBlueContainer,
                      AppTheme.softBlue.withOpacity(0.3),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: AppTheme.softBlue.withOpacity(0.2),
                    width: 2,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _breathingActive
                        ? _breathingInstruction
                        : 'Pulsa iniciar',
                    textAlign: TextAlign.center,
                    style: AppTheme.getTheme().textTheme.bodyMedium?.copyWith(
                          color: AppTheme.softBlueDark,
                          fontWeight: FontWeight.w600,
                        ),
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
              style: AppTheme.getTheme().textTheme.labelMedium?.copyWith(
                    color: AppTheme.mutedText,
                  ),
            ),
          ),
          const SizedBox(height: 16),
          Center(
            child: GestureDetector(
              onTap: _startBreathingExercise,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                decoration: BoxDecoration(
                  color: _breathingActive
                      ? AppTheme.surfaceVariant
                      : AppTheme.lavenderContainer,
                  borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                ),
                child: Text(
                  _breathingActive ? 'En progreso' : 'Iniciar',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _breathingActive
                        ? AppTheme.mutedText
                        : AppTheme.softLavender,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTasksSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tareas de Foco',
          style: AppTheme.getTheme().textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTheme.warmCharcoal,
              ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _focusTasksStream,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              );
            }
            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Text(
                    'Error al cargar tareas',
                    style: AppTheme.getTheme().textTheme.bodyMedium?.copyWith(
                          color: AppTheme.mutedText,
                        ),
                  ),
                ),
              );
            }
            final docs = snapshot.data?.docs ?? [];
            if (docs.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceWhite,
                  borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
                  border: Border.all(
                    color: AppTheme.outlineVariant.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.task_alt_rounded,
                      size: 48,
                      color: AppTheme.outlineSoft,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Sin tareas de foco',
                      style: AppTheme.getTheme().textTheme.bodyMedium?.copyWith(
                            color: AppTheme.mutedText,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Usa el botón + para añadir una',
                      style: AppTheme.getTheme().textTheme.bodySmall?.copyWith(
                            color: AppTheme.mutedText,
                          ),
                    ),
                  ],
                ),
              );
            }
            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: docs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final taskData = docs[index].data();
                final taskId = docs[index].id;
                final String text = taskData['text'] ?? '';
                final Timestamp? dueDate = taskData['dueDate'] as Timestamp?;
                final bool isDone = taskData['done'] ?? false;
                final int? reminderMinutes = extractReminderMinutes(taskData);
                return _buildTaskItem(
                  text: text,
                  isDone: isDone,
                  dueDate: dueDate,
                  onDonePressed: () => _toggleTask(
                    docs[index].reference,
                    taskId,
                    isDone,
                    text,
                    reminderMinutes,
                  ),
                  onEdit: () => _showTaskOptionsDialog(
                    context,
                    taskId,
                    text,
                    dueDate,
                    reminderMinutes,
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildTaskItem({
    required String text,
    required bool isDone,
    required VoidCallback onDonePressed,
    required VoidCallback onEdit,
    Timestamp? dueDate,
  }) {
    return GestureDetector(
      onLongPress: onEdit,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.surfaceWhite,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          border: Border.all(
            color: AppTheme.outlineVariant.withOpacity(0.4),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            GestureDetector(
              onTap: onDonePressed,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDone
                      ? AppTheme.sageGreen
                      : AppTheme.surfaceVariant,
                  border: Border.all(
                    color: isDone
                        ? AppTheme.sageGreen
                        : AppTheme.outlineSoft,
                    width: 1.5,
                  ),
                ),
                child: isDone
                    ? const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 18,
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    text,
                    style: AppTheme.getTheme().textTheme.bodyMedium?.copyWith(
                          color: isDone
                              ? AppTheme.mutedText
                              : AppTheme.warmCharcoal,
                          decoration: isDone
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                  ),
                  if (dueDate != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Entrega: ${_dateFormatter.format(dueDate.toDate())}',
                      style:
                          AppTheme.getTheme().textTheme.bodySmall?.copyWith(
                                color: AppTheme.mutedText,
                              ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleTask(
    DocumentReference<Map<String, dynamic>> taskRef,
    String taskId,
    bool isDone,
    String taskTitle,
    int? reminderMinutes,
  ) async {
    HapticFeedback.selectionClick();
    final pointsChange = isDone ? -10 : 10;
    final batch = FirebaseFirestore.instance.batch();
    batch.update(taskRef, {'done': !isDone});
    batch.update(userDocRef, {'points': FieldValue.increment(pointsChange)});
    try {
      await batch.commit();
      if (!isDone) {
        await ReminderDispatcher.cancelTaskReminder(
          userDocRef: userDocRef,
          taskId: taskId,
        );
        await StreakService.updateStreakOnTaskCompletion(userDocRef);
      }
    } catch (error) {
      debugPrint('Error al actualizar: $error');
    }
  }

  Future<void> _showAddTaskDialog(BuildContext context) async {
    final TextEditingController taskController = TextEditingController();
    DateTime? selectedDueDate;
    final int? defaultReminder = await fetchDefaultReminderMinutes(userDocRef);
    int? selectedReminderMinutes = defaultReminder;
    if (!context.mounted) {
      return;
    }

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surfaceWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
              ),
              title: Text(
                'Nueva tarea de foco',
                style: AppTheme.getTheme().textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.warmCharcoal,
                    ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: taskController,
                      decoration: const InputDecoration(
                        hintText: 'Describe tu práctica',
                      ),
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
                            style: TextStyle(
                              color: AppTheme.mutedText,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.calendar_today_rounded,
                            color: AppTheme.softBlue,
                            size: 20,
                          ),
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
                            icon: Icon(
                              Icons.close_rounded,
                              color: AppTheme.mutedText,
                              size: 18,
                            ),
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
                      ),
                      initialValue: selectedReminderMinutes,
                      items: kReminderOptions
                          .map((o) => DropdownMenuItem<int?>(
                                value: o['minutes'] as int?,
                                child: Text(o['label'] as String),
                              ))
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
                  child: Text(
                    'Cancelar',
                    style: TextStyle(color: AppTheme.mutedText),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    if (taskController.text.isEmpty) {
                      return;
                    }
                    final data = <String, dynamic>{
                      'text': taskController.text,
                      'category': 'Foco',
                      'iconName': 'psychology',
                      'colorName': 'purple',
                      'done': false,
                      'createdAt': Timestamp.now(),
                      'reminderMinutes': selectedReminderMinutes,
                      if (selectedDueDate != null)
                        'dueDate': Timestamp.fromDate(selectedDueDate!),
                    };
                    final docRef = await tasksCollection.add(data);
                    await ReminderDispatcher.scheduleTaskReminder(
                      userDocRef: userDocRef,
                      taskId: docRef.id,
                      taskTitle: taskController.text,
                      dueDate: selectedDueDate,
                      reminderMinutes: selectedReminderMinutes,
                    );
                    if (context.mounted) Navigator.of(context).pop();
                  },
                  child: Text(
                    'Añadir',
                    style: TextStyle(
                      color: AppTheme.softBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
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
    Timestamp? currentDueDate,
    int? reminderMinutes,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: AppTheme.surfaceWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
          ),
          title: Text(
            'Opciones',
            style: AppTheme.getTheme().textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppTheme.warmCharcoal,
                ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(Icons.edit_rounded, color: AppTheme.softBlue),
                title: Text(
                  'Editar',
                  style: AppTheme.getTheme().textTheme.bodyMedium?.copyWith(
                        color: AppTheme.warmCharcoal,
                      ),
                ),
                onTap: () {
                  Navigator.of(dialogContext).pop();
                  _showEditTaskDialog(
                    context,
                    taskId,
                    currentText,
                    currentDueDate,
                    reminderMinutes,
                  );
                },
              ),
              ListTile(
                leading:
                    Icon(Icons.delete_rounded, color: AppTheme.errorMuted),
                title: Text(
                  'Eliminar',
                  style: AppTheme.getTheme().textTheme.bodyMedium?.copyWith(
                        color: AppTheme.errorMuted,
                      ),
                ),
                onTap: () async {
                  final navigator = Navigator.of(dialogContext);
                  final messenger = ScaffoldMessenger.of(dialogContext);
                  try {
                    await tasksCollection.doc(taskId).delete();
                    try {
                      await ReminderDispatcher.cancelTaskReminder(
                        userDocRef: userDocRef,
                        taskId: taskId,
                      );
                    } catch (_) {}
                    if (navigator.mounted) navigator.pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('"$currentText" eliminada'),
                        backgroundColor: AppTheme.warmCharcoal,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                      ),
                    );
                  } catch (error) {
                    if (navigator.mounted) navigator.pop();
                    messenger.showSnackBar(
                      SnackBar(
                        content: Text('Error al eliminar: $error'),
                        backgroundColor: AppTheme.warmCharcoal,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusMedium),
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancelar',
                style: TextStyle(color: AppTheme.mutedText),
              ),
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
              backgroundColor: AppTheme.surfaceWhite,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppTheme.radiusXLarge),
              ),
              title: Text(
                'Editar tarea',
                style: AppTheme.getTheme().textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppTheme.warmCharcoal,
                    ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: taskController,
                      decoration: const InputDecoration(hintText: 'Nuevo texto'),
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
                            style: TextStyle(
                              color: AppTheme.mutedText,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(
                            Icons.calendar_today_rounded,
                            color: AppTheme.softBlue,
                            size: 20,
                          ),
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
                            icon: Icon(
                              Icons.close_rounded,
                              color: AppTheme.mutedText,
                              size: 18,
                            ),
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
                      ),
                      initialValue: selectedReminderMinutes,
                      items: kReminderOptions
                          .map((o) => DropdownMenuItem<int?>(
                                value: o['minutes'] as int?,
                                child: Text(o['label'] as String),
                              ))
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
                  child: Text(
                    'Cancelar',
                    style: TextStyle(color: AppTheme.mutedText),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    final navigator = Navigator.of(dialogContext);
                    if (taskController.text.isEmpty) {
                      navigator.pop();
                      return;
                    }
                    final updatedData = <String, dynamic>{
                      'text': taskController.text,
                      'category': 'Foco',
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
                      await ReminderDispatcher.cancelTaskReminder(
                        userDocRef: userDocRef,
                        taskId: taskId,
                      );
                      await ReminderDispatcher.scheduleTaskReminder(
                        userDocRef: userDocRef,
                        taskId: taskId,
                        taskTitle: taskController.text,
                        dueDate: selectedDueDate,
                        reminderMinutes: selectedReminderMinutes,
                      );
                    } catch (_) {}
                    finally {
                      navigator.pop();
                    }
                  },
                  child: Text(
                    'Guardar',
                    style: TextStyle(
                      color: AppTheme.softBlue,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ProgressRingPainter extends CustomPainter {
  final double progress;
  final Color trackColor;
  final Color progressColor;
  final double strokeWidth;

  _ProgressRingPainter({
    required this.progress,
    required this.trackColor,
    required this.progressColor,
    this.strokeWidth = 12,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) - strokeWidth) / 2;

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      final sweepAngle = 2 * pi * progress.clamp(0.0, 1.0);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi / 2,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_ProgressRingPainter oldDelegate) =>
      oldDelegate.progress != progress;
}
