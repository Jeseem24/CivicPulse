class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String role; // 'USER' or 'ADMIN'
  final String? departmentId; // e.g., 'ROADS_HIGHWAYS', 'WATER_SUPPLY', etc., or null

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.departmentId,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      role: json['role'] ?? 'USER',
      departmentId: json['departmentId'] ?? json['department_id'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'departmentId': departmentId,
    };
  }
}
