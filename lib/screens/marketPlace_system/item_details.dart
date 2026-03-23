import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'negotiation_chat.dart';

class ItemDetails extends StatefulWidget {
  final String? docId; // මෙය අනිවාර්යයෙන්ම තිබිය යුතුයි
  final String? itemName;
  final String? itemPrice;
  final String? itemImage;
  final String? itemDescription;

  const ItemDetails({
    super.key,
    this.docId, // පරණ පේජ් එකෙන් එන ID එක
    this.itemName,
    this.itemPrice,
    this.itemImage,
    this.itemDescription,
  });

  @override
  State<ItemDetails> createState() => _ItemDetailsState();
}

class _ItemDetailsState extends State<ItemDetails> {
  // SafePulse Branding Colors
  static const Color intenseRed = Color(0xFFE53935);
  static const Color accentPink = Color(0xFFFFF1F1);
  
  bool isFavourited = false;
  bool isSaved = false;

  // Firebase Toggle logic for Favourites & Saved
  void _toggleCollection(String collectionName, bool currentState, Function(bool) updateState) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || widget.docId == null) return;
    
    // ලිස්ට් එකට දත්ත ඇතුලත් කිරීමේදී docId එක භාවිත කරමු
    final uniqueId = "${user.uid}_${widget.docId}";

    if (!currentState) {
      await FirebaseFirestore.instance.collection(collectionName).doc(uniqueId).set({
        'userId': user.uid,
        'listingId': widget.docId, // සැබෑ Item ID එක
        'name': widget.itemName,
        'price': widget.itemPrice,
        'image': widget.itemImage,
        'createdAt': Timestamp.now(),
      });
      _showSnack("Added to $collectionName");
    } else {
      await FirebaseFirestore.instance.collection(collectionName).doc(uniqueId).delete();
      _showSnack("Removed from $collectionName");
    }
    setState(() => updateState(!currentState));
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(milliseconds: 700), behavior: SnackBarBehavior.floating),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: intenseRed, size: 30),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Specifications", style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. PRODUCT IMAGE AREA
            Container(
              height: 280, width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF9F9F9),
                border: Border(bottom: BorderSide(color: intenseRed, width: 2.5)),
              ),
              child: Image.network(widget.itemImage ?? "https://via.placeholder.com/400", fit: BoxFit.cover),
            ),

            Padding(
              padding: const EdgeInsets.all(22.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 2. ITEM NAME & RED PRICE
                  Text(widget.itemName ?? "New Campus Gear", style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold, letterSpacing: -0.5)),
                  const SizedBox(height: 5),
                  Text(widget.itemPrice ?? "Price Info", style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: intenseRed)),

                  const SizedBox(height: 25),

                  // --- 3. MESSENGER BOX (WITH NAVIGATION FIX) ---
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: accentPink,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: intenseRed.withOpacity(0.3), width: 1.2),
                    ),
                    child: Column(
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.messenger_outline_rounded, color: intenseRed, size: 20),
                            SizedBox(width: 10),
                            Text("Send Seller a Message", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black87)),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white, 
                                  borderRadius: BorderRadius.circular(25),
                                  border: Border.all(color: Colors.grey.shade200),
                                ),
                                child: const Text(
                                  "Hello, is this still available?",
                                  style: TextStyle(color: Colors.black54, fontSize: 13),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: intenseRed,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                elevation: 3,
                              ),
                              onPressed: () {
                                // --- පියවර: සියලුම දත්ත (docId ඇතුළුව) මෙතනින් Chat පේජ් එකට යවයි ---
                                Navigator.push(
                                  context, 
                                  MaterialPageRoute(
                                    builder: (context) => NegotiationChat(
                                      docId: widget.docId, // ඉතාම වැදගත්! මෙය නොමැතිව Mark as Sold කළ නොහැක
                                      itemName: widget.itemName,
                                      itemPrice: widget.itemPrice,
                                      itemImage: widget.itemImage,
                                      initialMessage: "Hello, is this still available?",
                                    ),
                                  ),
                                );
                              },
                              child: const Text("Send", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 35),

                  // 4. ACTION ROW
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionCircle(Icons.notifications_active_rounded, "Alerts", false, () {}),
                      _buildActionCircle(
                        isFavourited ? Icons.favorite_rounded : Icons.favorite_border_rounded, 
                        "Favourites", isFavourited, () => _toggleCollection('user_favourites', isFavourited, (v) => isFavourited = v)
                      ),
                      _buildActionCircle(
                        isSaved ? Icons.bookmark_added_rounded : Icons.bookmark_border_rounded, 
                        "Saved", isSaved, () => _toggleCollection('user_saved', isSaved, (v) => isSaved = v)
                      ),
                    ],
                  ),

                  const Divider(height: 50, thickness: 1.2),

                  // 5. DESCRIPTION
                  const Text("Full Description", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: intenseRed)),
                  const SizedBox(height: 10),
                  Text(widget.itemDescription ?? "Verified student gear available for campus deals. Secured meetups suggested.", 
                      style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5)),

                  const Divider(height: 50, thickness: 1.2),

                  // 6. SPECIFICATIONS
                  const Text("Item Specification", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: intenseRed)),
                  const SizedBox(height: 15),
                  _buildSpecRow("Item Status", "Safe Verified"),
                  _buildSpecRow("Delivery", "Hand-to-Hand"),
                  _buildSpecRow("Listing Id", widget.docId != null ? widget.docId!.substring(0,6) : "N/A"),

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCircle(IconData icon, String label, bool isActive, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: isActive ? intenseRed.withOpacity(0.08) : Colors.grey.shade50,
              shape: BoxShape.circle,
              border: Border.all(color: isActive ? intenseRed : Colors.grey.shade200),
            ),
            child: Icon(icon, color: isActive ? intenseRed : Colors.black87, size: 28),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildSpecRow(String left, String right) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(left, style: const TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          Text(right, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}