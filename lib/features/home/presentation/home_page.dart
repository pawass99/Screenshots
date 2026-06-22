import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:screenshots/features/movie_detail/presentation/movie_detail_page.dart';
import 'package:screenshots/features/profile/presentation/profile_page.dart';
import 'package:screenshots/features/scene_detail/presentation/scene_detail_page.dart';
import 'package:screenshots/models/film.dart';
import 'package:screenshots/models/scene.dart';
import 'package:screenshots/navigation/archive_page_route.dart';
import 'package:screenshots/services/film_service.dart';
import 'package:screenshots/services/scene_service.dart';
import 'package:screenshots/theme/screenshot_colors.dart';
import 'package:screenshots/theme/screenshot_spacing.dart';
import 'package:screenshots/theme/screenshot_typography.dart';
import 'package:screenshots/widgets/archive_background.dart';
import 'package:screenshots/widgets/archive_bottom_nav.dart';
import 'package:screenshots/widgets/archive_search_box.dart';
import 'package:screenshots/widgets/archive_scene_card.dart';
import 'package:screenshots/widgets/archive_top_bar.dart';
import 'package:screenshots/widgets/scene_frame.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FilmService _filmService = const FilmService();
  final SceneService _sceneService = const SceneService();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _savedSearchController = TextEditingController();

  late Future<_HomeData> _homeFuture;
  int _tabIndex = 0;
  final Set<String> _savedSceneIds = <String>{};

  @override
  void initState() {
    super.initState();
    _homeFuture = _fetchHomeData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _savedSearchController.dispose();
    super.dispose();
  }

  Future<_HomeData> _fetchHomeData() async {
    final filmsFuture = _filmService.getFilms();
    final scenesFuture = _sceneService.getScenes();
    final films = await filmsFuture;
    final scenes = [...await scenesFuture]..shuffle();

    return _HomeData(films: films, scenes: scenes);
  }

  void _retryFetchHomeData() {
    setState(() {
      _homeFuture = _fetchHomeData();
    });
  }

  void _openMovie(Film film, List<Scene> scenes) {
    Navigator.of(context).push(
      ArchivePageRoute(
        builder: (_) => MovieDetailPage(film: film, scenes: scenes),
      ),
    );
  }

  void _openScene(Scene scene, _HomeData data) {
    final related = _relatedScenes(scene, data.scenes);

    Navigator.of(context).push(
      ArchivePageRoute(
        builder: (_) => SceneDetailPage(
          scene: scene,
          film: data.filmForScene(scene),
          relatedScenes: related,
          isSaved: _savedSceneIds.contains(scene.id),
          onSavedChanged: (isSaved) {
            setState(() {
              if (isSaved) {
                _savedSceneIds.add(scene.id);
              } else {
                _savedSceneIds.remove(scene.id);
              }
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ScreenshotColors.deepestSurface,
      body: ArchiveBackground(
        child: SafeArea(
          bottom: false,
          child: FutureBuilder<_HomeData>(
            future: _homeFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const _HomeLoadingState();
              }

              if (snapshot.hasError) {
                return _HomeErrorState(onRetry: _retryFetchHomeData);
              }

              final data = snapshot.data ?? const _HomeData();
              if (data.films.isEmpty && data.scenes.isEmpty) {
                return const _HomeEmptyState();
              }

              return Stack(
                children: [
                  IndexedStack(
                    index: _tabIndex,
                    children: [
                      _DiscoveryPage(
                        data: data,
                        onOpenMovie: _openMovie,
                        onOpenScene: (scene) => _openScene(scene, data),
                      ),
                      _SearchPage(
                        data: data,
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        onOpenScene: (scene) => _openScene(scene, data),
                      ),
                      _SavedPage(
                        data: data,
                        savedSceneIds: _effectiveSavedSceneIds(),
                        controller: _savedSearchController,
                        onChanged: (_) => setState(() {}),
                        onOpenScene: (scene) => _openScene(scene, data),
                      ),
                      ProfilePage(
                        films: data.films,
                        scenes: data.scenes,
                        savedCount: _effectiveSavedSceneIds().length,
                      ),
                    ],
                  ),
                  Align(
                    alignment: Alignment.bottomCenter,
                    child: ArchiveBottomNav(
                      currentIndex: _tabIndex,
                      onChanged: (index) => setState(() => _tabIndex = index),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Set<String> _effectiveSavedSceneIds() {
    return _savedSceneIds;
  }
}

class _HomeData {
  const _HomeData({this.films = const [], this.scenes = const []});

  final List<Film> films;
  final List<Scene> scenes;

  Film? filmForScene(Scene scene) {
    for (final film in films) {
      if (film.id == scene.filmId) {
        return film;
      }
    }

    return films.isEmpty ? null : films.first;
  }

  List<Scene> scenesForFilm(Film film) {
    final matching = scenes.where((scene) => scene.filmId == film.id).toList();
    return matching.isEmpty ? scenes : matching;
  }
}

class _DiscoveryPage extends StatelessWidget {
  const _DiscoveryPage({
    required this.data,
    required this.onOpenMovie,
    required this.onOpenScene,
  });

  final _HomeData data;
  final void Function(Film film, List<Scene> scenes) onOpenMovie;
  final ValueChanged<Scene> onOpenScene;

  @override
  Widget build(BuildContext context) {
    final visibleScenes = data.scenes.where((scene) => scene.hasImage).toList();

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: _HomeLogoTopBar()),
        SliverToBoxAdapter(
          child: _HeroArchiveCarousel(
            films: _heroFilms(data.films),
            onOpenMovie: (film) => onOpenMovie(film, data.scenesForFilm(film)),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: ScreenshotSpacing.mobileMargin,
          ),
          sliver: SliverList.list(
            children: [
              const SizedBox(height: ScreenshotSpacing.md),
              const _ArchiveSectionTitle(title: 'Our Films', meta: 'Swipe'),
              if (data.films.isEmpty)
                const _InlineArchiveMessage('No movie records yet.')
              else
                _PosterRail(
                  films: data.films,
                  onTap: (film) => onOpenMovie(film, data.scenesForFilm(film)),
                ),
              _ArchiveSectionTitle(
                title: 'Our Scenes',
                meta: visibleScenes.length.toString(),
              ),
              if (visibleScenes.isEmpty)
                const _InlineArchiveMessage('No saved light in that frame.'),
            ],
          ),
        ),
        if (visibleScenes.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(
              horizontal: ScreenshotSpacing.mobileMargin,
            ),
            sliver: SliverList.separated(
              itemCount: visibleScenes.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: ScreenshotSpacing.md),
              itemBuilder: (context, index) {
                final scene = visibleScenes[index];

                return ArchiveSceneCard(
                  scene: scene,
                  semanticLabel: 'Open scene ${index + 1}',
                  onTap: () => onOpenScene(scene),
                );
              },
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 112)),
      ],
    );
  }
}

class _SearchPage extends StatelessWidget {
  const _SearchPage({
    required this.data,
    required this.controller,
    required this.onChanged,
    required this.onOpenScene,
  });

  final _HomeData data;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<Scene> onOpenScene;

  @override
  Widget build(BuildContext context) {
    final results = _filterScenes(data.scenes, controller.text);

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(child: ArchiveTopBar(title: 'Search Archive')),
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: ScreenshotSpacing.mobileMargin,
          ),
          sliver: SliverList.list(
            children: [
              ArchiveSearchBox(
                controller: controller,
                hintText: 'Search by movie, scene, mood, tag',
                onChanged: onChanged,
                autofocus: false,
              ),
              const _ArchiveSectionTitle(
                title: 'Scene Matches',
                meta: 'Archive',
              ),
              if (results.isEmpty)
                const _InlineArchiveMessage('No frame matches that search.')
              else
                _SceneFeed(scenes: results, onOpenScene: onOpenScene),
            ],
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 112)),
      ],
    );
  }
}

class _SavedPage extends StatelessWidget {
  const _SavedPage({
    required this.data,
    required this.savedSceneIds,
    required this.controller,
    required this.onChanged,
    required this.onOpenScene,
  });

  final _HomeData data;
  final Set<String> savedSceneIds;
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final ValueChanged<Scene> onOpenScene;

  @override
  Widget build(BuildContext context) {
    final saved = data.scenes
        .where((scene) => savedSceneIds.contains(scene.id))
        .toList();
    final filtered = _filterScenes(saved, controller.text);

    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: ArchiveTopBar(title: 'Your Collection'),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: ScreenshotSpacing.mobileMargin,
          ),
          sliver: SliverList.list(
            children: [
              ArchiveSearchBox(
                controller: controller,
                hintText: 'Filter by movie or tag',
                onChanged: onChanged,
              ),
              const _ArchiveSectionTitle(
                title: 'Saved Scenes',
                meta: 'Private',
              ),
              if (filtered.isEmpty)
                const _InlineArchiveMessage(
                  'No saved scenes match that filter.',
                )
              else
                _SavedMasonry(scenes: filtered, onOpenScene: onOpenScene),
            ],
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 112)),
      ],
    );
  }
}

class _HomeLogoTopBar extends StatelessWidget {
  const _HomeLogoTopBar();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(
        left: ScreenshotSpacing.mobileMargin,
        top: 2,
        right: ScreenshotSpacing.mobileMargin,
        bottom: 2,
      ),
      // Membuat header home dengan logo vector Screenshot.
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: ScreenshotSpacing.tapTarget,
        ),
        child: Align(
          alignment: Alignment.centerLeft,
          child: SvgPicture.asset(
            'assets/images/screenshot_wordmark.svg',
            width: 168,
            height: 11,
            semanticsLabel: 'SCREENSHOT',
          ),
        ),
      ),
    );
  }
}

class _HeroArchiveCard extends StatelessWidget {
  const _HeroArchiveCard({required this.film, required this.onTap});

  final Film? film;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final heroHeight = (MediaQuery.sizeOf(context).width * 0.92).clamp(
      330.0,
      430.0,
    );

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: double.infinity,
        height: heroHeight,
        child: ClipRRect(
          borderRadius: BorderRadius.zero,
          child: Stack(
            fit: StackFit.expand,
            children: [
              _ArchiveImage(imageUrl: film?.heroImageUrl ?? ''),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0x08000000),
                      Color(0x11000000),
                      Color(0xDD111112),
                      ScreenshotColors.deepestSurface,
                    ],
                    stops: [0, 0.46, 0.82, 1],
                  ),
                ),
              ),
              Positioned(
                left: ScreenshotSpacing.md,
                right: ScreenshotSpacing.md,
                bottom: ScreenshotSpacing.md,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      film?.title ?? 'Archive Pending',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: ScreenshotTypography.archiveDisplayTitle.copyWith(
                        fontSize: 34,
                        height: 0.98,
                      ),
                    ),
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

class _HeroArchiveCarousel extends StatefulWidget {
  const _HeroArchiveCarousel({required this.films, required this.onOpenMovie});

  final List<Film> films;
  final ValueChanged<Film> onOpenMovie;

  @override
  State<_HeroArchiveCarousel> createState() => _HeroArchiveCarouselState();
}

class _HeroArchiveCarouselState extends State<_HeroArchiveCarousel> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.films.isEmpty) {
      return const _HeroArchiveCard(film: null, onTap: null);
    }

    // Membuat hero editor's frame yang bisa digeser horizontal.
    return Column(
      children: [
        SizedBox(
          height: (MediaQuery.sizeOf(context).width * 0.92).clamp(330.0, 430.0),
          child: PageView.builder(
            controller: _controller,
            physics: const BouncingScrollPhysics(),
            itemCount: widget.films.length,
            onPageChanged: (index) => setState(() => _index = index),
            itemBuilder: (context, index) {
              final film = widget.films[index];
              return _HeroArchiveCard(
                film: film,
                onTap: () => widget.onOpenMovie(film),
              );
            },
          ),
        ),
        if (widget.films.length > 1) ...[
          const SizedBox(height: ScreenshotSpacing.xs),
          // Membuat indikator posisi hero carousel.
          Semantics(
            label: 'Hero frame ${_index + 1} of ${widget.films.length}',
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.films.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutCubic,
                  width: index == _index ? 18 : 6,
                  height: 6,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: index == _index
                        ? ScreenshotColors.onSurface
                        : ScreenshotColors.onSurface.withValues(alpha: 0.28),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PosterRail extends StatelessWidget {
  const _PosterRail({required this.films, required this.onTap});

  final List<Film> films;
  final ValueChanged<Film> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 174,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: films.length,
        separatorBuilder: (_, _) => const SizedBox(width: ScreenshotSpacing.sm),
        itemBuilder: (context, index) {
          final film = films[index];
          return _PosterCard(film: film, onTap: () => onTap(film));
        },
      ),
    );
  }
}

class _PosterCard extends StatelessWidget {
  const _PosterCard({required this.film, required this.onTap});

  final Film film;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 116,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            fit: StackFit.expand,
            children: [
              _ArchiveImage(imageUrl: film.posterUrl ?? ''),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0x00000000), Color(0xD0000000)],
                  ),
                ),
              ),
              Positioned(
                left: ScreenshotSpacing.sm,
                right: ScreenshotSpacing.sm,
                bottom: ScreenshotSpacing.sm,
                child: Text(
                  film.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: ScreenshotTypography.metadata.copyWith(
                    color: ScreenshotColors.onSurface,
                    fontSize: 12,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SceneFeed extends StatelessWidget {
  const _SceneFeed({required this.scenes, required this.onOpenScene});

  final List<Scene> scenes;
  final ValueChanged<Scene> onOpenScene;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: scenes
          .map(
            (scene) => Padding(
              padding: const EdgeInsets.only(bottom: ScreenshotSpacing.md),
              child: ArchiveSceneCard(
                scene: scene,
                onTap: () => onOpenScene(scene),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SavedMasonry extends StatelessWidget {
  const _SavedMasonry({required this.scenes, required this.onOpenScene});

  final List<Scene> scenes;
  final ValueChanged<Scene> onOpenScene;

  @override
  Widget build(BuildContext context) {
    final left = <Scene>[];
    final right = <Scene>[];
    for (var i = 0; i < scenes.length; i += 1) {
      (i.isEven ? left : right).add(scenes[i]);
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _SavedColumn(scenes: left, onOpenScene: onOpenScene),
        ),
        const SizedBox(width: ScreenshotSpacing.sm),
        Expanded(
          child: _SavedColumn(scenes: right, onOpenScene: onOpenScene),
        ),
      ],
    );
  }
}

class _SavedColumn extends StatelessWidget {
  const _SavedColumn({required this.scenes, required this.onOpenScene});

  final List<Scene> scenes;
  final ValueChanged<Scene> onOpenScene;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: scenes
          .asMap()
          .entries
          .map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: ScreenshotSpacing.sm),
              child: SceneFrame(
                imageUrl: entry.value.imageUrl,
                aspectRatio: entry.key.isEven ? 0.78 : 0.92,
                borderRadius: 16,
                onTap: () => onOpenScene(entry.value),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ArchiveSectionTitle extends StatelessWidget {
  const _ArchiveSectionTitle({required this.title, required this.meta});

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
                height: 1,
              ),
            ),
          ),
          Text(meta.toUpperCase(), style: ScreenshotTypography.labelCaps),
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

class _ArchiveImage extends StatelessWidget {
  const _ArchiveImage({required this.imageUrl});

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

class _HomeLoadingState extends StatelessWidget {
  const _HomeLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: ScreenshotColors.primary),
    );
  }
}

class _HomeErrorState extends StatelessWidget {
  const _HomeErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ScreenshotSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: ScreenshotColors.onSurfaceVariant,
              size: 32,
            ),
            const SizedBox(height: ScreenshotSpacing.sm),
            Text(
              'Unable to load the archive.',
              style: ScreenshotTypography.bodyMedium.copyWith(
                color: ScreenshotColors.onSurface,
              ),
            ),
            const SizedBox(height: ScreenshotSpacing.md),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _HomeEmptyState extends StatelessWidget {
  const _HomeEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ScreenshotSpacing.xl),
        child: Text(
          'No archive records yet.',
          style: ScreenshotTypography.bodyMedium.copyWith(
            color: ScreenshotColors.onSurfaceVariant,
            fontSize: 15,
          ),
        ),
      ),
    );
  }
}

List<Film> _heroFilms(List<Film> films) {
  final withHero = films.where((film) => film.hasHeroImage).toList();
  final withoutHero = films.where((film) => !film.hasHeroImage).toList();

  return [...withHero, ...withoutHero];
}

List<Scene> _filterScenes(List<Scene> scenes, String query) {
  final normalizedQuery = query.trim().toLowerCase();

  return scenes.where((scene) {
    final description = scene.description?.toLowerCase() ?? '';
    final tags = scene.tags.join(' ').toLowerCase();
    final haystack = '${scene.id} ${scene.filmId} $description $tags';
    final queryMatch =
        normalizedQuery.isEmpty || haystack.contains(normalizedQuery);
    return scene.hasImage && queryMatch;
  }).toList();
}

List<Scene> _relatedScenes(Scene scene, List<Scene> scenes) {
  final related = scenes
      .where((item) => item.id != scene.id && item.filmId == scene.filmId)
      .toList();

  if (related.isNotEmpty) {
    return related.take(4).toList();
  }

  return scenes.where((item) => item.id != scene.id).take(4).toList();
}
