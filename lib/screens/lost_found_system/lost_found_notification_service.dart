import 'package:cloud_firestore/cloud_firestore.dart';

import 'lost_item_model.dart';

class LostFoundNotificationService {
  static const String _notificationsCol = 'lost_found_notifications';
  static const String _usersCol = 'users';

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<QuerySnapshot<Map<String, dynamic>>> getNotificationsStream(
    String userId,
  ) {
    return _db
        .collection(_notificationsCol)
        .where('userId', isEqualTo: userId)
        .snapshots();
  }

  Future<void> sendToUser({
    required String userId,
    required String title,
    required String body,
    String? itemId,
    String? itemType,
    String? actionType,
    Map<String, dynamic>? extraData,
  }) async {
    if (userId.trim().isEmpty) return;

    await _db.collection(_notificationsCol).add({
      'userId': userId,
      'title': title.trim(),
      'body': body.trim(),
      'itemId': itemId,
      'itemType': itemType,
      'actionType': actionType,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      ...?extraData,
    });
  }

  Future<void> sendToMultipleUsers({
    required List<String> userIds,
    required String title,
    required String body,
    String? itemId,
    String? itemType,
    String? actionType,
    Map<String, dynamic>? extraData,
  }) async {
    final uniqueIds = userIds
        .where((e) => e.trim().isNotEmpty)
        .toSet()
        .toList();

    if (uniqueIds.isEmpty) return;

    WriteBatch batch = _db.batch();
    int opCount = 0;

    for (final uid in uniqueIds) {
      final docRef = _db.collection(_notificationsCol).doc();
      batch.set(docRef, {
        'userId': uid,
        'title': title.trim(),
        'body': body.trim(),
        'itemId': itemId,
        'itemType': itemType,
        'actionType': actionType,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        ...?extraData,
      });
      opCount++;

      if (opCount == 400) {
        await batch.commit();
        batch = _db.batch();
        opCount = 0;
      }
    }

    if (opCount > 0) {
      await batch.commit();
    }
  }

  Future<void> notifyAllUsersAboutNewPost({
    required LostItem item,
    required String itemId,
  }) async {
    final usersSnap = await _db.collection(_usersCol).get();
    final userIds = usersSnap.docs
        .map((e) => e.id)
        .where((e) => e.isNotEmpty)
        .toList();

    if (userIds.isEmpty) return;

    final title = item.type == 'Lost'
        ? 'New lost item posted'
        : 'New found item posted';

    final locationText = item.location.trim().isEmpty
        ? 'campus'
        : item.location.trim();

    final body =
        '${item.title} was posted in $locationText. Check the Lost & Found section.';

    await sendToMultipleUsers(
      userIds: userIds,
      title: title,
      body: body,
      itemId: itemId,
      itemType: item.type,
      actionType: 'new_post',
      extraData: {'postTitle': item.title, 'postCategory': item.category},
    );
  }

  Future<void> notifyAdminDeletedPost({
    required String userId,
    required String itemId,
    required String itemType,
    required String itemTitle,
    String? reason,
  }) async {
    final String finalReason = (reason ?? '').trim().isEmpty
        ? 'because it may be unsuitable or due to some other reason'
        : reason!.trim();

    await sendToUser(
      userId: userId,
      title: 'Post removed by system',
      body:
          'Your Lost & Found post "$itemTitle" was removed by the system $finalReason.',
      itemId: itemId,
      itemType: itemType,
      actionType: 'admin_deleted_post',
      extraData: {'adminDeleteReason': finalReason},
    );
  }

  Future<void> markAsRead(String notificationId) async {
    await _db.collection(_notificationsCol).doc(notificationId).update({
      'isRead': true,
    });
  }

  Future<void> markAllAsRead(String userId) async {
    final snap = await _db
        .collection(_notificationsCol)
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    if (snap.docs.isEmpty) return;

    WriteBatch batch = _db.batch();
    int opCount = 0;

    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
      opCount++;

      if (opCount == 400) {
        await batch.commit();
        batch = _db.batch();
        opCount = 0;
      }
    }

    if (opCount > 0) {
      await batch.commit();
    }
  }

  String formatTime(dynamic timestamp) {
    DateTime? dt;

    if (timestamp is Timestamp) {
      dt = timestamp.toDate();
    } else if (timestamp is DateTime) {
      dt = timestamp;
    }

    if (dt == null) return 'Just now';

    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';

    return '${dt.day}/${dt.month}/${dt.year}  $hour:$minute $period';
  }
}
