import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen>
    with SingleTickerProviderStateMixin {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _sliitIdController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _sliitIdController.dispose();
    super.dispose();
  }

  String _getDegreeType(String id) {
    String prefix = id.substring(0, 2).toUpperCase();
    if (prefix == "IT") return "Information Technology";
    if (prefix == "EN") return "Engineering";
    if (prefix == "BM") return "Business Management";
    if (prefix == "HS") return "Humanities & Sciences";
    if (prefix == "PG") return "Postgraduate";
    return "Undergraduate Student";
  }

  String _getBatchYear(String id) {
    String yearPart = id.substring(2, 4);
    return "20$yearPart";
  }

  bool _isValidName(String value) {
    final trimmed = value.trim();
    final reg = RegExp(r'^[A-Za-z]{1,10}$');
    return reg.hasMatch(trimmed);
  }

  bool _isValidSliitId(String value) {
    final trimmed = value.trim().toUpperCase();
    final reg = RegExp(r'^(IT|BM|EN|HS|PG)\d{8}$');
    return reg.hasMatch(trimmed);
  }

  bool _isValidEmail(String value) {
    final trimmed = value.trim();
    final reg = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return reg.hasMatch(trimmed);
  }

  bool _isValidPassword(String value) {
    final reg = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[^A-Za-z0-9]).{1,12}$',
    );
    return reg.hasMatch(value);
  }

  bool _validateForm() {
    String firstName = _firstNameController.text.trim();
    String lastName = _lastNameController.text.trim();
    String id = _sliitIdController.text.trim().toUpperCase();
    String email = _emailController.text.trim();
    String pw = _passwordController.text;
    String confirmPw = _confirmPasswordController.text;

    if (!_isValidName(firstName)) {
      _showError(
        "First name must contain only letters and be 10 characters or less.",
      );
      return false;
    }

    if (!_isValidName(lastName)) {
      _showError(
        "Last name must contain only letters and be 10 characters or less.",
      );
      return false;
    }

    if (!_isValidSliitId(id)) {
      _showError(
        "Invalid IT Number! Use IT/BM/EN/HS/PG + 8 digits. Example: IT23123456",
      );
      return false;
    }

    if (!_isValidEmail(email)) {
      _showError("Please enter a valid university or personal email address.");
      return false;
    }

    if (!_isValidPassword(pw)) {
      _showError(
        "Password must include upper/lowercase letters, a number, a special character, and be 12 characters or less.",
      );
      return false;
    }

    if (pw != confirmPw) {
      _showError("Re-entered password does not match.");
      return false;
    }

    return true;
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  Future<void> _signup() async {
    if (!_validateForm()) return;

    setState(() => _isLoading = true);

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      String uid = userCredential.user!.uid;
      String rawId = _sliitIdController.text.trim().toUpperCase();

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'sliit_id': rawId,
        'student_email': _emailController.text.trim(),
        'degree': _getDegreeType(rawId),
        'join_year': _getBatchYear(rawId),
        'role': 'student',
        'created_at': FieldValue.serverTimestamp(),
      });

      await userCredential.user?.sendEmailVerification();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Account created! Verification link sent to email."),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      _showError(e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C2230),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFF5363B),
                  Color(0xFFC90714),
                  Color(0xFF6B0009),
                  Color(0xFF140910),
                ],
                stops: [0.0, 0.42, 0.78, 1.0],
              ),
            ),
          ),
          Positioned(
            top: -120,
            right: -60,
            child: IgnorePointer(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF8A80).withOpacity(0.10),
                ),
              ),
            ),
          ),
          Positioned(
            top: 180,
            left: -90,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF3D0008).withOpacity(0.16),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                height: 170,
                decoration: const BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.elliptical(260, 58),
                    topRight: Radius.elliptical(260, 58),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFFFF5A63),
                      Color(0xFFD3192A),
                      Color(0x00140910),
                    ],
                    stops: [0.0, 0.24, 1.0],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 28,
                  vertical: 18,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 14),
                      Center(
                        child: AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final scale =
                                0.98 + (_pulseController.value * 0.04);
                            return Transform.scale(
                              scale: scale,
                              child: Container(
                                width: 106,
                                height: 106,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: const Color(0xFFF7F2F3),
                                    width: 4,
                                  ),
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color(0xFF5B1E2C),
                                      Color(0xFF1B0F18),
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.18),
                                      blurRadius: 16,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.shield_moon_rounded,
                                    color: Colors.white,
                                    size: 54,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 36),
                      const Center(
                        child: Text(
                          "WELCOME TO SAFEPLUS",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _inputField(
                        _firstNameController,
                        "FIRST NAME",
                        Icons.person_outline,
                        Colors.white,
                        hint: "Letters only",
                      ),
                      const SizedBox(height: 16),
                      _inputField(
                        _lastNameController,
                        "LAST NAME",
                        Icons.badge_outlined,
                        Colors.white,
                        hint: "Letters only",
                      ),
                      const SizedBox(height: 16),
                      _inputField(
                        _sliitIdController,
                        "IT NUMBER",
                        Icons.credit_card_outlined,
                        Colors.white,
                        hint: "IT23123456",
                        type: TextInputType.text,
                        upperCase: true,
                      ),
                      const SizedBox(height: 16),
                      _inputField(
                        _emailController,
                        "USERNAME OR EMAIL ADDRESS",
                        Icons.email_outlined,
                        Colors.white,
                        hint: "name@example.com",
                        type: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),
                      _inputField(
                        _passwordController,
                        "PASSWORD",
                        Icons.lock_outline,
                        Colors.white,
                        obscure: _obscurePassword,
                        hint: "Max 12 characters",
                        suffix: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.white60,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _inputField(
                        _confirmPasswordController,
                        "RE-ENTER PASSWORD",
                        Icons.lock_reset_outlined,
                        Colors.white,
                        obscure: _obscureConfirmPassword,
                        hint: "Type the same password",
                        suffix: IconButton(
                          onPressed: () {
                            setState(() {
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword;
                            });
                          },
                          icon: Icon(
                            _obscureConfirmPassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: Colors.white60,
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      _isLoading
                          ? const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            )
                          : SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: _signup,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF3150),
                                  foregroundColor: Colors.white,
                                  minimumSize: const Size(double.infinity, 52),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                                child: const Text(
                                  "SIGN UP",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                              ),
                            ),
                      const SizedBox(height: 18),
                      const Center(
                        child: Text(
                          "Names: letters only • IT/BM/EN/HS/PG + 8 digits • Email must contain @ and . • Password needs upper, lower, number, special, max 12",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 11,
                            height: 1.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            "Already have an account? Go back",
                            style: TextStyle(
                              color: Colors.white70,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return child;
  }

  Widget _inputField(
    TextEditingController c,
    String l,
    IconData i,
    Color theme, {
    bool obscure = false,
    TextInputType type = TextInputType.text,
    String? hint,
    Widget? suffix,
    bool upperCase = false,
  }) {
    return TextField(
      controller: c,
      obscureText: obscure,
      keyboardType: type,
      style: const TextStyle(color: Colors.white),
      textCapitalization: upperCase
          ? TextCapitalization.characters
          : TextCapitalization.none,
      onChanged: upperCase
          ? (value) {
              final updated = value.toUpperCase();
              if (updated != c.text) {
                c.value = TextEditingValue(
                  text: updated,
                  selection: TextSelection.collapsed(offset: updated.length),
                );
              }
            }
          : null,
      decoration: InputDecoration(
        labelText: l,
        hintText: hint,
        hintStyle: const TextStyle(
          color: Colors.white38,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        labelStyle: const TextStyle(
          color: Colors.white70,
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
        prefixIcon: Icon(i, color: Colors.white70, size: 20),
        suffixIcon: suffix,
        enabledBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white54, width: 1),
        ),
        focusedBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.white, width: 1.2),
        ),
        errorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent, width: 1),
        ),
        focusedErrorBorder: const UnderlineInputBorder(
          borderSide: BorderSide(color: Colors.redAccent, width: 1.2),
        ),
        filled: false,
        contentPadding: const EdgeInsets.symmetric(vertical: 14),
      ),
    );
  }
}
