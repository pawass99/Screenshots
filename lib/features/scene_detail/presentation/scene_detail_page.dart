import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:screenshots/models/film.dart';
import 'package:screenshots/models/scene.dart';
import 'package:screenshots/theme/screenshot_colors.dart';
import 'package:screenshots/theme/screenshot_spacing.dart';
import 'package:screenshots/theme/screenshot_typography.dart';
import 'package:screenshots/widgets/archive_background.dart';
import 'package:screenshots/widgets/archive_button.dart';
import 'package:screenshots/widgets/archive_top_bar.dart';
import 'package:screenshots/widgets/metadata_chip.dart';
import 'package:screenshots/widgets/scene_frame.dart';

class SceneDetailPage extends StatefulWidget {
  const SceneDetailPage({
    super.key,
    required this.scene,
    required this.film,
    this.relatedScenes = const [],
    this.isSaved = false,
    this.onSavedChanged,
  });

  final Scene scene;
  final Film? film;
  final List<Scene> relatedScenes;
  final bool isSaved;
  final ValueChanged<bool>? onSavedChanged;

  @override
  State<SceneDetailPage> createState() => _SceneDetailPageState();
}

class _SceneDetailPageState extends State<SceneDetailPage> {
  late bool _isSaved;

  @override
  void initState() {
    super.initState();
    _isSaved = widget.isSaved;
  }

  void _toggleSaved() {
    setState(() => _isSaved = !_isSaved);
    widget.onSavedChanged?.call(_isSaved);
  }

  @override
  Widget build(BuildContext context) {
    final quote = widget.scene.description?.trim().isNotEmpty == true
        ? widget.scene.description!.trim()
        : 'A selected frame waiting for composition notes.';

    return Scaffold(
      backgroundColor: ScreenshotColors.background,
      body: ArchiveBackground(
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: ArchiveTopBar(
                  title: 'Scene Record',
                  leading: ArchiveIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    semanticLabel: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: _SceneHeroMedia(imageUrl: widget.scene.imageUrl),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  ScreenshotSpacing.mobileMargin,
                  ScreenshotSpacing.md,
                  ScreenshotSpacing.mobileMargin,
                  ScreenshotSpacing.xxl,
                ),
                sliver: SliverList.list(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: ArchiveButton(
                            label: _isSaved
                                ? 'Saved in Collection'
                                : 'Save to Collection',
                            onPressed: _toggleSaved,
                            variant: _isSaved
                                ? ArchiveButtonVariant.ghost
                                : ArchiveButtonVariant.primary,
                          ),
                        ),
                        const SizedBox(width: ScreenshotSpacing.sm),
                        const _ShareButton(),
                      ],
                    ),
                    const SizedBox(height: ScreenshotSpacing.lg),
                    Text(
                      widget.film?.title ?? 'Scene Archive',
                      style: ScreenshotTypography.metadata,
                    ),
                    const SizedBox(height: ScreenshotSpacing.sm),
                    Text(
                      quote,
                      style: ScreenshotTypography.serifDescription.copyWith(
                        color: ScreenshotColors.onSurfaceVariant,
                        fontSize: 16,
                        height: 1.36,
                      ),
                    ),
                    const SizedBox(height: ScreenshotSpacing.md),
                    Wrap(
                      spacing: ScreenshotSpacing.xs,
                      runSpacing: ScreenshotSpacing.xs,
                      children: const [
                        MetadataChip(label: 'Memory'),
                        MetadataChip(label: 'Composition'),
                        MetadataChip(label: 'Quiet'),
                      ],
                    ),
                    if (widget.relatedScenes.isNotEmpty) ...[
                      const _DetailSectionTitle(
                        title: 'Related Scenes',
                        meta: 'same mood',
                      ),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: widget.relatedScenes.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              mainAxisSpacing: ScreenshotSpacing.sm,
                              crossAxisSpacing: ScreenshotSpacing.sm,
                              childAspectRatio: 0.92,
                            ),
                        itemBuilder: (context, index) {
                          final scene = widget.relatedScenes[index];
                          return SceneFrame(
                            imageUrl: scene.imageUrl,
                            title: scene.description ?? 'Related frame',
                            aspectRatio: 1,
                            borderRadius: 16,
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SceneHeroMedia extends StatelessWidget {
  const _SceneHeroMedia({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = (width / 1.78).clamp(190.0, 260.0);

    return DecoratedBox(
      decoration: const BoxDecoration(
        color: ScreenshotColors.deepestSurface,
        border: Border(
          top: BorderSide(color: ScreenshotColors.outlineVariant),
          bottom: BorderSide(color: ScreenshotColors.outlineVariant),
        ),
      ),
      child: SizedBox(
        width: double.infinity,
        height: height,
        child: imageUrl.trim().isEmpty
            ? const Icon(
                Icons.image_not_supported_outlined,
                color: ScreenshotColors.outline,
              )
            : CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.contain,
                alignment: Alignment.center,
                fadeInDuration: const Duration(milliseconds: 220),
                placeholder: (context, url) => const Center(
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
                errorWidget: (context, url, error) => const Icon(
                  Icons.broken_image_outlined,
                  color: ScreenshotColors.outline,
                ),
              ),
      ),
    );
  }
}

class _ShareButton extends StatelessWidget {
  const _ShareButton();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 52,
      height: ScreenshotSpacing.tapTarget,
      child: IconButton(
        onPressed: () {},
        icon: const Icon(Icons.ios_share_rounded),
        iconSize: 19,
        color: ScreenshotColors.onSurface,
        tooltip: 'Share scene',
        style: IconButton.styleFrom(
          backgroundColor: ScreenshotColors.surfaceLow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(2),
            side: const BorderSide(color: ScreenshotColors.outlineVariant),
          ),
        ),
      ),
    );
  }
}

class _DetailSectionTitle extends StatelessWidget {
  const _DetailSectionTitle({required this.title, required this.meta});

  final String title;
  final String meta;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        top: ScreenshotSpacing.xl,
        bottom: ScreenshotSpacing.sm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Text(
              title,
              style: ScreenshotTypography.archiveSectionTitle.copyWith(
                fontSize: 23,
              ),
            ),
          ),
          Text(meta.toUpperCase(), style: ScreenshotTypography.labelCaps),
        ],
      ),
    );
  }
}
