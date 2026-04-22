// Student ID: IT23600966
// Evidence for Testing Tool Usage - SafePulse Lost & Found Module

import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../lib/screens/lost_found_system/lost_found_rating_service.dart';
import '../lib/screens/lost_found_system/lost_item_model.dart';

void main() {
  group('LostFoundRatingService Logic Tests', () {
    test('Should return empty badge when count is 0', () {
      final result = LostFoundRatingService.badgeLabel(4.8, 0);
      expect(result, '');
    });

    test('Should return Gold badge for average rating 4.5 or above', () {
      final result = LostFoundRatingService.badgeLabel(4.7, 10);
      expect(result, 'Gold');
    });

    test(
      'Should return Silver badge for average rating 3.0 or above and below 4.5',
      () {
        final result = LostFoundRatingService.badgeLabel(3.8, 5);
        expect(result, 'Silver');
      },
    );

    test(
      'Should return Bronze badge for average rating below 3.0 when count is more than 0',
      () {
        final result = LostFoundRatingService.badgeLabel(2.5, 4);
        expect(result, 'Bronze');
      },
    );

    test('Should return correct color for Gold badge', () {
      final result = LostFoundRatingService.badgeColor('Gold');
      expect(result, 0xFFFFD700);
    });

    test('Should return correct color for Silver badge', () {
      final result = LostFoundRatingService.badgeColor('Silver');
      expect(result, 0xFFB0BEC5);
    });

    test('Should return correct color for Bronze badge', () {
      final result = LostFoundRatingService.badgeColor('Bronze');
      expect(result, 0xFFCD7F32);
    });

    test('Should return default color for unknown badge', () {
      final result = LostFoundRatingService.badgeColor('Unknown');
      expect(result, 0xFFB0BEC5);
    });
  });

  group('LostItem Model Tests', () {
    test('Should convert LostItem to map correctly', () {
      final item = LostItem(
        id: 'item123',
        userId: 'user001',
        userName: 'Nisith',
        type: 'Lost',
        title: 'Wallet',
        category: 'Others',
        description: 'Black wallet near library',
        location: 'Library',
        imageUrl: '',
        status: 'Active',
        timestamp: DateTime(2026, 4, 22, 10, 30),
        firstName: 'Nisith',
        lastName: 'Akalanka',
        chatEnabled: false,
      );

      final map = item.toMap();

      expect(map['userId'], 'user001');
      expect(map['userName'], 'Nisith');
      expect(map['type'], 'Lost');
      expect(map['title'], 'Wallet');
      expect(map['category'], 'Others');
      expect(map['description'], 'Black wallet near library');
      expect(map['location'], 'Library');
      expect(map['status'], 'Active');
      expect(map['firstName'], 'Nisith');
      expect(map['lastName'], 'Akalanka');
      expect(map['chatEnabled'], false);
      expect(map['timestamp'], isA<Timestamp>());
    });

    test('Should create LostItem from map correctly', () {
      final map = {
        'userId': 'user002',
        'userName': 'Amal',
        'type': 'Found',
        'title': 'Phone',
        'category': 'Electronics',
        'description': 'Found near canteen',
        'location': 'Canteen',
        'imageUrl': '',
        'status': 'Returned',
        'timestamp': Timestamp.fromDate(DateTime(2026, 4, 22, 9, 0)),
        'firstName': 'Amal',
        'lastName': 'Perera',
        'chatEnabled': true,
        'ownerChatAccepted': true,
        'requesterChatAccepted': true,
        'ownerRetryCount': 1,
        'ownerMarkedReceived': true,
        'requesterMarkedReturned': true,
      };

      final item = LostItem.fromMap(map, 'doc001');

      expect(item.id, 'doc001');
      expect(item.userId, 'user002');
      expect(item.userName, 'Amal');
      expect(item.type, 'Found');
      expect(item.title, 'Phone');
      expect(item.category, 'Electronics');
      expect(item.description, 'Found near canteen');
      expect(item.location, 'Canteen');
      expect(item.status, 'Returned');
      expect(item.firstName, 'Amal');
      expect(item.lastName, 'Perera');
      expect(item.chatEnabled, true);
      expect(item.ownerChatAccepted, true);
      expect(item.requesterChatAccepted, true);
      expect(item.ownerRetryCount, 1);
      expect(item.ownerMarkedReceived, true);
      expect(item.requesterMarkedReturned, true);
    });

    test('Should assign safe default values when fields are missing', () {
      final map = <String, dynamic>{};

      final item = LostItem.fromMap(map, 'doc002');

      expect(item.id, 'doc002');
      expect(item.userId, '');
      expect(item.userName, 'Anonymous');
      expect(item.type, 'Lost');
      expect(item.title, '');
      expect(item.category, 'General');
      expect(item.description, '');
      expect(item.location, '');
      expect(item.imageUrl, '');
      expect(item.status, 'Active');
      expect(item.chatEnabled, false);
      expect(item.ownerChatAccepted, false);
      expect(item.requesterChatAccepted, false);
      expect(item.ownerRetryCount, 0);
      expect(item.ownerMarkedReceived, false);
      expect(item.requesterMarkedReturned, false);
    });

    test(
      'Should correctly parse returnedAt and reportedDateTime timestamps',
      () {
        final map = {
          'userId': 'user003',
          'userName': 'Kamal',
          'type': 'Lost',
          'title': 'Bag',
          'category': 'Books',
          'description': 'Blue bag',
          'location': 'Main Gate',
          'imageUrl': '',
          'status': 'Returned',
          'timestamp': Timestamp.fromDate(DateTime(2026, 4, 22, 8, 0)),
          'returnedAt': Timestamp.fromDate(DateTime(2026, 4, 22, 11, 0)),
          'reportedDateTime': Timestamp.fromDate(DateTime(2026, 4, 22, 7, 45)),
        };

        final item = LostItem.fromMap(map, 'doc003');

        expect(item.returnedAt, DateTime(2026, 4, 22, 11, 0));
        expect(item.reportedDateTime, DateTime(2026, 4, 22, 7, 45));
      },
    );
  });
}
