import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'login_page.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage>
    with SingleTickerProviderStateMixin {
  static const String _baseUrl = 'http://127.0.0.1:8000/api';

  final _emailCtrl = TextEditingController();
  final _codeCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _loading = false;
  bool _codigoEnviado = false;
  bool _verPass = false;
  String? _codigoDesarrollo; // solo visible en dev

  late final AnimationController _animCtrl;
  late final Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _codeCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _solicitarCodigo() async {
    if (_emailCtrl.text.trim().isEmpty || !_emailCtrl.text.contains('@')) {
      _mostrarError('Ingresa un correo válido');
      return;
    }
    setState(() => _loading = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/forgot-password'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({'email': _emailCtrl.text.trim()}),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        setState(() {
          _codigoEnviado = true;
          _codigoDesarrollo = data['code']?.toString(); // dev only
        });
        _mostrarSnack('Código generado. ${_codigoDesarrollo != null ? 'Código: $_codigoDesarrollo' : 'Revisa tu correo.'}', true);
      } else {
        _mostrarError(data['message'] ?? 'Error al solicitar código');
      }
    } catch (e) {
      _mostrarError('Sin conexión al servidor');
    }

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _cambiarContrasena() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/reset-password'),
        headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
        body: jsonEncode({
          'email': _emailCtrl.text.trim(),
          'code': _codeCtrl.text.trim(),
          'password': _passCtrl.text,
          'password_confirmation': _confirmCtrl.text,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (mounted) {
          _mostrarSnack('¡Contraseña actualizada!', true);
          final nav = Navigator.of(context);
          await Future.delayed(const Duration(milliseconds: 1200));
          nav.pushReplacement(
            MaterialPageRoute(builder: (_) => const LoginPage()),
          );
        }
      } else {
        _mostrarError(data['message'] ?? 'Error al cambiar contraseña');
      }
    } catch (e) {
      _mostrarError('Sin conexión al servidor');
    }

    if (mounted) setState(() => _loading = false);
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.error_outline, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: const Color(0xFFDC2626),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  void _mostrarSnack(String msg, bool exito) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(
          exito ? Icons.check_circle_outline : Icons.info_outline,
          color: Colors.white,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(msg)),
      ]),
      backgroundColor: exito ? const Color(0xFF7C3AED) : const Color(0xFF3B82F6),
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF12121E),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),

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
                  const SizedBox(height: 32),

                  // Ícono
                  Center(
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF9D4EDD)],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF7C3AED).withOpacity(0.4),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.lock_reset_rounded, color: Colors.white, size: 36),
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Título
                  Text(
                    _codigoEnviado ? 'Ingresa el código' : 'Recuperar contraseña',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _codigoEnviado
                        ? 'Ingresa el código recibido y tu nueva contraseña'
                        : 'Te enviaremos un código de recuperación',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.45),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 36),

                  // Email (siempre visible)
                  _label('Correo electrónico'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailCtrl,
                    enabled: !_codigoEnviado,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(color: Colors.white),
                    decoration: _inputDeco(
                      hint: 'ejemplo@correo.com',
                      icon: Icons.email_outlined,
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (!_codigoEnviado) ...[
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _solicitarCodigo,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Solicitar código',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],

                  if (_codigoEnviado) ...[
                    // Código
                    _label('Código de verificación'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _codeCtrl,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        letterSpacing: 8,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      decoration: _inputDeco(
                        hint: '000000',
                        icon: Icons.pin_outlined,
                      ).copyWith(counterText: ''),
                      validator: (v) {
                        if (v == null || v.length < 6) return 'Ingresa el código de 6 dígitos';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Nueva contraseña
                    _label('Nueva contraseña'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _passCtrl,
                      obscureText: !_verPass,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDeco(
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
                        if (v == null || v.isEmpty) return 'Ingresa tu nueva contraseña';
                        if (v.length < 8) return 'Mínimo 8 caracteres';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Confirmar contraseña
                    _label('Confirmar contraseña'),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _confirmCtrl,
                      obscureText: !_verPass,
                      style: const TextStyle(color: Colors.white),
                      decoration: _inputDeco(
                        hint: '••••••••',
                        icon: Icons.lock_outline_rounded,
                      ),
                      validator: (v) {
                        if (v != _passCtrl.text) return 'Las contraseñas no coinciden';
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _cambiarContrasena,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF7C3AED),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Cambiar contraseña',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Center(
                      child: TextButton(
                        onPressed: () => setState(() {
                          _codigoEnviado = false;
                          _codeCtrl.clear();
                          _passCtrl.clear();
                          _confirmCtrl.clear();
                        }),
                        child: Text(
                          'Volver a solicitar código',
                          style: TextStyle(
                            color: const Color(0xFF7C3AED).withOpacity(0.8),
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                  Center(
                    child: Text(
                      'GeoPlaces • Flutter + Laravel',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.2),
                        fontSize: 12,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
        text,
        style: const TextStyle(
          color: Colors.white70,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.3,
        ),
      );

  InputDecoration _inputDeco({required String hint, required IconData icon}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.25), fontSize: 14),
      prefixIcon: Icon(icon, color: const Color(0xFF7C3AED), size: 20),
      filled: true,
      fillColor: const Color(0xFF1E1E2E),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
