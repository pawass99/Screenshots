import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:screenshots/services/film_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  static const _backgroundColor = Color(0xFF101010);
  static const _surfaceColor = Color(0xFF171717);
  static const _textColor = Colors.white;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final FilmService _filmService = const FilmService();
  late Future<List<Map<String, dynamic>>> _filmsFuture;

  @override
  void initState() {
    super.initState();
    _filmsFuture = _filmService.getFilms();
  }

  void _retryFetchFilms() {
    setState(() {
      _filmsFuture = _filmService.getFilms();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: HomePage._backgroundColor,
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<List<Map<String, dynamic>>>(
          future: _filmsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const _HomeLoadingState();
            }

            if (snapshot.hasError) {
              return _HomeErrorState(onRetry: _retryFetchFilms);
            }

            final films = snapshot.data ?? [];

            if (films.isEmpty) {
              return const _HomeEmptyState();
            }

            return _HomeContent(films: films);
          },
        ),
      ),
      bottomNavigationBar: const _ScreenShotBottomNavigation(),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent({required this.films});

  final List<Map<String, dynamic>> films;

  @override
  Widget build(BuildContext context) {
    final heroFilm = films.first;
    final featuredFilm = films.length > 1 ? films[1] : films.first;

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 22),
          sliver: SliverList.list(
            children: [
              const _ScreenShotHeader(),
              const SizedBox(height: 8),
              // Dummy hero data has been replaced by Supabase `films` rows.
              // Uses `background_url`, falling back to `poster_url`.
              _HeroFilmCard(film: heroFilm),
              const SizedBox(height: 24),
              const _SectionTitle('our collection'),
              const SizedBox(height: 8),
              // Dummy poster data has been replaced by Supabase `poster_url`.
              _CollectionPosterRail(collections: films),
              const SizedBox(height: 22),
              const _SectionTitle('see the scenes'),
              const SizedBox(height: 8),
              // Temporary homepage preview uses film artwork until a dedicated
              // `scenes` fetch is added by the scene module.
              _ScenePreviewCard(film: featuredFilm),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScreenShotHeader extends StatelessWidget {
  const _ScreenShotHeader();

  @override
  Widget build(BuildContext context) {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Text(
        'SCREENSHOT',
        style: TextStyle(
          color: HomePage._textColor,
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 0,
        ),
      ),
    );
  }
}

class _HeroFilmCard extends StatelessWidget {
  const _HeroFilmCard({required this.film});

  final Map<String, dynamic> film;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 0.86,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _NetworkCinemaImage(
              imageUrl: _filmBackgroundUrl(film),
              fit: BoxFit.cover,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x55000000),
                    Color(0x05000000),
                    Color(0xCC000000),
                  ],
                ),
              ),
            ),
            Center(
              child: const Text(
                'our movie picks.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            Positioned(
              left: 14,
              bottom: 14,
              child: Text(
                _filmTitle(film),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
    );
  }
}

class _CollectionPosterRail extends StatelessWidget {
  const _CollectionPosterRail({required this.collections});

  final List<Map<String, dynamic>> collections;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 108,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final posterWidth = (constraints.maxWidth * 0.2).clamp(58.0, 76.0);

          return ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: collections.length,
            separatorBuilder: (_, _) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final collection = collections[index];

              return _PosterCard(
                width: posterWidth,
                imageUrl: _filmPosterUrl(collection),
              );
            },
          );
        },
      ),
    );
  }
}

class _PosterCard extends StatelessWidget {
  const _PosterCard({required this.width, required this.imageUrl});

  final double width;
  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _NetworkCinemaImage(imageUrl: imageUrl, fit: BoxFit.cover),
      ),
    );
  }
}

class _ScenePreviewCard extends StatelessWidget {
  const _ScenePreviewCard({required this.film});

  final Map<String, dynamic> film;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 2.05,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            _NetworkCinemaImage(
              imageUrl: _filmBackgroundUrl(film),
              fit: BoxFit.cover,
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Color(0x88000000), Color(0x22000000)],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NetworkCinemaImage extends StatelessWidget {
  const _NetworkCinemaImage({required this.imageUrl, required this.fit});

  final String imageUrl;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return const ColoredBox(
        color: HomePage._surfaceColor,
        child: Icon(Icons.image_not_supported_outlined, color: Colors.white38),
      );
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 220),
      fadeOutDuration: const Duration(milliseconds: 120),
      placeholder: (context, url) => const ColoredBox(
        color: HomePage._surfaceColor,
        child: Center(
          child: SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white54,
            ),
          ),
        ),
      ),
      errorWidget: (context, url, error) => const ColoredBox(
        color: HomePage._surfaceColor,
        child: Icon(Icons.broken_image_outlined, color: Colors.white38),
      ),
    );
  }
}

class _HomeLoadingState extends StatelessWidget {
  const _HomeLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: CircularProgressIndicator(color: Colors.white70),
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
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              color: Colors.white54,
              size: 32,
            ),
            const SizedBox(height: 12),
            const Text(
              'Unable to load movies.',
              style: TextStyle(color: Colors.white, fontSize: 15),
            ),
            const SizedBox(height: 14),
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
        padding: EdgeInsets.all(24),
        child: Text(
          'No movies yet.',
          style: TextStyle(color: Colors.white70, fontSize: 15),
        ),
      ),
    );
  }
}

class _ScreenShotBottomNavigation extends StatelessWidget {
  const _ScreenShotBottomNavigation();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 62 + MediaQuery.paddingOf(context).bottom,
      padding: EdgeInsets.only(bottom: MediaQuery.paddingOf(context).bottom),
      decoration: const BoxDecoration(
        color: Color(0xFF111111),
        border: Border(top: BorderSide(color: Color(0xFF242424))),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _BottomNavIcon(icon: Icons.home_filled, isActive: true),
          _BottomNavIcon(icon: Icons.search_rounded),
          _BottomNavIcon(icon: Icons.person_outline_rounded),
        ],
      ),
    );
  }
}

class _BottomNavIcon extends StatelessWidget {
  const _BottomNavIcon({required this.icon, this.isActive = false});

  final IconData icon;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      color: isActive ? Colors.white : Colors.white70,
      size: 24,
    );
  }
}

String _filmTitle(Map<String, dynamic> film) {
  return (film['title'] ?? 'Untitled').toString();
}

String _filmPosterUrl(Map<String, dynamic> film) {
  return (film['poster_url'] ?? '').toString();
}

String _filmBackgroundUrl(Map<String, dynamic> film) {
  final backgroundUrl = (film['background_url'] ?? '').toString();

  if (backgroundUrl.isNotEmpty) {
    return backgroundUrl;
  }

  return _filmPosterUrl(film);
}
