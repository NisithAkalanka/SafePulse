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
      var doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
      if (doc.exists) {
        var data = doc.data()!;
        setState(() {
          _firstNameController.text = data['first_name'] ?? "";
          _lastNameController.text = data['last_name'] ?? "";
          _phoneController.text = data['phone'] ?? "";
          _degreeController.text = data['degree'] ?? "";
          _joinYearController.text = data['join_year'] ?? "";
          _currentYearController.text = data['current_year'] ?? "";
          _sliitIdController.text = data['sliit_id'] ?? "";
          _birthDate = data['birthday'] ?? "Select Birthday";
          _profileImageBase64 = data['profile_photo_base64']; // සේව් කල පින්තූරය ලබා ගැනීම
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
      imageQuality: 25, // Firestore document එකට ගැලපෙන ලෙස image quality එක 25% ට අඩු කලා
      maxWidth: 400,    // පින්තූරයේ ප්‍රමාණය තවත් කුඩා කරනවා
    );

    if (selected != null) {
      File file = File(selected.path);
      Uint8List imageBytes = await file.readAsBytes(); // පින්තූරය Bytes වලට හැරවීම
      setState(() {
        _profileImageBase64 = base64Encode(imageBytes); // Bytes ටික String එකක් බවට හරවා ගබඩා කිරීම
      });
    }
  }

  // 3. සියලු විස්තර Firestore වලට සේව් කිරීම
  Future<void> _saveFullProfile() async {
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
        'profile_photo_base64': _profileImageBase64, // මෙතනින් තමයි පින්තූරය DB එකට යන්නේ
        'student_email': user?.email,
        'last_updated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("✅ Profile updated and photo synced!"), backgroundColor: Colors.green));
      Navigator.pop(context, true); 
      
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.redAccent));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Edit Profile Details"), 
        backgroundColor: Colors.redAccent, 
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.redAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  // --- PROFILE PHOTO AREA ---
                  Center(
                    child: Stack(
                      children: [
                        CircleAvatar(
                          radius: 55,
                          backgroundColor: Colors.red[50],
                          // Base64 String එක පින්තූරයක් ලෙස පෙන්වමු
                          backgroundImage: _profileImageBase64 != null 
                              ? MemoryImage(base64Decode(_profileImageBase64!))
                              : null,
                          child: _profileImageBase64 == null
                              ? const Icon(Icons.person, size: 60, color: Colors.redAccent)
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _pickProfileImage,
                            child: const CircleAvatar(
                              backgroundColor: Colors.redAccent,
                              radius: 18,
                              child: Icon(Icons.camera_alt, size: 18, color: Colors.white),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 35),

                  _buildField(_firstNameController, "First Name", Icons.person_outline),
                  _buildField(_lastNameController, "Last Name", Icons.person_outline),
                  _buildField(_sliitIdController, "SLIIT ID", Icons.badge_outlined),
                  _buildField(_phoneController, "Contact Number", Icons.phone_android_outlined, keyboard: TextInputType.phone),
                  _buildField(_degreeController, "Degree Program", Icons.school_outlined),
                  
                  Row(
                    children: [
                      Expanded(child: _buildField(_joinYearController, "Join Year", Icons.event, keyboard: TextInputType.number)),
                      const SizedBox(width: 15),
                      Expanded(child: _buildField(_currentYearController, "Current Year", Icons.auto_graph, keyboard: TextInputType.number)),
                    ],
                  ),
                  
                  // Birthday Picker
                  Container(
                    decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade400), borderRadius: BorderRadius.circular(10)),
                    child: ListTile(
                      leading: const Icon(Icons.cake_outlined, color: Colors.redAccent),
                      title: Text(_birthDate, style: const TextStyle(fontSize: 16)),
                      trailing: const Icon(Icons.calendar_month, size: 20),
                      onTap: () async {
                        DateTime? picked = await showDatePicker(
                          context: context, 
                          initialDate: DateTime(2002), 
                          firstDate: DateTime(1970), 
                          lastDate: DateTime.now()
                        );
                        if (picked != null) {
                          setState(() => _birthDate = DateFormat('yyyy-MM-dd').format(picked));
                        }
                      },
                    ),
                  ),

                  const SizedBox(height: 40),

                  ElevatedButton(
                    onPressed: _saveFullProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      minimumSize: const Size(double.infinity, 58),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                    ),
                    child: const Text("UPDATE ALL DETAILS", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String label, IconData icon, {TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: TextField(
        controller: ctrl,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: Colors.redAccent),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }
}