
import 'package:market/data/data_source/other_user_remote_data_source.dart';
import 'package:market/data/models/user_model.dart';

import '../../domain/repositories/other_user_repository.dart';

class OtherUserRepositoryImpl implements OtherUserRepository {

  final OtherUserRemoteDataSource dataSource;


  OtherUserRepositoryImpl({required this.dataSource});

  @override

  Future<UserModel> getOtherUser(String userId) async {
    return await dataSource.getOtherUser(userId);
  }
}
