// ============================================================
// lib/features/tda_focus/services/streak_service.dart
// ============================================================
// Servicio de cálculo y actualización de la racha diaria (streak).
//
// La racha mide cuántos días consecutivos el usuario completó al menos
// una tarea. No cuenta el número de tareas, solo si hubo actividad ese día.
//
// Reglas de la racha:
//   - diffDays == 0: misma racha (ya completó una tarea hoy)
//   - diffDays == 1: racha aumenta en 1 (completó tarea ayer y hoy)
//   - diffDays > 1:  racha se reinicia a 1 (rompió la cadena)
//
// Usa Firestore Transaction para garantizar que la lectura del valor
// actual y la escritura del nuevo valor sean atómicas. Esto evita
// condiciones de carrera si el usuario completa dos tareas simultáneamente
// desde dos dispositivos.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';

class StreakService {
  // Constructor privado: clase puramente estática, no instanciar.
  const StreakService._();

  /// Actualiza la racha del usuario al completar una tarea.
  ///
  /// Lee el streak actual y lastStreakDate en la misma transacción,
  /// calcula el nuevo valor y escribe ambos campos atómicamente.
  static Future<void> updateStreakOnTaskCompletion(
    DocumentReference<Map<String, dynamic>> userDocRef,
  ) async {
    // Normaliza a medianoche para comparar solo días, no timestamps exactos.
    final today = _stripTime(DateTime.now());
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      // Lee el documento dentro de la transacción para garantizar atomicidad.
      final snapshot = await transaction.get(userDocRef);
      final data = snapshot.data() ?? <String, dynamic>{};
      final int currentStreak = (data['streak'] as num?)?.toInt() ?? 0;
      final Timestamp? lastTs = data['lastStreakDate'] as Timestamp?;

      // Normaliza la última fecha a medianoche para comparación de días.
      DateTime? lastDate;
      if (lastTs != null) {
        lastDate = _stripTime(lastTs.toDate());
      }

      final int newStreak = _computeNewStreak(
        currentStreak: currentStreak,
        today: today,
        lastDate: lastDate,
      );

      // Escribe solo streak y lastStreakDate; no toca los demás campos.
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

  /// Lógica pura de cálculo de racha (sin efectos secundarios, fácil de testear).
  ///
  /// - lastDate == null: primera vez → racha 1
  /// - diffDays == 0:    ya actualizó hoy → mantiene la racha actual
  /// - diffDays == 1:    día siguiente → incrementa
  /// - diffDays > 1:    hubo días sin actividad → reinicia a 1
  static int _computeNewStreak({
    required int currentStreak,
    required DateTime today,
    DateTime? lastDate,
  }) {
    if (lastDate == null) return 1;
    final diffDays = today.difference(lastDate).inDays;
    if (diffDays == 0) return currentStreak;  // Ya completó una tarea hoy
    if (diffDays == 1) return currentStreak + 1; // Día consecutivo
    return 1; // Rompió la cadena
  }

  /// Normaliza una fecha a medianoche (00:00:00) para comparar solo días.
  /// Ignora la hora, minuto y segundo para que dos timestamps del mismo
  /// día tengan diffDays == 0.
  static DateTime _stripTime(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
