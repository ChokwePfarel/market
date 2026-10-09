import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRepository {
  Future<AuthResponse> login(String email, String password);
  Future<AuthResponse> signUp(String email, String password, String name);
  Future<void> logout();
  Future<void> sendPasswordResetEmail(String email);
  Future<UserResponse> updatePassword(String newPassword);
  User? get currentUser;
}

