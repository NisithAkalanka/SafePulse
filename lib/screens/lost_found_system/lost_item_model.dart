import 'package:cloud_firestore/cloud_firestore.dart';

class LostItem {
  String id;
  String userId;
  String userName;
  String type; // "Lost" or "Found"
  String title;
  String category;
  String description;
  String location;
  String imageUrl;
  String status;
  DateTime timestamp;

  String? requesterId;
  String? requesterName;
  String? requestType; // "found" or "claim"
  String? verificationQuestion;
  String? verificationAnswer;
  bool chatEnabled;
  DateTime? returnedAt;

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
    this.requesterId,
    this.requesterName,
    this.requestType,
    this.verificationQuestion,
    this.verificationAnswer,
    this.chatEnabled = false,
    this.returnedAt,
  });

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
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requestType': requestType,
      'verificationQuestion': verificationQuestion,
      'verificationAnswer': verificationAnswer,
      'chatEnabled': chatEnabled,
      'returnedAt': returnedAt == null ? null : Timestamp.fromDate(returnedAt!),
    };
  }

  factory LostItem.fromMap(Map<String, dynamic> map, String docId) {
    DateTime safeTime = DateTime.now();
    final ts = map['timestamp'];
    if (ts is Timestamp) {
      safeTime = ts.toDate();
    } else if (ts is DateTime) {
      safeTime = ts;
    }

    DateTime? safeReturnedAt;
    final rt = map['returnedAt'];
    if (rt is Timestamp) {
      safeReturnedAt = rt.toDate();
    } else if (rt is DateTime) {
      safeReturnedAt = rt;
    }

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
      timestamp: safeTime,
      requesterId: map['requesterId'],
      requesterName: map['requesterName'],
      requestType: map['requestType'],
      verificationQuestion: map['verificationQuestion'],
      verificationAnswer: map['verificationAnswer'],
      chatEnabled: map['chatEnabled'] ?? false,
      returnedAt: safeReturnedAt,
    );
  }
}
