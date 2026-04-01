import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'negotiation_chat.dart';
import 'package:intl/intl.dart';

class MarketNotificationsScreen extends StatefulWidget {
  const MarketNotificationsScreen({super.key});

  @override
  State<MarketNotificationsScreen> createState() =>
      _MarketNotificationsScreenState();
}

class _MarketNotificationsScreenState extends State<MarketNotificationsScreen> {
  static const Color gRedStart = Color(0xFFFF4B4B);
  static const Color gRedMid = Color(0xFFB31217);
  static const Color gDarkEnd = Color(0xFF1B1B1B);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color pageBg = isDark
        ? const Color(0xFF0F0F13)
        : const Color(0xFFF6F7FB);
    final Color cardBg = isDark ? const Color(0xFF1B1B22) : Colors.white;
    final Color textPrimary = isDark ? Colors.white : Colors.black87;
    final Color borderColor = isDark
        ? const Color(0xFF34343F)
        : const Color(0xFFE8EAF0);

    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [gRedStart, gRedMid, gDarkEnd],
              stops: [0.0, 0.62, 1.0],
            ),
          ),
        ),
        title: const Text(
          "Activity Hub",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 19,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Colors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: currentUserId == null
          ? const Center(child: Text("Please login to see notifications"))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('market_notifications')
                  .where('userId', isEqualTo: currentUserId)
                  // .orderBy('createdAt', descending: true) //
                  .snapshots(),
              builder: (context, snapshot) {
                // --- අලුතින් එක් කළ Error handling (Index ප්‍රශ්නය දැනගැනීමට) ---
                if (snapshot.hasError) {
                  debugPrint("Notification Stream Error: ${snapshot.error}");
                  // මෙතැන Index error එක පෙන්වයි. දත්ත මැකී යෑම නවතී.
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        "Connecting to notification server...\n(Make sure the Firestore Index is created)",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: textPrimary.withOpacity(0.5)),
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: gRedMid),
                  );
                }

                final docs = snapshot.data?.docs ?? [];

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.notifications_off_outlined,
                          size: 80,
                          color: textPrimary.withOpacity(0.1),
                        ),
                        const SizedBox(height: 15),
                        Text(
                          "Your inbox is empty.",
                          style: TextStyle(
                            color: textPrimary.withOpacity(0.4),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    String notificationId = docs[index].id;
                    bool isRead = data['isRead'] ?? false;

                    // Time parsing safety
                    DateTime time;
                    if (data['createdAt'] is Timestamp) {
                      time = (data['createdAt'] as Timestamp).toDate();
                    } else {
                      time = DateTime.now();
                    }

                    return Dismissible(
                      key: Key(notificationId),
                      direction: DismissDirection.endToStart,
                      onDismissed: (dir) => _deleteNotification(notificationId),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(
                          color: Colors.red.shade900,
                          borderRadius: BorderRadius.circular(22),
                        ),
                        child: const Icon(
                          Icons.delete_outline_rounded,
                          color: Colors.white,
                        ),
                      ),
                      child: GestureDetector(
                        onTap: () {
                          _markAsSeen(notificationId);
                          _navigateToChat(context, data['itemId']);
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isRead
                                ? cardBg
                                : (isDark
                                      ? const Color(0xFF23232B)
                                      : const Color(0xFFFFFAFA)),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(
                              color: isRead
                                  ? borderColor
                                  : gRedMid.withOpacity(0.3),
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: isRead
                                    ? Colors.grey.withOpacity(0.1)
                                    : gRedMid.withOpacity(0.12),
                                radius: 25,
                                child: Icon(
                                  Icons.chat_bubble_rounded,
                                  color: isRead ? Colors.grey : gRedMid,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          data['title'] ?? "Inquiry Update",
                                          style: TextStyle(
                                            color: textPrimary,
                                            fontWeight: isRead
                                                ? FontWeight.w600
                                                : FontWeight.w900,
                                            fontSize: 14.5,
                                          ),
                                        ),
                                        Text(
                                          DateFormat('hh:mm a').format(time),
                                          style: const TextStyle(
                                            color: Colors.grey,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    Text(
                                      data['message'] ?? "",
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: textPrimary.withOpacity(0.6),
                                        fontSize: 12,
                                        fontWeight: isRead
                                            ? FontWeight.normal
                                            : FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isRead)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: CircleAvatar(
                                    radius: 4,
                                    backgroundColor: gRedStart,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }

  void _markAsSeen(String notifId) {
    FirebaseFirestore.instance
        .collection('market_notifications')
        .doc(notifId)
        .update({'isRead': true});
  }

  void _deleteNotification(String notifId) {
    FirebaseFirestore.instance
        .collection('market_notifications')
        .doc(notifId)
        .delete();
  }

  void _navigateToChat(BuildContext context, String? itemId) async {
    if (itemId == null) return;
    try {
      var itemDoc = await FirebaseFirestore.instance
          .collection('listings')
          .doc(itemId)
          .get();
      if (itemDoc.exists) {
        var item = itemDoc.data() as Map<String, dynamic>;
        if (context.mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (c) => NegotiationChat(
                docId: itemId,
                itemName: item['name'],
                itemPrice: item['price'],
                itemImage: item['image'],
                sellerId: item['sellerId'],
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Nav Failed: $e");
    }
  }
}
