import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.id,
    required super.name,
    required super.userType,
    required super.hasFreeTrial,
    required super.sex,
    required super.university,
    required super.profileImageUrl,
    super.isVerified = false,
    super.isProfileCompleted = false,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? '',
      name: json['full_name'] ?? json['name'] ?? '',
      userType: json['user_type'] ?? '',
      hasFreeTrial: json['has_free_trial'] ?? false,
      sex: json['sex'] ?? '',
      university: json['university'] ?? '',

      profileImageUrl: json['profile_image_url'] ?? '',
      isVerified: json['is_verified'] ?? false,
      isProfileCompleted: json['is_profile_completed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': name,
      'user_type': userType,
      'has_free_trial': hasFreeTrial,
      'sex': sex,
      'university': university,

      'profile_image_url': profileImageUrl,
      'is_verified': isVerified,
      'is_profile_completed': isProfileCompleted,
    };
  }
}

