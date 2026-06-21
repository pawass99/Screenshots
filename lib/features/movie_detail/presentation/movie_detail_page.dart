import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:screenshots/features/scene_detail/presentation/scene_detail_page.dart';
import 'package:screenshots/models/film.dart';
import 'package:screenshots/models/scene.dart';
import 'package:screenshots/navigation/archive_page_route.dart';
import 'package:screenshots/theme/screenshot_colors.dart';
import 'package:screenshots/theme/screenshot_spacing.dart';
import 'package:screenshots/theme/screenshot_typography.dart';
import 'package:screenshots/widgets/archive_background.dart';
import 'package:screenshots/widgets/scene_frame.dart';

class MovieDetailPage extends StatelessWidget {
  const MovieDetailPage({
    super.key,
    required this.film,
    this.scenes = const [],
  });

  final Film film;
  final List<Scene> scenes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScreenshotColors.background,
      body: ArchiveBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _MovieDetailTopBar(
                onBack: () => Navigator.of(context).maybePop(),
              ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverToBoxAdapter(child: _MovieHero(film: film)),
                    SliverToBoxAdapter(child: _MovieRecord(film: film)),
                    SliverToBoxAdapter(
                      child: _SceneArchiveHeader(frameCount: scenes.length),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(
                        ScreenshotSpacing.mobileMargin,
                        0,
                        ScreenshotSpacing.mobileMargin,
                        ScreenshotSpacing.xxl,
                      ),
                      sliver: scenes.isEmpty
                          ? const SliverToBoxAdapter(
                              child: _InlineArchiveMessage(
                                'No scene frames are connected to this movie yet.',
                              ),
                            )
                          : SliverList.separated(
                              itemCount: scenes.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: ScreenshotSpacing.md),
                              itemBuilder: (context, index) {
                                final scene = scenes[index];
                                return SceneFrame(
                                  imageUrl: scene.imageUrl,
                                  title: scene.description ?? 'Selected frame',
                                  subtitle: film.title,
                                  aspectRatio: 1.72,
                                  borderRadius: 24,
                                  onTap: () {
                                    Navigator.of(context).push(
                                      ArchivePageRoute(
                                        builder: (_) => SceneDetailPage(
                                          scene: scene,
                                          film: film,
                                          relatedScenes: scenes
                                              .where(
                                                (item) => item.id != scene.id,
                                              )
                                              .take(4)
                                              .toList(),
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
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
}

class _MovieDetailTopBar extends StatelessWidget {
  const _MovieDetailTopBar({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: ScreenshotColors.background,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          ScreenshotSpacing.mobileMargin,
          ScreenshotSpacing.xs,
          ScreenshotSpacing.mobileMargin,
          ScreenshotSpacing.sm,
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 58),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Semantics(
                label: 'Back to movie archive',
                button: true,
                child: SizedBox(
                  width: ScreenshotSpacing.tapTarget,
                  height: ScreenshotSpacing.tapTarget,
                  child: IconButton(
                    onPressed: onBack,
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    iconSize: 20,
                    color: ScreenshotColors.onSurface,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shape: const CircleBorder(),
                    ),
                  ),
                ),
              ),
              Text(
                'SCREENSHOT',
                style: ScreenshotTypography.labelCaps.copyWith(
                  color: ScreenshotColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MovieHero extends StatelessWidget {
  const _MovieHero({required this.film});

  final Film film;

  @override
  Widget build(BuildContext context) {
    final height = (MediaQuery.sizeOf(context).height * 0.56).clamp(
      390.0,
      462.0,
    );

    return SizedBox(
      height: height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _HeroImage(imageUrl: film.heroImageUrl),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0x0817130F),
                  Color(0x1817130F),
                  Color(0xFF17130F),
                ],
                stops: [0, 0.42, 1],
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 1,
              color: ScreenshotColors.onSurface.withValues(alpha: 0.16),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroImage extends StatelessWidget {
  const _HeroImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return const ColoredBox(
        color: ScreenshotColors.surfaceLow,
        child: Icon(
          Icons.image_not_supported_outlined,
          color: ScreenshotColors.outline,
        ),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 220),
      placeholder: (context, url) => const ColoredBox(
        color: ScreenshotColors.surfaceLow,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      ),
      errorWidget: (context, url, error) => const ColoredBox(
        color: ScreenshotColors.surfaceLow,
        child: Icon(
          Icons.broken_image_outlined,
          color: ScreenshotColors.outline,
        ),
      ),
    );
  }
}

class _MovieRecord extends StatelessWidget {
  const _MovieRecord({required this.film});

  final Film film;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ScreenshotSpacing.mobileMargin,
        26,
        ScreenshotSpacing.mobileMargin,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            film.title,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: ScreenshotTypography.archiveDisplayTitle.copyWith(
              fontSize: 52,
              fontWeight: FontWeight.w800,
              height: 0.88,
            ),
          ),
          _MovieCreditGrid(film: film),
          Padding(
            padding: const EdgeInsets.only(top: ScreenshotSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 315),
              child: Text(
                film.description?.trim().isNotEmpty == true
                    ? film.description!.trim()
                    : 'This movie record is waiting for archive notes.',
                style: ScreenshotTypography.serifDescription.copyWith(
                  color: ScreenshotColors.onSurfaceVariant,
                  fontSize: 17,
                  height: 1.62,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MovieCreditGrid extends StatelessWidget {
  const _MovieCreditGrid({required this.film});

  final Film film;

  @override
  Widget build(BuildContext context) {
    final facts = [
      _MovieFact(label: 'Year', value: _metadataValue(film.releaseYear)),
      _MovieFact(label: 'Director', value: _metadataValue(film.director)),
      _MovieFact(label: 'Country', value: _metadataValue(film.country)),
      _MovieFact(label: 'Studio', value: _metadataValue(film.studio)),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 26, bottom: 0),
      child: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: ScreenshotColors.outlineVariant),
            bottom: BorderSide(color: ScreenshotColors.outlineVariant),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: ScreenshotSpacing.lg),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth =
                  (constraints.maxWidth - ScreenshotSpacing.lg) / 2;

              return Wrap(
                spacing: ScreenshotSpacing.lg,
                runSpacing: ScreenshotSpacing.md,
                children: facts
                    .map(
                      (fact) => SizedBox(
                        width: itemWidth,
                        child: _MovieCreditItem(fact: fact),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MovieCreditItem extends StatelessWidget {
  const _MovieCreditItem({required this.fact});

  final _MovieFact fact;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '${fact.label}: ${fact.value}',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            fact.label.toUpperCase(),
            style: ScreenshotTypography.labelCaps.copyWith(
              color: ScreenshotColors.outline,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            fact.value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: ScreenshotTypography.bodyMedium.copyWith(
              color: ScreenshotColors.onSurface,
              fontSize: 15,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}

class _MovieFact {
  const _MovieFact({required this.label, required this.value});

  final String label;
  final String value;
}

class _SceneArchiveHeader extends StatelessWidget {
  const _SceneArchiveHeader({required this.frameCount});

  final int frameCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ScreenshotSpacing.mobileMargin,
        34,
        ScreenshotSpacing.mobileMargin,
        ScreenshotSpacing.md,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Scene archive',
                  style: ScreenshotTypography.archiveSectionTitle.copyWith(
                    fontSize: 27,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _frameCountLabel(frameCount),
            style: ScreenshotTypography.bodyMedium.copyWith(
              color: ScreenshotColors.outline,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
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

String _frameCountLabel(int count) {
  if (count == 1) {
    return '1 frame';
  }

  return '$count frames';
}

String _metadataValue(Object? value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) {
    return 'Unknown';
  }

  return text;
}
