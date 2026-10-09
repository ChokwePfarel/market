import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/user_repository.dart';
import '../data_source/user_remote_data_source.dart';
import '../models/user_model.dart';

class UserRepositoryImpl implements UserRepository {
  final UserRemoteDataSource remoteDataSource;

  UserRepositoryImpl({required this.remoteDataSource});


  @override
  Future<void> createUser({
    required String name,
    required String sex,
    required String userType,
    required String university,
    required bool isVerified,
    required String profileImageUrl,
  }) async {
    await remoteDataSource.createUser(
      name: name,
      sex: sex,
      userType: userType,
      university: university,
      isVerified: isVerified,
      profileImageUrl: profileImageUrl,
    );
  }


  @override
  Future<UserEntity> getUserProfile(String userId) async {
    return await remoteDataSource.getUserProfile(userId);
  }

  @override
  Future<void> updateUserProfile(UserEntity user, {String? localImagePath}) async {
    final model = UserModel(
      id: user.id,
      name: user.name,
      sex: user.sex,
      userType: user.userType,
      hasFreeTrial: user.hasFreeTrial,
      university: user.university,
      profileImageUrl: user.profileImageUrl,
      isVerified: user.isVerified,
    );
    await remoteDataSource.updateUserProfile(model, localImagePath: localImagePath);
  }

  @override
  Stream<UserEntity?> watchCurrentUser() {
    return remoteDataSource.watchCurrentUser();
  }

  @override
  Future<void> updateFreeTrialStatus(String userId, bool hasFreeTrial) async {
    await remoteDataSource.updateFreeTrialStatus(userId, hasFreeTrial);
  }

  @override
  Future<bool> checkIsProfileCompleted(String userId) async {
    return await remoteDataSource.checkIsProfileCompleted(userId);
  }
}

