import 'dart:async';

import '../models/conversation_model.dart';
import '../models/message_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

abstract class ChatRemoteDataSource {
  Future<List<ConversationModel>> getConversations(String currentUserId);

  Future<ConversationModel> getOrCreateConversation({
    required String currentUserId,
    required String otherUserId,
  });

  Future<List<MessageModel>> getMessages(String conversationId);

  Future<MessageModel> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  });

  Future<void> markAsRead(String conversationId, String currentUserId);

  Stream<MessageModel> subscribeToMessages(String conversationId);

  Stream<ConversationModel> subscribeToConversations(String currentUserId);

  Future<int> getUnreadCount(String currentUserId);

  Future<void> deleteMessage(String messageId);

  void dispose();
}

class ChatRemoteDataSourceImpl implements ChatRemoteDataSource {
  final SupabaseClient client;
  RealtimeChannel? _messagesChannel;
  RealtimeChannel? _conversationsChannel;

  ChatRemoteDataSourceImpl(this.client);

  @override
  Future<List<ConversationModel>> getConversations(String currentUserId) async {
    final response = await client
        .from('conversations')
        .select('''
      *,
      user_one:profiles!conversations_user_one_id_fkey (
        id, full_name, profile_image_url, is_verified
      ),
      user_two:profiles!conversations_user_two_id_fkey (
        id, full_name, profile_image_url, is_verified
      ),
      messages (
        id,
        is_read,
        sender_id
      )
    ''')
        .or('user_one_id.eq.$currentUserId,user_two_id.eq.$currentUserId')
        .order('last_message_at', ascending: false);

    return (response as List).map((e) {
      final messages = (e['messages'] as List? ?? []);
      final unreadCount = messages
          .where((m) => m['is_read'] == false && m['sender_id'] != currentUserId)
          .length;

      return ConversationModel.fromJson(e, currentUserId, unreadCount);
    }).toList();
  }

  @override
  Future<ConversationModel> getOrCreateConversation({
    required String currentUserId,
    required String otherUserId,
  }) async {
    final existing = await client
        .from('conversations')
        .select('''
          *,
          user_one:profiles!conversations_user_one_id_fkey (
            id, full_name, profile_image_url, is_verified
          ),
          user_two:profiles!conversations_user_two_id_fkey (
            id, full_name, profile_image_url, is_verified
          )
        ''')
        .or(
          'and(user_one_id.eq.$currentUserId,user_two_id.eq.$otherUserId),'
          'and(user_one_id.eq.$otherUserId,user_two_id.eq.$currentUserId)',
        )
        .maybeSingle();

    if (existing != null) {
      return ConversationModel.fromJson(existing, currentUserId);
    }

    final created = await client
        .from('conversations')
        .insert({'user_one_id': currentUserId, 'user_two_id': otherUserId})
        .select('''
          *,
          user_one:profiles!conversations_user_one_id_fkey (
            id, full_name, profile_image_url, is_verified
          ),
          user_two:profiles!conversations_user_two_id_fkey (
            id, full_name, profile_image_url, is_verified
          )
        ''')
        .single();

    return ConversationModel.fromJson(created, currentUserId);
  }

  @override
  Future<List<MessageModel>> getMessages(String conversationId) async {
    final response = await client
        .from('messages')
        .select()
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true);

    return (response as List).map((e) => MessageModel.fromJson(e)).toList();
  }

  @override
  Future<MessageModel> sendMessage({
    required String conversationId,
    required String senderId,
    required String text,
  }) async {
    final response = await client
        .from('messages')
        .insert({
          'conversation_id': conversationId,
          'sender_id': senderId,
          'text': text,
        })
        .select()
        .single();

    return MessageModel.fromJson(response);
  }

  @override
  Future<void> markAsRead(String conversationId, String currentUserId) async {
    await client
        .from('messages')
        .update({'is_read': true})
        .eq('conversation_id', conversationId)
        .neq('sender_id', currentUserId)
        .eq('is_read', false);
  }

  @override
  Stream<MessageModel> subscribeToMessages(String conversationId) {
    final controller = StreamController<MessageModel>.broadcast();

    _messagesChannel = client
        .channel('messages:$conversationId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'messages',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'conversation_id',
            value: conversationId,
          ),
          callback: (payload) {
            final message = MessageModel.fromJson(payload.newRecord);
            controller.add(message);
          },
        )
        .subscribe();

    return controller.stream;
  }


  Stream<ConversationModel> subscribeToConversations(String currentUserId) {
    final controller = StreamController<ConversationModel>.broadcast();

    _conversationsChannel = client
        .channel('conversations:$currentUserId')
        .onPostgresChanges(
      // Listen for ALL changes (INSERT, UPDATE, DELETE) to catch new chats
      // and summary updates after deletions
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'conversations',
      callback: (payload) async {
        if (payload.newRecord.isEmpty) return;

        final String conversationId = payload.newRecord['id'];

        try {
          final updated = await client
              .from('conversations')
              .select('''
                    *,
                    user_one:profiles!conversations_user_one_id_fkey (
                      id, full_name, profile_image_url, is_verified
                    ),
                    user_two:profiles!conversations_user_two_id_fkey (
                      id, full_name, profile_image_url, is_verified
                    ),
                    messages (
                      id, is_read, sender_id
                    )
                  ''')
              .eq('id', conversationId)
              .single();

          final messages = (updated['messages'] as List? ?? []);
          final unreadCount = messages
              .where((m) => m['is_read'] == false && m['sender_id'] != currentUserId)
              .length;

          controller.add(ConversationModel.fromJson(updated, currentUserId, unreadCount));
        } catch (e) {
        }
      },
    )
        .subscribe();

    return controller.stream;
  }

  @override
  Future<void> deleteMessage(String messageId) async {
    try {
      // 1. Get metadata before deletion
      final messageInfo = await client
          .from('messages')
          .select('conversation_id')
          .eq('id', messageId)
          .maybeSingle();

      if (messageInfo == null) return;
      final String conversationId = messageInfo['conversation_id'];

      // 2. Delete the message
      await client.from('messages').delete().eq('id', messageId);

      // 3. Find the new latest message
      final latestMessage = await client
          .from('messages')
          .select('text, created_at')
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      // 4. Update the conversation summary
      // This update triggers the Realtime listener on the Inbox page
      final updateData = {
        'last_message': latestMessage?['text'],
        'last_message_at': latestMessage?['created_at'],
      };

      await client
          .from('conversations')
          .update(updateData)
          .eq('id', conversationId)
          .select(); // Verify RLS allows update

    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<int> getUnreadCount(String currentUserId) async {
    final response = await client.rpc(
      'get_unread_count',
      params: {'current_user_id': currentUserId},
    );
    return response as int;
  }


  @override
  void dispose() {
    _messagesChannel?.unsubscribe();
    _conversationsChannel?.unsubscribe();
  }
}
