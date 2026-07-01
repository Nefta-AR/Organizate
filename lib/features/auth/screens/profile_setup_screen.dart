// ============================================================
// lib/features/auth/screens/profile_setup_screen.dart
// ============================================================
// Pantalla de configuración inicial de perfil. Se muestra una sola vez:
// cuando hasCompletedProfile == false Y el campo name está vacío en Firestore.
//
// El usuario escribe su nombre y elige un avatar de 8 opciones.
// Al guardar, AuthGate detecta el cambio en hasCompletedProfile via
// su StreamBuilder y redirige automáticamente a HomeScreen/TutorScreen
// sin necesidad de Navigator.push explícito.
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  // Lista de nombres de archivo de avatar (sin extensión).
  // Los assets están en assets/avatars/<nombre>.png.
  static const _avatars = [
    'emoticon', 'koala',    'panda',    'pinguino',
    'rana',     'tigre',    'unicornio','zorro',
  ];

  static const _primary = Color(0xFF7BB3D0); // Azul terapéutico
  static const _bg      = Color(0xFFF5F7FA); // Fondo gris claro

  late final TextEditingController _nameCtrl;
  String? _selectedAvatar; // null si el usuario no eligió avatar todavía
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    // Pre-rellena el nombre con el displayName de Firebase Auth si existe
    // (p. ej. si el usuario entró con Google y ya tiene nombre).
    final authUser = FirebaseAuth.instance.currentUser;
    _nameCtrl = TextEditingController(
      text: authUser?.displayName ?? '',
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  /// Guarda el nombre y el avatar seleccionado en Firestore.
  ///
  /// Efecto secundario: AuthGate detecta el cambio en hasCompletedProfile
  /// y redirige a la pantalla correcta de forma reactiva.
  Future<void> _save() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor ingresa tu nombre.')),
      );
      return;
    }
    setState(() => _saving = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {
          'name': name,
          // Solo se incluye 'avatar' en el documento si el usuario eligió uno;
          // si no eligió, el campo anterior (o el valor por defecto) se mantiene.
          if (_selectedAvatar != null) 'avatar': _selectedAvatar,
          'hasCompletedProfile': true, // AuthGate reacciona a este cambio
        },
        SetOptions(merge: true), // merge: true para no borrar otros campos
      );
      // No necesita Navigator.push: AuthGate redirige al detectar el cambio.
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo guardar el perfil. Intenta de nuevo.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 16),

              // ── Ícono decorativo ────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: _primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_rounded, size: 48, color: _primary),
              ),
              const SizedBox(height: 20),

              // ── Título y subtítulo ──────────────────────────────────
              const Text(
                '¡Casi listo!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF37474F),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Cuéntanos cómo quieres que te llamemos\ny elige tu avatar.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Color(0xFF78909C), height: 1.5),
              ),
              const SizedBox(height: 32),

              // ── Campo de nombre ─────────────────────────────────────
              TextField(
                controller: _nameCtrl,
                textCapitalization: TextCapitalization.words, // Capitaliza cada palabra
                decoration: InputDecoration(
                  labelText: 'Tu nombre',
                  prefixIcon: const Icon(Icons.badge_rounded, color: _primary),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // ── Selector de avatar ──────────────────────────────────
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Elige tu avatar',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Color(0xFF37474F),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Grid 4×2 de avatares con selección animada.
              GridView.builder(
                shrinkWrap: true,
                // NeverScrollableScrollPhysics porque el scroll es del SingleChildScrollView padre.
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,   // 4 columnas
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _avatars.length,
                itemBuilder: (_, i) {
                  final name     = _avatars[i];
                  final selected = _selectedAvatar == name;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedAvatar = name),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        // Borde azul si está seleccionado, transparente si no.
                        border: Border.all(
                          color: selected ? _primary : Colors.transparent,
                          width: 3,
                        ),
                        // Sombra azul suave al seleccionado para mayor visibilidad.
                        boxShadow: selected
                            ? [BoxShadow(
                                color: _primary.withValues(alpha: 0.35),
                                blurRadius: 8,
                              )]
                            : [],
                      ),
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        child: SizedBox.expand(
                          child: Image.asset(
                            'assets/avatars/$name.png',
                            fit: BoxFit.cover,
                            // Fallback si el asset no existe o hay error de carga.
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.person, color: Colors.grey);
                            },
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // ── Botón para deseleccionar avatar ─────────────────────
              TextButton(
                // Solo activo si hay un avatar seleccionado.
                onPressed: _selectedAvatar == null
                    ? null
                    : () => setState(() => _selectedAvatar = null),
                child: const Text(
                  'Sin avatar por ahora',
                  style: TextStyle(color: Color(0xFF78909C), fontSize: 13),
                ),
              ),
              const SizedBox(height: 32),

              // ── Botón "Comenzar" ─────────────────────────────────────
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _saving ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  // Spinner mientras guarda, texto cuando está listo.
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Text(
                          'Comenzar',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
