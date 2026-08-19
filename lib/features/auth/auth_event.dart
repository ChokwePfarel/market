import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

class LoginRequested extends AuthEvent {
  final String email;
  final String password;
  LoginRequested(this.email, this.password);
}

class SignUpRequested extends AuthEvent {
  final String email;
  final String password;
  final String name;
  SignUpRequested(this.email, this.password, this.name);
}

class LogoutRequested extends AuthEvent {}

class SendPasswordResetRequested extends AuthEvent {
  final String email;
  SendPasswordResetRequested(this.email);
}

class UpdatePasswordRequested extends AuthEvent {
  final String newPassword;
  UpdatePasswordRequested(this.newPassword);
}
