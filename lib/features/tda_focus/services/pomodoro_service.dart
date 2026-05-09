import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/notification_service.dart';

enum PomodoroStatus { idle, running, paused, finished }

class PomodoroService extends ChangeNotifier with WidgetsBindingObserver {
  Duration totalDuration = Duration.zero;
  Duration remaining = Duration.zero;
  PomodoroStatus status = PomodoroStatus.idle;

  Timer? _ticker;
  DateTime? _endTime;

  static const _keyEndTime = 'pomodoro_end_time_ms';
  static const _keyTotalDuration = 'pomodoro_total_duration_ms';
  static const _keyRemaining = 'pomodoro_remaining_ms';
  static const _keyStatus = 'pomodoro_status';

  PomodoroService() {
    WidgetsBinding.instance.addObserver(this);
    _restoreState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshFromPersistence();
    }
  }

  Future<void> start(Duration duration) async {
    _ticker?.cancel();
    _ticker = null;
    _endTime = null;
    await _cancelNotificationSafely();

    totalDuration = duration;
    remaining = duration;
    status = PomodoroStatus.running;
    _endTime = DateTime.now().add(duration);

    await _persistState();
    _startTicker();
    await _scheduleSystemNotification();
    notifyListeners();
  }

  Future<void> pause() async {
    if (status != PomodoroStatus.running) return;
    _ticker?.cancel();

    final millisLeft =
        _endTime?.difference(DateTime.now()).inMilliseconds ??
            remaining.inMilliseconds;
    final secondsLeft = (millisLeft / 1000).ceil();
    remaining = Duration(seconds: secondsLeft < 0 ? 0 : secondsLeft);

    status = PomodoroStatus.paused;
    _endTime = null;

    await _persistState();
    await _cancelNotificationSafely();
    notifyListeners();
  }

  Future<void> resume() async {
    if (status != PomodoroStatus.paused) return;

    status = PomodoroStatus.running;
    _endTime = DateTime.now().add(remaining);

    await _persistState();
    await _scheduleSystemNotification();
    _startTicker();
    notifyListeners();
  }

  Future<void> cancel() async {
    _ticker?.cancel();
    _ticker = null;
    _endTime = null;
    remaining = Duration.zero;
    totalDuration = Duration.zero;
    status = PomodoroStatus.idle;

    await _clearPersistence();
    await _cancelNotificationSafely();
    notifyListeners();
  }

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  Future<void> _tick() async {
    if (_endTime == null) {
      _ticker?.cancel();
      return;
    }

    final millisLeft = _endTime!.difference(DateTime.now()).inMilliseconds;
    if (millisLeft <= 0) {
      _ticker?.cancel();
      remaining = Duration.zero;
      status = PomodoroStatus.finished;
      _endTime = null;

      await _clearPersistence();
      await _cancelNotificationSafely();
      await _showFinishedNotificationSafely();
      notifyListeners();
      return;
    }

    remaining = Duration(seconds: (millisLeft / 1000).ceil());
    notifyListeners();
  }

  Future<void> _persistState() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyTotalDuration, totalDuration.inMilliseconds);
    await prefs.setInt(_keyRemaining, remaining.inMilliseconds);
    await prefs.setInt(_keyStatus, status.index);
    if (_endTime != null) {
      await prefs.setInt(_keyEndTime, _endTime!.millisecondsSinceEpoch);
    } else {
      await prefs.remove(_keyEndTime);
    }
  }

  Future<void> _clearPersistence() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyEndTime);
    await prefs.remove(_keyTotalDuration);
    await prefs.remove(_keyRemaining);
    await prefs.remove(_keyStatus);
  }

  Future<void> _restoreState() async {
    final prefs = await SharedPreferences.getInstance();
    final savedStatusIndex = prefs.getInt(_keyStatus);
    final savedTotalMs = prefs.getInt(_keyTotalDuration);
    final savedEndMs = prefs.getInt(_keyEndTime);
    final savedRemainingMs = prefs.getInt(_keyRemaining);

    if (savedStatusIndex == null || savedTotalMs == null) {
      return;
    }

    totalDuration = Duration(milliseconds: savedTotalMs);

    if (savedEndMs != null && savedStatusIndex == PomodoroStatus.running.index) {
      _endTime = DateTime.fromMillisecondsSinceEpoch(savedEndMs);
      final now = DateTime.now();
      final millisLeft = _endTime!.difference(now).inMilliseconds;

      if (millisLeft <= 0) {
        remaining = Duration.zero;
        status = PomodoroStatus.finished;
        _endTime = null;
        await _clearPersistence();
        await _showFinishedNotificationSafely();
      } else {
        remaining = Duration(seconds: (millisLeft / 1000).ceil());
        status = PomodoroStatus.running;
        _startTicker();
        await _scheduleSystemNotification();
      }
    } else if (savedStatusIndex == PomodoroStatus.paused.index &&
        savedRemainingMs != null) {
      remaining = Duration(milliseconds: savedRemainingMs);
      status = PomodoroStatus.paused;
    } else if (savedStatusIndex == PomodoroStatus.finished.index) {
      remaining = Duration.zero;
      status = PomodoroStatus.finished;
    }

    notifyListeners();
  }

  Future<void> _refreshFromPersistence() async {
    if (status != PomodoroStatus.running || _endTime == null) return;

    final now = DateTime.now();
    final millisLeft = _endTime!.difference(now).inMilliseconds;

    if (millisLeft <= 0) {
      _ticker?.cancel();
      remaining = Duration.zero;
      status = PomodoroStatus.finished;
      _endTime = null;
      await _clearPersistence();
      await _cancelNotificationSafely();
      await _showFinishedNotificationSafely();
      notifyListeners();
    } else {
      remaining = Duration(seconds: (millisLeft / 1000).ceil());
      notifyListeners();
    }
  }

  Future<void> _scheduleSystemNotification() async {
    if (_endTime == null) return;
    try {
      await NotificationService.schedulePomodoroNotification(_endTime!);
    } catch (error) {
      debugPrint('[POMO] No se pudo programar notificación: $error');
    }
  }

  Future<void> _cancelNotificationSafely() async {
    try {
      await NotificationService.cancelPomodoroNotification();
    } catch (error) {
      debugPrint('[POMO] No se pudo cancelar notificación: $error');
    }
  }

  Future<void> _showFinishedNotificationSafely() async {
    try {
      await NotificationService.showPomodoroFinishedNotification();
    } catch (error) {
      debugPrint('[POMO] No se pudo mostrar notificación final: $error');
    }
  }
}
