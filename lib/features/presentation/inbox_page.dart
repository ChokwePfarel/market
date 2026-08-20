
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/conversation_entity.dart';
import '../conversation/conversation_bloc.dart';
import '../conversation/conversation_event.dart';
import '../conversation/conversation_state.dart';
import 'chat_page.dart';

// ─── Helpers ──────────────────────────────────────────────────────────────────

String _timeAgo(DateTime? dt) {
  if (dt == null) return '';
  final diff = DateTime.now().difference(dt);
  if (diff.inMinutes < 1) return 'now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m';
  if (diff.inHours < 24) return '${diff.inHours}h';
  if (diff.inDays < 7) return '${diff.inDays}d';
  return '${dt.day}/${dt.month}';
}

// ─── InboxPage ────────────────────────────────────────────────────────────────

class InboxPage extends StatefulWidget {
  final String currentUserId;

  const InboxPage({
    super.key,
    required this.currentUserId,
  });

  @override
  State<InboxPage> createState() => _InboxPageState();
}

class _InboxPageState extends State<InboxPage>
    with SingleTickerProviderStateMixin {
  final _searchCtrl = TextEditingController();
  final String _query = '';

  late final _fadeCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 400),
  )..forward();

  @override
  void initState() {
    super.initState();
    context.read<ConversationsBloc>().add(LoadConversations(widget.currentUserId));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }

  List<ConversationEntity> _filter(List<ConversationEntity> all) {
    if (_query.isEmpty) return all;
    return all
        .where((c) =>
            c.otherUser.name.toLowerCase().contains(_query.toLowerCase()))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F7FB),
      body: FadeTransition(
        opacity: _fadeCtrl,
        child: RefreshIndicator(
          displacement: 100,
          onRefresh: () async {
            context.read<ConversationsBloc>().add(LoadConversations(widget.currentUserId));
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              _buildAppBar(),
              BlocBuilder<ConversationsBloc, ConversationsState>(
                builder: (context, state) {
                  if (state is ConversationsLoading) {
                    return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  if (state is ConversationsError) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('Error: ${state.message}'),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              onPressed: () => context.read<ConversationsBloc>().add(LoadConversations(widget.currentUserId)),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (state is ConversationsLoaded) {
                    return _buildList(state.conversations);
                  }

                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────────────────

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      pinned: true,
      title: const Text(
        'Chats',
        style: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1A1A2E),
          letterSpacing: -0.5,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0.5),
        child: Container(height: 0.5, color: const Color(0xFFEEEEF4)),
      ),
    );
  }

  // ── List ───────────────────────────────────────────────────────────────────

  Widget _buildList(List<ConversationEntity> all) {
    final filtered = _filter(all);

    if (filtered.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: _buildEmpty(),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (_, i) {
          final conv = filtered[i];

          return _ConversationTile(
            key: ValueKey(conv.id),
            conversation: conv,
            index: i,
            onTap: () {
              HapticFeedback.selectionClick();
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ChatPage(
                    conversation: conv,
                  ),
                ),
              );
            },
          );
        },
        childCount: filtered.length,
      ),
    );
  }

  // ── Empty ──────────────────────────────────────────────────────────────────

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('💬', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 16),
          const Text(
            'No messages yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Visit someone\'s profile and\nstart a conversation',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Conversation Tile ────────────────────────────────────────────────────────

class _ConversationTile extends StatefulWidget {
  final ConversationEntity conversation;
  final int index;
  final VoidCallback onTap;

  const _ConversationTile({
    super.key,
    required this.conversation,
    required this.index,
    required this.onTap,
  });

  @override
  State<_ConversationTile> createState() => _ConversationTileState();
}

class _ConversationTileState extends State<_ConversationTile>
    with SingleTickerProviderStateMixin {
  late final _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 450),
  );
  late final _slide = Tween<Offset>(
    begin: const Offset(0.04, 0),
    end: Offset.zero,
  ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  late final _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);

  @override
  void initState() {
    super.initState();
    Future.delayed(Duration(milliseconds: widget.index * 60), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conv = widget.conversation;

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                // ── Avatar ─────────────────────────────────────────────────
                Stack(
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFF4D6D).withOpacity(0.1),
                        image: conv.otherUser.profileImageUrl.isNotEmpty
                            ? DecorationImage(
                                image: conv.otherUser.profileImageUrl.startsWith('http')
                                    ? NetworkImage(conv.otherUser.profileImageUrl)
                                    : FileImage(File(conv.otherUser.profileImageUrl.replaceFirst('file://', ''))) as ImageProvider,
                                fit: BoxFit.cover,
                              )
                            : null,
                        border: Border.all(
                          color: const Color(0xFFFF4D6D).withOpacity(0.2),
                          width: 1.5,
                        ),
                      ),
                      child: conv.otherUser.profileImageUrl.isEmpty
                          ? const Center(
                              child: Text('👤', style: TextStyle(fontSize: 22)),
                            )
                          : null,
                    ),
                    if (conv.otherUser.isVerified)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            color: const Color(0xFF2EC4B6),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: const Icon(
                            CupertinoIcons.checkmark_alt,
                            size: 9,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),

                // ── Content ────────────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conv.otherUser.name,
                              style: TextStyle(
                                fontSize:   15,
                                fontWeight: conv.unreadCount > 0
                                    ? FontWeight.w800
                                    : FontWeight.w700,
                                color: const Color(0xFF1A1A2E),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              if (conv.unreadCount > 0)
                                Container(
                                  margin: const EdgeInsets.only(right: 6),
                                  width:  8,
                                  height: 8,
                                  decoration: const BoxDecoration(
                                    color:  Color(0xFFFF4D6D),
                                    shape:  BoxShape.circle,
                                  ),
                                ),
                              Text(
                                _timeAgo(conv.lastMessageAt),
                                style: TextStyle(
                                  fontSize:   12,
                                  fontWeight: conv.unreadCount > 0
                                      ? FontWeight.w800
                                      : FontWeight.w500,
                                  color: conv.unreadCount > 0
                                      ? const Color(0xFFFF4D6D)
                                      : Colors.grey.shade400,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        conv.lastMessage ?? 'Say hello 👋',
                        style: TextStyle(
                          fontSize: 13,
                          color: conv.lastMessage != null
                              ? Colors.grey.shade600
                              : Colors.grey.shade400,
                          fontStyle: conv.lastMessage == null
                              ? FontStyle.italic
                              : FontStyle.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(
                  CupertinoIcons.chevron_right,
                  size: 14,
                  color: Color(0xFFCCCCDD),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
