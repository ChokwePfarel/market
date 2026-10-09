import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/repositories/auth_repository.dart';
import '../data_source/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<AuthResponse> login(String email, String password) async {
    return await remoteDataSource.signInWithEmailPassword(email, password);
  }

  @override
  Future<AuthResponse> signUp(String email, String password, String name) async {
    return await remoteDataSource.signUpWithEmailPassword(email, password, name);
  }

  @override
  Future<void> logout() async {
    await remoteDataSource.signOut();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    await remoteDataSource.sendPasswordResetEmail(email);
  }

  @override
  Future<UserResponse> updatePassword(String newPassword) async {
    return await remoteDataSource.updatePassword(newPassword);
  }

  @override
  User? get currentUser => remoteDataSource.currentSession?.user;
}

