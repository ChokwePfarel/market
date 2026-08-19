import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/repositories/images_repository.dart';
import 'images_event.dart';
import 'images_state.dart';

class ImagesBloc extends Bloc<ImagesEvent, ImagesState> {
  final ImagesRepository _imagesRepository;

  ImagesBloc(this._imagesRepository) : super(ImagesInitial()) {
    on<LoadProductImages>(_onLoadProductImages);
    on<UploadProfileImage>(_onUploadProfileImage);
    on<UploadProductImage>(_onUploadProductImage);
    on<DeleteImage>(_onDeleteImage);
  }

  Future<void> _onLoadProductImages(
    LoadProductImages event,
    Emitter<ImagesState> emit,
  ) async {
    emit(ImagesLoading());
    try {
      final images = await _imagesRepository.getProductImages(event.userId);
      emit(ImagesLoaded(images));
    } catch (e) {
      emit(ImagesError(e.toString()));
    }
  }

  Future<void> _onUploadProfileImage(
    UploadProfileImage event,
    Emitter<ImagesState> emit,
  ) async {
    emit(ImagesLoading());
    try {
      final image = await _imagesRepository.uploadProfileImage(
        userId: event.userId,
        image: event.image,
      );
      emit(ImageOperationSuccess(image: image));
    } catch (e) {
      emit(ImagesError(e.toString()));
    }
  }

  Future<void> _onUploadProductImage(
    UploadProductImage event,
    Emitter<ImagesState> emit,
  ) async {
    emit(ImagesLoading());
    try {
      final image = await _imagesRepository.uploadImage(
        userId: event.userId,
        image: event.image,
        type: 'gallery',
      );
      emit(ImageOperationSuccess(image: image));
    } catch (e) {
      emit(ImagesError(e.toString()));
    }
  }

  Future<void> _onDeleteImage(
    DeleteImage event,
    Emitter<ImagesState> emit,
  ) async {
    emit(ImagesLoading());
    try {
      await _imagesRepository.deleteImage(
        imageId: event.imageId,
        path: event.path,
      );
      emit(const ImageOperationSuccess());
    } catch (e) {
      emit(ImagesError(e.toString()));
    }
  }
}
