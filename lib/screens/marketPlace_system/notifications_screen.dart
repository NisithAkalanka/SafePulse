import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'negotiation_chat.dart';
import 'rating_screen.dart';

class MarketNotificationsScreen extends StatefulWidget {
  const MarketNotificationsScreen({super.key});

<<<<<<< Updated upstream
<<<<<<< Updated upstream
<<<<<<< Updated upstream
=======
>>>>>>> Stashed changes
  @override
  State<MarketNotificationsScreen> createState() => _MarketNotificationsScreenState();
}

class _MarketNotificationsScreenState extends State<MarketNotificationsScreen> {
<<<<<<< Updated upstream
  // SafePulse Brand Colors
  static const Color primaryRed = Color(0xFFD32F2F);
  static const Color accentRed = Color(0xFFFF5252);
  static const Color darkBg = Color(0xFF121212);

  // නිදර්ශන Notifications කිහිපයක් (Mock Data)
  final List<Map<String, dynamic>> _notifications = [
    {
      "title": "New Offer Received!",
      "desc": "Kamal offered Rs. 15,000 for your iPhone 14 Case.",
      "time": "2 mins ago",
      "icon": Icons.local_offer_rounded,
      "isRead": false,
      "category": "Selling"
    },
    {
      "title": "Price Dropped!",
      "desc": "An item in your saved list 'Scientific Calculator' is now cheaper.",
      "time": "1 hour ago",
      "icon": Icons.trending_down_rounded,
      "isRead": false,
      "category": "Buying"
    },
    {
      "title": "Safety Reminder",
      "desc": "Remember to meet near the Campus Library for safe transactions.",
      "time": "3 hours ago",
      "icon": Icons.gpp_good_rounded,
      "isRead": true,
      "category": "All"
    },
    {
      "title": "New Message",
      "desc": "Nuwan sent you a message: 'Is it still available?'",
      "time": "Yesterday",
      "icon": Icons.chat_bubble_rounded,
      "isRead": true,
      "category": "Buying"
    },
  ];
=======
  // Teammate Colors
  static const Color gRedStart = Color(0xFFFF4B4B);
  static const Color gRedMid = Color(0xFFB31217);
  static const Color gDarkEnd = Color(0xFF1B1B1B);
>>>>>>> Stashed changes
=======
  static const Color gRedMid = Color(0xFFB31217);
  static const Color darkEnd = Color(0xFF1B1B1B);
>>>>>>> Stashed changes
=======
  static const Color gRedStart = Color(0xFFFF4B4B);
  static const Color gRedMid = Color(0xFFB31217);
  static const Color gDarkEnd = Color(0xFF1B1B1B);
>>>>>>> Stashed changes

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
<<<<<<< Updated upstream
    final Color pageBg = isDark ? const Color(0xFF0F0F13) : const Color(0xFFF6F7FB);
    final Color cardBg = isDark ? const Color(0xFF1B1B22) : Colors.white;
    final Color textPrimary = isDark ? Colors.white : Colors.black87;
    final Color borderColor = isDark ? const Color(0xFF34343F) : const Color(0xFFE8EAF0);
=======
    final Color pageBg =
        isDark ? const Color(0xFF0F0F13) : const Color(0xFFF6F7FB);
    final Color cardBg = isDark ? const Color(0xFF1B1B22) : Colors.white;
    final Color textPrimary = isDark ? Colors.white : Colors.black87;
    final Color borderColor =
        isDark ? const Color(0xFF34343F) : const Color(0xFFE8EAF0);
>>>>>>> Stashed changes

    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: pageBg,
<<<<<<< Updated upstream
      body: CustomScrollView(
        slivers: [
          // 1. SCROLLABLE HEADER (Same Style as others)
          SliverToBoxAdapter(
            child: Container(
              width: double.infinity, padding: const EdgeInsets.fromLTRB(15, 60, 20, 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(colors: [gRedStart, gRedMid, gDarkEnd], stops: [0.0, 0.62, 1.0]),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(34), bottomRight: Radius.circular(34)),
              ),
              child: Row(children: [
                IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white), onPressed: () => Navigator.pop(context)),
                const Text("Activity Hub", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                const Spacer(),
                const Icon(Icons.notifications_active_outlined, color: Colors.white24, size: 35),
              ]),
            ),
=======
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
<<<<<<< Updated upstream
            gradient: LinearGradient(colors: [Color(0xFFFF4B4B), gRedMid, darkEnd]),
>>>>>>> Stashed changes
          ),
        ),
        title: const Text("Activity Hub", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
            return const Center(child: CircularProgressIndicator(color: gRedMid));
          }

<<<<<<< Updated upstream
          
          StreamBuilder<QuerySnapshot>(
            
            stream: FirebaseFirestore.instance
                .collection('market_notifications')
                .where('userId', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                .orderBy('createdAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator())));
              }

              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(50), child: Text("No new notifications."))));
              }

              return SliverPadding(
                padding: const EdgeInsets.all(20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    return _buildNotificationCard(context, data, cardBg, textP);
                  }, childCount: docs.length),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  
  Widget _buildNotificationCard(BuildContext context, Map data, Color cb, Color tp) {
    bool isChat = data['type'] == 'chat'; 

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cb, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(15),
        leading: CircleAvatar(
          backgroundColor: isChat ? Colors.blue.withOpacity(0.1) : Colors.red.withOpacity(0.1),
          child: Icon(isChat ? Icons.chat_bubble_outline : Icons.sell_outlined, color: isChat ? Colors.blue : Colors.red, size: 20),
        ),
        title: Text(data['title'] ?? "Market Update", style: TextStyle(color: tp, fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Text(data['message'] ?? "", style: const TextStyle(color: Colors.grey, fontSize: 12)),
        trailing: const Icon(Icons.chevron_right, size: 16, color: Colors.grey),
        onTap: () {
          
          if (isChat) {
            Navigator.push(context, MaterialPageRoute(builder: (c) => NegotiationChat(docId: data['itemId'])));
          }
=======
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
                  color: isRead ? cardBg : (isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFFFF9F9)),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isRead ? Colors.transparent : gRedMid.withOpacity(0.2)),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10)],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: CircleAvatar(
                    backgroundColor: isRead ? Colors.grey.shade200 : const Color(0xFFFFF2F2),
                    child: Icon(Icons.chat_bubble_outline_rounded, color: isRead ? Colors.grey : gRedMid, size: 20),
                  ),
                  title: Text(
                    notifData['title'] ?? "Message Alert", 
                    style: TextStyle(
                      color: textPrimary, 
                      fontWeight: isRead ? FontWeight.normal : FontWeight.bold
                    )
                  ),
                  subtitle: Text(notifData['message'] ?? "", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  
                  // --- පියවර:Seen නොවූ පණිවිඩ සඳහා රතු පාට සලකුණ පෙන්වයි ---
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (!isRead)
                        const CircleAvatar(radius: 5, backgroundColor: Colors.red), // රතු තිත
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
>>>>>>> Stashed changes
        },
      ),
=======
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
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 19),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: currentUserId == null
          ? const Center(child: Text("Please login to see notifications"))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('market_notifications')
                  .where('userId', isEqualTo: currentUserId)
<<<<<<< Updated upstream
                 //.orderBy('createdAt', descending: true)//
=======
>>>>>>> Stashed changes
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  debugPrint("Notification Stream Error: ${snapshot.error}");
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Text(
                        "Failed to load notifications",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: textPrimary.withOpacity(0.6)),
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: gRedMid));
                }

                final rawDocs = snapshot.data?.docs ?? [];

                final docs = [...rawDocs];
                docs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;

                  final aTime = aData['createdAt'];
                  final bTime = bData['createdAt'];

                  if (aTime is Timestamp && bTime is Timestamp) {
                    return bTime.compareTo(aTime);
                  }
                  if (aTime is Timestamp) return -1;
                  if (bTime is Timestamp) return 1;
                  return 0;
                });

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_off_outlined, size: 80, color: textPrimary.withOpacity(0.1)),
                        const SizedBox(height: 15),
                        Text(
                          "Your inbox is empty.",
                          style: TextStyle(color: textPrimary.withOpacity(0.4), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 40),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
<<<<<<< Updated upstream
                    var data = docs[index].data() as Map<String, dynamic>;
                    String notificationId = docs[index].id;
                    bool isRead = data['isRead'] ?? false;
                    
                    // Time parsing safety
=======
                    final data = docs[index].data() as Map<String, dynamic>;
                    final String notificationId = docs[index].id;
                    final bool isRead = data['isRead'] ?? false;
                    final String messageType = data['messageType'] ?? 'chat';

>>>>>>> Stashed changes
                    DateTime time;
                    if(data['createdAt'] is Timestamp) {
                      time = (data['createdAt'] as Timestamp).toDate();
                    } else {
                      time = DateTime.now();
                    }

                    IconData leadingIcon;
                    if (messageType == 'rate_seller') {
                      leadingIcon = Icons.star_rounded;
                    } else if (messageType == 'image') {
                      leadingIcon = Icons.image_rounded;
                    } else if (messageType == 'audio') {
                      leadingIcon = Icons.mic_rounded;
                    } else {
                      leadingIcon = Icons.chat_bubble_rounded;
                    }

                    return Dismissible(
                      key: Key(notificationId),
                      direction: DismissDirection.endToStart,
                      onDismissed: (dir) => _deleteNotification(notificationId),
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        margin: const EdgeInsets.only(bottom: 15),
                        decoration: BoxDecoration(color: Colors.red.shade900, borderRadius: BorderRadius.circular(22)),
                        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
                      ),
                      child: GestureDetector(
                        onTap: () async {
                          await _markAsSeen(notificationId);

                          if ((data['messageType'] ?? '') == 'rate_seller') {
                            if (context.mounted) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => RatingScreen(
                                    docId: data['itemId'] ?? '',
                                    sellerId: data['sellerId'] ?? '',
                                    itemName: data['itemName'] ?? 'Item',
                                    itemImage: data['itemImage'] ?? '',
                                  ),
                                ),
                              );
                            }
                          } else {
                            await _navigateToChat(
                              context,
                              itemId: data['itemId'],
                              itemName: data['itemName'],
                              itemImage: data['itemImage'],
                              sellerId: data['sellerId'],
                              buyerId: data['buyerId'],
                            );
                          }
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isRead ? cardBg : (isDark ? const Color(0xFF23232B) : const Color(0xFFFFFAFA)),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: isRead ? borderColor : gRedMid.withOpacity(0.3), width: 1.2),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
                            ],
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: isRead ? Colors.grey.withOpacity(0.1) : gRedMid.withOpacity(0.12),
                                radius: 25,
<<<<<<< Updated upstream
                                child: Icon(Icons.chat_bubble_rounded, color: isRead ? Colors.grey : gRedMid, size: 22),
=======
                                child: Icon(
                                  leadingIcon,
                                  color: isRead ? Colors.grey : gRedMid,
                                  size: 22,
                                ),
>>>>>>> Stashed changes
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
<<<<<<< Updated upstream
                                        Text(
                                          data['title'] ?? "Inquiry Update",
                                          style: TextStyle(color: textPrimary, fontWeight: isRead ? FontWeight.w600 : FontWeight.w900, fontSize: 14.5),
=======
                                        Expanded(
                                          child: Text(
                                            data['title'] ?? "Inquiry Update",
                                            style: TextStyle(
                                              color: textPrimary,
                                              fontWeight: isRead
                                                  ? FontWeight.w600
                                                  : FontWeight.w900,
                                              fontSize: 14.5,
                                            ),
                                          ),
>>>>>>> Stashed changes
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          DateFormat('hh:mm a').format(time),
                                          style: const TextStyle(color: Colors.grey, fontSize: 10),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 5),
                                    if ((data['senderName'] ?? '')
                                        .toString()
                                        .isNotEmpty)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 4),
                                        child: Text(
                                          "From: ${data['senderName']}",
                                          style: TextStyle(
                                            color: textPrimary.withOpacity(0.55),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    Text(
                                      data['message'] ?? "",
                                      maxLines: 2, overflow: TextOverflow.ellipsis,
                                      style: TextStyle(color: textPrimary.withOpacity(0.6), fontSize: 12, fontWeight: isRead ? FontWeight.normal : FontWeight.bold),
                                    ),
                                  ],
                                ),
                              ),
<<<<<<< Updated upstream
                              if(!isRead) Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: CircleAvatar(radius: 4, backgroundColor: gRedStart),
                              ),
=======
                              if (!isRead)
                                const Padding(
                                  padding: EdgeInsets.only(left: 8.0),
                                  child: CircleAvatar(
                                    radius: 4,
                                    backgroundColor: gRedStart,
                                  ),
                                ),
>>>>>>> Stashed changes
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
>>>>>>> Stashed changes
    );
  }
<<<<<<< Updated upstream
=======

<<<<<<< Updated upstream
  void _markAsSeen(String notifId) {
    FirebaseFirestore.instance.collection('market_notifications').doc(notifId).update({'isRead': true});
  }

  void _deleteNotification(String notifId) {
    FirebaseFirestore.instance.collection('market_notifications').doc(notifId).delete();
=======
  Future<void> _markAsSeen(String notifId) async {
    await FirebaseFirestore.instance
        .collection('market_notifications')
        .doc(notifId)
        .update({'isRead': true});
  }

  Future<void> _deleteNotification(String notifId) async {
    await FirebaseFirestore.instance
        .collection('market_notifications')
        .doc(notifId)
        .delete();
>>>>>>> Stashed changes
  }

  Future<void> _navigateToChat(
    BuildContext context, {
    required String? itemId,
    required String? itemName,
    required String? itemImage,
    required String? sellerId,
    required String? buyerId,
  }) async {
    if (itemId == null || itemId.isEmpty) return;

    try {
<<<<<<< Updated upstream
<<<<<<< Updated upstream
      var doc = await FirebaseFirestore.instance.collection('listings').doc(itemId).get();
      if (doc.exists) {
        var itemData = doc.data() as Map<String, dynamic>;
        if (context.mounted) {
          Navigator.push(context, MaterialPageRoute(
            builder: (c) => NegotiationChat(
              docId: itemId,
              itemName: itemData['name'],
              itemPrice: itemData['itemPrice'] ?? itemData['price'],
              itemImage: itemData['image'],
              sellerId: itemData['sellerId'],
=======
      var itemDoc = await FirebaseFirestore.instance.collection('listings').doc(itemId).get();
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
>>>>>>> Stashed changes
            ),
          ));
=======
      String resolvedItemName = itemName ?? 'Item';
      String resolvedItemImage = itemImage ?? '';
      String resolvedSellerId = sellerId ?? '';
      String resolvedBuyerId = buyerId ?? '';
      String resolvedItemPrice = '0';

      final itemDoc = await FirebaseFirestore.instance
          .collection('listings')
          .doc(itemId)
          .get();

      if (itemDoc.exists) {
        final item = itemDoc.data() as Map<String, dynamic>;
        resolvedItemName = item['name'] ?? resolvedItemName;
        resolvedItemImage = item['image'] ?? resolvedItemImage;
        resolvedSellerId = item['sellerId'] ?? resolvedSellerId;
        resolvedItemPrice = item['price']?.toString() ?? '0';

        if (resolvedBuyerId.isEmpty) {
          resolvedBuyerId = item['buyerId'] ?? '';
>>>>>>> Stashed changes
        }
      }

      if (context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (c) => NegotiationChat(
              docId: itemId,
              itemName: resolvedItemName,
              itemPrice: resolvedItemPrice,
              itemImage: resolvedItemImage,
              sellerId: resolvedSellerId,
              buyerId: resolvedBuyerId,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint("Nav Failed: $e");
    }
  }
<<<<<<< Updated upstream
<<<<<<< Updated upstream
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
=======
>>>>>>> Stashed changes
}