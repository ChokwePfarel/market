import 'package:flutter_test/flutter_test.dart';
import 'package:market/domain/repositories/auth_repository.dart';
import 'package:market/features/auth/auth_bloc.dart';
import 'package:market/features/auth/auth_event.dart';
import 'package:market/features/auth/auth_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FakeAuthRepository implements AuthRepository {
  User? mockUser;
  bool shouldThrow = false;
  String errorMessage = 'Invalid login credentials';

  @override
  User? get currentUser => mockUser;

  @override
  Future<AuthResponse> login(String email, String password) async {
    if (shouldThrow) {
      throw AuthException(errorMessage);
    }
    return AuthResponse(
      session: Session(
        accessToken: 'fake-token',
        tokenType: 'bearer',
        user: mockUser ?? const User(id: 'user-123', appMetadata: {}, userMetadata: {}, aud: 'authenticated', createdAt: '2026-10-16'),
      ),
      user: mockUser ?? const User(id: 'user-123', appMetadata: {}, userMetadata: {}, aud: 'authenticated', createdAt: '2026-10-16'),
    );
  }

  @override
  Future<AuthResponse> signUp(String email, String password, String name) async {
    if (shouldThrow) throw AuthException('Sign up failed');
    return AuthResponse(
      session: null,
      user: const User(id: 'user-124', appMetadata: {}, userMetadata: {}, aud: 'authenticated', createdAt: '2026-10-16'),
    );
  }

  @override
  Future<void> logout() async {
    if (shouldThrow) throw Exception('Logout failed');
    mockUser = null;
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    if (shouldThrow) throw Exception('Reset failed');
  }

  @override
  Future<UserResponse> updatePassword(String newPassword) async {
    if (shouldThrow) throw Exception('Password update failed');
    return UserResponse.fromJson({'id': 'user-123'});
  }
}

void main() {
  late FakeAuthRepository fakeAuthRepository;
  late AuthBloc authBloc;

  setUp(() {
    fakeAuthRepository = FakeAuthRepository();
    authBloc = AuthBloc(fakeAuthRepository);
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc Critical Flow Tests', () {
    test('initial state is AuthInitial', () {
      expect(authBloc.state, isA<AuthInitial>());
    });

    test('AuthCheckRequested emits Unauthenticated when user is null', () async {
      fakeAuthRepository.mockUser = null;

      final expected = [isA<Unauthenticated>()];
      expectLater(authBloc.stream, emitsInOrder(expected));

      authBloc.add(AuthCheckRequested());
    });

    test('LoginRequested emits [AuthLoading, Authenticated] on success', () async {
      final expected = [
        isA<AuthLoading>(),
        isA<Authenticated>().having((a) => a.user.id, 'user id', 'user-123'),
      ];

      expectLater(authBloc.stream, emitsInOrder(expected));

      authBloc.add(LoginRequested('student@uct.ac.za', 'password123'));
    });

    test('LoginRequested emits [AuthLoading, AuthError] on invalid credentials', () async {
      fakeAuthRepository.shouldThrow = true;
      fakeAuthRepository.errorMessage = 'Invalid login credentials';

      final expected = [
        isA<AuthLoading>(),
        isA<AuthError>().having((e) => e.message, 'error message', contains('Incorrect email or password')),
      ];

      expectLater(authBloc.stream, emitsInOrder(expected));

      authBloc.add(LoginRequested('wrong@uct.ac.za', 'wrongpass'));
    });

    test('LogoutRequested emits [AuthLoading, Unauthenticated] on success', () async {
      final expected = [
        isA<AuthLoading>(),
        isA<Unauthenticated>(),
      ];

      expectLater(authBloc.stream, emitsInOrder(expected));

      authBloc.add(LogoutRequested());
    });
  });
}
