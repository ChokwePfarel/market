import '../../domain/entities/conversation_entity.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import '../data_source/chat_remote_data_source.dart';

class ChatRepositoryImpl implements ChatRepository {
  final ChatRemoteDataSource remoteDataSource;

  ChatRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<ConversationEntity>> getConversations(String currentUserId) async {
    return await remoteDataSource.getConversations(currentUserId);
  }

  @override
  Future<ConversationEntity> getOrCreateConversation({
    required String currentUserId,
    required String otherUserId,
  }) async {
    return await remoteDataSource.getOrCreateConversation(
      currentUserId: currentUserId,
      otherUserId: otherUserId,
    );
  }

  @override
  Future<List<MessageEntity>> getMessages(String conversationId) async {
    return await remoteDataSource.getMessages(conversationId);
  }

  @override
  Future<void> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    await remoteDataSource.sendMessage(
      conversationId: conversationId,
      senderId: senderId,
      text: text,
    );
  }

  @override
  Future<void> markAsRead(String conversationId, String currentUserId) async {
    await remoteDataSource.markAsRead(conversationId, currentUserId);
  }

  @override
  Stream<MessageEntity> subscribeToMessages(String conversationId) {
    return remoteDataSource.subscribeToMessages(conversationId);
  }

  @override
  Stream<ConversationEntity> subscribeToConversations(String currentUserId) {
    return remoteDataSource.subscribeToConversations(currentUserId);
  }

  @override
  Future<int> getUnreadCount(String currentUserId) async {
    return await remoteDataSource.getUnreadCount(currentUserId);
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    await remoteDataSource.deleteMessage(messageId);
  }

  @override
  void dispose() {
    remoteDataSource.dispose();
  }
}

