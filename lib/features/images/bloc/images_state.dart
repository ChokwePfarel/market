import 'package:equatable/equatable.dart';
import '../../../domain/entities/image_entity.dart';

abstract class ImagesState extends Equatable {
  const ImagesState();

  @override
  List<Object?> get props => [];
}

class ImagesInitial extends ImagesState {}

class ImagesLoading extends ImagesState {}

class ImagesLoaded extends ImagesState {
  final List<ImageEntity> images;
  const ImagesLoaded(this.images);

  @override
  List<Object?> get props => [images];
}

class ImageOperationSuccess extends ImagesState {
  final ImageEntity? image;
  const ImageOperationSuccess({this.image});

  @override
  List<Object?> get props => [image];
}

class ImagesError extends ImagesState {
  final String message;
  const ImagesError(this.message);

  @override
  List<Object?> get props => [message];
}

