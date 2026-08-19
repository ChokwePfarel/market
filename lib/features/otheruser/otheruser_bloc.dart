import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:market/domain/repositories/other_user_repository.dart';
import 'otheruser_event.dart';
import 'otheruser_state.dart';

class OtherUserBloc extends Bloc<OtherUserEvent, OtherUserState> {
  final OtherUserRepository _usersRepository;

  OtherUserBloc(this._usersRepository) : super(OtherUserInitial()) {
    on<FetchOtherUserRequested>(_onFetchOtherUser);
  }

  Future<void> _onFetchOtherUser(
    FetchOtherUserRequested event,
    Emitter<OtherUserState> emit,
  ) async {
    emit(OtherUserLoading());

    try {
      final user = await _usersRepository.getOtherUser(event.userId);
      emit(OtherUserLoaded(user));
    } catch (e) {
      emit(OtherUserError(e.toString()));
    }
  }
}
