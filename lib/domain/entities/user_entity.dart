import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String name;
  final String userType;
  final bool hasFreeTrial;
  final String sex;
  final String university;

  final String profileImageUrl;
  final bool isVerified;
  final bool isProfileCompleted;

  const UserEntity({
    required this.id,
    required this.name,
    required this.userType,
    required this.hasFreeTrial,
    required this.sex,
    required this.university,

    required this.profileImageUrl,
    this.isVerified = false,
    this.isProfileCompleted = false,
  });

  UserEntity copyWith({
    String? id,
    String? name,
    String? userType,
    bool? hasFreeTrial,
    String? sex,
    String? university,

    String? profileImageUrl,
    bool? isVerified,
    bool? isProfileCompleted,
  }) {
    return UserEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      userType: userType ?? this.userType,
      hasFreeTrial: hasFreeTrial ?? this.hasFreeTrial,
      sex: sex ?? this.sex,
      university: university ?? this.university,

      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      isVerified: isVerified ?? this.isVerified,
      isProfileCompleted: isProfileCompleted ?? this.isProfileCompleted,
    );
  }

  @override
  List<Object?> get props => [id, name,
    userType, hasFreeTrial,sex, university, profileImageUrl, isVerified, isProfileCompleted];
}
