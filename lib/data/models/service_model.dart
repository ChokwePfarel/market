import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../domain/entities/service_entity.dart';

class ServiceModel extends ServiceEntity {
  const ServiceModel({
    required super.id,
    required super.providerId,
    required super.title,
    required super.description,
    required super.category,
    required super.priceType,
    super.priceCents,
    required super.fulfilmentModes,
    super.resOrArea,
    required super.imageUrls,
    super.contactWhatsApp,
    required super.isActive,
    required super.createdAt,
    required super.updatedAt,
  });

  factory ServiceModel.fromJson(Map<String, dynamic> json) {
    // Parse image urls
    List<String> parsedUrls = [];
    try {
      final rawUrls = json['image_urls'] ?? json['image_url'];
      if (rawUrls != null) {
        if (rawUrls is List) {
          parsedUrls = rawUrls.where((e) => e != null).map((e) => e.toString()).toList();
        } else if (rawUrls is String) {
          final trimmed = rawUrls.trim();
          if (trimmed.startsWith('[') && trimmed.endsWith(']')) {
            final List decoded = jsonDecode(trimmed);
            parsedUrls = decoded.map((e) => e.toString()).toList();
          } else if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
            String content = trimmed.substring(1, trimmed.length - 1);
            parsedUrls = content.split(',').map((s) => s.trim().replaceAll('"', '')).where((s) => s.isNotEmpty).toList();
          } else if (trimmed.isNotEmpty) {
            parsedUrls = [trimmed];
          }
        }
      }
    } catch (e) {
      debugPrint('ServiceModel: Error parsing image_urls: $e');
    }

    // Parse fulfilment modes list
    List<FulfilmentMode> parsedModes = [];
    try {
      final rawModes = json['fulfilment_modes'];
      if (rawModes is List) {
        parsedModes = rawModes.map((m) => _parseFulfilmentMode(m.toString())).toList();
      } else if (rawModes is String) {
        // Handle postgres array or string
        final clean = rawModes.replaceAll('{', '').replaceAll('}', '').replaceAll('"', '');
        parsedModes = clean.split(',').map((s) => _parseFulfilmentMode(s.trim())).toList();
      }
    } catch (e) {
      debugPrint('ServiceModel: Error parsing fulfilment_modes: $e');
    }

    return ServiceModel(
      id: json['id'] ?? '',
      providerId: json['provider_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: _parseCategory(json['category']),
      priceType: _parsePriceType(json['price_type']),
      priceCents: json['price_cents'] != null ? (json['price_cents'] as num).toInt() : null,
      fulfilmentModes: parsedModes,
      resOrArea: json['res_or_area'],
      imageUrls: parsedUrls,
      contactWhatsApp: json['contact_whatsapp'],
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'provider_id': providerId,
      'title': title,
      'description': description,
      'category': categoryToString(category),
      'price_type': _priceTypeToString(priceType),
      'price_cents': priceCents,
      'fulfilment_modes': fulfilmentModes.map((m) => _fulfilmentModeToString(m)).toList(),
      'res_or_area': resOrArea,
      'image_urls': imageUrls,
      'contact_whatsapp': contactWhatsApp,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  static ServiceCategory _parseCategory(String? val) {
    switch (val?.toLowerCase()) {
      case 'shoe_cleaning':
      case 'shoecleaning':
        return ServiceCategory.shoeCleaning;
      case 'phone_repair':
      case 'phonerepair':
        return ServiceCategory.phoneRepair;
      case 'delivery':
        return ServiceCategory.delivery;
      case 'hair_and_beauty':
      case 'hairandbeauty':
        return ServiceCategory.hairAndBeauty;
      default:
        return ServiceCategory.other;
    }
  }

  static String categoryToString(ServiceCategory cat) {
    switch (cat) {
      case ServiceCategory.shoeCleaning:
        return 'shoe_cleaning';
      case ServiceCategory.phoneRepair:
        return 'phone_repair';
      case ServiceCategory.delivery:
        return 'delivery';
      case ServiceCategory.hairAndBeauty:
        return 'hair_and_beauty';
      case ServiceCategory.other:
        return 'other';
    }
  }

  static PriceType _parsePriceType(String? val) {
    switch (val?.toLowerCase()) {
      case 'starting_from':
      case 'startingfrom':
        return PriceType.startingFrom;
      case 'quote':
        return PriceType.quote;
      default:
        return PriceType.fixed;
    }
  }

  static String _priceTypeToString(PriceType type) {
    switch (type) {
      case PriceType.fixed:
        return 'fixed';
      case PriceType.startingFrom:
        return 'starting_from';
      case PriceType.quote:
        return 'quote';
    }
  }

  static FulfilmentMode _parseFulfilmentMode(String? val) {
    switch (val?.toLowerCase()) {
      case 'at_provider':
      case 'atprovider':
        return FulfilmentMode.atProvider;
      case 'comes_to_you':
      case 'comestoyou':
        return FulfilmentMode.comesToYou;
      case 'pickup_and_dropoff':
      case 'pickupanddropoff':
        return FulfilmentMode.pickupAndDropoff;
      default:
        return FulfilmentMode.campusDelivery;
    }
  }

  static String _fulfilmentModeToString(FulfilmentMode mode) {
    switch (mode) {
      case FulfilmentMode.atProvider:
        return 'at_provider';
      case FulfilmentMode.comesToYou:
        return 'comes_to_you';
      case FulfilmentMode.pickupAndDropoff:
        return 'pickup_and_dropoff';
      case FulfilmentMode.campusDelivery:
        return 'campus_delivery';
    }
  }
}
