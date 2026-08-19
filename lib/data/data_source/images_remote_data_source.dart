import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/image_model.dart';

abstract class ImagesRemoteDataSource {
  Future<List<ImageModel>> getProductImages(String userId);

  Future<ImageModel> uploadProfileImage({
    required String userId,
    required File image,
  });

  Future<ImageModel> uploadImage({
    required String userId,
    required File image,
    required String type, // 'profile' | 'product'
  });

  Future<void> deleteImage({required String imageId, required String path});
}

class ImagesRemoteDataSourceImpl implements ImagesRemoteDataSource {
  final SupabaseClient client;
  static const _bucket = 'user-images';

  ImagesRemoteDataSourceImpl(this.client);

  @override
  Future<List<ImageModel>> getProductImages(String userId) async {
    try {
      final response = await client
          .from('product_images')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((e) => ImageModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('Error fetching images: $e');
      return [];
    }
  }

  @override
  Future<ImageModel> uploadProfileImage({
    required String userId,
    required File image,
  }) async {
    try {
      // 1. Upload to Storage
      final path = '$userId/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      await client.storage.from(_bucket).upload(
            path,
            image,
            fileOptions: const FileOptions(upsert: true),
          );

      final url = client.storage.from(_bucket).getPublicUrl(path);

      // 2. Save metadata to product_images table (keeping track of history)
      final imageMetadata = await client
          .from('product_images')
          .insert({
            'user_id': userId,
            'url': url,
            'path': path,
            'type': 'profile',
          })
          .select()
          .single();

      // 3. Update the profiles table with the new URL
      await client.from('profiles').update({'profile_image_url': url}).eq('id', userId);

      return ImageModel.fromJson(imageMetadata);
    } catch (e) {
      debugPrint('Error uploading profile image: $e');
      throw Exception('Failed to upload profile image');
    }
  }

  @override
  Future<ImageModel> uploadImage({
    required String userId,
    required File image,
    required String type,
  }) async {
    try {
      final fileName = '${type}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final path = '$userId/$fileName';

      debugPrint('ImagesRemoteDataSource: Uploading $type image to path: $path');
      await client.storage.from(_bucket).upload(path, image);
      final url = client.storage.from(_bucket).getPublicUrl(path);
      debugPrint('ImagesRemoteDataSource: Image uploaded. Public URL: $url');

      debugPrint('ImagesRemoteDataSource: Saving metadata to product_images table...');
      final response = await client
          .from('product_images')
          .insert({
            'user_id': userId,
            'url': url,
            'path': path,
            'type': type,
          })
          .select()
          .single();
      debugPrint('ImagesRemoteDataSource: Metadata saved successfully: $response');

      return ImageModel.fromJson(response);
    } catch (e) {
      debugPrint('ImagesRemoteDataSource: Error uploading image: $e');
      throw Exception('Failed to upload image');
    }
  }

  @override
  Future<void> deleteImage({required String imageId, required String path}) async {
    try {
      await client.storage.from(_bucket).remove([path]);
      await client.from('product_images').delete().eq('id', imageId);
    } catch (e) {
      debugPrint('Error deleting image: $e');
      throw Exception('Failed to delete image');
    }
  }
}
