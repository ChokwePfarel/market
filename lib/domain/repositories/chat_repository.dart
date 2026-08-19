import '../entities/conversation_entity.dart';
import '../entities/message_entity.dart';

abstract class ChatRepository {
  Future<List<ConversationEntity>> getConversations(String currentUserId);
  Future<ConversationEntity> getOrCreateConversation({
    required String currentUserId,
    required String otherUserId,
  });
  Future<List<MessageEntity>> getMessages(String conversationId);
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  });
  Future<void> markAsRead(String conversationId, String currentUserId);
  Stream<MessageEntity> subscribeToMessages(String conversationId);
  Stream<ConversationEntity> subscribeToConversations(String currentUserId);
  Future<int> getUnreadCount(String currentUserId);
  Future<void> deleteMessage(String messageId);
  void dispose();
}
