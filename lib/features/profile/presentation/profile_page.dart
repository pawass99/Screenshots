import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:screenshots/models/film.dart';
import 'package:screenshots/models/scene.dart';
import 'package:screenshots/theme/screenshot_colors.dart';
import 'package:screenshots/theme/screenshot_spacing.dart';
import 'package:screenshots/theme/screenshot_typography.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.films,
    required this.scenes,
    required this.savedCount,
  });

  final List<Film> films;
  final List<Scene> scenes;
  final int savedCount;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const _usernameLimit = 15;
  static const _bioLimit = 84;

  String _username = 'Aqsha Maulana';
  String _bio = 'just a guy who wants to share his collection. Idk';
  String? _bannerUrl;
  String? _avatarUrl;
  bool _isEditingProfile = false;
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: _username);
    _bioController = TextEditingController(text: _bio);
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  void _toggleProfileEditing() {
    if (!_isEditingProfile) {
      setState(() => _isEditingProfile = true);
      return;
    }

    setState(() {
      _username = _limitText(
        _usernameController.text.trim().isEmpty
            ? 'Archive User'
            : _usernameController.text.trim(),
        _usernameLimit,
      );
      _bio = _limitText(_bioController.text.trim(), _bioLimit);
      _usernameController.text = _username;
      _bioController.text = _bio;
      _isEditingProfile = false;
      // TODO(profile-backend): simpan username dan bio profile ke tabel profile user di Supabase.
    });
  }

  void _syncProfileTextControllers() {
    if (_isEditingProfile) {
      return;
    }

    _usernameController.text = _username;
    _bioController.text = _bio;
  }

  void _changeProfileImage({required _ProfileImageTarget target}) {
    final options = _profileImageOptions(
      films: widget.films,
      scenes: widget.scenes,
      preferWide: target == _ProfileImageTarget.banner,
    );

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: ScreenshotColors.surfaceLow,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              ScreenshotSpacing.mobileMargin,
              0,
              ScreenshotSpacing.mobileMargin,
              ScreenshotSpacing.xl,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  target == _ProfileImageTarget.banner
                      ? 'Choose Banner'
                      : 'Choose Profile Photo',
                  style: ScreenshotTypography.smallHeadline,
                ),
                const SizedBox(height: ScreenshotSpacing.md),
                SizedBox(
                  height: 112,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: options.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(width: ScreenshotSpacing.sm),
                    itemBuilder: (context, index) {
                      final imageUrl = options[index];

                      // Membuat pilihan gambar lokal sementara.
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            if (target == _ProfileImageTarget.banner) {
                              _bannerUrl = imageUrl;
                              // TODO(profile-backend): simpan banner profile URL/path ke Supabase Storage + tabel profile user.
                            } else {
                              _avatarUrl = imageUrl;
                              // TODO(profile-backend): simpan avatar profile URL/path ke Supabase Storage + tabel profile user.
                            }
                          });
                          Navigator.of(context).pop();
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: SizedBox(
                            width: target == _ProfileImageTarget.banner
                                ? 168
                                : 112,
                            height: 112,
                            child: _ProfileArchiveImage(imageUrl: imageUrl),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    _syncProfileTextControllers();

    final bannerUrl =
        _bannerUrl ??
        _firstUsableImage(
          widget.films.map((film) => film.heroImageUrl).toList(),
        );
    final avatarUrl =
        _avatarUrl ??
        _firstUsableImage(
          widget.scenes.map((scene) => scene.imageUrl).toList(),
        );
    final collections = _placeholderCollections(widget.scenes);

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(
            horizontal: ScreenshotSpacing.mobileMargin,
          ),
          sliver: SliverList.list(
            children: [
              const SizedBox(height: ScreenshotSpacing.xl),
              _ProfileHero(
                bannerUrl: bannerUrl,
                avatarUrl: avatarUrl,
                onChangeBanner: () =>
                    _changeProfileImage(target: _ProfileImageTarget.banner),
                onChangeAvatar: () =>
                    _changeProfileImage(target: _ProfileImageTarget.avatar),
              ),
              const SizedBox(height: 20),
              _ProfileIdentity(
                username: _limitText(_username, _usernameLimit),
                bio: _limitText(_bio, _bioLimit),
                isEditing: _isEditingProfile,
                usernameController: _usernameController,
                bioController: _bioController,
                usernameLimit: _usernameLimit,
                bioLimit: _bioLimit,
                onEditToggle: _toggleProfileEditing,
              ),
              const SizedBox(height: ScreenshotSpacing.section),
              Text(
                'Your Collection',
                style: ScreenshotTypography.bodyLarge.copyWith(
                  color: ScreenshotColors.onSurface,
                  fontFamily: ScreenshotTypography.authBodyFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  height: 1,
                ),
              ),
              const SizedBox(height: ScreenshotSpacing.lg),
              ...collections.map(
                (collection) => Padding(
                  padding: const EdgeInsets.only(bottom: ScreenshotSpacing.md),
                  child: _ProfileCollectionCard(collection: collection),
                ),
              ),
            ],
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 112)),
      ],
    );
  }
}

enum _ProfileImageTarget { banner, avatar }

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.bannerUrl,
    required this.avatarUrl,
    required this.onChangeBanner,
    required this.onChangeAvatar,
  });

  final String bannerUrl;
  final String avatarUrl;
  final VoidCallback onChangeBanner;
  final VoidCallback onChangeAvatar;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 286,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Membuat banner profile.
          Positioned.fill(
            bottom: 56,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(26),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _ProfileArchiveImage(imageUrl: bannerUrl),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x16000000), Color(0xB8111112)],
                      ),
                    ),
                  ),
                  Positioned(
                    right: ScreenshotSpacing.sm,
                    top: ScreenshotSpacing.sm,
                    child: _ProfileIconAction(
                      icon: Icons.image_outlined,
                      tooltip: 'Change banner',
                      onPressed: onChangeBanner,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Membuat profile picture yang overlap dengan banner.
          Positioned(
            bottom: 0,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 132,
                  height: 132,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: ScreenshotColors.deepestSurface,
                    border: Border.all(
                      color: ScreenshotColors.deepestSurface,
                      width: 12,
                    ),
                  ),
                  child: ClipOval(
                    child: _ProfileArchiveImage(imageUrl: avatarUrl),
                  ),
                ),
                Positioned(
                  right: 2,
                  bottom: 8,
                  child: _ProfileIconAction(
                    icon: Icons.photo_camera_outlined,
                    tooltip: 'Change profile photo',
                    onPressed: onChangeAvatar,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileIdentity extends StatelessWidget {
  const _ProfileIdentity({
    required this.username,
    required this.bio,
    required this.isEditing,
    required this.usernameController,
    required this.bioController,
    required this.usernameLimit,
    required this.bioLimit,
    required this.onEditToggle,
  });

  final String username;
  final String bio;
  final bool isEditing;
  final TextEditingController usernameController;
  final TextEditingController bioController;
  final int usernameLimit;
  final int bioLimit;
  final VoidCallback onEditToggle;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Membuat username profile.
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 34),
                  child: isEditing
                      ? _ProfileInlineTextField(
                          controller: usernameController,
                          maxLength: usernameLimit,
                          textAlign: TextAlign.center,
                          textStyle: _profileUsernameStyle,
                          textInputAction: TextInputAction.next,
                        )
                      : Text(
                          username,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: _profileUsernameStyle,
                        ),
                ),
              ),
              Positioned(
                right: 0,
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: IconButton(
                    onPressed: onEditToggle,
                    padding: EdgeInsets.zero,
                    tooltip: isEditing
                        ? 'Save profile text'
                        : 'Edit profile text',
                    icon: Icon(
                      isEditing ? Icons.check_rounded : Icons.edit_outlined,
                      size: isEditing ? 18 : 14,
                    ),
                    color: ScreenshotColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: ScreenshotSpacing.sm),
        // Membuat deskripsi bio profile.
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: isEditing
              ? _ProfileInlineTextField(
                  controller: bioController,
                  maxLength: bioLimit,
                  maxLines: 3,
                  textAlign: TextAlign.center,
                  textStyle: _profileBioStyle,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => onEditToggle(),
                )
              : Text(
                  bio.isEmpty ? 'A quiet collector of cinematic frames.' : bio,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: _profileBioStyle,
                ),
        ),
      ],
    );
  }

  TextStyle get _profileUsernameStyle =>
      ScreenshotTypography.bodyLarge.copyWith(
        color: ScreenshotColors.onSurface,
        fontFamily: ScreenshotTypography.authBodyFamily,
        fontSize: 23,
        fontWeight: FontWeight.w600,
        height: 1,
      );

  TextStyle get _profileBioStyle => ScreenshotTypography.bodyMedium.copyWith(
    color: ScreenshotColors.onSurfaceVariant,
    fontSize: 17,
    height: 1.22,
    fontWeight: FontWeight.w100,
  );
}

class _ProfileInlineTextField extends StatelessWidget {
  const _ProfileInlineTextField({
    required this.controller,
    required this.maxLength,
    required this.textAlign,
    required this.textStyle,
    this.maxLines = 1,
    this.textInputAction,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final int maxLength;
  final TextAlign textAlign;
  final TextStyle textStyle;
  final int maxLines;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onSubmitted;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      textAlign: textAlign,
      textInputAction: textInputAction,
      onSubmitted: onSubmitted,
      cursorColor: ScreenshotColors.primary,
      style: textStyle,
      decoration: InputDecoration(
        isDense: true,
        counterText: '',
        contentPadding: const EdgeInsets.symmetric(
          horizontal: ScreenshotSpacing.xs,
          vertical: ScreenshotSpacing.xs,
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: ScreenshotColors.onSurfaceVariant.withValues(alpha: 0.34),
          ),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: ScreenshotColors.primary, width: 1.2),
        ),
      ),
    );
  }
}

class _ProfileIconAction extends StatelessWidget {
  const _ProfileIconAction({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ScreenshotSpacing.tapTarget,
      height: ScreenshotSpacing.tapTarget,
      child: IconButton(
        onPressed: onPressed,
        tooltip: tooltip,
        icon: Icon(icon, size: 19),
        color: Colors.white,
        style: IconButton.styleFrom(
          backgroundColor: Colors.black.withValues(alpha: 0.48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
          ),
        ),
      ),
    );
  }
}

class _ProfileCollectionCard extends StatelessWidget {
  const _ProfileCollectionCard({required this.collection});

  final _ProfileCollection collection;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 2.86,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Membuat thumbnail folder koleksi scene.
            _ProfileArchiveImage(imageUrl: collection.imageUrl),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x22000000),
                    Color(0x4D000000),
                    Color(0xC9000000),
                  ],
                  stops: [0, 0.5, 1],
                ),
              ),
            ),
            Positioned(
              left: ScreenshotSpacing.sm,
              right: ScreenshotSpacing.sm,
              bottom: ScreenshotSpacing.sm,
              child: Text(
                collection.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: ScreenshotTypography.bodyLarge.copyWith(
                  color: Colors.white,
                  fontFamily: ScreenshotTypography.authBodyFamily,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileArchiveImage extends StatelessWidget {
  const _ProfileArchiveImage({required this.imageUrl});

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

class _ProfileCollection {
  const _ProfileCollection({required this.name, required this.imageUrl});

  final String name;
  final String imageUrl;
}

List<_ProfileCollection> _placeholderCollections(List<Scene> scenes) {
  final names = [
    'room full of people',
    'romance scenes :)',
    'animation that i enjoy',
    'calm.',
  ];

  final imageUrls = scenes
      .where((scene) => scene.imageUrl.trim().isNotEmpty)
      .map((scene) => scene.imageUrl)
      .toList();

  return List.generate(names.length, (index) {
    final imageUrl = imageUrls.isEmpty
        ? ''
        : imageUrls[index % imageUrls.length];

    return _ProfileCollection(name: names[index], imageUrl: imageUrl);
  });
}

List<String> _profileImageOptions({
  required List<Film> films,
  required List<Scene> scenes,
  required bool preferWide,
}) {
  final filmImages = films
      .expand((film) => [film.heroImageUrl, film.posterUrl ?? ''])
      .where((imageUrl) => imageUrl.trim().isNotEmpty);
  final sceneImages = scenes
      .map((scene) => scene.imageUrl)
      .where((imageUrl) => imageUrl.trim().isNotEmpty);

  final ordered = preferWide
      ? [...filmImages, ...sceneImages]
      : [...sceneImages, ...filmImages];

  return ordered.toSet().take(12).toList();
}

String _firstUsableImage(List<String> imageUrls) {
  for (final imageUrl in imageUrls) {
    if (imageUrl.trim().isNotEmpty) {
      return imageUrl;
    }
  }

  return '';
}

String _limitText(String text, int maxLength) {
  final trimmed = text.trim();

  if (trimmed.length <= maxLength) {
    return trimmed;
  }

  return trimmed.substring(0, maxLength);
}
