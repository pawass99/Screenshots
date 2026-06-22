class UserProfile {
  const UserProfile({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.bio,
    this.avatarUrl,
    this.bannerUrl,
  });

  final String userId;
  final String username;
  final String displayName;
  final String bio;
  final String? avatarUrl;
  final String? bannerUrl;

  factory UserProfile.fromMap(
    Map<String, dynamic> map, {
    required String userId,
    required String fallbackUsername,
  }) {
    final username = _textOrNull(map['username']) ?? fallbackUsername;

    return UserProfile(
      userId: userId,
      username: username,
      displayName: _textOrNull(map['display_name']) ?? username,
      bio: _textOrNull(map['bio']) ?? '',
      avatarUrl: _textOrNull(map['avatar_url']),
      bannerUrl: _textOrNull(map['banner_url']),
    );
  }

  factory UserProfile.fallback({
    required String userId,
    required String username,
  }) {
    return UserProfile(
      userId: userId,
      username: username,
      displayName: username,
      bio: '',
    );
  }

  UserProfile copyWith({
    String? username,
    String? displayName,
    String? bio,
    String? avatarUrl,
    String? bannerUrl,
  }) {
    return UserProfile(
      userId: userId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      bio: bio ?? this.bio,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': userId,
      'username': username,
      'display_name': displayName,
      'bio': bio,
      'avatar_url': avatarUrl,
      'banner_url': bannerUrl,
    };
  }
}

String? _textOrNull(dynamic value) {
  final text = value?.toString().trim();
  if (text == null || text.isEmpty) {
    return null;
  }

  return text;
}
