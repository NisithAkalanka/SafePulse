import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'settings_screen.dart';
import 'navigation_screen.dart';
import 'edit_profile_screen.dart';
import 'sos_customization_screen.dart';
import 'security_status_screen.dart';
import 'medical_profile_screen.dart';
import 'admin_dashboard.dart'; // Admin Dashboard එක සඳහා මෙය අනිවාර්යයෙන්ම තිබිය යුතුයි

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
  String userRole = "student"; // Default role එක ශිෂ්‍යයෙක් ලෙස තබා ගනිමු
  String? _profilePhotoBase64;

  double completionPercentage = 0.0;
  bool isSetupComplete = false;

  @override
  void initState() {
    super.initState();
    if (user != null) {
      studentEmail = user?.email ?? "Guest";
      _loadUserData();
      _calculateCompletion();
    }
  }

  // Firestore එකෙන් දත්ත සහ User Role එක කියවීම
  Future<void> _loadUserData() async {
    if (user != null) {
      try {
        var ds = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();
        if (ds.exists) {
          setState(() {
            // පළමු සහ අවසාන නම තිබේදැයි බලමු
            String fname = ds.data()?['first_name'] ?? "";
            String lname = ds.data()?['last_name'] ?? "";
            studentName = (fname.isEmpty && lname.isEmpty)
                ? "Setup your name"
                : "$fname $lname";

            sliitId = ds.data()?['sliit_id'] ?? "No ID Found";
            studentEmail = ds.data()?['student_email'] ?? user?.email ?? "";

            // --- මෙන්න අලුතින් එක් කළ කොටස: Role එක ලබා ගැනීම ---
            userRole = ds.data()?['role'] ?? "student";

            _profilePhotoBase64 = ds.data()?['profile_photo_base64'];
            _calculateCompletion();
          });
        }
      } catch (e) {
        debugPrint("Error loading profile: $e");
      }
    }
  }

  Future<void> _calculateCompletion() async {
    if (user == null) return;

    var doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    if (doc.exists) {
      var data = doc.data()!;
      int filledFields = 0;

      List<String> requiredFields = [
        'first_name',
        'last_name',
        'sliit_id',
        'phone',
        'degree',
        'join_year',
        'blood_type',
        'allergies',
        'ice_name',
        'ice_phone',
      ];

      for (var field in requiredFields) {
        if (data[field] != null && data[field].toString().trim().isNotEmpty) {
          filledFields++;
        }
      }

      if (!mounted) return;

      setState(() {
        completionPercentage = filledFields / 10.0;
        isSetupComplete = completionPercentage == 1.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "User Profile",
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.2),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFA3A3A),
                  Color(0xFF8A0B0B),
                  Color(0xFF0F0F13),
                ],
                stops: [0.0, 0.45, 1.0],
              ),
            ),
          ),

          // Soft blobs
          Positioned(
            top: -140,
            left: -110,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            top: 140,
            right: -140,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.yellowAccent.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -170,
            left: -120,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),

          // Content
          RefreshIndicator(
            onRefresh: _loadUserData,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  // PROFILE COMPLETION SECTION
                  if (!isSetupComplete)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: _buildProgressBarUI(),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: _buildCompletionSuccessMsg(),
                    ),
                  const SizedBox(height: 120),

                  // HERO CARD (glass)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.18),
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              // Avatar with ring
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFFFF7B7B),
                                      Color(0xFFD32F2F),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.25),
                                      blurRadius: 18,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: CircleAvatar(
                                  radius: 40,
                                  backgroundColor: const Color(0xFF1B1B22),
                                  backgroundImage: _profilePhotoBase64 != null
                                      ? MemoryImage(
                                          base64Decode(_profilePhotoBase64!),
                                        )
                                      : null,
                                  child: _profilePhotoBase64 == null
                                      ? const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 44,
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 16),

                              Expanded(
                                // ✅ Required Expanded
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      studentName,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 3),

                                    Text(
                                      studentEmail,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),

                                    const SizedBox(height: 10),

                                    Wrap(
                                      // 🔥 Row → Wrap (overflow fix)
                                      spacing: 10,
                                      runSpacing: 6,
                                      children: [
                                        // ID chip
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withOpacity(
                                              0.22,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(
                                                0.16,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            "ID: $sliitId",
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 12,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),

                                        // Role chip
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                (userRole == 'admin'
                                                        ? Colors.amber
                                                        : Colors.green)
                                                    .withOpacity(0.18),
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                            border: Border.all(
                                              color: Colors.white.withOpacity(
                                                0.16,
                                              ),
                                            ),
                                          ),
                                          child: Text(
                                            userRole.toUpperCase(),
                                            style: TextStyle(
                                              color: userRole == 'admin'
                                                  ? Colors.amber
                                                  : Colors.lightGreenAccent,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.6,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 18),

                  // STATS
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      children: [
                        Expanded(
                          child: _statItem(
                            "05",
                            "SOS Hits",
                            const Color(0xFFFF4B4B),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _statItem(
                            "High",
                            "Trust",
                            const Color(0xFFFFC107),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _statItem(
                            "Main",
                            "Group",
                            const Color(0xFF40C4FF),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // MENU
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      children: [
                        _profileMenuItem(
                          Icons.edit_outlined,
                          "Edit Profile Details",
                          "Years, degree, phone & photo",
                          () async {
                            bool? updated = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EditProfileScreen(),
                              ),
                            );
                            if (updated == true) _loadUserData();
                          },
                        ),
                        _profileMenuItem(
                          Icons.tune,
                          "SOS Customization",
                          "Set vibrations & trigger delay",
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SOSCustomizationScreen(),
                              ),
                            );
                          },
                        ),

                        // ADMIN MENU (condition unchanged)
                        if (userRole == "admin")
                          _profileMenuItem(
                            Icons.admin_panel_settings,
                            "Security Admin Dashboard",
                            "Manage all university SOS alerts",
                            () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AdminDashboard(),
                                ),
                              );
                            },
                          ),

                        _profileMenuItem(
                          Icons.notifications_none,
                          "App Settings",
                          "Notifications & System preferences",
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const SettingsScreen(),
                              ),
                            );
                          },
                        ),
                        _profileMenuItem(
                          Icons.verified_user_outlined,
                          "Security Status",
                          "Check account verification & node status",
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const SecurityStatusScreen(),
                              ),
                            );
                          },
                        ),
                        _profileMenuItem(
                          Icons.health_and_safety_outlined,
                          "Medical Information",
                          "Blood group & Allergies",
                          () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    const MedicalProfileScreen(),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // LOGOUT BUTTON (same logic)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFFFF4B4B), Color(0xFFB31217)],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.30),
                              blurRadius: 18,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () async {
                            await FirebaseAuth.instance.signOut();
                            if (!mounted) return;
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const MainNavigationScreen(),
                              ),
                              (route) => false,
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            minimumSize: const Size(double.infinity, 58),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.logout_rounded,
                                color: Colors.white,
                                size: 20,
                              ),
                              SizedBox(width: 10),
                              Text(
                                "Log Out",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 34),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBarUI() {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Complete Your Safety Profile",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              Text(
                "${(completionPercentage * 100).toInt()}%",
                style: const TextStyle(
                  color: Colors.yellowAccent,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          LinearProgressIndicator(
            value: completionPercentage,
            minHeight: 8,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.greenAccent),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionSuccessMsg() {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.15),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.greenAccent.withOpacity(0.5)),
      ),
      child: const Row(
        children: [
          Icon(Icons.verified_user, color: Colors.greenAccent),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Your Safety Profile is fully connected! ✅",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withOpacity(0.16),
              width: 1.0,
            ),
          ),
          child: Column(
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white70,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileMenuItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Material(
            color: Colors.white.withOpacity(0.10),
            child: InkWell(
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFFFF7B7B), Color(0xFFD32F2F)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.20),
                            blurRadius: 12,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              fontSize: 15,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Colors.white70,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.black.withOpacity(0.20),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.14),
                        ),
                      ),
                      child: const Icon(
                        Icons.chevron_right,
                        size: 18,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
