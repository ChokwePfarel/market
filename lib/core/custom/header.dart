import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../features/conversation/conversation_bloc.dart';
import '../../features/conversation/conversation_state.dart';
import '../../features/presentation/inbox_page.dart';
import '../../features/presentation/my_products_page.dart';
import '../../features/presentation/profile_page.dart';
import '../../features/user/user_bloc.dart';
import '../../features/user/user_state.dart';

class Header extends StatelessWidget {
  const Header({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Profile
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          },
          child: BlocBuilder<UserBloc, UserState>(
            builder: (context, state) {
              String? profileUrl;
              if (state is UserLoaded) {
                profileUrl = state.user.profileImageUrl;
              }

              final bool hasImage = profileUrl != null && profileUrl.isNotEmpty;

              if (!hasImage) {
                return const CircleAvatar(
                  radius: 23,
                  backgroundColor: Color(0xFFF0E8F7),
                  child: Icon(Icons.person, color: Colors.black87, size: 25),
                );
              }

              if (profileUrl.startsWith('http')) {
                return CachedNetworkImage(
                  imageUrl: profileUrl,
                  imageBuilder: (context, imageProvider) => CircleAvatar(
                    radius: 23,
                    backgroundColor: const Color(0xFFF0E8F7),
                    backgroundImage: imageProvider,
                  ),
                  placeholder: (context, url) => const CircleAvatar(
                    radius: 23,
                    backgroundColor: Color(0xFFF0E8F7),
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  errorWidget: (context, url, error) => const CircleAvatar(
                    radius: 23,
                    backgroundColor: Color(0xFFF0E8F7),
                    child: Icon(Icons.person, color: Colors.black87, size: 25),
                  ),
                );
              } else {
                // Local file path handling
                final file = File(profileUrl.replaceFirst('file://', '').replaceFirst('file:/', ''));
                return CircleAvatar(
                  radius: 23,
                  backgroundColor: const Color(0xFFF0E8F7),
                  backgroundImage: FileImage(file),
                );
              }
            },
          ),
        ),

        const Spacer(),

        // Notification
        BlocBuilder<ConversationsBloc, ConversationsState>(
          builder: (context, state) {
            int unreadCount = 0;

            if (state is ConversationsLoaded) {
              unreadCount = state.unreadCount;
            }

            return IconButton(
              onPressed: () {
                final userState = context.read<UserBloc>().state;

                if (userState is UserLoaded) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          InboxPage(currentUserId: userState.user.id),
                    ),
                  );
                }
              },
              style: IconButton.styleFrom(
                backgroundColor: Colors.white,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(12),
              ),
              icon: Badge(
                isLabelVisible: unreadCount > 0,
                label: Text(unreadCount.toString()),
                child: const Icon(
                  CupertinoIcons.bell, // outlined bell
                  size: 25,
                  color: Colors.black87,
                ),
              ),
            );
          },
        ),

        const SizedBox(width: 6),

        // Cart
        IconButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyProductsPage() ),
            );
          },
          style: IconButton.styleFrom(
            backgroundColor: Colors.white,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(12),
          ),
          icon: const Icon(
            CupertinoIcons.bag,
            size: 25,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}

