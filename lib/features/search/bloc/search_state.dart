import 'package:equatable/equatable.dart';
import '../../../domain/entities/product_entity.dart';

abstract class SearchState extends Equatable {
  const SearchState();

  @override
  List<Object?> get props => [];
}

class SearchInitial extends SearchState {}

class SearchLoading extends SearchState {}

class SearchResultsLoaded extends SearchState {
  final List<ProductEntity> products;
  final String query;

  const SearchResultsLoaded({required this.products, required this.query});

  @override
  List<Object?> get props => [products, query];
}

class SearchError extends SearchState {
  final String message;

  const SearchError(this.message);

  @override
  List<Object?> get props => [message];
}

