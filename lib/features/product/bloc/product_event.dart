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
