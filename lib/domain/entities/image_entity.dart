
class ImageEntity {
  final String id;
  final String userId;
  final String url;
  final String path;
  final String type;       // 'profile' | 'gallery'
  final DateTime createdAt;

  const ImageEntity({
    required this.id,
    required this.userId,
    required this.url,
    required this.path,
    required this.type,
    required this.createdAt,
  });

  bool get isProfile => type == 'profile';
  bool get isGallery => type == 'gallery';
}
