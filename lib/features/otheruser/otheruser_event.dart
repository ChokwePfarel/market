abstract class OtherUserEvent {}

class FetchOtherUserRequested extends OtherUserEvent {
  final String userId;
  FetchOtherUserRequested(this.userId);
}

