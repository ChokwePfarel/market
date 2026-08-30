import 'dart:async';

import 'package:flutter/cupertino.dart';

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
    try {
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

      debugPrint('ChatRemoteDataSource: getConversations returned ${response.length} rows for user $currentUserId');
      if (response.isNotEmpty) {
        debugPrint('ChatRemoteDataSource: First row data: ${response.first}');
      }

      return (response as List).map((e) {
        final messages = (e['messages'] as List? ?? []);
        final unreadCount = messages
            .where((m) => m['is_read'] == false && m['sender_id'] != currentUserId)
            .length;

        return ConversationModel.fromJson(e, currentUserId, unreadCount);
      }).toList();
    } catch (e) {
      debugPrint('ChatRemoteDataSource: Error in getConversations: $e');
      rethrow;
    }
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
    debugPrint('ChatRemoteDataSource: Subscribing to messages for $conversationId');

    final channel = client.channel('public:messages:$conversationId');
    
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all, // Catch inserts and updates (for read status)
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'conversation_id',
        value: conversationId,
      ),
      callback: (payload) {
        if (payload.newRecord.isNotEmpty) {
          debugPrint('ChatRemoteDataSource: Realtime message event: ${payload.eventType}');
          final message = MessageModel.fromJson(payload.newRecord);
          controller.add(message);
        }
      },
    ).subscribe((status, error) {
      if (error != null) {
        debugPrint('ChatRemoteDataSource: Realtime subscription error: $error');
      }
      debugPrint('ChatRemoteDataSource: Realtime subscription status: $status');
    });

    controller.onCancel = () {
      debugPrint('ChatRemoteDataSource: Unsubscribing from messages for $conversationId');
      client.removeChannel(channel);
    };

    return controller.stream;
  }

  @override
  Stream<ConversationModel> subscribeToConversations(String currentUserId) {
    final controller = StreamController<ConversationModel>.broadcast();
    debugPrint('ChatRemoteDataSource: Subscribing to conversations for $currentUserId');

    final channel = client.channel('public:conversations:$currentUserId');

    // We listen to changes on the conversations table
    // Note: Ideally we'd filter by user_id, but PostgresChangeFilter only supports one column.
    // So we listen to all and filter in the callback, OR we can use two channels.
    // Listening to all and filtering is simpler since we fetch the full record anyway.
    
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'conversations',
      callback: (payload) async {
        try {
          // 1. Get the row ID and the user columns
          final String conversationId = payload.newRecord['id'] ?? payload.oldRecord['id'];
          if (conversationId == null) return;

          // 2. Identify if this user is involved. 
          // Note: On UPDATE, columns might be missing if they didn't change, 
          // so we may need to fetch the full row to be 100% sure.
          final String? userOneId = payload.newRecord['user_one_id'];
          final String? userTwoId = payload.newRecord['user_two_id'];

          bool shouldUpdate = false;
          if (userOneId != null || userTwoId != null) {
            shouldUpdate = (userOneId == currentUserId || userTwoId == currentUserId);
          } else {
            // If IDs are missing (typical in some Realtime versions for UPDATES), 
            // we do a quick check if this ID is already in our list.
            // But since the DataSource doesn't know the list, we'll just fetch it.
            shouldUpdate = true; 
          }

          if (shouldUpdate) {
            debugPrint('ChatRemoteDataSource: Detected potential conversation update for $conversationId');
            
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
                .maybeSingle();

            if (updated == null) return;

            final String actualUserOne = updated['user_one_id'];
            final String actualUserTwo = updated['user_two_id'];

            // FINAL double-check: is this row actually for this user?
            if (actualUserOne == currentUserId || actualUserTwo == currentUserId) {
              final messages = (updated['messages'] as List? ?? []);
              final unreadCount = messages
                  .where((m) => m['is_read'] == false && m['sender_id'] != currentUserId)
                  .length;

              controller.add(ConversationModel.fromJson(updated, currentUserId, unreadCount));
            }
          }
        } catch (e) {
          debugPrint('ChatRemoteDataSource: Error handling conversation realtime update: $e');
        }
      },
    ).subscribe();

    controller.onCancel = () {
      debugPrint('ChatRemoteDataSource: Unsubscribing from conversations for $currentUserId');
      client.removeChannel(channel);
    };

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
