import 'package:supabase_flutter/supabase_flutter.dart';

class FilmService {
  const FilmService();

  Future<List<Map<String, dynamic>>> getFilms() async {
    final data = await Supabase.instance.client
        .from('films')
        .select(
          'id, tmdb_id, title, poster_url, background_url, description, release_year, created_at',
        )
        .order('created_at', ascending: false);

    return data.map((film) => Map<String, dynamic>.from(film)).toList();
  }
}
