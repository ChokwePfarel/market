import 'package:equatable/equatable.dart';
import '../../../domain/entities/service_entity.dart';

abstract class ServiceEvent extends Equatable {
  const ServiceEvent();

  @override
  List<Object?> get props => [];
}

class FetchServices extends ServiceEvent {
  final String? university;
  final ServiceCategory? category;

  const FetchServices({this.university, this.category});

  @override
  List<Object?> get props => [university, category];
}

class FetchUserServices extends ServiceEvent {
  final String userId;

  const FetchUserServices(this.userId);

  @override
  List<Object?> get props => [userId];
}

class CreateService extends ServiceEvent {
  final String title;
  final String description;
  final ServiceCategory category;
  final PriceType priceType;
  final int? priceCents;
  final List<FulfilmentMode> fulfilmentModes;
  final String? resOrArea;
  final List<String> imageUrls;
  final String? contactWhatsApp;
  final String providerId;

  const CreateService({
    required this.title,
    required this.description,
    required this.category,
    required this.priceType,
    this.priceCents,
    required this.fulfilmentModes,
    this.resOrArea,
    required this.imageUrls,
    this.contactWhatsApp,
    required this.providerId,
  });

  @override
  List<Object?> get props => [
        title,
        description,
        category,
        priceType,
        priceCents,
        fulfilmentModes,
        resOrArea,
        imageUrls,
        contactWhatsApp,
        providerId,
      ];
}

class DeleteService extends ServiceEvent {
  final String serviceId;
  final String userId;

  const DeleteService({required this.serviceId, required this.userId});

  @override
  List<Object?> get props => [serviceId, userId];
}
