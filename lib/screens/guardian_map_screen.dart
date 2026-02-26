import 'dart:convert';
import 'dart:ui';
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
            backgroundColor: const Color(0xFF0F0F13),
            extendBodyBehindAppBar: true,
            appBar: AppBar(
              title: const Text("Circle Map"),
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              centerTitle: true,
            ),
            body: _bgWrap(
              child: _emptyState(
                "Login Required",
                "Please login to access tracking data.",
                Icons.lock_outline,
              ),
            ),
          );
        }

        // 2. ලොග් වෙලා ඉන්නවා නම්, Firestore එකෙන් ඔහුගේ Role එක සහ දත්ත කියවන දෙවන Stream එක
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .snapshots(),
          builder: (context, userDocSnapshot) {
            if (userDocSnapshot.hasError)
              return const Scaffold(
                body: Center(child: Text("Connection Error")),
              );
            if (userDocSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Colors.redAccent),
                ),
              );
            }

            var userData =
                userDocSnapshot.data?.data() as Map<String, dynamic>?;

            if (userData == null || !userDocSnapshot.data!.exists) {
              return Scaffold(
                backgroundColor: const Color(0xFF0F0F13),
                extendBodyBehindAppBar: true,
                appBar: AppBar(
                  title: const Text("Account Alert"),
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  centerTitle: true,
                ),
                body: _bgWrap(
                  child: _emptyState(
                    "Profile Incomplete",
                    "Setup your details in Edit Profile.",
                    Icons.info_outline,
                  ),
                ),
              );
            }

            String role = userData['role'] ?? "student";
            List guardians = userData['guardians'] ?? [];

            // 3. යූසර් ADMIN ද නැද්ද අනුව AppBar එක සහ Body එක මාරු කිරීම
            return Scaffold(
              backgroundColor: const Color(0xFF0F0F13),
              extendBodyBehindAppBar: true,
              appBar: AppBar(
                title: Text(
                  role == "admin"
                      ? "🛡️ Security Admin Hub"
                      : "Guardian Circle Map",
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                    letterSpacing: 0.2,
                  ),
                ),
                centerTitle: true,
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                leading: const Icon(Icons.my_location),
              ),
              body: _bgWrap(
                child: role == "admin"
                    ? _buildAdminFeed()
                    : _buildStudentFeed(guardians),
              ),
            );
          },
        );
      },
    );
  }

  Widget _bgWrap({required Widget child}) {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF4B4B), Color(0xFF8A0B0B), Color(0xFF0F0F13)],
              stops: [0.0, 0.50, 1.0],
            ),
          ),
        ),
        Positioned(
          top: -140,
          left: -120,
          child: Container(
            width: 360,
            height: 360,
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
            width: 360,
            height: 360,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.yellowAccent.withOpacity(0.06),
            ),
          ),
        ),
        Positioned(
          bottom: -170,
          left: -130,
          child: Container(
            width: 420,
            height: 420,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.06),
            ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.06),
                    Colors.transparent,
                    Colors.black.withOpacity(0.30),
                  ],
                  stops: const [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: child,
          ),
        ),
      ],
    );
  }

  // --- ADMIN: මුළු පද්ධතියම නිරීක්ෂණය කරයි ---
  Widget _buildAdminFeed() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        var allUsers = snapshot.data!.docs;
        return _buildUIStructure(allUsers, "SATELLITE CAMPUS OVERVIEW (ADMIN)");
      },
    );
  }

  // --- STUDENT: තම හිතවතුන් පමනක් නිරීක්ෂණය කරයි ---
  Widget _buildStudentFeed(List guardians) {
    if (guardians.isEmpty) {
      return _emptyState(
        "No Connections",
        "Your trusted circle is currently empty.\nAdd guardians from the profile tab.",
        Icons.people_outline,
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('student_email', whereIn: guardians)
          .snapshots(),
      builder: (context, friendSnapshot) {
        if (!friendSnapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        return _buildUIStructure(
          friendSnapshot.data!.docs,
          "ACTIVE GUARDIAN STATUS",
        );
      },
    );
  }

  Widget _buildUIStructure(List<QueryDocumentSnapshot> docs, String label) {
    final authEmail = FirebaseAuth.instance.currentUser?.email;

    return Column(
      children: [
        // Glass preview (map placeholder)
        ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: Colors.white.withOpacity(0.16),
                  width: 1.1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 54,
                    height: 54,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.18),
                      border: Border.all(color: Colors.white.withOpacity(0.14)),
                    ),
                    child: const Icon(
                      Icons.wifi_tethering_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "SECURE CONNECTION ACTIVE",
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Live location sync is running in the background.",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withOpacity(0.14)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          size: 8,
                          color: Colors.lightGreenAccent,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Live",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // Glass list panel
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.16),
                    width: 1.1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "📍 $label",
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 12.5,
                            color: Colors.white,
                            letterSpacing: 0.6,
                          ),
                        ),
                        const Icon(
                          Icons.flash_on_rounded,
                          color: Colors.orange,
                          size: 18,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: docs.length,
                        itemBuilder: (context, index) {
                          var data = docs[index].data() as Map<String, dynamic>;

                          if (data['student_email'] == authEmail)
                            return const SizedBox();

                          double? lat = double.tryParse(
                            data['last_lat']?.toString() ?? "",
                          );
                          double? lng = double.tryParse(
                            data['last_lng']?.toString() ?? "",
                          );
                          String name =
                              data['first_name'] ??
                              data['student_email']?.split('@')[0] ??
                              "Member";
                          String? photo = data['profile_photo_base64'];

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 14,
                                  sigmaY: 14,
                                ),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.12),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: ListTile(
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 6,
                                    ),
                                    leading: CircleAvatar(
                                      radius: 24,
                                      backgroundColor: Colors.white.withOpacity(
                                        0.10,
                                      ),
                                      backgroundImage: photo != null
                                          ? MemoryImage(base64Decode(photo))
                                          : null,
                                      child: photo == null
                                          ? const Icon(
                                              Icons.person,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                    title: Text(
                                      name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14.5,
                                        color: Colors.white,
                                      ),
                                    ),
                                    subtitle: Text(
                                      (lat != null && lng != null)
                                          ? "Live: Lat $lat, Lng $lng"
                                          : "GPS Signal Waiting...",
                                      style: TextStyle(
                                        color: (lat != null && lng != null)
                                            ? Colors.lightGreenAccent
                                            : Colors.white70,
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    trailing: const Icon(
                                      Icons.gps_fixed_sharp,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyState(String title, String msg, IconData icon) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 22),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(
                  color: Colors.white.withOpacity(0.16),
                  width: 1.1,
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withOpacity(0.18),
                      border: Border.all(color: Colors.white.withOpacity(0.14)),
                    ),
                    child: Icon(icon, size: 34, color: Colors.white),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    msg,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
