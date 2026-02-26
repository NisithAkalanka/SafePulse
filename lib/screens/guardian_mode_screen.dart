import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';

class GuardianModeScreen extends StatefulWidget {
  const GuardianModeScreen({super.key});

  @override
  State<GuardianModeScreen> createState() => _GuardianModeScreenState();
}

class _GuardianModeScreenState extends State<GuardianModeScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final _emailController = TextEditingController();
  bool _isLoading = false;

  // 1. යාළුවෙක්ව සෙවීම සහ ඇඩ් කිරීම
  Future<void> _addGuardian() async {
    String email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty) return;
    if (email == user?.email) {
      _showMsg("You cannot add yourself as a guardian!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Firebase එකේ මේ Email එකෙන් කවුරුහරි රෙජිස්ටර් වෙලා ඉන්නවද බලමු
      var query = await FirebaseFirestore.instance
          .collection('users')
          .where('student_email', isEqualTo: email)
          .get();

      if (query.docs.isEmpty) {
        _showMsg("This user is not registered on SafePulse.");
      } else {
        // ඔයාගේ 'guardians' array එකට මේ email එක ඇතුළත් කරමු
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .update({
              'guardians': FieldValue.arrayUnion([email]),
            });
        _showMsg("✅ Guardian added successfully!");
        _emailController.clear();
      }
    } catch (e) {
      _showMsg("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 2. ගාර්ඩියන් කෙනෙක් ඉවත් කිරීම
  Future<void> _removeGuardian(String email) async {
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'guardians': FieldValue.arrayRemove([email]),
    });
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Guardian Circle",
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.2),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
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
                  Color(0xFFFF4B4B),
                  Color(0xFF8A0B0B),
                  Color(0xFF0F0F13),
                ],
                stops: [0.0, 0.50, 1.0],
              ),
            ),
          ),

          // Soft blobs
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

          // Vignette overlay
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
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Column(
                children: [
                  // Top instruction glass card
                  ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(22),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.18),
                            width: 1.1,
                          ),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.shield_rounded,
                              color: Colors.white,
                              size: 30,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                "Your Guardians will receive high-priority alerts and live location during your SOS emergencies.",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.white70,
                                  height: 1.25,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Add guardian input row (glass)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.16),
                            width: 1.1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _emailController,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                                cursorColor: Colors.white,
                                decoration: InputDecoration(
                                  hintText: "Add via Student Email...",
                                  hintStyle: const TextStyle(
                                    color: Colors.white54,
                                  ),
                                  prefixIcon: const Icon(
                                    Icons.email_outlined,
                                    color: Colors.white,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: Colors.black.withOpacity(0.18),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            GestureDetector(
                              onTap: _isLoading ? null : _addGuardian,
                              child: Container(
                                width: 54,
                                height: 54,
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
                                      color: Colors.black.withOpacity(0.28),
                                      blurRadius: 16,
                                      offset: const Offset(0, 10),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 22,
                                          width: 22,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(
                                          Icons.add,
                                          color: Colors.white,
                                          size: 28,
                                        ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Divider + section label
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: Colors.white.withOpacity(0.16),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "MY CURRENT GUARDIANS",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Colors.white70,
                          fontSize: 11.5,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: Colors.white.withOpacity(0.16),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // List (StreamBuilder logic unchanged, only visuals)
                  Expanded(
                    child: StreamBuilder<DocumentSnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('users')
                          .doc(user!.uid)
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(
                              color: Colors.white,
                            ),
                          );
                        }

                        var userData =
                            snapshot.data!.data() as Map<String, dynamic>?;
                        List guardians = userData?['guardians'] ?? [];

                        if (guardians.isEmpty) {
                          return const Center(
                            child: Text(
                              "You haven't added any guardians yet.",
                              style: TextStyle(color: Colors.white70),
                            ),
                          );
                        }

                        return ListView.builder(
                          itemCount: guardians.length,
                          padding: const EdgeInsets.only(bottom: 12),
                          itemBuilder: (context, index) {
                            final email = guardians[index].toString();
                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 18,
                                    sigmaY: 18,
                                  ),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.10),
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.14),
                                        width: 1.0,
                                      ),
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 6,
                                          ),
                                      leading: Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.black.withOpacity(0.18),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.14,
                                            ),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.person,
                                          color: Colors.white,
                                          size: 22,
                                        ),
                                      ),
                                      title: Text(
                                        email,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w900,
                                          fontSize: 13.5,
                                          color: Colors.white,
                                        ),
                                      ),
                                      subtitle: const Text(
                                        "Trusted Contact",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      trailing: IconButton(
                                        icon: const Icon(
                                          Icons.delete_outline,
                                          color: Colors.white,
                                        ),
                                        onPressed: () => _removeGuardian(email),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
