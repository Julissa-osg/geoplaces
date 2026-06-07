import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/api_service.dart';
import 'home_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with SingleTickerProviderStateMixin {
  final _formKey                 = GlobalKey<FormState>();
  final nameController           = TextEditingController();
  final apellidoController       = TextEditingController();
  final nivelEducativoController = TextEditingController();
  final emailController          = TextEditingController();
  final passController           = TextEditingController();
  final confirmController        = TextEditingController();
  bool loading                   = false;
  bool _verPass                  = false;
  bool _verConfirm               = false;

  late final AnimationController _animCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    nameController.dispose();
    apellidoController.dispose();
    nivelEducativoController.dispose();
    emailController.dispose();
    passController.dispose();
    confirmController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => loading = true);

    final result = await ApiService.register(
      name:                 nameController.text.trim(),
      apellido:             apellidoController.text.trim(),
      nivelEducativo:       nivelEducativoController.text.trim(),
      email:                emailController.text.trim(),
      password:             passController.text,
      passwordConfirmation: confirmController.text,
    );

    if (mounted) setState(() => loading = false);

    if (result['ok'] == true && mounted) {
      // Registrar también en Firebase Auth
      try {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: emailController.text.trim(),
          password: passController.text,
        );
        print('FIREBASE AUTH: usuario registrado correctamente');
      } catch (e) {
        print('FIREBASE AUTH ERROR: $e');
      }

      Navigator.pushReplacement(
        context,
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomePage(),
          transitionsBuilder: (_, anim, __, child) =>
              FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    } else if (mounted) {
      String mensaje = 'Error al registrarse';
      final errors = result['errors'];
      if (errors is Map) {
        mensaje = errors.values.first is List
            ? errors.values.first[0]
            : errors.values.first.toString();
      } else if (errors is String) {
        mensaje = errors;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(child: Text(mensaje)),
            ],
          ),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(16),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12121E),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),

                      // Botón volver
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E2E),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.white.withOpacity(0.08)),
                          ),
                          child: const Icon(Icons.arrow_back, color: Colors.white70, size: 20),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Título
                      const Text(
                        'Crear cuenta',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Regístrate para guardar tus lugares',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 14,
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 36),

                      // Nombre
                      _buildLabel('Nombre'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: nameController,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: _inputDecoration(hint: 'Tu nombre', icon: Icons.person_outline),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Ingresa tu nombre';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Apellido
                      _buildLabel('Apellido'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: apellidoController,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: _inputDecoration(hint: 'Tu apellido', icon: Icons.person_outline),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Ingresa tu apellido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Nivel educativo
                      _buildLabel('Nivel educativo'),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        dropdownColor: const Color(0xFF1E1E2E),
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: _inputDecoration(
                          hint: 'Selecciona tu nivel',
                          icon: Icons.school_outlined,
                        ),
                        items: const [
                          DropdownMenuItem(value: 'Primaria',   child: Text('Primaria')),
                          DropdownMenuItem(value: 'Secundaria', child: Text('Secundaria')),
                          DropdownMenuItem(value: 'Técnico',    child: Text('Técnico')),
                          DropdownMenuItem(value: 'Superior',   child: Text('Superior')),
                          DropdownMenuItem(value: 'Posgrado',   child: Text('Posgrado')),
                        ],
                        onChanged: (v) => nivelEducativoController.text = v ?? '',
                        validator: (v) =>
                            (v == null || v.isEmpty) ? 'Selecciona tu nivel educativo' : null,
                      ),
                      const SizedBox(height: 16),

                      // Correo
                      _buildLabel('Correo electrónico'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: emailController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: _inputDecoration(hint: 'ejemplo@correo.com', icon: Icons.email_outlined),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Ingresa tu correo electrónico';
                          if (!v.contains('@')) return 'Correo no válido';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Contraseña
                      _buildLabel('Contraseña'),
                      const SizedBox(height: 4),
                      Text(
                        'Mínimo 8 caracteres, letras, números y un símbolo (!@#\$...)',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.35),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: passController,
                        obscureText: !_verPass,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: _inputDecoration(
                          hint: '••••••••',
                          icon: Icons.lock_outline_rounded,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _verPass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: Colors.white38,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _verPass = !_verPass),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Ingresa tu contraseña';
                          if (v.length < 8) return 'Mínimo 8 caracteres';
                          if (!v.contains(RegExp(r'[a-zA-Z]'))) return 'Debe contener letras';
                          if (!v.contains(RegExp(r'[0-9]'))) return 'Debe contener números';
                          if (!v.contains(RegExp(r'[\W_]'))) return 'Debe contener un símbolo (!@#\$...)';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Confirmar contraseña
                      _buildLabel('Confirmar contraseña'),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: confirmController,
                        obscureText: !_verConfirm,
                        style: const TextStyle(color: Colors.white, fontSize: 15),
                        decoration: _inputDecoration(
                          hint: '••••••••',
                          icon: Icons.lock_outline_rounded,
                        ).copyWith(
                          suffixIcon: IconButton(
                            icon: Icon(
                              _verConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                              color: Colors.white38,
                              size: 20,
                            ),
                            onPressed: () => setState(() => _verConfirm = !_verConfirm),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Confirma tu contraseña';
                          if (v != passController.text) return 'Las contraseñas no coinciden';
                          return null;
                        },
                      ),
                      const SizedBox(height: 36),

                      // Botón Crear cuenta
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: loading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF7C3AED),
                            disabledBackgroundColor: const Color(0xFF7C3AED).withOpacity(0.5),
                            foregroundColor: Colors.white,
                            elevation: 8,
                            shadowColor: const Color(0xFF7C3AED).withOpacity(0.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      'Crear cuenta',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.4),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(Icons.arrow_forward_rounded, size: 18),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ¿Ya tienes cuenta?
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: RichText(
                            text: TextSpan(
                              text: '¿Ya tienes cuenta? ',
                              style: TextStyle(color: Colors.white.withOpacity(0.45), fontSize: 14),
                              children: const [
                                TextSpan(
                                  text: 'Ingresar',
                                  style: TextStyle(color: Color(0xFF7C3AED), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Footer
                      Center(
                        child: Text(
                          'GeoPlaces • Flutter + Laravel',
                          style: TextStyle(color: Colors.white.withOpacity(0.2), fontSize: 12, letterSpacing: 0.5),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500, letterSpacing: 0.3),
    );
  }

  InputDecoration _inputDecoration({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF7C3AED), size: 20),
      filled: true,
      fillColor: const Color(0xFF1E1E2E),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: const Color(0xFF7C3AED).withOpacity(0.2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
      ),
      errorStyle: const TextStyle(color: Color(0xFFDC2626), fontSize: 12),
    );
  }
}