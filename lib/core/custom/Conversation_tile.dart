import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/conversation_entity.dart';
import 'avatar.dart';

class ConversationTile extends StatefulWidget {
  final ConversationEntity conversation;
  final int index;
  final VoidCallback onTap;

  const ConversationTile({
    super.key,
    required this.conversation,
    required this.index,
    required this.onTap,
  });

  @override
  State<ConversationTile> createState() => ConversationTileState();
}

class ConversationTileState extends State<ConversationTile>
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
                    CustomAvatar(url: conv.otherUser.profileImageUrl),
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


  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}';
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
}
