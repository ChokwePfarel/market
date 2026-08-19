import 'package:hive_flutter/adapters.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class AuthRemoteDataSource {
  Future<AuthResponse> signInWithEmailPassword(String email, String password);

  Future<AuthResponse> signUpWithEmailPassword(
    String email,
    String password,
    String name,
  );

  Future<void> signOut();

  Future<void> sendPasswordResetEmail(String email);

  Future<UserResponse> updatePassword(String newPassword);

  Session? get currentSession;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient client;

  AuthRemoteDataSourceImpl({required this.client});

  @override
  Future<AuthResponse> signInWithEmailPassword(
    String email,
    String password,
  ) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  @override
  Future<AuthResponse> signUpWithEmailPassword(
    String email,
    String password,
    String name,
  ) async {
    try {
      return await client.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': name},
       emailRedirectTo: 'marketapp://verify-callback',
      );
    } catch (e) {
      throw Exception('Error signing up: $e');
    }
  }

  @override
  Future<void> signOut() async {
    await client.auth.signOut();
    await Hive.deleteFromDisk(); // wipes all boxes
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await client.auth.resetPasswordForEmail(
      email,
      redirectTo: 'marketapp://reset-callback',
    );
  }

  @override
  Future<UserResponse> updatePassword(String newPassword) async {
    return await client.auth.updateUser(UserAttributes(password: newPassword));
  }



  @override
  Session? get currentSession => client.auth.currentSession;
}
