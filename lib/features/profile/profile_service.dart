
class UserProfile {
  final String id;
  final String name;
  final String email;
  final String? avatarUrl;
  final String? bio;
  final DateTime createdAt;
  final List<String> preferences;

  const UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
    this.bio,
    required this.createdAt,
    this.preferences = const [],
  });
}

class ProfileService {
  static UserProfile? _currentProfile;

  static UserProfile? get currentProfile => _currentProfile;

  static Future<UserProfile?> fetchProfile(String userId) async {
    // TODO: Implement actual API call
    await Future.delayed(const Duration(seconds: 1));
    return _currentProfile;
  }

  static Future<UserProfile?> updateProfile(UserProfile profile) async {
    // TODO: Implement actual update logic
    await Future.delayed(const Duration(seconds: 1));
    _currentProfile = profile;
    return profile;
  }

  static Future<void> deleteAccount(String userId) async {
    // TODO: Implement actual deletion logic
    await Future.delayed(const Duration(seconds: 1));
    _currentProfile = null;
  }
}
