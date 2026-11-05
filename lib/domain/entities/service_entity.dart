import 'package:equatable/equatable.dart';

enum ServiceCategory { shoeCleaning, phoneRepair, delivery, hairAndBeauty, other }

enum PriceType { fixed, startingFrom, quote }

enum FulfilmentMode { atProvider, comesToYou, pickupAndDropoff, campusDelivery }

class ServiceEntity extends Equatable {
  final String id;
  final String providerId;
  final String title;
  final String description;
  final ServiceCategory category;
  final PriceType priceType;
  final int? priceCents;
  final List<FulfilmentMode> fulfilmentModes;
  final String? resOrArea;
  final List<String> imageUrls;
  final String? contactWhatsApp;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const ServiceEntity({
    required this.id,
    required this.providerId,
    required this.title,
    required this.description,
    required this.category,
    required this.priceType,
    this.priceCents,
    required this.fulfilmentModes,
    this.resOrArea,
    required this.imageUrls,
    this.contactWhatsApp,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  ServiceEntity copyWith({
    String? id,
    String? providerId,
    String? title,
    String? description,
    ServiceCategory? category,
    PriceType? priceType,
    int? priceCents,
    List<FulfilmentMode>? fulfilmentModes,
    String? resOrArea,
    List<String>? imageUrls,
    String? contactWhatsApp,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceEntity(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      priceType: priceType ?? this.priceType,
      priceCents: priceCents ?? this.priceCents,
      fulfilmentModes: fulfilmentModes ?? this.fulfilmentModes,
      resOrArea: resOrArea ?? this.resOrArea,
      imageUrls: imageUrls ?? this.imageUrls,
      contactWhatsApp: contactWhatsApp ?? this.contactWhatsApp,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        providerId,
        title,
        description,
        category,
        priceType,
        priceCents,
        fulfilmentModes,
        resOrArea,
        imageUrls,
        contactWhatsApp,
        isActive,
        createdAt,
        updatedAt,
      ];
}
