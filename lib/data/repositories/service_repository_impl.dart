import '../../domain/entities/service_entity.dart';
import '../../domain/repositories/service_repository.dart';
import '../data_source/service_remote_data_source.dart';
import '../models/service_model.dart';

class ServiceRepositoryImpl implements ServiceRepository {
  final ServiceRemoteDataSource remoteDataSource;

  ServiceRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<ServiceEntity>> getServices({String? university, ServiceCategory? category}) async {
    return await remoteDataSource.getServices(university: university, category: category);
  }

  @override
  Future<List<ServiceEntity>> getUserServices(String userId) async {
    return await remoteDataSource.getUserServices(userId);
  }

  @override
  Future<void> createService(ServiceEntity service) async {
    final model = ServiceModel(
      id: service.id,
      providerId: service.providerId,
      title: service.title,
      description: service.description,
      category: service.category,
      priceType: service.priceType,
      priceCents: service.priceCents,
      fulfilmentModes: service.fulfilmentModes,
      resOrArea: service.resOrArea,
      imageUrls: service.imageUrls,
      contactWhatsApp: service.contactWhatsApp,
      isActive: service.isActive,
      createdAt: service.createdAt,
      updatedAt: service.updatedAt,
    );
    await remoteDataSource.createService(model);
  }

  @override
  Future<void> updateService(ServiceEntity service) async {
    final model = ServiceModel(
      id: service.id,
      providerId: service.providerId,
      title: service.title,
      description: service.description,
      category: service.category,
      priceType: service.priceType,
      priceCents: service.priceCents,
      fulfilmentModes: service.fulfilmentModes,
      resOrArea: service.resOrArea,
      imageUrls: service.imageUrls,
      contactWhatsApp: service.contactWhatsApp,
      isActive: service.isActive,
      createdAt: service.createdAt,
      updatedAt: service.updatedAt,
    );
    await remoteDataSource.updateService(model);
  }

  @override
  Future<void> deleteService(String serviceId) async {
    await remoteDataSource.deleteService(serviceId);
  }
}
