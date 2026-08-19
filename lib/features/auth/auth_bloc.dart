import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;

  AuthBloc(this._authRepository) : super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<LoginRequested>(_onLoginRequested);
    on<SignUpRequested>(_onSignUpRequested);
    on<LogoutRequested>(_onLogoutRequested);
    on<SendPasswordResetRequested>(_onSendPasswordResetRequested);
    on<UpdatePasswordRequested>(_onUpdatePasswordRequested);
  }

  Future<void> _onAuthCheckRequested(
    AuthCheckRequested event,
    Emitter<AuthState> emit,
  ) async {
    final user = _authRepository.currentUser;
    if (user != null) {
      emit(Authenticated(user));
    } else {
      emit(Unauthenticated());
    }
  }

  Future<void> _onLoginRequested(
    LoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await _authRepository.login(event.email, event.password);
      final user = response.user;
      if (user != null) {
        emit(Authenticated(user));
      } else {
        emit(AuthError("Login failed. Please try again."));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSignUpRequested(
      SignUpRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());
    try {
      final response =
      await _authRepository.signUp(event.email, event.password, event.name);
      final user = response.user;
      if (user == null) {
        emit(AuthError("Sign up failed. Please try again."));
        return;
      }
      if (response.session == null) {
        // Confirm-email is on — no session until the link is clicked
        emit(EmailVerificationRequired(event.email));
      } else {
        emit(Authenticated(user));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }



  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.logout();
      emit(Unauthenticated());
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onSendPasswordResetRequested(
    SendPasswordResetRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      await _authRepository.sendPasswordResetEmail(event.email);
      emit(Unauthenticated()); // Or a specific state like PasswordResetEmailSent
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> _onUpdatePasswordRequested(
    UpdatePasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(AuthLoading());
    try {
      final response = await _authRepository.updatePassword(event.newPassword);
      if (response.user != null) {
        emit(Authenticated(response.user!));
      } else {
        emit(AuthError("Failed to update password."));
      }
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }
}
