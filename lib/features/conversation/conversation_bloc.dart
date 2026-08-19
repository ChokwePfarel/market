import 'dart:async';
import '../../core/utils/offline_cache.dart';
import '../../data/models/conversation_model.dart';
import '../../domain/entities/conversation_entity.dart';
import '../../domain/repositories/chat_repository.dart';
import 'conversation_event.dart';
import 'conversation_state.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ConversationsBloc extends Bloc<ConversationsEvent, ConversationsState> {
  final ChatRepository _chatRepository;
  StreamSubscription? _subscription;
  String? _activeConversationId;

  ConversationsBloc(this._chatRepository) : super(ConversationsInitial()) {
    on<LoadConversations>(_onLoad);
    on<OpenOrCreateConversation>(_onOpenOrCreate);
    on<ConversationUpdated>(_onConversationUpdated);
    on<RefreshUnreadCount>(_onRefreshUnreadCount);
    on<MarkConversationAsRead>(_onMarkAsRead);
    on<SetActiveConversation>(_onSetActiveConversation);
  }

  Future<void> _onLoad(
    LoadConversations event,
    Emitter<ConversationsState> emit,
  ) async {
    final cached = OfflineCache.getCachedConversations(event.currentUserId);
    if (cached.isNotEmpty) {
      emit(ConversationsLoaded(conversations: cached, unreadCount: 0));
    } else {
      emit(ConversationsLoading());
    }

    try {
      final conversations =
          await _chatRepository.getConversations(event.currentUserId);
      final unreadCount =
          await _chatRepository.getUnreadCount(event.currentUserId);

      final models = conversations.whereType<ConversationModel>().toList();
      if (models.isNotEmpty) {
        await OfflineCache.cacheConversations(event.currentUserId, models);
      }

      emit(
        ConversationsLoaded(
          conversations: conversations,
          unreadCount: unreadCount,
        ),
      );

      await _subscription?.cancel();
      _subscription = _chatRepository
          .subscribeToConversations(event.currentUserId)
          .listen((updated) {
        add(ConversationUpdated(updated));
        add(RefreshUnreadCount(event.currentUserId));
      });
    } catch (e) {
      if (state is! ConversationsLoaded) {
        emit(ConversationsError(e.toString()));
      }
    }
  }

  Future<void> _onOpenOrCreate(
    OpenOrCreateConversation event,
    Emitter<ConversationsState> emit,
  ) async {
    try {
      // We don't emit Loading here anymore to avoid breaking the background list state
      final conversation = await _chatRepository.getOrCreateConversation(
        currentUserId: event.currentUserId,
        otherUserId: event.otherUserId,
      );
      
      // First, signal the UI to navigate
      emit(ConversationReady(conversation));
      
      // Then, immediately restore the list state so the Inbox stays functional
      add(LoadConversations(event.currentUserId));

    } catch (e) {
      emit(ConversationsError(e.toString()));
    }
  }

  void _onConversationUpdated(
    ConversationUpdated event,
    Emitter<ConversationsState> emit,
  ) {
    final current = state;
    if (current is! ConversationsLoaded) return;

    bool found = false;
    final List<ConversationEntity> updatedList = current.conversations.map((c) {
      if (c.id == event.conversation.id) {
        found = true;
        // If this conversation is currently open, force unread count to 0
        if (c.id == _activeConversationId) {
          final conv = event.conversation;
          return ConversationModel(
            id: conv.id,
            userOneId: conv.userOneId,
            userTwoId: conv.userTwoId,
            lastMessage: conv.lastMessage,
            lastMessageAt: conv.lastMessageAt,
            otherUser: conv.otherUser,
            unreadCount: 0,
          );
        }
        return event.conversation;
      }
      return c;
    }).toList();

    if (!found) {
      updatedList.add(event.conversation);
    }

    updatedList.sort(
      (ConversationEntity a, ConversationEntity b) =>
          (b.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(a.lastMessageAt ?? DateTime.fromMillisecondsSinceEpoch(0)),
    );

    emit(current.copyWith(conversations: updatedList));
  }

  Future<void> _onRefreshUnreadCount(
    RefreshUnreadCount event,
    Emitter<ConversationsState> emit,
  ) async {
    final current = state;
    if (current is! ConversationsLoaded) return;
    try {
      final count = await _chatRepository.getUnreadCount(event.currentUserId);
      emit(current.copyWith(unreadCount: count));
    } catch (_) {}
  }

  void _onMarkAsRead(
    MarkConversationAsRead event,
    Emitter<ConversationsState> emit,
  ) {
    final current = state;
    if (current is! ConversationsLoaded) return;

    int unreadInThisConv = 0;
    final updatedConversations = current.conversations.map((c) {
      if (c.id == event.conversationId) {
        unreadInThisConv = c.unreadCount;
        if (c is ConversationModel) {
          return ConversationModel(
            id: c.id,
            userOneId: c.userOneId,
            userTwoId: c.userTwoId,
            lastMessage: c.lastMessage,
            lastMessageAt: c.lastMessageAt,
            otherUser: c.otherUser,
            unreadCount: 0,
          );
        }
      }
      return c;
    }).toList();

    // Optimistically update the total unread count
    final newTotalUnread = (current.unreadCount - unreadInThisConv).clamp(0, 999);

    emit(current.copyWith(
      conversations: updatedConversations,
      unreadCount: newTotalUnread,
    ));
    
    // Background refresh
    add(RefreshUnreadCount(event.currentUserId));
  }

  void _onSetActiveConversation(
    SetActiveConversation event,
    Emitter<ConversationsState> emit,
  ) {
    _activeConversationId = event.conversationId;
    debugPrint('ConversationsBloc: Active conversation set to: $_activeConversationId');
    
    // If we just opened a conversation, mark it as read immediately
    if (_activeConversationId != null) {
      final current = state;
      if (current is ConversationsLoaded) {
        final userId = current.conversations.first.userOneId; // Any valid ID works for event
        add(MarkConversationAsRead(
          conversationId: _activeConversationId!,
          currentUserId: userId,
        ));
      }
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    _chatRepository.dispose();
    return super.close();
  }
}
