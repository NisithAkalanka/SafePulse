import 'dart:convert'; // පින්තූරය Decode කිරීමට මෙය අත්‍යවශ්‍යයි
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'settings_screen.dart';
import 'navigation_screen.dart'; 
import 'edit_profile_screen.dart';       
import 'sos_customization_screen.dart'; 
import 'security_status_screen.dart';
import 'medical_profile_screen.dart'; // තිබේ නම් පමණක්

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  
  String studentEmail = "Not Logged In";
  String studentName = "SafePulse Member";
  String sliitId = "---";
  String? _profilePhotoBase64; // පින්තූරය තාවකාලිකව රඳවා ගැනීමට

  @override
  void initState() {
    super.initState();
    if (user != null) {
      studentEmail = user?.email ?? "Guest";
      _loadUserData();
    }
  }

  // Firestore එකෙන් දත්ත කියවා පින්තූරය ඇතුළු දත්ත පෙන්වමු
  Future<void> _loadUserData() async {
    if (user != null) {
      try {
        var ds = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
        if (ds.exists) {
          setState(() {
            // First Name සහ Last Name තිබේ නම් එය පෙන්වමු
            String fname = ds.data()?['first_name'] ?? "";
            String lname = ds.data()?['last_name'] ?? "";
            studentName = (fname.isEmpty && lname.isEmpty) 
                ? "Setup your name" 
                : "$fname $lname";

            sliitId = ds.data()?['sliit_id'] ?? "No ID Found";
            studentEmail = ds.data()?['student_email'] ?? user?.email ?? "";
            
            // Database එකේ ඇති පින්තූර Text එක ගනිමු
            _profilePhotoBase64 = ds.data()?['profile_photo_base64'];
          });
        }
      } catch (e) {
        debugPrint("Error loading profile: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("User Profile", style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadUserData, // පහළට අැද්දම පේජ් එක update වෙනවා
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              // --- HEADER SECTION (IMAGE + NAME + SLIIT ID) ---
              Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(35),
                    bottomRight: Radius.circular(35),
                  ),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 42,
                      backgroundColor: Colors.redAccent,
                      // මෙන්න පින්තූරය පෙන්වන ලොජික් එක
                      backgroundImage: _profilePhotoBase64 != null 
                          ? MemoryImage(base64Decode(_profilePhotoBase64!))
                          : null,
                      child: _profilePhotoBase64 == null 
                          ? const Icon(Icons.person, color: Colors.white, size: 45) 
                          : null,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            studentName,
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(studentEmail, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                          const SizedBox(height: 5),
                          Text(
                            "ID: $sliitId",
                            style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          const SizedBox(height: 5),
                          const Text("🛡️ Verified Guardian",
                              style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold, fontSize: 12)),
                        ],
                      ),
                    )
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // --- STATISTICS ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _statItem("05", "SOS Hits", Colors.red),
                    _statItem("High", "Trust", Colors.orange),
                    _statItem("Main", "Group", Colors.blue),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // --- MENU OPTIONS ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    _profileMenuItem(Icons.edit_outlined, "Edit Profile Details", "Years, degree, phone & photo", () async {
                      bool? updated = await Navigator.push(context, MaterialPageRoute(builder: (context) => const EditProfileScreen()));
                      if (updated == true) _loadUserData(); // දත්ත මාරු කළොත් පේජ් එක update කරමු
                    }),
                    _profileMenuItem(Icons.tune, "SOS Customization", "Set vibrations & trigger delay", () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SOSCustomizationScreen()));
                    }),
                    _profileMenuItem(Icons.notifications_none, "App Settings", "Notifications & System preferences", () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                    }),
                    _profileMenuItem(Icons.verified_user_outlined, "Security Status", "Security check & Node status", () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const SecurityStatusScreen()));
                    }),
                    _profileMenuItem(Icons.health_and_safety_outlined, "Medical Information", "Blood group & Allergies", () {
                       Navigator.push(context, MaterialPageRoute(builder: (context) => MedicalProfileScreen()));
                    }),
                  ],
                ),
              ),

              const SizedBox(height: 35),

              // --- LOGOUT BUTTON ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 30),
                child: ElevatedButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    if (!mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (context) => const MainNavigationScreen()),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    minimumSize: const Size(double.infinity, 58),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    elevation: 2,
                  ),
                  child: const Text("Log Out", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _statItem(String value, String label, Color color) {
    return Container(
      width: 105,
      padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: Column(
        children: [
          Text(value, style: TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _profileMenuItem(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
          child: Icon(icon, color: Colors.redAccent, size: 22),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        trailing: const Icon(Icons.chevron_right, size: 18, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }
}