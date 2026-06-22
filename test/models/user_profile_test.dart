import 'package:flutter_test/flutter_test.dart';
import 'package:screenshots/models/user_profile.dart';

void main() {
  test('maps profile fields and falls back display name to username', () {
    final profile = UserProfile.fromMap(
      {
        'username': 'archive_user',
        'display_name': null,
        'bio': 'Collecting quiet frames.',
        'avatar_url': 'https://example.com/avatar.jpg',
        'banner_url': 'https://example.com/banner.jpg',
      },
      userId: 'user-1',
      fallbackUsername: 'fallback',
    );

    expect(profile.username, 'archive_user');
    expect(profile.displayName, 'archive_user');
    expect(profile.bio, 'Collecting quiet frames.');
    expect(profile.avatarUrl, 'https://example.com/avatar.jpg');
    expect(profile.bannerUrl, 'https://example.com/banner.jpg');
  });
}
