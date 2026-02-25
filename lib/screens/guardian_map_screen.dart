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
  
  @override
  Widget build(BuildContext context) {
    // 1. Auth Status එක නිරීක්ෂණය කරන ප්‍රධාන Stream එක
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final currentUser = authSnapshot.data;

        // යූසර් ලොග් වෙලා නැතිනම් පෙන්වන කොටස
        if (currentUser == null) {
          return Scaffold(
            appBar: AppBar(title: const Text("Circle Map"), backgroundColor: Colors.redAccent),
            body: _emptyState("Login Required", "Please login to access tracking data.", Icons.lock_outline),
          );
        }

        // 2. ලොග් වෙලා ඉන්නවා නම්, Firestore එකෙන් ඔහුගේ Role එක සහ දත්ත කියවන දෙවන Stream එක
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).snapshots(),
          builder: (context, userDocSnapshot) {
            if (userDocSnapshot.hasError) return const Scaffold(body: Center(child: Text("Connection Error")));
            if (userDocSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator(color: Colors.redAccent)));
            }

            var userData = userDocSnapshot.data?.data() as Map<String, dynamic>?;

            if (userData == null || !userDocSnapshot.data!.exists) {
              return Scaffold(
                appBar: AppBar(title: const Text("Account Alert"), backgroundColor: Colors.orange),
                body: _emptyState("Profile Incomplete", "Setup your details in Edit Profile.", Icons.info_outline),
              );
            }

            String role = userData['role'] ?? "student";
            List guardians = userData['guardians'] ?? [];

            // 3. යූසර් ADMIN ද නැද්ද අනුව AppBar එක සහ Body එක මාරු කිරීම
            return Scaffold(
              backgroundColor: Colors.white,
              appBar: AppBar(
                title: Text(role == "admin" ? "🛡️ Security Admin Hub" : "Guardian Circle Map", 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                backgroundColor: role == "admin" ? Colors.black87 : Colors.redAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                leading: const Icon(Icons.my_location),
              ),
              body: role == "admin" ? _buildAdminFeed() : _buildStudentFeed(guardians),
            );
          },
        );
      },
    );
  }

  // --- ADMIN: මුළු පද්ධතියම නිරීක්ෂණය කරයි ---
  Widget _buildAdminFeed() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        var allUsers = snapshot.data!.docs;
        return _buildUIStructure(allUsers, "SATELLITE CAMPUS OVERVIEW (ADMIN)");
      },
    );
  }

  // --- STUDENT: තම හිතවතුන් පමනක් නිරීක්ෂණය කරයි ---
  Widget _buildStudentFeed(List guardians) {
    if (guardians.isEmpty) {
      return _emptyState("No Connections", "Your trusted circle is currently empty.\nAdd guardians from the profile tab.", Icons.people_outline);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('student_email', whereIn: guardians)
          .snapshots(),
      builder: (context, friendSnapshot) {
        if (!friendSnapshot.hasData) return const Center(child: CircularProgressIndicator());
        return _buildUIStructure(friendSnapshot.data!.docs, "ACTIVE GUARDIAN STATUS");
      },
    );
  }

  // --- පොදු UI කොටස: මෙතැනින් ගැස්සීම නවතයි ---
  Widget _buildUIStructure(List<QueryDocumentSnapshot> docs, String label) {
    final authEmail = FirebaseAuth.instance.currentUser?.email;

    return Column(
      children: [
        // Premium Header Map Preview
        Expanded(
          flex: 2,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.blue[50], borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.blue.shade100, width: 2),
            ),
            child: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.wifi_tethering_rounded, size: 50, color: Colors.blueAccent),
                  SizedBox(height: 5),
                  Text("SECURE CONNECTION ACTIVE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10, color: Colors.blueAccent)),
                ],
              ),
            ),
          ),
        ),

        // List Container
        Expanded(
          flex: 3,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.vertical(top: Radius.circular(35)),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("📍 $label", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
                    const Icon(Icons.flash_on_rounded, color: Colors.orange, size: 18),
                  ],
                ),
                const SizedBox(height: 15),
                Expanded(
                  child: ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      var data = docs[index].data() as Map<String, dynamic>;
                      
                      // තමන්ගේ නම පෙන්වීම වලක්වයි
                      if (data['student_email'] == authEmail) return const SizedBox();

                      double? lat = double.tryParse(data['last_lat']?.toString() ?? "");
                      double? lng = double.tryParse(data['last_lng']?.toString() ?? "");
                      String name = data['first_name'] ?? data['student_email']?.split('@')[0] ?? "Member";
                      String? photo = data['profile_photo_base64'];

                      return Card(
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15), side: BorderSide(color: Colors.grey.shade200)),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 24, backgroundColor: Colors.red[50],
                            backgroundImage: photo != null ? MemoryImage(base64Decode(photo)) : null,
                            child: photo == null ? const Icon(Icons.person, color: Colors.redAccent) : null,
                          ),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          subtitle: Text(
                            (lat != null) ? "Live: Lat $lat, Lng $lng" : "GPS Signal Waiting...",
                            style: TextStyle(color: lat != null ? Colors.green[700] : Colors.grey, fontSize: 11),
                          ),
                          trailing: const Icon(Icons.gps_fixed_sharp, size: 16, color: Colors.blueAccent),
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

  Widget _emptyState(String title, String msg, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 70, color: Colors.grey[400]),
          const SizedBox(height: 15),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          Padding(padding: const EdgeInsets.all(10), child: Text(msg, textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[600]))),
        ],
      ),
    );
  }
}