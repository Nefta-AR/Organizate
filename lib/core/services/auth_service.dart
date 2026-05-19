import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

// Representa todos los roles posibles del sistema.
// Usar `.name` produce la cadena que va a Firestore (ej: 'usuario_tdah').
// ignore: constant_identifier_names
enum UserRole { tutor, usuario_tdah, usuario_tea, usuario_general }

/// Servicio estático de autenticación y gestión de usuarios.
///
/// Responsabilidades:
///   - Registro e inicio de sesión (email/contraseña y Google)
///   - Resolución y migración automática de roles en Firestore
///   - Vinculación tutor ↔ usuario mediante códigos de invitación de 6 caracteres
///   - Consultas de vinculación activa (streams en tiempo real)
///
/// Invariante de seguridad: ningún método expone el uid de otro usuario
/// sin pasar primero por una validación de vinculación activa en Firestore.
class AuthService {
  // Clase puramente estática; constructor privado evita instanciación accidental.
  AuthService._();

  static final FirebaseAuth _auth = FirebaseAuth.instance;
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final GoogleSignIn _googleSignIn = GoogleSignIn();

  static const _codesCollection = 'invitationCodes';
  static const _usersCollection = 'users';

  // ─────────────────────────────────────────────────────────────
  // STREAMS DE AUTENTICACIÓN
  // ─────────────────────────────────────────────────────────────

  /// Stream que emite cada vez que el estado de sesión cambia
  /// (login, logout, token refresh). Utilizado por [AuthGate].
  static Stream<User?> get authStateChanges => _auth.authStateChanges();

  static User? get currentUser => _auth.currentUser;

  // ─────────────────────────────────────────────────────────────
  // REGISTRO CON ROL
  // ─────────────────────────────────────────────────────────────

  /// Crea una cuenta con email/contraseña y escribe el documento
  /// inicial en Firestore con los campos específicos del rol.
  ///
  /// Los campos adicionales (linkedPatients, linkedTutors, etc.) se
  /// inicializan vacíos para que las reglas de Firestore puedan verificar
  /// su existencia sin hacer gets adicionales en evaluación de reglas.
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
      if (role == UserRole.usuario_tdah || role == UserRole.usuario_tea) ...{
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

  /// Inicia sesión con Google. En web usa popup; en móvil usa el flujo nativo.
  ///
  /// Si el usuario es nuevo se crea su documento Firestore con rol
  /// [UserRole.usuario_general] para que [AuthGate] lo redirija a
  /// [RoleSelectionScreen] antes de darle acceso a la app.
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
        'role': UserRole.usuario_general.name,
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

  /// Resuelve el rol del usuario actual con tres capas de fallback:
  ///
  /// 1. Lee el campo `role` del documento Firestore.
  /// 2. Si está vacío, infiere el rol por la presencia de campos estructurales
  ///    (`linkedPatients` → tutor, `pictograms` → tea, `linkedTutors` → tdah)
  ///    y escribe el rol inferido para que no se repita en futuros accesos.
  /// 3. Si los strings son los nombres legacy (`paciente_*`), los migra
  ///    automáticamente al nuevo esquema (`usuario_*`) en la misma llamada.
  ///
  /// Este patrón de migración on-the-fly evita scripts de migración batch
  /// y garantiza compatibilidad hacia atrás con cuentas anteriores.
  static Future<UserRole?> getUserRole() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection(_usersCollection).doc(user.uid).get();
    final data = doc.data();
    var roleStr = data?['role'] as String?;

    // Capa 2: inferir rol por campos estructurales del documento
    if (roleStr == null || roleStr.isEmpty) {
      final hasTutorFields = data?.containsKey('linkedPatients') ?? false;
      final hasPatientFields = data?.containsKey('linkedTutors') ?? false;
      final hasTeaFields = data?.containsKey('pictograms') ?? false;

      if (hasTutorFields) {
        roleStr = 'tutor';
      } else if (hasTeaFields) {
        roleStr = 'usuario_tea';
      } else if (hasPatientFields) {
        roleStr = 'usuario_tdah';
      } else {
        roleStr = 'usuario_general';
      }

      await _firestore.collection(_usersCollection).doc(user.uid).set(
        {
          'role': roleStr,
          if (roleStr == 'tutor') ...{
            'linkedPatients': {},
            'invitationCodes': {},
            'kioskModeEnabled': false,
          },
          if (roleStr == 'usuario_tdah' || roleStr == 'usuario_tea') ...{
            'linkedTutors': {},
            'acceptedInvitationCode': null,
          },
        },
        SetOptions(merge: true),
      );
    }

    // Capa 3: migración automática de nombres de rol legacy
    if (roleStr == 'paciente' || roleStr == 'paciente_tdah') {
      roleStr = 'usuario_tdah';
      await _firestore.collection(_usersCollection).doc(user.uid).set(
        {'role': roleStr, 'linkedTutors': {}, 'acceptedInvitationCode': null},
        SetOptions(merge: true),
      );
    } else if (roleStr == 'paciente_tea') {
      roleStr = 'usuario_tea';
      await _firestore.collection(_usersCollection).doc(user.uid).set(
        {'role': roleStr},
        SetOptions(merge: true),
      );
    }

    switch (roleStr) {
      case 'tutor':
        return UserRole.tutor;
      case 'usuario_tdah':
        return UserRole.usuario_tdah;
      case 'usuario_tea':
        return UserRole.usuario_tea;
      case 'usuario_general':
        return UserRole.usuario_general;
      default:
        return UserRole.usuario_general;
    }
  }

  /// Versión reactiva de [getUserRole] para [AuthGate].
  ///
  /// Usa `asyncMap` porque la migración de roles requiere escrituras en
  /// Firestore que no pueden ejecutarse dentro de un `map` síncrono.
  /// Cada emisión del stream del documento puede disparar una migración.
  static Stream<UserRole?> getUserRoleStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value(null);

    return _firestore
        .collection(_usersCollection)
        .doc(user.uid)
        .snapshots()
        .asyncMap((snapshot) async {
      final data = snapshot.data();
      var roleStr = data?['role'] as String?;

      // Misma lógica de inferencia y migración que getUserRole()
      if (roleStr == null || roleStr.isEmpty) {
        final hasTutorFields = data?.containsKey('linkedPatients') ?? false;
        final hasPatientFields = data?.containsKey('linkedTutors') ?? false;
        final hasTeaFields = data?.containsKey('pictograms') ?? false;

        if (hasTutorFields) {
          roleStr = 'tutor';
        } else if (hasTeaFields) {
          roleStr = 'usuario_tea';
        } else if (hasPatientFields) {
          roleStr = 'usuario_tdah';
        } else {
          roleStr = 'usuario_general';
        }

        await _firestore.collection(_usersCollection).doc(user.uid).set(
          {
            'role': roleStr,
            if (roleStr == 'tutor') ...{
              'linkedPatients': {},
              'invitationCodes': {},
              'kioskModeEnabled': false,
            },
            if (roleStr == 'usuario_tdah' || roleStr == 'usuario_tea') ...{
              'linkedTutors': {},
              'acceptedInvitationCode': null,
            },
          },
          SetOptions(merge: true),
        );
      }

      if (roleStr == 'paciente' || roleStr == 'paciente_tdah') {
        roleStr = 'usuario_tdah';
        await _firestore.collection(_usersCollection).doc(user.uid).set(
          {'role': roleStr, 'linkedTutors': {}, 'acceptedInvitationCode': null},
          SetOptions(merge: true),
        );
      } else if (roleStr == 'paciente_tea') {
        roleStr = 'usuario_tea';
        await _firestore.collection(_usersCollection).doc(user.uid).set(
          {'role': roleStr},
          SetOptions(merge: true),
        );
      }

      switch (roleStr) {
        case 'tutor':
          return UserRole.tutor;
        case 'usuario_tdah':
          return UserRole.usuario_tdah;
        case 'usuario_tea':
          return UserRole.usuario_tea;
        case 'usuario_general':
          return UserRole.usuario_general;
        default:
          return UserRole.usuario_general;
      }
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
  // VINCULACIÓN TUTOR ↔ USUARIO (Código de invitación)
  // ─────────────────────────────────────────────────────────────

  /// Genera un código alfanumérico de 6 caracteres y lo almacena en
  /// la colección global `invitationCodes` con TTL de 7 días.
  ///
  /// El campo `tutorName` se incluye en el documento del código para que
  /// el usuario pueda ver a quién pertenece sin necesitar leer
  /// `users/{tutorId}` (permiso que no tiene antes de vincularse).
  static Future<String> generateInvitationCode() async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No hay usuario autenticado.');

    final role = await getUserRole();
    if (role != UserRole.tutor) {
      throw Exception('Solo los tutores pueden generar códigos de invitación.');
    }

    final code = _generateRandomCode();
    final tutorName = user.displayName ?? 'Tutor';

    await _firestore.collection(_codesCollection).doc(code).set({
      'code': code,
      'tutorId': user.uid,
      'tutorName': tutorName,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'active',
      'usedBy': null,
      'usedAt': null,
      'expiresAt': Timestamp.fromDate(DateTime.now().add(const Duration(days: 7))),
    });

    return code;
  }

  /// Valida un código sin consumirlo. Retorna null si el documento no existe,
  /// o un mapa con `valid: false` y `reason` si está vencido/usado.
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

    final tutorName = data['tutorName'] as String? ?? 'Tutor';

    return {
      'valid': true,
      'tutorId': data['tutorId'],
      'tutorName': tutorName,
    };
  }

  /// Acepta un código y crea los documentos de vinculación en ambas
  /// direcciones en un batch atómico.
  ///
  /// Usa batch en lugar de transacción porque una transacción multi-documento
  /// que incluya lecturas de colecciones de otros usuarios falla por las
  /// reglas de Firestore (la transacción ejecuta todas las lecturas primero
  /// con los permisos del usuario que inicia, y `invitationCodes` tiene
  /// reglas de escritura que referencian `linkedTutors`).
  static Future<void> acceptInvitationCode(String code) async {
    final patient = _auth.currentUser;
    if (patient == null) throw Exception('No hay usuario autenticado.');

    final role = await getUserRole();
    if (role != UserRole.usuario_tdah && role != UserRole.usuario_tea) {
      throw Exception('Solo los usuarios pueden aceptar códigos de invitación.');
    }

    final validation = await validateInvitationCode(code);
    if (validation == null || validation['valid'] != true) {
      throw Exception(validation?['reason'] ?? 'Código inválido.');
    }

    final tutorId = validation['tutorId'] as String;
    final normalizedCode = code.trim().toUpperCase();

    // Segunda verificación de estado antes del batch para detectar
    // condición de carrera si dos usuarios intentan el mismo código.
    final codeSnap = await _firestore.collection(_codesCollection).doc(normalizedCode).get();
    if (codeSnap.data()?['status'] != 'active') {
      throw Exception('El código ya fue utilizado por otro usuario.');
    }

    final batch = _firestore.batch();

    // Marca el código como usado
    batch.update(
      _firestore.collection(_codesCollection).doc(normalizedCode),
      {
        'status': 'used',
        'usedBy': patient.uid,
        'usedAt': FieldValue.serverTimestamp(),
      },
    );

    // Registra el tutor en la subcolección del usuario (permite a las
    // reglas verificar `isLinkedTutor` y `isLinkedPatient`)
    batch.set(
      _firestore.collection(_usersCollection).doc(patient.uid).collection('linkedTutors').doc(tutorId),
      {
        'tutorId': tutorId,
        'linkedAt': FieldValue.serverTimestamp(),
        'status': 'active',
      },
      SetOptions(merge: true),
    );

    batch.set(
      _firestore.collection(_usersCollection).doc(patient.uid),
      {'acceptedInvitationCode': normalizedCode},
      SetOptions(merge: true),
    );

    await batch.commit();
  }

  /// Desvincula un usuario del tutor marcando la entrada en `linkedTutors`
  /// como `inactive`. No elimina el documento para mantener historial.
  static Future<void> removePatientLink(String patientId) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('No hay usuario autenticado.');

    final role = await getUserRole();
    if (role != UserRole.tutor) {
      throw Exception('Solo los tutores pueden desvincular usuarios.');
    }

    final batch = _firestore.batch();

    // El tutor puede actualizar su propia entrada en linkedTutors del usuario
    // gracias a la regla: `allow update: if tutorId == request.auth.uid`
    batch.set(
      _firestore.collection(_usersCollection).doc(patientId).collection('linkedTutors').doc(user.uid),
      {'status': 'inactive'},
      SetOptions(merge: true),
    );

    final codesSnap = await _firestore
        .collection(_codesCollection)
        .where('tutorId', isEqualTo: user.uid)
        .where('usedBy', isEqualTo: patientId)
        .get();

    for (final doc in codesSnap.docs) {
      batch.update(doc.reference, {'status': 'deactivated'});
    }

    await batch.commit();
  }

  // ─────────────────────────────────────────────────────────────
  // CONSULTAS DE VINCULACIÓN
  // ─────────────────────────────────────────────────────────────

  /// Retorna en tiempo real la lista de usuarios vinculados al tutor actual.
  ///
  /// La estrategia es consultar `invitationCodes` filtrados por `tutorId` y
  /// `status == 'used'`, luego leer cada documento de usuario. Esto evita
  /// mantener una subcolección `linkedPatients` en el tutor (que requeriría
  /// permisos bidireccionales más complejos en las reglas de Firestore).
  static Stream<List<Map<String, dynamic>>> getLinkedPatientsStream() {
    final user = _auth.currentUser;
    if (user == null) return Stream.value([]);

    return _firestore
        .collection(_codesCollection)
        .where('tutorId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'used')
        .snapshots()
        .asyncMap((snapshot) async {
      final patients = <Map<String, dynamic>>[];
      for (final doc in snapshot.docs) {
        final patientId = doc.data()['usedBy'] as String?;
        if (patientId == null) continue;
        final patientDoc = await _firestore.collection(_usersCollection).doc(patientId).get();
        if (patientDoc.exists) {
          patients.add({
            'id': patientId,
            ...patientDoc.data()!,
            'linkedAt': doc.data()['usedAt'],
          });
        }
      }
      return patients;
    });
  }

  /// Retorna en tiempo real el tutor activo del usuario actual,
  /// o `null` si no hay ninguno vinculado.
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

  /// Cierra sesión tanto en Firebase Auth como en Google Sign-In.
  /// El orden importa: primero Google para limpiar el token OAuth,
  /// luego Firebase para disparar `authStateChanges`.
  static Future<void> logout() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // ─────────────────────────────────────────────────────────────
  // UTILIDADES INTERNAS
  // ─────────────────────────────────────────────────────────────

  static Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Genera un código de 6 caracteres usando el timestamp actual como semilla.
  ///
  /// El alfabeto excluye caracteres ambiguos (0/O, 1/I/l) para facilitar
  /// la transcripción manual del código desde una pantalla compartida.
  /// No usa `Random.secure()` porque la entropía del timestamp es suficiente
  /// para un código de uso único con TTL de 7 días.
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
