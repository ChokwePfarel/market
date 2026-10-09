import 'dart:io';
import '../entities/image_entity.dart';

abstract class ImagesRepository {
  Future<List<ImageEntity>> getProductImages(String userId);

  Future<ImageEntity> uploadProfileImage({
    required String userId,
    required File image,
  });

  Future<ImageEntity> uploadImage({
    required String userId,
    required File image,
    required String type,
  });

  Future<void> deleteImage({required String imageId, required String path});
}

