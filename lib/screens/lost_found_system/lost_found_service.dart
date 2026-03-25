import 'dart:io';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'lost_item_model.dart';

class LostFoundService {
  static const String _col = 'lost_found_posts';

  final FirebaseFirestore _db = FirebaseFirestore.instance;

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
    try {
      String? base64Image;

      if (imageFile != null) {
        final bytes = await imageFile.readAsBytes();
        base64Image = base64Encode(bytes);

        print('Current String Length: ${base64Image.length}');

        if (base64Image.length > 800000) {
          print('❌ Image too big for Firestore!');
          throw Exception(
            'Image too big for Firestore. Please choose a smaller/compressed image.',
          );
        }
      }

      final data = item.toMap();

      if (base64Image != null && base64Image.isNotEmpty) {
        data['image_data'] = base64Image;
      }

      data['timestamp'] = FieldValue.serverTimestamp();

      await _db.collection(_col).add(data);
    } catch (e) {
      print('ERROR uploading post: $e');
      rethrow;
    }
  }

  Future<void> updatePostBasic({
    required String itemId,
    required String title,
    required String category,
    required String description,
    required String location,
  }) async {
    await _db.collection(_col).doc(itemId).update({
      'title': title.trim(),
      'category': category.trim(),
      'description': description.trim(),
      'location': location.trim(),
    });
  }

  Future<void> deletePost(String itemId) async {
    final doc = await _db.collection(_col).doc(itemId).get();
    if (!doc.exists) return;

    final data = doc.data();

    final messages = await _db
        .collection(_col)
        .doc(itemId)
        .collection('messages')
        .get();

    for (final m in messages.docs) {
      await m.reference.delete();
    }

    await _db.collection(_col).doc(itemId).delete();
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
