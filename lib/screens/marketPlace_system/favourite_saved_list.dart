import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'item_details.dart'; 

class FavoriteSavedScreen extends StatelessWidget {
  final String title;
  final String collectionName; // 'user_favourites' හෝ 'user_saved'

  const FavoriteSavedScreen({super.key, required this.title, required this.collectionName});

  // Teammate's Style Branding Colors
  static const Color gRedStart = Color(0xFFFF4B4B);
  static const Color gRedMid = Color(0xFFB31217);
  static const Color gDarkEnd = Color(0xFF1B1B1B);

  @override
  Widget build(BuildContext context) {
    // --- Dark Mode awareness ---
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color pageBg = isDark ? const Color(0xFF0F0F13) : const Color(0xFFF6F7FB);
    final Color cardBg = isDark ? const Color(0xFF1B1B22) : Colors.white;
    final Color textPrimary = isDark ? Colors.white : const Color(0xFF1B1B22);
    final Color textSecondary = isDark ? const Color(0xFFB7BBC6) : const Color(0xFF747A86);
    final Color borderColor = isDark ? const Color(0xFF34343F) : const Color(0xFFE8EAF0);

    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: pageBg,
      
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 60, 20, 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [gRedStart, gRedMid, gDarkEnd],
                  stops: [0.0, 0.62, 1.0],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(34),
                  bottomRight: Radius.circular(34),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title, 
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)
                        ),
                        const Text(
                          "Your personally curated campus list", 
                          style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(collectionName)
                  .where('userId', isEqualTo: currentUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 100),
                    child: Center(child: CircularProgressIndicator(color: gRedMid)),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 100),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.layers_clear_outlined, size: 80, color: textSecondary.withOpacity(0.3)),
                          const SizedBox(height: 10),
                          Text("No items found in $title", style: TextStyle(color: textSecondary, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var item = docs[index].data() as Map<String, dynamic>;
                    String docId = item['listingId'] ?? docs[index].id;

                    return _buildModernListItem(context, docId, item, cardBg, textPrimary, textSecondary, borderColor);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- Mini-Card Style Item Row ---
  Widget _buildModernListItem(BuildContext context, String docId, Map<String, dynamic> data, Color cb, Color tp, Color ts, Color bc) {
    return GestureDetector(
      onTap: () {
        
        Navigator.push(context, MaterialPageRoute(builder: (c) => ItemDetails(
          docId: docId,
          itemName: data['name'],
          itemPrice: data['price'],
          itemImage: data['image'],
          
          sellerId: data['sellerId'], 
        )));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 15),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cb,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: bc),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          children: [
            
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.network(
                data['image'] ?? "",
                width: 75, height: 75, fit: BoxFit.cover,
                errorBuilder: (c, e, s) => Container(
                  width: 75, height: 75,
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(15)),
                  child: const Icon(Icons.image, color: Colors.grey),
                ),
              ),
            ),
            const SizedBox(width: 15),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'] ?? "Unknown Item", 
                    style: TextStyle(color: tp, fontWeight: FontWeight.w800, fontSize: 16),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "Rs. ${data['price'] ?? "0.00"}", 
                    style: const TextStyle(color: gRedMid, fontWeight: FontWeight.w900, fontSize: 15),
                  ),
                ],
              ),
            ),
           
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: gRedMid.withOpacity(0.1), shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward_ios_rounded, color: gRedMid, size: 14),
            )
          ],
        ),
      ),
    );
  }
}