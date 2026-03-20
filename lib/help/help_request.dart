import 'package:cloud_firestore/cloud_firestore.dart';

class HelpRequest {
  final String id;
  final String category;
  /// Display name of the person posting the request (shown on the form & feed).
  final String requesterName;
  final String title;
  final String description;
  final String locationName;
  final double? lat;
  final double? lng;
  final bool isUrgent;
  final bool isMine;
  final DateTime createdAt;
  /// When the requester needs help (date + time from the form).
  final DateTime neededAt;
  final String? creatorUid;
  final Map<String, dynamic>? helperPreferences;

  const HelpRequest({
    required this.id,
    required this.category,
    required this.requesterName,
    required this.title,
    required this.description,
    required this.locationName,
    required this.lat,
    required this.lng,
    required this.isUrgent,
    required this.isMine,
    required this.createdAt,
    required this.neededAt,
    this.creatorUid,
    this.helperPreferences,
  });

  Map<String, dynamic> toMap() {
    final m = <String, dynamic>{
      'category': category,
      'requesterName': requesterName,
      'title': title,
      'description': description,
      'locationName': locationName,
      'lat': lat,
      'lng': lng,
      'isUrgent': isUrgent,
      'creatorUid': creatorUid,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'neededAt': neededAt.millisecondsSinceEpoch,
    };
    if (helperPreferences != null && helperPreferences!.isNotEmpty) {
      m['helperPreferences'] = helperPreferences;
    }
    return m;
  }

  static HelpRequest fromMap(String id, Map<String, dynamic> data, String? currentUid) {
    final createdAt = data['createdAt'] is int
        ? DateTime.fromMillisecondsSinceEpoch(data['createdAt'] as int)
        : DateTime.now();
    final creatorUid = data['creatorUid'] as String?;
    Map<String, dynamic>? prefs;
    final raw = data['helperPreferences'];
    if (raw is Map) {
      prefs = Map<String, dynamic>.from(raw);
    }

    final requesterName = (data['requesterName'] as String?)?.trim() ?? '';

    DateTime neededAt;
    final na = data['neededAt'];
    if (na is Timestamp) {
      neededAt = na.toDate();
    } else if (na is int) {
      neededAt = DateTime.fromMillisecondsSinceEpoch(na);
    } else {
      neededAt = createdAt;
    }

    return HelpRequest(
      id: id,
      category: (data['category'] ?? '') as String,
      requesterName: requesterName,
      title: (data['title'] ?? '') as String,
      description: (data['description'] ?? '') as String,
      locationName: (data['locationName'] ?? '') as String,
      lat: (data['lat'] as num?)?.toDouble(),
      lng: (data['lng'] as num?)?.toDouble(),
      isUrgent: (data['isUrgent'] ?? false) as bool,
      isMine: currentUid != null && creatorUid == currentUid,
      createdAt: createdAt,
      neededAt: neededAt,
      creatorUid: creatorUid,
      helperPreferences: prefs,
    );
  }
}

