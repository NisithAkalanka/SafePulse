import 'dart:convert'; // --- පියවර 1: Base64 decode කිරීමට මෙය අත්‍යවශ්‍යයි ---
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'item_details.dart'; 

class FavoriteSavedScreen extends StatelessWidget {
  final String title;
  final String collectionName; 

  const FavoriteSavedScreen({super.key, required this.title, required this.collectionName});

  static const Color gRedStart = Color(0xFFFF4B4B);
  static const Color gRedMid = Color(0xFFB31217);
  static const Color gDarkEnd = Color(0xFF1B1B1B);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color pageBg = isDark ? const Color(0xFF0F0F13) : const Color(0xFFF6F7FB);
    final Color cardBg = isDark ? const Color(0xFF1B1B22) : Colors.white;
    final Color textPrimary = isDark ? Colors.white : const Color(0xFF1B1B22);
    final Color textSecondary = isDark ? const Color(0xFFB7BBC6) : const Color(0xFF747A86);
    final Color borderColor = isDark ? const Color(0xFF34343F) : const Color(0xFFE8EAF0);

    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: pageBg,
      body: Column(
        children: [
          // PREMIUM CURVED HEADER
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
                      Text(title, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                      const Text("Manage your personally curated campus list", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // REAL-TIME LIST DATA
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection(collectionName)
                  .where('userId', isEqualTo: currentUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: gRedMid));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.bookmark_border_rounded, size: 80, color: textSecondary.withOpacity(0.2)),
                        const SizedBox(height: 10),
                        Text("No items saved here.", style: TextStyle(color: textSecondary)),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 50),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var itemData = docs[index].data() as Map<String, dynamic>;
                    String docId = itemData['listingId'] ?? docs[index].id;
                    return _buildModernListItem(context, docId, itemData, cardBg, textPrimary, borderColor);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- අයිතම පෙන්වන පෙළ (Modern List Tile) ---
  Widget _buildModernListItem(BuildContext context, String docId, Map<String, dynamic> data, Color cb, Color tp, Color bc) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (c) => ItemDetails(
          docId: docId,
          itemName: data['name'],
          itemPrice: data['price'],
          itemImage: data['image'], // Base64 Text එක details වෙත යවයි
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
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
        ),
        child: Row(
          children: [
            // --- පියවර 2: රූපය පෙන්වන කොටස (BASE64 DECODE logic සහිතව) ---
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Container(
                width: 75, height: 75,
                decoration: BoxDecoration(color: Colors.grey[100]),
                // මෙතනින් තමයි පරණ Laptop Image එක ඉවත් කර අලුත් එක හඳුනාගන්නේ
                child: (data['image'] != null && data['image'].toString().length > 100)
                  ? Image.memory(
                      base64Decode(data['image']), // අකුරු රූපයකට හරවයි
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, e, s) => const Icon(Icons.image_not_supported, color: Colors.grey),
                    )
                  : const Icon(Icons.shopping_bag_outlined, color: gRedMid, size: 30),
              ),
            ),
            const SizedBox(width: 15),
            
            // විස්තර පෙන්වන කොටස
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(data['name'] ?? "Saved Ad", style: TextStyle(color: tp, fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1),
                  const SizedBox(height: 5),
                  Text("Rs. ${data['price'] ?? "0.00"}", style: const TextStyle(color: gRedMid, fontWeight: FontWeight.w900)),
                ],
              ),
            ),
           
            const Icon(Icons.arrow_forward_ios_rounded, color: Colors.grey, size: 14),
          ],
        ),
      ),
    );
  }
}