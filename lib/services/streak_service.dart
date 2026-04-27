import 'package:cloud_firestore/cloud_firestore.dart';

/// Servicio pequeño que encapsula la lógica de la racha para mantenerla
/// centralizada y fácil de consumir desde cualquier pantalla.
class StreakService {
  /// Constructor privado porque solo usamos miembros estáticos.
  const StreakService._();

  /// Se llama justo después de que el usuario marque una tarea como hecha.
  ///
  /// Hace una transacción para:
  /// 1. Leer la racha actual y la última fecha guardada.
  /// 2. Calcular la nueva racha usando solo fechas (sin horas).
  /// 3. Guardar streak y lastStreakDate de forma atómica.
  static Future<void> updateStreakOnTaskCompletion(
    DocumentReference<Map<String, dynamic>> userDocRef,
  ) async {
    // Tomamos la fecha de hoy sin hora para comparar solo días.
    final today = _stripTime(DateTime.now());
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      // Paso 1: leemos el documento actual dentro de la transacción.
      final snapshot = await transaction.get(userDocRef);
      final data = snapshot.data() ?? <String, dynamic>{};
      final int currentStreak = (data['streak'] as num?)?.toInt() ?? 0;
      final Timestamp? lastTs = data['lastStreakDate'] as Timestamp?;
      // Normalizamos la fecha anterior para ignorar la hora.
      DateTime? lastDate;
      if (lastTs != null) {
        final date = lastTs.toDate();
        lastDate = _stripTime(date);
      }

      // Paso 2: calculamos la racha nueva según la fecha previa.
      final int newStreak = _computeNewStreak(
        currentStreak: currentStreak,
        today: today,
        lastDate: lastDate,
      );

      // Paso 3: guardamos streak y la fecha de hoy en el doc del usuario.
      transaction.set(
        userDocRef,
        {
          'streak': newStreak,
          'lastStreakDate': Timestamp.fromDate(today),
        },
        SetOptions(merge: true),
      );
    });
  }

  /// Dada la racha actual y la fecha anterior devuelve el valor que toca.
  static int _computeNewStreak({
    required int currentStreak,
    required DateTime today,
    DateTime? lastDate,
  }) {
    // Si nunca hubo fecha, empezamos con 1 porque es la primera tarea hecha.
    if (lastDate == null) {
      return 1;
    }
    // Diferencia en días enteros para saber si es consecutivo.
    final diffDays = today.difference(lastDate).inDays;
    // Si ya se registró algo hoy, la racha se mantiene igual.
    if (diffDays == 0) {
      return currentStreak;
    }
    // Si ayer fue el último registro, sumamos 1 a la racha.
    if (diffDays == 1) {
      return currentStreak + 1;
    }
    // Cualquier otra diferencia implica reiniciar la cadena.
    return 1;
  }

  /// Convierte un DateTime en solo fecha (año/mes/día).
  static DateTime _stripTime(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
