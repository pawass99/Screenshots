import 'dart:typed_data';

import 'package:screenshots/models/collection_summary.dart';
import 'package:screenshots/models/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum ProfileImageKind { avatar, banner }

enum ProfileOperation { load, save, upload, collection }

class ProfileServiceException implements Exception {
  const ProfileServiceException({
    required this.operation,
    required this.message,
  });

  final ProfileOperation operation;
  final String message;

  @override
  String toString() => message;
}

class ProfileService {
  const ProfileService();

  SupabaseClient get _client => Supabase.instance.client;

  Future<UserProfile> getCurrentProfile() async {
    try {
      final user = _requireUser();
      final fallbackUsername = _fallbackUsername(user);
      final data = await _client
          .from('profiles')
          .select('username, display_name, bio, avatar_url, banner_url')
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) {
        return UserProfile.fallback(
          userId: user.id,
          username: fallbackUsername,
        );
      }

      return UserProfile.fromMap(
        Map<String, dynamic>.from(data),
        userId: user.id,
        fallbackUsername: fallbackUsername,
      );
    } on PostgrestException catch (error) {
      throw ProfileServiceException(
        operation: ProfileOperation.load,
        message: error.message,
      );
    }
  }

  Future<UserProfile> saveProfile(UserProfile profile) async {
    try {
      await _client.from('profiles').upsert(profile.toMap(), onConflict: 'id');
      return profile;
    } on PostgrestException catch (error) {
      throw ProfileServiceException(
        operation: ProfileOperation.save,
        message: error.message,
      );
    }
  }

  Future<void> ensureProfileExists() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    try {
      final data = await _client
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (data == null) {
        final rawMetadata = user.userMetadata ?? {};
        final String? fullName = rawMetadata['full_name'] ?? rawMetadata['name'];
        final String? avatarUrl = rawMetadata['avatar_url'] ?? rawMetadata['picture'];

        final newProfile = UserProfile(
          userId: user.id,
          username: fullName ?? _fallbackUsername(user),
          displayName: fullName ?? _fallbackUsername(user),
          bio: '',
          avatarUrl: avatarUrl,
        );

        await saveProfile(newProfile);
      }
    } catch (_) {
      // Ignore errors silently as this is an automated background step
    }
  }

  Future<List<CollectionSummary>> getCurrentUserCollections() async {
    final user = _requireUser();
    try {
      final data = await _client
          .from('collections')
          .select(
            'id, name, created_at, collection_items(scene_id, scenes(id, film_id, image_url, description, created_at, scene_tags(tags(name))))',
          )
          .eq('user_id', user.id)
          .order('created_at', ascending: false);

      return data
          .map(
            (collection) => CollectionSummary.fromMap(
              Map<String, dynamic>.from(collection),
            ),
          )
          .toList(growable: false);
    } on PostgrestException catch (error) {
      throw ProfileServiceException(
        operation: ProfileOperation.load,
        message: error.message,
      );
    }
  }

  Future<CollectionSummary> createCollection(String name) async {
    final user = _requireUser();
    final normalizedName = name.trim();
    if (normalizedName.isEmpty) {
      throw const ProfileServiceException(
        operation: ProfileOperation.collection,
        message: 'Collection name cannot be empty.',
      );
    }

    try {
      final data = await _client
          .from('collections')
          .insert({'user_id': user.id, 'name': normalizedName})
          .select('id, name, created_at')
          .single();

      return CollectionSummary.fromMap(Map<String, dynamic>.from(data));
    } on PostgrestException catch (error) {
      throw ProfileServiceException(
        operation: ProfileOperation.collection,
        message: error.message,
      );
    }
  }

  Future<void> syncSceneCollections({
    required String sceneId,
    required Set<String> initialCollectionIds,
    required Set<String> selectedCollectionIds,
  }) async {
    final user = _requireUser();
    try {
      final ownedRows = await _client
          .from('collections')
          .select('id')
          .eq('user_id', user.id);
      final ownedIds = ownedRows
          .map((row) => row['id']?.toString() ?? '')
          .where((id) => id.isNotEmpty)
          .toSet();
      final initial = initialCollectionIds.intersection(ownedIds);
      final selected = selectedCollectionIds.intersection(ownedIds);
      final toAdd = selected.difference(initial);
      final toRemove = initial.difference(selected);

      if (toAdd.isNotEmpty) {
        await _client.from('collection_items').upsert(
          toAdd
              .map(
                (collectionId) => {
                  'collection_id': collectionId,
                  'scene_id': sceneId,
                },
              )
              .toList(growable: false),
          onConflict: 'collection_id,scene_id',
        );
      }

      if (toRemove.isNotEmpty) {
        await _client
            .from('collection_items')
            .delete()
            .eq('scene_id', sceneId)
            .inFilter('collection_id', toRemove.toList(growable: false));
      }
    } on PostgrestException catch (error) {
      throw ProfileServiceException(
        operation: ProfileOperation.collection,
        message: error.message,
      );
    }
  }

  Future<String> uploadProfileImage({
    required ProfileImageKind kind,
    required Uint8List bytes,
    required String fileName,
    String? contentType,
  }) async {
    final user = _requireUser();
    final bucket = kind == ProfileImageKind.avatar ? 'avatars' : 'banners';
    final extension = _safeExtension(fileName);
    final path =
        '${user.id}/${DateTime.now().microsecondsSinceEpoch}.$extension';

    try {
      await _client.storage
          .from(bucket)
          .uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              cacheControl: '3600',
              contentType: contentType ?? _contentTypeFor(extension),
              upsert: false,
            ),
          );
    } on StorageException catch (error) {
      throw ProfileServiceException(
        operation: ProfileOperation.upload,
        message: error.message,
      );
    }

    return _client.storage.from(bucket).getPublicUrl(path);
  }

  User _requireUser() {
    final user = _client.auth.currentUser;
    if (user == null) {
      throw StateError('Your session has expired. Please sign in again.');
    }

    return user;
  }
}

String _fallbackUsername(User user) {
  final metadataUsername = user.userMetadata?['username']?.toString().trim();
  if (metadataUsername != null && metadataUsername.isNotEmpty) {
    return metadataUsername;
  }

  final emailPrefix = user.email?.split('@').first.trim();
  if (emailPrefix != null && emailPrefix.isNotEmpty) {
    return emailPrefix;
  }

  return 'archive_user';
}

String _safeExtension(String fileName) {
  final extension = fileName.contains('.')
      ? fileName.split('.').last.toLowerCase()
      : 'jpg';

  return switch (extension) {
    'jpeg' || 'jpg' || 'png' || 'webp' => extension,
    _ => 'jpg',
  };
}

String _contentTypeFor(String extension) {
  return switch (extension) {
    'png' => 'image/png',
    'webp' => 'image/webp',
    _ => 'image/jpeg',
  };
}
