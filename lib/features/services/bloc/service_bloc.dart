import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import '../../../domain/entities/service_entity.dart';
import '../../../domain/repositories/service_repository.dart';
import '../../../domain/repositories/user_repository.dart';
import 'service_event.dart';
import 'service_state.dart';

class ServiceBloc extends Bloc<ServiceEvent, ServiceState> {
  final ServiceRepository _serviceRepository;
  final UserRepository _userRepository;

  ServiceBloc(this._serviceRepository, this._userRepository) : super(ServiceInitial()) {
    on<FetchServices>(_onFetchServices);
    on<FetchUserServices>(_onFetchUserServices);
    on<CreateService>(_onCreateService);
    on<DeleteService>(_onDeleteService);
  }

  Future<void> _onFetchServices(FetchServices event, Emitter<ServiceState> emit) async {
    emit(ServiceLoading());
    try {
      final services = await _serviceRepository.getServices(
        university: event.university,
        category: event.category,
      );
      emit(ServicesLoaded(services));
    } catch (e) {
      emit(ServiceError(e.toString()));
    }
  }

  Future<void> _onFetchUserServices(FetchUserServices event, Emitter<ServiceState> emit) async {
    emit(ServiceLoading());
    try {
      final services = await _serviceRepository.getUserServices(event.userId);
      emit(UserServicesLoaded(services));
    } catch (e) {
      emit(ServiceError(e.toString()));
    }
  }

  Future<void> _onCreateService(CreateService event, Emitter<ServiceState> emit) async {
    emit(ServiceLoading());
    try {
      // 1. Check free trial status of the user
      final user = await _userRepository.getUserProfile(event.providerId);
      final bool hasFreeTrial = user.hasFreeTrial;

      final serviceId = const Uuid().v4();

      if (!hasFreeTrial) {
        // User has no free trial -> emit subscription/payment placeholder state
        emit(ServicePaymentRequired(serviceId: serviceId));
        return;
      }

      // 2. Create service entity
      final service = ServiceEntity(
        id: serviceId,
        providerId: event.providerId,
        title: event.title,
        description: event.description,
        category: event.category,
        priceType: event.priceType,
        priceCents: event.priceCents,
        fulfilmentModes: event.fulfilmentModes,
        resOrArea: event.resOrArea,
        imageUrls: event.imageUrls,
        contactWhatsApp: event.contactWhatsApp,
        isActive: true,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _serviceRepository.createService(service);

      // 3. Update free trial status to false
      try {
        await _userRepository.updateFreeTrialStatus(event.providerId, false);
      } catch (_) {}

      emit(ServiceCreatedSuccess());
    } catch (e) {
      emit(ServiceError(e.toString()));
    }
  }

  Future<void> _onDeleteService(DeleteService event, Emitter<ServiceState> emit) async {
    try {
      await _serviceRepository.deleteService(event.serviceId);
      add(FetchUserServices(event.userId));
    } catch (e) {
      emit(ServiceError(e.toString()));
    }
  }
}
