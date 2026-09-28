import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/entities/product_entity.dart';
import '../../../domain/repositories/product_repository.dart';

// --- EVENTS ---
abstract class OtherUserProductsEvent extends Equatable {
  const OtherUserProductsEvent();

  @override
  List<Object?> get props => [];
}

class FetchOtherUserProducts extends OtherUserProductsEvent {
  final String userId;
  const FetchOtherUserProducts(this.userId);

  @override
  List<Object?> get props => [userId];
}

// --- STATES ---
abstract class OtherUserProductsState extends Equatable {
  const OtherUserProductsState();

  @override
  List<Object?> get props => [];
}

class OtherUserProductsInitial extends OtherUserProductsState {}

class OtherUserProductsLoading extends OtherUserProductsState {}

class OtherUserProductsLoaded extends OtherUserProductsState {
  final List<ProductEntity> products;
  const OtherUserProductsLoaded(this.products);

  @override
  List<Object?> get props => [products];
}

class OtherUserProductsError extends OtherUserProductsState {
  final String message;
  const OtherUserProductsError(this.message);

  @override
  List<Object?> get props => [message];
}


//TODO MOVE THIS TO ANOTHER FILE AFTER TEXTING,,, .

// --- BLOC ---
class OtherUserProductsBloc extends Bloc<OtherUserProductsEvent, OtherUserProductsState> {
  final ProductRepository _productRepository;

  OtherUserProductsBloc(this._productRepository) : super(OtherUserProductsInitial()) {
    on<FetchOtherUserProducts>(_onFetchOtherUserProducts);
  }

  Future<void> _onFetchOtherUserProducts(
    FetchOtherUserProducts event,
    Emitter<OtherUserProductsState> emit,
  ) async {
    emit(OtherUserProductsLoading());
    try {
      final products = await _productRepository.getOtherUserProducts(event.userId);
      emit(OtherUserProductsLoaded(products));
    } catch (e) {
      emit(OtherUserProductsError(e.toString()));
    }
  }
}
