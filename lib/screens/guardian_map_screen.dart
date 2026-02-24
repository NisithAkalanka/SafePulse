import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GuardianMapScreen extends StatefulWidget {
  const GuardianMapScreen({super.key});
  @override
  State<GuardianMapScreen> createState() => _GuardianMapScreenState();
}

class _GuardianMapScreenState extends State<GuardianMapScreen> {
  final user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    // 1. යූසර් ලොග් වෙලා නැතිනම් (ආරක්ෂාවට)
    if (user == null) {
      return const Scaffold(body: Center(child: Text("Please login to see the map")));
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Circle Tracking", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        // දැනට ලොග් වී ඉන්න යූසර්ගේ තොරතුරු බලමු
        stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
        builder: (context, userSnapshot) {
          // ලෝඩ් වන අතරතුර
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          // යම් හෙයකින් දත්ත නැතිනම් හෝ ඩොකියුමන්ට් එක නැතිනම් (අලුත් යූසර් කෙනෙක් නම්)
          if (!userSnapshot.hasData || !userSnapshot.data!.exists) {
            return _emptyState("Initializing your profile. Please add a guardian first.");
          }

          var myData = userSnapshot.data!.data() as Map<String, dynamic>?;
          List guardians = myData?['guardians'] ?? []; // null නම් හිස් ලැයිස්තුවක් ගනී

          if (guardians.isEmpty) {
            return _emptyState("Your Guardian Circle is empty.\nAdd friends to track them!");
          }

          // 2. යාළුවන්ගේ ලොකේෂන් දත්ත ලබා ගැනීම
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where('student_email', whereIn: guardians)
                .snapshots(),
            builder: (context, friendSnapshot) {
              if (friendSnapshot.hasError) {
                return _emptyState("Error loading guardians data.");
              }
              if (!friendSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              var friendDocs = friendSnapshot.data!.docs;

              return Column(
                children: [
                  // --- TOP MAP VISUALIZATION (SNAP STYLE) ---
                  Expanded(
                    flex: 4,
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(25),
                        image: const DecorationImage(
                          image: NetworkImage("https://www.google.com/maps/d/u/0/thumbnail?mid=1S9S-T-H-K5H-Q&msa=0"),
                          fit: BoxFit.cover,
                          opacity: 0.3,
                        ),
                      ),
                      child: const Center(
                        child: Icon(Icons.my_location, color: Colors.blueAccent, size: 50),
                      ),
                    ),
                  ),

                  // --- BOTTOM FRIENDS LIST ---
                  Expanded(
                    flex: 5,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
                        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.hub_outlined, color: Colors.orange, size: 18),
                              SizedBox(width: 8),
                              Text("ACTIVE CIRCLE DATA", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.1)),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Expanded(
                            child: friendDocs.isEmpty 
                              ? const Center(child: Text("Your friends haven't set up their location yet.", style: TextStyle(fontSize: 12, color: Colors.grey)))
                              : ListView.builder(
                                  itemCount: friendDocs.length,
                                  itemBuilder: (context, index) {
                                    var data = friendDocs[index].data() as Map<String, dynamic>;
                                    
                                    // Null-Safe Data Fetching
                                    double? lat = double.tryParse(data['last_lat']?.toString() ?? "");
                                    double? lng = double.tryParse(data['last_lng']?.toString() ?? "");
                                    String name = data['first_name'] ?? data['student_email']?.split('@')[0] ?? "Member";
                                    String? photo = data['profile_photo_base64'];

                                    return Card(
                                      elevation: 2,
                                      margin: const EdgeInsets.only(bottom: 12),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                                      child: ListTile(
                                        leading: CircleAvatar(
                                          backgroundColor: Colors.red[100],
                                          backgroundImage: photo != null ? MemoryImage(base64Decode(photo)) : null,
                                          child: photo == null ? const Icon(Icons.person, color: Colors.redAccent) : null,
                                        ),
                                        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                        subtitle: Text(
                                          (lat != null) ? "📍 Lat: $lat | Lng: $lng" : "GPS signal pending...",
                                          style: TextStyle(color: (lat != null) ? Colors.green[700] : Colors.orange[300], fontSize: 12),
                                        ),
                                        trailing: Icon(Icons.gps_fixed, color: (lat != null) ? Colors.blue : Colors.grey, size: 18),
                                      ),
                                    );
                                  },
                                ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _emptyState(String msg) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.people_outline, size: 80, color: Colors.grey),
            const SizedBox(height: 20),
            Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}