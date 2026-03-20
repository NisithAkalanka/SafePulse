import 'package:flutter/foundation.dart';
import 'help_request.dart';

class HelpRequestsStore {
  HelpRequestsStore._();

  static final HelpRequestsStore instance = HelpRequestsStore._();

  final ValueNotifier<List<HelpRequest>> requests = ValueNotifier<List<HelpRequest>>([
    HelpRequest(
      id: 'seed-1',
      category: 'Study Support',
      requesterName: 'Alex P.',
      title: 'Need help preparing for exam',
      description: 'Need help preparing for exam',
      locationName: 'Main Library',
      lat: 6.9148,
      lng: 79.9720,
      isUrgent: true,
      isMine: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 2)),
      neededAt: DateTime.now().add(const Duration(hours: 2)),
    ),
    HelpRequest(
      id: 'seed-2',
      category: 'Study Support',
      requesterName: 'Sam K.',
      title: 'Preparation for exam',
      description: 'Preparation for exam',
      locationName: 'Engineering Block',
      lat: 6.9155,
      lng: 79.9712,
      isUrgent: false,
      isMine: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      neededAt: DateTime.now().add(const Duration(hours: 5)),
    ),
    HelpRequest(
      id: 'seed-3',
      category: 'Safety Transport',
      requesterName: 'Jordan M.',
      title: 'Safe ride to dormitory',
      description: 'Need a safe ride to dormitory',
      locationName: 'North Gate',
      lat: 6.9162,
      lng: 79.9734,
      isUrgent: true,
      isMine: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      neededAt: DateTime.now().add(const Duration(minutes: 30)),
    ),
    HelpRequest(
      id: 'seed-4',
      category: 'Tech Support',
      requesterName: 'Riley T.',
      title: 'Fix laptop',
      description: 'Laptop issue, need help',
      locationName: 'Lab 3, Tech Center',
      lat: 6.9139,
      lng: 79.9740,
      isUrgent: false,
      isMine: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 15)),
      neededAt: DateTime.now().add(const Duration(days: 1, hours: 3)),
    ),
    HelpRequest(
      id: 'seed-5',
      category: 'Cash Exchange',
      requesterName: 'You',
      title: 'Need to exchange 10\$ to coins',
      description: 'Need to exchange 10\$ to coins',
      locationName: 'Cafeteria',
      lat: 6.9141,
      lng: 79.9750,
      isUrgent: false,
      isMine: true,
      createdAt: DateTime.now().subtract(const Duration(minutes: 20)),
      neededAt: DateTime.now().add(const Duration(hours: 1)),
    ),
  ]);

  void add(HelpRequest request) {
    requests.value = [request, ...requests.value];
  }

  /// Replace list with Firestore data (used by HelpRequestService).
  void setFromFirestore(List<HelpRequest> list) {
    requests.value = list;
  }
}

