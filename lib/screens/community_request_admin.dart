import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CommunityRequestCategory {
  const CommunityRequestCategory({
    required this.id,
    required this.name,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  static CommunityRequestCategory fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return CommunityRequestCategory(
      id: doc.id,
      name: (data['name'] as String? ?? '').trim(),
      isActive: (data['isActive'] as bool?) ?? true,
      createdAt: _parseDate(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(data['updatedAt']) ?? DateTime.now(),
    );
  }
}

class SupportRecoveryTicket {
  const SupportRecoveryTicket({
    required this.id,
    required this.subject,
    required this.issueType,
    required this.description,
    required this.requesterName,
    required this.requesterEmail,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.resolutionNote,
  });

  final String id;
  final String subject;
  final String issueType;
  final String description;
  final String requesterName;
  final String requesterEmail;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? resolutionNote;

  static SupportRecoveryTicket fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return SupportRecoveryTicket(
      id: doc.id,
      subject: (data['subject'] as String? ?? '').trim(),
      issueType: (data['issueType'] as String? ?? '').trim(),
      description: (data['description'] as String? ?? '').trim(),
      requesterName: (data['requesterName'] as String? ?? '').trim(),
      requesterEmail: (data['requesterEmail'] as String? ?? '').trim(),
      status: (data['status'] as String? ?? 'open').trim(),
      createdAt: _parseDate(data['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDate(data['updatedAt']) ?? DateTime.now(),
      resolutionNote: (data['resolutionNote'] as String?)?.trim(),
    );
  }
}

class ModerationRequestItem {
  const ModerationRequestItem({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    required this.requesterName,
    required this.createdAt,
    required this.moderationStatus,
    this.flagReason,
  });

  final String id;
  final String category;
  final String title;
  final String description;
  final String requesterName;
  final DateTime createdAt;
  final String moderationStatus;
  final String? flagReason;

  static ModerationRequestItem fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    return ModerationRequestItem(
      id: doc.id,
      category: (data['category'] as String? ?? '').trim(),
      title: (data['title'] as String? ?? '').trim(),
      description: (data['description'] as String? ?? '').trim(),
      requesterName: (data['requesterName'] as String? ?? 'Unknown').trim(),
      createdAt: _parseDate(data['createdAt']) ?? DateTime.now(),
      moderationStatus: (data['moderationStatus'] as String? ?? 'active').trim(),
      flagReason: (data['moderationReason'] as String?)?.trim(),
    );
  }
}

class CommunityRequestsAdminService {
  CommunityRequestsAdminService._();

  static final CommunityRequestsAdminService instance =
      CommunityRequestsAdminService._();

  static const String _categoriesCollection = 'community_request_categories';
  static const String _ticketsCollection = 'support_recovery_tickets';
  static const String _requestsCollection = 'help_requests';

  static const List<String> defaultRequestTypes = <String>[
    'Resource Sharing',
    'Study Support',
    'Safety Transport',
    'Tech Support',
    'Canteen Runner',
    'Campus Logistics & Moving',
    'Cash Exchange',
  ];

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<CommunityRequestCategory>> watchAllCategories() {
    return _firestore
        .collection(_categoriesCollection)
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map(CommunityRequestCategory.fromDoc).toList());
  }

  Stream<List<CommunityRequestCategory>> watchActiveCategories() {
    return _firestore
        .collection(_categoriesCollection)
        .where('isActive', isEqualTo: true)
        .orderBy('name')
        .snapshots()
        .map((snap) => snap.docs.map(CommunityRequestCategory.fromDoc).toList());
  }

  Future<void> addCategory(String name) async {
    final clean = name.trim();
    if (clean.isEmpty) return;
    final now = FieldValue.serverTimestamp();
    await _firestore.collection(_categoriesCollection).add({
      'name': clean,
      'isActive': true,
      'createdAt': now,
      'updatedAt': now,
      'createdBy': _auth.currentUser?.uid,
    });
  }

  Future<void> ensureDefaultCategories() async {
    final snapshot = await _firestore.collection(_categoriesCollection).get();
    final existing = snapshot.docs
        .map((d) => (d.data()['name'] as String? ?? '').trim().toLowerCase())
        .where((n) => n.isNotEmpty)
        .toSet();

    final now = FieldValue.serverTimestamp();
    final batch = _firestore.batch();
    var hasWrites = false;

    for (final name in defaultRequestTypes) {
      if (existing.contains(name.toLowerCase())) continue;
      final ref = _firestore.collection(_categoriesCollection).doc();
      batch.set(ref, {
        'name': name,
        'isActive': true,
        'createdAt': now,
        'updatedAt': now,
        'createdBy': _auth.currentUser?.uid,
      });
      hasWrites = true;
    }

    if (hasWrites) {
      await batch.commit();
    }
  }

  Future<void> updateCategory({
    required String id,
    required String name,
    required bool isActive,
  }) async {
    final clean = name.trim();
    if (clean.isEmpty) return;
    await _firestore.collection(_categoriesCollection).doc(id).update({
      'name': clean,
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _auth.currentUser?.uid,
    });
  }

  Future<void> deleteCategory(String id) async {
    await _firestore.collection(_categoriesCollection).doc(id).delete();
  }

  Stream<List<SupportRecoveryTicket>> watchTickets() {
    return _firestore
        .collection(_ticketsCollection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map(SupportRecoveryTicket.fromDoc).toList());
  }

  Future<void> createTicket({
    required String subject,
    required String issueType,
    required String description,
    required String requesterName,
    required String requesterEmail,
  }) async {
    final now = FieldValue.serverTimestamp();
    await _firestore.collection(_ticketsCollection).add({
      'subject': subject.trim(),
      'issueType': issueType.trim(),
      'description': description.trim(),
      'requesterName': requesterName.trim(),
      'requesterEmail': requesterEmail.trim(),
      'status': 'open',
      'createdAt': now,
      'updatedAt': now,
      'createdBy': _auth.currentUser?.uid,
    });
  }

  Future<void> updateTicketStatus({
    required String id,
    required String status,
    String? resolutionNote,
  }) async {
    await _firestore.collection(_ticketsCollection).doc(id).update({
      'status': status,
      'resolutionNote': resolutionNote?.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'updatedBy': _auth.currentUser?.uid,
    });
  }

  Stream<List<ModerationRequestItem>> watchRequestsForModeration() {
    return _firestore
        .collection(_requestsCollection)
        .orderBy('createdAt', descending: true)
        .limit(200)
        .snapshots()
        .map((snap) => snap.docs.map(ModerationRequestItem.fromDoc).toList());
  }

  Future<void> flagRequest({
    required String requestId,
    required String reason,
  }) async {
    await _firestore.collection(_requestsCollection).doc(requestId).update({
      'moderationStatus': 'flagged',
      'moderationReason': reason.trim(),
      'moderatedAt': FieldValue.serverTimestamp(),
      'moderatedBy': _auth.currentUser?.uid,
    });
  }

  Future<void> unflagRequest(String requestId) async {
    await _firestore.collection(_requestsCollection).doc(requestId).update({
      'moderationStatus': 'active',
      'moderationReason': null,
      'moderatedAt': FieldValue.serverTimestamp(),
      'moderatedBy': _auth.currentUser?.uid,
    });
  }

  Future<void> deleteRequest(String requestId) async {
    await _firestore.collection(_requestsCollection).doc(requestId).delete();
  }
}

DateTime? _parseDate(Object? value) {
  if (value is Timestamp) return value.toDate();
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
  return null;
}
