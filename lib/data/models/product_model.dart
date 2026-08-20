import 'dart:convert';
import 'package:flutter/cupertino.dart';

import '../../domain/entities/product_entity.dart';

class ProductModel extends ProductEntity {
  const ProductModel({
    required super.id,
    required super.name,
    required super.description,
    required super.price,
    required super.category,
    required super.university,
    required super.imageUrls,
    required super.sellerId,
    required super.status,
    required super.createdAt,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    // Robust parsing for image_urls to handle various formats from Supabase
    List<String> parsedUrls = [];
    try {
      // Check both plural and singular just in case of mismatch
      final rawUrls = json['image_urls'] ?? json['image_url'];
      
      if (rawUrls == null) {
        parsedUrls = [];
      } else if (rawUrls is List) {
        // Filter out any nulls and ensure everything is a string
        parsedUrls = rawUrls
            .where((item) => item != null)
            .map((item) => item.toString())
            .toList();
      } else if (rawUrls is String) {
        final trimmed = rawUrls.trim();
        if (trimmed.isEmpty) {
          parsedUrls = [];
        } else if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
          // Handle stringified JSON array format ["url1","url2"]
          try {
            final List decoded = jsonDecode(trimmed);
            parsedUrls = decoded.map((e) => e.toString()).toList();
          } catch (e) {
            debugPrint('ProductModel: JSON parsing failed, treating as single string');
            parsedUrls = [trimmed];
          }
        } else if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
          // Handle Postgres array string format "{url1,url2}"
          String content = trimmed.substring(1, trimmed.length - 1);
          if (content.isEmpty) {
            parsedUrls = [];
          } else {
            parsedUrls = content
                .split(',')
                .map((s) {
                  String res = s.trim();
                  // Remove quotes added by Postgres for special characters/format
                  if (res.startsWith('"') && res.endsWith('"')) {
                    res = res.substring(1, res.length - 1);
                  }
                  return res;
                })
                .where((s) => s.isNotEmpty)
                .toList();
          }
        } else {
          // Handle single string case
          parsedUrls = [trimmed];
        }
      }
    } catch (e) {
      debugPrint('ProductModel: Error parsing image_urls: $e');
      parsedUrls = [];
    }

    return ProductModel(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      category: json['category'] ?? '',
      university: json['university'] ?? '',
      imageUrls: parsedUrls,
      sellerId: json['seller_id'] ?? '',
      status: json['status'] ?? 'active',
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'university': university,
      'image_urls': imageUrls,
      'seller_id': sellerId,
      'status': status,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
