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
      final rt = doc.data()['returnedAt'];
      DateTime? returnedAt;
      if (rt is Timestamp) returnedAt = rt.toDate();

      if (returnedAt != null &&
          DateTime.now().difference(returnedAt).inMinutes >= 60) {
        await doc.reference.delete();
      }
    }
  }

  Future<String?> _convertImageToBase64(File? imageFile) async {
    if (imageFile == null) return null;

    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    if (base64Image.length > 800000) {
      throw Exception(
        'Image too big for Firestore. Please choose a smaller/compressed image.',
      );
    }

    return base64Image;
  }

  Future<void> createPost(LostItem item, File? imageFile) async {
<<<<<<< Updated upstream
    String imageUrl = '';

    if (imageFile != null) {
      final fileName =
          'lost_found/${DateTime.now().millisecondsSinceEpoch}_${item.userId}.jpg';

      final ref = _storage.ref().child(fileName);
      await ref.putFile(imageFile);
      imageUrl = await ref.getDownloadURL();
=======
    try {
      final String? base64Image = await _convertImageToBase64(imageFile);
      final data = item.toMap();

      if (base64Image != null && base64Image.isNotEmpty) {
        data['image_data'] = base64Image;
      }

      data['timestamp'] = FieldValue.serverTimestamp();

      await _db.collection(_col).add(data);
    } catch (e) {
      print('ERROR uploading post: $e');
      rethrow;
>>>>>>> Stashed changes
    }

    final data = item.toMap();
    data['imageUrl'] = imageUrl;
    data['timestamp'] = FieldValue.serverTimestamp();

    await _db.collection(_col).add(data);
  }

  Future<void> updatePostFull({
    required String itemId,
    required String title,
    required String category,
    required String description,
    required String location,
    required DateTime reportedDateTime,
    File? imageFile,
    bool removePhoto = false,
  }) async {
    final docRef = _db.collection(_col).doc(itemId);
    final doc = await docRef.get();

    if (!doc.exists) {
      throw Exception('Post not found.');
    }

    final currentData = doc.data();
    final currentStatus = (currentData?['status'] ?? '').toString();

    if (currentStatus != 'Active') {
      throw Exception('Only active posts can be edited.');
    }

    final Map<String, dynamic> updateData = {
      'title': title.trim(),
      'category': category.trim(),
      'description': description.trim(),
      'location': location.trim(),
      'reportedDateTime': Timestamp.fromDate(reportedDateTime),
    };

    if (removePhoto) {
      updateData['image_data'] = null;
      updateData['imageUrl'] = '';
    } else if (imageFile != null) {
      final String? base64Image = await _convertImageToBase64(imageFile);
      updateData['image_data'] = base64Image;
      updateData['imageUrl'] = '';
    }

    await docRef.update(updateData);
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

<<<<<<< Updated upstream
    final data = doc.data();
    final imageUrl = (data?['imageUrl'] as String?) ?? '';

    if (imageUrl.isNotEmpty) {
      try {
        await _storage.refFromURL(imageUrl).delete();
      } catch (_) {}
    }

=======
>>>>>>> Stashed changes
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
