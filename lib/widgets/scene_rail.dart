import 'package:flutter/material.dart';
import 'package:screenshots/models/scene.dart';
import 'package:screenshots/theme/screenshot_spacing.dart';
import 'package:screenshots/widgets/archive_scene_card.dart';

class SceneRail extends StatelessWidget {
  const SceneRail({super.key, required this.scenes, this.onSceneTap});

  final List<Scene> scenes;
  final ValueChanged<Scene>? onSceneTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(scenes.length, (index) {
        final scene = scenes[index];

        return Padding(
          padding: EdgeInsets.only(
            bottom: index == scenes.length - 1 ? 0 : ScreenshotSpacing.md,
          ),
          child: ArchiveSceneCard(
            scene: scene,
            onTap: onSceneTap == null ? null : () => onSceneTap!(scene),
            semanticLabel: 'Open scene ${index + 1}',
          ),
        );
      }),
    );
  }
}
