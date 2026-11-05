import '../entities/service_entity.dart';

abstract class ServiceRepository {
  Future<List<ServiceEntity>> getServices({String? university, ServiceCategory? category});
  Future<List<ServiceEntity>> getUserServices(String userId);
  Future<void> createService(ServiceEntity service);
  Future<void> updateService(ServiceEntity service);
  Future<void> deleteService(String serviceId);
}
