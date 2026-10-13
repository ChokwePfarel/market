import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';

abstract class CartRemoteDataSource {
  Future<List<ProductModel>> getCartProducts(String userId);
  Future<void> addToCart(String userId, String productId);
  Future<void> removeFromCart(String userId, String productId);
  Future<void> clearCart(String userId);
}

class CartRemoteDataSourceImpl implements CartRemoteDataSource {
  final SupabaseClient client;

  CartRemoteDataSourceImpl({required this.client});

  @override
  Future<List<ProductModel>> getCartProducts(String userId) async {
    try {
      final response = await client
          .from('user_cart')
          .select('product_id')
          .eq('user_id', userId);

      final List<dynamic> rows = response as List;
      if (rows.isEmpty) return [];

      final List<String> productIds = rows
          .map((row) => row['product_id']?.toString())
          .whereType<String>()
          .toList();

      if (productIds.isEmpty) return [];

      final productsResponse = await client
          .from('products')
          .select()
          .inFilter('id', productIds);

      return (productsResponse as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('CartRemoteDataSource: Error fetching cart products: $e');
      return [];
    }
  }

  @override
  Future<void> addToCart(String userId, String productId) async {
    try {
      await client.from('user_cart').upsert(
        {
          'user_id': userId,
          'product_id': productId,
        },
        onConflict: 'user_id,product_id',
      );
      debugPrint('CartRemoteDataSource: Added product $productId to cart for user $userId');
    } catch (e) {
      debugPrint('CartRemoteDataSource: Error adding to cart: $e');
      throw Exception('Failed to add product to cart database');
    }
  }

  @override
  Future<void> removeFromCart(String userId, String productId) async {
    try {
      await client
          .from('user_cart')
          .delete()
          .eq('user_id', userId)
          .eq('product_id', productId);
      debugPrint('CartRemoteDataSource: Removed product $productId from cart');
    } catch (e) {
      debugPrint('CartRemoteDataSource: Error removing from cart: $e');
      throw Exception('Failed to remove product from cart');
    }
  }

  @override
  Future<void> clearCart(String userId) async {
    try {
      await client.from('user_cart').delete().eq('user_id', userId);
      debugPrint('CartRemoteDataSource: Cleared cart for user $userId');
    } catch (e) {
      debugPrint('CartRemoteDataSource: Error clearing cart: $e');
      throw Exception('Failed to clear cart');
    }
  }
}
