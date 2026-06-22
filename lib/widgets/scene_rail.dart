import 'package:flutter/material.dart';
import 'package:screenshots/models/scene.dart';
import 'package:screenshots/theme/screenshot_spacing.dart';
import 'package:screenshots/widgets/scene_frame.dart';

class SceneRail extends StatelessWidget {
  const SceneRail({super.key, required this.scenes, this.onSceneTap});

  static const _aspectRatio = 1.72;

  final List<Scene> scenes;
  final ValueChanged<Scene>? onSceneTap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = (constraints.maxWidth * 0.88)
            .clamp(240.0, 340.0)
            .toDouble();

        return SizedBox(
          height: cardWidth / _aspectRatio,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            cacheExtent: 680,
            itemCount: scenes.length,
            separatorBuilder: (_, _) =>
                const SizedBox(width: ScreenshotSpacing.md),
            itemBuilder: (context, index) {
              final scene = scenes[index];

              return Semantics(
                button: onSceneTap != null,
                label: 'Open scene ${index + 1}',
                child: SizedBox(
                  width: cardWidth,
                  child: SceneFrame(
                    imageUrl: scene.imageUrl,
                    aspectRatio: _aspectRatio,
                    borderRadius: 24,
                    onTap: onSceneTap == null ? null : () => onSceneTap!(scene),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}
