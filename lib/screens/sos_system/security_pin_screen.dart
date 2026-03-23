import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SecurityPinScreen extends StatefulWidget {
  const SecurityPinScreen({super.key});
  @override
  State<SecurityPinScreen> createState() => _SecurityPinScreenState();
}

class _SecurityPinScreenState extends State<SecurityPinScreen> {
  final _pinController = TextEditingController();
  final user = FirebaseAuth.instance.currentUser;
  bool _hasExistingPin = false; // දැනට පින් එකක් තිබේද?

  @override
  void initState() {
    super.initState();
    _checkExistingPin();
  }

  // 1. කලින් සෙට් කරලා තියෙන පින් එකක් තියෙනවද බලමු
  Future<void> _checkExistingPin() async {
    var doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();
    if (doc.exists && doc.data()?['app_pin'] != null) {
      setState(() {
        _hasExistingPin = true;
      });
    }
  }

  // 2. පින් එක සේව් කිරීම හෝ යාවත්කාලීන කිරීම
  Future<void> _saveOrUpdatePin() async {
    if (_pinController.text.length != 4) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Enter 4 digits!")));
      return;
    }
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
      'app_pin': _pinController.text,
      'security_lock_enabled': true,
    }, SetOptions(merge: true));

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("✅ Security PIN Saved!"),
        backgroundColor: Colors.green,
      ),
    );
  }

  // 3. පින් එක සම්පූර්ණයෙන්ම අයින් කිරීම (Disable Lock)
  Future<void> _disablePin() async {
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'app_pin': FieldValue.delete(),
      'security_lock_enabled': false,
    });
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("🛡️ Security Lock Disabled!")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_hasExistingPin ? "Update PIN" : "Setup PIN"),
        backgroundColor: Colors.redAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          children: [
            Icon(
              _hasExistingPin ? Icons.lock_reset : Icons.security,
              size: 80,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 20),
            Text(
              _hasExistingPin
                  ? "Change your existing security lock"
                  : "Secure your personal safety data",
            ),
            const SizedBox(height: 40),
            TextField(
              controller: _pinController,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 30, letterSpacing: 15),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: "••••",
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveOrUpdatePin,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
                backgroundColor: Colors.redAccent,
              ),
              child: const Text(
                "CONFIRM PIN",
                style: TextStyle(color: Colors.white),
              ),
            ),

            // --- අයින් කිරීමේ බටන් එක පෙන්වන්නේ කලින් එකක් තිබේනම් පමණි ---
            if (_hasExistingPin)
              TextButton(
                onPressed: _disablePin,
                child: const Text(
                  "Remove Password Lock",
                  style: TextStyle(color: Colors.red),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
