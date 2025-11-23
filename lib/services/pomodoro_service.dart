import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:organizate/services/notification_service.dart';

enum PomodoroStatus { idle, running, paused, finished }

class PomodoroService extends ChangeNotifier {
  Duration totalDuration = Duration.zero;
  Duration remaining = Duration.zero;
  PomodoroStatus status = PomodoroStatus.idle;

  Timer? _ticker;
  DateTime? _endTime;

  Future<void> start(Duration duration) async {
    _ticker?.cancel();
    _ticker = null;
    _endTime = null;
    unawaited(_cancelNotificationSafely());
    totalDuration = duration;
    remaining = duration;
    status = PomodoroStatus.running;
    _endTime = DateTime.now().add(duration);
    _startTicker();
    notifyListeners();
    unawaited(_scheduleSystemNotification());
  }

  Future<void> pause() async {
    if (status != PomodoroStatus.running) return;
    _ticker?.cancel();
    final millisLeft = _endTime?.difference(DateTime.now()).inMilliseconds ??
        remaining.inMilliseconds;
    final secondsLeft = (millisLeft / 1000).ceil();
    remaining = Duration(seconds: secondsLeft < 0 ? 0 : secondsLeft);
    status = PomodoroStatus.paused;
    _endTime = null;
    await _cancelNotificationSafely();
    notifyListeners();
  }

  Future<void> resume() async {
    if (status != PomodoroStatus.paused) return;
    _endTime = DateTime.now().add(remaining);
    status = PomodoroStatus.running;
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
      await _cancelNotificationSafely();
      await _showFinishedNotificationSafely();
      notifyListeners();
      return;
    }
    // Use ceil to avoid skipping seconds when the tick fires slightly late.
    final secondsLeft = (millisLeft / 1000).ceil();
    remaining = Duration(seconds: secondsLeft);
    notifyListeners();
  }

  Future<void> _scheduleSystemNotification() async {
    if (_endTime == null) return;
    try {
      await NotificationService.schedulePomodoroNotification(_endTime!);
    } catch (error, stack) {
      debugPrint('[POMO] No se pudo programar notificación: $error');
      debugPrint('$stack');
    }
  }

  Future<void> _cancelNotificationSafely() async {
    try {
      await NotificationService.cancelPomodoroNotification();
    } catch (error, stack) {
      debugPrint('[POMO] No se pudo cancelar notificación: $error');
      debugPrint('$stack');
    }
  }

  Future<void> _showFinishedNotificationSafely() async {
    try {
      await NotificationService.showPomodoroFinishedNotification();
    } catch (error, stack) {
      debugPrint('[POMO] No se pudo mostrar notificación final: $error');
      debugPrint('$stack');
    }
  }
}
