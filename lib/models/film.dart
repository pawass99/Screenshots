class Film {
  const Film({
    required this.id,
    this.tmdbId,
    required this.title,
    this.posterUrl,
    this.backgroundUrl,
    this.description,
    this.releaseYear,
    this.director,
    this.country,
    this.studio,
    this.createdAt,
  });

  final String id;
  final int? tmdbId;
  final String title;
  final String? posterUrl;
  final String? backgroundUrl;
  final String? description;
  final int? releaseYear;
  final String? director;
  final String? country;
  final String? studio;
  final DateTime? createdAt;

  factory Film.fromMap(Map<String, dynamic> map) {
    return Film(
      id: map['id']?.toString() ?? '',
      tmdbId: _parseInt(map['tmdb_id']),
      title: map['title']?.toString() ?? 'Untitled',
      posterUrl: _parseNullableString(map['poster_url']),
      backgroundUrl: _parseNullableString(map['background_url']),
      description: _parseNullableString(map['description']),
      releaseYear: _parseInt(map['release_year']),
      director: _parseNullableString(map['director']),
      country: _parseNullableString(map['country']),
      studio: _parseNullableString(map['studio']),
      createdAt: _parseDateTime(map['created_at']),
    );
  }

  bool get hasPoster => posterUrl != null && posterUrl!.trim().isNotEmpty;

  bool get hasBackground =>
      backgroundUrl != null && backgroundUrl!.trim().isNotEmpty;

  bool get hasHeroImage => hasBackground || hasPoster;

  String get heroImageUrl {
    final background = backgroundUrl?.trim();
    if (background != null && background.isNotEmpty) {
      return background;
    }

    return posterUrl?.trim() ?? '';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tmdb_id': tmdbId,
      'title': title,
      'poster_url': posterUrl,
      'background_url': backgroundUrl,
      'description': description,
      'release_year': releaseYear,
      'director': director,
      'country': country,
      'studio': studio,
      'created_at': createdAt?.toIso8601String(),
    };
  }
}

String? _parseNullableString(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) {
    return null;
  }

  return text;
}

int? _parseInt(dynamic value) {
  if (value == null) {
    return null;
  }

  if (value is int) {
    return value;
  }

  return int.tryParse(value.toString());
}

DateTime? _parseDateTime(dynamic value) {
  if (value == null) {
    return null;
  }

  return DateTime.tryParse(value.toString());
}
