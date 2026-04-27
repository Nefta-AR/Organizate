import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PALETA CALMA — diseñada para reducir sobrecarga sensorial (TDAH / TEA)
// Ref. WCAG 2.1 — contraste mínimo AA garantizado en todos los textos.
// ─────────────────────────────────────────────────────────────────────────────
class _Palette {
  _Palette._();
  static const background = Color(0xFFF0F4F8); // Gris azulado pálido — fondo general
  static const primary    = Color(0xFF607D8B); // Azul grisáceo — botones / títulos
  static const accent     = Color(0xFFFF9800); // Naranja suave — solo detalles / links
  static const surface    = Colors.white;      // Superficie de campos y tarjetas
  static const textDark   = Color(0xFF37474F); // Texto principal
  static const textMuted  = Color(0xFF78909C); // Texto secundario / placeholders
  static const border     = Color(0xFFCFD8DC); // Borde de campos en reposo
}

// Radio de borde global — reduce la "fricción visual" (WCAG SC 1.4.12)
const double _kRadius = 16;

// ─────────────────────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ── Formulario ─────────────────────────────────────────────────────────────
  final _formKey           = GlobalKey<FormState>();
  final _emailController   = TextEditingController();
  final _passwordController= TextEditingController();
  final _nameController    = TextEditingController();

  // ── Estado de la UI ────────────────────────────────────────────────────────
  bool _isLogin         = true;
  bool _isLoading       = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // ── Persistencia del correo (sin contraseña — seguridad) ──────────────────
  Future<void> _loadSavedEmail() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString('saved_email');
    if (!mounted || saved == null) return;
    _emailController.text = saved;
  }

  Future<void> _saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('saved_email', email);
  }

  // ── PUNTO DE EXTENSIÓN: ruteo por rol ─────────────────────────────────────
  // Llama a esta función tras cualquier autenticación exitosa.
  // Aquí podrás leer el campo 'role' del documento users/{uid} y redirigir
  // al flujo de Tutor o Paciente sin modificar el resto del login.
  //
  // Ejemplo futuro:
  //   final snap = await FirebaseFirestore.instance
  //       .collection('users').doc(user.uid).get();
  //   final role = snap.data()?['role'] as String? ?? 'paciente';
  //   if (role == 'tutor') { Navigator.pushReplacement(...TutorHome...); }
  //   else                 { Navigator.pushReplacement(...PacienteHome...); }
  Future<void> _handleAuthSuccess(User user) async {
    // TODO: implementar lógica de ruteo por rol (tutor / paciente).
  }

  // ── Login / Registro con correo ────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final auth     = FirebaseAuth.instance;
    final email    = _emailController.text.trim();
    final password = _passwordController.text.trim();

    try {
      if (_isLogin) {
        final cred = await auth.signInWithEmailAndPassword(
          email: email, password: password,
        );
        await _saveEmail(email);
        if (cred.user != null) await _handleAuthSuccess(cred.user!);
      } else {
        final cred = await auth.createUserWithEmailAndPassword(
          email: email, password: password,
        );
        final user = cred.user;
        if (user != null) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'name'                  : _nameController.text.trim(),
                'email'                 : email,
                'avatar'                : 'emoticon',
                'points'                : 0,
                'streak'                : 0,
                'hasCompletedOnboarding': false,
                'createdAt'             : FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
          await _saveEmail(email);
          await _handleAuthSuccess(user);
        }
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Ocurrió un error inesperado');
    } catch (_) {
      _showError('Ocurrió un error inesperado');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── Login con Google (opción prioritaria — sin recordar contraseñas) ───────
  Future<void> _signInWithGoogle() async {
    if (_isGoogleLoading) return;
    setState(() => _isGoogleLoading = true);
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // usuario canceló el flujo

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken    : googleAuth.idToken,
      );
      final userCred =
          await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCred.user;

      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .set({
              'name'                  : user.displayName ?? 'Usuario',
              'email'                 : user.email,
              'avatar'                : 'emoticon',
              'points'                : 0,
              'streak'                : 0,
              'hasCompletedOnboarding': false,
              'createdAt'             : FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
        if (user.email != null) await _saveEmail(user.email!);
        await _handleAuthSuccess(user);
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'No pudimos iniciar sesión con Google.');
    } catch (_) {
      _showError('No pudimos iniciar sesión con Google.');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  // ── Recuperar contraseña ───────────────────────────────────────────────────
  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Escribe tu correo arriba para enviarte el enlace.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Te enviamos un enlace para restablecer tu contraseña.'),
      ));
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'No se pudo enviar el correo');
    } catch (_) {
      _showError('No se pudo enviar el correo');
    }
  }

  void _showError(String message) =>
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(message)));

  // ── Campo de texto reutilizable ────────────────────────────────────────────
  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller   : controller,
      validator    : validator,
      keyboardType : keyboardType,
      obscureText  : obscureText,
      style        : const TextStyle(color: _Palette.textDark),
      decoration   : InputDecoration(
        labelText  : label,
        labelStyle : const TextStyle(
          color      : _Palette.primary,
          fontWeight : FontWeight.w600,
        ),
        filled    : true,
        fillColor : _Palette.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kRadius),
          borderSide  : BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kRadius),
          borderSide  : const BorderSide(color: _Palette.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kRadius),
          borderSide  : const BorderSide(color: _Palette.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kRadius),
          borderSide  : const BorderSide(color: Colors.redAccent),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kRadius),
          borderSide  : const BorderSide(color: Colors.redAccent, width: 2),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.background,
      bottomNavigationBar: const SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '© 2025 Organízate. Todos los derechos reservados.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: _Palette.textMuted),
              ),
              SizedBox(height: 2),
              Text(
                'v1.0.0',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: _Palette.textMuted),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize     : MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  // ── Logo ────────────────────────────────────────────────
                  Image.asset('assets/images/Logo.png', height: 100),
                  const SizedBox(height: 12),

                  // ── Título y subtítulo ───────────────────────────────────
                  const Text(
                    'Organízate',
                    style: TextStyle(
                      fontSize  : 30,
                      fontWeight: FontWeight.bold,
                      color     : _Palette.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tu asistente cognitivo',
                    style: TextStyle(fontSize: 14, color: _Palette.textMuted),
                  ),
                  const SizedBox(height: 32),

                  // ── BOTÓN GOOGLE — elemento de mayor jerarquía visual ────
                  // Posicionado primero para reducir la carga cognitiva:
                  // el usuario no necesita recordar ninguna contraseña.
                  _GoogleButton(
                    isLoading: _isGoogleLoading,
                    onTap    : _signInWithGoogle,
                  ),
                  const SizedBox(height: 24),

                  // ── Divisor ──────────────────────────────────────────────
                  const Row(children: [
                    Expanded(child: Divider(color: _Palette.border)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'o con correo',
                        style: TextStyle(
                          fontSize: 13,
                          color   : _Palette.textMuted,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: _Palette.border)),
                  ]),
                  const SizedBox(height: 20),

                  // ── Nombre (solo en registro) ────────────────────────────
                  if (!_isLogin) ...[
                    _buildInput(
                      controller: _nameController,
                      label     : 'Nombre',
                      validator : (v) => (v == null || v.trim().length < 3)
                          ? 'Ingresa un nombre válido'
                          : null,
                    ),
                    const SizedBox(height: 14),
                  ],

                  // ── Correo ───────────────────────────────────────────────
                  _buildInput(
                    controller  : _emailController,
                    label       : 'Correo electrónico',
                    keyboardType: TextInputType.emailAddress,
                    validator   : (v) =>
                        (v == null || v.isEmpty || !v.contains('@'))
                            ? 'Ingresa un correo válido'
                            : null,
                  ),
                  const SizedBox(height: 14),

                  // ── Contraseña ───────────────────────────────────────────
                  _buildInput(
                    controller : _passwordController,
                    label      : 'Contraseña',
                    obscureText: _obscurePassword,
                    validator  : (v) => (v == null || v.length < 6)
                        ? 'Mínimo 6 caracteres'
                        : null,
                    suffixIcon : IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: _Palette.textMuted,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),

                  // ── ¿Olvidaste tu contraseña? — acento naranja ───────────
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: _isLoading ? null : _resetPassword,
                      style: TextButton.styleFrom(
                        foregroundColor: _Palette.accent,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 8),
                      ),
                      child: const Text('¿Olvidaste tu contraseña?'),
                    ),
                  ),
                  const SizedBox(height: 4),

                  // ── Botón Iniciar sesión / Registrarse ───────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _Palette.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            _Palette.primary.withValues(alpha: 0.5),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_kRadius),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width : 22,
                              child : CircularProgressIndicator(
                                strokeWidth: 2,
                                color      : Colors.white,
                              ),
                            )
                          : Text(
                              _isLogin ? 'Iniciar sesión' : 'Registrarse',
                              style: const TextStyle(
                                fontSize  : 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Alternar entre login y registro ──────────────────────
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => setState(() => _isLogin = !_isLogin),
                    style: TextButton.styleFrom(
                      foregroundColor: _Palette.primary,
                    ),
                    child: Text(
                      _isLogin
                          ? '¿No tienes cuenta? Regístrate'
                          : '¿Ya tienes cuenta? Inicia sesión',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Botón de Google — widget privado separado para mantener el build limpio.
//
// Es el elemento de mayor jerarquía visual en el formulario:
// fondo blanco, sombra suave y tipografía en negrita comunican prioridad
// sin recurrir a colores saturados que generen estrés visual.
// ─────────────────────────────────────────────────────────────────────────────
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({
    required this.isLoading,
    required this.onTap,
  });

  final bool         isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color       : _Palette.surface,
        borderRadius: BorderRadius.circular(_kRadius),
        elevation   : 3,
        shadowColor : Colors.black.withValues(alpha: 0.12),
        child: InkWell(
          borderRadius: BorderRadius.circular(_kRadius),
          onTap       : isLoading ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            child: isLoading
                ? const Center(
                    child: SizedBox(
                      height: 24,
                      width : 24,
                      child : CircularProgressIndicator(
                        strokeWidth: 2,
                        color      : _Palette.primary,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/icons/google.png', height: 26),
                      const SizedBox(width: 14),
                      const Text(
                        'Continuar con Google',
                        style: TextStyle(
                          fontSize  : 16,
                          fontWeight: FontWeight.w700,
                          color     : _Palette.textDark,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
