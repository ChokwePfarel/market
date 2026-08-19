import '../entities/product_entity.dart';

abstract class ProductRepository {
  Future<List<ProductEntity>> getProducts({
    required String university,
    required String category,
    required int limit,
    required int offset,
  });

  Future<void> createProduct(ProductEntity product);
  Future<int> getUserProductCount(String userId);
  Future<void> activateProduct(String productId);
  Future<List<ProductEntity>> getUserProducts(String userId);
  Future<void> updateProductPrice(String productId, double newPrice);
  Future<void> deleteProduct(String productId);
  
  Future<List<ProductEntity>> searchProducts({
    required String query,
    required String university,
  });
}
