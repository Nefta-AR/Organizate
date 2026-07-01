// ============================================================
// lib/features/tutor_dashboard/screens/perfil_screen.dart
// ============================================================
// Pantalla de perfil simplificada del usuario (vista secundaria).
//
// Muestra:
//   - Avatar (foto de perfil o imagen de asset seleccionada).
//   - Nombre, email y chip de rol.
//   - Tarjetas de estadísticas: puntos y racha.
//   - Botón para cambiar la foto de perfil (Gallery → Firebase Storage).
//
// Esta pantalla es más sencilla que SettingsScreen: no tiene
// ajustes de notificaciones, backup, ni contacto de emergencia.
// Se usa como vista de perfil rápido desde ciertas rutas.
//
// [_handlePhotoUpload]: sube la imagen a `user_photos/{uid}/profile.jpg`
//   en Firebase Storage y guarda la URL en Firestore (campo `photoURL`).
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// ── Paleta de colores interna ─────────────────────────────────────────────────
// Definida como clase privada para mantener los tokens semánticos en un solo lugar.
class _Palette {
  _Palette._(); // Constructor privado: clase no instanciable, solo constantes
  static const background = Color(0xFFF5F7FA); // Gris azulado muy claro
  static const primary = Color(0xFF4A90E2);    // Azul medio (acento principal)
  static const surface = Colors.white;          // Fondo de tarjetas
  static const textDark = Color(0xFF2D3748);   // Texto principal (casi negro)
  static const textMuted = Color(0xFF718096);  // Texto secundario (gris)
}

// Radio de borde para tarjetas y contenedores
const double _kRadius = 14;

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  // Controla si hay una subida de foto en curso (para mostrar el spinner)
  bool _isUploadingPhoto = false;

  // Acceso rápido al usuario autenticado actual de Firebase Auth
  User? get _currentUser => FirebaseAuth.instance.currentUser;

  // Referencia al documento Firestore del usuario actual
  // (campos: name, role, avatar, photoURL, points, streak, etc.)
  DocumentReference<Map<String, dynamic>> get _userDoc =>
      FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid);

  // ── Subida de foto de perfil ──────────────────────────────────────────────

  Future<void> _handlePhotoUpload() async {
    final picker = ImagePicker();

    // Abrimos la galería del dispositivo
    // imageQuality: 70 reduce el tamaño del archivo antes de subirlo
    // maxWidth: 512 limita la resolución (suficiente para un avatar circular)
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 512,
    );

    // Si el usuario canceló la selección o el widget fue desmontado, no hacemos nada
    if (picked == null || !mounted) return;

    // Activamos el spinner sobre el avatar
    setState(() => _isUploadingPhoto = true);

    // Capturamos el messenger antes del await para evitar usarlo
    // después de un posible desmontaje del widget
    final messenger = ScaffoldMessenger.of(context);

    try {
      final uid = _currentUser!.uid;

      // Ruta en Firebase Storage: user_photos/{uid}/profile.jpg
      // Al usar siempre el mismo nombre, cada subida reemplaza la anterior
      final ref =
          FirebaseStorage.instance.ref().child('user_photos/$uid/profile.jpg');

      // Leemos los bytes del archivo temporal (funciona en iOS y Android)
      final bytes = await picked.readAsBytes();

      // Subimos los bytes con Content-Type correcto para que el navegador
      // pueda mostrar la imagen desde la URL sin problemas de MIME type
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));

      // Obtenemos la URL pública de descarga para mostrarla como avatar
      final url = await ref.getDownloadURL();

      // Guardamos la URL en Firestore (merge: true para no sobreescribir otros campos)
      await _userDoc.set({'photoURL': url}, SetOptions(merge: true));

      // Confirmamos al usuario que el cambio fue exitoso
      if (mounted) {
        messenger.showSnackBar(const SnackBar(
          content: Text('Foto de perfil actualizada.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } on FirebaseException catch (e) {
      // Error específico de Firebase (permisos, cuota, network): mostramos el código
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content:
              Text('[${e.code}] ${e.message ?? "Error de Firebase Storage"}'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6), // Más tiempo para que el usuario lo lea
        ));
      }
    } catch (_) {
      // Error genérico (permisos del sistema, archivo no legible, etc.)
      if (mounted) {
        messenger.showSnackBar(const SnackBar(
          content: Text('No se pudo subir la foto. Intenta de nuevo.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      // Siempre apagamos el spinner, incluso si hubo un error
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  // ── Resolución del proveedor de imagen del avatar ──────────────────────────

  // Prioridad: foto subida por el usuario (URL de Storage) > asset de avatar
  // Si ninguno está disponible, retorna null → se muestra el icono de persona
  ImageProvider? _resolvePhoto(String? photoUrl, String? avatar) {
    if (photoUrl != null && photoUrl.isNotEmpty) return NetworkImage(photoUrl);
    if (avatar != null && avatar.isNotEmpty) {
      return AssetImage('assets/avatars/$avatar.png');
    }
    return null; // Sin imagen: el CircleAvatar mostrará el icono child
  }

  // Capitaliza la primera letra del rol para mostrarlo legible en el chip
  // Ejemplo: 'tutor' → 'Tutor', 'paciente' → 'Paciente'
  String _capitalizeRole(String role) {
    if (role.isEmpty) return '';
    return '${role[0].toUpperCase()}${role.substring(1)}';
  }

  @override
  Widget build(BuildContext context) {
    // Seguridad: si por alguna razón no hay usuario autenticado, mostramos spinner
    // (no debería ocurrir porque AuthGate protege esta pantalla)
    if (_currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: _Palette.background, // Fondo gris azulado

      // AppBar con fondo del mismo color que el Scaffold (seamless)
      appBar: AppBar(
        backgroundColor: _Palette.background,
        elevation: 0, // Sin sombra para diseño plano
        iconTheme: const IconThemeData(color: _Palette.primary),
        title: const Text(
          'Mi perfil',
          style: TextStyle(
            color: _Palette.primary,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),

      // ── Datos del perfil en tiempo real via StreamBuilder ─────────────────
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _userDoc.snapshots(),
        builder: (context, snapshot) {
          // Cargando: spinner centrado
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // Error de Firestore: mensaje genérico al usuario
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar el perfil.'));
          }

          // Extraemos los datos del documento; {} si el doc no existe aún
          final data = snapshot.data?.data() ?? {};

          // Nombre: priorizamos displayName de Firebase Auth (establecido en Google Sign-In
          // o en la creación de cuenta), luego el campo 'name' de Firestore
          final displayName = _currentUser?.displayName;
          final firestoreName = data['name'] as String?;
          final name =
              (displayName?.isNotEmpty == true ? displayName : firestoreName) ??
                  'Usuario de Simple';

          // Email del usuario (de Auth o de Firestore como fallback)
          final email = _currentUser?.email ?? (data['email'] as String?) ?? '';

          // Rol del usuario: 'paciente', 'tutor', etc.
          final role = (data['role'] as String?) ?? '';

          // photoURL: primero en Firestore (puede venir de Storage), luego de Auth
          // (Google Sign-In guarda la foto de Google en Auth.photoURL)
          final photoUrl =
              data['photoURL'] as String? ?? _currentUser?.photoURL;

          // Nombre del asset de avatar (ej: 'zorro' → assets/avatars/zorro.png)
          final avatar = data['avatar'] as String?;

          // Estadísticas del usuario con conversión segura num→int
          final points = (data['points'] as num?)?.toInt() ?? 0;
          final streak = (data['streak'] as num?)?.toInt() ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ── Avatar con botón de cámara superpuesto ─────────────────
                GestureDetector(
                  // Deshabilitar el tap durante la subida para evitar subidas paralelas
                  onTap: _isUploadingPhoto ? null : _handlePhotoUpload,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Círculo con foto de perfil o icono de persona
                      CircleAvatar(
                        radius: 54,
                        backgroundColor: const Color(0xFFE8EEF5), // Azul muy claro
                        backgroundImage: _resolvePhoto(photoUrl, avatar),
                        // child solo se muestra si backgroundImage es null
                        child: (photoUrl == null || photoUrl.isEmpty) &&
                                (avatar == null || avatar.isEmpty)
                            ? const Icon(Icons.person,
                                size: 48, color: _Palette.textMuted)
                            : null,
                      ),

                      // Overlay semitransparente oscuro + spinner mientras se sube
                      if (_isUploadingPhoto)
                        Container(
                          width: 108, height: 108,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.35),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(30),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          ),
                        ),

                      // Botón de cámara en la esquina inferior derecha del avatar
                      // Solo visible cuando no hay subida en curso
                      if (!_isUploadingPhoto)
                        Positioned(
                          bottom: 2, right: 2,
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _Palette.primary,
                              // Borde blanco para separarlo visualmente del avatar
                              border: Border.all(
                                  color: _Palette.background, width: 2.5),
                            ),
                            child: const Icon(Icons.camera_alt_rounded,
                                size: 14, color: Colors.white),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),

                // ── Nombre del usuario ──────────────────────────────────────
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: _Palette.textDark,
                  ),
                ),
                const SizedBox(height: 5),

                // Email en texto secundario
                Text(
                  email,
                  style:
                      const TextStyle(fontSize: 14, color: _Palette.textMuted),
                ),

                // Chip de rol (solo visible si el rol no está vacío)
                if (role.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      // Fondo azul muy tenue (10% de opacidad)
                      color: _Palette.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20), // Cápsula redondeada
                    ),
                    child: Text(
                      _capitalizeRole(role),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _Palette.primary,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),

                // ── Tarjetas de estadísticas (puntos y racha) ───────────────
                // Row de dos _StatCard que se expanden proporcionalmente
                Row(children: [
                  _StatCard(
                    label: 'Puntos',
                    value: '$points',
                    icon: Icons.star_rounded,
                    color: const Color(0xFFD4A853), // Dorado
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Racha',
                    value: '$streak días',
                    icon: Icons.local_fire_department_rounded,
                    color: const Color(0xFFBF8060), // Naranja tostado
                  ),
                ]),
                const SizedBox(height: 24),

                // ── Botón de cambio de foto ─────────────────────────────────
                // Botón outlined de ancho completo para acción secundaria
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    // Deshabilitar durante la subida (mismo guard que el avatar)
                    onPressed: _isUploadingPhoto ? null : _handlePhotoUpload,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _Palette.primary,
                      side: const BorderSide(color: _Palette.primary, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_kRadius),
                      ),
                    ),
                    icon: const Icon(Icons.photo_library_outlined, size: 20),
                    label: const Text(
                      'Cambiar foto de perfil',
                      style:
                          TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Widget de tarjeta de estadística ─────────────────────────────────────────
// Widget privado reutilizable para mostrar un número con icono y etiqueta.
// Se usa para 'Puntos' y 'Racha' en el perfil.

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,  // Etiqueta descriptiva (ej: "Puntos")
    required this.value,  // Valor a mostrar (ej: "1200" o "5 días")
    required this.icon,   // Icono representativo
    required this.color,  // Color del icono
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    // Expanded para que ambas tarjetas tomen el mismo ancho en la Row
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color: _Palette.surface, // Fondo blanco para contraste con el fondo gris
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04), // Sombra muy suave
              blurRadius: 8,
              offset: const Offset(0, 2), // Sombra desplazada hacia abajo
            ),
          ],
        ),
        child: Row(children: [
          // Icono de la estadística
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Etiqueta en pequeño (ej: "Puntos")
              Text(label,
                  style:
                      const TextStyle(fontSize: 12, color: _Palette.textMuted)),
              // Valor grande y en negrita (ej: "1200")
              Text(value,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _Palette.textDark,
                  )),
            ],
          ),
        ]),
      ),
    );
  }
}
