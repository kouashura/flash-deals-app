import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class CheckAuthStatus extends AuthEvent {
  const CheckAuthStatus();
}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;

  const LoginRequested({
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [email, password];
}

class RegisterRequested extends AuthEvent {
  final String fullName;
  final String phone;
  final String email;
  final String password;

  const RegisterRequested({
    required this.fullName,
    required this.phone,
    required this.email,
    required this.password,
  });

  @override
  List<Object?> get props => [fullName, phone, email, password];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class UpdateProfile extends AuthEvent {
  final String fullName;
  final String phone;
  final String? avatarUrl;

  const UpdateProfile({
    required this.fullName,
    required this.phone,
    this.avatarUrl,
  });

  @override
  List<Object?> get props => [fullName, phone, avatarUrl];
}
