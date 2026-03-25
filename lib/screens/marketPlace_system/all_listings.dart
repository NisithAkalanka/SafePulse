import 'dart:convert'; // --- පියවර 1: මෙය අනිවාර්යයෙන්ම එක් කරන්න ---
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'item_details.dart';

class AllListingsScreen extends StatelessWidget {
  const AllListingsScreen({super.key});

  static const Color gRedStart = Color(0xFFFF4B4B);
  static const Color gRedMid = Color(0xFFB31217);
  static const Color gDarkEnd = Color(0xFF1B1B1B);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color pageBg = isDark ? const Color(0xFF0F0F13) : const Color(0xFFF6F7FB);
    final Color textPrimary = isDark ? Colors.white : const Color(0xFF1B1B22);
    final Color textSecondary = isDark ? const Color(0xFFB7BBC6) : const Color(0xFF747A86);

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
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Campus Explorer", 
                          style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)
                        ),
                        Text(
                          "Browse every listing in one place", 
                          style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.grid_view_rounded, color: Colors.white24, size: 40),
                ],
              ),
            ),

            const SizedBox(height: 10),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('listings').snapshots(),
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
                      child: Text(
                        "No products found on campus.",
                        style: TextStyle(color: textSecondary, fontWeight: FontWeight.bold),
                      ),
                    ),
                  );
                }

                final docs = snapshot.data!.docs.toList();
                docs.sort((a, b) {
                  var dataA = a.data() as Map<String, dynamic>;
                  var dataB = b.data() as Map<String, dynamic>;
                  Timestamp? tA = dataA['timestamp'] ?? dataA['createdAt'];
                  Timestamp? tB = dataB['timestamp'] ?? dataB['createdAt'];
                  if (tA == null || tB == null) return 0;
                  return tB.compareTo(tA);
                });

                return GridView.builder(
                  shrinkWrap: true, 
                  physics: const NeverScrollableScrollPhysics(), 
                  padding: const EdgeInsets.all(20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, 
                    crossAxisSpacing: 15, 
                    mainAxisSpacing: 15, 
                    childAspectRatio: 0.82, 
                  ),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    return _buildProductCard(context, docs[index].id, data);
                  },
                );
              },
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, String docId, Map<String, dynamic> data) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (c) => ItemDetails(
          docId: docId,
          itemName: data['name'],
          itemPrice: data['price'],
          itemImage: data['image'],
          itemDescription: data['description'],
          itemCondition: data['condition'],
          sellerId: data['sellerId'],
        )));
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFB31217), Color(0xFF101010)],
          ),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(6.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  // --- පියවර 2: රූපය පෙන්වන කොටස (BASE64 Logic) මාරු කර ඇත ---
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(color: Colors.black12),
                    child: (data['image'] != null && data['image'].toString().length > 100)
                      ? Image.memory(
                          base64Decode(data['image']), // Base64 අකුරු රූපයකට හරවයි
                          fit: BoxFit.cover,
                          errorBuilder: (c, e, s) => const Icon(Icons.broken_image, color: Colors.white24),
                        )
                      : const Center(child: Icon(Icons.image, color: Colors.white24, size: 40)),
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data['name'] ?? "Item", 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), 
                    maxLines: 1, overflow: TextOverflow.ellipsis
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "Rs. ${data['price'] ?? "0"}", 
                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}