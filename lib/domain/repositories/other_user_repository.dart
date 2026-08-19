import 'package:market/data/models/user_model.dart';

abstract class OtherUserRepository {
  Future<UserModel> getOtherUser(String userId);
}