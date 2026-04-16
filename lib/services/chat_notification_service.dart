import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

class ChatNotificationService {
  ChatNotificationService._internal();
  static final ChatNotificationService instance =
      ChatNotificationService._internal();

  final Map<String, StreamSubscription> _activeListeners = {};
  DateTime appStartTime = DateTime.now();

  void startListening() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("🔔 [ChatNotif]: No user logged in. Listener not started.");
      return;
    }

    print("🔔 [ChatNotif]: Listening for messages for user: ${user.email}");

    // 1. මම ඉන්න ගෲප් ලිස්ට් එක බලනවා
    FirebaseFirestore.instance
        .collection('groups')
        .where('members', arrayContains: user.uid)
        .snapshots()
        .listen((groupSnapshot) {
          print("🔔 [ChatNotif]: Found ${groupSnapshot.docs.length} groups.");

          for (var groupDoc in groupSnapshot.docs) {
            String groupId = groupDoc.id;
            String groupName = groupDoc.data()['groupName'] ?? "Safety Group";

            if (_activeListeners.containsKey(groupId)) continue;

            print("🔔 [ChatNotif]: Subscribing to group: $groupName");

            // 2. අදාළ ගෲප් එකේ මැසේජ් Listen කිරීම
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
                    String senderName = msgData['senderName'] ?? "Someone";
                    String text = msgData['text'] ?? "";

                    if (msgData['timestamp'] == null) return;
                    DateTime msgTime = (msgData['timestamp'] as Timestamp)
                        .toDate();

                    // ලොග් එකක් දාමු මැසේජ් එකක් ආවම
                    print(
                      "📩 [ChatNotif]: New message detected in $groupName from $senderName",
                    );

                    // 3. කොන්දේසි පරීක්ෂාව
                    // මැසේජ් එක මම යවපු එකක් නොවිය යුතුයි
                    // මැසේජ් එකේ වෙලාව ඇප් එක පටන් ගත්ත වෙලාවට වඩා අලුත් විය යුතුයි (පරණ ඒවාට නොටිෆිකේෂන් එන එක නවත්වන්න)
                    if (senderId != user.uid &&
                        msgTime.isAfter(
                          appStartTime.subtract(const Duration(seconds: 10)),
                        )) {
                      // පරීක්ෂා කිරීමේ පහසුවට තත්පර 10 ක පරතරයක් දෙමු
                      if (msgTime.isAfter(
                        appStartTime.subtract(const Duration(seconds: 1)),
                      )) {
                        print("🚀 [ChatNotif]: Showing notification now!");

                        NotificationService.showChatNotification(
                          id: groupId.hashCode,
                          groupName: groupName,
                          senderName: senderName,
                          message: text.isEmpty ? "Sent an attachment" : text,
                          groupId: groupId,
                        );

                        // වෙලාව Update කරනවා එකම මැසේජ් එකට දෙපාරක් එන එක නවත්වන්න
                        appStartTime = DateTime.now();
                      } else {
                        print(
                          "⏳ [ChatNotif]: Message ignored because it is old.",
                        );
                      }
                    } else {
                      print(
                        "🚫 [ChatNotif]: Message ignored because sender is ME.",
                      );
                    }
                  }
                });

            _activeListeners[groupId] = sub;
          }
        });
  }

  void stopListening() {
    for (var sub in _activeListeners.values) {
      sub.cancel();
    }
    _activeListeners.clear();
  }
}
