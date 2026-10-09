import '../entities/user_entity.dart';

abstract class UserRepository {
  Future<void> createUser({
    required String name,
    required String sex,
    required String userType,
    required String university,
    required bool isVerified,
    required String profileImageUrl
  });
  Future<UserEntity> getUserProfile(String userId);
  Future<void> updateUserProfile(UserEntity user, {String? localImagePath});
  Future<void> updateFreeTrialStatus(String userId, bool hasFreeTrial);
  Stream<UserEntity?> watchCurrentUser();
  Future<bool> checkIsProfileCompleted(String userId);

}

