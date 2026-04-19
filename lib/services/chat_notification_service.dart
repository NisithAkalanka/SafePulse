import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

class ChatNotificationService {
  // Singleton Pattern
  ChatNotificationService._internal();
  static final ChatNotificationService instance =
      ChatNotificationService._internal();

  final Map<String, StreamSubscription> _activeListeners = {};

  // ඇප් එක පටන් ගන්නා වෙලාව (පරණ මැසේජ් වලට නොටිෆිකේෂන් එන එක නවත්වන්න)
  DateTime _lastNotificationTime = DateTime.now();

  void startListening() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("🔔 [ChatNotif]: No user logged in. Listener not started.");
      return;
    }

    print("🔔 [ChatNotif]: Listening for messages for: ${user.email}");

    // 1. මම සාමාජිකයෙක් වෙලා ඉන්න හැම ගෲප් එකක්ම බලනවා
    FirebaseFirestore.instance
        .collection('groups')
        .where('members', arrayContains: user.uid)
        .snapshots()
        .listen((groupSnapshot) {
          for (var groupDoc in groupSnapshot.docs) {
            String groupId = groupDoc.id;
            String groupName =
                groupDoc.data()['groupName'] ?? "Protection Circle";

            // දැනටමත් මේ ගෲප් එකට සවන් දෙනවා නම් (Listener) ආයෙත් පටන් ගන්න එපා
            if (_activeListeners.containsKey(groupId)) continue;

            print("🔔 [ChatNotif]: New listener added for group: $groupName");

            // 2. ඒ ගෲප් එකේ අලුත්ම මැසේජ් එක විතරක් Listen කරනවා
            var sub = FirebaseFirestore.instance
                .collection('groups')
                .doc(groupId)
                .collection('messages')
                .orderBy('timestamp', descending: true)
                .limit(1)
                .snapshots()
                .listen((messageSnapshot) {
                  if (messageSnapshot.docs.isNotEmpty) {
                    var msgData = messageSnapshot.docs.first.data();
                    String senderId = msgData['senderId'] ?? "";
                    String senderName = msgData['senderName'] ?? "Guardian";
                    String text = msgData['text'] ?? "";

                    // මැසේජ් එකේ වෙලාව පරීක්ෂා කිරීම
                    if (msgData['timestamp'] == null) return;
                    DateTime msgTime = (msgData['timestamp'] as Timestamp)
                        .toDate();

                    // 3. කොන්දේසි පරීක්ෂාව (Conditions)
                    // - මැසේජ් එක මම යවපු එකක් නොවිය යුතුයි (senderId != user.uid)
                    // - මැසේජ් එකේ වෙලාව ඇප් එක පටන් ගත් වෙලාවට වඩා අලුත් විය යුතුයි
                    if (senderId != user.uid) {
                      // තත්පර 5ක සහනයක් (Buffer) සහිතව පරීක්ෂා කිරීම
                      if (msgTime.isAfter(
                        _lastNotificationTime.subtract(
                          const Duration(seconds: 5),
                        ),
                      )) {
                        print(
                          "🚀 [ChatNotif]: Sending Notification for: $text",
                        );

                        NotificationService.showChatNotification(
                          id: groupId.hashCode,
                          groupName: groupName,
                          senderName: senderName,
                          message: text.isEmpty ? "Sent an attachment" : text,
                          groupId: groupId,
                        );

                        // අවසන් වරට නොටිෆිකේෂන් එක එවූ වෙලාව Update කරනවා (Duplicate වැළැක්වීමට)
                        _lastNotificationTime = msgTime;
                      } else {
                        print("⏳ [ChatNotif]: Ignored old message.");
                      }
                    } else {
                      print("🚫 [ChatNotif]: Ignored message from ME.");
                    }
                  }
                });

            // Listener එක save කරගන්නවා පස්සේ cancel කරන්න
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
