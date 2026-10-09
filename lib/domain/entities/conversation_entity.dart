import 'package:equatable/equatable.dart';
import 'user_entity.dart';

class ConversationEntity extends Equatable {
  final String id;
  final String userOneId;
  final String userTwoId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final UserEntity otherUser;
  final int unreadCount;

  const ConversationEntity({
    required this.id,
    required this.userOneId,
    required this.userTwoId,
    this.lastMessage,
    this.lastMessageAt,
    required this.otherUser,
    this.unreadCount = 0,
  });

  @override
  List<Object?> get props => [id, userOneId, userTwoId, lastMessage, lastMessageAt, otherUser, unreadCount];
}

