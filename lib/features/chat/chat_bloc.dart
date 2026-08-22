import 'dart:async';

import 'package:flutter/cupertino.dart';

import '../../core/utils/offline_cache.dart';
import '../../data/models/message_model.dart';
import '../../domain/entities/message_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import 'chat_event.dart';
import 'chat_state.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ChatRepository _chatRepository;
  StreamSubscription<MessageEntity>? _msgSubscription;
  StreamSubscription<List<ConnectivityResult>>? _connSubscription;

  String? _currentUserId;
  String? _conversationId;

  ChatBloc(this._chatRepository) : super(ChatInitial()) {
    on<LoadMessages>(_onLoadMessages);
    on<SendMessage>(_onSendMessage);
    on<MessageReceived>(_onMessageReceived);
    on<ResendQueuedMessages>(_onResendQueued);
    on<UpdateMessageStatus>(_onUpdateStatus);
    on<deleteMessage>(_onDeleteMessage);

    _connSubscription = Connectivity().onConnectivityChanged.listen((results) {
      if (results.isNotEmpty && results.first != ConnectivityResult.none) {
        if (_conversationId != null) {
          add(ResendQueuedMessages(conversationId: _conversationId!));
        }
      }
    });
  }

  // ─── Load Messages ─────────────────────────────────────────────────────────

  Future<void> _onLoadMessages(
      LoadMessages event,
      Emitter<ChatState> emit,
      ) async {
    _currentUserId = event.currentUserId;
    _conversationId = event.conversationId;

    final cachedMessages = OfflineCache.getCachedMessages(event.conversationId);
    final queuedMessages = OfflineCache.getQueuedMessages(event.conversationId);

    if (cachedMessages.isNotEmpty || queuedMessages.isNotEmpty) {
      final combined = _merge(cachedMessages, queuedMessages);
      emit(ChatLoaded(messages: combined));
    } else {
      // Avoid emitting loading if we already have something to show
      emit(ChatLoading());
    }

    try {
      final serverMessages = await _chatRepository.getMessages(event.conversationId);

      final models = serverMessages.whereType<MessageModel>().toList();
      if (models.isNotEmpty) {
        await OfflineCache.cacheMessageHistory(event.conversationId, models);
      }

      final stillQueued = queuedMessages
          .where((q) => !serverMessages.any(
            (s) => s.text == q.text && s.senderId == q.senderId,
      ))
          .toList();

      final allMessages = _merge(serverMessages, stillQueued);
      emit(ChatLoaded(messages: allMessages));

      // Mark conversation as read on entry
      await _chatRepository.markAsRead(event.conversationId, event.currentUserId);

      await _msgSubscription?.cancel();
      _msgSubscription = _chatRepository
          .subscribeToMessages(event.conversationId)
          .listen((message) => add(MessageReceived(message)));
          
    } catch (e) {
      debugPrint('ChatBloc: Error loading messages: $e');
      // Only emit error if we don't have cached messages
      if (state is! ChatLoaded) {
        emit(ChatError(e.toString()));
      }
    }
  }

  // ─── Send Message ──────────────────────────────────────────────────────────

  Future<void> _onSendMessage(
      SendMessage event,
      Emitter<ChatState> emit,
      ) async {
    final current = state;
    if (current is! ChatLoaded) return;

    final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
    final pending = MessageEntity(
      id: tempId,
      conversationId: event.conversationId,
      senderId: event.senderId,
      text: event.text,
      isRead: false,
      createdAt: DateTime.now(),
      status: MessageStatus.pending,
    );

    emit(current.copyWith(messages: [...current.messages, pending]));

    final connectivity = await Connectivity().checkConnectivity();
    if (connectivity.first == ConnectivityResult.none) {
      await OfflineCache.enqueueMessage(pending);
      return;
    }

    try {
      await _chatRepository.sendMessage(
        conversationId: event.conversationId,
        senderId: event.senderId,
        text: event.text,
      );
    } catch (e) {
      await OfflineCache.enqueueMessage(pending);
      add(UpdateMessageStatus(messageId: tempId, status: MessageStatus.error));
    }
  }

  // ─── Resend Queued Messages ────────────────────────────────────────────────

  Future<void> _onResendQueued(
      ResendQueuedMessages event,
      Emitter<ChatState> emit,
      ) async {
    final queued = OfflineCache.getQueuedMessages(event.conversationId);
    if (queued.isEmpty) return;

    for (final msg in queued) {
      try {
        await _chatRepository.sendMessage(
          conversationId: msg.conversationId,
          senderId: msg.senderId,
          text: msg.text,
        );
        await OfflineCache.dequeueMessage(msg.conversationId, msg.id);
      } catch (_) {}
    }
  }

  // ─── Update Message Status ─────────────────────────────────────────────────

  void _onUpdateStatus(
      UpdateMessageStatus event,
      Emitter<ChatState> emit,
      ) {
    final current = state;
    if (current is! ChatLoaded) return;

    final updated = current.messages.map((m) {
      return m.id == event.messageId ? m.copyWith(status: event.status) : m;
    }).toList();

    emit(current.copyWith(messages: updated));
  }

  // ─── Delete Message ────────────────────────────────────────────────────────

  Future<void> _onDeleteMessage(
      deleteMessage event,
      Emitter<ChatState> emit,
      ) async {
    final current = state;
    if (current is! ChatLoaded) return;

    // Optimistic UI update
    final updatedMessages = current.messages.where((m) => m.id != event.messageId).toList();
    emit(current.copyWith(messages: updatedMessages));

    try {
      await _chatRepository.deleteMessage(event.messageId);
    } catch (e) {
      // Revert or show error if deletion fails
    }
  }

  // ─── Message Received ──────────────────────────────────────────────────────

  void _onMessageReceived(
      MessageReceived event,
      Emitter<ChatState> emit,
      ) {
    final current = state;
    if (current is! ChatLoaded) return;

    final List<MessageEntity> updated = List.from(current.messages);

    // 1. Handle potential temp message removal
    bool removedTemp = false;
    updated.removeWhere((m) {
      if (!removedTemp &&
          m.status != MessageStatus.sent &&
          m.text == event.message.text &&
          m.senderId == event.message.senderId) {
        removedTemp = true;
        return true;
      }
      return false;
    });

    // 2. Add or UPDATE the message in the list
    final existingIndex = updated.indexWhere((m) => m.id == event.message.id);
    if (existingIndex != -1) {
      debugPrint('ChatBloc: Updating existing message: ${event.message.id}');
      updated[existingIndex] = event.message;
    } else {
      debugPrint('ChatBloc: Adding new message: ${event.message.id}');
      updated.add(event.message);
    }

    updated.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    emit(current.copyWith(messages: updated));

    // 3. Mark as read logic
    if (_currentUserId != null && _conversationId != null && event.message.senderId != _currentUserId) {
       _chatRepository.markAsRead(_conversationId!, _currentUserId!);
    }
  }

  List<MessageEntity> _merge(List<MessageEntity> a, List<MessageEntity> b) {
    final seen = <String>{};
    final merged = <MessageEntity>[];
    for (final m in [...a, ...b]) {
      if (seen.add(m.id)) merged.add(m);
    }
    merged.sort((x, y) => x.createdAt.compareTo(y.createdAt));
    return merged;
  }

  @override
  Future<void> close() {
    _msgSubscription?.cancel();
    _connSubscription?.cancel();
    return super.close();
  }
}
