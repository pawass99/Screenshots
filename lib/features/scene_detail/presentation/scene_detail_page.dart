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
import 'package:screenshots/features/collections/presentation/save_to_collection_sheet.dart';
import 'package:screenshots/features/share/widgets/scene_story_template.dart';
import 'package:screenshots/services/instagram_story_share_service.dart';
import 'package:screenshots/services/profile_service.dart';
import 'package:screenshots/widgets/scene_rail.dart';

class SceneDetailPage extends StatefulWidget {
  const SceneDetailPage({
    super.key,
    required this.scene,
    required this.film,
    this.relatedScenes = const [],
    this.onRelatedSceneTap,
    this.isSaved = false,
    this.onSavedChanged,
    this.onCollectionChanged,
  });

  final Scene scene;
  final Film? film;
  final List<Scene> relatedScenes;
  final ValueChanged<Scene>? onRelatedSceneTap;
  final bool isSaved;
  final ValueChanged<bool>? onSavedChanged;
  final VoidCallback? onCollectionChanged;

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

  Future<void> _handleSaveToCollection() async {
    final result = await showSaveToCollectionSheet(
      context: context,
      scene: widget.scene,
      profileService: const ProfileService(),
    );

    if (result != null && mounted) {
      setState(() => _isSaved = result.isSaved);
      widget.onSavedChanged?.call(result.isSaved);
      widget.onCollectionChanged?.call();
    }
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
                  title: '',
                  leading: ArchiveIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    semanticLabel: 'Back',
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  trailing: _ShareButton(
                    scene: widget.scene,
                    description: widget.scene.description ?? '',
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
                            onPressed: _handleSaveToCollection,
                            variant: _isSaved
                                ? ArchiveButtonVariant.ghost
                                : ArchiveButtonVariant.primary,
                            textStyle: ScreenshotTypography.bodyMedium.copyWith(
                              fontFamily: ScreenshotTypography.uiFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: ScreenshotSpacing.lg),
                    Text(
                      widget.film?.title ?? 'Scene Archive',
                      style: ScreenshotTypography.metadata.copyWith(
                        fontFamily: ScreenshotTypography.filmTitleFamily,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0,
                      ),
                    ),
                    const SizedBox(height: ScreenshotSpacing.sm),
                    Text(
                      quote,
                      style: ScreenshotTypography.sceneDescription.copyWith(
                        color: ScreenshotColors.onSurfaceVariant,
                        fontSize: 16,
                        height: 1.36,
                      ),
                    ),
                    if (widget.scene.tags.isNotEmpty) ...[
                      const SizedBox(height: ScreenshotSpacing.md),
                      Wrap(
                        spacing: ScreenshotSpacing.xs,
                        runSpacing: ScreenshotSpacing.xs,
                        children: widget.scene.tags
                            .map((tag) => MetadataChip(label: tag))
                            .toList(),
                      ),
                    ],
                    if (widget.relatedScenes.isNotEmpty) ...[
                      const _DetailSectionTitle(title: 'Related Scenes'),
                      _RelatedSceneList(
                        scenes: widget.relatedScenes,
                        onSceneTap: widget.onRelatedSceneTap,
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

class _RelatedSceneList extends StatelessWidget {
  const _RelatedSceneList({required this.scenes, this.onSceneTap});

  final List<Scene> scenes;
  final ValueChanged<Scene>? onSceneTap;

  @override
  Widget build(BuildContext context) {
    return SceneRail(scenes: scenes, onSceneTap: onSceneTap);
  }
}

class _SceneHeroMedia extends StatelessWidget {
  const _SceneHeroMedia({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = (width / 1.78).clamp(190.0, 260.0);

    return ColoredBox(
      color: ScreenshotColors.deepestSurface,
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

class _ShareButton extends StatefulWidget {
  const _ShareButton({required this.scene, required this.description});

  final Scene scene;
  final String description;

  @override
  State<_ShareButton> createState() => _ShareButtonState();
}

class _ShareButtonState extends State<_ShareButton> {
  final InstagramStoryShareService _instagramStoryShareService =
      const InstagramStoryShareService();
  final GlobalKey _repaintBoundaryKey = GlobalKey();
  bool _isLoading = false;
  bool _isSharingToInstagram = false;

  Future<void> _handleShare() async {
    setState(() => _isLoading = true);
    String? avatarUrl;
    try {
      final profile = await const ProfileService().getCurrentProfile();
      avatarUrl = profile.avatarUrl;
    } catch (_) {
      // Ignore error and fall back to null avatar
    }

    if (!mounted) return;
    await _precacheStoryImages(avatarUrl);
    if (!mounted) return;
    setState(() => _isLoading = false);
    _showStoryDialog(avatarUrl);
  }

  Future<void> _precacheStoryImages(String? avatarUrl) async {
    final urls = [
      widget.scene.imageUrl,
      avatarUrl ?? '',
    ].where((url) => url.trim().isNotEmpty).toSet();

    for (final url in urls) {
      try {
        await precacheImage(CachedNetworkImageProvider(url), context);
      } catch (_) {
        // The story template has image fallbacks if a remote image fails.
      }
    }
  }

  void _showStoryDialog(String? avatarUrl) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(ScreenshotSpacing.lg),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: SceneStoryTemplate(
                        sceneImageUrl: widget.scene.imageUrl,
                        description: widget.description,
                        userProfileImageUrl: avatarUrl,
                        repaintBoundaryKey: _repaintBoundaryKey,
                      ),
                    ),
                  ),
                  const SizedBox(height: ScreenshotSpacing.lg),
                  Row(
                    children: [
                      ArchiveIconButton(
                        icon: Icons.close_rounded,
                        onPressed: _isSharingToInstagram
                            ? null
                            : () => Navigator.of(dialogContext).pop(),
                        semanticLabel: 'Close',
                      ),
                      const SizedBox(width: ScreenshotSpacing.sm),
                      Expanded(
                        child: ArchiveButton(
                          label: 'Instagram Story',
                          isLoading: _isSharingToInstagram,
                          onPressed: _isSharingToInstagram
                              ? null
                              : () => _shareToInstagramStory(
                                  dialogContext,
                                  setDialogState,
                                ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _shareToInstagramStory(
    BuildContext dialogContext,
    StateSetter setDialogState,
  ) async {
    setState(() => _isSharingToInstagram = true);
    setDialogState(() {});

    try {
      await _instagramStoryShareService.shareTemplate(_repaintBoundaryKey);
      if (dialogContext.mounted) {
        Navigator.of(dialogContext).pop();
      }
    } on InstagramStoryShareException catch (error) {
      _showShareMessage(error.message);
    } catch (_) {
      _showShareMessage('Could not share to Instagram Stories.');
    } finally {
      if (mounted) {
        setState(() => _isSharingToInstagram = false);
        if (dialogContext.mounted) {
          setDialogState(() {});
        }
      }
    }
  }

  void _showShareMessage(String message) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ScreenshotColors.surfaceHigh,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ArchiveIconButton(
      icon: Icons.ios_share_rounded,
      onPressed: _isLoading ? null : _handleShare,
      semanticLabel: 'Share scene',
    );
  }
}

class _DetailSectionTitle extends StatelessWidget {
  const _DetailSectionTitle({required this.title});

  final String title;

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
                fontSize: 21,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
