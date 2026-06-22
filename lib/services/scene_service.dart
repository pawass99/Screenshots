import 'package:screenshots/models/scene.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SceneService {
  const SceneService();

  Future<List<Scene>> getScenes() async {
    final data = await Supabase.instance.client
        .from('scenes')
        .select(
          'id, film_id, image_url, description, created_at, scene_tags(tags(name))',
        )
        .order('created_at', ascending: false);

    return data
        .map((scene) => Scene.fromMap(Map<String, dynamic>.from(scene)))
        .toList();
  }
}
