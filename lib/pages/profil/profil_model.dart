class UserProfile {
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String? avatar;
  final String role;
  final String? createdAt;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.avatar,
    required this.role,
    this.createdAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Print untuk debugging
    print('Parsing user profile: $json');
    
    return UserProfile(
      id: json['id'],
      name: json['name'],
      email: json['email'],
      phone: json['phone'],
      avatar: json['avatar'],
      role: json['role'] ?? 'user',
      createdAt: json['created_at'],
    );
  }

  // Mendapatkan URL lengkap avatar
  String get avatarUrl {
    if (avatar == null || avatar!.isEmpty) return '';
    
    // Jika avatar sudah berupa URL lengkap
    if (avatar!.startsWith('http')) return avatar!;
    
    // Jika tidak, gabungkan dengan base URL
    return 'http://127.0.0.1:8000/storage/$avatar';
  }
}


