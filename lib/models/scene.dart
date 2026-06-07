class Scene {
  const Scene({
    required this.id,
    required this.filmId,
    required this.imageUrl,
    this.description,
    this.createdAt,
  });

  final String id;
  final String filmId;
  final String imageUrl;
  final String? description;
  final DateTime? createdAt;

  factory Scene.fromMap(Map<String, dynamic> map) {
    return Scene(
      id: map['id']?.toString() ?? '',
      filmId: map['film_id']?.toString() ?? '',
      imageUrl: map['image_url']?.toString().trim() ?? '',
      description: _parseNullableString(map['description']),
      createdAt: _parseDateTime(map['created_at']),
    );
  }

  bool get hasImage => imageUrl.trim().isNotEmpty;
}

String? _parseNullableString(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) {
    return null;
  }

  return text;
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) {
    return null;
  }

  return DateTime.tryParse(value.toString());
}
