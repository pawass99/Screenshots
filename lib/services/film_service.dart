import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:screenshots/models/film.dart';

class FilmService {
  const FilmService();

  Future<List<Film>> getFilms() async {
    final data = await Supabase.instance.client
        .from('films')
        .select(
          'id, tmdb_id, title, poster_url, background_url, description, release_year, director, country, studio, created_at',
        )
        .order('created_at', ascending: false);

    return data
        .map((film) => Film.fromMap(Map<String, dynamic>.from(film)))
        .toList();
  }
}
