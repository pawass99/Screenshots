class Scene {
  const Scene({
    required this.id,
    required this.filmId,
    required this.imageUrl,
    this.description,
    this.tags = const [],
    this.createdAt,
  });

  final String id;
  final String filmId;
  final String imageUrl;
  final String? description;
  final List<String> tags;
  final DateTime? createdAt;

  factory Scene.fromMap(Map<String, dynamic> map) {
    return Scene(
      id: map['id']?.toString() ?? '',
      filmId: map['film_id']?.toString() ?? '',
      imageUrl: map['image_url']?.toString().trim() ?? '',
      description: _parseNullableString(map['description']),
      tags: _parseTags(map),
      createdAt: _parseDateTime(map['created_at']),
    );
  }

  bool get hasImage => imageUrl.trim().isNotEmpty;
}

List<String> _parseTags(Map<String, dynamic> map) {
  final rawSceneTags = map['scene_tags'];
  final parsed = <String>[];

  if (rawSceneTags is List) {
    for (final sceneTag in rawSceneTags) {
      if (sceneTag is! Map) {
        continue;
      }

      final rawTag = sceneTag['tags'];
      if (rawTag is Map) {
        final tag = _parseNullableString(rawTag['name']);
        if (tag != null) {
          parsed.add(tag);
        }
      }
    }
  }

  final rawTags = map['tags'];
  if (rawTags is List) {
    for (final tag in rawTags) {
      if (tag is Map) {
        final name = _parseNullableString(tag['name']);
        if (name != null) {
          parsed.add(name);
        }
      } else {
        final name = _parseNullableString(tag);
        if (name != null) {
          parsed.add(name);
        }
      }
    }
  }

  return parsed.toSet().toList(growable: false);
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
