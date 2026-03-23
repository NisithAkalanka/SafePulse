import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'item_details.dart';

class FavoriteSavedScreen extends StatelessWidget {
  final String title;
  final String collectionName;

  const FavoriteSavedScreen({super.key, required this.title, required this.collectionName});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: const Color(0xFFD32F2F)),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection(collectionName)
            .where('userId', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) return Center(child: Text("Your $title is empty."));

          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              var data = docs[index].data() as Map<String, dynamic>;
              return ListTile(
                leading: Image.network(data['image'], width: 50, fit: BoxFit.cover),
                title: Text(data['name']),
                subtitle: Text(data['price'], style: const TextStyle(color: Colors.red)),
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ItemDetails(itemName: data['name'], itemPrice: data['price'], itemImage: data['image']))),
              );
            },
          );
        },
      ),
    );
  }
}