import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/utils/offline_cache.dart';
import '../../../domain/entities/product_entity.dart';
import '../../../domain/repositories/cart_repository.dart';
import 'cart_event.dart';
import 'cart_state.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  final CartRepository _cartRepository;

  CartBloc(this._cartRepository) : super(CartInitial()) {
    on<LoadCart>(_onLoadCart);
    on<AddToCart>(_onAddToCart);
    on<RemoveFromCart>(_onRemoveFromCart);
    on<ClearCart>(_onClearCart);
  }

  Future<void> _onLoadCart(LoadCart event, Emitter<CartState> emit) async {
    // 1. Show cached items first for fast rendering
    final cached = OfflineCache.getCachedProducts('user_cart_${event.userId}');
    if (cached.isNotEmpty) {
      emit(CartLoaded(products: cached));
    } else if (state is! CartLoaded) {
      emit(CartLoading());
    }

    // 2. Fetch from Supabase Database
    try {
      final remoteProducts = await _cartRepository.getCartProducts(event.userId);
      await OfflineCache.cacheProducts('user_cart_${event.userId}', remoteProducts);
      emit(CartLoaded(products: remoteProducts));
    } catch (e) {
      debugPrint('CartBloc: Error fetching remote cart: $e');
      if (state is! CartLoaded) {
        emit(CartError(e.toString()));
      }
    }
  }

  Future<void> _onAddToCart(AddToCart event, Emitter<CartState> emit) async {
    List<ProductEntity> currentProducts = [];

    if (state is CartLoaded) {
      currentProducts = List.from((state as CartLoaded).products);
    } else {
      currentProducts = OfflineCache.getCachedProducts('user_cart_${event.userId}');
    }

    // Check if product is already in cart
    final exists = currentProducts.any((p) => p.id == event.product.id);
    if (!exists) {
      currentProducts.add(event.product);
      await OfflineCache.cacheProducts('user_cart_${event.userId}', currentProducts);

      emit(CartLoaded(
        products: currentProducts,
        message: 'Added "${event.product.name}" to cart',
      ));

      // Persist to Supabase Database
      try {
        await _cartRepository.addToCart(event.userId, event.product.id);
      } catch (e) {
        debugPrint('CartBloc: Remote add to cart failed: $e');
      }
    } else {
      emit(CartLoaded(
        products: currentProducts,
        message: '"${event.product.name}" is already in your cart',
      ));
    }
  }

  Future<void> _onRemoveFromCart(RemoveFromCart event, Emitter<CartState> emit) async {
    List<ProductEntity> currentProducts = [];

    if (state is CartLoaded) {
      currentProducts = List.from((state as CartLoaded).products);
    } else {
      currentProducts = OfflineCache.getCachedProducts('user_cart_${event.userId}');
    }

    currentProducts.removeWhere((p) => p.id == event.productId);
    await OfflineCache.cacheProducts('user_cart_${event.userId}', currentProducts);

    emit(CartLoaded(products: currentProducts));

    try {
      await _cartRepository.removeFromCart(event.userId, event.productId);
    } catch (e) {
      debugPrint('CartBloc: Remote remove from cart failed: $e');
    }
  }

  Future<void> _onClearCart(ClearCart event, Emitter<CartState> emit) async {
    await OfflineCache.cacheProducts('user_cart_${event.userId}', []);
    emit(const CartLoaded(products: []));

    try {
      await _cartRepository.clearCart(event.userId);
    } catch (e) {
      debugPrint('CartBloc: Remote clear cart failed: $e');
    }
  }
}
