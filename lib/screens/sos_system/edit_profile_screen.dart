import 'dart:io';
import 'dart:convert'; // String බවට හරවන්න අවශ්‍යයි
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // ටෙක්ස්ට් පාලනය සඳහා controllers
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _degreeController = TextEditingController();
  final _joinYearController = TextEditingController();
  final _currentYearController = TextEditingController();
  final _sliitIdController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _birthDateTouched = false;

  String _birthDate = "Select Birthday";
  String? _profileImageBase64; // පින්තූරය Text එකක් ලෙස තබා ගැනීමට
  bool _isLoading = false;

  final user = FirebaseAuth.instance.currentUser;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadExistingData();
  }

  // 1. කලින් සේව් කර ඇති දත්ත Firestore එකෙන් ලෝඩ් කරමු
  _loadExistingData() async {
    setState(() => _isLoading = true);
    try {
      var doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      if (doc.exists) {
        var data = doc.data()!;
        setState(() {
          _firstNameController.text = (data['first_name'] ?? '').toString();
          _lastNameController.text = (data['last_name'] ?? '').toString();
          _phoneController.text = (data['phone'] ?? '').toString();
          _degreeController.text = (data['degree'] ?? '').toString();
          _joinYearController.text = (data['join_year'] ?? '').toString();
          _currentYearController.text = (data['current_year'] ?? '').toString();
          _sliitIdController.text = (data['sliit_id'] ?? '').toString();
          _birthDate = (data['birthday'] ?? 'Select Birthday').toString();
          _profileImageBase64 = data['profile_photo_base64'];
        });
      }
    } catch (e) {
      debugPrint("Load Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 2. පින්තූරයක් ගැලරියෙන් තෝරා එය Base64 Text එකක් බවට හැරවීම (Storage අවැසි නොවේ)
  Future<void> _pickProfileImage() async {
    final XFile? selected = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality:
          25, // Firestore document එකට ගැලපෙන ලෙස image quality එක 25% ට අඩු කලා
      maxWidth: 400, // පින්තූරයේ ප්‍රමාණය තවත් කුඩා කරනවා
    );

    if (selected != null) {
      File file = File(selected.path);
      Uint8List imageBytes = await file
          .readAsBytes(); // පින්තූරය Bytes වලට හැරවීම
      setState(() {
        _profileImageBase64 = base64Encode(
          imageBytes,
        ); // Bytes ටික String එකක් බවට හරවා ගබඩා කිරීම
      });
    }
  }

  // 3. සියලු විස්තර Firestore වලට සේව් කිරීම
  Future<void> _saveFullProfile() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _birthDateTouched = true;
    });

    final isFormValid = _formKey.currentState?.validate() ?? false;
    final hasValidBirthDate = _birthDate != "Select Birthday";

    if (!isFormValid || !hasValidBirthDate) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please complete all required fields correctly."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // කෙලින්ම Firestore එකට යූසර්ගේ ඩොකියුමන්ට් එකේ සියල්ල සේව් කරමු
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'sliit_id': _sliitIdController.text.trim().toUpperCase(),
        'phone': _phoneController.text.trim(),
        'degree': _degreeController.text.trim(),
        'join_year': _joinYearController.text.trim(),
        'current_year': _currentYearController.text.trim(),
        'birthday': _birthDate,
        'profile_photo_base64':
            _profileImageBase64, // මෙතනින් තමයි පින්තූරය DB එකට යන්නේ
        'student_email': user?.email,
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Profile updated and photo synced!"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Edit Profile",
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
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFB31217)),
            )
          : Stack(
              children: [
                Container(
                  height: 270,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFFF4B4B),
                        Color(0xFFB31217),
                        Color(0xFF1B1B1B),
                      ],
                      stops: [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  top: -80,
                  right: -30,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.08),
                    ),
                  ),
                ),
                SafeArea(
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
                      child: Column(
                        children: [
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF6F7FB),
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x14000000),
                                  blurRadius: 18,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                22,
                                18,
                                24,
                              ),
                              child: Column(
                                children: [
                                  Center(
                                    child: Stack(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: const LinearGradient(
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                              colors: [
                                                Color(0xFFFF5A63),
                                                Color(0xFFB31217),
                                              ],
                                            ),
                                            boxShadow: const [
                                              BoxShadow(
                                                color: Color(0x22000000),
                                                blurRadius: 16,
                                                offset: Offset(0, 8),
                                              ),
                                            ],
                                          ),
                                          child: CircleAvatar(
                                            radius: 54,
                                            backgroundColor: const Color(
                                              0xFF24131A,
                                            ),
                                            backgroundImage:
                                                _profileImageBase64 != null
                                                ? MemoryImage(
                                                    base64Decode(
                                                      _profileImageBase64!,
                                                    ),
                                                  )
                                                : null,
                                            child: _profileImageBase64 == null
                                                ? const Icon(
                                                    Icons.person,
                                                    size: 56,
                                                    color: Colors.white,
                                                  )
                                                : null,
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 2,
                                          right: 2,
                                          child: GestureDetector(
                                            onTap: _pickProfileImage,
                                            child: Container(
                                              width: 38,
                                              height: 38,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: const LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    Color(0xFFFF5A63),
                                                    Color(0xFFB31217),
                                                  ],
                                                ),
                                                border: Border.all(
                                                  color: Colors.white,
                                                  width: 2,
                                                ),
                                              ),
                                              child: const Icon(
                                                Icons.camera_alt,
                                                size: 18,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 26),
                                  _buildField(
                                    _firstNameController,
                                    "First Name",
                                    Icons.person_outline,
                                    validator: (value) {
                                      final v = (value ?? '').trim();
                                      if (v.isEmpty)
                                        return 'First name is required';
                                      if (!RegExp(
                                        r'^[A-Za-z]{1,10}$',
                                      ).hasMatch(v)) {
                                        return 'Letters only, max 10 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  _buildField(
                                    _lastNameController,
                                    "Last Name",
                                    Icons.person_outline,
                                    validator: (value) {
                                      final v = (value ?? '').trim();
                                      if (v.isEmpty)
                                        return 'Last name is required';
                                      if (!RegExp(
                                        r'^[A-Za-z]{1,10}$',
                                      ).hasMatch(v)) {
                                        return 'Letters only, max 10 characters';
                                      }
                                      return null;
                                    },
                                  ),
                                  _buildField(
                                    _sliitIdController,
                                    "SLIIT ID",
                                    Icons.badge_outlined,
                                    enabled: false,
                                    readOnly: true,
                                  ),
                                  _buildField(
                                    _phoneController,
                                    "Contact Number",
                                    Icons.phone_android_outlined,
                                    keyboard: TextInputType.phone,
                                    validator: (value) {
                                      final v = (value ?? '').trim();
                                      if (v.isEmpty)
                                        return 'Contact number is required';
                                      if (!RegExp(r'^0\d{9}$').hasMatch(v)) {
                                        return 'Must be 10 digits, start with 0';
                                      }
                                      return null;
                                    },
                                  ),
                                  _buildField(
                                    _degreeController,
                                    "Degree Program",
                                    Icons.school_outlined,
                                    enabled: false,
                                    readOnly: true,
                                  ),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildField(
                                          _joinYearController,
                                          "Join Year",
                                          Icons.event,
                                          keyboard: TextInputType.number,
                                          enabled: false,
                                          readOnly: true,
                                        ),
                                      ),
                                      const SizedBox(width: 14),
                                      Expanded(
                                        child: _buildField(
                                          _currentYearController,
                                          "Current Year",
                                          Icons.auto_graph,
                                          keyboard: TextInputType.number,
                                          validator: (value) {
                                            final v = (value ?? '').trim();
                                            if (v.isEmpty) return 'Required';
                                            if (!RegExp(
                                              r'^[1-4]$',
                                            ).hasMatch(v)) {
                                              return 'Only 1 to 4 allowed';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(
                                        color:
                                            _birthDateTouched &&
                                                _birthDate == "Select Birthday"
                                            ? Colors.redAccent
                                            : const Color(0xFFE2E5EC),
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x08000000),
                                          blurRadius: 10,
                                          offset: Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: ListTile(
                                      leading: const Icon(
                                        Icons.cake_outlined,
                                        color: Color(0xFFB31217),
                                      ),
                                      title: Text(
                                        _birthDate,
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: _birthDate == "Select Birthday"
                                              ? Colors.grey[700]
                                              : const Color(0xFF1B1B22),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      trailing: const Icon(
                                        Icons.calendar_month,
                                        size: 20,
                                        color: Color(0xFFB31217),
                                      ),
                                      onTap: () async {
                                        final picked = await showDatePicker(
                                          context: context,
                                          initialDate: DateTime(2002),
                                          firstDate: DateTime(1970),
                                          lastDate: DateTime.now(),
                                        );
                                        if (picked != null) {
                                          setState(() {
                                            _birthDateTouched = true;
                                            _birthDate = DateFormat(
                                              'yyyy-MM-dd',
                                            ).format(picked);
                                          });
                                        } else {
                                          setState(() {
                                            _birthDateTouched = true;
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                  if (_birthDateTouched &&
                                      _birthDate == "Select Birthday")
                                    const Padding(
                                      padding: EdgeInsets.only(top: 8, left: 4),
                                      child: Align(
                                        alignment: Alignment.centerLeft,
                                        child: Text(
                                          'Birthday is required',
                                          style: TextStyle(
                                            color: Colors.redAccent,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ),
                                  const SizedBox(height: 30),
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFFFF4B4B),
                                          Color(0xFFB31217),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x22000000),
                                          blurRadius: 16,
                                          offset: Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _saveFullProfile,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        minimumSize: const Size(
                                          double.infinity,
                                          58,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        "UPDATE ALL DETAILS",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType keyboard = TextInputType.text,
    String? Function(String?)? validator,
    bool enabled = true,
    bool readOnly = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        controller: ctrl,
        keyboardType: keyboard,
        validator: validator,
        enabled: enabled,
        readOnly: readOnly,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: const Color(0xFFB31217)),
          filled: true,
          fillColor: enabled ? Colors.white : const Color(0xFFF1F3F6),
          labelStyle: TextStyle(
            color: enabled ? const Color(0xFF666C78) : const Color(0xFF8C93A1),
            fontWeight: FontWeight.w600,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E5EC)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E5EC)),
          ),
          disabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFE2E5EC)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFB31217), width: 1.4),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
          ),
        ),
      ),
    );
  }
} //orig
