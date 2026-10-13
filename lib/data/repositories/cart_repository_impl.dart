import '../../domain/entities/product_entity.dart';
import '../../domain/repositories/cart_repository.dart';
import '../data_source/cart_remote_data_source.dart';

class CartRepositoryImpl implements CartRepository {
  final CartRemoteDataSource remoteDataSource;

  CartRepositoryImpl({required this.remoteDataSource});

  @override
  Future<List<ProductEntity>> getCartProducts(String userId) async {
    return await remoteDataSource.getCartProducts(userId);
  }

  @override
  Future<void> addToCart(String userId, String productId) async {
    await remoteDataSource.addToCart(userId, productId);
  }

  @override
  Future<void> removeFromCart(String userId, String productId) async {
    await remoteDataSource.removeFromCart(userId, productId);
  }

  @override
  Future<void> clearCart(String userId) async {
    await remoteDataSource.clearCart(userId);
  }
}
