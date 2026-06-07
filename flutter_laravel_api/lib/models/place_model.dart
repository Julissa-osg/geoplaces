class Place {
  final int id;
  final int userId;
  final String name;
  final String description;
  final double latitude;
  final double longitude;
  final String? image;
  final String? imageUrl;

  Place({
    required this.id,
    required this.userId,
    required this.name,
    required this.description,
    required this.latitude,
    required this.longitude,
    this.image,
    this.imageUrl,
  });

  factory Place.fromJson(Map<String, dynamic> json) {
    return Place(
      id: json['id'],
      userId: json['user_id'],
      name: json['name'],
      description: json['description'] ?? '',
      latitude: double.parse(json['latitude'].toString()),
      longitude: double.parse(json['longitude'].toString()),
      image: json['image'],
      imageUrl: json['image_url'],
    );
  }
}
// este es place_model.dart