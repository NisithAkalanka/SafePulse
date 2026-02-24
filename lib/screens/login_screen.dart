import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';   // මෙය HomeScreen පේජ් එක හඳුනා ගැනීමට
import 'signup_screen.dart'; // මෙය Signup පේජ් එක හඳුනා ගැනීමට

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ටෙක්ස්ට් ෆීල්ඩ් වල දත්ත ලබා ගැනීමට Controller භාවිතා කරමු
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // Login ක්‍රියාවලිය පටන් ගමු
  Future<void> _login() async {
    try {
      // 1. Firebase හරහා යූසර් ලොගින් කිරීම
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // 2. ලොගින් වීම සාර්ථක නම් Snackbar එකක් පෙන්වමු
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Logged In Successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      // 3. දැන් ඔයා ඉල්ලපු කොටස - සාර්ථක වුණාම HomeScreen එකට යමු
      // pushReplacement පාවිච්චි කරන්නේ යූසර්ට ආයේ ලොගින් පේජ් එකට Back බටන් එකෙන් එන්න බැරි වෙන්නයි
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
      
    } on FirebaseAuthException catch (e) {
      // වැරදි ඊමේල් හෝ පාස්වර්ඩ් එකක් ගැහුවොත් ඒ Error එක පෙන්වමු
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Login Failed: ${e.message}"),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      // වෙනත් ඕනෑම Error එකක් ආවොත් (Internet issue etc.)
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  @override
  void dispose() {
    // ෆයිල් එක වැසෙද්දී Controller මතකය නිදහස් කරමු
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
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // ඇප් ලෝගෝ එක වෙනුවට ලස්සන අයිකනයක්
              const Icon(Icons.security, size: 100, color: Colors.redAccent),
              const SizedBox(height: 10),
              const Text(
                "SafePulse",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const Text("Welcome Back to Safety"),
              const SizedBox(height: 40),
              
              // Email ඇතුළත් කරන TextField එක
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: "Email Address",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              
              // Password ඇතුළත් කරන TextField එක
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(
                  labelText: "Password",
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                obscureText: true,
              ),
              const SizedBox(height: 24),
              
              // Login බටන් එක
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _login,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.redAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text(
                    "LOGIN",
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              
              // Signup එකට යන බටන් එක
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const SignupScreen()),
                  );
                },
                child: const Text(
                  "Don't have an account? Sign Up",
                  style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}