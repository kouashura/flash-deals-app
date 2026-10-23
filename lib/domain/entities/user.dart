import 'package:equatable/equatable.dart';

class User extends Equatable {
  final String id;
  final String fullName;
  final String phone;
  final String email;
  final String? avatarUrl;
  final int loyaltyPoints;

  const User({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.email,
    this.avatarUrl,
    this.loyaltyPoints = 0,
  });

  @override
  List<Object?> get props => [id, fullName, phone, email];
}
