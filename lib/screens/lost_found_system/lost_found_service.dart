import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'lost_found_notification_service.dart';
import 'lost_item_model.dart';

class LostFoundService {
  static const String _col = 'lost_found_posts';
  static const String _archiveCol = 'lost_found_returned_archive';

  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final LostFoundNotificationService _notificationService =
      LostFoundNotificationService();

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

  Future<LostItem?> getItemById(String itemId) async {
    await _cleanupReturnedItems();

    final doc = await _db.collection(_col).doc(itemId).get();

    if (!doc.exists || doc.data() == null) return null;

    final item = LostItem.fromMap(doc.data()!, doc.id);

    if (item.status == 'Returned' && item.returnedAt != null) {
      final expired =
          DateTime.now().difference(item.returnedAt!).inMinutes >= 60;
      if (expired) return null;
    }

    return item;
  }

  Future<void> _archiveReturnedDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) async {
    final data = doc.data();

    final archiveRef = _db.collection(_archiveCol).doc(doc.id);

    final Map<String, dynamic> archiveData = Map<String, dynamic>.from(data);
    archiveData['archivedAt'] = FieldValue.serverTimestamp();
    archiveData['originalDocId'] = doc.id;

    final messagesSnap = await doc.reference.collection('messages').get();
    final List<Map<String, dynamic>> archivedMessages = messagesSnap.docs
        .map((m) => m.data())
        .toList();

    archiveData['archivedMessages'] = archivedMessages;

    await archiveRef.set(archiveData, SetOptions(merge: true));

    for (final messageDoc in messagesSnap.docs) {
      await messageDoc.reference.delete();
    }

    await doc.reference.delete();
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

      if (rt is Timestamp) {
        returnedAt = rt.toDate();
      } else if (rt is DateTime) {
        returnedAt = rt;
      }

      if (returnedAt != null &&
          DateTime.now().difference(returnedAt).inMinutes >= 60) {
        await _archiveReturnedDocument(doc);
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

      final docRef = await _db.collection(_col).add(data);

      await _notificationService.notifyAllUsersAboutNewPost(
        item: item,
        itemId: docRef.id,
      );
    } catch (e) {
      rethrow;
    }
  }

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
    final doc = await _db.collection(_col).doc(itemId).get();
    final item = doc.exists && doc.data() != null
        ? LostItem.fromMap(doc.data()!, doc.id)
        : null;

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

    if (item != null) {
      await _notificationService.sendToUser(
        userId: item.userId,
        title: 'New verification request',
        body:
            '$requesterName asked a verification question for "${item.title}".',
        itemId: itemId,
        itemType: item.type,
        actionType: 'claim_request',
      );
    }
  }

  Future<void> submitOwnerAnswer({
    required String itemId,
    required String answer,
  }) async {
    final doc = await _db.collection(_col).doc(itemId).get();
    final item = doc.exists && doc.data() != null
        ? LostItem.fromMap(doc.data()!, doc.id)
        : null;

    await _db.collection(_col).doc(itemId).update({
      'status': 'Answer Submitted',
      'verificationAnswer': answer,
    });

    if (item != null && (item.requesterId ?? '').isNotEmpty) {
      await _notificationService.sendToUser(
        userId: item.requesterId!,
        title: 'Verification answer received',
        body:
            'The owner answered your verification request for "${item.title}".',
        itemId: itemId,
        itemType: item.type,
        actionType: 'verification_answer',
      );
    }
  }

  Future<void> sendLostItemFoundRequest({
    required String itemId,
    required String requesterId,
    required String requesterName,
  }) async {
    final doc = await _db.collection(_col).doc(itemId).get();
    final item = doc.exists && doc.data() != null
        ? LostItem.fromMap(doc.data()!, doc.id)
        : null;

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

    if (item != null) {
      await _notificationService.sendToUser(
        userId: item.userId,
        title: 'New claim request',
        body: '$requesterName sent a claim request for "${item.title}".',
        itemId: itemId,
        itemType: item.type,
        actionType: 'claim_request',
      );
    }
  }

  Future<void> ownerRequestsChatOpen(String itemId) async {
    final doc = await _db.collection(_col).doc(itemId).get();
    final item = doc.exists && doc.data() != null
        ? LostItem.fromMap(doc.data()!, doc.id)
        : null;

    await _db.collection(_col).doc(itemId).update({
      'status': 'Owner Requested Chat Approval',
      'ownerChatAccepted': true,
      'requesterChatAccepted': false,
      'chatEnabled': false,
      'ownerRetryMessage': null,
    });

    if (item != null && (item.requesterId ?? '').isNotEmpty) {
      await _notificationService.sendToUser(
        userId: item.requesterId!,
        title: 'Chat request received',
        body: 'The owner requested to open chat for "${item.title}".',
        itemId: itemId,
        itemType: item.type,
        actionType: 'request_chat',
      );
    }
  }

  Future<void> requesterAcceptsChat(String itemId) async {
    final doc = await _db.collection(_col).doc(itemId).get();
    final item = doc.exists && doc.data() != null
        ? LostItem.fromMap(doc.data()!, doc.id)
        : null;

    await _db.collection(_col).doc(itemId).update({
      'status': 'Chat Enabled',
      'requesterChatAccepted': true,
      'ownerChatAccepted': true,
      'chatEnabled': true,
      'ownerRetryMessage': null,
      'ownerMarkedReceived': false,
      'requesterMarkedReturned': false,
    });

    if (item != null) {
      final ids = <String>[
        item.userId,
        if ((item.requesterId ?? '').isNotEmpty) item.requesterId!,
      ];

      await _notificationService.sendToMultipleUsers(
        userIds: ids,
        title: 'Private chat enabled',
        body: 'Private chat is now enabled for "${item.title}".',
        itemId: itemId,
        itemType: item.type,
        actionType: 'chat_accepted',
      );
    }
  }

  Future<void> requesterRejectsOwnerChatRequest(String itemId) async {
    final doc = await _db.collection(_col).doc(itemId).get();
    final item = doc.exists && doc.data() != null
        ? LostItem.fromMap(doc.data()!, doc.id)
        : null;

    await _db.collection(_col).doc(itemId).update({
      'status': 'Owner Chat Rejected',
      'requesterChatAccepted': false,
      'chatEnabled': false,
    });

    if (item != null) {
      await _notificationService.sendToUser(
        userId: item.userId,
        title: 'Chat request rejected',
        body: 'Your chat request for "${item.title}" was rejected.',
        itemId: itemId,
        itemType: item.type,
        actionType: 'chat_rejected',
      );
    }
  }

  Future<void> ownerSendsRetryMessage({
    required String itemId,
    required String message,
  }) async {
    final doc = await _db.collection(_col).doc(itemId).get();
    if (!doc.exists) return;

    final data = doc.data() ?? {};
    final item = LostItem.fromMap(data, doc.id);
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

    if ((item.requesterId ?? '').isNotEmpty) {
      await _notificationService.sendToUser(
        userId: item.requesterId!,
        title: 'Message from owner',
        body:
            'The owner sent a message about "${item.title}": ${message.trim()}',
        itemId: itemId,
        itemType: item.type,
        actionType: 'retry_message',
      );
    }
  }

  Future<void> rejectChatRequest(String itemId) async {
    final doc = await _db.collection(_col).doc(itemId).get();
    if (!doc.exists || doc.data() == null) return;

    final item = LostItem.fromMap(doc.data()!, doc.id);
    final currentUid = FirebaseAuth.instance.currentUser?.uid ?? '';

    final bool ownerRejected =
        currentUid.isNotEmpty && currentUid == item.userId;
    final bool requesterCancelled =
        currentUid.isNotEmpty && currentUid == (item.requesterId ?? '');

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

    if (ownerRejected && (item.requesterId ?? '').isNotEmpty) {
      await _notificationService.sendToUser(
        userId: item.requesterId!,
        title: 'Request rejected',
        body: 'Your request for "${item.title}" was rejected.',
        itemId: itemId,
        itemType: item.type,
        actionType: 'chat_rejected',
      );
    } else if (requesterCancelled && item.userId.trim().isNotEmpty) {
      await _notificationService.sendToUser(
        userId: item.userId,
        title: 'Request cancelled',
        body: 'The request for "${item.title}" was cancelled.',
        itemId: itemId,
        itemType: item.type,
        actionType: 'chat_rejected',
      );
    }
  }

  Future<String> getVerificationAnswer(String itemId) async {
    final ds = await _db.collection(_col).doc(itemId).get();
    if (!ds.exists) return 'No details provided.';
    final data = ds.data();
    return (data?['verificationAnswer'] as String?) ?? 'No details provided.';
  }

  Future<String> getVerificationQuestion(String itemId) async {
    final ds = await _db.collection(_col).doc(itemId).get();
    if (!ds.exists) return 'No question provided.';
    final data = ds.data();
    return (data?['verificationQuestion'] as String?) ??
        'No question provided.';
  }

  Future<void> enablePrivateChat(String itemId) async {
    final doc = await _db.collection(_col).doc(itemId).get();
    final item = doc.exists && doc.data() != null
        ? LostItem.fromMap(doc.data()!, doc.id)
        : null;

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

    if (item != null) {
      final ids = <String>[
        item.userId,
        if ((item.requesterId ?? '').isNotEmpty) item.requesterId!,
      ];

      await _notificationService.sendToMultipleUsers(
        userIds: ids,
        title: 'Private chat enabled',
        body: 'Private chat is now enabled for "${item.title}".',
        itemId: itemId,
        itemType: item.type,
        actionType: 'chat_accepted',
      );
    }
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
    final item = LostItem.fromMap(data, doc.id);
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

    await _notificationService.sendToUser(
      userId: item.userId,
      title: 'Item marked as returned',
      body: 'The other user marked "${item.title}" as returned.',
      itemId: itemId,
      itemType: item.type,
      actionType: 'returned',
    );
  }

  Future<void> ownerMarksReceived(String itemId) async {
    final doc = await _db.collection(_col).doc(itemId).get();
    if (!doc.exists) return;

    final data = doc.data() ?? {};
    final item = LostItem.fromMap(data, doc.id);
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

    if ((item.requesterId ?? '').isNotEmpty) {
      await _notificationService.sendToUser(
        userId: item.requesterId!,
        title: 'Item marked as received',
        body: 'The owner marked "${item.title}" as received.',
        itemId: itemId,
        itemType: item.type,
        actionType: 'received',
      );
    }
  }

  Future<void> markAsReturned(String itemId) async {
    final doc = await _db.collection(_col).doc(itemId).get();
    final item = doc.exists && doc.data() != null
        ? LostItem.fromMap(doc.data()!, doc.id)
        : null;

    await _db.collection(_col).doc(itemId).update({
      'status': 'Returned',
      'returnedAt': FieldValue.serverTimestamp(),
      'ownerMarkedReceived': true,
      'requesterMarkedReturned': true,
    });

    if (item != null) {
      final ids = <String>[
        item.userId,
        if ((item.requesterId ?? '').isNotEmpty) item.requesterId!,
      ];

      await _notificationService.sendToMultipleUsers(
        userIds: ids,
        title: 'Item return completed',
        body: '"${item.title}" was marked as returned.',
        itemId: itemId,
        itemType: item.type,
        actionType: 'returned',
      );
    }
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
      'readBy': [senderId],
      'hiddenFor': <String>[],
      'edited': false,
      'deletedForEveryone': false,
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

    if (base64Image.length > 900000) {
      throw Exception('Image is too large to send.');
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

    if (base64Audio.length > 1200000) {
      throw Exception('Audio is too large to send.');
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

  Future<void> markMessagesAsSeen({
    required String itemId,
    required String currentUserId,
    required List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  }) async {
    for (final doc in docs) {
      final data = doc.data();
      final senderId = (data['senderId'] ?? '').toString();
      final readBy = List<String>.from(data['readBy'] ?? const <String>[]);
      final hiddenFor = List<String>.from(
        data['hiddenFor'] ?? const <String>[],
      );

      if (hiddenFor.contains(currentUserId)) continue;
      if (senderId == currentUserId) continue;
      if (readBy.contains(currentUserId)) continue;

      await doc.reference.update({
        'readBy': FieldValue.arrayUnion([currentUserId]),
      });
    }
  }

  Future<void> editTextMessage({
    required String itemId,
    required String messageId,
    required String updatedText,
  }) async {
    await _db
        .collection(_col)
        .doc(itemId)
        .collection('messages')
        .doc(messageId)
        .update({
          'text': updatedText.trim(),
          'edited': true,
          'editedAt': FieldValue.serverTimestamp(),
        });
  }

  Future<void> deleteMessageForMe({
    required String itemId,
    required String messageId,
    required String currentUserId,
  }) async {
    await _db
        .collection(_col)
        .doc(itemId)
        .collection('messages')
        .doc(messageId)
        .update({
          'hiddenFor': FieldValue.arrayUnion([currentUserId]),
        });
  }

  Future<void> deleteMessageForEveryone({
    required String itemId,
    required String messageId,
  }) async {
    await _db
        .collection(_col)
        .doc(itemId)
        .collection('messages')
        .doc(messageId)
        .update({
          'deletedForEveryone': true,
          'type': 'text',
          'text': 'This message was deleted',
          'image_data': null,
          'audio_data': null,
          'audio_duration_ms': null,
          'edited': false,
          'editedAt': null,
        });
  }
}
