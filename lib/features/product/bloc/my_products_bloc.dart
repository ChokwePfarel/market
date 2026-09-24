import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/product_entity.dart';
import '../../../domain/repositories/product_repository.dart';

// --- EVENTS ---
abstract class MyProductsEvent extends Equatable {
  const MyProductsEvent();

  @override
  List<Object?> get props => [];
}

class FetchUserProducts extends MyProductsEvent {
  final String userId;
  const FetchUserProducts(this.userId);

  @override
  List<Object?> get props => [userId];
}

class UpdateProductPrice extends MyProductsEvent {
  final String productId;
  final double newPrice;
  const UpdateProductPrice(this.productId, this.newPrice);

  @override
  List<Object?> get props => [productId, newPrice];
}

class DeleteProduct extends MyProductsEvent {
  final String productId;
  const DeleteProduct(this.productId);

  @override
  List<Object?> get props => [productId];
}

class ActivateMyProduct extends MyProductsEvent {
  final String productId;
  const ActivateMyProduct(this.productId);

  @override
  List<Object?> get props => [productId];
}

// --- STATES ---
abstract class MyProductsState extends Equatable {
  const MyProductsState();

  @override
  List<Object?> get props => [];
}

class MyProductsInitial extends MyProductsState {}

class MyProductsLoading extends MyProductsState {}

class MyProductsLoaded extends MyProductsState {
  final List<ProductEntity> products;
  const MyProductsLoaded(this.products);

  @override
  List<Object?> get props => [products];
}

class MyProductsError extends MyProductsState {
  final String message;
  const MyProductsError(this.message);

  @override
  List<Object?> get props => [message];
}

class MyProductActivatedSuccess extends MyProductsState {}

// --- BLOC ---
class MyProductsBloc extends Bloc<MyProductsEvent, MyProductsState> {
  final ProductRepository _productRepository;

  MyProductsBloc(this._productRepository) : super(MyProductsInitial()) {
    on<FetchUserProducts>(_onFetchUserProducts);
    on<UpdateProductPrice>(_onUpdateProductPrice);
    on<DeleteProduct>(_onDeleteProduct);
    on<ActivateMyProduct>(_onActivateMyProduct);
  }

  Future<void> _onFetchUserProducts(
    FetchUserProducts event,
    Emitter<MyProductsState> emit,
  ) async {
    emit(MyProductsLoading());
    try {
      final products = await _productRepository.getUserProducts(event.userId);
      emit(MyProductsLoaded(products));
    } catch (e) {
      emit(MyProductsError(e.toString()));
    }
  }

  Future<void> _onUpdateProductPrice(
    UpdateProductPrice event,
    Emitter<MyProductsState> emit,
  ) async {
    final currentState = state;
    if (currentState is MyProductsLoaded) {
      final updatedProducts = currentState.products.map((p) {
        return p.id == event.productId ? p.copyWith(price: event.newPrice) : p;
      }).toList();
      emit(MyProductsLoaded(updatedProducts));

      try {
        await _productRepository.updateProductPrice(event.productId, event.newPrice);
      } catch (e) {
        emit(MyProductsError(e.toString()));
      }
    }
  }

  Future<void> _onDeleteProduct(
    DeleteProduct event,
    Emitter<MyProductsState> emit,
  ) async {
    final currentState = state;
    if (currentState is MyProductsLoaded) {
      final updatedProducts = currentState.products.where((p) => p.id != event.productId).toList();
      emit(MyProductsLoaded(updatedProducts));

      try {
        await _productRepository.deleteProduct(event.productId);
      } catch (e) {
        emit(MyProductsError(e.toString()));
      }
    }
  }

  Future<void> _onActivateMyProduct(
    ActivateMyProduct event,
    Emitter<MyProductsState> emit,
  ) async {
    try {
      await _productRepository.activateProduct(event.productId);
      emit(MyProductActivatedSuccess());
    } catch (e) {
      emit(MyProductsError(e.toString()));
    }
  }
}
