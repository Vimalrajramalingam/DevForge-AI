class UserModel {
  final int id;
  final String email;
  final String fullName;
  final String createdAt;

  UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as int,
      email: json['email'] as String,
      fullName: json['full_name'] as String,
      createdAt: json['created_at'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'created_at': createdAt,
    };
  }
}
