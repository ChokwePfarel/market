import '../../../data/models/user_model.dart';

abstract class OtherUserState {}

class OtherUserInitial extends OtherUserState {}
class OtherUserLoading extends OtherUserState {}
class OtherUserLoaded extends OtherUserState {
  final UserModel user;
  OtherUserLoaded(this.user);
}
class OtherUserError extends OtherUserState {
  final String message;
  OtherUserError(this.message);
}
