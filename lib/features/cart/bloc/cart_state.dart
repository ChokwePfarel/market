import 'package:equatable/equatable.dart';
import '../../../domain/entities/product_entity.dart';

abstract class CartState extends Equatable {
  const CartState();

  @override
  List<Object?> get props => [];
}

class CartInitial extends CartState {}

class CartLoading extends CartState {}

class CartLoaded extends CartState {
  final List<ProductEntity> products;
  final String? message;

  const CartLoaded({
    required this.products,
    this.message,
  });

  bool get isEmpty => products.isEmpty;

  @override
  List<Object?> get props => [products, message];
}

class CartError extends CartState {
  final String message;

  const CartError(this.message);

  @override
  List<Object?> get props => [message];
}
