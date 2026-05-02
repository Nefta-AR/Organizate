// lib/services/streak_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class StreakService {
  const StreakService._();

  static Future<void> updateStreakOnTaskCompletion(
    DocumentReference<Map<String, dynamic>> userDocRef,
  ) async {
    final today = _stripTime(DateTime.now());
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(userDocRef);
      final data = snapshot.data() ?? <String, dynamic>{};
      final int currentStreak = (data['streak'] as num?)?.toInt() ?? 0;
      final Timestamp? lastTs = data['lastStreakDate'] as Timestamp?;

      DateTime? lastDate;
      if (lastTs != null) {
        lastDate = _stripTime(lastTs.toDate());
      }

      final int newStreak = _computeNewStreak(
        currentStreak: currentStreak,
        today: today,
        lastDate: lastDate,
      );

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

  static int _computeNewStreak({
    required int currentStreak,
    required DateTime today,
    DateTime? lastDate,
  }) {
    if (lastDate == null) return 1;
    final diffDays = today.difference(lastDate).inDays;
    if (diffDays == 0) return currentStreak;
    if (diffDays == 1) return currentStreak + 1;
    return 1;
  }

  static DateTime _stripTime(DateTime date) =>
      DateTime(date.year, date.month, date.day);
}
