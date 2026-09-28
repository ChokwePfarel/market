import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class CustomAvatar extends StatelessWidget {

  final String url;
  const CustomAvatar({super.key, required this.url});

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) {
      return Container(
        width: 58,
        height: 54,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
        child: const Icon(Icons.person, color: Colors.grey, size: 28),
      );
    }

    if (url.startsWith('http')) {
      return CachedNetworkImage(
        imageUrl: url,
        imageBuilder: (context, imageProvider) => Container(
          width: 58,
          height: 54,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: DecorationImage(image: imageProvider, fit: BoxFit.cover),
          ),
        ),
        placeholder: (context, url) => Container(
          width: 58,
          height: 54,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
        errorWidget: (context, url, error) => Container(
          width: 58,
          height: 54,
          decoration: const BoxDecoration(shape: BoxShape.circle, color: Colors.white),
          child: const Icon(Icons.person, color: Colors.grey, size: 28),
        ),
      );
    }


    //Fixing The Image not showing bugg
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
