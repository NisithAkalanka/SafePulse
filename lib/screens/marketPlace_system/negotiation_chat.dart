import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'rating_screen.dart';
import 'package:intl/intl.dart';

class NegotiationChat extends StatefulWidget {
  final String? docId;
  final String? itemName;
  final String? itemPrice;
  final String? itemImage;
  final String? initialMessage;
  final String? sellerId;

  const NegotiationChat({
    super.key,
    this.docId,
    this.itemName,
    this.itemPrice,
    this.itemImage,
    this.initialMessage,
    this.sellerId,
  });

  @override
  State<NegotiationChat> createState() => _NegotiationChatState();
}

class _NegotiationChatState extends State<NegotiationChat> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  static const Color gRedStart = Color(0xFFFF4B4B);
  static const Color gRedMid = Color(0xFFB31217);
  static const Color gDarkEnd = Color(0xFF1B1B1B);

  @override
  void initState() {
    super.initState();
    if (widget.initialMessage != null && widget.docId != null) {
      _checkAndSendInitialMessage();
    }
  }

  void _checkAndSendInitialMessage() async {
    final chatRef = FirebaseFirestore.instance
        .collection('listings')
        .doc(widget.docId)
        .collection('messages');

    var existingMessages = await chatRef.limit(1).get();
    if (existingMessages.docs.isEmpty && widget.initialMessage != null) {
      _sendMessageToFirestore(widget.initialMessage!);
    }
  }

  // --- Real-time පණිවිඩ යැවීම සහ නොටිෆිකේෂන් සේව් කිරීම ---
  Future<void> _sendMessageToFirestore(String text) async {
    if (widget.docId == null || currentUserId == null) return;

    try {
      // 1. පණිවිඩය සේව් කිරීම
      await FirebaseFirestore.instance
          .collection('listings')
          .doc(widget.docId)
          .collection('messages')
          .add({
            'senderId': currentUserId,
            'msg': text,
            'createdAt': FieldValue.serverTimestamp(),
          });

      // 2. Notification එක සේව් කිරීම (MarketHub එකට)
      // සෙලර් පණිවිඩය එවන්නේ නම් අනෙක් පුද්ගලයා (Buyer) හටත්, බයර් එවන්නේ නම් Seller හටත් notification එක යා යුතුයි
      String receiverId = "";

      if (currentUserId == widget.sellerId) {
        // මම සෙලර් නම්, චැට් එකේ ඉන්න බයර්ව හොයාගන්න අවශ්‍යයි.
        // සරලම ක්‍රමය ලෙස අවසන් පණිවිඩය එවූ විකුණුම්කරු නොවන පුද්ගලයාට යැවිය හැක.
        var messages = await FirebaseFirestore.instance
            .collection('listings')
            .doc(widget.docId)
            .collection('messages')
            .where('senderId', isNotEqualTo: widget.sellerId)
            .limit(1)
            .get();

        if (messages.docs.isNotEmpty) {
          receiverId = messages.docs.first['senderId'];
        }
      } else {
        // මම බයර් නම්, receiver වෙන්නේ widget එකේ ඉන්න seller
        receiverId = widget.sellerId ?? "";
      }

      if (receiverId.isNotEmpty) {
        await FirebaseFirestore.instance.collection('market_notifications').add({
          'userId':
              receiverId, // මෙන්න මේ ID එක නිසා අදාළ පුද්ගලයාගේ Hub එකට මැසේජ් එක යනවා
          'title':
              "Message from ${currentUserId == widget.sellerId ? 'Seller' : 'Buyer'}",
          'message': text,
          'senderId': currentUserId,
          'itemId': widget.docId,
          'isRead': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      _msgController.clear();
      _scrollToBottom();
    } catch (e) {
      debugPrint("Messaging/Notification Error: $e");
    }
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _confirmAndMarkAsSold() async {
    if (widget.docId != null) {
      try {
        await FirebaseFirestore.instance
            .collection('listings')
            .doc(widget.docId)
            .update({'status': 'Sold', 'soldAt': FieldValue.serverTimestamp()});

        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (c) => RatingScreen(
                itemName: widget.itemName ?? "Product",
                itemImage: widget.itemImage ?? "",
              ),
            ),
          );
        }
      } catch (e) {
        debugPrint("Sold Status Error: $e");
      }
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return "Just now";
    DateTime dt = (timestamp as Timestamp).toDate();
    return DateFormat('hh:mm a').format(dt);
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color pageBg = isDark
        ? const Color(0xFF0F0F13)
        : const Color(0xFFF6F7FB);
    final Color cardBg = isDark ? const Color(0xFF1B1B22) : Colors.white;
    final Color textPrimary = isDark ? Colors.white : Colors.black;
    final Color borderColor = isDark
        ? const Color(0xFF34343F)
        : const Color(0xFFE8EAF0);

    final bool isSeller = currentUserId == widget.sellerId;

    return Scaffold(
      backgroundColor: pageBg,
      body: Column(
        children: [
          // Gradient Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 60, 20, 30),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [gRedStart, gRedMid, gDarkEnd],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.62, 1.0],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(34),
                bottomRight: Radius.circular(34),
              ),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      "Inquiry Chat",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: widget.itemImage != null
                            ? Image.network(
                                widget.itemImage!,
                                width: 50,
                                height: 50,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => const Icon(
                                  Icons.image,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.image, color: Colors.white),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.itemName ?? "Product",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "Rs. ${widget.itemPrice ?? "0"}",
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (isSeller)
                        ElevatedButton(
                          onPressed: _confirmAndMarkAsSold,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: gRedMid,
                            shape: const StadiumBorder(),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          child: const Text(
                            "MARK SOLD",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Messages View
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('listings')
                  .doc(widget.docId)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(15, 10, 15, 20),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    var data = docs[i].data() as Map<String, dynamic>;
                    bool isMe = data['senderId'] == currentUserId;

                    return Align(
                      alignment: isMe
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: isMe
                              ? gRedMid
                              : (isDark
                                    ? const Color(0xFF23232B)
                                    : Colors.white),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(20),
                            topRight: const Radius.circular(20),
                            bottomLeft: Radius.circular(isMe ? 20 : 4),
                            bottomRight: Radius.circular(isMe ? 4 : 20),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 10,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: isMe
                              ? CrossAxisAlignment.end
                              : CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['msg'] ?? "",
                              style: TextStyle(
                                color: isMe ? Colors.white : textPrimary,
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatTimestamp(data['createdAt']),
                              style: TextStyle(
                                color: isMe ? Colors.white70 : Colors.grey,
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // Input Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(top: BorderSide(color: borderColor)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F0F13)
                          : const Color(0xFFF3F5F7),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: _msgController,
                      style: TextStyle(color: textPrimary),
                      decoration: const InputDecoration(
                        hintText: "Enter a message...",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 15,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: () {
                    if (_msgController.text.trim().isNotEmpty) {
                      _sendMessageToFirestore(_msgController.text.trim());
                    }
                  },
                  child: const CircleAvatar(
                    backgroundColor: gRedMid,
                    radius: 25,
                    child: Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
