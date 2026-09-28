import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:market/core/custom/avatar.dart';

import '../../core/custom/Conversation_tile.dart';
import '../../domain/entities/conversation_entity.dart';
import '../conversation/conversation_bloc.dart';
import '../conversation/conversation_event.dart';
import '../conversation/conversation_state.dart';
import 'chat_page.dart';

class InboxPage extends StatefulWidget {
  final String currentUserId;

  const InboxPage({super.key, required this.currentUserId});

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
    context.read<ConversationsBloc>().add(
      LoadConversations(widget.currentUserId),
    );
  }

  List<ConversationEntity> _filter(List<ConversationEntity> all) {
    if (_query.isEmpty) return all;
    return all
        .where(
          (c) => c.otherUser.name.toLowerCase().contains(_query.toLowerCase()),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fadeCtrl,
        child: RefreshIndicator(
          color: Colors.black,
          displacement: 100,
          onRefresh: () async {
            context.read<ConversationsBloc>().add(
              LoadConversations(widget.currentUserId),
            );
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
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.black,
                          ),
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
                            const Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.grey,
                            ),

                            const SizedBox(height: 16),

                            Text('Error: ${state.message}'),

                            const SizedBox(height: 12),

                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                              ),
                              onPressed: () => context
                                  .read<ConversationsBloc>()
                                  .add(LoadConversations(widget.currentUserId)),
                              child: const Text(
                                'Retry',
                                style: TextStyle(color: Colors.white),
                              ),
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
          color: Colors.white,
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
                  color: Colors.white,
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
            Container(height: 0.5, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<ConversationEntity> all) {
    final filtered = _filter(all);

    if (filtered.isEmpty) {
      return SliverFillRemaining(hasScrollBody: false, child: _buildEmpty());
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((_, i) {
        final conv = filtered[i];

        return ConversationTile(
          key: ValueKey(conv.id),
          conversation: conv,
          index: i,
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ChatPage(conversation: conv)),
            );
          },
        );
      }, childCount: filtered.length),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
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

  @override
  void dispose() {
    _searchCtrl.dispose();
    _fadeCtrl.dispose();
    super.dispose();
  }
}
