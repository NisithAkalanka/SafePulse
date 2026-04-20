import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

class ChatNotificationService {
  ChatNotificationService._internal();
  static final ChatNotificationService instance =
      ChatNotificationService._internal();

  final Map<String, StreamSubscription> _activeListeners = {};

  // අවසන් වරට නොටිෆිකේෂන් එකක් පෙන්වූ මැසේජ් එකේ ID එක (Duplicate වැළැක්වීමට)
  String? _lastProcessedMessageId;

  void startListening() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("🔔 [ChatNotif]: No user logged in.");
      return;
    }

    print("🔔 [ChatNotif]: Listening for messages for: ${user.email}");

    // 1. මම සාමාජිකයෙක් වී සිටින සියලුම ගෲප් ලබා ගැනීම
    FirebaseFirestore.instance
        .collection('groups')
        .where('members', arrayContains: user.uid)
        .snapshots()
        .listen((groupSnapshot) {
          for (var groupDoc in groupSnapshot.docs) {
            String groupId = groupDoc.id;
            String groupName =
                groupDoc.data()['groupName'] ?? "Protection Circle";

            if (_activeListeners.containsKey(groupId)) continue;

            print("🔔 [ChatNotif]: Monitoring group: $groupName");

            // 2. අදාළ ගෲප් එකේ අලුත්ම මැසේජ් එක Listen කිරීම (iOS Metadata සමඟ)
            var sub = FirebaseFirestore.instance
                .collection('groups')
                .doc(groupId)
                .collection('messages')
                .orderBy('timestamp', descending: true)
                .limit(1)
                .snapshots(includeMetadataChanges: true)
                .listen((messageSnapshot) {
                  if (messageSnapshot.docs.isNotEmpty) {
                    var messageDoc = messageSnapshot.docs.first;
                    var msgData = messageDoc.data();
                    String messageId = messageDoc.id;

                    // සර්වර් එකේ මැසේජ් එක හරියටම Save වුණාම විතරක් (Not Pending) වැඩේ පටන් ගන්නවා
                    if (messageSnapshot.metadata.hasPendingWrites) return;

                    // දැනටමත් මේ මැසේජ් එකට නොටිෆිකේෂන් එකක් දුන්නා නම් නවත්වන්න
                    if (_lastProcessedMessageId == messageId) return;

                    String senderId = msgData['senderId'] ?? "";
                    String senderName = msgData['senderName'] ?? "Guardian";
                    String text = msgData['text'] ?? "";

                    if (msgData['timestamp'] == null) return;
                    DateTime msgTime = (msgData['timestamp'] as Timestamp)
                        .toDate();

                    // 3. iPhone (iOS) සඳහා වන විශේෂ කොන්දේසි පරීක්ෂාව
                    // - මැසේජ් එක මම යවපු එකක් නොවිය යුතුයි
                    // - මැසේජ් එකේ වෙලාව දැනට විනාඩියකට වඩා පරණ නොවිය යුතුයි (iOS Time Sync Fix)
                    if (senderId != user.uid) {
                      DateTime now = DateTime.now();
                      if (msgTime.isAfter(
                        now.subtract(const Duration(minutes: 1)),
                      )) {
                        print(
                          "🚀 [ChatNotif]: New Message in $groupName: $text",
                        );

                        NotificationService.showChatNotification(
                          id: groupId.hashCode,
                          groupName: groupName,
                          senderName: senderName,
                          message: text.isEmpty
                              ? "Sent an attachment 📎"
                              : text,
                          groupId: groupId,
                        );

                        _lastProcessedMessageId = messageId;
                      } else {
                        print("⏳ [ChatNotif]: Ignored old message.");
                      }
                    }
                  }
                });

            _activeListeners[groupId] = sub;
          }
        });
  }

  void stopListening() {
    print("🔔 [ChatNotif]: Stopping all listeners.");
    for (var sub in _activeListeners.values) {
      sub.cancel();
    }
    _activeListeners.clear();
  }
}
