import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:screenshots/features/movie_detail/presentation/movie_detail_page.dart';
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
import 'package:screenshots/widgets/archive_top_bar.dart';
import 'package:screenshots/widgets/metadata_chip.dart';
import 'package:screenshots/widgets/scene_frame.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FilmService _filmService = const FilmService();
  final SceneService _sceneService = const SceneService();
  final TextEditingController _homeSearchController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _savedSearchController = TextEditingController();

  late Future<_HomeData> _homeFuture;
  int _tabIndex = 0;
  String _homeTag = 'all';
  String _savedTag = 'all';
  final Set<String> _savedSceneIds = <String>{};

  static const _tags = [
    'all',
    'cinematography',
    'neon',
    'symmetry',
    'indie',
    'wide',
  ];

  @override
  void initState() {
    super.initState();
    _homeFuture = _fetchHomeData();
  }

  @override
  void dispose() {
    _homeSearchController.dispose();
    _searchController.dispose();
    _savedSearchController.dispose();
    super.dispose();
  }

  Future<_HomeData> _fetchHomeData() async {
    final filmsFuture = _filmService.getFilms();
    final scenesFuture = _sceneService.getScenes();

    return _HomeData(films: await filmsFuture, scenes: await scenesFuture);
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
                        queryController: _homeSearchController,
                        selectedTag: _homeTag,
                        tags: _tags,
                        onQueryChanged: (_) => setState(() {}),
                        onTagChanged: (tag) => setState(() => _homeTag = tag),
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
                        savedSceneIds: _effectiveSavedSceneIds(data.scenes),
                        controller: _savedSearchController,
                        selectedTag: _savedTag,
                        tags: _tags,
                        onChanged: (_) => setState(() {}),
                        onTagChanged: (tag) => setState(() => _savedTag = tag),
                        onOpenScene: (scene) => _openScene(scene, data),
                      ),
                      _ProfilePage(
                        films: data.films,
                        scenes: data.scenes,
                        savedCount: _effectiveSavedSceneIds(data.scenes).length,
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

  Set<String> _effectiveSavedSceneIds(List<Scene> scenes) {
    if (_savedSceneIds.isNotEmpty) {
      return _savedSceneIds;
    }

    return scenes.take(3).map((scene) => scene.id).toSet();
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
    required this.queryController,
    required this.selectedTag,
    required this.tags,
    required this.onQueryChanged,
    required this.onTagChanged,
    required this.onOpenMovie,
    required this.onOpenScene,
  });

  final _HomeData data;
  final TextEditingController queryController;
  final String selectedTag;
  final List<String> tags;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onTagChanged;
  final void Function(Film film, List<Scene> scenes) onOpenMovie;
  final ValueChanged<Scene> onOpenScene;

  @override
  Widget build(BuildContext context) {
    final filteredScenes = _filterScenes(
      data.scenes,
      queryController.text,
      selectedTag,
    );

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
              ArchiveSearchBox(
                controller: queryController,
                hintText: 'Search scenes, tags, directors',
                onChanged: onQueryChanged,
              ),
              const SizedBox(height: ScreenshotSpacing.sm),
              _TagRail(
                tags: tags,
                selectedTag: selectedTag,
                onTagChanged: onTagChanged,
              ),
              const _ArchiveSectionTitle(title: 'Our Films', meta: 'Swipe'),
              if (data.films.isEmpty)
                const _InlineArchiveMessage('No movie records yet.')
              else
                _PosterRail(
                  films: data.films,
                  onTap: (film) => onOpenMovie(film, data.scenesForFilm(film)),
                ),
              _ArchiveSectionTitle(
                title: 'Field of Frames',
                meta: filteredScenes.length.toString(),
              ),
              if (filteredScenes.isEmpty)
                const _InlineArchiveMessage('No saved light in that frame.')
              else
                _SceneFeed(
                  scenes: filteredScenes,
                  data: data,
                  onOpenScene: onOpenScene,
                ),
            ],
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
    final results = _filterScenes(data.scenes, controller.text, 'all');

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
                _SceneFeed(
                  scenes: results,
                  data: data,
                  onOpenScene: onOpenScene,
                ),
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
    required this.selectedTag,
    required this.tags,
    required this.onChanged,
    required this.onTagChanged,
    required this.onOpenScene,
  });

  final _HomeData data;
  final Set<String> savedSceneIds;
  final TextEditingController controller;
  final String selectedTag;
  final List<String> tags;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onTagChanged;
  final ValueChanged<Scene> onOpenScene;

  @override
  Widget build(BuildContext context) {
    final saved = data.scenes
        .where((scene) => savedSceneIds.contains(scene.id))
        .toList();
    final filtered = _filterScenes(saved, controller.text, selectedTag);

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
              const SizedBox(height: ScreenshotSpacing.sm),
              _TagRail(
                tags: tags,
                selectedTag: selectedTag,
                onTagChanged: onTagChanged,
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
                _SavedMasonry(
                  scenes: filtered,
                  data: data,
                  onOpenScene: onOpenScene,
                ),
            ],
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 112)),
      ],
    );
  }
}

class _ProfilePage extends StatelessWidget {
  const _ProfilePage({
    required this.films,
    required this.scenes,
    required this.savedCount,
  });

  final List<Film> films;
  final List<Scene> scenes;
  final int savedCount;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        const SliverToBoxAdapter(
          child: ArchiveTopBar(title: 'Archive Profile'),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: ScreenshotSpacing.mobileMargin,
          ),
          sliver: SliverList.list(
            children: [
              const SizedBox(height: ScreenshotSpacing.lg),
              Text(
                'Private index',
                style: ScreenshotTypography.archiveDisplayTitle.copyWith(
                  fontSize: 38,
                  height: 1,
                ),
              ),
              const SizedBox(height: ScreenshotSpacing.md),
              Text(
                'A quiet record of films, frames, and saved visual references.',
                style: ScreenshotTypography.bodyMedium,
              ),
              const SizedBox(height: ScreenshotSpacing.xxl),
              Row(
                children: [
                  _ProfileMetric(
                    label: 'MOVIES',
                    value: films.length.toString(),
                  ),
                  const SizedBox(width: ScreenshotSpacing.sm),
                  _ProfileMetric(
                    label: 'FRAMES',
                    value: scenes.length.toString(),
                  ),
                  const SizedBox(width: ScreenshotSpacing.sm),
                  _ProfileMetric(label: 'SAVED', value: savedCount.toString()),
                ],
              ),
              const _ArchiveSectionTitle(
                title: 'Composition Notes',
                meta: 'Local',
              ),
              const _InlineArchiveMessage(
                'Profile actions and account settings can be connected later without changing the archive shell.',
              ),
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
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
                    const _Badge(label: "Editor's frame"),
                    const SizedBox(height: ScreenshotSpacing.xs),
                    Text(
                      film?.title ?? 'Archive Pending',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: ScreenshotTypography.archiveDisplayTitle.copyWith(
                        fontSize: 34,
                        height: 0.98,
                      ),
                    ),
                    const SizedBox(height: ScreenshotSpacing.xs),
                    Text(
                      _filmMetaLine(film),
                      style: ScreenshotTypography.metadata.copyWith(
                        color: ScreenshotColors.onSurfaceVariant,
                        letterSpacing: 0,
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
                  style: const TextStyle(
                    color: ScreenshotColors.onSurface,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
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
  const _SceneFeed({
    required this.scenes,
    required this.data,
    required this.onOpenScene,
  });

  final List<Scene> scenes;
  final _HomeData data;
  final ValueChanged<Scene> onOpenScene;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: scenes
          .map(
            (scene) => Padding(
              padding: const EdgeInsets.only(bottom: ScreenshotSpacing.md),
              child: SceneFrame(
                imageUrl: scene.imageUrl,
                title: _sceneTitle(scene),
                subtitle: data.filmForScene(scene)?.title ?? 'Scene Archive',
                aspectRatio: 1.72,
                borderRadius: 24,
                onTap: () => onOpenScene(scene),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _SavedMasonry extends StatelessWidget {
  const _SavedMasonry({
    required this.scenes,
    required this.data,
    required this.onOpenScene,
  });

  final List<Scene> scenes;
  final _HomeData data;
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
          child: _SavedColumn(
            scenes: left,
            data: data,
            onOpenScene: onOpenScene,
          ),
        ),
        const SizedBox(width: ScreenshotSpacing.sm),
        Expanded(
          child: _SavedColumn(
            scenes: right,
            data: data,
            onOpenScene: onOpenScene,
          ),
        ),
      ],
    );
  }
}

class _SavedColumn extends StatelessWidget {
  const _SavedColumn({
    required this.scenes,
    required this.data,
    required this.onOpenScene,
  });

  final List<Scene> scenes;
  final _HomeData data;
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
                title: data.filmForScene(entry.value)?.title ?? 'Saved Frame',
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

class _TagRail extends StatelessWidget {
  const _TagRail({
    required this.tags,
    required this.selectedTag,
    required this.onTagChanged,
  });

  final List<String> tags;
  final String selectedTag;
  final ValueChanged<String> onTagChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: tags.length,
        separatorBuilder: (_, _) => const SizedBox(width: ScreenshotSpacing.xs),
        itemBuilder: (context, index) {
          final tag = tags[index];
          return MetadataChip(
            label: tag == 'all' ? 'All' : tag.replaceAll('-', ' '),
            isActive: tag == selectedTag,
            onPressed: () => onTagChanged(tag),
          );
        },
      ),
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

class _ProfileMetric extends StatelessWidget {
  const _ProfileMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0x12EAE1DA),
          border: Border.all(color: ScreenshotColors.outlineVariant),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Padding(
          padding: const EdgeInsets.all(ScreenshotSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: ScreenshotTypography.smallHeadline),
              const SizedBox(height: ScreenshotSpacing.xs),
              Text(label, style: ScreenshotTypography.labelCaps),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x22EAE1DA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: ScreenshotSpacing.sm,
          vertical: ScreenshotSpacing.xs,
        ),
        child: Text(label, style: ScreenshotTypography.metadata),
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
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(ScreenshotSpacing.xl),
        child: Text(
          'No archive records yet.',
          style: TextStyle(
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

List<Scene> _filterScenes(List<Scene> scenes, String query, String tag) {
  final normalizedQuery = query.trim().toLowerCase();

  return scenes.where((scene) {
    final description = scene.description?.toLowerCase() ?? '';
    final haystack = '${scene.id} ${scene.filmId} $description';
    final queryMatch =
        normalizedQuery.isEmpty || haystack.contains(normalizedQuery);
    final tagMatch = tag == 'all' || haystack.contains(tag);
    return scene.hasImage && queryMatch && tagMatch;
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

String _sceneTitle(Scene scene) {
  final description = scene.description?.trim();
  if (description != null && description.isNotEmpty) {
    return description;
  }

  return 'Selected frame';
}

String _filmMetaLine(Film? film) {
  if (film == null) {
    return 'Archive record waiting for a frame';
  }

  final year = film.releaseYear?.toString();
  if (year == null || year.isEmpty) {
    return 'Scene archive record';
  }

  return '$year · private visual reference';
}
