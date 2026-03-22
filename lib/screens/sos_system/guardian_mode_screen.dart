import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      backgroundColor: const Color(0xFFF6F7FB),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Guardian Circle",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(18, 108, 18, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFF4B4B),
                  Color(0xFFB31217),
                  Color(0xFF1B1B1B),
                ],
                stops: [0.0, 0.62, 1.0],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(34),
                bottomRight: Radius.circular(34),
              ),
            ),
            child: Column(
              children: [
                _headerCard(),
                const SizedBox(height: 12),
                _topInfoStrip(),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
              child: Column(
                children: [
                  _addGuardianCard(),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: const Color(0xFFE5E7EE),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        "MY CURRENT GUARDIANS",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF7A808C),
                          fontSize: 11.5,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: const Color(0xFFE5E7EE),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x12000000),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      child: StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('users')
                            .doc(user!.uid)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFFB31217),
                              ),
                            );
                          }

                          var userData =
                              snapshot.data!.data() as Map<String, dynamic>?;
                          List guardians = userData?['guardians'] ?? [];

                          if (guardians.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: const [
                                  CircleAvatar(
                                    radius: 30,
                                    backgroundColor: Color(0xFFFFE3E3),
                                    child: Icon(
                                      Icons.shield_outlined,
                                      color: Color(0xFFB31217),
                                      size: 28,
                                    ),
                                  ),
                                  SizedBox(height: 14),
                                  Text(
                                    "No guardians added yet",
                                    style: TextStyle(
                                      color: Color(0xFF1B1B22),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                  SizedBox(height: 6),
                                  Text(
                                    "Add trusted contacts to receive SOS alerts and live location.",
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: Color(0xFF747A86),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: guardians.length,
                            padding: const EdgeInsets.only(bottom: 8),
                            itemBuilder: (context, index) {
                              final email = guardians[index].toString();
                              return _guardianTile(email);
                            },
                          );
                        },
                      ),
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

  Widget _headerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.14),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: const Icon(
              Icons.groups_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Guardian Circle",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Add trusted contacts who receive your SOS alerts and live updates.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.18),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: Colors.white.withOpacity(0.14)),
            ),
            child: const Row(
              children: [
                Icon(Icons.shield_rounded, color: Colors.white, size: 14),
                SizedBox(width: 6),
                Text(
                  "Trusted",
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
    );
  }

  Widget _topInfoStrip() {
    return Row(
      children: [
        Expanded(
          child: _topMiniChip(
            Icons.notifications_active_outlined,
            "SOS alerts",
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _topMiniChip(Icons.location_on_outlined, "Live location"),
        ),
      ],
    );
  }

  Widget _topMiniChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _addGuardianCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF4B4B), Color(0xFFB31217)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x18000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Color(0x33FFFFFF),
                child: Icon(
                  Icons.person_add_alt_1_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Add New Guardian",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Search using the registered student email address.",
                      style: TextStyle(
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
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Icon(Icons.email_outlined, color: Color(0xFFB31217)),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    style: const TextStyle(
                      color: Color(0xFF1B1B22),
                      fontWeight: FontWeight.w700,
                    ),
                    cursorColor: const Color(0xFFB31217),
                    decoration: const InputDecoration(
                      hintText: "Add via Student Email...",
                      hintStyle: TextStyle(color: Color(0xFF9AA1AD)),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _isLoading ? null : _addGuardian,
                  child: Container(
                    width: 46,
                    height: 46,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFB31217),
                    ),
                    child: Center(
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.add,
                              color: Colors.white,
                              size: 24,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _guardianTile(String email) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EAF0)),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFE3E3),
            ),
            child: const Icon(Icons.person, color: Color(0xFFB31217), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 13.5,
                    color: Color(0xFF1B1B22),
                  ),
                ),
                const SizedBox(height: 3),
                const Text(
                  "Trusted Contact",
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF747A86),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Color(0xFFB31217)),
            onPressed: () => _removeGuardian(email),
          ),
        ],
      ),
    );
  }
}
