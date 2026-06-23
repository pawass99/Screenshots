import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:screenshots/features/auth/presentation/login_page.dart';
import 'package:screenshots/models/collection_summary.dart';
import 'package:screenshots/models/film.dart';
import 'package:screenshots/models/scene.dart';
import 'package:screenshots/models/user_profile.dart';
import 'package:screenshots/navigation/archive_page_route.dart';
import 'package:screenshots/features/collections/presentation/collection_detail_page.dart';
import 'package:screenshots/services/auth_service.dart';
import 'package:screenshots/services/profile_service.dart';
import 'package:screenshots/theme/screenshot_colors.dart';
import 'package:screenshots/theme/screenshot_spacing.dart';
import 'package:screenshots/theme/screenshot_typography.dart';
import 'package:screenshots/widgets/archive_background.dart';
import 'package:screenshots/widgets/archive_button.dart';
import 'package:screenshots/widgets/archive_collection_card.dart';
import 'package:screenshots/widgets/archive_top_bar.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    required this.films,
    required this.scenes,
    required this.savedCount,
    required this.onOpenScene,
    this.collectionRevision = 0,
  });

  final List<Film> films;
  final List<Scene> scenes;
  final int savedCount;
  final ValueChanged<Scene> onOpenScene;
  final int collectionRevision;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final ProfileService _profileService = const ProfileService();

  UserProfile? _profile;
  String _username = 'archive_user';
  String _bio = '';
  String? _bannerUrl;
  String? _avatarUrl;
  String? _profileError;
  String? _collectionsError;
  List<CollectionSummary> _collections = const [];
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadCollections();
  }

  @override
  void didUpdateWidget(covariant ProfilePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.collectionRevision != widget.collectionRevision) {
      _loadCollections();
    }
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
        _bio = _limitText(profile.bio, _EditProfilePageState.bioLimit);
        _avatarUrl = profile.avatarUrl;
        _bannerUrl = profile.bannerUrl;
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

  Future<void> _loadCollections() async {
    try {
      final data = await _profileService.getCurrentUserCollections();
      if (!mounted) {
        return;
      }
      setState(() {
        _collections = data;
        _collectionsError = null;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _collectionsError = error.toString();
        });
      }
    }
  }

  Future<void> _openEditProfile() async {
    final profile = _profile;
    if (profile == null || _isLoadingProfile) {
      _showProfileMessage('Profile record is not ready yet.');
      return;
    }

    final updated = await Navigator.of(context).push<UserProfile>(
      ArchivePageRoute(
        builder: (_) =>
            _EditProfilePage(profile: profile, profileService: _profileService),
      ),
    );
    if (updated == null || !mounted) {
      return;
    }

    setState(() {
      _profile = updated;
      _username = updated.username;
      _bio = updated.bio;
      _avatarUrl = updated.avatarUrl;
      _bannerUrl = updated.bannerUrl;
    });
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

  @override
  Widget build(BuildContext context) {
    final bannerUrl = _bannerUrl ?? '';
    final avatarUrl = _avatarUrl ?? '';

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
                isUploadingBanner: false,
                isUploadingAvatar: false,
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
                username: _username,
                bio: _limitText(_bio, _EditProfilePageState.bioLimit),
                onEdit: _openEditProfile,
              ),
              const SizedBox(height: ScreenshotSpacing.section),
              Text(
                'Scenes Collection',
                style: ScreenshotTypography.bodyLarge.copyWith(
                  color: ScreenshotColors.onSurface,
                  fontFamily: ScreenshotTypography.uiFamily,
                  fontSize: 20,
                  fontWeight: FontWeight.w500,
                  height: 1,
                ),
              ),
              const SizedBox(height: ScreenshotSpacing.lg),
              if (_collectionsError != null)
                _ProfileStatusMessage(
                  message: 'Collections could not be loaded.',
                  onRetry: _loadCollections,
                )
              else if (_collections.isEmpty)
                Text(
                  "you don't have any collections",
                  style: ScreenshotTypography.bodyMedium.copyWith(
                    color: ScreenshotColors.onSurfaceVariant,
                    fontFamily: ScreenshotTypography.uiFamily,
                  ),
                )
              else
                ..._collections.map(
                  (collection) => Padding(
                    padding: const EdgeInsets.only(
                      bottom: ScreenshotSpacing.xl,
                    ),
                    child: _ProfileCollectionSection(
                      collection: collection,
                      onOpenScene: widget.onOpenScene,
                    ),
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

class _EditProfilePage extends StatefulWidget {
  const _EditProfilePage({required this.profile, required this.profileService});

  final UserProfile profile;
  final ProfileService profileService;

  @override
  State<_EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<_EditProfilePage> {
  static const usernameLimit = 32;
  static const bioLimit = 100;

  final ImagePicker _imagePicker = ImagePicker();
  final AuthService _authService = const AuthService();
  late final TextEditingController _usernameController;
  late final TextEditingController _bioController;
  String? _avatarUrl;
  String? _bannerUrl;
  String? _errorMessage;
  bool _isSaving = false;
  bool _isUploadingAvatar = false;
  bool _isUploadingBanner = false;
  bool _isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(text: widget.profile.username);
    _bioController = TextEditingController(text: widget.profile.bio);
    _avatarUrl = widget.profile.avatarUrl;
    _bannerUrl = widget.profile.bannerUrl;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _changeProfileImage(_ProfileImageTarget target) async {
    final isBanner = target == _ProfileImageTarget.banner;
    if (_isUploadingAvatar || _isUploadingBanner || _isSaving) {
      return;
    }

    final pickedImage = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: isBanner ? 88 : 92,
      maxWidth: isBanner ? 2200 : 1200,
    );
    if (pickedImage == null || !mounted) {
      return;
    }

    setState(() {
      _errorMessage = null;
      if (isBanner) {
        _isUploadingBanner = true;
      } else {
        _isUploadingAvatar = true;
      }
    });

    try {
      final imageUrl = await widget.profileService.uploadProfileImage(
        kind: isBanner ? ProfileImageKind.banner : ProfileImageKind.avatar,
        bytes: await pickedImage.readAsBytes(),
        fileName: pickedImage.name,
        contentType: pickedImage.mimeType,
      );
      if (!mounted) {
        return;
      }
      setState(() {
        if (isBanner) {
          _bannerUrl = imageUrl;
        } else {
          _avatarUrl = imageUrl;
        }
      });
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = _profileFailureMessage(error));
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

  Future<void> _save() async {
    final username = _usernameController.text.trim();
    if (username.isEmpty) {
      setState(() => _errorMessage = 'Username cannot be empty.');
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });
    try {
      final updated = await widget.profileService.saveProfile(
        widget.profile.copyWith(
          username: _limitText(username, usernameLimit),
          bio: _limitText(_bioController.text, bioLimit),
          avatarUrl: _avatarUrl,
          bannerUrl: _bannerUrl,
        ),
      );
      if (mounted) {
        Navigator.of(context).pop(updated);
      }
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = _profileFailureMessage(error));
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _logout() async {
    setState(() {
      _isLoggingOut = true;
      _errorMessage = null;
    });
    try {
      await _authService.signOut();
      if (!mounted) {
        return;
      }
      Navigator.of(context).pushAndRemoveUntil(
        ArchivePageRoute(builder: (_) => const LoginPage()),
        (_) => false,
      );
    } catch (_) {
      if (mounted) {
        setState(() => _errorMessage = 'Unable to log out right now.');
      }
    } finally {
      if (mounted) {
        setState(() => _isLoggingOut = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy =
        _isSaving || _isUploadingAvatar || _isUploadingBanner || _isLoggingOut;

    return Scaffold(
      backgroundColor: ScreenshotColors.background,
      body: ArchiveBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              ArchiveTopBar(
                title: 'Edit Profile',
                titleStyle: ScreenshotTypography.archiveHeadline.copyWith(
                  fontSize: 21,
                ),
                leading: ArchiveIconButton(
                  icon: Icons.arrow_back_ios_new_rounded,
                  semanticLabel: 'Back to profile',
                  onPressed: busy
                      ? null
                      : () => Navigator.of(context).maybePop(),
                ),
              ),
              Expanded(
                child: CustomScrollView(
                  slivers: [
                    SliverPadding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: ScreenshotSpacing.mobileMargin,
                      ),
                      sliver: SliverList.list(
                        children: [
                          _ProfileHero(
                            bannerUrl: _bannerUrl ?? '',
                            avatarUrl: _avatarUrl ?? '',
                            isUploadingBanner: _isUploadingBanner,
                            isUploadingAvatar: _isUploadingAvatar,
                            onChangeBanner: () =>
                                _changeProfileImage(_ProfileImageTarget.banner),
                            onChangeAvatar: () =>
                                _changeProfileImage(_ProfileImageTarget.avatar),
                          ),
                          const SizedBox(height: ScreenshotSpacing.lg),
                          const _EditFieldLabel('Username'),
                          _ProfileInlineTextField(
                            controller: _usernameController,
                            maxLength: usernameLimit,
                            textAlign: TextAlign.left,
                            textStyle: ScreenshotTypography.bodyLarge,
                            textInputAction: TextInputAction.next,
                          ),
                          const SizedBox(height: ScreenshotSpacing.lg),
                          const _EditFieldLabel('Bio'),
                          _ProfileInlineTextField(
                            controller: _bioController,
                            maxLength: bioLimit,
                            maxLines: 3,
                            textAlign: TextAlign.left,
                            textStyle: ScreenshotTypography.bodyMedium.copyWith(
                              color: ScreenshotColors.onSurface,
                            ),
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _save(),
                          ),
                          if (_errorMessage != null) ...[
                            const SizedBox(height: ScreenshotSpacing.md),
                            Text(
                              _errorMessage!,
                              style: ScreenshotTypography.metadata.copyWith(
                                color: ScreenshotColors.error,
                                letterSpacing: 0,
                              ),
                            ),
                          ],
                          const SizedBox(height: ScreenshotSpacing.xl),
                          ArchiveButton(
                            label: 'Save Profile',
                            onPressed: busy ? null : _save,
                            isLoading: _isSaving,
                            textStyle: ScreenshotTypography.bodyMedium.copyWith(
                              fontFamily: ScreenshotTypography.uiFamily,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0,
                            ),
                          ),
                          const SizedBox(height: ScreenshotSpacing.section),
                          ArchiveButton(
                            label: 'Logout',
                            onPressed: busy ? null : _logout,
                            isLoading: _isLoggingOut,
                            variant: ArchiveButtonVariant.ghost,
                          ),
                          const SizedBox(height: ScreenshotSpacing.xxl),
                        ],
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

class _EditFieldLabel extends StatelessWidget {
  const _EditFieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: ScreenshotSpacing.xs),
      child: Text(
        label.toUpperCase(),
        style: ScreenshotTypography.bodyMedium.copyWith(
          color: ScreenshotColors.onSurfaceVariant,
          fontFamily: ScreenshotTypography.uiFamily,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          height: 1.2,
        ),
      ),
    );
  }
}

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
    this.onChangeBanner,
    this.onChangeAvatar,
  });

  final String bannerUrl;
  final String avatarUrl;
  final bool isUploadingBanner;
  final bool isUploadingAvatar;
  final VoidCallback? onChangeBanner;
  final VoidCallback? onChangeAvatar;

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
                  if (onChangeBanner != null)
                    Positioned(
                      right: ScreenshotSpacing.sm,
                      top: ScreenshotSpacing.sm,
                      child: _ProfileIconAction(
                        icon: Icons.image_outlined,
                        tooltip: 'Change banner',
                        isLoading: isUploadingBanner,
                        onPressed: onChangeBanner!,
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
                if (onChangeAvatar != null)
                  Positioned(
                    right: 2,
                    bottom: 8,
                    child: _ProfileIconAction(
                      icon: Icons.photo_camera_outlined,
                      tooltip: 'Change profile photo',
                      isLoading: isUploadingAvatar,
                      onPressed: onChangeAvatar!,
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
    required this.onEdit,
  });

  final String username;
  final String bio;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: SizedBox(
            height: ScreenshotSpacing.tapTarget,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    username.trim(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: _profileUsernameStyle,
                  ),
                ),
                Positioned(
                  right: 0,
                  child: IconButton(
                    onPressed: onEdit,
                    tooltip: 'Edit profile',
                    icon: const Icon(Icons.edit_outlined),
                    iconSize: 19,
                    color: ScreenshotColors.onSurfaceVariant,
                    constraints: const BoxConstraints.tightFor(
                      width: ScreenshotSpacing.tapTarget,
                      height: ScreenshotSpacing.tapTarget,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: ScreenshotSpacing.sm),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 260),
          child: Text(
            bio,
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

  TextStyle get _profileBioStyle =>
      ScreenshotTypography.sceneDescription.copyWith(
        color: ScreenshotColors.onSurfaceVariant,
        fontSize: 17,
        height: 1.22,
        fontWeight: FontWeight.w400,
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

class _ProfileCollectionSection extends StatelessWidget {
  const _ProfileCollectionSection({
    required this.collection,
    required this.onOpenScene,
  });

  final CollectionSummary collection;
  final ValueChanged<Scene> onOpenScene;

  @override
  Widget build(BuildContext context) {
    return ArchiveCollectionCard(
      collection: collection,
      onTap: () {
        Navigator.of(context).push(
          ArchivePageRoute(
            builder: (_) => CollectionDetailPage(
              collection: collection,
              onOpenScene: onOpenScene,
            ),
          ),
        );
      },
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

String _profileFailureMessage(Object error) {
  if (error is ProfileServiceException) {
    return error.message;
  }
  return 'Unable to update profile.';
}

String _limitText(String text, int maxLength) {
  final trimmed = text.trim();

  if (trimmed.length <= maxLength) {
    return trimmed;
  }

  return trimmed.substring(0, maxLength);
}
