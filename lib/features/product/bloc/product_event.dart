import 'package:equatable/equatable.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

class FetchProducts extends ProductEvent {
  final String university;
  final String category;
  final bool isRefresh;

  const FetchProducts({
    required this.university,
    required this.category,
    this.isRefresh = false,
  });

  @override
  List<Object?> get props => [university, category, isRefresh];
}

class AddProduct extends ProductEvent {
  final String name;
  final String description;
  final double price;
  final String category;
  final String university;
  final List<String> imageUrls;
  final String sellerId;

  const AddProduct({
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.university,
    required this.imageUrls,
    required this.sellerId,
  });

  @override
  List<Object?> get props => [name, description, price, category, university, imageUrls, sellerId];
}

class ActivateProductEvent extends ProductEvent {
  final String productId;

  const ActivateProductEvent(this.productId);

  @override
  List<Object?> get props => [productId];
}

class FetchUserProducts extends ProductEvent {
  final String userId;

  const FetchUserProducts(this.userId);

  @override
  List<Object?> get props => [userId];
}

class FetchOtherUserProducts extends ProductEvent {
  final String userId;

  const FetchOtherUserProducts(this.userId);

  @override
  List<Object?> get props => [userId];
}

class UpdateProductPrice extends ProductEvent {
  final String productId;
  final double newPrice;

  const UpdateProductPrice(this.productId, this.newPrice);

  @override
  List<Object?> get props => [productId, newPrice];
}

class DeleteProduct extends ProductEvent {
  final String productId;

  const DeleteProduct(this.productId);

  @override
  List<Object?> get props => [productId];
}
