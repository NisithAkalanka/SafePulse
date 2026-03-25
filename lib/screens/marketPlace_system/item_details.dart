import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'negotiation_chat.dart';

class ItemDetails extends StatefulWidget {
  final String? docId;
  final String? itemName;
  final String? itemPrice;
  final String? itemImage;
  final String? itemDescription;
  final String? itemCondition;
  final String? sellerId;

  const ItemDetails({
    super.key,
    this.docId,
    this.itemName,
    this.itemPrice,
    this.itemImage,
    this.itemDescription,
    this.itemCondition,
    this.sellerId,
  });

  @override
  State<ItemDetails> createState() => _ItemDetailsState();
}

class _ItemDetailsState extends State<ItemDetails> {
  bool isAlert = false;
  bool isFav = false;
  bool isSaved = false;
  String sellerName = "Loading...";

  static const Color gRedStart = Color(0xFFFF4B4B);
  static const Color gRedMid = Color(0xFFB31217);
  static const Color gDarkEnd = Color(0xFF1B1B1B);

  @override
  void initState() {
    super.initState();
    _checkInitialStatus();
    _fetchSellerName();
  }

  void _fetchSellerName() async {
    if (widget.sellerId == null || widget.sellerId!.isEmpty) {
      setState(() => sellerName = "Unknown Seller");
      return;
    }
    try {
      var userDoc = await FirebaseFirestore.instance.collection('users').doc(widget.sellerId).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        setState(() {
          sellerName = data?['username'] ?? data?['name'] ?? "Campus User";
        });
      } else {
        setState(() => sellerName = "Verified Seller");
      }
    } catch (e) {
      setState(() => sellerName = "SafePulse User");
    }
  }

  void _checkInitialStatus() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || widget.docId == null) return;
    final docPath = "${uid}_${widget.docId}";

    var favDoc = await FirebaseFirestore.instance.collection('user_favourites').doc(docPath).get();
    if (favDoc.exists) setState(() => isFav = true);

    var savedDoc = await FirebaseFirestore.instance.collection('user_saved').doc(docPath).get();
    if (savedDoc.exists) setState(() => isSaved = true);
  }

  void _toggleCollection(String colName, bool currentStatus, Function(bool) updater) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || widget.docId == null) return;
    final docPath = "${uid}_${widget.docId}";

    try {
      if (currentStatus) {
        await FirebaseFirestore.instance.collection(colName).doc(docPath).delete();
        setState(() => updater(false));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Removed!")));
      } else {
        await FirebaseFirestore.instance.collection(colName).doc(docPath).set({
          'userId': uid,
          'listingId': widget.docId,
          'name': widget.itemName,
          'price': widget.itemPrice,
          'image': widget.itemImage,
          'sellerId': widget.sellerId,
          'createdAt': Timestamp.now(),
        });
        setState(() => updater(true));
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Saved Successfully!")));
      }
    } catch (e) {
      debugPrint("Error toggling: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color pageBg = isDark ? const Color(0xFF0F0F13) : const Color(0xFFF6F7FB);
    final Color cardBg = isDark ? const Color(0xFF1B1B22) : Colors.white;
    final Color textPrimary = isDark ? Colors.white : const Color(0xFF1B1B22);
    final Color textSecondary = isDark ? const Color(0xFFB7BBC6) : const Color(0xFF747A86);
    final Color borderColor = isDark ? const Color(0xFF34343F) : const Color(0xFFE8EAF0);

    return Scaffold(
      backgroundColor: pageBg,
      
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            
            Container(
              width: double.infinity,
              padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top), // Status bar space
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [gRedStart, gRedMid, gDarkEnd],
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  stops: [0.0, 0.62, 1.0],
                ),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(34), bottomRight: Radius.circular(34)),
              ),
              child: Column(
                children: [
                  // --- Custom AppBar Row ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Center(
                            child: Text(
                              "Item Details",
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 48), 
                      ],
                    ),
                  ),
                  // --- Image Area ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(30, 20, 30, 40),
                    child: Hero(
                      tag: widget.docId ?? "img",
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.network(
                          widget.itemImage ?? "",
                          height: 250, width: double.infinity, fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => const Icon(Icons.image, color: Colors.white38, size: 60),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.itemName ?? "Product Name", style: TextStyle(color: textPrimary, fontSize: 26, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 6),
                  
                  
                  Text("Rs. ${widget.itemPrice ?? "0"}", style: const TextStyle(color: gRedStart, fontSize: 28, fontWeight: FontWeight.w900)),

                  const SizedBox(height: 25),

                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF23232B) : const Color(0xFFFFF1F1),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: borderColor),
                    ),
                    child: Row(
                      children: [
                        Expanded(child: Text("Is this still available?", style: TextStyle(color: textSecondary, fontWeight: FontWeight.w600, fontSize: 13.5))),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: gRedMid, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                          onPressed: () {
                            Navigator.push(context, MaterialPageRoute(builder: (c) => NegotiationChat(
                              docId: widget.docId, itemName: widget.itemName, itemPrice: widget.itemPrice, itemImage: widget.itemImage, initialMessage: "Hi, is this still available?",
                            )));
                          },
                          child: const Text("CHAT", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 35),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildInteractiveCircle(Icons.notifications_active_rounded, "Alert", isAlert, () => setState(() => isAlert = !isAlert), borderColor, cardBg),
                      _buildInteractiveCircle(Icons.favorite_rounded, "Fav", isFav, () => _toggleCollection('user_favourites', isFav, (val) => isFav = val), borderColor, cardBg),
                      _buildInteractiveCircle(Icons.bookmark_added_rounded, "Save", isSaved, () => _toggleCollection('user_saved', isSaved, (val) => isSaved = val), borderColor, cardBg),
                    ],
                  ),

                  const SizedBox(height: 40),

                  Text("Description", style: TextStyle(color: gRedStart, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Text(
                    (widget.itemDescription == null || widget.itemDescription!.isEmpty) 
                        ? "No description provided." 
                        : widget.itemDescription!,
                    style: TextStyle(color: textSecondary, fontSize: 15, height: 1.6, fontWeight: FontWeight.w500),
                  ),
                  
                  const Divider(height: 60, thickness: 0.8),

                  _buildSpecRow("Condition", widget.itemCondition ?? "Used", textSecondary, textPrimary),
                  _buildSpecRow("Seller Information", sellerName, textSecondary, textPrimary),
                  _buildSpecRow("Item ID", widget.docId != null ? "#${widget.docId!.substring(0, 6)}" : "#N/A", textSecondary, textPrimary),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInteractiveCircle(IconData icon, String label, bool active, VoidCallback onTap, Color bc, Color cardBg) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: active ? gRedStart.withOpacity(0.15) : cardBg,
              shape: BoxShape.circle,
              border: Border.all(color: active ? gRedStart : bc),
            ),
            child: Icon(icon, color: active ? gRedStart : Colors.grey, size: 24),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(color: active ? gRedStart : Colors.grey, fontSize: 11, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String l, String r, Color s, Color p) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(l, style: TextStyle(color: s, fontWeight: FontWeight.w600, fontSize: 15)),
          Expanded(child: Text(r, textAlign: TextAlign.right, style: TextStyle(color: p, fontWeight: FontWeight.w900, fontSize: 15))),
        ],
      ),
    );
  }
}