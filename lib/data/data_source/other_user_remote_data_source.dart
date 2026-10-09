import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_model.dart';

abstract class OtherUserRemoteDataSource {
  Future<UserModel> getOtherUser(String userId);

}



//--------------------------------------------------------------------


class OtherUserRemoteDataSourceImpl implements OtherUserRemoteDataSource {


  final SupabaseClient client;

  OtherUserRemoteDataSourceImpl({required this.client});

  @override
  Future<UserModel> getOtherUser(String userId) async {

      final response = await client.from('profiles').select().eq('id', userId).single();

      return UserModel.fromJson(response);

  }

}
