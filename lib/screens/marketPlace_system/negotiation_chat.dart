import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'rating_screen.dart';

class NegotiationChat extends StatefulWidget {
  final String? docId;
  final String? itemName;
  final String? itemPrice;
  final String? itemImage;
  final String? initialMessage;

  const NegotiationChat({
    super.key,
    this.docId,
    this.itemName,
    this.itemPrice,
    this.itemImage,
    this.initialMessage,
  });

  @override
  State<NegotiationChat> createState() => _NegotiationChatState();
}

class _NegotiationChatState extends State<NegotiationChat> {
  final TextEditingController _msgController = TextEditingController();
  final List<Map<String, dynamic>> _chatHistory = [];

  static const Color primaryRed = Color(0xFFB31217);
  static const Color accentRed = Color(0xFFFF4B4B);

  @override
  void initState() {
    super.initState();
    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      _chatHistory.add({
        "msg": widget.initialMessage,
        "isMe": true,
      });
    }
  }

  void _sendMessage() {
    String text = _msgController.text.trim();
    if (text.isEmpty && _chatHistory.isEmpty) text = "Is this still available?";
    if (text.isEmpty) return;

    setState(() {
      _chatHistory.add({
        "msg": text,
        "isMe": true,
      });
      _msgController.clear();
    });
  }

  Future<void> _deleteItemAndProceed() async {
    if (widget.docId != null) {
      try {
        await FirebaseFirestore.instance.collection('listings').doc(widget.docId).delete();
        debugPrint("Product removed successfully.");
      } catch (e) {
        debugPrint("Error: $e");
      }
    }

    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => RatingScreen(
        itemName: widget.itemName ?? "Product",
        itemImage: widget.itemImage ?? "https://via.placeholder.com/150",
      )));
    }
  }

  void _showMarkAsSoldDialog(Color dialogBg, Color txtPrimary) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: dialogBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
        title: Text("Success Trade?", style: TextStyle(color: txtPrimary)),
        content: Text(
          "Once you click confirm, this item will be permanently deleted from the database.",
          style: TextStyle(color: txtPrimary.withOpacity(0.7)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx), 
            child: const Text("Cancel", style: TextStyle(color: Colors.grey))
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryRed),
            onPressed: () {
              Navigator.pop(ctx);
              _deleteItemAndProceed();
            },
            child: const Text("Confirmed", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // --- Dark Mode Awareness ---
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color pageBg = isDark ? const Color(0xFF0F0F13) : const Color(0xFFF6F7FB);
    final Color cardBg = isDark ? const Color(0xFF1B1B22) : Colors.white;
    final Color textPrimary = isDark ? Colors.white : Colors.black87;
    final Color inputBg = isDark ? const Color(0xFF25252D) : const Color(0xFFF3F5F7);
    final Color bottomNavBg = isDark ? const Color(0xFF14141A) : Colors.white;

    return Scaffold(
      backgroundColor: pageBg,
      body: Column(
        children: [
          // 1. Curved Gradient Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 65, 18, 25),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [accentRed, primaryRed, Color(0xFF1B1B1B)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
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
                    const Text("Negotiation Chat", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  margin: const EdgeInsets.only(top: 15),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 55,
                        height: 55,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(
                            widget.itemImage ?? "https://via.placeholder.com/150",
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, e, s) => Container(color: Colors.white10, child: const Icon(Icons.image, color: Colors.white24)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.itemName ?? "Product",
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 3),
                            Text(
                              widget.itemPrice ?? "",
                              style: const TextStyle(color: Colors.white70, fontSize: 12.5, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          shape: const StadiumBorder(),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                        ),
                        onPressed: () => _showMarkAsSoldDialog(cardBg, textPrimary),
                        child: const Text("MARK SOLD", style: TextStyle(fontSize: 10, color: primaryRed, fontWeight: FontWeight.w900)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 2. Dynamic Chat View
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _chatHistory.length,
              itemBuilder: (context, index) {
                final chat = _chatHistory[index];
                return Align(
                  alignment: Alignment.centerRight,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(20),
                        topRight: Radius.circular(20),
                        bottomLeft: Radius.circular(20),
                        bottomRight: Radius.circular(4),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isDark ? Colors.black26 : Colors.black.withOpacity(0.04), 
                          blurRadius: 4
                        )
                      ],
                    ),
                    child: Text(
                      chat['msg'], 
                      style: TextStyle(fontWeight: FontWeight.w600, color: textPrimary)
                    ),
                  ),
                );
              },
            ),
          ),

          // 3. Persistent Input Field
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 35),
            color: bottomNavBg,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(color: inputBg, borderRadius: BorderRadius.circular(25)),
                    child: TextField(
                      controller: _msgController,
                      style: TextStyle(color: textPrimary),
                      decoration: InputDecoration(
                        hintText: "Enter a message...", 
                        hintStyle: TextStyle(color: textPrimary.withOpacity(0.4)),
                        border: InputBorder.none, 
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18)
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _sendMessage,
                  child: const CircleAvatar(
                    backgroundColor: primaryRed, 
                    radius: 24, 
                    child: Icon(Icons.send_rounded, color: Colors.white, size: 20)
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