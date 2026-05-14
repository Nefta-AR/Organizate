// lib/screens/settings_screen.dart

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

class _Palette {
  _Palette._();
  static const background = Color(0xFFF4F6F8);
  static const primary = Color(0xFF607D8B);
  static const surface = Colors.white;
  static const textDark = Color(0xFF37474F);
  static const textMuted = Color(0xFF78909C);
  static const accent = Color(0xFF7EA3BC);
}

class SettingsScreen extends StatefulWidget {
  final bool showNavBar;
  const SettingsScreen({super.key, this.showNavBar = true});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late final DocumentReference<Map<String, dynamic>> _userDoc;
  final _emergencyNameController = TextEditingController();
  final _emergencyPhoneController = TextEditingController();
  bool _isEmergencyDirty = false;
  bool _isSavingEmergency = false;
  bool _isUploadingPhoto = false;
  bool _isBackingUp = false;
  double? _backupProgress;
  DateTime? _lastSync;

  static const List<Map<String, String>> _pomodoroSoundOptions = [
    {'key': 'bell', 'label': 'Campanilla clásica'},
    {'key': 'notificacion1', 'label': 'Sonido Notificación'},
  ];

  static const List<String> _availableAvatars = [
    'emoticon',
    'koala',
    'panda',
    'pinguino',
    'rana',
    'tigre',
    'unicornio',
    'zorro',
  ];

  @override
  void initState() {
    super.initState();
    final uid = FirebaseAuth.instance.currentUser!.uid;
    _userDoc = FirebaseFirestore.instance.collection('users').doc(uid);
    _loadLastSync();
  }

  Future<void> _loadLastSync() async {
    final lastSync = await GoogleDriveService.instance.getLastSyncTime();
    if (mounted) {
      setState(() => _lastSync = lastSync);
    }
  }

  @override
  void dispose() {
    _emergencyNameController.dispose();
    _emergencyPhoneController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
    try {
      await GoogleSignIn().signOut();
    } catch (_) {}
    try {
      await FirebaseAuth.instance.signOut();
    } catch (_) {}
  }

  Future<void> _saveEmergencyContact() async {
    setState(() => _isSavingEmergency = true);
    final messenger = ScaffoldMessenger.of(context);
    final trimmedName = _emergencyNameController.text.trim();
    final trimmedPhone = _emergencyPhoneController.text.trim();
    final payload = <String, dynamic>{
      'phone': FieldValue.delete(),
      'emergencyName': trimmedName.isEmpty ? FieldValue.delete() : trimmedName,
      'emergencyPhone':
          trimmedPhone.isEmpty ? FieldValue.delete() : trimmedPhone,
    };
    try {
      await _userDoc.set(payload, SetOptions(merge: true));
      setState(() => _isEmergencyDirty = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Contacto de emergencia actualizado')),
      );
    } catch (_) {
      messenger.showSnackBar(
        const SnackBar(content: Text('No se pudo guardar el contacto')),
      );
    } finally {
      if (mounted) setState(() => _isSavingEmergency = false);
    }
  }

  Future<void> _uploadProfilePhoto() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
      maxWidth: 512,
    );
    if (picked == null || !mounted) return;

    setState(() => _isUploadingPhoto = true);
    final messenger = ScaffoldMessenger.of(context);

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      final ref = FirebaseStorage.instance.ref('user_photos/$uid/profile.jpg');
      final bytes = await picked.readAsBytes();
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      await ref.putData(bytes, metadata);
      final url = await ref.getDownloadURL();
      await _userDoc.set({'photoURL': url}, SetOptions(merge: true));
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Foto de perfil actualizada')),
        );
      }
    } on FirebaseException catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content:
              Text('[${e.code}] ${e.message ?? "Error de Firebase Storage"}'),
          duration: const Duration(seconds: 6),
        ));
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(SnackBar(
          content: Text('Error inesperado: $e'),
          duration: const Duration(seconds: 6),
        ));
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

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
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: _Palette.accent),
                title: const Text('Subir foto de galería',
                    style: TextStyle(color: _Palette.textDark)),
                onTap: () {
                  Navigator.pop(ctx);
                  _uploadProfilePhoto();
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.face_outlined, color: _Palette.accent),
                title: const Text('Elegir avatar prediseñado',
                    style: TextStyle(color: _Palette.textDark)),
                onTap: () {
                  Navigator.pop(ctx);
                  _showAvatarPicker(currentAvatar);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showAvatarPicker(String? currentAvatar) async {
    final messenger = ScaffoldMessenger.of(context);
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
              shrinkWrap: true,
              itemCount: _availableAvatars.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                final avatarName = _availableAvatars[index];
                final isSelected = avatarName == currentAvatar;
                return GestureDetector(
                  onTap: () => Navigator.of(context).pop(avatarName),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: isSelected
                                ? _Palette.accent.withValues(alpha: 0.15)
                                : Colors.grey.shade100,
                            backgroundImage:
                                AssetImage('assets/avatars/$avatarName.png'),
                          ),
                          if (isSelected)
                            Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _Palette.accent.withValues(alpha: 0.4),
                              ),
                              child: const Icon(Icons.check,
                                  color: Colors.white, size: 22),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        avatarName,
                        style: const TextStyle(
                            fontSize: 11, color: _Palette.textMuted),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );

    if (selected != null) {
      try {
        await _userDoc.set({'avatar': selected}, SetOptions(merge: true));
        if (mounted) setState(() {});
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

  ImageProvider? _resolveAvatar(String? photoUrl, String? avatar) {
    if (photoUrl != null && photoUrl.isNotEmpty) return NetworkImage(photoUrl);
    if (avatar != null && avatar.isNotEmpty) {
      return AssetImage('assets/avatars/$avatar.png');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.background,
      bottomNavigationBar: widget.showNavBar
          ? const CustomNavBar(initialIndex: 3)
          : null,
      appBar: AppBar(
        backgroundColor: _Palette.background,
        elevation: 0,
        title: const Text(
          'Perfil y configuración',
          style: TextStyle(
            color: _Palette.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _userDoc.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              !snapshot.hasData ||
              snapshot.data?.data() == null) {
            return const Center(child: Text('No se pudo cargar tu perfil.'));
          }

          final data = snapshot.data!.data()!;
          final authUser = FirebaseAuth.instance.currentUser;
          final displayName = authUser?.displayName;
          final firestoreName = data['name'] as String?;
          final name =
              (displayName?.isNotEmpty == true ? displayName : firestoreName) ??
                  'Usuario';
          final email = authUser?.email ?? (data['email'] as String?) ?? '';
          final photoUrl = data['photoURL'] as String? ?? authUser?.photoURL;
          final avatar = data['avatar'] as String?;

          final emergencyName = (data['emergencyName'] as String?) ?? '';
          final emergencyPhone = (data['emergencyPhone'] as String?) ??
              (data['phone'] as String?) ??
              '';

          final notiTaskEnabled = (data['notiTaskEnabled'] as bool?) ?? true;
          final hasDefaultReminderKey =
              data.containsKey('notiTaskDefaultOffsetMinutes');
          final notiOffset = hasDefaultReminderKey
              ? (data['notiTaskDefaultOffsetMinutes'] as num?)?.toInt()
              : kDefaultReminderMinutes;

          final pomodoroSoundEnabled =
              (data['pomodoroSoundEnabled'] as bool?) ?? true;
          final pomodoroVibrationEnabled =
              (data['pomodoroVibrationEnabled'] as bool?) ?? false;
          final pomodoroSoundRaw = (data['pomodoroSound'] as String?) ?? 'bell';
          final pomodoroSound =
              _pomodoroSoundOptions.any((o) => o['key'] == pomodoroSoundRaw)
                  ? pomodoroSoundRaw
                  : _pomodoroSoundOptions.first['key']!;

          final role = (data['role'] as String?) ?? '';
          final points = (data['points'] as num?)?.toInt() ?? 0;
          final streak = (data['streak'] as num?)?.toInt() ?? 0;
          final focusSessions =
              (data['focusSessionsCompleted'] as num?)?.toInt() ?? 0;
          final totalFocusMinutes =
              (data['totalFocusMinutes'] as num?)?.toInt() ?? 0;

          if (!_isEmergencyDirty) {
            _emergencyNameController.text = emergencyName;
            _emergencyPhoneController.text = emergencyPhone;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProfileCard(name, email, photoUrl, avatar),
                const SizedBox(height: 16),
                _buildRoleCard(role),
                const SizedBox(height: 16),
                if (role == 'tutor') ...[
                  _buildVinculacionCard(),
                  const SizedBox(height: 16),
                ],
                if (role == 'paciente_tea' || role == 'paciente_tdah') ...[
                  _buildVinculacionPacienteCard(),
                  const SizedBox(height: 16),
                ],
                _buildEmergencyCard(),
                const SizedBox(height: 16),
                _buildNotificacionesCard(notiTaskEnabled, notiOffset),
                const SizedBox(height: 16),
                if (role != 'paciente_tea') ...[
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
                _buildBackupCard(),
                const SizedBox(height: 16),
                _buildLogoutCard(),
                const SizedBox(height: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileCard(
      String name, String email, String? photoUrl, String? avatar) {
    return GestureDetector(
      onTap: _isUploadingPhoto ? null : () => _showPhotoOptions(avatar),
      child: Container(
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
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                CircleAvatar(
                  radius: 38,
                  backgroundColor: const Color(0xFFE8EEF2),
                  backgroundImage: _resolveAvatar(photoUrl, avatar),
                  child: (photoUrl == null || photoUrl.isEmpty) &&
                          (avatar == null || avatar.isEmpty)
                      ? const Icon(Icons.person,
                          size: 34, color: _Palette.textMuted)
                      : null,
                ),
                if (_isUploadingPhoto)
                  Container(
                    width: 76,
                    height: 76,
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
              ],
            ),
            const SizedBox(width: 18),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: _Palette.textDark,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(email,
                      style: const TextStyle(
                          fontSize: 13, color: _Palette.textMuted)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(Icons.camera_alt_outlined,
                          size: 13,
                          color: _Palette.accent.withValues(alpha: 0.75)),
                      const SizedBox(width: 4),
                      Text(
                        'Toca para cambiar foto o avatar',
                        style: TextStyle(
                          fontSize: 11,
                          color: _Palette.accent.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVinculacionCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const Icon(Icons.people_alt_outlined,
            color: _Palette.accent, size: 28),
        title: const Text('Vincular pacientes',
            style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: const Text(
            'Genera códigos y gestiona pacientes vinculados',
            style: TextStyle(color: _Palette.textMuted, fontSize: 14)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TutorVinculacionScreen()),
        ),
      ),
    );
  }

  // ── Vinculación paciente ──────────────────────────────────────────────────

  Widget _buildVinculacionPacienteCard() {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: AuthService.getLinkedTutorStream(),
      builder: (context, snapshot) {
        final tutor = snapshot.data;
        final loading = snapshot.connectionState == ConnectionState.waiting;

        if (loading) {
          return Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const ListTile(
              leading: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              title: Text('Verificando vinculación...'),
            ),
          );
        }

        if (tutor != null) {
          final name = tutor['name'] as String? ?? 'Tutor';
          final email = tutor['email'] as String? ?? '';
          return Card(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
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
                  Text(name,
                      style: const TextStyle(
                          color: _Palette.textDark,
                          fontWeight: FontWeight.w500)),
                  if (email.isNotEmpty)
                    Text(email,
                        style: const TextStyle(
                            color: _Palette.textMuted, fontSize: 12)),
                ],
              ),
              trailing: const Icon(Icons.check_circle_rounded,
                  color: Colors.green, size: 24),
            ),
          );
        }

        return Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading:
                const Icon(Icons.link_outlined, color: _Palette.accent, size: 28),
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

  Future<void> _mostrarDialogoVinculacion() async {
    final controller = TextEditingController();
    final messenger = ScaffoldMessenger.of(context);

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Vincular con tutor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Ingresa el código de invitación que te dio tu tutor:'),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              textCapitalization: TextCapitalization.characters,
              maxLength: 6,
              decoration: const InputDecoration(
                hintText: 'Ej: ABC123',
                border: OutlineInputBorder(),
                counterText: '',
              ),
              onSubmitted: (_) async {
                final code = controller.text.trim().toUpperCase();
                if (code.length < 6) return;
                Navigator.of(ctx).pop();
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
              if (code.length < 6) return;
              Navigator.of(ctx).pop();
              await _vincularConTutor(code, messenger);
            },
            child: const Text('Verificar'),
          ),
        ],
      ),
    );

    controller.dispose();
  }

  Future<void> _vincularConTutor(
      String code, ScaffoldMessengerState messenger) async {
    try {
      final validation = await AuthService.validateInvitationCode(code);

      if (!mounted) return;

      if (validation == null || validation['valid'] != true) {
        messenger.showSnackBar(SnackBar(
          content: Text(validation?['reason'] ?? 'Código inválido'),
          backgroundColor: Colors.redAccent,
        ));
        return;
      }

      final tutorName = validation['tutorName'] as String? ?? 'tu tutor';

      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
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

  Widget _buildRoleCard(String currentRole) {
    final roleLabel = switch (currentRole) {
      'usuario_general' => 'Usuario General',
      'tutor' => 'Tutor',
      'paciente_tdah' => 'Paciente TDAH',
      'paciente_tea' => 'Paciente TEA',
      _ => currentRole.isEmpty ? 'Sin rol asignado' : currentRole,
    };

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: const Icon(Icons.manage_accounts_outlined,
            color: _Palette.accent, size: 28),
        title: const Text('Rol actual',
            style: TextStyle(fontWeight: FontWeight.w600)),
        subtitle: Text(roleLabel,
            style: const TextStyle(color: _Palette.textDark, fontSize: 14)),
        trailing: TextButton(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const RoleSelectionScreen()),
          ),
          child: const Text('Cambiar'),
        ),
      ),
    );
  }

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
            Text(
              'Número al que llamar en caso de emergencia (opcional).',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade700),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emergencyNameController,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nombre del contacto (ej: Mamá, Pareja, Amigo)',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) {
                if (!_isEmergencyDirty) {
                  setState(() => _isEmergencyDirty = true);
                }
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emergencyPhoneController,
              keyboardType: TextInputType.phone,
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
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: _isEmergencyDirty && !_isSavingEmergency
                    ? _saveEmergencyContact
                    : null,
                icon: _isSavingEmergency
                    ? const SizedBox(
                        width: 16,
                        height: 16,
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
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              value: notiTaskEnabled,
              title: const Text('Activar notificaciones de tareas'),
              onChanged: (value) {
                _userDoc
                    .set({'notiTaskEnabled': value}, SetOptions(merge: true));
              },
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<int?>(
              key: ValueKey(notiOffset),
              decoration: const InputDecoration(
                labelText: 'Recordarme antes',
                border: OutlineInputBorder(),
              ),
              initialValue: notiOffset,
              items: kReminderOptions
                  .map((option) => DropdownMenuItem<int?>(
                        value: option['minutes'] as int?,
                        child: Text(option['label'] as String),
                      ))
                  .toList(),
              onChanged: (value) {
                _userDoc.set(
                  {'notiTaskDefaultOffsetMinutes': value},
                  SetOptions(merge: true),
                );
              },
            ),
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      await NotificationService
                          .ensureDeviceCanDeliverNotifications();
                      if (!context.mounted) return;
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
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      if (kIsWeb) {
                        messenger.showSnackBar(const SnackBar(
                          content: Text(
                              'Modo Web: Prueba en tu celular.'),
                          behavior: SnackBarBehavior.floating,
                        ));
                        return;
                      }
                      final result =
                          await NotificationService.showTestNotification(
                        playPreviewSound: true,
                      );
                      if (!mounted) return;
                      if (!result.notificationSent) {
                        final String msg;
                        switch (result.failure) {
                          case NotificationTestFailure.permissionDenied:
                            msg =
                                'Debes aceptar el permiso de notificaciones.';
                          case NotificationTestFailure
                                .permissionPermanentlyDenied:
                            msg = 'Activa las notificaciones desde Ajustes.';
                          default:
                            msg = result.errorDescription != null
                                ? 'No se pudo enviar: ${result.errorDescription}'
                                : 'No se pudo enviar. Revisa los permisos.';
                        }
                        messenger.showSnackBar(SnackBar(content: Text(msg)));
                        return;
                      }
                      final base = result.previewSoundPlayed
                          ? 'Notificación enviada con sonido.'
                          : 'Notificación enviada. Activa el volumen.';
                      final hint = result.usedFallbackSound
                          ? '\nSe usó el sonido por defecto.'
                          : '';
                      messenger
                          .showSnackBar(SnackBar(content: Text(base + hint)));
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
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Sonido al terminar pomodoro'),
              value: soundEnabled,
              onChanged: (value) {
                _userDoc.set(
                    {'pomodoroSoundEnabled': value}, SetOptions(merge: true));
              },
            ),
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Vibración al terminar pomodoro'),
              value: vibrationEnabled,
              onChanged: (value) {
                _userDoc.set({'pomodoroVibrationEnabled': value},
                    SetOptions(merge: true));
              },
            ),
            const SizedBox(height: 8),
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
            const Text(
              'Registros',
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _Palette.textMuted),
            ),
            const SizedBox(height: 8),
            _buildStatRow(
                Icons.self_improvement, 'Sesiones completadas', '$focusSessions'),
            _buildStatRow(
                Icons.timer, 'Minutos de foco', '$totalFocusMinutes'),
            _buildStatRow(Icons.star, 'Puntos actuales', '$points'),
            _buildStatRow(
                Icons.local_fire_department, 'Racha actual', '$streak días'),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _Palette.textMuted),
          const SizedBox(width: 8),
          Text(label,
              style: const TextStyle(fontSize: 13, color: _Palette.textDark)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _Palette.textDark),
          ),
        ],
      ),
    );
  }

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
        onTap: _confirmLogout,
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Cerrar sesión'),
        content:
            const Text('¿Estás seguro de que quieres cerrar sesión?'),
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
    if (confirmed == true && mounted) _handleLogout();
  }

  Widget _buildBackupCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Text(
              'Tus pictogramas y configuraciones se guardan en tu Google Drive personal. Sin costes de servidor.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
            ),
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
            Row(
              children: [
                Expanded(
                  child: _buildBackupButton(
                    label: 'Sincronizar con Google Drive',
                    icon: Icons.cloud_upload_outlined,
                    onPressed: _isBackingUp ? null : _handleBackup,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildBackupButton(
                    label: 'Restaurar desde Drive',
                    icon: Icons.cloud_download_outlined,
                    onPressed: _isBackingUp ? null : _handleRestore,
                    isSecondary: true,
                  ),
                ),
              ],
            ),
            if (_isBackingUp) ...[
              const SizedBox(height: 16),
              Center(
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 48,
                        height: 48,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          value: _backupProgress,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            _Palette.primary,
                          ),
                        ),
                      ),
                      const Icon(
                        Icons.sync,
                        size: 20,
                        color: _Palette.primary,
                      ),
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

  Widget _buildBackupButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    bool isSecondary = false,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 18),
      label: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: isSecondary ? _Palette.surface : _Palette.primary,
        foregroundColor: isSecondary ? _Palette.primary : Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: isSecondary
              ? BorderSide(color: _Palette.primary.withValues(alpha: 0.3))
              : BorderSide.none,
        ),
        elevation: isSecondary ? 0 : 2,
      ),
    );
  }

  String _formatSyncDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Justo ahora';
    if (diff.inMinutes < 60) return 'Hace ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Hace ${diff.inHours}h';

    return DateFormat('dd/MM/yyyy HH:mm', 'es_ES').format(date);
  }

  Future<void> _handleBackup() async {
    if (!mounted) return;

    setState(() {
      _isBackingUp = true;
      _backupProgress = null;
    });

    final messenger = ScaffoldMessenger.of(context);

    try {
      final result = await GoogleDriveService.instance.backupToDrive();

      if (!mounted) return;

      setState(() {
        _isBackingUp = false;
        if (result.success) {
          _lastSync = result.timestamp;
        }
      });

      messenger.showSnackBar(SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? Colors.green.shade700 : Colors.red.shade700,
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

  Future<void> _handleRestore() async {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    try {
      final isCloudNewer = await GoogleDriveService.instance.isCloudNewerThanLocal();

      if (!mounted) return;

      if (isCloudNewer) {
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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

        if (confirm != true || !mounted) return;
      }

      setState(() {
        _isBackingUp = true;
        _backupProgress = null;
      });

      final result = await GoogleDriveService.instance.restoreFromDrive(force: true);

      if (!mounted) return;

      setState(() {
        _isBackingUp = false;
        if (result.success) {
          _lastSync = DateTime.now();
        }
      });

      messenger.showSnackBar(SnackBar(
        content: Text(result.message),
        backgroundColor: result.success ? Colors.green.shade700 : Colors.red.shade700,
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
