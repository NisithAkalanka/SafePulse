import 'package:flutter/material.dart';
import 'rating_screen.dart';

class NegotiationChat extends StatefulWidget {
  final String? itemName;
  final String? itemPrice;
  final String? itemImage;
  final String? initialMessage; // කලින් පේජ් එකෙන් එවන පණිවිඩය ලබා ගැනීමට

  const NegotiationChat({
    super.key,
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

  static const Color primaryRed = Color(0xFFD32F2F);
  static const Color accentRed = Color(0xFFFF5252);
  static const Color chatBg = Color(0xFFFFF8F8);

  @override
  void initState() {
    super.initState();
    // පේජ් එක විවෘත වූ සැණින් (කලින් එකෙන් එවපු පණිවිඩය තිබේ නම්) එය ලිස්ට් එකට එක් කරයි
    if (widget.initialMessage != null && widget.initialMessage!.isNotEmpty) {
      _chatHistory.add({
        "msg": widget.initialMessage,
        "isMe": true,
        "time": "${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}"
      });
    }
  }

  void _sendMessage() {
    String text = _msgController.text.trim();
    // හිස්ව තිබියදී send කරොත් යවන මැසේජ් එක
    if (text.isEmpty) {
      text = "Is this still available?";
    }

    setState(() {
      _chatHistory.add({
        "msg": text,
        "isMe": true,
        "time": "${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}"
      });
      _msgController.clear();
    });
  }

  // "Mark as Sold" Logic (පරණ විදියටම තැබුවා)
  void _showMarkAsSoldDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Transaction Done?"),
        content: const Text("Did you successfully sell this item to this user?"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryRed),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(context, MaterialPageRoute(builder: (context) => RatingScreen(
                itemName: widget.itemName ?? "Item",
                itemImage: widget.itemImage ?? "https://via.placeholder.com/150",
              )));
            },
            child: const Text("Confirmed", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [primaryRed, accentRed]),
          ),
        ),
        elevation: 0,
        title: const Text("Negotiate Chat", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // PRODUCT INFORMATION BANNER
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: primaryRed.withOpacity(0.1)))),
            child: Row(
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(widget.itemImage ?? "https://via.placeholder.com/50", width: 55, height: 55, fit: BoxFit.cover)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.itemName ?? "Product Inquiry", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  Text(widget.itemPrice ?? "Price Info", style: const TextStyle(color: primaryRed, fontWeight: FontWeight.bold, fontSize: 13)),
                ])),
                ElevatedButton(onPressed: _showMarkAsSoldDialog, style: ElevatedButton.styleFrom(backgroundColor: Colors.black87, shape: const StadiumBorder()), child: const Text("Mark Sold", style: TextStyle(color: Colors.white, fontSize: 10))),
              ],
            ),
          ),

          // CHAT AREA (පළමු පණිවිඩය කෙලින්ම දිස්වේ)
          Expanded(
            child: Container(
              color: chatBg,
              child: ListView.builder(
                padding: const EdgeInsets.all(15),
                itemCount: _chatHistory.length,
                itemBuilder: (context, index) {
                  final chat = _chatHistory[index];
                  return Align(
                    alignment: Alignment.centerRight,
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                      decoration: const BoxDecoration(
                        color: primaryRed,
                        borderRadius: BorderRadius.only(topLeft: Radius.circular(15), topRight: Radius.circular(15), bottomLeft: Radius.circular(15), bottomRight: Radius.circular(2)),
                      ),
                      child: Text(chat['msg'], style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
                    ),
                  );
                },
              ),
            ),
          ),

          // TYPING FIELD
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 35),
            color: Colors.white,
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(color: primaryRed.withOpacity(0.05), borderRadius: BorderRadius.circular(30), border: Border.all(color: primaryRed.withOpacity(0.15))),
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: TextField(controller: _msgController, decoration: const InputDecoration(hintText: "Enter a message...", border: InputBorder.none)),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(onTap: _sendMessage, child: const CircleAvatar(backgroundColor: primaryRed, radius: 24, child: Icon(Icons.send_rounded, color: Colors.white, size: 20))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}