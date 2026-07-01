// ============================================================
// lib/features/tda_focus/services/pomodoro_service.dart
// ============================================================
// Servicio de estado global del temporizador Pomodoro.
//
// Patrón: ChangeNotifier inyectado via MultiProvider en main.dart.
// Cualquier widget puede escucharlo con context.watch<PomodoroService>()
// o context.read<PomodoroService>() para acceder sin reconstruir.
// ============================================================

import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/notification_service.dart';

/// Estados posibles del timer Pomodoro.
enum PomodoroStatus {
  idle,     // Sin timer activo
  running,  // Timer en curso
  paused,   // Timer pausado (remaining guardado en memoria y SharedPreferences)
  finished, // Timer llegó a cero (el listener en FocoScreen lo detecta)
}

/// ChangeNotifier que gestiona el ciclo de vida completo de un temporizador
/// Pomodoro, incluyendo persistencia entre sesiones y notificaciones.
///
/// ## Diseño del temporizador
///
/// En lugar de decrementar un contador en cada tick (enfoque naïve),
/// el servicio persiste la marca de tiempo de finalización (`_endTime`)
/// y calcula el tiempo restante como `_endTime - now()` en cada tick.
/// Esto garantiza precisión aunque el hilo de UI se congele brevemente.
///
/// ## Persistencia entre reinicios de la app
///
/// [_persistState] guarda el estado en SharedPreferences. Al abrir la app,
/// [_restoreState] lee ese estado y:
///   - Si el timer habría terminado mientras la app estaba cerrada, muestra
///     la notificación de finalización y actualiza el estado a `finished`.
///   - Si todavía tiene tiempo, reanuda el ticker desde el punto correcto.
///
/// ## Notificaciones
///
/// Se programa una notificación del sistema para la hora de finalización.
/// Esto permite que el usuario reciba el aviso aunque minimice la app.
/// La notificación se cancela si el usuario pausa o cancela el timer.
class PomodoroService extends ChangeNotifier with WidgetsBindingObserver {
  Duration totalDuration = Duration.zero;
  Duration remaining     = Duration.zero;
  PomodoroStatus status  = PomodoroStatus.idle;

  Timer?    _ticker;
  DateTime? _endTime;

  // Claves de SharedPreferences (prefijo 'pomodoro_' para evitar colisiones)
  static const _keyEndTime       = 'pomodoro_end_time_ms';
  static const _keyTotalDuration = 'pomodoro_total_duration_ms';
  static const _keyRemaining     = 'pomodoro_remaining_ms';
  static const _keyStatus        = 'pomodoro_status';

  PomodoroService() {
    // WidgetsBindingObserver para detectar cuando la app vuelve a primer plano
    // y recalcular el tiempo restante desde la persistencia.
    WidgetsBinding.instance.addObserver(this);
    _restoreState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  /// Se dispara cuando la app regresa a primer plano (AppLifecycleState.resumed).
  /// Recalcula `remaining` desde `_endTime` para corregir cualquier drift
  /// acumulado mientras la app estuvo en background.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshFromPersistence();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // CONTROLES PÚBLICOS
  // ─────────────────────────────────────────────────────────────

  /// Inicia el timer. Cancela cualquier sesión en curso antes de comenzar.
  Future<void> start(Duration duration) async {
    _ticker?.cancel();
    _ticker  = null;
    _endTime = null;
    await _cancelNotificationSafely();

    totalDuration = duration;
    remaining     = duration;
    status        = PomodoroStatus.running;
    _endTime      = DateTime.now().add(duration);

    await _persistState();
    _startTicker();
    await _scheduleSystemNotification();
    notifyListeners();
  }

  Future<void> pause() async {
    if (status != PomodoroStatus.running) return;
    _ticker?.cancel();

    // Usar `_endTime - now` en lugar de `remaining` para evitar que el
    // último segundo del tick quede inconsistente con el tiempo real.
    final millisLeft =
        _endTime?.difference(DateTime.now()).inMilliseconds ??
            remaining.inMilliseconds;
    final secondsLeft = (millisLeft / 1000).ceil();
    remaining = Duration(seconds: secondsLeft < 0 ? 0 : secondsLeft);

    status   = PomodoroStatus.paused;
    _endTime = null; // Sin endTime → no hay notificación activa

    await _persistState();
    await _cancelNotificationSafely();
    notifyListeners();
  }

  Future<void> resume() async {
    if (status != PomodoroStatus.paused) return;

    status   = PomodoroStatus.running;
    _endTime = DateTime.now().add(remaining);

    await _persistState();
    await _scheduleSystemNotification();
    _startTicker();
    notifyListeners();
  }

  Future<void> cancel() async {
    _ticker?.cancel();
    _ticker       = null;
    _endTime      = null;
    remaining     = Duration.zero;
    totalDuration = Duration.zero;
    status        = PomodoroStatus.idle;

    await _clearPersistence();
    await _cancelNotificationSafely();
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────
  // TICKER INTERNO
  // ─────────────────────────────────────────────────────────────

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
      status    = PomodoroStatus.finished;
      _endTime  = null;

      await _clearPersistence();
      await _cancelNotificationSafely();
      await _showFinishedNotificationSafely();
      notifyListeners();
      return;
    }

    // `ceil` en lugar de `floor` para que el display muestre "1s" en vez
    // de "0s" cuando quedan menos de 1000ms.
    remaining = Duration(seconds: (millisLeft / 1000).ceil());
    notifyListeners();
  }

  // ─────────────────────────────────────────────────────────────
  // PERSISTENCIA
  // ─────────────────────────────────────────────────────────────

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

  /// Restaura el estado al arrancar la app.
  ///
  /// Casos posibles:
  ///   - **running + endTime en el pasado**: el timer terminó en background →
  ///     marcar como `finished` y mostrar notificación.
  ///   - **running + endTime en el futuro**: reanudar desde el tiempo correcto.
  ///   - **paused**: restaurar `remaining` sin `endTime`.
  ///   - **finished**: mantener estado para que la UI muestre el resultado.
  Future<void> _restoreState() async {
    final prefs             = await SharedPreferences.getInstance();
    final savedStatusIndex  = prefs.getInt(_keyStatus);
    final savedTotalMs      = prefs.getInt(_keyTotalDuration);
    final savedEndMs        = prefs.getInt(_keyEndTime);
    final savedRemainingMs  = prefs.getInt(_keyRemaining);

    if (savedStatusIndex == null || savedTotalMs == null) return;

    totalDuration = Duration(milliseconds: savedTotalMs);

    if (savedEndMs != null && savedStatusIndex == PomodoroStatus.running.index) {
      _endTime = DateTime.fromMillisecondsSinceEpoch(savedEndMs);
      final now       = DateTime.now();
      final millisLeft = _endTime!.difference(now).inMilliseconds;

      if (millisLeft <= 0) {
        // El timer habría terminado mientras la app estaba cerrada
        remaining = Duration.zero;
        status    = PomodoroStatus.finished;
        _endTime  = null;
        await _clearPersistence();
        await _showFinishedNotificationSafely();
      } else {
        remaining = Duration(seconds: (millisLeft / 1000).ceil());
        status    = PomodoroStatus.running;
        _startTicker();
        await _scheduleSystemNotification();
      }
    } else if (savedStatusIndex == PomodoroStatus.paused.index &&
        savedRemainingMs != null) {
      remaining = Duration(milliseconds: savedRemainingMs);
      status    = PomodoroStatus.paused;
    } else if (savedStatusIndex == PomodoroStatus.finished.index) {
      remaining = Duration.zero;
      status    = PomodoroStatus.finished;
    }

    notifyListeners();
  }

  Future<void> _refreshFromPersistence() async {
    if (status != PomodoroStatus.running || _endTime == null) return;

    final now        = DateTime.now();
    final millisLeft = _endTime!.difference(now).inMilliseconds;

    if (millisLeft <= 0) {
      _ticker?.cancel();
      remaining = Duration.zero;
      status    = PomodoroStatus.finished;
      _endTime  = null;
      await _clearPersistence();
      await _cancelNotificationSafely();
      await _showFinishedNotificationSafely();
      notifyListeners();
    } else {
      remaining = Duration(seconds: (millisLeft / 1000).ceil());
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────────────────────────
  // NOTIFICACIONES (fallos silenciosos para no interrumpir el timer)
  // ─────────────────────────────────────────────────────────────

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
