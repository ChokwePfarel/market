import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/product_repository.dart';
import '../data_source/product_remote_data_source.dart';
import '../models/product_model.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductRemoteDataSource remoteDataSource;

  ProductRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<ProductEntity>> getProducts({
    required String university,
    required String category,
    required int limit,
    required int offset,
  }) async {
    return await remoteDataSource.getProducts(
      university: university,
      category: category,
      limit: limit,
      offset: offset,
    );
  }

  @override
  Future<void> createProduct(ProductEntity product) async {
    final model = ProductModel(
      id: product.id,
      name: product.name,
      description: product.description,
      price: product.price,
      category: product.category,
      university: product.university,
      imageUrls: product.imageUrls,
      sellerId: product.sellerId,
      status: product.status,
      createdAt: product.createdAt,
    );
    await remoteDataSource.createProduct(model);
  }

  @override
  Future<int> getUserProductCount(String userId) async {
    return await remoteDataSource.getUserProductCount(userId);
  }

  @override
  Future<void> activateProduct(String productId) async {
    await remoteDataSource.activateProduct(productId);
  }

  @override
  Future<List<ProductEntity>> getUserProducts(String userId) async {
    return await remoteDataSource.getUserProducts(userId);
  }

  @override
  Future<List<ProductEntity>> getOtherUserProducts(String userId) async {
    return await remoteDataSource.getOtherUserProducts(userId);
  }

  @override
  Future<void> updateProductPrice(String productId, double newPrice) async {
    await remoteDataSource.updateProductPrice(productId, newPrice);
  }

  @override
  Future<void> deleteProduct(String productId) async {
    await remoteDataSource.deleteProduct(productId);
  }

  @override
  Future<List<ProductEntity>> searchProducts({
    required String query,
    required String university,
  }) async {
    return await remoteDataSource.searchProducts(
      query: query,
      university: university,
    );
  }


}
