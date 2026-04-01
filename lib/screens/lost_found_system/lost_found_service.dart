import 'dart:convert';
import 'dart:io';

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

  Stream<LostItem?> getItemStream(String itemId) {
    _cleanupReturnedItems();
    return _db.collection(_col).doc(itemId).snapshots().map((doc) {
      if (!doc.exists || doc.data() == null) return null;
      return LostItem.fromMap(doc.data()!, doc.id);
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

        if (base64Image.length > 800000) {
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
      rethrow;
    }
  }

<<<<<<< Updated upstream
<<<<<<< Updated upstream
  Future<void> updatePostBasic({
=======
=======
  Future<String?> _convertImageToBase64(File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    if (base64Image.length > 800000) {
      throw Exception(
        'Image too big for Firestore. Please choose a smaller/compressed image.',
      );
    }

    return base64Image;
  }

>>>>>>> Stashed changes
  Future<void> updatePostFull({
>>>>>>> Stashed changes
    required String itemId,
    required String title,
    required String category,
    required String description,
    required String location,
<<<<<<< Updated upstream
  }) async {
    await _db.collection(_col).doc(itemId).update({
=======
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
>>>>>>> Stashed changes
      'title': title.trim(),
      'category': category.trim(),
      'description': description.trim(),
      'location': location.trim(),
<<<<<<< Updated upstream
    });
=======
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
>>>>>>> Stashed changes
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

  Future<void> saveOrUpdatePost(LostItem item) async {
    await _db
        .collection(_col)
        .doc(item.id)
        .set(item.toMap(), SetOptions(merge: true));
  }

  Future<void> deletePost(String itemId) async {
    final doc = await _db.collection(_col).doc(itemId).get();
    if (!doc.exists) return;

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
      'ownerChatAccepted': false,
      'requesterChatAccepted': false,
      'ownerRetryMessage': null,
      'ownerRetryCount': 0,
      'ownerMarkedReceived': false,
      'requesterMarkedReturned': false,
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

  Future<void> sendLostItemFoundRequest({
    required String itemId,
    required String requesterId,
    required String requesterName,
  }) async {
    await _db.collection(_col).doc(itemId).update({
      'status': 'Chat Request Pending',
      'requestType': 'chat_request',
      'requesterId': requesterId,
      'requesterName': requesterName,
      'verificationQuestion': null,
      'verificationAnswer': null,
      'chatEnabled': false,
      'ownerChatAccepted': false,
      'requesterChatAccepted': false,
      'ownerRetryMessage': null,
      'ownerMarkedReceived': false,
      'requesterMarkedReturned': false,
    });
  }

  Future<void> ownerRequestsChatOpen(String itemId) async {
    await _db.collection(_col).doc(itemId).update({
      'status': 'Owner Requested Chat Approval',
      'ownerChatAccepted': true,
      'requesterChatAccepted': false,
      'chatEnabled': false,
      'ownerRetryMessage': null,
    });
  }

  Future<void> requesterAcceptsChat(String itemId) async {
    await _db.collection(_col).doc(itemId).update({
      'status': 'Chat Enabled',
      'requesterChatAccepted': true,
      'ownerChatAccepted': true,
      'chatEnabled': true,
      'ownerRetryMessage': null,
      'ownerMarkedReceived': false,
      'requesterMarkedReturned': false,
    });
  }

  Future<void> requesterRejectsOwnerChatRequest(String itemId) async {
    await _db.collection(_col).doc(itemId).update({
      'status': 'Owner Chat Rejected',
      'requesterChatAccepted': false,
      'chatEnabled': false,
    });
  }

  Future<void> ownerSendsRetryMessage({
    required String itemId,
    required String message,
  }) async {
    final doc = await _db.collection(_col).doc(itemId).get();
    if (!doc.exists) return;

    final data = doc.data() ?? {};
    final int currentCount = (data['ownerRetryCount'] ?? 0) as int;

    if (currentCount >= 2) {
      throw Exception('Retry limit reached.');
    }

    await _db.collection(_col).doc(itemId).update({
      'status': 'Owner Retry Message Sent',
      'ownerRetryMessage': message.trim(),
      'ownerRetryCount': currentCount + 1,
      'chatEnabled': false,
      'ownerChatAccepted': true,
      'requesterChatAccepted': false,
    });
  }

  Future<void> rejectChatRequest(String itemId) async {
    await _db.collection(_col).doc(itemId).update({
      'status': 'Active',
      'requestType': null,
      'requesterId': null,
      'requesterName': null,
      'verificationQuestion': null,
      'verificationAnswer': null,
      'chatEnabled': false,
      'ownerChatAccepted': false,
      'requesterChatAccepted': false,
      'ownerRetryMessage': null,
      'ownerRetryCount': 0,
      'ownerMarkedReceived': false,
      'requesterMarkedReturned': false,
      'returnedAt': null,
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
      'ownerChatAccepted': true,
      'requesterChatAccepted': true,
      'ownerRetryMessage': null,
      'ownerMarkedReceived': false,
      'requesterMarkedReturned': false,
      'returnedAt': null,
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
      'ownerChatAccepted': false,
      'requesterChatAccepted': false,
      'ownerRetryMessage': null,
      'ownerRetryCount': 0,
      'ownerMarkedReceived': false,
      'requesterMarkedReturned': false,
      'returnedAt': null,
    });
  }

  Future<void> requesterMarksReturned(String itemId) async {
    final doc = await _db.collection(_col).doc(itemId).get();
    if (!doc.exists) return;

    final data = doc.data() ?? {};
    final bool ownerMarkedReceived = data['ownerMarkedReceived'] ?? false;

    if (ownerMarkedReceived) {
      await _db.collection(_col).doc(itemId).update({
        'status': 'Returned',
        'requesterMarkedReturned': true,
        'ownerMarkedReceived': true,
        'returnedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await _db.collection(_col).doc(itemId).update({
        'status': 'Return Pending',
        'requesterMarkedReturned': true,
        'returnedAt': null,
      });
    }
  }

  Future<void> ownerMarksReceived(String itemId) async {
    final doc = await _db.collection(_col).doc(itemId).get();
    if (!doc.exists) return;

    final data = doc.data() ?? {};
    final bool requesterMarkedReturned =
        data['requesterMarkedReturned'] ?? false;

    if (requesterMarkedReturned) {
      await _db.collection(_col).doc(itemId).update({
        'status': 'Returned',
        'ownerMarkedReceived': true,
        'requesterMarkedReturned': true,
        'returnedAt': FieldValue.serverTimestamp(),
      });
    } else {
      await _db.collection(_col).doc(itemId).update({
        'status': 'Receive Pending',
        'ownerMarkedReceived': true,
        'returnedAt': null,
      });
    }
  }

  Future<void> markAsReturned(String itemId) async {
    await _db.collection(_col).doc(itemId).update({
      'status': 'Returned',
      'returnedAt': FieldValue.serverTimestamp(),
      'ownerMarkedReceived': true,
      'requesterMarkedReturned': true,
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
    String? text,
    String type = 'text',
    String? imageBase64,
    String? audioBase64,
    int? audioDurationMs,
  }) async {
    await _db.collection(_col).doc(itemId).collection('messages').add({
      'senderId': senderId,
      'senderName': senderName,
      'type': type,
      'text': text ?? '',
      'image_data': imageBase64,
      'audio_data': audioBase64,
      'audio_duration_ms': audioDurationMs,
      'timestamp': FieldValue.serverTimestamp(),
    });
  }

  Future<void> sendTextMessage({
    required String itemId,
    required String senderId,
    required String senderName,
    required String text,
  }) async {
    await sendMessage(
      itemId: itemId,
      senderId: senderId,
      senderName: senderName,
      text: text,
      type: 'text',
    );
  }

  Future<void> sendImageMessage({
    required String itemId,
    required String senderId,
    required String senderName,
    required File imageFile,
  }) async {
    final bytes = await imageFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    if (base64Image.length > 1000000) {
      throw Exception('Selected image is too large. Choose a smaller image.');
    }

    await sendMessage(
      itemId: itemId,
      senderId: senderId,
      senderName: senderName,
      type: 'image',
      imageBase64: base64Image,
    );
  }

  Future<void> sendAudioMessage({
    required String itemId,
    required String senderId,
    required String senderName,
    required File audioFile,
    int? audioDurationMs,
  }) async {
    final bytes = await audioFile.readAsBytes();
    final base64Audio = base64Encode(bytes);

    if (base64Audio.length > 1500000) {
      throw Exception(
        'Recorded audio is too large. Please record a shorter clip.',
      );
    }

    await sendMessage(
      itemId: itemId,
      senderId: senderId,
      senderName: senderName,
      type: 'audio',
      audioBase64: base64Audio,
      audioDurationMs: audioDurationMs,
    );
  }
}
