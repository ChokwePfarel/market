import 'package:equatable/equatable.dart';
import '../../../data/models/product_model.dart';
import '../../../domain/entities/product_entity.dart';

class CartItem extends Equatable {
  final ProductEntity product;
  final int quantity;

  const CartItem({
    required this.product,
    this.quantity = 1,
  });

  double get totalPrice => product.price * quantity;

  CartItem copyWith({
    ProductEntity? product,
    int? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'product': product is ProductModel
          ? (product as ProductModel).toJson()
          : ProductModel(
              id: product.id,
              name: product.name,
              description: product.description,
              price: product.price,
              category: product.category,
              university: product.university,
              imageUrls: product.imageUrls,
              sellerId: product.sellerId,
              status: product.status,
              createdAt: product.createdAt,
            ).toJson(),
      'quantity': quantity,
    };
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    return CartItem(
      product: ProductModel.fromJson(Map<String, dynamic>.from(json['product'] ?? {})),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
    );
  }

  @override
  List<Object?> get props => [product, quantity];
}
