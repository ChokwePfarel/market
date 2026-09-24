import 'package:equatable/equatable.dart';
import '../../../domain/entities/product_entity.dart';

abstract class ProductState extends Equatable {
  const ProductState();

  @override
  List<Object?> get props => [];
}

class ProductInitial extends ProductState {}

class ProductLoading extends ProductState {}

class ProductLoaded extends ProductState {
  final List<ProductEntity> products;
  final bool hasReachedMax;
  final String currentCategory;

  const ProductLoaded({
    required this.products,
    required this.hasReachedMax,
    required this.currentCategory,
  });

  ProductLoaded copyWith({
    List<ProductEntity>? products,
    bool? hasReachedMax,
    String? currentCategory,
  }) {
    return ProductLoaded(
      products: products ?? this.products,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      currentCategory: currentCategory ?? this.currentCategory,
    );
  }

  @override
  List<Object?> get props => [products, hasReachedMax, currentCategory];
}

class ProductAddedSuccess extends ProductState {}

class PaymentRequired extends ProductState {
  final String productId;

  const PaymentRequired({required this.productId});

  @override
  List<Object?> get props => [productId];
}

class UserProductsLoaded extends ProductState {
  final List<ProductEntity> products;

  const UserProductsLoaded(this.products);

  @override
  List<Object?> get props => [products];
}

class OtherUserProductsLoaded extends ProductState {
  final List<ProductEntity> products;

  const OtherUserProductsLoaded(this.products);

  @override
  List<Object?> get props => [products];
}

class ProductError extends ProductState {
  final String message;

  const ProductError(this.message);

  @override
  List<Object?> get props => [message];
}
