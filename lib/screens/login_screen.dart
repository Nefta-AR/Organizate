import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:organizate/screens/auth_gate.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Paleta Calma — Simple
// Fondo blanco/gris extraclaro, azul pastel como color primario.
// WCAG 2.1 AA: contraste mínimo garantizado en todos los textos.
// ─────────────────────────────────────────────────────────────────────────────
class _Palette {
  _Palette._();
  static const background = Color(0xFFF5F7FA); // gris extraclaro
  static const primary    = Color(0xFF4A90E2); // azul pastel
  static const surface    = Colors.white;
  static const textDark   = Color(0xFF2D3748); // casi negro cálido
  static const textMuted  = Color(0xFF718096); // gris azulado
  static const border     = Color(0xFFE2E8F0); // borde muy sutil
}

const double _kRadius = 14;

// ─────────────────────────────────────────────────────────────────────────────
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ── Formulario ─────────────────────────────────────────────────────────────
  final _formKey            = GlobalKey<FormState>();
  final _emailController    = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController     = TextEditingController();

  // ── Estado UI ──────────────────────────────────────────────────────────────
  bool _isLogin         = true;
  bool _isLoading       = false;
  bool _isGoogleLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _loadSavedEmail();
  }

  // Limpieza explícita de controladores — evita leaks de memoria.
  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  // ── Persistencia del correo ────────────────────────────────────────────────
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

  // ── Punto de extensión para ruteo por rol ─────────────────────────────────
  // La AuthGate en main.dart maneja el ruteo automáticamente via stream.
  // Este hook queda disponible para lógica adicional post-login si se necesita.
  Future<void> _handleAuthSuccess(User user) async {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const AuthGate()),
      (route) => false,
    );
  }

  // ── FIX CRÍTICO: LOGIN CON CORREO ─────────────────────────────────────────
  // El bloque finally garantiza que _isLoading SIEMPRE vuelve a false,
  // incluso si hay una excepción no capturada, evitando el botón congelado.
  Future<void> _handleLogin() async {
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
          // Sincroniza displayName en FirebaseAuth y Firestore.
          await user.updateDisplayName(_nameController.text.trim());
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
      _showError(_mapAuthError(e.code));
    } catch (_) {
      _showError('Ocurrió un error inesperado. Intenta de nuevo.');
    } finally {
      // CRÍTICO: siempre libera la UI independientemente del resultado.
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ── GOOGLE ─────────────────────────────────────────────────────────────────
  Future<void> _handleGoogleLogin() async {
    if (_isGoogleLoading) return;
    setState(() => _isGoogleLoading = true);

    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return; // usuario canceló — finally se ejecuta igual

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken    : googleAuth.idToken,
      );
      final userCred = await FirebaseAuth.instance.signInWithCredential(credential);
      final user     = userCred.user;

      if (user != null) {
        final isNew = userCred.additionalUserInfo?.isNewUser ?? false;
        final payload = {
          'name' : user.displayName ?? 'Usuario de Simple',
          'email': user.email,
        };
        if (isNew) {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                ...payload,
                'avatar'                : 'emoticon',
                'points'                : 0,
                'streak'                : 0,
                'hasCompletedOnboarding': false,
                'createdAt'             : FieldValue.serverTimestamp(),
              });
        } else {
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set(payload, SetOptions(merge: true));
        }
        if (user.email != null) await _saveEmail(user.email!);
        await _handleAuthSuccess(user);
      }
    } on FirebaseAuthException catch (e) {
      _showError(_mapAuthError(e.code));
    } catch (_) {
      _showError('No pudimos iniciar sesión con Google. Intenta de nuevo.');
    } finally {
      if (mounted) setState(() => _isGoogleLoading = false);
    }
  }

  // ── RECUPERAR CONTRASEÑA ───────────────────────────────────────────────────
  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Escribe tu correo arriba para recibir el enlace.');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Te enviamos el enlace para restablecer tu contraseña.'),
        behavior: SnackBarBehavior.floating,
      ));
    } on FirebaseAuthException catch (e) {
      _showError(_mapAuthError(e.code));
    } catch (_) {
      _showError('No se pudo enviar el correo.');
    }
  }

  // ── Traducciones de errores de Firebase ───────────────────────────────────
  String _mapAuthError(String code) {
    switch (code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Correo o contraseña incorrectos.';
      case 'email-already-in-use':
        return 'Este correo ya está registrado. Inicia sesión.';
      case 'weak-password':
        return 'La contraseña debe tener al menos 6 caracteres.';
      case 'invalid-email':
        return 'El correo no tiene un formato válido.';
      case 'too-many-requests':
        return 'Demasiados intentos. Espera un momento e intenta de nuevo.';
      case 'network-request-failed':
        return 'Sin conexión a internet. Verifica tu red.';
      default:
        return 'Error inesperado ($code). Intenta de nuevo.';
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content : Text(message),
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ── Campo de texto reutilizable ────────────────────────────────────────────
  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText           = false,
    Widget? suffixIcon,
  }) {
    return TextFormField(
      controller   : controller,
      validator    : validator,
      keyboardType : keyboardType,
      obscureText  : obscureText,
      style        : const TextStyle(color: _Palette.textDark, fontSize: 15),
      decoration   : InputDecoration(
        labelText  : label,
        labelStyle : const TextStyle(color: _Palette.textMuted, fontSize: 14),
        filled     : true,
        fillColor  : _Palette.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kRadius),
          borderSide  : BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kRadius),
          borderSide  : const BorderSide(color: _Palette.border, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kRadius),
          borderSide  : const BorderSide(color: _Palette.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kRadius),
          borderSide  : const BorderSide(color: Color(0xFFE53E3E)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_kRadius),
          borderSide  : const BorderSide(color: Color(0xFFE53E3E), width: 2),
        ),
        suffixIcon: suffixIcon,
      ),
    );
  }

  // ── BUILD ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _Palette.background,
      bottomNavigationBar: const SafeArea(
        child: Padding(
          padding: EdgeInsets.only(bottom: 14),
          child: Text(
            '© 2026 Simple · Tu ayuda cognitiva',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: _Palette.textMuted),
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
                mainAxisSize      : MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [

                  // ── Logo ────────────────────────────────────────────────
                  Image.asset('assets/images/Simple.png', height: 140),
                  const SizedBox(height: 20),

                  // ── Nombre y eslogan ─────────────────────────────────────
                  const Text(
                    'Simple',
                    style: TextStyle(
                      fontSize    : 35,
                      fontWeight  : FontWeight.bold,
                      color       : _Palette.primary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Tu ayuda cognitiva',
                    style: TextStyle(fontSize: 15, color: _Palette.textMuted),
                  ),
                  const SizedBox(height: 36),

                  // ── Google (jerarquía máxima) ─────────────────────────────
                  _GoogleButton(
                    isLoading: _isGoogleLoading,
                    onTap    : _handleGoogleLogin,
                  ),
                  const SizedBox(height: 24),

                  // ── Divisor ───────────────────────────────────────────────
                  const Row(children: [
                    Expanded(child: Divider(color: _Palette.border)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'o continúa con correo',
                        style: TextStyle(fontSize: 12, color: _Palette.textMuted),
                      ),
                    ),
                    Expanded(child: Divider(color: _Palette.border)),
                  ]),
                  const SizedBox(height: 20),

                  // ── Nombre (solo en registro, con animación) ──────────────
                  AnimatedSize(
                    duration: const Duration(milliseconds: 250),
                    curve   : Curves.easeInOut,
                    child: _isLogin
                        ? const SizedBox.shrink()
                        : Column(children: [
                            _buildInput(
                              controller: _nameController,
                              label     : 'Tu nombre',
                              validator : (v) =>
                                  (v == null || v.trim().length < 2)
                                      ? 'Ingresa un nombre válido'
                                      : null,
                            ),
                            const SizedBox(height: 14),
                          ]),
                  ),

                  // ── Correo ────────────────────────────────────────────────
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

                  // ── Contraseña ────────────────────────────────────────────
                  _buildInput(
                    controller : _passwordController,
                    label      : 'Contraseña',
                    obscureText: _obscurePassword,
                    validator  : (v) =>
                        (v == null || v.length < 6) ? 'Mínimo 6 caracteres' : null,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: _Palette.textMuted,
                        size : 20,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),

                  // ── ¿Olvidaste tu contraseña? (solo en login) ────────────
                  if (_isLogin)
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: _isLoading ? null : _handleForgotPassword,
                        style: TextButton.styleFrom(
                          foregroundColor: _Palette.primary,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 8),
                        ),
                        child: const Text(
                          '¿Olvidaste tu contraseña?',
                          style: TextStyle(fontSize: 13),
                        ),
                      ),
                    ),
                  const SizedBox(height: 4),

                  // ── Botón principal ───────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _Palette.primary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            _Palette.primary.withValues(alpha: 0.45),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(_kRadius),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 22, width: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color      : Colors.white,
                              ),
                            )
                          : Text(
                              _isLogin ? 'Iniciar sesión' : 'Crear cuenta',
                              style: const TextStyle(
                                fontSize  : 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // ── Alternar login / registro ─────────────────────────────
                  TextButton(
                    onPressed: _isLoading
                        ? null
                        : () => setState(() {
                              _isLogin = !_isLogin;
                              _formKey.currentState?.reset();
                            }),
                    style: TextButton.styleFrom(
                      foregroundColor: _Palette.primary,
                    ),
                    child: Text(
                      _isLogin
                          ? '¿No tienes cuenta? Regístrate'
                          : '¿Ya tienes cuenta? Inicia sesión',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w500),
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
// Botón de Google — widget privado para mantener el build limpio.
// Sombra sutil, sin colores saturados, coherente con la Paleta Calma.
// ─────────────────────────────────────────────────────────────────────────────
class _GoogleButton extends StatelessWidget {
  const _GoogleButton({required this.isLoading, required this.onTap});

  final bool         isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Material(
        color       : _Palette.surface,
        borderRadius: BorderRadius.circular(_kRadius),
        elevation   : 2,
        shadowColor : Colors.black.withValues(alpha: 0.08),
        child: InkWell(
          borderRadius: BorderRadius.circular(_kRadius),
          onTap       : isLoading ? null : onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 24),
            child: isLoading
                ? const Center(
                    child: SizedBox(
                      height: 24, width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color      : _Palette.primary,
                      ),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/icons/google.png', height: 24),
                      const SizedBox(width: 12),
                      const Text(
                        'Continuar con Google',
                        style: TextStyle(
                          fontSize  : 15,
                          fontWeight: FontWeight.w600,
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
