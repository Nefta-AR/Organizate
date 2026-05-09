import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

enum UserRole { tutor, paciente }

class AuthService {
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static const _codesCollection = 'invitationCodes';
  static const _usersCollection = 'users';

  // ─────────────────────────────────────────────────────────────
  // STREAMS
  // ─────────────────────────────────────────────────────────────

  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static User? get currentUser => _auth.currentUser;

  // ─────────────────────────────────────────────────────────────
  // REGISTRO CON ROL
  // ─────────────────────────────────────────────────────────────

  static Future<UserCredential> registerWithEmail({
    required String name,
    required String email,
    required String password,
    required UserRole role,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = cred.user;
    if (user == null) {
      throw Exception('No se pudo crear el usuario.');
    }

    await user.updateDisplayName(name.trim());

    await _firestore.collection(_usersCollection).doc(user.uid).set({
      'name': name.trim(),
      'email': email.trim(),
      'role': role.name,
      'avatar': 'emoticon',
      'points': 0,
      'streak': 0,
      'hasCompletedOnboarding': false,
      'createdAt': FieldValue.serverTimestamp(),
      if (role == UserRole.tutor) ...{
        'linkedPatients': {},
        'invitationCodes': {},
        'kioskModeEnabled': false,
      },
      if (role == UserRole.paciente) ...{
        'linkedTutors': {},
        'acceptedInvitationCode': null,
      },
    });

    return cred;
  }

  // ─────────────────────────────────────────────────────────────
  // LOGIN
  // ─────────────────────────────────────────────────────────────

  static Future<UserCredential> loginWithEmail({
    required String email,
    required String password,
  }) async {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<UserCredential?> loginWithGoogle() async {
    final UserCredential userCred;

    if (kIsWeb) {
      final provider = GoogleAuthProvider()
        ..setCustomParameters({'prompt': 'select_account'});
      userCred = await _auth.signInWithPopup(provider);
    } else {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      userCred = await _auth.signInWithCredential(credential);
    }

    final user = userCred.user;
    if (user == null) return null;

    final isNew = userCred.additionalUserInfo?.isNewUser ?? false;
    if (isNew) {
      await _firestore.collection(_usersCollection).doc(user.uid).set({
        'name': user.displayName ?? 'Usuario de Simple',
        'email': user.email,
        'role': UserRole.paciente.name,
        'avatar': 'emoticon',
        'points': 0,
        'streak': 0,
        'hasCompletedOnboarding': false,
        'createdAt': FieldValue.serverTimestamp(),
        'linkedTutors': {},
        'acceptedInvitationCode': null,
      });
    }

    return userCred;
  }

  // ─────────────────────────────────────────────────────────────
  // GESTIÓN DE ROL
  // ─────────────────────────────────────────────────────────────

  static Future<UserRole?> getUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection(_usersCollection).doc(user.uid).get();
    final roleStr = doc.data()?['role'] as String?;
    if (roleStr == null) return null;

    return roleStr == 'tutor' ? UserRole.tutor : UserRole.paciente;
  }

  static Stream<UserRole?> getUserRoleStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection(_usersCollection)
        .doc(user.uid)
        .snapshots()
        .map((snapshot) {
      final roleStr = snapshot.data()?['role'] as String?;
      if (roleStr == null) return null;
      return roleStr == 'tutor' ? UserRole.tutor : UserRole.paciente;
    });
  }

  static Future<void> setRole(UserRole role) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No hay usuario autenticado.');

    final updates = <String, dynamic>{
      'role': role.name,
    };

    if (role == UserRole.tutor) {
      updates['linkedPatients'] = {};
      updates['invitationCodes'] = {};
      updates['kioskModeEnabled'] = false;
    } else {
      updates['linkedTutors'] = {};
      updates['acceptedInvitationCode'] = null;
    }

    await _firestore.collection(_usersCollection).doc(user.uid).set(
      updates,
      SetOptions(merge: true),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // VINCULACIÓN TUTOR ↔ PACIENTE (Código de invitación)
  // ─────────────────────────────────────────────────────────────

  static Future<String> generateInvitationCode() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No hay usuario autenticado.');

    final role = await getUserRole();
    if (role != UserRole.tutor) {
      throw Exception('Solo los tutores pueden generar códigos de invitación.');
    }

    final code = _generateRandomCode();

    await _firestore.collection(_codesCollection).doc(code).set({
      'code': code,
      'tutorId': user.uid,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'active',
      'usedBy': null,
      'usedAt': null,
      'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
    });

    return code;
  }

  static Future<Map<String, dynamic>?> validateInvitationCode(String code) async {
    final doc = await _firestore.collection(_codesCollection).doc(code.trim().toUpperCase()).get();

    if (!doc.exists) return null;

    final data = doc.data()!;
    final status = data['status'] as String?;
    final expiresAt = data['expiresAt'] as Timestamp?;

    if (status != 'active') {
      return {'valid': false, 'reason': 'Código ya utilizado o desactivado.'};
    }

    if (expiresAt != null && expiresAt.toDate().isBefore(DateTime.now())) {
      return {'valid': false, 'reason': 'Código expirado.'};
    }

    final tutorDoc = await _firestore.collection(_usersCollection).doc(data['tutorId'] as String).get();
    final tutorName = tutorDoc.data()?['name'] as String? ?? 'Tutor';

    return {
      'valid': true,
      'tutorId': data['tutorId'],
      'tutorName': tutorName,
    };
  }

  static Future<void> acceptInvitationCode(String code) async {
    final patient = _auth.currentUser;
    if (patient == null) throw Exception('No hay usuario autenticado.');

    final role = await getUserRole();
    if (role != UserRole.paciente) {
      throw Exception('Solo los pacientes pueden aceptar códigos de invitación.');
    }

    final validation = await validateInvitationCode(code);
    if (validation == null || validation['valid'] != true) {
      throw Exception(validation?['reason'] ?? 'Código inválido.');
    }

    final tutorId = validation['tutorId'] as String;
    final normalizedCode = code.trim().toUpperCase();

    await _firestore.runTransaction((transaction) async {
      final codeRef = _firestore.collection(_codesCollection).doc(normalizedCode);
      final codeDoc = await transaction.get(codeRef);

      if (codeDoc.data()?['status'] != 'active') {
        throw Exception('El código ya fue utilizado por otro paciente.');
      }

      transaction.update(codeRef, {
        'status': 'used',
        'usedBy': patient.uid,
        'usedAt': FieldValue.serverTimestamp(),
      });

      transaction.set(
        _firestore.collection(_usersCollection).doc(patient.uid).collection('linkedTutors').doc(tutorId),
        {
          'tutorId': tutorId,
          'linkedAt': FieldValue.serverTimestamp(),
          'status': 'active',
        },
        SetOptions(merge: true),
      );

      transaction.set(
        _firestore.collection(_usersCollection).doc(tutorId).collection('linkedPatients').doc(patient.uid),
        {
          'patientId': patient.uid,
          'linkedAt': FieldValue.serverTimestamp(),
          'status': 'active',
        },
        SetOptions(merge: true),
      );

      transaction.set(
        _firestore.collection(_usersCollection).doc(patient.uid),
        {
          'acceptedInvitationCode': normalizedCode,
        },
        SetOptions(merge: true),
      );
    });
  }

  static Future<void> removePatientLink(String patientId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No hay usuario autenticado.');

    final role = await getUserRole();
    if (role != UserRole.tutor) {
      throw Exception('Solo los tutores pueden desvincular pacientes.');
    }

    await _firestore.runTransaction((transaction) async {
      transaction.set(
        _firestore.collection(_usersCollection).doc(user.uid).collection('linkedPatients').doc(patientId),
        {'status': 'inactive'},
        SetOptions(merge: true),
      );

      transaction.set(
        _firestore.collection(_usersCollection).doc(patientId).collection('linkedTutors').doc(user.uid),
        {'status': 'inactive'},
        SetOptions(merge: true),
      );
    });
  }

  // ─────────────────────────────────────────────────────────────
  // CONSULTAS DE VINCULACIÓN
  // ─────────────────────────────────────────────────────────────

  static Stream<List<Map<String, dynamic>>> getLinkedPatientsStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection(_usersCollection)
        .doc(user.uid)
        .collection('linkedPatients')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .asyncMap((snapshot) async {
      final patients = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final patientId = doc.data()['patientId'] as String;
        final patientDoc = await _firestore.collection(_usersCollection).doc(patientId).get();
        if (patientDoc.exists) {
          patients.add({
            'id': patientId,
            ...patientDoc.data()!,
            'linkedAt': doc.data()['linkedAt'],
          });
        }
      }
      return patients;
    });
  }

  static Stream<Map<String, dynamic>?> getLinkedTutorStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection(_usersCollection)
        .doc(user.uid)
        .collection('linkedTutors')
        .where('status', isEqualTo: 'active')
        .snapshots()
        .asyncMap((snapshot) async {
      if (snapshot.docs.isEmpty) return null;

      final tutorId = snapshot.docs.first.data()['tutorId'] as String;
      final tutorDoc = await _firestore.collection(_usersCollection).doc(tutorId).get();

      if (!tutorDoc.exists) return null;

      return {
        'id': tutorId,
        ...tutorDoc.data()!,
      };
    });
  }

  // ─────────────────────────────────────────────────────────────
  // LOGOUT
  // ─────────────────────────────────────────────────────────────

  static Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ─────────────────────────────────────────────────────────────
  // PASSWORD RESET
  // ─────────────────────────────────────────────────────────────

  static Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  // ─────────────────────────────────────────────────────────────
  // UTILIDADES
  // ─────────────────────────────────────────────────────────────

  static String _generateRandomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final random = DateTime.now().millisecondsSinceEpoch;
    final code = List.generate(6, (index) {
      final idx = (random + index * 7919) % chars.length;
      return chars[idx];
    }).join();
    return code;
  }
}
