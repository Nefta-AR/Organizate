import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Catálogo de tipos de actividad reconocidos por el sistema de auditoría.
///
/// Usar constantes en lugar de strings libres evita errores tipográficos
/// y facilita búsquedas en Firestore con índices compuestos en el futuro.
class ActivityType {
  static const taskCompleted     = 'task_completed';
  static const taskCreated       = 'task_created';
  static const taskDeleted       = 'task_deleted';
  static const pictogramCreated  = 'pictogram_created';
  static const pictogramDeleted  = 'pictogram_deleted';
  static const pictogramUsed     = 'pictogram_used';  // El usuario activó TTS de un pictograma
  static const pomodoroCompleted = 'pomodoro_completed';
}

/// Servicio de auditoría que registra eventos de uso en Firestore.
///
/// El log se almacena en `users/{userId}/activityLog` y es consultado
/// por el tutor en tiempo real desde [_TutorHistorialTab].
///
/// Diseño deliberado: [log] atrapa todas las excepciones silenciosamente
/// porque un fallo de logging no debe interrumpir el flujo del usuario.
/// Si la escritura falla (red, permisos), la actividad simplemente no queda
/// registrada — aceptable dado que el log es de supervisión, no de negocio.
class ActivityLogService {
  ActivityLogService._();

  static final _firestore = FirebaseFirestore.instance;
  static final _auth      = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> _logRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('activityLog');

  /// Escribe una entrada de log para [userId] (o el usuario actual si es null).
  ///
  /// [metadata] es un mapa libre para datos específicos del evento,
  /// por ejemplo `{'minutes': 25}` para un Pomodoro completado.
  static Future<void> log({
    String? userId,
    required String type,
    required String description,
    Map<String, dynamic>? metadata,
  }) async {
    final uid = userId ?? _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      await _logRef(uid).add({
        'type':        type,
        'description': description,
        'timestamp':   FieldValue.serverTimestamp(),
        if (metadata != null) 'metadata': metadata,
      });
    } catch (_) {
      // Fallo silencioso intencional: el log es observacional, no crítico.
    }
  }

  /// Stream de las últimas 100 entradas del log, ordenadas por recencia.
  ///
  /// El límite de 100 evita leer el historial completo en cada snapshot
  /// cuando el log crece con el uso prolongado de la app.
  static Stream<List<Map<String, dynamic>>> getStream(String userId) {
    return _logRef(userId)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .snapshots()
        .map((s) => s.docs
            .map((d) => {'id': d.id, ...d.data()})
            .toList());
  }
}
