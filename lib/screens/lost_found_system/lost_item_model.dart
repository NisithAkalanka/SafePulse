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
  String? imageData;
  String status;
  DateTime timestamp;

  String? firstName;
  String? lastName;
  DateTime? reportedDateTime;

  String? requesterId;
  String? requesterName;
  String? requestType; // "found" or "claim" or "chat_request"
  String? verificationQuestion;
  String? verificationAnswer;
  bool chatEnabled;
  DateTime? returnedAt;

  bool ownerChatAccepted;
  bool requesterChatAccepted;

  String? ownerRetryMessage;
  int ownerRetryCount;

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
    this.firstName,
    this.lastName,
    this.reportedDateTime,
    this.requesterId,
    this.requesterName,
    this.requestType,
    this.verificationQuestion,
    this.verificationAnswer,
    this.chatEnabled = false,
    this.returnedAt,
    this.imageData,
    this.ownerChatAccepted = false,
    this.requesterChatAccepted = false,
    this.ownerRetryMessage,
    this.ownerRetryCount = 0,
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
      'image_data': imageData,
      'status': status,
      'timestamp': Timestamp.fromDate(timestamp),
      'firstName': firstName,
      'lastName': lastName,
      'reportedDateTime': reportedDateTime == null
          ? null
          : Timestamp.fromDate(reportedDateTime!),
      'requesterId': requesterId,
      'requesterName': requesterName,
      'requestType': requestType,
      'verificationQuestion': verificationQuestion,
      'verificationAnswer': verificationAnswer,
      'chatEnabled': chatEnabled,
      'returnedAt': returnedAt == null ? null : Timestamp.fromDate(returnedAt!),
      'ownerChatAccepted': ownerChatAccepted,
      'requesterChatAccepted': requesterChatAccepted,
      'ownerRetryMessage': ownerRetryMessage,
      'ownerRetryCount': ownerRetryCount,
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

    DateTime? safeReportedDateTime;
    final rdt = map['reportedDateTime'];
    if (rdt is Timestamp) {
      safeReportedDateTime = rdt.toDate();
    } else if (rdt is DateTime) {
      safeReportedDateTime = rdt;
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
      imageData: map['image_data'],
      status: map['status'] ?? 'Active',
      timestamp: safeTime,
      firstName: map['firstName'],
      lastName: map['lastName'],
      reportedDateTime: safeReportedDateTime,
      requesterId: map['requesterId'],
      requesterName: map['requesterName'],
      requestType: map['requestType'],
      verificationQuestion: map['verificationQuestion'],
      verificationAnswer: map['verificationAnswer'],
      chatEnabled: map['chatEnabled'] ?? false,
      returnedAt: safeReturnedAt,
      ownerChatAccepted: map['ownerChatAccepted'] ?? false,
      requesterChatAccepted: map['requesterChatAccepted'] ?? false,
      ownerRetryMessage: map['ownerRetryMessage'],
      ownerRetryCount: map['ownerRetryCount'] ?? 0,
    );
  }
}
