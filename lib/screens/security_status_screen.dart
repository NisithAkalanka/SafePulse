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
  bool _isNodeActive = false; // Firebase සම්බන්ධතාවය පරීක්ෂාව
  bool _isTwoFactorEnabled = false;
  bool _pinEnabled = false;
  bool _isChecking = true;

  @override
  void initState() {
    super.initState();
    _performSecurityScan();
  }

  // සියලුම ආරක්ෂක අංශ පරීක්ෂා කිරීමේ සජීවී Scan එකක් කරමු
  Future<void> _performSecurityScan() async {
    setState(() => _isChecking = true);

    // 1. යූසර් තොරතුරු Update කරගනිමු (ඊමේල් වෙරිෆිකේෂන් බලන්න මෙය ඕනේ)
    await user?.reload();
    user = FirebaseAuth.instance.currentUser;

    try {
      // 2. SOS Node Connectivity (ඇත්තටම Firestore වැඩද බලමු)
      final pingStart = DateTime.now();
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      _isNodeActive = true;

      // 3. Firestore එකෙන් Pin සහ 2FA status එක ගමු
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Security Checkup",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isChecking ? Icons.hourglass_empty : Icons.refresh),
            onPressed: _isChecking ? null : _performSecurityScan,
          ),
        ],
      ),
      body: _isChecking
          ? const Center(
              child: CircularProgressIndicator(color: Colors.redAccent),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // 1. ACCOUNT AUTHENTICATION
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

                // 2. SOS NODE CONNECTIVITY (LIVE STATUS)
                _securityTile(
                  "SOS Node Connectivity",
                  _isNodeActive
                      ? "Active and Encrypted"
                      : "Server Connection Lost",
                  Icons.wifi_tethering,
                  _isNodeActive ? Colors.blue : Colors.grey,
                ),

                // 3. TWO-FACTOR AUTH (2FA) - ටොගල් කළ හැකියි
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

                // 4. APP PRIVACY LOCK (පරණ PIN වැඩේ මෙතැනට සම්බන්ධයි)
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
                    ).then(
                      (_) => _performSecurityScan(),
                    ); // පින් එක සෙට් කරලා ආවාම ආයේ ස්කෑන් කරන්න
                  },
                ),

                const SizedBox(height: 30),
                const Center(
                  child: Text(
                    "Safety Level: Optimal",
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ),
              ],
            ),
    );
  }

  // 2FA ටොගල් කරන ලොජික් එක
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
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: c.withOpacity(0.1),
          child: Icon(i, color: c, size: 24),
        ),
        title: Text(
          t,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        subtitle: Text(
          s,
          style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w600),
        ),
        trailing: const Icon(Icons.chevron_right, size: 18),
      ),
    );
  }
}
