import 'dart:io';
import 'package:equatable/equatable.dart';

abstract class ImagesEvent extends Equatable {
  const ImagesEvent();

  @override
  List<Object?> get props => [];
}

class LoadProductImages extends ImagesEvent {
  final String userId;
  const LoadProductImages(this.userId);

  @override
  List<Object?> get props => [userId];
}

class UploadProfileImage extends ImagesEvent {
  final String userId;
  final File image;
  const UploadProfileImage({required this.userId, required this.image});

  @override
  List<Object?> get props => [userId, image];
}

class UploadProductImage extends ImagesEvent {
  final String userId;
  final File image;
  const UploadProductImage({required this.userId, required this.image});

  @override
  List<Object?> get props => [userId, image];
}

class DeleteImage extends ImagesEvent {
  final String imageId;
  final String path;
  const DeleteImage({required this.imageId, required this.path});

  @override
  List<Object?> get props => [imageId, path];
}
