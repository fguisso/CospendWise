class User {
  final String id;
  final String name;
  final String email;
  final String? profilePicture;
  final DateTime? createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.profilePicture,
    this.createdAt,
  });

  // Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'profilePicture': profilePicture,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  // Create User from JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      profilePicture: json['profilePicture'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
    );
  }
} 