import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:screenshots/models/film.dart';
import 'package:screenshots/models/scene.dart';
import 'package:screenshots/models/user_profile.dart';
import 'package:screenshots/services/profile_service.dart';
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
  static const _displayNameLimit = 32;
  static const _bioLimit = 160;

  final ProfileService _profileService = const ProfileService();
  final ImagePicker _imagePicker = ImagePicker();

  UserProfile? _profile;
  String _username = 'archive_user';
  String _displayName = 'Archive User';
  String _bio = '';
  String? _bannerUrl;
  String? _avatarUrl;
  String? _profileError;
  bool _isLoadingProfile = true;
  bool _isEditingProfile = false;
  bool _isSavingProfile = false;
  bool _isUploadingAvatar = false;
  bool _isUploadingBanner = false;
  late final TextEditingController _displayNameController;
  late final TextEditingController _bioController;

  @override
  void initState() {
    super.initState();
    _displayNameController = TextEditingController(text: _displayName);
    _bioController = TextEditingController(text: _bio);
    _loadProfile();
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoadingProfile = true;
      _profileError = null;
    });

    try {
      final profile = await _profileService.getCurrentProfile();
      if (!mounted) {
        return;
      }

      setState(() {
        _profile = profile;
        _username = profile.username;
        _displayName = _limitText(profile.displayName, _displayNameLimit);
        _bio = _limitText(profile.bio, _bioLimit);
        _avatarUrl = profile.avatarUrl;
        _bannerUrl = profile.bannerUrl;
        _displayNameController.text = _displayName;
        _bioController.text = _bio;
        _isLoadingProfile = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _profileError = error.toString();
        _isLoadingProfile = false;
      });
    }
  }

  Future<void> _toggleProfileEditing() async {
    if (_isSavingProfile || _isLoadingProfile) {
      return;
    }

    if (!_isEditingProfile) {
      setState(() => _isEditingProfile = true);
      return;
    }

    final profile = _profile;
    if (profile == null) {
      _showProfileMessage('Profile record is not ready yet.');
      return;
    }

    final displayName = _limitText(
      _displayNameController.text.trim().isEmpty
          ? profile.username
          : _displayNameController.text.trim(),
      _displayNameLimit,
    );
    final bio = _limitText(_bioController.text.trim(), _bioLimit);

    setState(() => _isSavingProfile = true);

    try {
      final updated = await _profileService.saveProfile(
        profile.copyWith(displayName: displayName, bio: bio),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = updated;
        _displayName = displayName;
        _bio = bio;
        _displayNameController.text = displayName;
        _bioController.text = bio;
        _isEditingProfile = false;
      });
    } catch (error) {
      if (mounted) {
        _showProfileMessage(_profileFailureMessage(error));
      }
    } finally {
      if (mounted) {
        setState(() => _isSavingProfile = false);
      }
    }
  }

  Future<void> _changeProfileImage({
    required _ProfileImageTarget target,
  }) async {
    final isBanner = target == _ProfileImageTarget.banner;
    if (_isLoadingProfile || _isUploadingAvatar || _isUploadingBanner) {
      return;
    }

    final pickedImage = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: isBanner ? 88 : 92,
      maxWidth: isBanner ? 2200 : 1200,
    );

    if (pickedImage == null) {
      return;
    }

    setState(() {
      if (isBanner) {
        _isUploadingBanner = true;
      } else {
        _isUploadingAvatar = true;
      }
    });

    try {
      final bytes = await pickedImage.readAsBytes();
      final imageUrl = await _profileService.uploadProfileImage(
        kind: isBanner ? ProfileImageKind.banner : ProfileImageKind.avatar,
        bytes: bytes,
        fileName: pickedImage.name,
        contentType: pickedImage.mimeType,
      );

      final profile = _profile ?? await _profileService.getCurrentProfile();
      final updated = await _profileService.saveProfile(
        isBanner
            ? profile.copyWith(bannerUrl: imageUrl)
            : profile.copyWith(avatarUrl: imageUrl),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _profile = updated;
        _username = updated.username;
        _displayName = _limitText(updated.displayName, _displayNameLimit);
        _bio = _limitText(updated.bio, _bioLimit);
        _displayNameController.text = _displayName;
        _bioController.text = _bio;
        if (isBanner) {
          _bannerUrl = imageUrl;
        } else {
          _avatarUrl = imageUrl;
        }
      });
    } catch (error) {
      if (mounted) {
        _showProfileMessage(_profileFailureMessage(error, isBanner: isBanner));
      }
    } finally {
      if (mounted) {
        setState(() {
          if (isBanner) {
            _isUploadingBanner = false;
          } else {
            _isUploadingAvatar = false;
          }
        });
      }
    }
  }

  void _syncProfileTextControllers() {
    if (_isEditingProfile) {
      return;
    }

    _displayNameController.text = _displayName;
    _bioController.text = _bio;
  }

  void _showProfileMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ScreenshotColors.surfaceHigh,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _profileFailureMessage(Object error, {bool? isBanner}) {
    final imageName = isBanner == true ? 'banner' : 'profile photo';
    if (error is ProfileServiceException) {
      return switch (error.operation) {
        ProfileOperation.upload =>
          'Unable to upload $imageName: ${error.message}',
        ProfileOperation.save =>
          'The image was uploaded, but the profile could not be updated: '
              '${error.message}',
        ProfileOperation.load => 'Unable to load profile: ${error.message}',
      };
    }

    return isBanner == null
        ? 'Unable to save profile.'
        : 'Unable to update $imageName.';
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
                isUploadingBanner: _isUploadingBanner,
                isUploadingAvatar: _isUploadingAvatar,
                onChangeBanner: () =>
                    _changeProfileImage(target: _ProfileImageTarget.banner),
                onChangeAvatar: () =>
                    _changeProfileImage(target: _ProfileImageTarget.avatar),
              ),
              const SizedBox(height: 20),
              if (_profileError != null) ...[
                _ProfileStatusMessage(
                  message: 'Profile could not be loaded.',
                  onRetry: _loadProfile,
                ),
                const SizedBox(height: ScreenshotSpacing.md),
              ] else if (_isLoadingProfile) ...[
                const _ProfileStatusMessage(message: 'Loading profile.'),
                const SizedBox(height: ScreenshotSpacing.md),
              ],
              _ProfileIdentity(
                displayName: _limitText(_displayName, _displayNameLimit),
                username: _username,
                bio: _limitText(_bio, _bioLimit),
                isEditing: _isEditingProfile,
                isSaving: _isSavingProfile,
                displayNameController: _displayNameController,
                bioController: _bioController,
                displayNameLimit: _displayNameLimit,
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

class _ProfileStatusMessage extends StatelessWidget {
  const _ProfileStatusMessage({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0x12EAE1DA),
        border: Border.all(color: ScreenshotColors.outlineVariant),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Padding(
        padding: const EdgeInsets.all(ScreenshotSpacing.sm),
        child: Row(
          children: [
            Expanded(
              child: Text(
                message,
                style: ScreenshotTypography.metadata.copyWith(
                  color: ScreenshotColors.onSurfaceVariant,
                  letterSpacing: 0,
                ),
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(width: ScreenshotSpacing.sm),
              TextButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  const _ProfileHero({
    required this.bannerUrl,
    required this.avatarUrl,
    required this.isUploadingBanner,
    required this.isUploadingAvatar,
    required this.onChangeBanner,
    required this.onChangeAvatar,
  });

  final String bannerUrl;
  final String avatarUrl;
  final bool isUploadingBanner;
  final bool isUploadingAvatar;
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
                      isLoading: isUploadingBanner,
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
                    isLoading: isUploadingAvatar,
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
    required this.displayName,
    required this.username,
    required this.bio,
    required this.isEditing,
    required this.isSaving,
    required this.displayNameController,
    required this.bioController,
    required this.displayNameLimit,
    required this.bioLimit,
    required this.onEditToggle,
  });

  final String displayName;
  final String username;
  final String bio;
  final bool isEditing;
  final bool isSaving;
  final TextEditingController displayNameController;
  final TextEditingController bioController;
  final int displayNameLimit;
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
                          controller: displayNameController,
                          maxLength: displayNameLimit,
                          textAlign: TextAlign.center,
                          textStyle: _profileUsernameStyle,
                          textInputAction: TextInputAction.next,
                        )
                      : Text(
                          displayName,
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
                    onPressed: isSaving ? null : onEditToggle,
                    padding: EdgeInsets.zero,
                    tooltip: isEditing
                        ? 'Save profile text'
                        : 'Edit profile text',
                    icon: isSaving
                        ? const SizedBox(
                            width: 15,
                            height: 15,
                            child: CircularProgressIndicator(strokeWidth: 1.7),
                          )
                        : Icon(
                            isEditing
                                ? Icons.check_rounded
                                : Icons.edit_outlined,
                            size: isEditing ? 18 : 14,
                          ),
                    color: ScreenshotColors.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (username.trim().isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            '@${username.trim()}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: ScreenshotTypography.metadata.copyWith(
              color: ScreenshotColors.outline,
              letterSpacing: 0,
            ),
          ),
        ],
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
    this.isLoading = false,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: ScreenshotSpacing.tapTarget,
      height: ScreenshotSpacing.tapTarget,
      child: IconButton(
        onPressed: isLoading ? null : onPressed,
        tooltip: tooltip,
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(icon, size: 19),
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
