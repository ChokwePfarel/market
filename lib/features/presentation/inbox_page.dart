import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
  String _query = '';

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
          color: Colors.black,
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
                      child: Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                        ),
                      ),
                    );
                  }

                  if (state is ConversationsError) {
                    return SliverFillRemaining(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
                            const SizedBox(height: 16),
                            Text('Error: ${state.message}'),
                            const SizedBox(height: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
                              onPressed: () => context.read<ConversationsBloc>().add(LoadConversations(widget.currentUserId)),
                              child: const Text('Retry', style: TextStyle(color: Colors.white)),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (state is ConversationsLoaded) {
                    return _buildList(state.conversations);
                  }

                  return const SliverToBoxAdapter(child: SizedBox.shrink());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  SliverAppBar _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      pinned: true,
      centerTitle: false,
      title: const Text(
        'Chats',
        style: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w800,
          color: Color(0xFF1A1A2E),
          letterSpacing: -0.5,
        ),
      ),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(60),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F1F5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (val) => setState(() => _query = val),
                  decoration: const InputDecoration(
                    hintText: 'Search conversations...',
                    prefixIcon: Icon(Icons.search, size: 20),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
            ),
            Container(height: 0.5, color: const Color(0xFFEEEEF4)),
          ],
        ),
      ),
    );
  }

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
            'Start a conversation with a seller\nto see your messages here.',
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
                Stack(
                  children: [
                    _buildAvatar(conv.otherUser.profileImageUrl),
                    if (conv.otherUser.isVerified)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(Icons.check, size: 10, color: Colors.white),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 14),
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
                                fontSize: 16,
                                fontWeight: conv.unreadCount > 0 ? FontWeight.w800 : FontWeight.w700,
                                color: const Color(0xFF1A1A2E),
                              ),
                            ),
                          ),
                          Text(
                            _timeAgo(conv.lastMessageAt),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: conv.unreadCount > 0 ? FontWeight.w800 : FontWeight.w500,
                              color: conv.unreadCount > 0 ? Colors.blue : Colors.grey.shade400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              conv.lastMessage ?? 'Start a conversation',
                              style: TextStyle(
                                fontSize: 14,
                                color: conv.unreadCount > 0 ? Colors.black87 : Colors.grey.shade600,
                                fontWeight: conv.unreadCount > 0 ? FontWeight.w600 : FontWeight.w400,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (conv.unreadCount > 0)
                            Container(
                              margin: const EdgeInsets.only(left: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                conv.unreadCount.toString(),
                                style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, size: 20, color: Color(0xFFCCCCDD)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar(String url) {
    if (url.isEmpty) {
      return Container(
        width: 58,
        height: 54,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF1F1F5)),
        child: const Icon(Icons.person, color: Colors.grey, size: 28),
      );
    }

    if (url.startsWith('http')) {
      return Container(
        width: 58,
        height: 54,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(
            image: CachedNetworkImageProvider(url),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // Local file path handling with existence check
    final String cleanPath = url.replaceFirst('file://', '').replaceFirst('file:/', '');
    
    // SAFETY: If the path belongs to the old package name, it's dead. Ignore it.
    if (cleanPath.contains('com.example.market')) {
      return Container(
        width: 58,
        height: 54,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF1F1F5)),
        child: const Icon(Icons.person, color: Colors.grey, size: 28),
      );
    }

    final file = File(cleanPath);

    return Container(
      width: 58,
      height: 54,
      decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFFF1F1F5)),
      child: FutureBuilder<bool>(
        future: file.exists(),
        builder: (context, snapshot) {
          if (snapshot.data == true) {
            return ClipOval(
              child: Image.file(
                file,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.person, color: Colors.grey),
              ),
            );
          }
          return const Icon(Icons.person, color: Colors.grey);
        },
      ),
    );
  }
}
