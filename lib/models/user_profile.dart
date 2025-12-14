class UserProfile {
  final String id;
  final String username;
  final String email;

  UserProfile({required this.id, required this.username, required this.email});

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String,
      username: json['username'] as String? ?? 'Unknown',
      email: json['email'] as String? ?? '',
    );
  }
}
