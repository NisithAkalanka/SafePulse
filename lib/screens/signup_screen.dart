import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _sliitIdController = TextEditingController(); // SLIIT ID එක සඳහා
  bool _isLoading = false;

  // Validation Logic - දත්ත නිවැරදිදැයි බැලීම
  bool _validateInputs() {
    String email = _emailController.text.trim();
    String password = _passwordController.text.trim();
    String sliitId = _sliitIdController.text.trim();

    if (sliitId.isEmpty) {
      _showError("SLIIT ID number is required!");
      return false;
    }
    if (email.isEmpty || !email.contains('@')) {
      _showError("Please enter a valid University email!");
      return false;
    }
    if (password.length < 6) {
      _showError("Password must be at least 6 characters long!");
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.redAccent),
    );
  }

  Future<void> _signup() async {
    if (!_validateInputs()) return; // Validation පරාජිත නම් නවත්වන්න

    setState(() { _isLoading = true; });

    try {
      // 1. Firebase Auth හරහා ගිණුම සෑදීම
      UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      User? user = userCredential.user;

      if (user != null) {
        // 2. SLIIT ID සහ අනෙකුත් විස්තර Firestore හි සේව් කිරීම (Profile එකේ පෙන්වීමට)
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'sliit_id': _sliitIdController.text.trim().toUpperCase(),
          'student_email': user.email,
          'created_at': FieldValue.serverTimestamp(),
          'first_name': '', // පසුව profile එකේදී edit කළ හැක
          'address': '',
        });

        // 3. Email Verification ලින්ක් එක යැවීම
        await user.sendEmailVerification();

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Account created! Check your email for the verification link."),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 6),
          ),
        );

        Navigator.pop(context); // ආපසු Login පිටුවට
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? "An error occurred during signup");
    } catch (e) {
      _showError(e.toString());
    } finally {
      setState(() { _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Create SafePulse Account"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            const Icon(Icons.app_registration, size: 80, color: Colors.redAccent),
            const SizedBox(height: 30),

            // SLIIT ID Field
            TextField(
              controller: _sliitIdController,
              decoration: const InputDecoration(
                labelText: "SLIIT ID Number (e.g. IT21XXXXXX)",
                prefixIcon: Icon(Icons.badge_outlined),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 15),

            // Email Field
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: "Student Email Address",
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 15),

            // Password Field
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                labelText: "Create Password (Min 6 chars)",
                prefixIcon: Icon(Icons.lock_outline),
                border: OutlineInputBorder(),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 30),

            _isLoading 
              ? const CircularProgressIndicator()
              : ElevatedButton(
                  onPressed: _signup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("REGISTER NOW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
          ],
        ),
      ),
    );
  }
}