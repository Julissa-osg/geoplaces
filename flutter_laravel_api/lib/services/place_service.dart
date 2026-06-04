import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/place_model.dart';

class PlaceService {
  static const String baseUrl = 'http://127.0.0.1:8000/api';

  static Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  static Map<String, String> _headers(String token) => {
        'Accept': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // GET /api/places
  static Future<List<Place>> getPlaces() async {
    final token = await _getToken();
    if (token == null) return [];

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/places'),
        headers: {..._headers(token), 'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((e) => Place.fromJson(e)).toList();
      }
    } catch (e) {
      print('GET PLACES ERROR: $e');
    }
    return [];
  }

  // POST /api/places (multipart para soportar imagen)
  static Future<Place?> createPlace({
    required String name,
    required String description,
    required double latitude,
    required double longitude,
    File? imageFile,
  }) async {
    final token = await _getToken();
    if (token == null) return null;

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/places'),
      );
      request.headers.addAll(_headers(token));
      request.fields['name'] = name;
      request.fields['description'] = description;
      request.fields['latitude'] = latitude.toString();
      request.fields['longitude'] = longitude.toString();

      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', imageFile.path),
        );
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 201) {
        return Place.fromJson(jsonDecode(response.body));
      }
      print('CREATE PLACE ERROR: ${response.statusCode} ${response.body}');
    } catch (e) {
      print('CREATE PLACE ERROR: $e');
    }
    return null;
  }

  // POST /api/places/{id} (multipart para soportar imagen)
  static Future<Place?> updatePlace({
    required int id,
    required String name,
    required String description,
    required double latitude,
    required double longitude,
    File? imageFile,
  }) async {
    final token = await _getToken();
    if (token == null) return null;

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/places/$id'),
      );
      request.headers.addAll(_headers(token));
      request.fields['name'] = name;
      request.fields['description'] = description;
      request.fields['latitude'] = latitude.toString();
      request.fields['longitude'] = longitude.toString();

      if (imageFile != null) {
        request.files.add(
          await http.MultipartFile.fromPath('image', imageFile.path),
        );
      }

      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);

      if (response.statusCode == 200) {
        return Place.fromJson(jsonDecode(response.body));
      }
      print('UPDATE PLACE ERROR: ${response.statusCode} ${response.body}');
    } catch (e) {
      print('UPDATE PLACE ERROR: $e');
    }
    return null;
  }

  // DELETE /api/places/{id}
  static Future<bool> deletePlace(int id) async {
    final token = await _getToken();
    if (token == null) return false;

    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/places/$id'),
        headers: {..._headers(token), 'Content-Type': 'application/json'},
      );
      return response.statusCode == 200;
    } catch (e) {
      print('DELETE PLACE ERROR: $e');
      return false;
    }
  }
}
