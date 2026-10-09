import 'package:equatable/equatable.dart';

import '../../domain/entities/user_entity.dart';

abstract class UserEvent extends Equatable {
  const UserEvent();

  @override
  List<Object?> get props => [];
}

class LoadUserSubscription extends UserEvent {
  const LoadUserSubscription();

  @override
  List<Object?> get props => [];
}

class CreateUser extends UserEvent {
  final String name;
  final String sex;
  final String userType;
  final String university;
  final bool isVerified;
  final String profileImageUrl;

  const CreateUser({
    required this.name,
    required this.sex,
    required this.userType,
    required this.university,
    required this.isVerified,
    required this.profileImageUrl,
  });

  @override
  List<Object?> get props => [name, sex, userType, university, isVerified, profileImageUrl];
}

class LoadUserProfile extends UserEvent {
  final String userId;

  const LoadUserProfile(this.userId);

  @override
  List<Object?> get props => [userId];
}

class UpdateUserProfile extends UserEvent {
  final String? name;
  final String? university;
  final bool? isVerified;
  final String? localImagePath;

  const UpdateUserProfile({
    this.name,
    this.university,
    this.isVerified,
    this.localImagePath,
  });

  @override
  List<Object?> get props => [name, university, isVerified, localImagePath];
}

class WatchCurrentUser extends UserEvent {
  const WatchCurrentUser();
}

class UserUpdated extends UserEvent {
  final UserEntity user;
  const UserUpdated(this.user);

  @override
  List<Object?> get props => [user];
}

