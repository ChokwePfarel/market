import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/service_model.dart';
import '../../domain/entities/service_entity.dart';

abstract class ServiceRemoteDataSource {
  Future<List<ServiceModel>> getServices({String? university, ServiceCategory? category});
  Future<List<ServiceModel>> getUserServices(String userId);
  Future<void> createService(ServiceModel service);
  Future<void> updateService(ServiceModel service);
  Future<void> deleteService(String serviceId);
}

class ServiceRemoteDataSourceImpl implements ServiceRemoteDataSource {
  final SupabaseClient client;

  ServiceRemoteDataSourceImpl(this.client);

  @override
  Future<List<ServiceModel>> getServices({String? university, ServiceCategory? category}) async {
    try {
      var query = client.from('services').select().eq('is_active', true);
      
      if (category != null) {
        // convert enum to string format matching db
        final catStr = ServiceModel.categoryToString(category);
        query = query.eq('category', catStr);
      }

      final response = await query.order('created_at', ascending: false);
      return (response as List).map((e) => ServiceModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('ServiceRemoteDataSource: Error fetching services: $e');
      throw Exception('Failed to fetch services: $e');
    }
  }

  @override
  Future<List<ServiceModel>> getUserServices(String userId) async {
    try {
      final response = await client
          .from('services')
          .select()
          .eq('provider_id', userId)
          .order('created_at', ascending: false);

      return (response as List).map((e) => ServiceModel.fromJson(e)).toList();
    } catch (e) {
      debugPrint('ServiceRemoteDataSource: Error fetching user services: $e');
      throw Exception('Failed to fetch user services: $e');
    }
  }

  @override
  Future<void> createService(ServiceModel service) async {
    try {
      final json = service.toJson();
      debugPrint('ServiceRemoteDataSource: Creating service. Payload: $json');
      await client.from('services').insert(json);
      debugPrint('ServiceRemoteDataSource: Service created successfully.');
    } catch (e) {
      debugPrint('ServiceRemoteDataSource: Error creating service: $e');
      throw Exception('Failed to create service: $e');
    }
  }

  @override
  Future<void> updateService(ServiceModel service) async {
    try {
      final json = service.toJson();
      await client.from('services').update(json).eq('id', service.id);
    } catch (e) {
      debugPrint('ServiceRemoteDataSource: Error updating service: $e');
      throw Exception('Failed to update service: $e');
    }
  }

  @override
  Future<void> deleteService(String serviceId) async {
    try {
      await client.from('services').delete().eq('id', serviceId);
    } catch (e) {
      debugPrint('ServiceRemoteDataSource: Error deleting service: $e');
      throw Exception('Failed to delete service: $e');
    }
  }
}
