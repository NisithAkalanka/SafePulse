import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageListingsScreen extends StatelessWidget {
  const ManageListingsScreen({super.key});

  static const Color primaryRed = Color(0xFFD32F2F);
  static const Color darkBlack = Color(0xFF1A1A1A);

  @override
  Widget build(BuildContext context) {
    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [primaryRed, darkBlack]),
          ),
        ),
        title: const Text("Manage My Listings", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('listings')
            .where('sellerId', isEqualTo: currentUserId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: primaryRed));
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return const Center(child: Text("You haven't posted any items."));

          return ListView.builder(
            padding: const EdgeInsets.all(15),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              String docId = docs[index].id;

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8F8), // ලා රෝස පැහැති පසුබිම
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(15),
                      child: Image.network(
                        data['image'] ?? "", 
                        width: 70, height: 70, fit: BoxFit.cover,
                        errorBuilder: (c,e,s) => Container(color: Colors.grey[200], child: const Icon(Icons.image)),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(data['name'] ?? "", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(data['price'] ?? "", style: const TextStyle(color: primaryRed, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    
                    // --- මෙතනින් තමයි බොත්තම් දෙක (Edit & Delete) එකතු කරලා තියෙන්නේ ---
                    Row(
                      children: [
                        // 1. UPDATE BUTTON (Pencil Icon)
                        IconButton(
                          icon: const Icon(Icons.edit_note_rounded, color: Colors.blue, size: 28),
                          onPressed: () => _showUpdateDialog(context, docId, data['name'], data['price']),
                        ),
                        // 2. DELETE BUTTON (Trash Icon)
                        IconButton(
                          icon: const Icon(Icons.delete_forever_rounded, color: primaryRed, size: 28),
                          onPressed: () => _showDeleteDialog(context, docId),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- CRUD: UPDATE FUNCTION ---
  void _showUpdateDialog(BuildContext context, String id, String oldName, String oldPrice) {
    TextEditingController nameController = TextEditingController(text: oldName);
    // මිලෙන් 'Rs' කෑල්ල ඉවත් කර පෙන්වමු
    TextEditingController priceController = TextEditingController(text: oldPrice.replaceAll("Rs ", ""));

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Update Listing", style: TextStyle(fontWeight: FontWeight.bold, color: primaryRed)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: "New Title")),
            TextField(controller: priceController, decoration: const InputDecoration(labelText: "New Price"), keyboardType: TextInputType.number),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: primaryRed),
            onPressed: () async {
              // Firebase Update ලොජික් එක
              await FirebaseFirestore.instance.collection('listings').doc(id).update({
                'name': nameController.text.trim(),
                'price': "Rs ${priceController.text.trim()}",
              });
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Updated successfully!")));
            },
            child: const Text("Update", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }

  // --- CRUD: DELETE FUNCTION ---
  void _showDeleteDialog(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Delete listing?"),
        content: const Text("This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Back")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
            onPressed: () async {
              await FirebaseFirestore.instance.collection('listings').doc(id).delete();
              Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
          )
        ],
      ),
    );
  }
}