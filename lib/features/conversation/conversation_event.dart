import '../../domain/entities/conversation_entity.dart';

abstract class ConversationsEvent {}

class LoadConversations extends ConversationsEvent {
  final String currentUserId;
  LoadConversations(this.currentUserId);
}

class OpenOrCreateConversation extends ConversationsEvent {
  final String currentUserId;
  final String otherUserId;
  OpenOrCreateConversation({
    required this.currentUserId,
    required this.otherUserId,
  });
}

class ConversationUpdated extends ConversationsEvent {
  final ConversationEntity conversation;
  ConversationUpdated(this.conversation);
}

class RefreshUnreadCount extends ConversationsEvent {
  final String currentUserId;
  RefreshUnreadCount(this.currentUserId);
}

class MarkConversationAsRead extends ConversationsEvent {
  final String conversationId;
  final String currentUserId;
  MarkConversationAsRead({
    required this.conversationId,
    required this.currentUserId,
  });
}

class SetActiveConversation extends ConversationsEvent {
  final String? conversationId;
  SetActiveConversation(this.conversationId);
}
