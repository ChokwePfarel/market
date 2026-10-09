import 'package:equatable/equatable.dart';

class ProductEntity extends Equatable {
  final String id;
  final String name;
  final String description;
  final double price; // Wait, looking at current file it was double. I should check again.
  final String category;
  final String university;
  final List<String> imageUrls;
  final String sellerId;
  final String status; // active, pending_payment, sold
  final DateTime createdAt;

  const ProductEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.university,
    required this.imageUrls,
    required this.sellerId,
    required this.status,
    required this.createdAt,
  });

  ProductEntity copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? category,
    String? university,
    List<String>? imageUrls,
    String? sellerId,
    String? status,
    DateTime? createdAt,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      university: university ?? this.university,
      imageUrls: imageUrls ?? this.imageUrls,
      sellerId: sellerId ?? this.sellerId,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        description,
        price,
        category,
        university,
        imageUrls,
        sellerId,
        status,
        createdAt,
      ];
}

