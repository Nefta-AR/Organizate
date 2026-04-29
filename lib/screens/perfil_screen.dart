import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Paleta Calma — Simple (misma base que login_screen.dart).
// ─────────────────────────────────────────────────────────────────────────────
class _Palette {
  _Palette._();
  static const background = Color(0xFFF5F7FA);
  static const primary    = Color(0xFF4A90E2);
  static const surface    = Colors.white;
  static const textDark   = Color(0xFF2D3748);
  static const textMuted  = Color(0xFF718096);
}

const double _kRadius = 14;

// ─────────────────────────────────────────────────────────────────────────────
class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> {
  bool _isUploadingPhoto = false;

  User? get _currentUser => FirebaseAuth.instance.currentUser;

  DocumentReference<Map<String, dynamic>> get _userDoc =>
      FirebaseFirestore.instance
          .collection('users')
          .doc(_currentUser!.uid);

  // ── FOTO DE PERFIL ─────────────────────────────────────────────────────────
  // GestureDetector en el CircleAvatar dispara este método.
  // Usa image_picker para galería y firebase_storage para persistencia.
  Future<void> _handlePhotoUpload() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source      : ImageSource.gallery,
      imageQuality: 70,
      maxWidth    : 512,
    );
    if (picked == null || !mounted) return;

    setState(() => _isUploadingPhoto = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final uid = _currentUser!.uid;
      final ref = FirebaseStorage.instance
          .ref()
          .child('user_photos/$uid/profile.jpg');

      final bytes = await picked.readAsBytes();
      await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
      final url = await ref.getDownloadURL();

      await _userDoc.set({'photoURL': url}, SetOptions(merge: true));

      if (mounted) {
        messenger.showSnackBar(const SnackBar(
          content : Text('Foto de perfil actualizada.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content : Text('[${e.code}] ${e.message ?? "Error de Firebase Storage"}'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
        ));
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(const SnackBar(
          content : Text('No se pudo subir la foto. Intenta de nuevo.'),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      // Siempre libera el estado de carga, incluso si hay error.
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  // Resuelve la fuente de imagen: foto personalizada > avatar preset > nada.
  ImageProvider? _resolvePhoto(String? photoUrl, String? avatar) {
    if (photoUrl != null && photoUrl.isNotEmpty) return NetworkImage(photoUrl);
    if (avatar   != null && avatar.isNotEmpty) {
      return AssetImage('assets/avatars/$avatar.png');
    }
    return null;
  }

  String _capitalizeRole(String role) {
    if (role.isEmpty) return '';
    return '${role[0].toUpperCase()}${role.substring(1)}';
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_currentUser == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: _Palette.background,
      appBar: AppBar(
        backgroundColor: _Palette.background,
        elevation      : 0,
        iconTheme      : const IconThemeData(color: _Palette.primary),
        title: const Text(
          'Mi perfil',
          style: TextStyle(
            color     : _Palette.primary,
            fontWeight: FontWeight.w600,
            fontSize  : 18,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream : _userDoc.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar el perfil.'));
          }

          final data = snapshot.data?.data() ?? {};

          // ── 4. Nombre dinámico — displayName de FirebaseAuth tiene prioridad ──
          final displayName   = _currentUser?.displayName;
          final firestoreName = data['name'] as String?;
          final name = (displayName?.isNotEmpty == true ? displayName : firestoreName)
              ?? 'Usuario de Simple';

          final email    = _currentUser?.email ?? (data['email'] as String?) ?? '';
          final role     = (data['role'] as String?) ?? '';
          final photoUrl = data['photoURL'] as String? ?? _currentUser?.photoURL;
          final avatar   = data['avatar'] as String?;
          final points   = (data['points'] as num?)?.toInt() ?? 0;
          final streak   = (data['streak'] as num?)?.toInt() ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [

                // ── AVATAR con GestureDetector preparado para image_picker ──
                GestureDetector(
                  onTap: _isUploadingPhoto ? null : _handlePhotoUpload,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius         : 54,
                        backgroundColor: const Color(0xFFE8EEF5),
                        backgroundImage: _resolvePhoto(photoUrl, avatar),
                        child: (photoUrl == null || photoUrl.isEmpty) &&
                                (avatar == null || avatar.isEmpty)
                            ? const Icon(Icons.person,
                                size: 48, color: _Palette.textMuted)
                            : null,
                      ),

                      // Overlay de carga mientras sube la foto.
                      if (_isUploadingPhoto)
                        Container(
                          width : 108, height: 108,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.35),
                          ),
                          child: const Padding(
                            padding: EdgeInsets.all(30),
                            child  : CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color      : Colors.white,
                            ),
                          ),
                        ),

                      // Badge de cámara (visible cuando no está cargando).
                      if (!_isUploadingPhoto)
                        Positioned(
                          bottom: 2, right: 2,
                          child: Container(
                            padding   : const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              shape : BoxShape.circle,
                              color : _Palette.primary,
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

                // ── Nombre ────────────────────────────────────────────────
                Text(
                  name,
                  textAlign: TextAlign.center,
                  style    : const TextStyle(
                    fontSize  : 22,
                    fontWeight: FontWeight.bold,
                    color     : _Palette.textDark,
                  ),
                ),
                const SizedBox(height: 5),

                // ── Correo ────────────────────────────────────────────────
                Text(
                  email,
                  style: const TextStyle(fontSize: 14, color: _Palette.textMuted),
                ),

                // ── Chip de rol ───────────────────────────────────────────
                if (role.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 5),
                    decoration: BoxDecoration(
                      color       : _Palette.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _capitalizeRole(role),
                      style: const TextStyle(
                        fontSize  : 13,
                        fontWeight: FontWeight.w600,
                        color     : _Palette.primary,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 32),

                // ── Estadísticas ──────────────────────────────────────────
                Row(children: [
                  _StatCard(
                    label: 'Puntos',
                    value: '$points',
                    icon : Icons.star_rounded,
                    color: const Color(0xFFD4A853),
                  ),
                  const SizedBox(width: 12),
                  _StatCard(
                    label: 'Racha',
                    value: '$streak días',
                    icon : Icons.local_fire_department_rounded,
                    color: const Color(0xFFBF8060),
                  ),
                ]),
                const SizedBox(height: 24),

                // ── Botón explícito de cambio de foto ─────────────────────
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isUploadingPhoto ? null : _handlePhotoUpload,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _Palette.primary,
                      side   : const BorderSide(color: _Palette.primary, width: 1.5),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape  : RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(_kRadius),
                      ),
                    ),
                    icon : const Icon(Icons.photo_library_outlined, size: 20),
                    label: const Text(
                      'Cambiar foto de perfil',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
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

// ─────────────────────────────────────────────────────────────────────────────
// Tarjeta de estadística individual — widget privado reutilizable.
// ─────────────────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String   label;
  final String   value;
  final IconData icon;
  final Color    color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding   : const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        decoration: BoxDecoration(
          color       : _Palette.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow   : [
            BoxShadow(
              color     : Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset    : const Offset(0, 2),
            ),
          ],
        ),
        child: Row(children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 12, color: _Palette.textMuted)),
              Text(value,
                  style: const TextStyle(
                    fontSize  : 18,
                    fontWeight: FontWeight.bold,
                    color     : _Palette.textDark,
                  )),
            ],
          ),
        ]),
      ),
    );
  }
}
