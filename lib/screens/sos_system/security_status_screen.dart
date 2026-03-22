import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'security_pin_screen.dart';

class SecurityStatusScreen extends StatefulWidget {
  const SecurityStatusScreen({super.key});

  @override
  State<SecurityStatusScreen> createState() => _SecurityStatusScreenState();
}

class _SecurityStatusScreenState extends State<SecurityStatusScreen> {
  User? user = FirebaseAuth.instance.currentUser;
  bool _isNodeActive = false;
  bool _isTwoFactorEnabled = false;
  bool _pinEnabled = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _performSecurityScan();
  }

  Future<void> _performSecurityScan() async {
    setState(() => _isChecking = true);

    await user?.reload();
    user = FirebaseAuth.instance.currentUser;

    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      _isNodeActive = true;

      var doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      _pinEnabled = doc.data()?['security_lock_enabled'] ?? false;
      _isTwoFactorEnabled = doc.data()?['two_factor_enabled'] ?? false;
    } catch (e) {
      _isNodeActive = false;
    }

    if (mounted) {
      setState(() => _isChecking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1B1B22),
        title: const Text(
          "Security Checkup",
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.2),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isChecking
                  ? Icons.hourglass_empty_rounded
                  : Icons.refresh_rounded,
              color: const Color(0xFFB31217),
            ),
            onPressed: _isChecking ? null : _performSecurityScan,
          ),
        ],
      ),
      body: _isChecking
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFB31217)),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                Container(
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
                        color: Color(0x22000000),
                        blurRadius: 16,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Color(0x33FFFFFF),
                        child: Icon(
                          Icons.shield_outlined,
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
                              "Security Overview",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              "Review account safety, app lock, and emergency protection status.",
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
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Protection Status",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 16,
                          color: Color(0xFF1B1B22),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        "Tap any item below to manage or improve your security setup.",
                        style: TextStyle(
                          color: Color(0xFF747A86),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _securityTile(
                        "Account Authentication",
                        user!.emailVerified
                            ? "Verified Safe"
                            : "Verify SLIIT Email Now",
                        user!.emailVerified
                            ? Icons.verified_user
                            : Icons.warning_amber_rounded,
                        user!.emailVerified ? Colors.green : Colors.redAccent,
                        onTap: user!.emailVerified
                            ? null
                            : () async {
                                await user!.sendEmailVerification();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Verification link sent! Check your inbox and spam folder.",
                                    ),
                                  ),
                                );
                              },
                      ),
                      const SizedBox(height: 12),
                      _securityTile(
                        "SOS Node Connectivity",
                        _isNodeActive
                            ? "Active and Encrypted"
                            : "Server Connection Lost",
                        Icons.wifi_tethering,
                        _isNodeActive ? Colors.blue : Colors.grey,
                      ),
                      const SizedBox(height: 12),
                      _securityTile(
                        "Two-Factor Auth (2FA)",
                        _isTwoFactorEnabled
                            ? "2FA Status: Enabled"
                            : "Enhance your protection",
                        Icons.phonelink_lock,
                        _isTwoFactorEnabled ? Colors.orange : Colors.grey,
                        onTap: () {
                          _toggleTwoFactor();
                        },
                      ),
                      const SizedBox(height: 12),
                      _securityTile(
                        "App Privacy Lock",
                        _pinEnabled
                            ? "Protected with PIN"
                            : "Lock not set (Risk detected)",
                        Icons.password,
                        _pinEnabled ? Colors.green : Colors.orangeAccent,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (c) => const SecurityPinScreen(),
                            ),
                          ).then((_) => _performSecurityScan());
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(18),
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
                  child: Row(
                    children: [
                      Container(
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
                        child: const Icon(
                          Icons.security_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Safety Level",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF1B1B22),
                              ),
                            ),
                            SizedBox(height: 3),
                            Text(
                              "Your current account protection status is being monitored for reliable emergency use.",
                              style: TextStyle(
                                fontSize: 11.5,
                                color: Color(0xFF747A86),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  void _toggleTwoFactor() async {
    bool newState = !_isTwoFactorEnabled;
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
      'two_factor_enabled': newState,
    }, SetOptions(merge: true));

    _performSecurityScan();

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(newState ? "2FA Enabled!" : "2FA Disabled!")),
    );
  }

  Widget _securityTile(
    String t,
    String s,
    IconData i,
    Color c, {
    VoidCallback? onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EAF0)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: c.withOpacity(0.12),
          child: Icon(i, color: c, size: 22),
        ),
        title: Text(
          t,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            s,
            style: TextStyle(
              color: c,
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right_rounded,
          size: 18,
          color: Color(0xFF747A86),
        ),
      ),
    );
  }
}
