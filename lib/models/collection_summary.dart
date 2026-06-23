import 'package:screenshots/models/scene.dart';

class CollectionSummary {
  const CollectionSummary({
    required this.id,
    required this.name,
    this.scenes = const [],
    this.createdAt,
  });

  final String id;
  final String name;
  final List<Scene> scenes;
  final DateTime? createdAt;

  factory CollectionSummary.fromMap(Map<String, dynamic> map) {
    final scenes = <Scene>[];
    final items = map['collection_items'];
    if (items is List) {
      for (final item in items) {
        if (item is! Map) {
          continue;
        }

        final scene = item['scenes'];
        if (scene is Map) {
          scenes.add(Scene.fromMap(Map<String, dynamic>.from(scene)));
        }
      }
    }

    return CollectionSummary(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString().trim() ?? '',
      scenes: scenes.where((scene) => scene.hasImage).toList(growable: false),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? ''),
    );
  }

  bool containsScene(String sceneId) {
    return scenes.any((scene) => scene.id == sceneId);
  }
}
