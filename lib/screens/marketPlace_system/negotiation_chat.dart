import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'rating_screen.dart';

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
 State<NegotiationChat> createState() => _MarketplaceNegotiationChatState();
}

class _MarketplaceNegotiationChatState extends State<NegotiationChat> {
  final TextEditingController _msgController = TextEditingController();
  final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

  // Branding Colors
  static const Color gRedStart = Color(0xFFFF4B4B);
  static const Color gRedMid = Color(0xFFB31217);
  static const Color gDarkEnd = Color(0xFF1B1B1B);

  @override
  void initState() {
    super.initState();
    // චැට් එක ආරම්භයේදීම මුල් පණිවිඩය ඇත්නම් එය සජීවීව සේව් කිරීමට උත්සාහ කරයි
    if (widget.initialMessage != null && widget.docId != null) {
      _checkAndSendInitialMessage();
    }
  }

  // පළමු වරට පණිවිඩයක් ලැබෙන විට පමණක් එය Firestore එකට යැවීමේ Logic එක
  void _checkAndSendInitialMessage() async {
    final chatRef = FirebaseFirestore.instance
        .collection('listings')
        .doc(widget.docId)
        .collection('messages');
        
    var existingMessages = await chatRef.limit(1).get();
    
    // චැට් එක අලුත්ම එකක් නම් (හිස් නම්) පමණක් initial message එක පෝස්ට් කරයි
    if (existingMessages.docs.isEmpty) {
      _sendMessageToFirestore(widget.initialMessage!);
    }
  }

  // --- Real-time Message යැවීමේ ප්‍රධාන කොටස ---
  Future<void> _sendMessageToFirestore(String text) async {
    if (widget.docId == null || currentUserId == null) return;

    try {
      // මෙය එක උපාංගයකින් කළ විට සැනින් Firestore එකට දත්ත එක්වේ
      await FirebaseFirestore.instance
          .collection('listings')
          .doc(widget.docId)
          .collection('messages')
          .add({
        'senderId': currentUserId,
        'msg': text,
        'createdAt': FieldValue.serverTimestamp(), // කාලය අනුව පේළි ගැසීමට අත්‍යවශ්‍යයි
      });
    } catch (e) {
      debugPrint("Messaging Error: $e");
    }
  }

  void _sendMessage() {
    String text = _msgController.text.trim();
<<<<<<< Updated upstream
    if (text.isEmpty) text = "Hi, is this available?";

    setState(() {
      _chatHistory.add({
        "msg": text,
        "isMe": true,
      });
      _msgController.clear();
    });
=======
    if (text.isEmpty && widget.initialMessage == null) return;
    
    // ටයිප් කර ඇත්නම් එය ද, හිස්ව බටන් එක එබුවහොත් default message එක ද යවයි
    _sendMessageToFirestore(text.isEmpty ? "Hi, is this still available?" : text);
    _msgController.clear();
>>>>>>> Stashed changes
  }

  void _confirmAndMarkAsSold() async {
    if (widget.docId != null) {
<<<<<<< Updated upstream
      await FirebaseFirestore.instance.collection('listings').doc(widget.docId).delete();
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => RatingScreen(
          itemName: widget.itemName ?? "Product",
          itemImage: widget.itemImage ?? "",
        )));
=======
      try {
        await FirebaseFirestore.instance
            .collection('listings')
            .doc(widget.docId)
            .update({
          'status': 'Sold',
          'soldAt': FieldValue.serverTimestamp(),
        });

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
        debugPrint("Update status failed: $e");
>>>>>>> Stashed changes
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color pageBg = isDark ? const Color(0xFF0F0F13) : const Color(0xFFF6F7FB);
    final Color cardBg = isDark ? const Color(0xFF1B1B22) : Colors.white;
    final Color textPrimary = isDark ? Colors.white : Colors.black;
    final Color textSecondary = isDark ? Colors.white70 : Colors.black87;
    final Color borderColor = isDark ? const Color(0xFF34343F) : const Color(0xFFE8EAF0);
<<<<<<< Updated upstream
=======

    // සෙලර් පරීක්ෂාව
    final bool isSeller = currentUserId != null && currentUserId == widget.sellerId;
>>>>>>> Stashed changes

    return Scaffold(
      backgroundColor: pageBg,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [gRedStart, gRedMid, gDarkEnd],
              begin: Alignment.topCenter, end: Alignment.bottomCenter, stops: [0.0, 0.62, 1.0],
            ),
          ),
        ),
<<<<<<< Updated upstream
        title: Text(widget.itemName ?? "Chat", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.white),
=======
        elevation: 0,
        title: Text(widget.itemName ?? "Chat", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
>>>>>>> Stashed changes
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Banner Area (භාණ්ඩයේ තොරතුරු පෙන්වන කොටස)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: cardBg, border: Border(bottom: BorderSide(color: borderColor))),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: (widget.itemImage != null && widget.itemImage!.length > 100)
                      ? Image.memory(base64Decode(widget.itemImage!), width: 50, height: 50, fit: BoxFit.cover)
                      : const Icon(Icons.image, size: 50, color: Colors.grey),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
<<<<<<< Updated upstream
                      Text(widget.itemName ?? "Inquiry", style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
=======
                      Text(widget.itemName ?? "Product Inquiry", style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
>>>>>>> Stashed changes
                      Text("Rs. ${widget.itemPrice ?? "0"}", style: const TextStyle(color: gRedMid, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
                ElevatedButton(
<<<<<<< Updated upstream
                  onPressed: () {
                    // --- English Confirmation Dialog Box ---
                    showDialog(context: context, builder: (ctx) => AlertDialog(
                      backgroundColor: cardBg,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                      title: Text("Transaction Success?", style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
                      content: Text(
                        "Clicking confirm will permanently remove this item from the system.", 
                        style: TextStyle(color: textSecondary, fontSize: 14)
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
                        ElevatedButton(
                          onPressed: _confirmAndMarkAsSold, 
                          style: ElevatedButton.styleFrom(backgroundColor: gRedMid), 
                          child: const Text("CONFIRM", style: TextStyle(color: Colors.white))
                        ),
                      ],
                    ));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black87),
                  child: const Text("MARK SOLD", style: TextStyle(color: Colors.white, fontSize: 10)),
                )
=======
                  onPressed: isSeller ? () {
                    showDialog(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        backgroundColor: cardBg,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                        title: Text("Transaction Success?", style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
                        content: Text("Marking this as sold will remove the listing for others.", style: TextStyle(color: textSecondary, fontSize: 14)),
                        actions: [
                          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCEL")),
                          ElevatedButton(onPressed: _confirmAndMarkAsSold, style: ElevatedButton.styleFrom(backgroundColor: gRedMid), child: const Text("CONFIRM", style: TextStyle(color: Colors.white))),
                        ],
                      ),
                    );
                  } : null, // බයර් හට ඉබේම Disabled වේ
                  style: ElevatedButton.styleFrom(backgroundColor: isSeller ? Colors.black87 : Colors.grey.withOpacity(0.3)),
                  child: const Text("MARK SOLD", style: TextStyle(color: Colors.white, fontSize: 10)),
                ),
>>>>>>> Stashed changes
              ],
            ),
          ),

          // --- වැදගත්ම කොටස: උපාංග දෙකක මැසේජ් සජීවීව පෙන්වන STREAM BUILDER ---
          Expanded(
<<<<<<< Updated upstream
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: _chatHistory.length,
              itemBuilder: (ctx, i) {
                bool isMe = _chatHistory[i]['isMe'];
                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isMe ? gRedMid : (isDark ? Colors.white10 : Colors.grey[200]),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(18),
                        topRight: const Radius.circular(18),
                        bottomLeft: Radius.circular(isMe ? 18 : 2),
                        bottomRight: Radius.circular(isMe ? 2 : 18),
                      ),
                    ),
                    child: Text(
                      _chatHistory[i]['msg'],
                      style: TextStyle(color: isMe ? Colors.white : textPrimary, fontWeight: FontWeight.w500),
                    ),
                  ),
=======
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('listings')
                  .doc(widget.docId)
                  .collection('messages')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data?.docs ?? [];
                
                return ListView.builder(
                  padding: const EdgeInsets.all(15),
                  reverse: true,
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    var data = docs[i].data() as Map<String, dynamic>;
                    bool isMe = data['senderId'] == currentUserId;
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: isMe ? gRedMid : (isDark ? Colors.white10 : Colors.grey[200]),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(18), topRight: const Radius.circular(18),
                            bottomLeft: Radius.circular(isMe ? 18 : 2), bottomRight: Radius.circular(isMe ? 2 : 18),
                          ),
                        ),
                        child: Text(data['msg'] ?? "", style: TextStyle(color: isMe ? Colors.white : textPrimary, fontWeight: FontWeight.w500)),
                      ),
                    );
                  },
>>>>>>> Stashed changes
                );
              },
            ),
          ),

          // Message input bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 35),
            decoration: BoxDecoration(color: cardBg, border: Border(top: BorderSide(color: borderColor))),
            child: Row(
              children: [
                Expanded(
                  child: Container(
<<<<<<< Updated upstream
                    decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F5F7), borderRadius: BorderRadius.circular(30)),
                    child: TextField(
                      controller: _msgController,
                      style: TextStyle(color: textPrimary),
                      decoration: const InputDecoration(
                        hintText: "Enter your offer or message...",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      ),
=======
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F5F7),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: TextField(
                      controller: _msgController,
                      style: TextStyle(color: textPrimary),
                      decoration: const InputDecoration(hintText: "Make an offer...", border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15)),
>>>>>>> Stashed changes
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
<<<<<<< Updated upstream
                  onTap: _sendMessage,
=======
                  onTap: _sendMessage, // මවුලය: දැන් සජීවීව පෝස්ට් කරන්නේ මෙතැනිනි
>>>>>>> Stashed changes
                  child: const CircleAvatar(backgroundColor: gRedMid, radius: 24, child: Icon(Icons.send_rounded, color: Colors.white, size: 20)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}