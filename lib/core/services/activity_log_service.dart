import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ActivityType {
  static const taskCompleted = 'task_completed';
  static const taskCreated = 'task_created';
  static const taskDeleted = 'task_deleted';
  static const pictogramCreated = 'pictogram_created';
  static const pictogramDeleted = 'pictogram_deleted';
}

class ActivityLogService {
  ActivityLogService._();

  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  static CollectionReference<Map<String, dynamic>> _logRef(String userId) =>
      _firestore.collection('users').doc(userId).collection('activityLog');

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
        'type': type,
        'description': description,
        'timestamp': FieldValue.serverTimestamp(),
        if (metadata != null) 'metadata': metadata,
      });
    } catch (_) {}
  }

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
