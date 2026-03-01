import 'package:cloud_firestore/cloud_firestore.dart';

class LostItem {
  String id;
  String userId;
  String userName;
  String type; // "Lost" or "Found"
  String title;
  String category; // "Electronics", "Keys", etc.
  String description;
  String location;
  String imageUrl;
  String status; // "Active", "Claimed", "Returned"
  DateTime timestamp;
  String? claimerId; // Who is trying to claim it?

  LostItem({
    required this.id,
    required this.userId,
    required this.userName,
    required this.type,
    required this.title,
    required this.category,
    required this.description,
    required this.location,
    required this.imageUrl,
    required this.status,
    required this.timestamp,
    this.claimerId,
  });

  // Convert to Map for Firebase
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userName': userName,
      'type': type,
      'title': title,
      'category': category,
      'description': description,
      'location': location,
      'imageUrl': imageUrl,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      'claimerId': claimerId,
    };
  }

  // Create Object from Firebase Data
  factory LostItem.fromMap(Map<String, dynamic> map, String docId) {
    return LostItem(
      id: docId,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? 'Anonymous',
      type: map['type'] ?? 'Lost',
      title: map['title'] ?? '',
      category: map['category'] ?? 'General',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      status: map['status'] ?? 'Active',
      timestamp: (map['timestamp'] as Timestamp).toDate(),
      claimerId: map['claimerId'],
    );
  }
}
