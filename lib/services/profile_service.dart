import 'dart:typed_data';

import 'package:screenshots/models/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum ProfileImageKind { avatar, banner }

enum ProfileOperation { load, save, upload }

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
