import '../../domain/entities/conversation_entity.dart';

abstract class ConversationsState {}

class ConversationsInitial extends ConversationsState {}

class ConversationsLoading extends ConversationsState {}

class ConversationsLoaded extends ConversationsState {
  final List<ConversationEntity> conversations;
  final int unreadCount;

  ConversationsLoaded({
    required this.conversations,
    required this.unreadCount,
  });

  ConversationsLoaded copyWith({
    List<ConversationEntity>? conversations,
    int? unreadCount,
  }) =>
      ConversationsLoaded(
        conversations: conversations ?? this.conversations,
        unreadCount:   unreadCount   ?? this.unreadCount,
      );
}

class ConversationReady extends ConversationsState {
  final ConversationEntity conversation;
  ConversationReady(this.conversation);
}

class ConversationsError extends ConversationsState {
  final String message;
  ConversationsError(this.message);
}

