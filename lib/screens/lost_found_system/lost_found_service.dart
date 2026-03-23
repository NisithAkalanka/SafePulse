import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'lost_item_model.dart';

class LostFoundService {
  static const String _col = 'lost_found_posts';

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Stream<List<LostItem>> getItemsStream(String type) {
    _cleanupReturnedItems();
    return _db.collection(_col).where('type', isEqualTo: type).snapshots().map((
      snap,
    ) {
      final items = snap.docs
          .map((d) => LostItem.fromMap(d.data(), d.id))
          .where((item) {
            if (item.status != 'Returned') return true;
            if (item.returnedAt == null) return true;
            return DateTime.now().difference(item.returnedAt!).inMinutes < 60;
          })
          .toList();

      items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return items;
    });
  }

  Future<void> _cleanupReturnedItems() async {
    final snap = await _db
        .collection(_col)
        .where('status', isEqualTo: 'Returned')
        .get();

    for (final doc in snap.docs) {
      final data = doc.data();
      final rt = data['returnedAt'];
      DateTime? returnedAt;
      if (rt is Timestamp) returnedAt = rt.toDate();

      if (returnedAt != null &&
          DateTime.now().difference(returnedAt).inMinutes >= 60) {
        await doc.reference.delete();
      }
    }
  }

  Future<void> createPost(LostItem item, File? imageFile) async {
    String imageUrl = '';

    if (imageFile != null) {
      final fileName =
          'lost_found/${DateTime.now().millisecondsSinceEpoch}_${item.userId}.jpg';

      final ref = _storage.ref().child(fileName);
      await ref.putFile(imageFile);
      imageUrl = await ref.getDownloadURL();
    }

    final data = item.toMap();
    data['imageUrl'] = imageUrl;
    data['timestamp'] = FieldValue.serverTimestamp();

    await _db.collection(_col).add(data);
  }

  Future<void> submitFoundReport({
    required String itemId,
    required String requesterId,
    required String requesterName,
    required String question,
  }) async {
    await _db.collection(_col).doc(itemId).update({
      'status': 'Verification Pending',
      'requestType': 'found',
      'requesterId': requesterId,
      'requesterName': requesterName,
      'verificationQuestion': question,
      'verificationAnswer': null,
      'chatEnabled': false,
    });
  }

  Future<void> submitOwnerAnswer({
    required String itemId,
    required String answer,
  }) async {
    await _db.collection(_col).doc(itemId).update({
      'status': 'Answer Submitted',
      'verificationAnswer': answer,
    });
  }

  Future<void> submitClaimRequest({
    required String itemId,
    required String requesterId,
    required String requesterName,
    required String proofAnswer,
  }) async {
    await _db.collection(_col).doc(itemId).update({
      'status': 'Claim Pending',
      'requestType': 'claim',
      'requesterId': requesterId,
      'requesterName': requesterName,
      'verificationQuestion': 'Describe any special marks or unique details.',
      'verificationAnswer': proofAnswer,
      'chatEnabled': false,
    });
  }

  Future<String> getVerificationAnswer(String itemId) async {
    final ds = await _db.collection(_col).doc(itemId).get();
    if (!ds.exists) return "No details provided.";
    final data = ds.data();
    return (data?['verificationAnswer'] as String?) ?? "No details provided.";
  }

  Future<String> getVerificationQuestion(String itemId) async {
    final ds = await _db.collection(_col).doc(itemId).get();
    if (!ds.exists) return "No question provided.";
    final data = ds.data();
    return (data?['verificationQuestion'] as String?) ??
        "No question provided.";
  }

  Future<void> enablePrivateChat(String itemId) async {
    await _db.collection(_col).doc(itemId).update({
      'status': 'Chat Enabled',
      'chatEnabled': true,
    });
  }

  Future<void> rejectRequest(String itemId) async {
    await _db.collection(_col).doc(itemId).update({
      'status': 'Active',
      'requestType': null,
      'requesterId': null,
      'requesterName': null,
      'verificationQuestion': null,
      'verificationAnswer': null,
      'chatEnabled': false,
    });
  }

  Future<void> markAsReturned(String itemId) async {
    await _db.collection(_col).doc(itemId).update({
      'status': 'Returned',
      'returnedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> getMessagesStream(String itemId) {
    return _db
        .collection(_col)
        .doc(itemId)
        .collection('messages')
        .orderBy('timestamp')
        .snapshots();
  }

  Future<void> sendMessage({
    required String itemId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    await _db.collection(_col).doc(itemId).collection('messages').add({
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }
}
