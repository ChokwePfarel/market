import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/offline_cache.dart';
import '../../../domain/repositories/product_repository.dart';
import '../../../domain/repositories/user_repository.dart';
import '../../../domain/repositories/payment_repository.dart';
import '../../../domain/entities/product_entity.dart';
import 'product_event.dart';
import 'product_state.dart';
import 'package:uuid/uuid.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository _productRepository;
  final UserRepository _userRepository;
  static const int _limit = 10;

  ProductBloc(this._productRepository, this._userRepository, [PaymentRepository? paymentRepository]) : super(ProductInitial()) {
    on<FetchProducts>(_onFetchProducts);
    on<AddProduct>(_onAddProduct);
    on<ActivateProductEvent>(_onActivateProduct);
  }

  Future<void> _onFetchProducts(
    FetchProducts event,
    Emitter<ProductState> emit,
  ) async {
    final currentState = state;

    // Only emit loading if we don't have existing products to show
    if (event.isRefresh && currentState is! ProductLoaded) {
      emit(ProductLoading());
    }

    final cacheKey = '${event.university}_${event.category}';
    final cached = OfflineCache.getCachedProducts(cacheKey);

    // If initial load and we have cache, show it immediately
    if (currentState is! ProductLoaded && cached.isNotEmpty) {
      emit(ProductLoaded(
        products: cached,
        hasReachedMax: false,
        currentCategory: event.category,
      ));
    }

    // Optimization: avoid redundant fetches for the same category if already reached max
    if (currentState is ProductLoaded &&
        currentState.hasReachedMax &&
        !event.isRefresh &&
        currentState.currentCategory == event.category) {
      return;
    }

    try {
      int offset = 0;
      List<ProductEntity> currentProducts = [];

      if (currentState is ProductLoaded &&
          !event.isRefresh &&
          currentState.currentCategory == event.category) {
        currentProducts = currentState.products;
        offset = currentProducts.length;
      }

      final products = await _productRepository.getProducts(
        university: event.university,
        category: event.category,
        limit: _limit,
        offset: offset,
      );

      final allProducts = event.isRefresh ? products : [...currentProducts, ...products];

      if (event.isRefresh) {
        await OfflineCache.cacheProducts(cacheKey, products);
      }

      emit(ProductLoaded(
        products: allProducts,
        hasReachedMax: products.length < _limit,
        currentCategory: event.category,
      ));
      
    } catch (e) {
      if (state is! ProductLoaded) {
        emit(ProductError(e.toString()));
      }
    }
  }

  Future<void> _onAddProduct(
    AddProduct event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    try {
      final user = await _userRepository.getUserProfile(event.sellerId);
      final bool hasFreeTrial = user.hasFreeTrial;

      final productId = const Uuid().v4();
      final String status = hasFreeTrial ? 'active' : 'pending_payment';

      final product = ProductEntity(
        id: productId,
        name: event.name,
        description: event.description,
        price: event.price,
        category: event.category,
        university: event.university,
        imageUrls: event.imageUrls,
        sellerId: event.sellerId,
        status: status,
        createdAt: DateTime.now(),
      );

      await _productRepository.createProduct(product);

      if (status == 'active') {
        try {
          await _userRepository.updateFreeTrialStatus(event.sellerId, false);
        } catch (updateError) {
          //debugPrint('ProductBloc: updateFreeTrialStatus failed: $updateError');
        }
        
        emit(ProductAddedSuccess());
      } else {
        emit(PaymentRequired(productId: productId));
      }
    } catch (e) {
      //debugPrint('ProductBloc: Error during AddProduct: $e');
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onActivateProduct(
    ActivateProductEvent event,
    Emitter<ProductState> emit,
  ) async {
    //debugPrint('ProductBloc: Activating product ${event.productId}');
    try {
      await _productRepository.activateProduct(event.productId);
      emit(ProductAddedSuccess());
    } catch (e) {
      //debugPrint('ProductBloc: Activation error: $e');
      emit(ProductError(e.toString()));
    }
  }
}

