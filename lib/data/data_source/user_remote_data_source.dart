import 'package:flutter/cupertino.dart';
import 'package:market/domain/entities/user_entity.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user_model.dart';

abstract class UserRemoteDataSource {

  Future<void> createUser({
    required String name,
    required String sex,
    required String userType,
    required String university,
    required bool isVerified,
    required String profileImageUrl
  });

  Future<UserModel> getUserProfile(String userId);

  Future<void> updateUserProfile(UserModel user, {String? localImagePath});

  Future<void> updateFreeTrialStatus(String userId, bool hasFreeTrial);

  Stream<UserEntity?> watchCurrentUser();

  Future<bool> checkIsProfileCompleted(String userId);
}

class UserRemoteDataSourceImpl implements UserRemoteDataSource {
  final SupabaseClient client;

  UserRemoteDataSourceImpl({required this.client});

  @override
  Future<void> createUser({
    required String name,
    required String sex,
    required String userType,
    required String university,
    required bool isVerified,
    required String profileImageUrl,
  }) async {
    try {
      final user = client.auth.currentUser;
      if (user == null) {
        print('CREATE_USER ERROR: User is null');
        throw Exception('Not signed in');
      }

      final Map<String, dynamic> updates = {
        'id': user.id,
        'full_name': name,
        'sex': sex,
        'user_type': userType,
        'has_free_trial': true,
        'university': university,
        'is_verified': isVerified,
        'profile_image_url': profileImageUrl,
        'is_profile_completed': true,
      };

      print('Supabase Payload: $updates');
      final response = await client.from('profiles').upsert(updates).select();
      print('Supabase Response: $response');
    } catch (e) {
      print('CREATE_USER EXCEPTION: $e');
      rethrow;
    }
  }

  @override
  Stream<UserEntity?> watchCurrentUser() {
    debugPrint('UserRemoteDataSource: watchCurrentUser called');
    final user = client.auth.currentUser;
    if (user == null) return Stream.value(null);

    return client
        .from('profiles')
        .stream(primaryKey: ['id'])
        .eq('id', user.id)
        .map((data) {
          if (data.isEmpty) return null;
          return UserModel.fromJson(data.first);
        });
  }

  @override
  Future<UserModel> getUserProfile(String userId) async {
    try {
      debugPrint('UserRemoteDataSource: getUserProfile called for $userId');
      final response = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return UserModel.fromJson(response);
    } catch (e) {
      debugPrint('UserRemoteDataSource: Error fetching user profile: $e');
      throw Exception('Failed to fetch user profile: $e');
    }
  }

  @override
  Future<void> updateUserProfile(
    UserModel user, {
    String? localImagePath,
  }) async {
    try {
      String? profileImageUrl = user.profileImageUrl;

      if (localImagePath != null) {
        // TODO: Implement actual storage upload
      }

      final updatedData = user.toJson();
      
      // EXCLUDE sensitive fields from being updated here
      updatedData.remove('user_type');
      updatedData.remove('has_free_trial');
      updatedData.remove('sex');

      if (profileImageUrl != user.profileImageUrl) {
        updatedData['profile_image_url'] = profileImageUrl;
      }

      await client.from('profiles').update(updatedData).eq('id', user.id);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }

  @override
  Future<void> updateFreeTrialStatus(String userId, bool hasFreeTrial) async {
    try {
      debugPrint('UserRemoteDataSource: Updating has_free_trial to $hasFreeTrial for $userId');
      await client.from('profiles').update({'has_free_trial': hasFreeTrial}).eq('id', userId);
    } catch (e) {
      debugPrint('UserRemoteDataSource: Error updating free trial status: $e');
      throw Exception('Failed to update free trial status: $e');
    }
  }

  @override
  Future<bool> checkIsProfileCompleted(String userId) async {
    try {
      final response = await client
          .from('profiles')
          .select('is_profile_completed')
          .eq('id', userId)
          .maybeSingle(); // Use maybeSingle() instead of single()

      // If response is null, the record doesn't exist (New user)
      if (response == null) {
        return false;
      }

      return response['is_profile_completed'] as bool;
      print("Profile status: ${response['is_profile_completed']}");
    } catch (e) {
      print("Error checking profile: $e");
      return false; // Default to false to be safe
    }
  }
}
