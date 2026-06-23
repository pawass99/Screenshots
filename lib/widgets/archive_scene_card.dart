import 'package:flutter/material.dart';
import 'package:screenshots/models/scene.dart';
import 'package:screenshots/widgets/scene_frame.dart';

class ArchiveSceneCard extends StatelessWidget {
  const ArchiveSceneCard({
    super.key,
    required this.scene,
    this.onTap,
    this.semanticLabel,
  });

  static const aspectRatio = 1.72;
  static const borderRadius = 18.0;

  final Scene scene;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: SceneFrame(
        imageUrl: scene.imageUrl,
        aspectRatio: aspectRatio,
        borderRadius: borderRadius,
        onTap: onTap,
      ),
    );
  }
}
