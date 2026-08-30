import 'package:flutter/cupertino.dart';
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
  final PaymentRepository _paymentRepository;
  static const int _limit = 10;

  ProductBloc(this._productRepository, this._userRepository, this._paymentRepository) : super(ProductInitial()) {
    on<FetchProducts>(_onFetchProducts);
    on<AddProduct>(_onAddProduct);
    on<ActivateProductEvent>(_onActivateProduct);
    on<FetchUserProducts>(_onFetchUserProducts);
    on<UpdateProductPrice>(_onUpdateProductPrice);
    on<DeleteProduct>(_onDeleteProduct);
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
      
      debugPrint('ProductBloc: Emitted ${allProducts.length} products. First product images: ${allProducts.isNotEmpty ? allProducts.first.imageUrls : 'N/A'}');
    } catch (e) {
      debugPrint('ProductBloc: Error fetching products: $e');
      if (state is! ProductLoaded) {
        emit(ProductError(e.toString()));
      }
    }
  }

  Future<void> _onAddProduct(
    AddProduct event,
    Emitter<ProductState> emit,
  ) async {
    debugPrint('ProductBloc: _onAddProduct started for ${event.name}');
    emit(ProductLoading());
    try {
      debugPrint('ProductBloc: Fetching user profile to check free trial status...');
      final user = await _userRepository.getUserProfile(event.sellerId);
      final bool hasFreeTrial = user.hasFreeTrial;
      debugPrint('ProductBloc: User has free trial: $hasFreeTrial');

      final productId = const Uuid().v4();
      // Use the boolean flag as the source of truth
      final String status = hasFreeTrial ? 'active' : 'pending_payment';
      debugPrint('ProductBloc: Generated Product ID: $productId, target status: $status');

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

      debugPrint('ProductBloc: Calling repository.createProduct...');
      await _productRepository.createProduct(product);
      debugPrint('ProductBloc: Repository call successful.');

      if (status == 'active') {
        debugPrint('ProductBloc: status is active. User repository: $_userRepository');
        
        debugPrint('ProductBloc: Flipping has_free_trial to false for ${event.sellerId}');
        
        try {
          // Double-check: immediately flip the trial flag so they can't list another one for free
          await _userRepository.updateFreeTrialStatus(event.sellerId, false);
          debugPrint('ProductBloc: updateFreeTrialStatus successful.');
        } catch (updateError) {
          debugPrint('ProductBloc: updateFreeTrialStatus failed: $updateError');
        }
        
        debugPrint('ProductBloc: Emitting ProductAddedSuccess');
        emit(ProductAddedSuccess());
      } else {
        debugPrint('ProductBloc: Emitting PaymentRequired for $productId');
        emit(PaymentRequired(productId: productId));
      }
    } catch (e) {
      debugPrint('ProductBloc: Error during AddProduct: $e');
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onActivateProduct(
    ActivateProductEvent event,
    Emitter<ProductState> emit,
  ) async {
    debugPrint('ProductBloc: Activating product ${event.productId}');
    try {
      await _productRepository.activateProduct(event.productId);
      debugPrint('ProductBloc: Activation successful, emitting ProductAddedSuccess');
      emit(ProductAddedSuccess());
    } catch (e) {
      debugPrint('ProductBloc: Activation error: $e');
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onFetchUserProducts(
    FetchUserProducts event,
    Emitter<ProductState> emit,
  ) async {
    emit(ProductLoading());
    try {
      final products = await _productRepository.getUserProducts(event.userId);
      emit(UserProductsLoaded(products));
    } catch (e) {
      emit(ProductError(e.toString()));
    }
  }

  Future<void> _onUpdateProductPrice(
    UpdateProductPrice event,
    Emitter<ProductState> emit,
  ) async {
    final currentState = state;
    if (currentState is UserProductsLoaded) {
      final updatedProducts = currentState.products.map((p) {
        return p.id == event.productId ? p.copyWith(price: event.newPrice) : p;
      }).toList();
      emit(UserProductsLoaded(updatedProducts));

      try {
        await _productRepository.updateProductPrice(event.productId, event.newPrice);
      } catch (e) {
        emit(ProductError(e.toString()));
        // Optional: Revert on error
      }
    }
  }

  Future<void> _onDeleteProduct(
    DeleteProduct event,
    Emitter<ProductState> emit,
  ) async {
    final currentState = state;
    if (currentState is UserProductsLoaded) {
      final updatedProducts = currentState.products.where((p) => p.id != event.productId).toList();
      emit(UserProductsLoaded(updatedProducts));

      try {
        await _productRepository.deleteProduct(event.productId);
      } catch (e) {
        emit(ProductError(e.toString()));
      }
    }
  }
}
