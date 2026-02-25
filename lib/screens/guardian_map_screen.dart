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
  String _userRole = "student"; // Default එක student ලෙස තබමු

  @override
  void initState() {
    super.initState();
    _checkUserRole();
  }

  // Firestore එකෙන් යූසර් ඇත්තටම Admin ද නැද්ද කියා පරීක්ෂා කරමු
  Future<void> _checkUserRole() async {
    if (user != null) {
      try {
        var doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
        if (doc.exists) {
          setState(() {
            _userRole = doc.data()?['role'] ?? "student";
          });
        }
      } catch (e) {
        debugPrint("Role check error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) return const Scaffold(body: Center(child: Text("Please login first.")));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_userRole == "admin" ? "🛡️ Global Security Map" : "Guardian Circle", 
          style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: _userRole == "admin" ? Colors.black87 : Colors.redAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _userRole == "admin" ? _buildAdminFeed() : _buildStudentFeed(),
    );
  }

  // --- 1. ADMIN ලොජික් එක: පද්ධතියේ සියලු ශිෂ්‍යයින් ලෝඩ් කරයි ---
  Widget _buildAdminFeed() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var allUsers = snapshot.data!.docs;
        return _buildLayoutUI(allUsers, "GLOBAL CAMPUS FEED (ADMIN MODE)");
      },
    );
  }

  // --- 2. STUDENT ලොජික් එක: තමන්ගේ Guardians පිරිස පමණක් ලෝඩ් කරයි ---
  Widget _buildStudentFeed() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
      builder: (context, userSnapshot) {
        if (!userSnapshot.hasData) return const Center(child: CircularProgressIndicator());

        var myData = userSnapshot.data!.data() as Map<String, dynamic>?;
        List guardians = myData?['guardians'] ?? [];

        if (guardians.isEmpty) {
          return _emptyState("No Guardians added.\nOnly your trusted circle will appear here.");
        }

        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where('student_email', whereIn: guardians)
              .snapshots(),
          builder: (context, friendSnapshot) {
            if (!friendSnapshot.hasData) return const Center(child: CircularProgressIndicator());
            return _buildLayoutUI(friendSnapshot.data!.docs, "ACTIVE CIRCLE STATUS");
          },
        );
      },
    );
  }

  // --- පොදු UI කොටස: මෙය Admin/Student දෙන්නාටම දත්ත පෙන්වයි ---
  Widget _buildLayoutUI(List<QueryDocumentSnapshot> docs, String title) {
    return Column(
      children: [
        // Simulated Snap-Map පෙනුම ඇති Header එක
        Expanded(
          flex: 2,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.blue.shade100),
            ),
            child: const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.map_outlined, size: 80, color: Colors.blueAccent),
                SizedBox(height: 10),
                Text("MAP VISUALIZER READY", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                Text("GPS tracking signals active", style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ),
        ),

        // සජීවී දත්ත ලැයිස්තුව (Live Tracking Feed)
        Expanded(
          flex: 3,
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("🔥 $title", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 1.1)),
                    const Icon(Icons.bolt, color: Colors.orange, size: 18),
                  ],
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var data = docs[index].data() as Map<String, dynamic>;
                      
                      // අනවශ්‍ය ලෙස තමන්ගේම නම ලිස්ට් එකට එන එක වැලැක්වීම
                      if (data['student_email'] == user?.email) return const SizedBox();
                      // Admin කෙනෙක් ශිෂ්‍ය ලැයිස්තුවේ පෙන්විය යුතු නැතිනම්:
                      if (_userRole == "admin" && data['role'] == "admin") return const SizedBox();

                      double? lat = double.tryParse(data['last_lat']?.toString() ?? "");
                      double? lng = double.tryParse(data['last_lng']?.toString() ?? "");
                      String name = data['first_name'] ?? data['student_email']?.split('@')[0] ?? "Member";
                      String? photo = data['profile_photo_base64'];

                      return Card(
                        elevation: 1.5,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.red[50],
                            backgroundImage: photo != null ? MemoryImage(base64Decode(photo)) : null,
                            child: photo == null ? const Icon(Icons.person, color: Colors.redAccent) : null,
                          ),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Text(
                            lat != null ? "Sensed: Lat $lat, Lng $lng" : "GPS connection pending...",
                            style: TextStyle(color: lat != null ? Colors.green : Colors.orange),
                          ),
                          trailing: Icon(Icons.circle, color: lat != null ? Colors.green : Colors.grey, size: 10),
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
  }

  Widget _emptyState(String msg) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.explore_off_outlined, size: 80, color: Colors.grey),
          const SizedBox(height: 20),
          Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: Colors.grey, fontSize: 15)),
        ],
      ),
    );
  }
}