import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SecurityStatusScreen extends StatelessWidget {
  const SecurityStatusScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text("Security Checkup")),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Email Verify
          _securityTile(
            "Account Authentication", 
            user!.emailVerified ? "Email Verified" : "Unverified Email", 
            user.emailVerified ? Icons.verified_user : Icons.gpp_maybe, 
            user.emailVerified ? Colors.green : Colors.red,
            onTap: () async {
              if (!user.emailVerified) {
                await user.sendEmailVerification();
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Link sent!")));
              }
            }
          ),

          // Connectivity status
          _securityTile("SOS Node Connectivity", "Secure Connection Active", Icons.lan, Colors.blue),

          // Two Factor UI placeholder
          _securityTile("Two-Factor Auth (2FA)", "Highly Recommended", Icons.password, Colors.orange),

          // Screen lock option
          _securityTile("App Privacy Lock", "Setup a Screen Lock", Icons.fingerprint, Colors.black87),
        ],
      ),
    );
  }

  Widget _securityTile(String title, String subtitle, IconData icon, Color color, {VoidCallback? onTap}) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color, size: 28),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle, style: TextStyle(color: color.withOpacity(0.8))),
        trailing: const Icon(Icons.arrow_forward_ios, size: 14),
      ),
    );
  }
}