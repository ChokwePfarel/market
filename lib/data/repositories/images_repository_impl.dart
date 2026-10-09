import 'dart:io';
import '../../domain/entities/image_entity.dart';
import '../../domain/repositories/images_repository.dart';
import '../data_source/images_remote_data_source.dart';

class ImagesRepositoryImpl implements ImagesRepository {
  final ImagesRemoteDataSource remoteDataSource;

  ImagesRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<ImageEntity>> getProductImages(String userId) async {
    return await remoteDataSource.getProductImages(userId);
  }

  @override
  Future<ImageEntity> uploadProfileImage({
    required String userId,
    required File image,
  }) async {
    return await remoteDataSource.uploadProfileImage(
      userId: userId,
      image: image,
    );
  }

  @override
  Future<ImageEntity> uploadImage({
    required String userId,
    required File image,
    required String type,
  }) async {
    return await remoteDataSource.uploadImage(
      userId: userId,
      image: image,
      type: type,
    );
  }

  @override
  Future<void> deleteImage({required String imageId, required String path}) async {
    await remoteDataSource.deleteImage(imageId: imageId, path: path);
  }
}

