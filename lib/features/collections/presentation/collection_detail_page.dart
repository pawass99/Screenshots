import 'package:flutter/material.dart';
import 'package:screenshots/models/collection_summary.dart';
import 'package:screenshots/models/scene.dart';
import 'package:screenshots/theme/screenshot_colors.dart';
import 'package:screenshots/theme/screenshot_spacing.dart';
import 'package:screenshots/theme/screenshot_typography.dart';
import 'package:screenshots/widgets/archive_background.dart';
import 'package:screenshots/widgets/archive_top_bar.dart';
import 'package:screenshots/widgets/scene_rail.dart';

class CollectionDetailPage extends StatelessWidget {
  const CollectionDetailPage({
    super.key,
    required this.collection,
    required this.onOpenScene,
  });

  final CollectionSummary collection;
  final ValueChanged<Scene> onOpenScene;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScreenshotColors.background,
      body: ArchiveBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              ArchiveTopBar(
                title: '',
                leading: ArchiveIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  semanticLabel: 'Back to profile',
                  onPressed: () => Navigator.of(context).maybePop(),
                ),
              ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          ScreenshotSpacing.mobileMargin,
                          ScreenshotSpacing.xxl,
                          ScreenshotSpacing.mobileMargin,
                          ScreenshotSpacing.lg,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              collection.name,
                              style: ScreenshotTypography.archiveDisplayTitle.copyWith(
                                fontSize: 44,
                                fontWeight: FontWeight.w800,
                                height: 0.9,
                              ),
                            ),
                            const SizedBox(height: ScreenshotSpacing.sm),
                            Text(
                              _itemLabel(collection.scenes.length),
                              style: ScreenshotTypography.bodyMedium.copyWith(
                                color: ScreenshotColors.outline,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        ScreenshotSpacing.mobileMargin,
                        ScreenshotSpacing.lg,
                        ScreenshotSpacing.mobileMargin,
                        ScreenshotSpacing.xxl,
                      ),
                      sliver: collection.scenes.isEmpty
                          ? const SliverToBoxAdapter(
                              child: _InlineArchiveMessage(
                                'No scene frames are connected to this collection yet.',
                              ),
                            )
                          : SliverToBoxAdapter(
                              child: SceneRail(
                                scenes: collection.scenes,
                                onSceneTap: onOpenScene,
                              ),
                            ),
                    ),
                    const SliverToBoxAdapter(child: SizedBox(height: 24)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _itemLabel(int count) => '$count ${count == 1 ? 'scene' : 'scenes'}';
}

class _InlineArchiveMessage extends StatelessWidget {
  const _InlineArchiveMessage(this.message);

  final String message;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x12EAE1DA),
        border: Border.all(color: ScreenshotColors.outlineVariant),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(ScreenshotSpacing.lg),
        child: Text(
          message,
          textAlign: TextAlign.center,
          style: ScreenshotTypography.metadata.copyWith(
            color: ScreenshotColors.onSurfaceVariant,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}
