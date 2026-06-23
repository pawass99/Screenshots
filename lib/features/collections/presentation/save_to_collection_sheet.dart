import 'package:flutter/material.dart';
import 'package:screenshots/models/collection_summary.dart';
import 'package:screenshots/models/scene.dart';
import 'package:screenshots/services/profile_service.dart';
import 'package:screenshots/theme/screenshot_colors.dart';
import 'package:screenshots/theme/screenshot_spacing.dart';
import 'package:screenshots/theme/screenshot_typography.dart';
import 'package:screenshots/widgets/archive_button.dart';
import 'package:screenshots/widgets/archive_collection_card.dart';
import 'package:screenshots/widgets/archive_text_field.dart';

class SaveToCollectionResult {
  const SaveToCollectionResult({required this.isSaved});

  final bool isSaved;
}

Future<SaveToCollectionResult?> showSaveToCollectionSheet({
  required BuildContext context,
  required Scene scene,
  required ProfileService profileService,
}) {
  final disableMotion = MediaQuery.disableAnimationsOf(context);

  return showModalBottomSheet<SaveToCollectionResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    sheetAnimationStyle: AnimationStyle(
      duration: disableMotion ? Duration.zero : const Duration(milliseconds: 240),
      reverseDuration: disableMotion
          ? Duration.zero
          : const Duration(milliseconds: 180),
    ),
    builder: (_) => _SaveToCollectionSheet(
      scene: scene,
      profileService: profileService,
    ),
  );
}

class _SaveToCollectionSheet extends StatefulWidget {
  const _SaveToCollectionSheet({
    required this.scene,
    required this.profileService,
  });

  final Scene scene;
  final ProfileService profileService;

  @override
  State<_SaveToCollectionSheet> createState() =>
      _SaveToCollectionSheetState();
}

class _SaveToCollectionSheetState extends State<_SaveToCollectionSheet> {
  final TextEditingController _nameController = TextEditingController();

  List<CollectionSummary> _collections = const [];
  Set<String> _initialCollectionIds = const {};
  final Set<String> _selectedCollectionIds = <String>{};
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isCreating = false;
  bool _showCreateForm = false;
  String? _loadError;
  String? _createError;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _loadCollections();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _loadCollections() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });
    try {
      final collections = await widget.profileService
          .getCurrentUserCollections();
      if (!mounted) {
        return;
      }

      final selected = collections
          .where((collection) => collection.containsScene(widget.scene.id))
          .map((collection) => collection.id)
          .toSet();
      setState(() {
        _collections = collections;
        _initialCollectionIds = Set<String>.from(selected);
        _selectedCollectionIds
          ..clear()
          ..addAll(selected);
        _isLoading = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _loadError = _collectionFailureMessage(error);
        });
      }
    }
  }

  void _setSelected(String collectionId, bool selected) {
    setState(() {
      _saveError = null;
      if (selected) {
        _selectedCollectionIds.add(collectionId);
      } else {
        _selectedCollectionIds.remove(collectionId);
      }
    });
  }

  void _openCreateForm() {
    setState(() {
      _showCreateForm = true;
      _createError = null;
    });
  }

  void _closeCreateForm() {
    if (_isCreating) {
      return;
    }
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _showCreateForm = false;
      _createError = null;
      _nameController.clear();
    });
  }

  Future<void> _createCollection() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _createError = 'Collection name cannot be empty.');
      return;
    }

    setState(() {
      _isCreating = true;
      _createError = null;
    });
    try {
      final created = await widget.profileService.createCollection(name);
      if (!mounted) {
        return;
      }
      FocusManager.instance.primaryFocus?.unfocus();
      setState(() {
        _collections = [created, ..._collections];
        _selectedCollectionIds.add(created.id);
        _nameController.clear();
        _showCreateForm = false;
        _isCreating = false;
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _isCreating = false;
          _createError = _collectionFailureMessage(error);
        });
      }
    }
  }

  Future<void> _save() async {
    setState(() {
      _isSaving = true;
      _saveError = null;
    });
    try {
      await widget.profileService.syncSceneCollections(
        sceneId: widget.scene.id,
        initialCollectionIds: _initialCollectionIds,
        selectedCollectionIds: _selectedCollectionIds,
      );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(
        SaveToCollectionResult(isSaved: _selectedCollectionIds.isNotEmpty),
      );
    } catch (error) {
      if (mounted) {
        setState(() {
          _isSaving = false;
          _saveError = _collectionFailureMessage(error);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final disableMotion = MediaQuery.disableAnimationsOf(context);
    final keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedPadding(
      duration: disableMotion ? Duration.zero : const Duration(milliseconds: 180),
      curve: Curves.easeOutQuart,
      padding: EdgeInsets.only(bottom: keyboardInset),
      child: FractionallySizedBox(
        heightFactor: _showCreateForm ? 0.58 : 0.88,
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: ScreenshotColors.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Column(
            children: [
              const SizedBox(height: ScreenshotSpacing.sm),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: ScreenshotColors.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: disableMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 200),
                  switchInCurve: Curves.easeOutQuart,
                  switchOutCurve: Curves.easeInCubic,
                  child: _showCreateForm
                      ? _buildCreateForm()
                      : _buildCollectionPicker(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCollectionPicker() {
    return Column(
      key: const ValueKey('collection-picker'),
      children: [
        _SheetHeader(
          title: 'Save to Collection',
          onClose: _isSaving ? null : () => Navigator.of(context).pop(),
        ),
        Expanded(child: _buildPickerBody()),
        if (!_isLoading && _loadError == null && _collections.isNotEmpty)
          _PickerActions(
            isSaving: _isSaving,
            errorMessage: _saveError,
            onCancel: () => Navigator.of(context).pop(),
            onSave: _save,
          ),
      ],
    );
  }

  Widget _buildPickerBody() {
    if (_isLoading) {
      return const _CollectionLoadingState();
    }
    if (_loadError != null) {
      return _CenteredSheetState(
        message: _loadError!,
        actionLabel: 'Retry',
        onAction: _loadCollections,
      );
    }
    if (_collections.isEmpty) {
      return _CenteredSheetState(
        message: "You don't have any collections.",
        actionLabel: 'Create Collection',
        onAction: _openCreateForm,
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        ScreenshotSpacing.mobileMargin,
        ScreenshotSpacing.sm,
        ScreenshotSpacing.mobileMargin,
        ScreenshotSpacing.lg,
      ),
      itemCount: _collections.length,
      separatorBuilder: (_, _) =>
          const SizedBox(height: ScreenshotSpacing.sm),
      itemBuilder: (context, index) {
        final collection = _collections[index];
        return ArchiveCollectionCard(
          collection: collection,
          selected: _selectedCollectionIds.contains(collection.id),
          onChanged: (selected) => _setSelected(collection.id, selected),
        );
      },
    );
  }

  Widget _buildCreateForm() {
    return Column(
      key: const ValueKey('create-collection'),
      children: [
        _SheetHeader(title: 'Create Collection', onClose: _closeCreateForm),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: ScreenshotSpacing.mobileMargin,
              vertical: ScreenshotSpacing.lg,
            ),
            child: ArchiveTextField(
              controller: _nameController,
              label: 'Collection name',
              hintText: 'Name your collection',
              errorText: _createError,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _isCreating ? null : _createCollection(),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            ScreenshotSpacing.mobileMargin,
            ScreenshotSpacing.sm,
            ScreenshotSpacing.mobileMargin,
            ScreenshotSpacing.lg,
          ),
          child: Row(
            children: [
              Expanded(
                child: ArchiveButton(
                  label: 'Cancel',
                  onPressed: _isCreating ? null : _closeCreateForm,
                  variant: ArchiveButtonVariant.ghost,
                  textStyle: _buttonTextStyle,
                ),
              ),
              const SizedBox(width: ScreenshotSpacing.sm),
              Expanded(
                child: ArchiveButton(
                  label: 'Create',
                  onPressed: _isCreating ? null : _createCollection,
                  isLoading: _isCreating,
                  textStyle: _buttonTextStyle,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SheetHeader extends StatelessWidget {
  const _SheetHeader({required this.title, required this.onClose});

  final String title;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ScreenshotSpacing.mobileMargin,
        ScreenshotSpacing.sm,
        ScreenshotSpacing.xs,
        0,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: ScreenshotTypography.bodyLarge.copyWith(
                color: ScreenshotColors.onSurface,
                fontFamily: ScreenshotTypography.uiFamily,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SizedBox(
            width: ScreenshotSpacing.tapTarget,
            height: ScreenshotSpacing.tapTarget,
            child: IconButton(
              onPressed: onClose,
              tooltip: 'Close',
              icon: const Icon(Icons.close_rounded, size: 20),
              color: ScreenshotColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PickerActions extends StatelessWidget {
  const _PickerActions({
    required this.isSaving,
    required this.errorMessage,
    required this.onCancel,
    required this.onSave,
  });

  final bool isSaving;
  final String? errorMessage;
  final VoidCallback onCancel;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        ScreenshotSpacing.mobileMargin,
        ScreenshotSpacing.sm,
        ScreenshotSpacing.mobileMargin,
        ScreenshotSpacing.lg,
      ),
      child: Column(
        children: [
          if (errorMessage != null) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                errorMessage!,
                style: ScreenshotTypography.bodyMedium.copyWith(
                  color: ScreenshotColors.error,
                  fontFamily: ScreenshotTypography.uiFamily,
                  fontSize: 13,
                ),
              ),
            ),
            const SizedBox(height: ScreenshotSpacing.xs),
          ],
          Row(
            children: [
              Expanded(
                child: ArchiveButton(
                  label: 'Cancel',
                  onPressed: isSaving ? null : onCancel,
                  variant: ArchiveButtonVariant.ghost,
                  textStyle: _buttonTextStyle,
                ),
              ),
              const SizedBox(width: ScreenshotSpacing.sm),
              Expanded(
                child: ArchiveButton(
                  label: 'Save',
                  onPressed: isSaving ? null : onSave,
                  isLoading: isSaving,
                  textStyle: _buttonTextStyle,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CollectionLoadingState extends StatelessWidget {
  const _CollectionLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        72,
        ScreenshotSpacing.sm,
        ScreenshotSpacing.mobileMargin,
        ScreenshotSpacing.lg,
      ),
      itemCount: 3,
      separatorBuilder: (_, _) =>
          const SizedBox(height: ScreenshotSpacing.sm),
      itemBuilder: (_, _) => AspectRatio(
        aspectRatio: ArchiveCollectionCard.aspectRatio,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: ScreenshotColors.surfaceHigh,
            borderRadius: BorderRadius.circular(
              ArchiveCollectionCard.borderRadius,
            ),
          ),
        ),
      ),
    );
  }
}

class _CenteredSheetState extends StatelessWidget {
  const _CenteredSheetState({
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(ScreenshotSpacing.mobileMargin),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: ScreenshotTypography.bodyMedium.copyWith(
                color: ScreenshotColors.onSurfaceVariant,
                fontFamily: ScreenshotTypography.uiFamily,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: ScreenshotSpacing.lg),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 220),
              child: ArchiveButton(
                label: actionLabel,
                onPressed: onAction,
                textStyle: _buttonTextStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final TextStyle _buttonTextStyle = ScreenshotTypography.bodyMedium.copyWith(
  fontFamily: ScreenshotTypography.uiFamily,
  fontSize: 14,
  fontWeight: FontWeight.w500,
  letterSpacing: 0,
);

String _collectionFailureMessage(Object error) {
  if (error is ProfileServiceException) {
    return error.message;
  }
  return 'Unable to update collections right now.';
}
