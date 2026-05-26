// lib/models/app_user.dart

class AppUser {
  final String uid;
  final String username;
  final String email;
  final String phone;
  final String role;          // 'Teacher' | 'Student'
  final String? photoUrl;
  final DateTime createdAt;

  AppUser({
    required this.uid,
    required this.username,
    required this.email,
    required this.phone,
    required this.role,
    this.photoUrl,
    required this.createdAt,
  });

  // ── Firestore ↔ Dart conversion ────────────────────────────────────────────
  factory AppUser.fromMap(Map<String, dynamic> map, String uid) {
    return AppUser(
      uid:       uid,
      username:  map['username']  ?? '',
      email:     map['email']     ?? '',
      phone:     map['phone']     ?? '',
      role:      map['role']      ?? 'Student',
      photoUrl:  map['photoUrl'],
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() => {
    'username':  username,
    'email':     email,
    'phone':     phone,
    'role':      role,
    'photoUrl':  photoUrl,
    'createdAt': createdAt.toIso8601String(),
  };

  AppUser copyWith({
    String? username,
    String? email,
    String? phone,
    String? role,
    String? photoUrl,
  }) {
    return AppUser(
      uid:       uid,
      username:  username  ?? this.username,
      email:     email     ?? this.email,
      phone:     phone     ?? this.phone,
      role:      role      ?? this.role,
      photoUrl:  photoUrl  ?? this.photoUrl,
      createdAt: createdAt,
    );
  }
}
