import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'notification_service.dart';

class ChatNotificationService {
  ChatNotificationService._internal();
  static final ChatNotificationService instance =
      ChatNotificationService._internal();

  final Map<String, StreamSubscription> _activeListeners = {};

  void startListening() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    print("🔔 [ChatNotif]: Listener Started for ${user.email}");

    // 1. මම ඉන්න ගෲප් ලිස්ට් එක බලනවා
    FirebaseFirestore.instance
        .collection('groups')
        .where('members', arrayContains: user.uid)
        .snapshots()
        .listen((groupSnapshot) {
          for (var groupDoc in groupSnapshot.docs) {
            String groupId = groupDoc.id;
            String groupName = groupDoc.data()['groupName'] ?? "SafePlus Group";

            if (_activeListeners.containsKey(groupId)) continue;

            // 2. අලුත්ම මැසේජ් එක විතරක් බලනවා
            var sub = FirebaseFirestore.instance
                .collection('groups')
                .doc(groupId)
                .collection('messages')
                .orderBy('timestamp', descending: true)
                .limit(1)
                .snapshots()
                .listen((messageSnapshot) {
                  if (messageSnapshot.docs.isNotEmpty) {
                    var msgData =
                        messageSnapshot.docs.first.data()
                            as Map<String, dynamic>;
                    String senderId = msgData['senderId'] ?? "";
                    String senderName = msgData['senderName'] ?? "Guardian";
                    String text = msgData['text'] ?? "";

                    // 🛑 වැදගත්ම දේ:
                    // 1. යැව්වේ මම නෙවෙයි නම්
                    // 2. මැසේජ් එක පරණ එකක් වුණත් කමක් නැහැ, දැනට ටෙස්ට් කරන්න පෙන්වන්න
                    if (senderId != user.uid) {
                      print("🚀 [ChatNotif]: TRIGGERING NOTIFICATION: $text");

                      NotificationService.showChatNotification(
                        id: groupId.hashCode,
                        groupName: groupName,
                        senderName: senderName,
                        message: text,
                        groupId: groupId,
                      );
                    }
                  }
                });
            _activeListeners[groupId] = sub;
          }
        });
  }
}
