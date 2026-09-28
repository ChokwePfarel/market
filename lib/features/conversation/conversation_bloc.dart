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
  String? _currentUserId; // Store the user ID locally for filtering

  ConversationsBloc(this._chatRepository) : super(ConversationsInitial()) {
    on<LoadConversations>(_onLoad);
    on<OpenOrCreateConversation>(_onOpenOrCreate);
    on<ConversationUpdated>(_onConversationUpdated);
    on<RefreshUnreadCount>(_onRefreshUnreadCount);
    on<MarkConversationAsRead>(_onMarkAsRead);
    on<SetActiveConversation>(_onSetActiveConversation);
    on<ClearConversations>(_onClear);
  }

  Future<void> _onClear(
    ClearConversations event,
    Emitter<ConversationsState> emit,
  ) async {
    await _subscription?.cancel();
    _subscription = null;
    _currentUserId = null;
    _activeConversationId = null;
    emit(ConversationsInitial());
  }

  Future<void> _onLoad(
    LoadConversations event,
    Emitter<ConversationsState> emit,
  ) async {
    // If we are already subscribed to this user, only perform a refresh of data, don't restart listener..

    if (_currentUserId == event.currentUserId && _subscription != null) {
      debugPrint('ConversationsBloc: Already subscribed to ${event.currentUserId}. Refreshing data...');
      try {
        final conversations = await _chatRepository.getConversations(event.currentUserId);
        final unreadCount = await _chatRepository.getUnreadCount(event.currentUserId);
        emit(ConversationsLoaded(conversations: conversations, unreadCount: unreadCount));
      } catch (_) {}
      return;
    }

    _currentUserId = event.currentUserId; // Save for later use in updates
    final currentState = state;
    
    // Show cached data immediately if not already showing data..
    final cached = OfflineCache.getCachedConversations(event.currentUserId);
    if (currentState is! ConversationsLoaded && cached.isNotEmpty) {
      emit(ConversationsLoaded(conversations: cached, unreadCount: 0));
    } else if (currentState is! ConversationsLoaded) {
      emit(ConversationsLoading());
    }

    try {
      //Fetch fresh data from server
      final conversations =
          await _chatRepository.getConversations(event.currentUserId);
      
      // Double check filtering here to ensure we ONLYshow current user's chats..
      final filtered = conversations.where((c) => 
        c.userOneId == event.currentUserId || c.userTwoId == event.currentUserId
      ).toList();

      final unreadCount =
          await _chatRepository.getUnreadCount(event.currentUserId);

      //Update cache
      final models = filtered.whereType<ConversationModel>().toList();
      if (models.isNotEmpty) {
        await OfflineCache.cacheConversations(event.currentUserId, models);
      }

      //Emit fresh data
      emit(
        ConversationsLoaded(
          conversations: filtered,
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

      //what i did
      // We don't emit Loading here anymore to avoid breaking the background list state
      final conversation = await _chatRepository.getOrCreateConversation(
        currentUserId: event.currentUserId,
        otherUserId: event.otherUserId,
      );
      
      // First, signal the UI to navigate.
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

    // SAFETY: Only process if the current user is part of the updated conversation..

    if (_currentUserId != null &&
        event.conversation.userOneId != _currentUserId &&
        event.conversation.userTwoId != _currentUserId) {
      debugPrint('ConversationsBloc: Ignoring unrelated chat update');
      return;
    }

    bool found = false;
    final List<ConversationEntity> updatedList = current.conversations.map((c) {
      if (c.id == event.conversation.id) {
        found = true;

        //Fixing budge
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
      //debugPrint('ConversationsBloc: Adding new conversation ${event.conversation.id}');
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

    //Optimistically update the total unread count
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
   // debugPrint('ConversationsBloc: Active conversation set to: $_activeConversationId');
    
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
