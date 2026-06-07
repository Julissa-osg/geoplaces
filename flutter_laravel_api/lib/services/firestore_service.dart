import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  static final _db = FirebaseFirestore.instance;
  static const _collection = 'places';

  // Guardar lugar en Firestore
  static Future<void> savePlace({
    required int id,
    required String name,
    required String description,
    required double latitude,
    required double longitude,
    String? imageUrl,
    required int userId,
  }) async {
    try {
      await _db.collection(_collection).doc(id.toString()).set({
        'id': id,
        'user_id': userId,
        'name': name,
        'description': description,
        'latitude': latitude,
        'longitude': longitude,
        'image_url': imageUrl ?? '',
        'created_at': FieldValue.serverTimestamp(),
      });
      print('FIRESTORE: lugar guardado correctamente');
    } catch (e) {
      print('FIRESTORE ERROR al guardar: $e');
    }
  }

  // Eliminar lugar de Firestore
  static Future<void> deletePlace(int id) async {
    try {
      await _db.collection(_collection).doc(id.toString()).delete();
      print('FIRESTORE: lugar eliminado correctamente');
    } catch (e) {
      print('FIRESTORE ERROR al eliminar: $e');
    }
  }
}