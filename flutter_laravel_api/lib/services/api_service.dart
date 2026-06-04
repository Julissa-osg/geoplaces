import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  static final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: '978895417776-592bimm75813obnue31skg599begk0i8.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  // Headers base para JSON
  static Map<String, String> get _jsonHeaders => {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
      };

  static Future<Map<String, String>> _authHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token') ?? '';
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // ── LOGIN normal ─────────────────────────────────────
  static Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: _jsonHeaders,
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      print('LOGIN STATUS: ${response.statusCode}');
      print('LOGIN BODY:   ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        return {'ok': true};
      }

      // Errores específicos del servidor
      try {
        final data = jsonDecode(response.body);
        return {
          'ok': false,
          'error_type': data['error_type'] ?? 'unknown',
          'message': data['message'] ?? 'Error al ingresar',
        };
      } catch (_) {
        return {'ok': false, 'error_type': 'unknown', 'message': 'Error al ingresar'};
      }
    } catch (e) {
      print('LOGIN ERROR: $e');
      return {'ok': false, 'error_type': 'connection', 'message': 'Sin conexión al servidor'};
    }
  }

  // ── REGISTRO ─────────────────────────────────────────
  static Future<Map<String, dynamic>> register({
    required String name,
    required String apellido,
    required String email,
    required String password,
    required String passwordConfirmation,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: _jsonHeaders,
        body: jsonEncode({
          'name':                  name,
          'apellido':              apellido,
          'email':                 email,
          'password':              password,
          'password_confirmation': passwordConfirmation,
        }),
      );

      print('REGISTER STATUS: ${response.statusCode}');
      print('REGISTER BODY:   ${response.body}');

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        return {'ok': true};
      }

      final data = jsonDecode(response.body);
      return {'ok': false, 'errors': data['errors'] ?? data['message'] ?? 'Error desconocido'};
    } catch (e) {
      print('REGISTER ERROR: $e');
      return {'ok': false, 'errors': 'Error de conexión'};
    }
  }

  // ── LOGIN con Google ─────────────────────────────────
  static Future<bool> loginWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/google/flutter'),
        headers: _jsonHeaders,
        body: jsonEncode({'id_token': idToken}),
      );

      print('GOOGLE LOGIN STATUS: ${response.statusCode}');
      print('GOOGLE LOGIN BODY:   ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', data['token']);
        return true;
      }
      return false;
    } catch (e) {
      print('GOOGLE LOGIN ERROR: $e');
      return false;
    }
  }

  // ── OBTENER USUARIO ──────────────────────────────────
  static Future<Map<String, dynamic>?> getUser() async {
    try {
      final headers = await _authHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/user'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      print('GET USER ERROR: $e');
      return null;
    }
  }

  // ── LOGOUT ───────────────────────────────────────────
  static Future<void> logout() async {
    try {
      final headers = await _authHeaders();
      await http.post(
        Uri.parse('$baseUrl/logout'),
        headers: headers,
      );
      await _googleSignIn.signOut();
    } catch (e) {
      print('LOGOUT ERROR: $e');
    } finally {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('token');
    }
  }
}