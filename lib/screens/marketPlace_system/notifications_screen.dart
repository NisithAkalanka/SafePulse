import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'negotiation_chat.dart';

class MarketNotificationsScreen extends StatelessWidget {
  const MarketNotificationsScreen({super.key});

  static const Color gRedMid = Color(0xFFB31217);
  static const Color darkEnd = Color(0xFF1B1B1B);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color pageBg = isDark
        ? const Color(0xFF0F0F13)
        : const Color(0xFFF6F7FB);
    final Color cardBg = isDark ? const Color(0xFF1B1B22) : Colors.white;
    final Color textPrimary = isDark ? Colors.white : Colors.black87;

    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFFFF4B4B), gRedMid, darkEnd],
            ),
          ),
        ),
        title: const Text(
          "Activity Hub",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('market_notifications')
            .where('userId', isEqualTo: currentUserId)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: gRedMid),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No new notifications yet."));
          }

          final docs = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var notifData = docs[index].data() as Map<String, dynamic>;
              String notificationId = docs[index].id;

              // --- පියවර: Seen කර ඇත්දැයි බැලීමට boolean එකක් භාවිත කරමු ---
              bool isRead = notifData['isRead'] ?? false;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: isRead
                      ? cardBg
                      : (isDark
                            ? Colors.white.withOpacity(0.05)
                            : const Color(0xFFFFF9F9)),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isRead
                        ? Colors.transparent
                        : gRedMid.withOpacity(0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    backgroundColor: isRead
                        ? Colors.grey.shade200
                        : const Color(0xFFFFF2F2),
                    child: Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: isRead ? Colors.grey : gRedMid,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    notifData['title'] ?? "Message Alert",
                    style: TextStyle(
                      color: textPrimary,
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    notifData['message'] ?? "",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),

                  // --- පියවර:Seen නොවූ පණිවිඩ සඳහා රතු පාට සලකුණ පෙන්වයි ---
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!isRead)
                        const CircleAvatar(
                          radius: 5,
                          backgroundColor: Colors.red,
                        ), // රතු තිත
                      const SizedBox(height: 5),
                      const Icon(Icons.chevron_right, size: 16),
                    ],
                  ),
                  onTap: () {
                    // --- ඉතා වැදගත්: ක්ලික් කළ සැනින් 'Mark as Seen' වේ ---
                    _markAsSeen(notificationId);
                    _navigateToChatFromNotif(context, notifData['itemId']);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- පියවර: Firestore හි isRead flag එක update කරයි ---
  void _markAsSeen(String notifId) async {
    await FirebaseFirestore.instance
        .collection('market_notifications')
        .doc(notifId)
        .update({'isRead': true});
  }

  void _navigateToChatFromNotif(BuildContext context, String? itemId) async {
    if (itemId == null) return;
    try {
      var doc = await FirebaseFirestore.instance
          .collection('listings')
          .doc(itemId)
          .get();
      if (doc.exists) {
        var itemData = doc.data() as Map<String, dynamic>;
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => NegotiationChat(
                docId: itemId,
                itemName: itemData['name'],
                itemPrice: itemData['itemPrice'] ?? itemData['price'],
                itemImage: itemData['image'],
                sellerId: itemData['sellerId'],
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Navigation Error: $e");
    }
  }
}
