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
  State<NegotiationChat> createState() => _NegotiationChatState();
}

class _NegotiationChatState extends State<NegotiationChat> {
  final TextEditingController _msgController = TextEditingController();
  final List<Map<String, dynamic>> _chatHistory = [];

  // Branding Colors
  static const Color gRedStart = Color(0xFFFF4B4B);
  static const Color gRedMid = Color(0xFFB31217);
  static const Color gDarkEnd = Color(0xFF1B1B1B);

  @override
  void initState() {
    super.initState();
    if (widget.initialMessage != null) {
      _chatHistory.add({"msg": widget.initialMessage, "isMe": true});
    }
  }

  void _sendMessage() {
    String text = _msgController.text.trim();
    if (text.isEmpty) text = "Hi, is this available?";

    setState(() {
      _chatHistory.add({
        "msg": text,
        "isMe": true,
      });
      _msgController.clear();
    });
  }

  void _confirmAndMarkAsSold() async {
    if (widget.docId != null) {
      await FirebaseFirestore.instance.collection('listings').doc(widget.docId).delete();
      if (mounted) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (c) => RatingScreen(
          itemName: widget.itemName ?? "Product",
          itemImage: widget.itemImage ?? "",
        )));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // --- Adaptive Colors for Dark Mode ---
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color pageBg = isDark ? const Color(0xFF0F0F13) : const Color(0xFFF6F7FB);
    final Color cardBg = isDark ? const Color(0xFF1B1B22) : Colors.white;
    final Color textPrimary = isDark ? Colors.white : Colors.black;
    final Color textSecondary = isDark ? Colors.white70 : Colors.black87;
    final Color borderColor = isDark ? const Color(0xFF34343F) : const Color(0xFFE8EAF0);

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
        title: Text(widget.itemName ?? "Chat", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // 1. Context Banner Area
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cardBg,
              border: Border(bottom: BorderSide(color: borderColor)),
            ),
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
                      Text(widget.itemName ?? "Inquiry", style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold)),
                      Text("Rs. ${widget.itemPrice ?? "0"}", style: const TextStyle(color: gRedMid, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
                ElevatedButton(
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
              ],
            ),
          ),

          // 2. Chat Bubble Stream
          Expanded(
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
                );
              },
            ),
          ),

          // 3. Footer Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 35),
            decoration: BoxDecoration(color: cardBg, border: Border(top: BorderSide(color: borderColor))),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : const Color(0xFFF3F5F7), borderRadius: BorderRadius.circular(30)),
                    child: TextField(
                      controller: _msgController,
                      style: TextStyle(color: textPrimary),
                      decoration: const InputDecoration(
                        hintText: "Enter your offer or message...",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
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