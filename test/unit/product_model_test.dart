import 'package:flutter_test/flutter_test.dart';
import 'package:market/data/models/product_model.dart';
import 'package:market/domain/entities/product_entity.dart';

void main() {
  group('ProductModel and ProductEntity Unit Tests', () {
    final now = DateTime.parse('2026-10-09T12:00:00.000Z');

    test('should correctly parse standard JSON with List image_urls', () {
      final json = {
        'id': 'prod-123',
        'name': 'Textbook',
        'description': 'Calculus 10th edition',
        'price': 250.0,
        'category': 'Books',
        'university': 'UCT',
        'image_urls': ['https://example.com/img1.jpg', 'https://example.com/img2.jpg'],
        'seller_id': 'user-789',
        'status': 'active',
        'created_at': '2026-10-09T12:00:00.000Z',
      };

      final result = ProductModel.fromJson(json);

      expect(result.id, 'prod-123');
      expect(result.name, 'Textbook');
      expect(result.price, 250.0);
      expect(result.imageUrls, ['https://example.com/img1.jpg', 'https://example.com/img2.jpg']);
      expect(result.createdAt, now);
    });

    test('Should correctly parse integer price into double', () {
      final json = {
        'id': 'prod-124',
        'name': 'Desk Lamp',
        'description': 'LED Desk Lamp',
        'price': 150, // integer from database
        'category': 'Room',
        'university': 'UCT',
        'image_urls': [],
        'seller_id': 'user-789',
        'status': 'active',
        'created_at': '2026-10-09T12:00:00.000Z',
      };

      final result = ProductModel.fromJson(json);

      expect(result.price, 150.0);
      expect(result.price, isA<double>());
    });

    test('Should correctly parse Postgres array string "{url1,url2}"', () {

      final json = {
        'id': 'prod-125',
        'name': 'Laptop',
        'description': 'MacBook Air',
        'price': 8500.0,
        'category': 'Electronics',
        'university': 'UCT',
        'image_urls': '{"https://example.com/img1.jpg","https://example.com/img2.jpg"}',
        'seller_id': 'user-789',
        'status': 'active',
        'created_at': '2026-10-09T12:00:00.000Z',
      };

      final result = ProductModel.fromJson(json);

      expect(result.imageUrls, ['https://example.com/img1.jpg', 'https://example.com/img2.jpg']);
    });



    test('should correctly parse stringi fied JSON array "["url1"]"', () {
      final json = {
        'id': 'prod-126',
        'name': 'Kettle',
        'description': 'Electric kettle',
        'price': 180.0,
        'category': 'Kitchen',
        'university': 'UCT',
        'image_urls': '["https://example.com/kettle.jpg"]',
        'seller_id': 'user-789',
        'status': 'active',
        'created_at': '2026-10-09T12:00:00.000Z',
      };

      final result = ProductModel.fromJson(json);

      expect(result.imageUrls, ['https://example.com/kettle.jpg']);
    });

    test('should handle missing or null image_urls gracefully', () {
      final json = {
        'id': 'prod-127',
        'name': 'Chair',
        'description': 'Study chair',
        'price': 300.0,
        'category': 'Room',
        'university': 'UCT',
        'image_urls': null,
        'seller_id': 'user-789',
        'status': 'active',
      };


      final result = ProductModel.fromJson(json);

      expect(result.imageUrls, isEmpty);
    });



    test('should serialize ProductModel to valid JSON map', () {
      final model = ProductModel(
        id: 'prod-200',
        name: 'Headphones',
        description: 'Noise cancelling',
        price: 1200.0,
        category: 'Electronics',
        university: 'UCT',
        imageUrls: const ['https://example.com/hp.jpg'],
        sellerId: 'user-789',
        status: 'active',
        createdAt: now,
      );

      final json = model.toJson();

      expect(json['id'], 'prod-200');
      expect(json['name'], 'Headphones');
      expect(json['price'], 1200.0);
      expect(json['image_urls'], ['https://example.com/hp.jpg']);
      expect(json['created_at'], '2026-10-09T12:00:00.000Z');
    });

    test('ProductEntity copyWith should correctly produce updated instance', () {

      final entity = ProductEntity(
        id: 'prod-300',
        name: 'Original Title',
        description: 'Desc',
        price: 100.0,
        category: 'Books',
        university: 'UCT',
        imageUrls: const [],
        sellerId: 'user-1',
        status: 'pending_payment',
        createdAt: now,
      );

      final updated = entity.copyWith(
        price: 150.0,
        status: 'active',
      );

      expect(updated.id, 'prod-300');
      expect(updated.name, 'Original Title');
      expect(updated.price, 150.0);
      expect(updated.status, 'active');
    });
  });
}
