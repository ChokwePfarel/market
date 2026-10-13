import '../entities/product_entity.dart';

abstract class CartRepository {
  Future<List<ProductEntity>> getCartProducts(String userId);
  Future<void> addToCart(String userId, String productId);
  Future<void> removeFromCart(String userId, String productId);
  Future<void> clearCart(String userId);
}
