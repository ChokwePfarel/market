import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../domain/entities/user_entity.dart';
import 'user_event.dart';
import 'user_state.dart';

class UserBloc extends Bloc<UserEvent, UserState> {
  final UserRepository _userRepository;

  UserBloc(this._userRepository) : super(UserInitial()) {
    on<LoadUserSubscription>(_onLoadUserSubscription);
    on<CreateUser>(_onCreateUser);
    on<LoadUserProfile>(_onLoadUserProfile);
    on<UpdateUserProfile>(_onUpdateUserProfile);
    on<WatchCurrentUser>(_onWatchCurrentUser);
  }

  Future<void> _onLoadUserSubscription(
    LoadUserSubscription event,
    Emitter<UserState> emit,
  ) async {

    // We use emit.forEach to stay reactive and avoid 'emit after complete' errors.

    return emit.forEach<UserEntity?>(
      _userRepository.watchCurrentUser(),
      onData: (user) {
        if (user != null) {
          return UserLoaded(user);
        }
        return UserInitial();
      },
      onError: (error, stackTrace) {
        return UserError(error.toString());
      },
    );
  }

  Future<void> _onCreateUser(
    CreateUser event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());
    try {
      await _userRepository.createUser(
        name: event.name,
        sex: event.sex,
        userType: event.userType,
        university: event.university,
        isVerified: event.isVerified,
        profileImageUrl: event.profileImageUrl,
      );

      add(const WatchCurrentUser());

    } catch (e) {
      emit(UserError(e.toString()));
      debugPrint('UserBloc: Error creating user: $e');
    }
  }

  Future<void> _onWatchCurrentUser(
    WatchCurrentUser event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());
    
    return emit.forEach<UserEntity?>(
      _userRepository.watchCurrentUser(),
      onData: (user) {
        if (user != null) {
          return UserLoaded(user);
        }
        return UserInitial();
      },
      onError: (error, stackTrace) {
        return UserError(error.toString());
      },
    );
  }

  Future<void> _onLoadUserProfile(
    LoadUserProfile event,
    Emitter<UserState> emit,
  ) async {
    emit(UserLoading());
    try {
      final user = await _userRepository.getUserProfile(event.userId);
      emit(UserLoaded(user));
    } catch (e) {
      emit(UserError(e.toString()));
    }
  }

  Future<void> _onUpdateUserProfile(
    UpdateUserProfile event,
    Emitter<UserState> emit,
  ) async {
    final currentState = state;
    if (currentState is UserLoaded) {
      final previousUser = currentState.user;
      
      // Optimistic update - only update allowed fields
      final updatedUser = previousUser.copyWith(
        name: event.name ?? previousUser.name,
        university: event.university ?? previousUser.university,
        profileImageUrl: event.localImagePath ?? previousUser.profileImageUrl,
        isVerified: event.isVerified ?? previousUser.isVerified,
      );
      
      emit(UserLoaded(updatedUser));

      try {
        await _userRepository.updateUserProfile(updatedUser, localImagePath: event.localImagePath);
      } catch (e) {
        // Revert on failure
        emit(UserLoaded(previousUser));
      }
    }
  }
}
