import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/product_model.dart';

abstract class ProductRemoteDataSource {
  Future<List<ProductModel>> getProducts({
    required String university,
    required String category,
    required int limit,
    required int offset,
  });

  Future<void> createProduct(ProductModel product);
  Future<int> getUserProductCount(String userId);
  Future<void> activateProduct(String productId);
  Future<List<ProductModel>> getUserProducts(String userId);
  Future<void> updateProductPrice(String productId, double newPrice);
  Future<void> deleteProduct(String productId);

  Future<List<ProductModel>> searchProducts({
    required String query,
    required String university,
  });
}

class ProductRemoteDataSourceImpl implements ProductRemoteDataSource {
  final SupabaseClient client;

  ProductRemoteDataSourceImpl({required this.client});

  @override
  Future<List<ProductModel>> getProducts({
    required String university,
    required String category,
    required int limit,
    required int offset,
  }) async {
    try {
      final response = await client
          .from('products')
          .select()
          .eq('university', university)
          .eq('category', category)
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      debugPrint('ProductRemoteDataSource: Fetched ${response.length} products.');
      if (response.isNotEmpty) {
        debugPrint('ProductRemoteDataSource: First product raw data: ${response.first}');
      }

      return (response as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }



  @override
  Future<void> createProduct(ProductModel product) async {
    try {
      final json = product.toJson();
      debugPrint('ProductRemoteDataSource: Inserting product to Supabase. Payload: $json');
      final response = await client.from('products').insert(json).select();
      debugPrint('ProductRemoteDataSource: Insert successful. Response: $response');
    } catch (e) {
      debugPrint('ProductRemoteDataSource: Error inserting product: $e');
      throw Exception('Failed to create product: $e');
    }
  }



  @override
  Future<int> getUserProductCount(String userId) async {
    try {
      final response = await client
          .from('products')
          .select('id')
          .eq('seller_id', userId);
      return (response as List).length;
    } catch (e) {
      throw Exception('Failed to get user product count: $e');
    }
  }

  @override
  Future<void> activateProduct(String productId) async {
    try {
      await client
          .from('products')
          .update({'status': 'active'})
          .eq('id', productId);
    } catch (e) {
      throw Exception('Failed to activate product: $e');
    }
  }

  @override
  Future<List<ProductModel>> getUserProducts(String userId) async {
    try {
      final response = await client
          .from('products')
          .select()
          .eq('seller_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user products: $e');
    }
  }

  @override
  Future<void> updateProductPrice(String productId, double newPrice) async {
    try {
      await client
          .from('products')
          .update({'price': newPrice})
          .eq('id', productId);
    } catch (e) {
      throw Exception('Failed to update product price: $e');
    }
  }

  @override
  Future<void> deleteProduct(String productId) async {
    try {
      await client.from('products').delete().eq('id', productId);
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  @override
  Future<List<ProductModel>> searchProducts({
    required String query,
    required String university,
  }) async {
    try {
      final response = await client
          .from('products')
          .select()
          .eq('university', university)
          .eq('status', 'active')
          .or('name.ilike.%$query%,description.ilike.%$query%')
          .order('created_at', ascending: false)
          .limit(20);

      return (response as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }
}
