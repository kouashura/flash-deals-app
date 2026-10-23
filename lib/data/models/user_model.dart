import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.fullName,
    required super.phone,
    required super.email,
    super.avatarUrl,
    super.loyaltyPoints,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] as String,
      fullName: json['fullName'] as String,
      phone: json['phone'] as String,
      email: json['email'] as String,
      avatarUrl: json['avatarUrl'] as String?,
      loyaltyPoints: json['loyaltyPoints'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'phone': phone,
        'email': email,
        'avatarUrl': avatarUrl,
        'loyaltyPoints': loyaltyPoints,
      };
}
