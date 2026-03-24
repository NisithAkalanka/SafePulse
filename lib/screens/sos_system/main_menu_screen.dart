import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// මීට පෙර හැදූ සියලුම Screens Import කරන්න
import 'profile_screen.dart';
import 'sos_customization_screen.dart';
import 'settings_screen.dart';
import 'security_status_screen.dart';
import 'medical_profile_screen.dart';
import 'login_screen.dart';

class MainMenuScreen extends StatefulWidget {
  const MainMenuScreen({super.key});

  /// Opens the menu as a transparent overlay so background blur is visible.
  static Future<void> showOverlay(BuildContext context) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.transparent,
        pageBuilder: (_, __, ___) => const MainMenuScreen(),
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: Tween<double>(begin: 0, end: 1).animate(curved),
            child: child,
          );
        },
      ),
    );
  }

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  final user = FirebaseAuth.instance.currentUser;
  String studentName = "Loading...";
  String? _photoBase64;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  void _loadUserInfo() async {
    if (user != null) {
      var doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      if (doc.exists) {
        setState(() {
          studentName = doc.data()?['first_name'] ?? "SafePulse Member";
          _photoBase64 = doc.data()?['profile_photo_base64'];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    if (FirebaseAuth.instance.currentUser == null) {
      return const LoginScreen();
    }
    return Scaffold(
      backgroundColor: Colors.transparent,
      resizeToAvoidBottomInset: false,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
              child: Container(color: Colors.black.withOpacity(0.05)),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.centerRight,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.82,
                height: double.infinity,
                margin: const EdgeInsets.fromLTRB(0, 10, 10, 10),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF121217).withOpacity(0.96)
                      : Colors.white.withOpacity(0.92),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 24,
                      offset: Offset(-8, 0),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Container(
                      height: 165,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFFF5A63),
                            Color(0xFFE53935),
                            Color(0xFFB71C1C),
                          ],
                          stops: [0.0, 0.62, 1.0],
                        ),
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(30),
                          topRight: Radius.circular(30),
                        ),
                      ),
                    ),
                    Positioned(
                      top: -60,
                      right: -25,
                      child: Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.08),
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(18, 18, 14, 10),
                          child: Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  "App Menu",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 28,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              InkWell(
                                borderRadius: BorderRadius.circular(999),
                                onTap: () => Navigator.pop(context),
                                child: Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.14),
                                  ),
                                  child: const Icon(
                                    Icons.close_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.fromLTRB(18, 6, 18, 22),
                            child: Column(
                              children: [
                                _buildHeader(),
                                const SizedBox(height: 18),
                                _menuTile(
                                  Icons.person_outline,
                                  "My Profile",
                                  "Edit name, years and identity",
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (c) => const ProfileScreen(),
                                      ),
                                    );
                                  },
                                  isDark: isDark,
                                ),
                                _menuTile(
                                  Icons.tune,
                                  "SOS Customization",
                                  "Vibrations & Trigger duration",
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (c) =>
                                            const SOSCustomizationScreen(),
                                      ),
                                    );
                                  },
                                  isDark: isDark,
                                ),
                                _menuTile(
                                  Icons.medical_services_outlined,
                                  "Medical Information",
                                  "Allergies, blood group & ICE",
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (c) =>
                                            const MedicalProfileScreen(),
                                      ),
                                    );
                                  },
                                  isDark: isDark,
                                ),
                                _menuTile(
                                  Icons.verified_user_outlined,
                                  "Security Status",
                                  "Verify email and node protection",
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (c) =>
                                            const SecurityStatusScreen(),
                                      ),
                                    );
                                  },
                                  isDark: isDark,
                                ),
                                _menuTile(
                                  Icons.settings_outlined,
                                  "App Settings",
                                  "Language and notification system",
                                  () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (c) => const SettingsScreen(),
                                      ),
                                    );
                                  },
                                  isDark: isDark,
                                ),
                                const SizedBox(height: 24),
                                Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFFFF4B4B),
                                        Color(0xFFB31217),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(18),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Color(0x18000000),
                                        blurRadius: 14,
                                        offset: Offset(0, 7),
                                      ),
                                    ],
                                  ),
                                  child: TextButton.icon(
                                    onPressed: () async {
                                      await FirebaseAuth.instance.signOut();
                                      Navigator.of(
                                        context,
                                      ).pushNamedAndRemoveUntil(
                                        '/',
                                        (route) => false,
                                      );
                                    },
                                    icon: const Icon(
                                      Icons.logout,
                                      color: Colors.white,
                                    ),
                                    label: const Text(
                                      "Log out of account",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF5A63), Color(0xFFE53935)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.20),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFF24131A),
              backgroundImage: _photoBase64 != null
                  ? MemoryImage(base64Decode(_photoBase64!))
                  : null,
              child: _photoBase64 == null
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  studentName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  user?.email ?? "",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _menuTile(
    IconData icon,
    String title,
    String sub,
    VoidCallback tap, {
    bool isDark = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        onTap: tap,
        leading: Container(
          width: 46,
          height: 46,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF7B7B), Color(0xFFD32F2F)],
            ),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: const Color(0xFF1B1B22),
            fontWeight: FontWeight.w900,
            fontSize: 15,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Text(
            sub,
            style: TextStyle(
              color: const Color(0xFF747A86),
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        trailing: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFF4F5F7),
            border: Border.all(color: const Color(0xFFE8EAF0)),
          ),
          child: Icon(
            Icons.chevron_right,
            color: const Color(0xFF1B1B22),
            size: 18,
          ),
        ),
      ),
    );
  }
}
