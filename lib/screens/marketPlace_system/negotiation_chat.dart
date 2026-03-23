import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'rating_screen.dart';

class NegotiationChat extends StatefulWidget {
  // අපි මෙතනට '?' දාන නිසා main.dart එකේදී රතු ඉරි එන්නෙ නැහැ
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

  static const Color primaryRed = Color(0xFFD32F2F);
  static const Color accentRed = Color(0xFFFF5252);

  @override
  void initState() {
    super.initState();
    if (widget.initialMessage != null) {
      _chatHistory.add({"msg": widget.initialMessage, "isMe": true});
    }
  }

  // --- අයිතමය වෙළඳපොලෙන් ඉවත් කිරීමේ function එක ---
  void _confirmAndMarkAsSold() async {
    // docId එක තිබේ නම් පමණක් Firestore එකෙන් මකයි
    if (widget.docId != null && widget.docId!.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('listings') // මෙතන ඔයාගේ collection නම හරියටම තියෙන්න ඕනේ
            .doc(widget.docId)
            .delete(); 
        debugPrint("Success: Item deleted");
      } catch (e) {
        debugPrint("Error: $e");
      }
    }

    // දත්ත මැකුවත් නැතත් ඊළඟ පේජ් එකට ලස්සනට Navigate වෙනවා
    if (mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => RatingScreen(
        itemName: widget.itemName ?? "Product",
        itemImage: widget.itemImage ?? "https://via.placeholder.com/150",
      )));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(decoration: const BoxDecoration(gradient: LinearGradient(colors: [primaryRed, Color(0xFF121212)]))),
        title: Text(widget.itemName ?? "Negotiate", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // PRODUCT SUMMARY BANNER
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(color: Colors.white, border: Border(bottom: BorderSide(color: Colors.grey.shade200))),
            child: Row(
              children: [
                ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.network(widget.itemImage ?? "https://via.placeholder.com/60", width: 50, height: 50, fit: BoxFit.cover)),
                const SizedBox(width: 15),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.itemName ?? "Chat", style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(widget.itemPrice ?? "", style: const TextStyle(color: primaryRed, fontWeight: FontWeight.bold)),
                ])),
                ElevatedButton(
                  onPressed: () {
                    showDialog(context: context, builder: (ctx) => AlertDialog(
                      title: const Text("Transaction Done?"),
                      content: const Text("Did you successfully sell this to the user? This will remove the listing."),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: primaryRed),
                          onPressed: () { 
                            Navigator.pop(ctx); 
                            _confirmAndMarkAsSold(); // මෙන්න මෙතනින් delete එක වෙනවා
                          }, 
                          child: const Text("Confirmed", style: TextStyle(color: Colors.white)),
                        ),
                      ],
                    ));
                  }, 
                  style: ElevatedButton.styleFrom(backgroundColor: primaryRed),
                  child: const Text("Mark Sold", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(15),
              itemCount: _chatHistory.length,
              itemBuilder: (ctx, i) => Align(
                alignment: _chatHistory[i]['isMe'] ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _chatHistory[i]['isMe'] ? primaryRed : Colors.grey[200], 
                    borderRadius: BorderRadius.circular(15)
                  ),
                  child: Text(_chatHistory[i]['msg'], style: TextStyle(color: _chatHistory[i]['isMe'] ? Colors.white : Colors.black87)),
                ),
              ),
            ),
          ),

          // Message Input Field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 35),
            child: Row(
              children: [
                Expanded(child: Container(decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(30)), child: TextField(controller: _msgController, decoration: const InputDecoration(hintText: "Enter a message...", border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 20))))),
                const SizedBox(width: 12),
                GestureDetector(onTap: () { if(_msgController.text.isNotEmpty) setState(() { _chatHistory.add({"msg": _msgController.text, "isMe": true}); _msgController.clear(); }); }, child: const CircleAvatar(backgroundColor: primaryRed, child: Icon(Icons.send, color: Colors.white))),
              ],
            ),
          ),
        ],
      ),
    );
  }
}