

import '../../domain/entities/image_entity.dart';

class ImageModel extends ImageEntity {
  const ImageModel({
    required super.id,
    required super.userId,
    required super.url,
    required super.path,
    required super.type,
    required super.createdAt,
  });

  factory ImageModel.fromJson(Map<String, dynamic> json) {
    return ImageModel(
      id:        json['id'],
      userId:    json['user_id'],
      url:       json['url'],
      path:      json['path'],
      type:      json['type'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id':         id,
    'user_id':    userId,
    'url':        url,
    'path':       path,
    'type':       type,
    'created_at': createdAt.toIso8601String(),
  };
}