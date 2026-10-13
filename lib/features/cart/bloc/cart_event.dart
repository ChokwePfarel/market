import 'package:equatable/equatable.dart';
import '../../../domain/entities/product_entity.dart';

abstract class CartEvent extends Equatable {
  const CartEvent();

  @override
  List<Object?> get props => [];
}

class LoadCart extends CartEvent {
  final String userId;

  const LoadCart(this.userId);

  @override
  List<Object?> get props => [userId];
}

class AddToCart extends CartEvent {
  final String userId;
  final ProductEntity product;

  const AddToCart({
    required this.userId,
    required this.product,
  });

  @override
  List<Object?> get props => [userId, product];
}

class RemoveFromCart extends CartEvent {
  final String userId;
  final String productId;

  const RemoveFromCart({
    required this.userId,
    required this.productId,
  });

  @override
  List<Object?> get props => [userId, productId];
}

class ClearCart extends CartEvent {
  final String userId;

  const ClearCart(this.userId);

  @override
  List<Object?> get props => [userId];
}
