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
    // Robust parsing for image_urls to handle both List and legacy String cases
    List<String> parsedUrls = [];
    try {
      final rawUrls = json['image_urls'];
      if (rawUrls is List) {
        parsedUrls = List<String>.from(rawUrls);
      } else if (rawUrls is String && rawUrls.isNotEmpty) {
        // Handle case where it might be a single URL or a Postgres array string "{url1,url2}"
        if (rawUrls.startsWith('{') && rawUrls.endsWith('}')) {
          parsedUrls = rawUrls
              .substring(1, rawUrls.length - 1)
              .split(',')
              .map((s) => s.trim())
              .where((s) => s.isNotEmpty)
              .toList();
        } else {
          parsedUrls = [rawUrls];
        }
      }
    } catch (e) {
      debugPrint('ProductModel: Error parsing image_urls: $e');
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
