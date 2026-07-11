// ============================================================
// lib/core/services/notification_service.dart
// ============================================================
// Servicio de notificaciones locales via flutter_local_notifications.
//
// ## Canal de Android
//
//   ID: 'tareas_channel', importancia MAX, sonido y vibración.
//   Se crea en [init] con permisos de alarma exacta para Android 12+.
//
// ## Funciones principales
//
//   [init]: inicializa el plugin, crea el canal Android y configura
//     la timezone local via flutter_native_timezone (fallback a UTC si falla).
//
//   [scheduleReminderIfNeeded]: programa una alarma zonedSchedule
//     para (dueDate − reminderMinutes). Si no hay permiso de alarma exacta
//     (Android 12+), programa un alarm inexacto (setAndAllowWhileIdle).
//
//   [cancelTaskNotification]: cancela por ID = taskId.hashCode & 0x7FFFFFFF.
//     El masking garantiza que el ID sea siempre positivo en 32 bits,
//     ya que hashCode puede ser negativo en Dart.
//
//   [schedulePomodoroNotification]: ID fijo 7777, al terminar el timer Pomodoro.
//
//   [showTestNotification]: retorna NotificationTestResult con diagnóstico
//     detallado (permisos, canal activo, alarma exacta, reproducción de sonido).
//
//   [showInstantNotification]: muestra una notificación inmediata
//     (usada por PushNotificationService en foreground para emular FCM).
// ============================================================

import 'dart:io';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_native_timezone/flutter_native_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../utils/reminder_options.dart';

class NotificationService {
  // Constructor privado: esta clase no se instancia; todos sus métodos son estáticos.
  // El patrón "clase de métodos estáticos" es equivalente a un singleton pero
  // sin necesidad de guardar referencia al objeto.
  NotificationService._();

  // Instancia global del plugin de notificaciones locales.
  // Se comparte entre todos los métodos estáticos.
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  // Guard para evitar doble inicialización si init() se llama más de una vez.
  static bool _initialized = false;

  // Guard separado para la inicialización de timezone (puede ser lento).
  static bool _tzInitialized = false;

  // ID fijo para la notificación del Pomodoro.
  // Al usar siempre el mismo ID, cancelar y volver a programar reemplaza
  // la notificación anterior sin acumular múltiples entradas.
  static const int _pomodoroNotificationId = 7777;

  // Definición del canal de Android de alta importancia.
  // En Android 8+, todas las notificaciones deben pertenecer a un canal.
  // importance.max → el sistema nunca silencia ni filtra estas notificaciones.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'tareas_channel',                          // ID del canal (único en la app)
    'Recordatorios Simple',                    // Nombre visible en Ajustes del SO
    description:
        'Notificaciones de tareas y Pomodoro de la app Simple',
    importance: Importance.max,  // Máxima importancia: aparece en pantalla bloqueada
    playSound: true,
    enableVibration: true,
  );

  // ── Solicitar todos los permisos necesarios en bloque ─────────────────────────

  // Método proactivo que llama al usuario a conceder permisos esenciales.
  // Se llama desde SettingsScreen sección "Notificaciones".
  // Captura excepciones individualmente para que un permiso denegado
  // no bloquee los demás.
  static Future<void> ensureDeviceCanDeliverNotifications() async {
    if (kIsWeb) return; // Web no soporta notificaciones locales
    if (!Platform.isAndroid) return; // Solo Android necesita este flujo manual

    // 1. Permiso de notificaciones (obligatorio desde Android 13)
    try {
      if (!await Permission.notification.isGranted) {
        final status = await Permission.notification.request();
        // Si denegó permanentemente, abrimos la pantalla de ajustes del SO
        if (!status.isGranted) await openAppSettings();
      }
    } catch (_) {} // Silenciamos errores del OS (ej. dispositivos muy viejos)

    // 2. Permiso de ignorar optimización de batería.
    // Sin este permiso, las alarmas programadas pueden fallar en modo Doze.
    try {
      const ignoreBattery = Permission.ignoreBatteryOptimizations;
      final status = await ignoreBattery.status;
      if (!status.isGranted) {
        final req = await ignoreBattery.request();
        if (!req.isGranted) await openAppSettings();
      }
    } catch (_) {}

    // 3. Permiso de alarma exacta (SCHEDULE_EXACT_ALARM en Android 12+).
    // Necesario para que las notificaciones lleguen justo a la hora programada.
    try {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestExactAlarmsPermission();
    } catch (_) {}
  }

  // ── Inicialización del plugin ─────────────────────────────────────────────────

  static Future<void> init() async {
    if (_initialized) return; // Evita doble inicialización

    // En web no hay notificaciones locales; marcamos como inicializado para
    // que el resto de métodos no fallen con "not initialized"
    if (kIsWeb) {
      _initialized = true;
      return;
    }

    // Configuración de inicio para cada plataforma:
    // - Android: usar el ícono de la app (@mipmap/ic_launcher) en la barra de estado
    // - iOS: usa configuración por defecto (solicita permisos on-demand)
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings();
    const settings = InitializationSettings(android: androidInit, iOS: darwinInit);

    // Inicializa el plugin y registra el callback que se llama al tocar la notificación
    await _plugin.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    // Accedemos a la implementación específica de Android para operaciones avanzadas
    final androidImpl = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    // Creamos el canal de notificaciones (obligatorio Android 8+).
    // Si ya existe, el SO ignora la creación sin lanzar error.
    await androidImpl?.createNotificationChannel(_channel);

    // Solicitamos permiso de notificaciones (Android 13+)
    await androidImpl?.requestNotificationsPermission();

    // Solicitamos alarma exacta (Android 12+, opcional pero deseable)
    await androidImpl?.requestExactAlarmsPermission();

    // Solicitamos ignorar optimización de batería para alarmas confiables
    await _tryRequestIgnoreBatteryOptimizations();

    // Configuramos la zona horaria local para zonedSchedule
    await _configureLocalTimezone();

    _initialized = true;
  }

  // ── Solicitar permisos individuales ──────────────────────────────────────────

  // Retorna true si todos los permisos necesarios fueron concedidos.
  // Se llama desde la pantalla de ajustes para mostrar estado de permisos.
  static Future<bool> requestPermissions() async {
    if (kIsWeb) return true; // Web: no aplica, devolvemos true para no bloquear

    if (Platform.isAndroid) {
      // Permiso básico de notificaciones
      final status = await Permission.notification.request();
      if (!status.isGranted) return false;

      // Alarma exacta: no fallamos si la solicitud falla (es opcional en algunos modelos)
      try {
        await Permission.scheduleExactAlarm.request();
      } catch (_) {}

    } else if (Platform.isIOS) {
      // En iOS basta con el permiso de notificaciones
      final status = await Permission.notification.request();
      if (!status.isGranted) return false;
    }

    return true;
  }

  // ── Detalles por defecto para todas las notificaciones ───────────────────────

  // Construye el objeto NotificationDetails común a todas las notificaciones.
  // - Android: Importance MAX sin pantalla completa forzada
  // - iOS: Alert + Badge + Sound + interrupción de nivel TimeSensitive
  static NotificationDetails _defaultDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        'tareas_channel',    // Debe coincidir con el canal creado en init()
        'Recordatorios Simple',
        channelDescription: 'Notificaciones de tareas y Pomodoro',
        importance: Importance.max,
        priority: Priority.max,
        playSound: true,
        enableVibration: true,
        category: AndroidNotificationCategory.reminder, // reminder no requiere permiso especial de Android 12
        fullScreenIntent: false,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,  // Muestra el banner de alerta
        presentBadge: true,  // Incrementa el badge del icono de la app
        presentSound: true,
        // timeSensitive: interrumpe el modo Focus/DND del iPhone
        interruptionLevel: InterruptionLevel.timeSensitive,
      ),
    );
  }

  // ── Notificación inmediata ────────────────────────────────────────────────────

  // Muestra una notificación de inmediato sin programación futura.
  // Usada por PushNotificationService cuando llega un mensaje FCM en foreground
  // (porque FCM no muestra banner en foreground sin este método).
  static Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload, // Payload opcional para saber qué abrió la notificación
  }) async {
    if (kIsWeb) return;
    if (!_initialized) await init(); // Auto-inicialización si es necesario

    if (!await _arePermissionsGranted()) return; // Guard de permisos

    // ID único basado en el timestamp (segundos) para evitar colisiones
    final int notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _plugin.show(notificationId, title, body, _defaultDetails(),
        payload: payload);
  }

  // ── Notificación de prueba ────────────────────────────────────────────────────

  // Muestra una notificación ID 9999 como prueba de funcionamiento.
  // Retorna un NotificationTestResult con diagnóstico detallado del sistema.
  // Se usa desde SettingsScreen para que el usuario verifique que todo funciona.
  static Future<NotificationTestResult> showTestNotification(
      {bool playPreviewSound = false}) async {
    // Verificamos permisos antes de intentar mostrar la notificación
    if (!await _arePermissionsGranted()) {
      return const NotificationTestResult(
        notificationSent: false,
        previewSoundPlayed: false,
        failure: NotificationTestFailure.permissionDenied,
        errorDescription: 'Permiso de notificaciones denegado',
      );
    }

    bool notificationSent = false;
    String? errorDescription;

    try {
      // ID 9999 reservado para pruebas: no colisiona con tareas reales
      await _plugin.show(
        9999,
        'Prueba de notificación',
        'Si ves esto, las notificaciones están funcionando.',
        _defaultDetails(),
      );
      notificationSent = true;
    } catch (error) {
      errorDescription = error.toString(); // Capturamos el error para diagnóstico
    }

    // Si se solicitó reproducción de sonido de prueba, lo reproducimos
    final bool previewSoundPlayed =
        playPreviewSound ? await _playTestSoundPreview() : false;

    return NotificationTestResult(
      notificationSent: notificationSent,
      previewSoundPlayed: previewSoundPlayed,
      failure: notificationSent ? null : NotificationTestFailure.unknown,
      errorDescription: errorDescription,
      usedFallbackSound: false, // Sin fallback en esta versión
    );
  }

  // ── Notificaciones del Pomodoro ───────────────────────────────────────────────

  // Muestra la notificación de fin de Pomodoro inmediatamente.
  // Se llama cuando el temporizador expira y el usuario tiene la app en foreground.
  static Future<void> showPomodoroFinishedNotification() async {
    if (kIsWeb) return;
    if (!await _arePermissionsGranted()) return;

    // ID fijo _pomodoroNotificationId (7777): siempre reemplaza la anterior
    await _plugin.show(
      _pomodoroNotificationId,
      'Pomodoro terminado',
      'Buen trabajo, tómate un descanso 😌',
      _defaultDetails(),
    );
  }

  // Programa la notificación del Pomodoro para una hora futura.
  // Si el Pomodoro se pausó, se debe cancelar primero y reprogramar.
  static Future<void> schedulePomodoroNotification(DateTime endTime) async {
    if (kIsWeb) return;

    // Verificamos permisos: primero exactos, luego básicos como fallback
    final hasExactPermission = await _arePermissionsGranted(exact: true);
    final hasBasicPermission =
        hasExactPermission || await _arePermissionsGranted();
    if (!hasBasicPermission) return; // Sin ningún permiso, no podemos programar

    // Convertimos DateTime a TZDateTime con la zona horaria local del dispositivo
    final tzDateTime = tz.TZDateTime.from(endTime, tz.local);

    await _plugin.zonedSchedule(
      _pomodoroNotificationId,
      'Pomodoro terminado',
      'Buen trabajo, tómate un descanso 😌',
      tzDateTime,
      _defaultDetails(),
      // exactAllowWhileIdle: alarma exacta incluso si el dispositivo está en Doze
      // inexactAllowWhileIdle: fallback cuando no hay permiso de alarma exacta
      androidScheduleMode: hasExactPermission
          ? AndroidScheduleMode.exactAllowWhileIdle
          : AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'pomodoro', // Identifica la notificación en _onNotificationResponse
    );
  }

  // Cancela la notificación del Pomodoro (ej: cuando el usuario pausa o reinicia).
  static Future<void> cancelPomodoroNotification() async {
    if (kIsWeb) return;
    await _plugin.cancel(_pomodoroNotificationId);
  }

  // ── Recordatorio de tarea ─────────────────────────────────────────────────────

  // Programa un recordatorio local para una tarea específica.
  //
  // La hora de disparo es: dueDate − reminderMinutes.
  // Ejemplo: si dueDate = 15:00 y reminderMinutes = 30 → alarma a las 14:30.
  //
  // [userDocRef]: referencia al doc del usuario (actualmente no se usa en la
  //   lógica local, pero se pasa para futuras extensiones remotas).
  // [taskId]: ID de Firestore de la tarea. Se convierte a notificationId
  //   usando hashCode & 0x7FFFFFFF para garantizar un int32 positivo.
  static Future<void> scheduleReminderIfNeeded({
    required DocumentReference<Map<String, dynamic>> userDocRef,
    required String taskId,
    required String taskTitle,
    DateTime? dueDate,
    int? reminderMinutes,
  }) async {
    if (kIsWeb) return;

    // Guard: si no hay fecha o minutos de recordatorio, no hay nada que programar
    if (dueDate == null || reminderMinutes == null) return;

    // Verificamos permisos
    final hasExactPermission = await _arePermissionsGranted(exact: true);
    final hasBasicPermission =
        hasExactPermission || await _arePermissionsGranted();
    if (!hasBasicPermission) return;

    // Aplicamos mínimo de minutos para evitar recordatorios demasiado cercanos
    // kMinimumReminderMinutes está definido en reminder_options.dart
    final int safeMinutes = reminderMinutes < kMinimumReminderMinutes
        ? kMinimumReminderMinutes
        : reminderMinutes;

    // Calculamos la hora de disparo: antes del vencimiento
    DateTime scheduledDateTime =
        dueDate.subtract(Duration(minutes: safeMinutes));

    final DateTime now = DateTime.now();

    // Si la hora calculada ya pasó (o es en menos de 5 segundos),
    // la reemplazamos por "5 segundos desde ahora" para que el usuario vea algo
    if (scheduledDateTime.isBefore(now.add(const Duration(seconds: 5)))) {
      scheduledDateTime = now.add(const Duration(seconds: 5));
    }

    // Convertimos el String taskId a un int32 positivo para usarlo como ID.
    // & 0x7FFFFFFF pone el bit de signo a 0, garantizando un valor positivo.
    final int notificationId = taskId.hashCode & 0x7fffffff;

    try {
      // Convertimos a TZDateTime para usar la zona horaria local del dispositivo
      final tzDateTime = tz.TZDateTime.from(scheduledDateTime, tz.local);

      await _plugin.zonedSchedule(
        notificationId,
        'Recordatorio: $taskTitle',
        'Tarea programada para ${dueDate.toLocal()}',
        tzDateTime,
        _defaultDetails(),
        androidScheduleMode: hasExactPermission
            ? AndroidScheduleMode.exactAllowWhileIdle  // Exacto si hay permiso
            : AndroidScheduleMode.inexactAllowWhileIdle, // Inexacto como fallback
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: taskId, // Payload = ID de Firestore para navegar al abrir la notif
      );
    } catch (error) {
      // No relanzamos: si falla la programación, la tarea sigue funcionando
      debugPrint('[NOTI] Error al programar recordatorio: $error');
    }
  }

  // ── Cancelar recordatorio de tarea ────────────────────────────────────────────

  // Cancela el recordatorio de una tarea por su ID de Firestore.
  // Se llama cuando la tarea se marca como hecha, se edita o se elimina.
  static Future<void> cancelTaskNotification(String taskId) async {
    if (kIsWeb) return;

    // Reproducimos la misma operación de hashing para obtener el mismo ID
    final int notificationId = taskId.hashCode & 0x7fffffff;
    await _plugin.cancel(notificationId);
  }

  // ── Reproducción de sonido de prueba ─────────────────────────────────────────

  // Reproduce el sonido de notificación desde los assets para previsualización.
  // Retorna true si se reprodujo correctamente, false si hubo un error.
  static Future<bool> _playTestSoundPreview() async {
    final player = AudioPlayer();
    try {
      // Reproducimos el asset de sonido directamente (sin programar notificación)
      await player.play(AssetSource('sounds/Notificacion1.mp3'));

      // Esperamos a que termine completamente antes de retornar
      await player.onPlayerComplete.first;
      return true;
    } catch (error) {
      debugPrint('[NOTI] Error al reproducir preview: $error');
      return false;
    } finally {
      // Liberamos el player aunque haya fallado (evita memory leak)
      await player.dispose();
    }
  }

  // ── Permisos de batería ───────────────────────────────────────────────────────

  // Solicita el permiso de ignorar optimización de batería.
  // Este permiso es necesario para que las alarmas funcionen en modo Doze.
  // Usamos try/catch porque en algunos ROMs esto no está disponible.
  static Future<void> _tryRequestIgnoreBatteryOptimizations() async {
    if (kIsWeb || !Platform.isAndroid) return;
    try {
      const permission = Permission.ignoreBatteryOptimizations;
      if (!await permission.isGranted) await permission.request();
    } catch (_) {} // Silenciamos si el dispositivo no soporta este permiso
  }

  // ── Verificación de permisos ─────────────────────────────────────────────────

  // Verifica si la app tiene los permisos necesarios para mostrar notificaciones.
  // [exact]: si true, verifica adicionalmente el permiso de alarma exacta.
  static Future<bool> _arePermissionsGranted({bool exact = false}) async {
    if (kIsWeb) return false; // Web: siempre false (no soportado)

    if (Platform.isAndroid) {
      // Primero verificamos el permiso básico de notificaciones
      if (!await Permission.notification.isGranted) return false;

      // Si se pide exacto, verificamos adicionalmente SCHEDULE_EXACT_ALARM
      if (exact) return await _hasExactAlarmPermission();

      return true; // Permiso básico concedido
    }

    if (Platform.isIOS) {
      // En iOS hay un único permiso de notificaciones
      return await Permission.notification.isGranted;
    }

    return false; // Otras plataformas no soportadas
  }

  // Verifica si el dispositivo Android tiene permiso de alarma exacta.
  // En dispositivos anteriores a Android 12 este permiso no existe,
  // por lo que retornamos true en caso de excepción.
  static Future<bool> _hasExactAlarmPermission() async {
    if (!Platform.isAndroid) return false;
    try {
      return await Permission.scheduleExactAlarm.isGranted;
    } catch (_) {
      // En Android < 12 el permiso no existe: asumimos que sí se puede
      return true;
    }
  }

  // ── Configuración de zona horaria ─────────────────────────────────────────────

  // Inicializa la base de datos de zonas horarias y establece la local del dispositivo.
  // Es necesaria para [zonedSchedule] que usa TZDateTime.
  // Fallback a UTC si [FlutterNativeTimezone.getLocalTimezone()] falla.
  static Future<void> _configureLocalTimezone() async {
    if (_tzInitialized) return; // Evita doble inicialización

    try {
      tz.initializeTimeZones(); // Carga todos los datos de zonas horarias

      // Obtenemos el nombre de la zona horaria del dispositivo (ej: "America/Santiago")
      final String timeZone = await FlutterNativeTimezone.getLocalTimezone();

      // Establecemos la zona como local para que TZDateTime.from() use la correcta
      tz.setLocalLocation(tz.getLocation(timeZone));

    } catch (_) {
      // Si el plugin falla (ej: zona desconocida), usamos UTC como fallback seguro
      tz.initializeTimeZones();
      tz.setLocalLocation(tz.getLocation('UTC'));
    }

    _tzInitialized = true;
  }

  // ── Callback de tap en notificación ──────────────────────────────────────────

  // Se llama cuando el usuario toca una notificación.
  // [response.payload] contiene el taskId o 'pomodoro' según la notificación.
  // TODO: navegar a la tarea correspondiente usando el payload.
  static void _onNotificationResponse(NotificationResponse response) {
    debugPrint('[NOTI] Notification tapped with payload=${response.payload}');
  }
}

// ── DTO de resultado de prueba de notificaciones ─────────────────────────────

/// Resultado de [NotificationService.showTestNotification].
/// Permite a SettingsScreen mostrar un diagnóstico detallado al usuario.
class NotificationTestResult {
  /// true si la notificación fue enviada al sistema operativo
  final bool notificationSent;

  /// true si el sonido de previsualización fue reproducido correctamente
  final bool previewSoundPlayed;

  /// Fallo específico que ocurrió (null = sin fallo)
  final NotificationTestFailure? failure;

  /// Descripción técnica del error para logs (null = sin error)
  final String? errorDescription;

  /// true si se usó el sonido de fallback en vez del preferido
  final bool usedFallbackSound;

  const NotificationTestResult({
    required this.notificationSent,
    required this.previewSoundPlayed,
    this.failure,
    this.errorDescription,
    this.usedFallbackSound = false,
  });
}

/// Tipos de fallo posibles en [NotificationTestResult].
enum NotificationTestFailure {
  /// El usuario denegó el permiso de notificaciones
  permissionDenied,

  /// El usuario denegó permanentemente (debe ir a Ajustes del SO)
  permissionPermanentlyDenied,

  /// Error desconocido (ver [NotificationTestResult.errorDescription])
  unknown,
}
