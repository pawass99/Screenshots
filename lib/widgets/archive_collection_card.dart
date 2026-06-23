import 'package:flutter/material.dart';
import 'package:screenshots/models/collection_summary.dart';
import 'package:screenshots/theme/screenshot_colors.dart';
import 'package:screenshots/theme/screenshot_spacing.dart';
import 'package:screenshots/widgets/archive_scene_card.dart';
import 'package:screenshots/widgets/scene_frame.dart';

class ArchiveCollectionCard extends StatelessWidget {
  const ArchiveCollectionCard({
    super.key,
    required this.collection,
    this.selected,
    this.onChanged,
    this.onTap,
  });

  static const borderRadius = ArchiveSceneCard.borderRadius;
  static const aspectRatio = ArchiveSceneCard.aspectRatio;

  final CollectionSummary collection;
  final bool? selected;
  final ValueChanged<bool>? onChanged;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final selectable = selected != null && onChanged != null;

    final card = Expanded(
      child: Semantics(
        button: selectable || onTap != null,
        selected: selected,
        label: '${collection.name}, ${_itemLabel(collection.scenes.length)}',
        child: SceneFrame(
          imageUrl: _coverImageUrl(collection),
          aspectRatio: aspectRatio,
          borderRadius: borderRadius,
          title: collection.name,
          subtitle: _itemLabel(collection.scenes.length),
          onTap: selectable ? () => onChanged!(!selected!) : onTap,
        ),
      ),
    );

    if (!selectable) {
      return Row(children: [card]);
    }

    return Row(
      children: [
        SizedBox(
          width: ScreenshotSpacing.tapTarget,
          height: ScreenshotSpacing.tapTarget,
          child: Checkbox(
            value: selected,
            onChanged: (value) => onChanged!(value ?? false),
            activeColor: ScreenshotColors.primary,
            checkColor: ScreenshotColors.onPrimary,
            side: const BorderSide(color: ScreenshotColors.outline),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(3)),
          ),
        ),
        const SizedBox(width: ScreenshotSpacing.xs),
        card,
      ],
    );
  }

  String _coverImageUrl(CollectionSummary collection) {
    return collection.scenes
            .where((scene) => scene.hasImage)
            .map((scene) => scene.imageUrl)
            .firstOrNull ??
        '';
  }

  String _itemLabel(int count) => '$count ${count == 1 ? 'Scene' : 'Scenes'}';
}
