import 'package:flutter_test/flutter_test.dart';
import 'package:market/data/models/user_model.dart';
import 'package:market/domain/entities/user_entity.dart';

void main() {
  group('UserModel and UserEntity Unit Tests', () {

    test('should parse UserModel from JSON with full_name field', () {
      final json = {
        'id': 'user-100',
        'full_name': 'Jane Doe',
        'user_type': 'student',
        'has_free_trial': true,
        'sex': 'Female',
        'university': 'University of Cape Town',
        'profile_image_url': 'https://example.com/avatar.jpg',
        'is_verified': true,
        'is_profile_completed': true,
      };

      final model = UserModel.fromJson(json);

      expect(model.id, 'user-100');
      expect(model.name, 'Jane Doe');
      expect(model.userType, 'student');
      expect(model.hasFreeTrial, isTrue);
      expect(model.university, 'University of Cape Town');
      expect(model.isVerified, isTrue);
      expect(model.isProfileCompleted, isTrue);
    });

    test('should fallback to name field if full_name is missing', () {
      final json = {
        'id': 'user-101',
        'name': 'John Smith',
        'user_type': 'student',
        'has_free_trial': false,
        'sex': 'Male',
        'university': 'Wits',
        'profile_image_url': '',
      };

      final model = UserModel.fromJson(json);


      expect(model.id, 'user-101');
      expect(model.name, 'John Smith');
      expect(model.hasFreeTrial, isFalse);
      expect(model.isVerified, isFalse);
      expect(model.isProfileCompleted, isFalse);
    });



    test('should serialize UserModel to JSON', () {
      const model = UserModel(
        id: 'user-102',
        name: 'Alice Johnson',
        userType: 'student',
        hasFreeTrial: true,
        sex: 'Female',
        university: 'Stellenbosch',
        profileImageUrl: 'https://example.com/alice.jpg',
        isVerified: true,
        isProfileCompleted: true,
      );

      final json = model.toJson();

      expect(json['id'], 'user-102');
      expect(json['full_name'], 'Alice Johnson');
      expect(json['has_free_trial'], isTrue);
      expect(json['university'], 'Stellenbosch');
      expect(json['is_profile_completed'], isTrue);
    });

    test('UserEntity copyWith should return updated entity', () {
      const entity = UserEntity(
        id: 'user-103',
        name: 'Bob Brown',
        userType: 'student',
        hasFreeTrial: true,
        sex: 'Male',
        university: 'UCT',
        profileImageUrl: '',
        isVerified: false,
        isProfileCompleted: false,
      );

      final updated = entity.copyWith(
        hasFreeTrial: false,
        isProfileCompleted: true,
      );

      expect(updated.id, 'user-103');
      expect(updated.hasFreeTrial, isFalse);
      expect(updated.isProfileCompleted, isTrue);
      expect(updated.name, 'Bob Brown');

    });
  });
}
