import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'signup_screen.dart'; // Signup පේජ් එක හඳුනා ගැනීමට

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // TextField පාලනය කිරීමට Controllers
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // ලොගින් ක්‍රියාවලිය
  Future<void> _login() async {
    try {
      // 1. Firebase ලොගින් කිරීම
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (!mounted) return;

      // 2. ලොගින් වීම සාර්ථක නම් පණිවිඩයක් පෙන්වීම
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Logged In Successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      // 3. --- මෙන්න මෙතන තමයි වැදගත්ම වෙනස ---
      // අලුත් පේජ් එකකට (HomeScreen) 'Push' කරන්නේ නැතිව, දැනට තිබෙන Login පේජ් එක 'Pop' කර (වසා) දමනවා.
      // එවිට යූසර් ප්‍රොෆයිල් ටැබ් එකෙන් ආවා නම් නැවත එතැනටම සාර්ථකව ඇතුළු වෙනවා.
      Navigator.pop(context);
      
    } on FirebaseAuthException catch (e) {
      // වැරදි ඊමේල්/පාස්වර්ඩ් සඳහා Error එක පෙන්වීම
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Login Failed: ${e.message}"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("SafePulse Login"),
        centerTitle: true,
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        // පස්සට යාමේ ඊතලය අවශ්‍ය නිසා මම මෙය default තැබුවා
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ඇප් එකේ Icon එක සහ නම
              const Icon(Icons.security, size: 100, color: Colors.redAccent),
              const SizedBox(height: 10),
              const Text(
                "SafePulse",
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, letterSpacing: 1.2),
              ),
              const Text("Welcome back to Guardian SafeMode", style: TextStyle(color: Colors.grey)),
              const SizedBox(height: 40),
              
              // Email Field
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email Address",
                  hintText: "Enter your registered email",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              
              // Password Field
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: "Password",
                  hintText: "Enter your password",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 30),
              
              // Login Button
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: const Text(
                    "LOGIN",
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Signup Screen එකට යාමට බටන් එක
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignupScreen()),
                  );
                },
                child: RichText(
                  text: const TextSpan(
                    text: "Don't have an account? ",
                    style: TextStyle(color: Colors.black54),
                    children: [
                      TextSpan(
                        text: "Sign Up",
                        style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}