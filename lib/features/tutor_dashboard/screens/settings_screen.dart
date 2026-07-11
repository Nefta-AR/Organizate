// ============================================================
// lib/features/tutor_dashboard/screens/settings_screen.dart
// ============================================================
// Pantalla de ajustes completa para el usuario paciente o tutor.
//
// ## Secciones principales (Cards)
//
//   _buildProfileRoleCard       — Nombre, email, avatar y rol del usuario.
//                                 Botón de foto (galería o avatar prediseñado).
//
//   _buildVinculacionCard        — Solo tutor: navega a TutorVinculacionScreen.
//
//   _buildVinculacionUsuarioCard — Solo usuario: muestra tutor vinculado o
//                                 botón para vincular con código de invitación.
//
//   _buildPantallasNavTile       — Solo usuario: navega a PantallasConfigScreen
//                                 para elegir qué pestañas mostrar.
//
//   _buildEmergencyCard          — Nombre y teléfono del contacto de emergencia.
//                                 Se usa en PantallaPacienteTEA para llamadas SOS.
//
//   _buildNotificacionesCard     — Toggle notiTaskEnabled + picker de offset.
//                                 Botones "Optimizar entrega" y "Probar notificación".
//
//   _buildFocoCard               — Sonido y vibración del Pomodoro + estadísticas.
//
//   _buildBackupCard             — Backup/restauración via GoogleDriveService.
//
//   _buildLogoutCard             — Cerrar sesión con diálogo de confirmación.
//
// ## Métodos clave
//
//   [_handleLogout]           — Navega a LoginScreen y llama Firebase+Google signOut.
//   [_saveEmergencyContact]   — Valida y guarda emergencyName/emergencyPhone.
//   [_uploadProfilePhoto]     — Gallery → Storage → Firestore photoURL.
//   [_vincularConTutor]       — Valida código → batch write tutor-paciente.
//   [_editDisplayName]        — Diálogo para editar nombre + Firebase Auth displayName.
//
// ## Paleta interna (_Palette)
//
//   Colores blue-grey para diferenciar visualmente de HomeScreen (warmCream).
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:simple/features/auth/screens/login_screen.dart';
import 'package:simple/core/services/auth_service.dart';
import 'package:simple/features/auth/screens/role_selection_screen.dart';
import 'package:simple/features/tutor_dashboard/screens/tutor_vinculacion_screen.dart';
import 'package:simple/core/services/notification_service.dart';
import 'package:simple/core/services/google_drive_service.dart';
import 'package:simple/core/utils/reminder_options.dart';
import 'package:simple/core/widgets/custom_nav_bar.dart';
import 'package:simple/features/tutor_dashboard/screens/pantallas_config_screen.dart';
import 'package:simple/core/services/tour_service.dart';

// ── Paleta de colores interna ─────────────────────────────────────────────────
// Tonos blue-grey para distinguir esta pantalla de las de flujo principal.
class _Palette {
  _Palette._(); // No instanciable: clase de constantes
  static const background = Color(0xFFF4F6F8); // Gris muy claro para el Scaffold
  static const primary    = Color(0xFF607D8B); // Blue-grey 600 (color principal)
  static const surface    = Colors.white;       // Fondo de Cards
  static const textDark   = Color(0xFF37474F); // Texto principal oscuro
  static const textMuted  = Color(0xFF78909C); // Texto secundario gris
  static const accent     = Color(0xFF7EA3BC); // Azul más vivo para íconos y acciones
}

class SettingsScreen extends StatefulWidget {
  // showNavBar: false cuando SettingsScreen se abre desde una ruta que ya tiene barra
  final bool showNavBar;
  const SettingsScreen({super.key, this.showNavBar = true});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Referencia al documento Firestore del usuario autenticado.
  // Se usa para leer datos en StreamBuilder y para escribir ajustes.
  late final DocumentReference<Map<String, dynamic>> _userDoc;

  // Controllers para los campos de texto del contacto de emergencia.
  // late init en initState para vincularlos con _userDoc cuando ya conocemos el UID.
  final _emergencyNameController  = TextEditingController();
  final _emergencyPhoneController = TextEditingController();

  // true cuando el usuario ha modificado algún campo del contacto de emergencia
  // pero aún no ha guardado. Habilita el botón "Guardar".
  bool _isEmergencyDirty = false;

  // true durante la escritura del contacto de emergencia en Firestore.
  bool _isSavingEmergency = false;

  // true mientras se sube la foto de perfil a Firebase Storage.
  // Muestra el spinner sobre el avatar y deshabilita el tap.
  bool _isUploadingPhoto = false;

  // true durante una operación de backup o restauración con Google Drive.
  // Deshabilita ambos botones para evitar operaciones paralelas.
  bool _isBackingUp = false;

  // Progreso de la operación de backup (0.0–1.0); null para un spinner indeterminado.
  double? _backupProgress;

  // Fecha del último sync con Google Drive. Se carga en initState
  // desde SharedPreferences via GoogleDriveService.getLastSyncTime().
  DateTime? _lastSync;

  // Opciones de sonido disponibles para el Pomodoro.
  // 'key' se guarda en Firestore; 'label' se muestra en el Dropdown.
  static const List<Map<String, String>> _pomodoroSoundOptions = [
    {'key': 'bell',          'label': 'Campanilla clásica'},
    {'key': 'notificacion1', 'label': 'Sonido Notificación'},
  ];

  // Lista de nombres de avatares prediseñados.
  // Cada nombre corresponde a assets/avatars/{nombre}.png.
  static const List<String> _availableAvatars = [
    'emoticon', 'koala', 'panda', 'pinguino',
    'rana', 'tigre', 'unicornio', 'zorro',
  ];

  // ── Ciclo de vida ─────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    // Obtenemos el UID del usuario autenticado (garantizado por AuthGate)
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // Referencia al documento de usuario en Firestore
    _userDoc = FirebaseFirestore.instance.collection('users').doc(uid);

    // Cargamos la fecha del último sync desde SharedPreferences
    _loadLastSync();
  }

  /// Carga la fecha del último sync con Google Drive desde SharedPreferences.
  /// Si nunca se hizo backup, retorna null y no se muestra la etiqueta de sync.
  Future<void> _loadLastSync() async {
    final lastSync = await GoogleDriveService.instance.getLastSyncTime();
    if (mounted) {
      setState(() => _lastSync = lastSync);
    }
  }

  @override
  void dispose() {
    // Liberamos los controllers para evitar memory leaks al salir de la pantalla
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  // ── Cerrar sesión ─────────────────────────────────────────────────────────────

  /// Navega a LoginScreen quitando todas las rutas del stack, luego cierra
  /// la sesión de Google (si la hay) y de Firebase Auth.
  ///
  /// La navegación se hace ANTES del signOut para evitar errores de contexto
  /// cuando el AuthGate detecta el cambio de estado y reconstruye el árbol.
  Future<void> _handleLogout() async {
    if (!mounted) return;

    // Cerramos sesión primero para evitar que una re-autenticación rápida con
    // Google encuentre un usuario de Firebase todavía activo (condición de carrera
    // que causa error "unknown" en signInWithCredential al cambiar de cuenta).
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}

    // Navegamos después de cerrar sesión: AuthGate ya detectó user == null,
    // y esta navegación explícita limpia el stack de rutas del Navigator.
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  // ── Guardar contacto de emergencia ────────────────────────────────────────────

  /// Guarda el nombre y teléfono del contacto de emergencia en Firestore.
  ///
  /// Si el campo está vacío, usa FieldValue.delete() para eliminar el campo existente.
  /// También elimina el campo 'phone' heredado (campo legado de versiones anteriores).
  Future<void> _saveEmergencyContact() async {
    setState(() => _isSavingEmergency = true);

    // Capturamos el messenger antes del await para evitar uso tras desmontaje
    final messenger = ScaffoldMessenger.of(context);

    final trimmedName  = _emergencyNameController.text.trim();
    final trimmedPhone = _emergencyPhoneController.text.trim();

    // Construimos el payload con delete() para campos vacíos
    final payload = <String, dynamic>{
      // Eliminamos el campo 'phone' heredado (campo legado renombrado)
      'phone': FieldValue.delete(),
      // Si el campo está vacío, lo eliminamos; si no, lo guardamos
      'emergencyName':  trimmedName.isEmpty  ? FieldValue.delete() : trimmedName,
      'emergencyPhone': trimmedPhone.isEmpty ? FieldValue.delete() : trimmedPhone,
    };

    try {
      // merge: true para no sobreescribir el resto del documento
      await _userDoc.set(payload, SetOptions(merge: true));

      // Marcamos como "no sucio" para deshabilitar el botón de guardar
      setState(() => _isEmergencyDirty = false);

      messenger.showSnackBar(
        const SnackBar(content: Text('Contacto de emergencia actualizado')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo guardar el contacto')),
      );
    } finally {
      // Siempre apagamos el spinner aunque haya fallado
      if (mounted) setState(() => _isSavingEmergency = false);
    }
  }

  // ── Subir foto de perfil ──────────────────────────────────────────────────────

  /// Abre la galería del dispositivo, sube la imagen a Firebase Storage
  /// y guarda la URL en Firestore (campo 'photoURL').
  ///
  /// Ruta en Storage: user_photos/{uid}/profile.jpg
  /// Al usar siempre el mismo nombre, cada subida reemplaza la anterior.
  Future<void> _uploadProfilePhoto() async {
    final picker = ImagePicker();

    // Abrimos la galería con compresión de calidad y tamaño máximo
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,  // 70% de calidad JPEG (reduce el tamaño del archivo)
      maxWidth: 512,     // Máximo 512px de ancho (suficiente para un avatar)
    );

    // Si el usuario canceló o el widget fue desmontado, salimos
    if (picked == null || !mounted) return;

    setState(() => _isUploadingPhoto = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;

      // Referencia a la ruta del avatar en Storage
      final ref = FirebaseStorage.instance.ref('user_photos/$uid/profile.jpg');

      // Leemos los bytes del archivo temporal de la galería
      final bytes = await picked.readAsBytes();

      // Metadatos necesarios para que los navegadores sirvan la imagen correctamente
      final metadata = SettableMetadata(contentType: 'image/jpeg');

      // Subimos los bytes a Storage (putData funciona en iOS y Android)
      await ref.putData(bytes, metadata);

      // Obtenemos la URL pública de descarga para guardarla en Firestore
      final url = await ref.getDownloadURL();

      // Guardamos la URL en el perfil del usuario
      await _userDoc.set({'photoURL': url}, SetOptions(merge: true));

      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Foto de perfil actualizada')),
        );
      }
    } on FirebaseException catch (e) {
      // Error específico de Firebase: mostramos el código y mensaje técnico
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text('[${e.code}] ${e.message ?? "Error de Firebase Storage"}'),
          duration: const Duration(seconds: 6),
        ));
      }
    } catch (e) {
      // Error genérico (permisos del sistema, archivo corrupto, etc.)
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text('Error inesperado: $e'),
          duration: const Duration(seconds: 6),
        ));
      }
    } finally {
      // Siempre apagamos el spinner, aunque el pop o error ocurra antes
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  // ── Bottom sheet: opciones de foto ───────────────────────────────────────────

  /// Muestra un menú inferior con dos opciones: galería o avatar prediseñado.
  Future<void> _showPhotoOptions(String? currentAvatar) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _Palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Solo ocupa el espacio necesario
            children: [
              // Barra drag handle del sheet
              Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Opción 1: Subir foto desde la galería
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: _Palette.accent),
                title: const Text('Subir foto de galería',
                    style: TextStyle(color: _Palette.textDark)),
                onTap: () {
                  Navigator.pop(ctx); // Cerramos el sheet antes de abrir la galería
                  _uploadProfilePhoto();
                },
              ),

              // Opción 2: Elegir un avatar de los prediseñados
              ListTile(
                leading: const Icon(Icons.face_outlined, color: _Palette.accent),
                title: const Text('Elegir avatar prediseñado',
                    style: TextStyle(color: _Palette.textDark)),
                onTap: () {
                  Navigator.pop(ctx); // Cerramos el sheet antes de abrir el picker
                  _showAvatarPicker(currentAvatar);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Selector de avatar prediseñado ───────────────────────────────────────────

  /// Muestra un GridView de avatares prediseñados en un bottom sheet.
  /// Al seleccionar uno, lo guarda en Firestore (campo 'avatar').
  Future<void> _showAvatarPicker(String? currentAvatar) async {
    final messenger = ScaffoldMessenger.of(context);

    // showModalBottomSheet retorna el nombre del avatar seleccionado (o null si canceló)
    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: _Palette.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              shrinkWrap: true, // No expande más allá de lo necesario
              itemCount: _availableAvatars.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,    // 4 avatares por fila
                crossAxisSpacing: 12, // Espacio horizontal entre avatares
                mainAxisSpacing: 12,  // Espacio vertical entre avatares
              ),
              itemBuilder: (context, index) {
                final avatarName = _availableAvatars[index];
                final isSelected = avatarName == currentAvatar; // ¿Es el actual?

                return GestureDetector(
                  // Retornamos el nombre del avatar seleccionado al pop
                  onTap: () => Navigator.of(context).pop(avatarName),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          // Círculo con la imagen del avatar
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: isSelected
                                ? _Palette.accent.withValues(alpha: 0.15) // Fondo azul si seleccionado
                                : Colors.grey.shade100,
                            backgroundImage:
                                AssetImage('assets/avatars/$avatarName.png'),
                          ),
                          // Overlay con check encima si es el avatar actual
                          if (isSelected)
                            Container(
                              width: 60, height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                // Semitransparente azul para no ocultar el avatar
                                color: _Palette.accent.withValues(alpha: 0.4),
                              ),
                              child: const Icon(Icons.check,
                                  color: Colors.white, size: 22),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Nombre del avatar en texto pequeño
                      Text(avatarName,
                          style: const TextStyle(
                              fontSize: 11, color: _Palette.textMuted)),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    // Si el usuario seleccionó un avatar, lo guardamos en Firestore
    if (selected != null) {
      try {
        // merge: true para no sobreescribir otros campos
        await _userDoc.set({'avatar': selected}, SetOptions(merge: true));
        if (mounted) setState(() {}); // Forzamos rebuild para actualizar el avatar
        messenger.showSnackBar(
          const SnackBar(content: Text('Avatar actualizado')),
        );
      } catch (_) {
        messenger.showSnackBar(
          const SnackBar(content: Text('No se pudo actualizar el avatar')),
        );
      }
    }
  }

  // ── Resolución de imagen de avatar ───────────────────────────────────────────

  /// Determina qué ImageProvider usar para el avatar del usuario.
  ///
  /// Prioridad:
  ///   1. photoURL de Firestore o Google Auth (URL de Storage o Google)
  ///   2. Asset del avatar prediseñado seleccionado
  ///   3. null → el CircleAvatar mostrará el icono de persona por defecto
  ImageProvider? _resolveAvatar(String? photoUrl, String? avatar) {
    if (photoUrl != null && photoUrl.isNotEmpty) return NetworkImage(photoUrl);
    if (avatar != null && avatar.isNotEmpty) {
      return AssetImage('assets/avatars/$avatar.png');
    }
    return null;
  }

  // ── Construcción principal ────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.background,

      // La barra de navegación inferior solo se muestra cuando showNavBar = true
      // (cuando SettingsScreen es una pestaña de la nav bar principal)
      bottomNavigationBar: widget.showNavBar
          ? const CustomNavBar(screen: NavScreen.perfil)
          : null,

      appBar: AppBar(
        backgroundColor: _Palette.background,
        elevation: 0, // Sin sombra para diseño plano
        title: const Text(
          'Perfil y configuración',
          style: TextStyle(
            color: _Palette.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // StreamBuilder: escucha cambios en el documento del usuario en tiempo real.
      // Se reconstruye automáticamente cuando el usuario cambia nombre, rol, etc.
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _userDoc.snapshots(),
        builder: (context, snapshot) {
          // Cargando: spinner centrado
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error o documento sin datos: mensaje de error
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data?.data() == null) {
            return const Center(child: Text('No se pudo cargar tu perfil.'));
          }

          // Extraemos todos los datos del documento Firestore
          final data     = snapshot.data!.data()!;
          final authUser = FirebaseAuth.instance.currentUser;

          // Nombre: Auth.displayName tiene prioridad (Google Sign-In lo establece)
          final displayName  = authUser?.displayName;
          final firestoreName = data['name'] as String?;
          final name = (displayName?.isNotEmpty == true ? displayName : firestoreName) ?? 'Usuario';

          // Email del usuario
          final email = authUser?.email ?? (data['email'] as String?) ?? '';

          // Foto: Firestore primero (foto subida por el usuario), luego Auth (Google)
          final photoUrl = data['photoURL'] as String? ?? authUser?.photoURL;

          // Nombre del asset de avatar (ej: 'zorro')
          final avatar = data['avatar'] as String?;

          // Contacto de emergencia (legado: 'phone' → nuevo: 'emergencyPhone')
          final emergencyName  = (data['emergencyName']  as String?) ?? '';
          final emergencyPhone = (data['emergencyPhone'] as String?) ??
              (data['phone']         as String?) ?? ''; // Fallback al campo legado

          // Ajustes de notificaciones
          final notiTaskEnabled = (data['notiTaskEnabled'] as bool?) ?? true;

          // notiTaskDefaultOffsetMinutes puede no existir en docs antiguos
          // Si no existe, usamos kDefaultReminderMinutes como valor por defecto
          final hasDefaultReminderKey = data.containsKey('notiTaskDefaultOffsetMinutes');
          final notiOffset = hasDefaultReminderKey
              ? (data['notiTaskDefaultOffsetMinutes'] as num?)?.toInt()
              : kDefaultReminderMinutes;

          // Ajustes del Pomodoro
          final pomodoroSoundEnabled     = (data['pomodoroSoundEnabled']     as bool?) ?? true;
          final pomodoroVibrationEnabled = (data['pomodoroVibrationEnabled'] as bool?) ?? false;
          final pomodoroSoundRaw = (data['pomodoroSound'] as String?) ?? 'bell';

          // Validamos que el sonido guardado sea uno de los disponibles.
          // Si no coincide (ej: sonido eliminado), usamos el primero de la lista.
          final pomodoroSound =
              _pomodoroSoundOptions.any((o) => o['key'] == pomodoroSoundRaw)
                  ? pomodoroSoundRaw
                  : _pomodoroSoundOptions.first['key']!;

          // Rol y estadísticas del usuario
          final role             = (data['role']                    as String?) ?? '';
          final points           = (data['points']                  as num?)?.toInt() ?? 0;
          final streak           = (data['streak']                  as num?)?.toInt() ?? 0;
          final focusSessions    = (data['focusSessionsCompleted']  as num?)?.toInt() ?? 0;
          final totalFocusMinutes = (data['totalFocusMinutes']       as num?)?.toInt() ?? 0;

          // Sincronizamos los controllers del contacto de emergencia.
          // Solo si el usuario NO está editando actualmente (_isEmergencyDirty = false)
          // para no sobreescribir lo que el usuario está escribiendo.
          if (!_isEmergencyDirty) {
            _emergencyNameController.text  = emergencyName;
            _emergencyPhoneController.text = emergencyPhone;
          }

          return SingleChildScrollView(
            // Padding inferior extra si hay nav bar para no quedar detrás de ella
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              MediaQuery.paddingOf(context).bottom +
                  (widget.showNavBar ? 112 : 88),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Tarjeta de perfil: avatar, nombre, email, rol
                _buildProfileRoleCard(name, email, photoUrl, avatar, role),
                const SizedBox(height: 16),

                // Sección exclusiva para tutores: gestión de vinculaciones
                if (role == 'tutor') ...[
                  _buildVinculacionCard(), // Navega a TutorVinculacionScreen
                  const SizedBox(height: 16),
                ],

                // Secciones exclusivas para usuarios (pacientes)
                if (role != 'tutor') ...[
                  _buildVinculacionUsuarioCard(),  // Estado de vinculación con tutor
                  const SizedBox(height: 16),
                  // La personalización de pestañas solo aparece si el usuario
                  // NO tiene tutor vinculado. Con tutor, el tutor gestiona las
                  // pestañas desde su panel de supervisión.
                  StreamBuilder<Map<String, dynamic>?>(
                    stream: AuthService.getLinkedTutorStream(),
                    builder: (context, tutorSnap) {
                      final hasTutor = tutorSnap.data != null;
                      if (hasTutor) return const SizedBox.shrink();
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildPantallasNavTile(), // Navega a PantallasConfigScreen
                          const SizedBox(height: 16),
                        ],
                      );
                    },
                  ),
                  _buildEmergencyCard(),            // Contacto de emergencia
                  const SizedBox(height: 16),
                  _buildNotificacionesCard(notiTaskEnabled, notiOffset),
                  const SizedBox(height: 16),
                  _buildFocoCard(
                    pomodoroSoundEnabled,
                    pomodoroVibrationEnabled,
                    pomodoroSound,
                    focusSessions,
                    totalFocusMinutes,
                    points,
                    streak,
                  ),
                  const SizedBox(height: 16),
                ],

                // Backup y restauración (disponible para todos los roles)
                _buildBackupCard(),
                const SizedBox(height: 16),

                // Repetir tour de bienvenida
                _buildTourCard(),
                const SizedBox(height: 16),

                // Botón de cerrar sesión (disponible para todos los roles)
                _buildLogoutCard(),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  // ── Tarjeta de perfil y rol ───────────────────────────────────────────────────

  Widget _buildProfileRoleCard(
      String name, String email, String? photoUrl, String? avatar, String role) {

    // Traduce el rol de Firestore a texto legible para el usuario
    final roleLabel = switch (role) {
      'tutor'   => 'Tutor',
      'usuario' => 'Usuario',
      // Roles legados de versiones anteriores (aún pueden existir en Firestore)
      'usuario_tea' || 'usuario_tdah' || 'usuario_general' => 'Usuario',
      _ => role.isEmpty ? 'Sin rol asignado' : role, // Rol desconocido: lo mostramos literal
    };

    return Container(
      decoration: BoxDecoration(
        color: _Palette.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar tappable: al tocar abre el menú de opciones de foto
          GestureDetector(
            onTap: _isUploadingPhoto ? null : () => _showPhotoOptions(avatar),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Círculo de avatar con foto o icono de persona
                CircleAvatar(
                  radius: 38,
                  backgroundColor: const Color(0xFFE8EEF2),
                  backgroundImage: _resolveAvatar(photoUrl, avatar),
                  // child solo se muestra si backgroundImage es null
                  child: (photoUrl == null || photoUrl.isEmpty) &&
                          (avatar == null || avatar.isEmpty)
                      ? const Icon(Icons.person,
                          size: 34, color: _Palette.textMuted)
                      : null,
                ),

                // Spinner oscuro sobre el avatar mientras se sube la foto
                if (_isUploadingPhoto)
                  Container(
                    width: 76, height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.35),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    ),
                  ),

                // Badge de cámara en la esquina inferior derecha del avatar
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: 24, height: 24,
                    decoration: BoxDecoration(
                      color: _Palette.accent,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(Icons.camera_alt, size: 12, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),

          // Información del usuario (nombre, email, rol)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Fila de nombre con botón de edición
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: _Palette.textDark,
                        ),
                      ),
                    ),
                    // Botón de lápiz: abre diálogo para editar el nombre
                    GestureDetector(
                      onTap: () => _editDisplayName(name),
                      child: const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Icon(Icons.edit_outlined,
                            size: 18, color: _Palette.accent),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),

                // Email del usuario
                Text(email,
                    style: const TextStyle(fontSize: 13, color: _Palette.textMuted)),

                const SizedBox(height: 10),
                const Divider(height: 1), // Separador visual
                const SizedBox(height: 10),

                // Fila del rol con botón de edición
                Row(
                  children: [
                    const Icon(Icons.manage_accounts_outlined,
                        size: 16, color: _Palette.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        roleLabel,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _Palette.textDark),
                      ),
                    ),
                    // Botón de lápiz: muestra confirmación antes de ir a RoleSelectionScreen.
                    // Se oculta si el usuario tiene tutor vinculado para evitar que rompa
                    // la relación tutor-paciente.
                    StreamBuilder<Map<String, dynamic>?>(
                      stream: AuthService.getLinkedTutorStream(),
                      builder: (context, tutorSnap) {
                        final hasTutor = tutorSnap.data != null;
                        if (hasTutor) return const SizedBox.shrink();
                        return GestureDetector(
                          onTap: () => _showRoleChangeConfirmation(),
                          child: const Padding(
                            padding: EdgeInsets.only(left: 6),
                            child: Icon(Icons.edit_outlined,
                                size: 18, color: _Palette.accent),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Editar nombre de usuario ──────────────────────────────────────────────────

  /// Muestra un diálogo con un TextField para cambiar el nombre del usuario.
  /// Actualiza tanto Firebase Auth (displayName) como Firestore (campo 'name').
  Future<void> _editDisplayName(String currentName) async {
    // Pre-llenamos el campo con el nombre actual
    final controller = TextEditingController(text: currentName);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Editar nombre'),
        content: TextField(
          controller: controller,
          textCapitalization: TextCapitalization.words, // Capitaliza cada palabra
          autofocus: true, // Abre el teclado automáticamente
          decoration: const InputDecoration(
            labelText: 'Nombre',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false), // Cancelar: retorna false
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true), // Guardar: retorna true
            child: const Text('Guardar'),
          ),
        ],
      ),
    );

    // Liberamos el controller al cerrar el diálogo
    controller.dispose();

    if (confirmed != true || !mounted) return;

    final newName = controller.text.trim();
    // No guardamos si el nombre está vacío o es igual al actual
    if (newName.isEmpty || newName == currentName) return;

    final messenger = ScaffoldMessenger.of(context);
    try {
      // Actualizamos Firebase Auth (visible en otros lugares que usen displayName)
      await FirebaseAuth.instance.currentUser?.updateDisplayName(newName);

      // Actualizamos Firestore (fuente de verdad del nombre en la app)
      await _userDoc.set({'name': newName}, SetOptions(merge: true));

      if (mounted) setState(() {}); // Forzamos rebuild para mostrar el nuevo nombre
      messenger.showSnackBar(
        const SnackBar(content: Text('Nombre actualizado')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo actualizar el nombre')),
      );
    }
  }

  // ── Cambiar rol ───────────────────────────────────────────────────────────────

  /// Muestra una advertencia antes de ir a RoleSelectionScreen.
  /// El cambio de rol ajusta las funcionalidades que ve el usuario.
  Future<void> _showRoleChangeConfirmation() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cambiar rol'),
        content: const Text(
          'Al cambiar tu rol se ajustará la interfaz de la aplicación. '
          '¿Deseas continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _Palette.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Continuar'),
          ),
        ],
      ),
    );

    // Solo navegamos si el usuario confirmó
    if (confirmed == true && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
      );
    }
  }

  // ── Tarjeta de vinculación (tutor) ────────────────────────────────────────────

  /// Card simple que lleva al tutor a TutorVinculacionScreen.
  Widget _buildVinculacionCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const Icon(Icons.people_alt_outlined,
            color: _Palette.accent, size: 28),
        title: const Text('Vincular usuarios',
            style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: const Text(
            'Genera códigos y gestiona usuarios vinculados',
            style: TextStyle(color: _Palette.textMuted, fontSize: 14)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TutorVinculacionScreen()),
        ),
      ),
    );
  }

  // ── Tarjeta de vinculación (usuario/paciente) ─────────────────────────────────

  /// Card reactiva que muestra el estado de vinculación del usuario.
  ///
  /// Usa un StreamBuilder para escuchar si el usuario tiene tutor vinculado.
  /// - Si tiene tutor: muestra el nombre y email del tutor con check verde.
  /// - Si no tiene: muestra botón "Vincular" que abre el diálogo de código.
  Widget _buildVinculacionUsuarioCard() {
    return StreamBuilder<Map<String, dynamic>?>(
      // getLinkedTutorStream: emite el doc del tutor o null si no hay vinculación
      stream: AuthService.getLinkedTutorStream(),
      builder: (context, snapshot) {
        final tutor   = snapshot.data;
        final loading = snapshot.connectionState == ConnectionState.waiting;

        // Cargando: spinner dentro de la tarjeta
        if (loading) {
          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const ListTile(
              leading: SizedBox(
                width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              title: Text('Verificando vinculación...'),
            ),
          );
        }

        // Tutor vinculado: mostramos sus datos
        if (tutor != null) {
          final name  = tutor['name']  as String? ?? 'Tutor';
          final email = tutor['email'] as String? ?? '';

          return Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: const Icon(Icons.person_pin_outlined,
                  color: _Palette.accent, size: 28),
              title: const Text('Tutor vinculado',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nombre del tutor en negrita
                  Text(name,
                      style: const TextStyle(
                          color: _Palette.textDark, fontWeight: FontWeight.w500)),
                  // Email del tutor si está disponible
                  if (email.isNotEmpty)
                    Text(email,
                        style: const TextStyle(
                            color: _Palette.textMuted, fontSize: 12)),
                ],
              ),
              // Check verde: indica que la vinculación está activa
              trailing: const Icon(Icons.check_circle_rounded,
                  color: Colors.green, size: 24),
            ),
          );
        }

        // Sin tutor: botón para iniciar el flujo de vinculación
        return Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: const Icon(Icons.link_outlined,
                color: _Palette.accent, size: 28),
            title: const Text('Vincular con tutor',
                style: TextStyle(fontWeight: FontWeight.w600)),
            subtitle: const Text(
                'Ingresa el código que te dio tu tutor',
                style: TextStyle(color: _Palette.textMuted, fontSize: 14)),
            trailing: ElevatedButton(
              onPressed: _mostrarDialogoVinculacion,
              style: ElevatedButton.styleFrom(
                backgroundColor: _Palette.accent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Vincular'),
            ),
          ),
        );
      },
    );
  }

  // ── Diálogo de ingreso de código de vinculación ───────────────────────────────

  /// Muestra un diálogo con un TextField de 6 caracteres para ingresar
  /// el código de invitación generado por el tutor.
  Future<void> _mostrarDialogoVinculacion() async {
    final controller = TextEditingController();
    final messenger  = ScaffoldMessenger.of(context);

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Vincular con tutor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ingresa el código de invitación que te dio tu tutor:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters, // Fuerza mayúsculas
              maxLength: 6,  // Los códigos son exactamente de 6 caracteres
              decoration: const InputDecoration(
                hintText: 'Ej: ABC123',
                border: OutlineInputBorder(),
                counterText: '', // Ocultamos el contador de caracteres
              ),
              // Submit en el teclado: equivale a tocar "Verificar"
              onSubmitted: (_) async {
                final code = controller.text.trim().toUpperCase();
                if (code.length < 6) return; // Guard: código incompleto
                Navigator.of(ctx).pop();     // Cerramos el diálogo primero
                await _vincularConTutor(code, messenger);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = controller.text.trim().toUpperCase();
              if (code.length < 6) return; // No enviamos si el código está incompleto
              Navigator.of(ctx).pop();
              await _vincularConTutor(code, messenger);
            },
            child: const Text('Verificar'),
          ),
        ],
      ),
    );

    // Liberamos el controller al cerrar el diálogo
    controller.dispose();
  }

  // ── Proceso de vinculación con tutor ─────────────────────────────────────────

  /// Valida el código de invitación y, si es válido, vincula al usuario con el tutor.
  ///
  /// Pasos:
  ///   1. AuthService.validateInvitationCode(code) — verifica en Firestore
  ///      invitation_codes/{code} que sea válido y no esté expirado.
  ///   2. Muestra diálogo de confirmación con el nombre del tutor.
  ///   3. AuthService.acceptInvitationCode(code) — batch write que:
  ///      a) Añade el UID del paciente al array linkedPatients del tutor.
  ///      b) Guarda el tutorId en el documento del paciente.
  ///      c) Marca el código como isUsed: true.
  Future<void> _vincularConTutor(
      String code, ScaffoldMessengerState messenger) async {
    try {
      // Paso 1: validamos el código en Firestore
      final validation = await AuthService.validateInvitationCode(code);

      if (!mounted) return;

      // Código inválido, expirado o ya usado: mostramos el motivo
      if (validation == null || validation['valid'] != true) {
        messenger.showSnackBar(SnackBar(
          content: Text(validation?['reason'] ?? 'Código inválido'),
          backgroundColor: Colors.redAccent,
        ));
        return;
      }

      // Extraemos el nombre del tutor para mostrarlo en la confirmación
      final tutorName = validation['tutorName'] as String? ?? 'tu tutor';

      // Paso 2: diálogo de confirmación antes de hacer la escritura
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Confirmar vinculación'),
          content: Text('¿Deseas vincularte con $tutorName?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Vincular'),
            ),
          ],
        ),
      );

      if (confirmed != true || !mounted) return;

      // Paso 3: batch write atómico en Firestore
      await AuthService.acceptInvitationCode(code);

      if (mounted) {
        messenger.showSnackBar(const SnackBar(
          content: Text('¡Vinculado con éxito!'),
          backgroundColor: Colors.green,
        ));
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.redAccent,
        ));
      }
    }
  }

  // ── Tile de personalización de pantallas ──────────────────────────────────────

  /// Tile que navega a PantallasConfigScreen para activar/desactivar pestañas.
  Widget _buildPantallasNavTile() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const Icon(Icons.tune_rounded, color: _Palette.accent, size: 28),
        title: const Text('Personalización de pantalla',
            style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: const Text('Elige qué pestañas ver en la app',
            style: TextStyle(color: _Palette.textMuted, fontSize: 14)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const PantallasConfigScreen()),
        ),
      ),
    );
  }

  // ── Card de contacto de emergencia ────────────────────────────────────────────

  /// Formulario con dos campos: nombre y teléfono del contacto de emergencia.
  ///
  /// Los campos se pre-llenan desde Firestore pero se pueden editar libremente.
  /// _isEmergencyDirty controla si el botón de guardar está habilitado.
  Widget _buildEmergencyCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Contacto de emergencia',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            // Descripción del propósito del contacto de emergencia
            Text(
              'Número al que llamar en caso de emergencia (opcional).',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),

            // Campo de nombre del contacto
            TextField(
              controller: _emergencyNameController,
              textCapitalization: TextCapitalization.words, // Capitaliza cada palabra
              decoration: const InputDecoration(
                labelText: 'Nombre del contacto (ej: Mamá, Pareja, Amigo)',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) {
                // Marcamos como "sucio" al primer cambio para habilitar el botón
                if (!_isEmergencyDirty) {
                  setState(() => _isEmergencyDirty = true);
                }
              },
            ),
            const SizedBox(height: 12),

            // Campo de teléfono del contacto
            TextField(
              controller: _emergencyPhoneController,
              keyboardType: TextInputType.phone, // Abre el teclado numérico
              decoration: const InputDecoration(
                labelText: 'Teléfono',
                hintText: 'Ej: +56 9 1234 5678',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) {
                if (!_isEmergencyDirty) {
                  setState(() => _isEmergencyDirty = true);
                }
              },
            ),
            const SizedBox(height: 12),

            // Botón "Guardar" alineado a la derecha
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                // Habilitado solo si hay cambios sin guardar y no se está guardando
                onPressed: _isEmergencyDirty && !_isSavingEmergency
                    ? _saveEmergencyContact
                    : null,
                icon: _isSavingEmergency
                    ? const SizedBox(
                        width: 16, height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: const Text('Guardar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Card de notificaciones ────────────────────────────────────────────────────

  /// Configuración de notificaciones de tareas.
  ///
  /// - Toggle: activa/desactiva las notificaciones globalmente.
  /// - Dropdown: minutos de antelación para el recordatorio por defecto.
  /// - Botones: "Optimizar entrega" y "Probar notificación".
  Widget _buildNotificacionesCard(bool notiTaskEnabled, int? notiOffset) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notificaciones',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Toggle: activa/desactiva las notificaciones de tareas
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: notiTaskEnabled,
              title: const Text('Activar notificaciones de tareas'),
              onChanged: (value) {
                // Escritura directa en Firestore; el StreamBuilder rebuild la UI
                _userDoc.set({'notiTaskEnabled': value}, SetOptions(merge: true));
              },
            ),
            const SizedBox(height: 8),

            // Dropdown: minutos de recordatorio por defecto
            // ValueKey(notiOffset): fuerza rebuild cuando cambia el valor en Firestore
            DropdownButtonFormField<int?>(
              key: ValueKey(notiOffset),
              decoration: const InputDecoration(
                labelText: 'Recordarme antes',
                border: OutlineInputBorder(),
              ),
              initialValue: notiOffset,
              // kReminderOptions: lista de opciones definida en reminder_options.dart
              items: kReminderOptions
                  .map((option) => DropdownMenuItem<int?>(
                        value: option['minutes'] as int?,
                        child: Text(option['label'] as String),
                      ))
                  .toList(),
              onChanged: (value) {
                // Guardamos el offset en minutos en Firestore
                _userDoc.set(
                  {'notiTaskDefaultOffsetMinutes': value},
                  SetOptions(merge: true),
                );
              },
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Fila de dos botones de diagnóstico/prueba
            Row(
              children: [
                // Botón 1: solicita permisos de notificación, batería y alarma exacta
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await NotificationService.ensureDeviceCanDeliverNotifications();
                      if (!context.mounted) return;
                      // Mensaje informativo tras solicitar los permisos
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Revisa permisos del sistema y optimización '
                            'de batería si usas Xiaomi/HyperOS.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.settings_suggest, size: 16),
                    label: const Text('Optimizar entrega',
                        style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),

                // Botón 2: muestra una notificación de prueba y diagnóstica el resultado
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);

                      // En web no hay notificaciones locales
                      if (kIsWeb) {
                        messenger.showSnackBar(const SnackBar(
                          content: Text('Modo Web: Prueba en tu celular.'),
                          behavior: SnackBarBehavior.floating,
                        ));
                        return;
                      }

                      // Enviamos la notificación de prueba con previsualización de sonido
                      final result = await NotificationService.showTestNotification(
                        playPreviewSound: true,
                      );

                      if (!mounted) return;

                      if (!result.notificationSent) {
                        // La notificación no se pudo enviar: mostramos el motivo
                        final String msg;
                        switch (result.failure) {
                          case NotificationTestFailure.permissionDenied:
                            msg = 'Debes aceptar el permiso de notificaciones.';
                          case NotificationTestFailure.permissionPermanentlyDenied:
                            msg = 'Activa las notificaciones desde Ajustes.';
                          default:
                            msg = result.errorDescription != null
                                ? 'No se pudo enviar: ${result.errorDescription}'
                                : 'No se pudo enviar. Revisa los permisos.';
                        }
                        messenger.showSnackBar(SnackBar(content: Text(msg)));
                        return;
                      }

                      // Notificación enviada: mostramos si se reprodujo el sonido
                      final base = result.previewSoundPlayed
                          ? 'Notificación enviada con sonido.'
                          : 'Notificación enviada. Activa el volumen.';
                      final hint = result.usedFallbackSound
                          ? '\nSe usó el sonido por defecto.'
                          : '';
                      messenger.showSnackBar(SnackBar(content: Text(base + hint)));
                    },
                    icon: const Icon(Icons.notifications_active, size: 16),
                    label: const Text('Probar notificación',
                        style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Card de configuración del modo Foco (Pomodoro) ────────────────────────────

  /// Configuración de sonido, vibración y estadísticas del Pomodoro.
  Widget _buildFocoCard(
    bool soundEnabled,
    bool vibrationEnabled,
    String sound,
    int focusSessions,
    int totalFocusMinutes,
    int points,
    int streak,
  ) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Modo Foco',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),

            // Toggle: sonido al terminar el Pomodoro
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Sonido al terminar pomodoro'),
              value: soundEnabled,
              onChanged: (value) {
                _userDoc.set(
                    {'pomodoroSoundEnabled': value}, SetOptions(merge: true));
              },
            ),

            // Toggle: vibración al terminar el Pomodoro
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Vibración al terminar pomodoro'),
              value: vibrationEnabled,
              onChanged: (value) {
                _userDoc.set(
                    {'pomodoroVibrationEnabled': value}, SetOptions(merge: true));
              },
            ),
            const SizedBox(height: 8),

            // Dropdown de selección del sonido del Pomodoro.
            // ValueKey(sound) fuerza rebuild cuando cambia el valor en Firestore.
            DropdownButtonFormField<String>(
              key: ValueKey(sound),
              decoration: const InputDecoration(
                labelText: 'Sonido del Pomodoro',
                border: OutlineInputBorder(),
              ),
              initialValue: sound,
              items: _pomodoroSoundOptions
                  .map((option) => DropdownMenuItem<String>(
                        value: option['key'],
                        child: Text(option['label'] ?? ''),
                      ))
                  .toList(),
              // Disabled si el sonido está apagado (no tiene sentido elegir sonido)
              onChanged: soundEnabled
                  ? (value) {
                      if (value == null) return;
                      _userDoc.set(
                          {'pomodoroSound': value}, SetOptions(merge: true));
                    }
                  : null,
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),

            // Sección de estadísticas de sesiones de foco
            const Text(
              'Registros',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _Palette.textMuted),
            ),
            const SizedBox(height: 8),

            // Filas de estadísticas (icono + etiqueta + valor)
            _buildStatRow(Icons.self_improvement, 'Sesiones completadas', '$focusSessions'),
            _buildStatRow(Icons.timer, 'Minutos de foco', '$totalFocusMinutes'),
            _buildStatRow(Icons.star, 'Puntos actuales', '$points'),
            _buildStatRow(Icons.local_fire_department, 'Racha actual', '$streak días'),
          ],
        ),
      ),
    );
  }

  // ── Fila de estadística ───────────────────────────────────────────────────────

  /// Fila con icono, etiqueta a la izquierda y valor a la derecha.
  Widget _buildStatRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _Palette.textMuted),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(fontSize: 13, color: _Palette.textDark)),
          const Spacer(), // Empuja el valor al lado derecho
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _Palette.textDark)),
        ],
      ),
    );
  }

  // ── Card de tour de bienvenida ────────────────────────────────────────────────

  Widget _buildTourCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const Icon(Icons.tour_rounded, color: _Palette.accent),
        title: const Text(
          'Ver tour de bienvenida',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: const Text(
          'Reinicia la guía de Inicio, Pictogramas y Tutor',
        ),
        onTap: () async {
          await TourService.resetAll();
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Tour reiniciado — vuelve a Inicio para verlo otra vez',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );

          final navigator = Navigator.of(context);
          if (navigator.canPop()) {
            navigator.pop();
          }
        },
      ),
    );
  }

  // ── Card de cerrar sesión ─────────────────────────────────────────────────────

  /// Tile rojo que abre el diálogo de confirmación de cierre de sesión.
  Widget _buildLogoutCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: const Icon(Icons.logout, color: Colors.redAccent),
        title: const Text(
          'Cerrar sesión',
          style: TextStyle(
              color: Colors.redAccent, fontWeight: FontWeight.w600),
        ),
        onTap: _confirmLogout, // Siempre pide confirmación antes de cerrar sesión
      ),
    );
  }

  /// Diálogo de confirmación antes de llamar a [_handleLogout].
  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cerrar sesión'),
        content: const Text('¿Estás seguro de que quieres cerrar sesión?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cerrar sesión'),
          ),
        ],
      ),
    );
    // Solo procedemos si el usuario confirmó explícitamente
    if (confirmed == true && mounted) _handleLogout();
  }

  // ── Card de backup y restauración ────────────────────────────────────────────

  /// Muestra el estado del último backup y los botones de sincronización.
  Widget _buildBackupCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado: icono de nube + título
            const Row(
              children: [
                Icon(Icons.cloud_outlined, color: _Palette.primary, size: 22),
                SizedBox(width: 10),
                Text(
                  'Respaldo y Seguridad',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Descripción del mecanismo de backup
            Text(
              'Tus pictogramas y configuraciones se guardan en tu Google Drive personal. Sin costes de servidor.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),

            // Fecha del último sync (solo si se ha hecho al menos un backup)
            if (_lastSync != null) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.access_time,
                      size: 14, color: _Palette.textMuted),
                  const SizedBox(width: 6),
                  Text(
                    'Última sincronización: ${_formatSyncDate(_lastSync!)}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: _Palette.textMuted,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],

            const SizedBox(height: 16),

            // Fila de dos botones: Sincronizar y Restaurar
            Row(
              children: [
                // Botón principal (azul): sube los datos a Drive
                Expanded(
                  child: _buildBackupButton(
                    label: 'Sincronizar con Google Drive',
                    icon: Icons.cloud_upload_outlined,
                    // null durante _isBackingUp para evitar operaciones paralelas
                    onPressed: _isBackingUp ? null : _handleBackup,
                  ),
                ),
                const SizedBox(width: 10),

                // Botón secundario (outlined): descarga datos desde Drive
                Expanded(
                  child: _buildBackupButton(
                    label: 'Restaurar desde Drive',
                    icon: Icons.cloud_download_outlined,
                    onPressed: _isBackingUp ? null : _handleRestore,
                    isSecondary: true, // Outlined style
                  ),
                ),
              ],
            ),

            // Spinner visible durante backup/restauración
            if (_isBackingUp) ...[
              const SizedBox(height: 16),
              Center(
                child: SizedBox(
                  width: 48, height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Spinner circular (determinado si hay progreso, indeterminado si no)
                      SizedBox(
                        width: 48, height: 48,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          value: _backupProgress, // null = indeterminado
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            _Palette.primary,
                          ),
                        ),
                      ),
                      // Icono de sincronización en el centro del spinner
                      const Icon(Icons.sync, size: 20, color: _Palette.primary),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Botón de backup con dos estilos: primario (relleno) y secundario (outlined).
  Widget _buildBackupButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    bool isSecondary = false, // false = primario (azul relleno), true = outlined
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        // Primario: fondo azul; secundario: blanco con borde
        backgroundColor: isSecondary ? _Palette.surface  : _Palette.primary,
        foregroundColor: isSecondary ? _Palette.primary  : Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          // Borde azul suave solo en el botón secundario
          side: isSecondary
              ? BorderSide(color: _Palette.primary.withValues(alpha: 0.3))
              : BorderSide.none,
        ),
        elevation: isSecondary ? 0 : 2, // Sin sombra en el secundario
      ),
    );
  }

  // ── Formateo de fecha de sync ─────────────────────────────────────────────────

  /// Formatea la fecha del último backup en texto relativo o absoluto.
  ///
  /// - < 1 minuto: "Justo ahora"
  /// - < 1 hora: "Hace X min"
  /// - < 24 horas: "Hace Xh"
  /// - Más antiguo: "DD/MM/YYYY HH:MM" con intl
  String _formatSyncDate(DateTime date) {
    final now  = DateTime.now();
    final diff = now.difference(date); // Duración desde la fecha hasta ahora

    if (diff.inMinutes < 1)  return 'Justo ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24)   return 'Hace ${diff.inHours}h';

    // Formato absoluto con intl (ej: "01/06/2025 14:30")
    return DateFormat('dd/MM/yyyy HH:mm', 'es_ES').format(date);
  }

  // ── Handler de backup ─────────────────────────────────────────────────────────

  /// Inicia el backup a Google Drive y actualiza el estado de _lastSync.
  Future<void> _handleBackup() async {
    if (!mounted) return;

    setState(() {
      _isBackingUp     = true;
      _backupProgress  = null; // Spinner indeterminado
    });

    final messenger = ScaffoldMessenger.of(context);

    try {
      // Llamamos al servicio de backup (sube JSON de Firestore + pictogramas)
      final result = await GoogleDriveService.instance.backupToDrive();

      if (!mounted) return;

      setState(() {
        _isBackingUp = false;
        // Si el backup fue exitoso, actualizamos la fecha mostrada
        if (result.success) {
          _lastSync = result.timestamp;
        }
      });

      // Snackbar verde/rojo según el resultado
      messenger.showSnackBar(SnackBar(
        content: Text(result.message),
        backgroundColor: result.success
            ? Colors.green.shade700
            : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));

    } catch (e) {
      if (!mounted) return;
      setState(() => _isBackingUp = false);
      messenger.showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  // ── Handler de restauración ───────────────────────────────────────────────────

  /// Inicia la restauración desde Google Drive.
  ///
  /// Si la nube tiene datos más recientes, muestra un diálogo de confirmación
  /// antes de sobreescribir la configuración local.
  Future<void> _handleRestore() async {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    try {
      // Verificamos si la versión en la nube es más reciente que la local
      final isCloudNewer =
          await GoogleDriveService.instance.isCloudNewerThanLocal();

      if (!mounted) return;

      // Si la nube es más nueva, pedimos confirmación antes de restaurar
      if (isCloudNewer) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20)),
            title: const Text('Actualizar desde la Nube'),
            content: const Text(
              'Se encontró una versión más reciente en Google Drive. '
              '¿Deseas restaurar tu configuración y pictogramas?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _Palette.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Restaurar'),
              ),
            ],
          ),
        );

        // Si el usuario canceló el diálogo, salimos sin restaurar
        if (confirm != true || !mounted) return;
      }

      setState(() {
        _isBackingUp    = true;
        _backupProgress = null; // Spinner indeterminado durante la restauración
      });

      // force: true → restauramos incluso si la versión local es más reciente
      // (el usuario ya confirmó en el diálogo anterior)
      final result =
          await GoogleDriveService.instance.restoreFromDrive(force: true);

      if (!mounted) return;

      setState(() {
        _isBackingUp = false;
        // Si la restauración fue exitosa, actualizamos la fecha de sync
        if (result.success) {
          _lastSync = DateTime.now();
        }
      });

      messenger.showSnackBar(SnackBar(
        content: Text(result.message),
        backgroundColor: result.success
            ? Colors.green.shade700
            : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));

    } catch (e) {
      if (!mounted) return;
      setState(() => _isBackingUp = false);
      messenger.showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }
}
