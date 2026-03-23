import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';

class CreateListing extends StatefulWidget {
  const CreateListing({super.key});

  @override
  State<CreateListing> createState() => _CreateListingState();
}

class _CreateListingState extends State<CreateListing> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedCategory;
  String? _selectedCondition;
  File? _selectedImage;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();

  // SafePulse Branding - Intense Red
  static const Color primaryRed = Color(0xFFD32F2F);
  static const Color darkBlack = Color(0xFF1A0101);
  static const Color darkBg = Color(0xFF0F0F13);

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );
    if (pickedFile != null)
      setState(() => _selectedImage = File(pickedFile.path));
  }

  // --- දත්ත පරීක්ෂා කර Publish කිරීමේ Logic එක ---
  Future<void> _handlePublish() async {
    // Form එක Validate කිරීම
    bool isValid = _formKey.currentState!.validate();

    // UI එක Update කිරීමට අවශ්‍ය නිසා (Red border පෙන්වීමට)
    setState(() {});

    if (isValid) {
      setState(() => _isLoading = true);
      String imageUrl =
          "https://via.placeholder.com/400"; // පින්තූරයක් නැතිවිට default එක
      try {
        if (_selectedImage != null) {
          String path = 'listings/${DateTime.now().millisecondsSinceEpoch}.jpg';
          await FirebaseStorage.instance.ref(path).putFile(_selectedImage!);
          imageUrl = await FirebaseStorage.instance.ref(path).getDownloadURL();
        }

        await FirebaseFirestore.instance.collection('listings').add({
          'sellerId': FirebaseAuth.instance.currentUser?.uid,
          'name': _titleController.text.trim(),
          'price': "Rs ${_priceController.text.trim()}",
          'category': _selectedCategory,
          'condition': _selectedCondition,
          'description': _descriptionController.text.trim(),
          'image': imageUrl,
          'status': 'Available',
          'createdAt': Timestamp.now(),
        });

        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Listing Published!"),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        debugPrint(e.toString());
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        title: const Text(
          "New listing",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _handlePublish,
            child: const Text(
              "Publish",
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [primaryRed, darkBlack],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 100, 20, 30),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode
                      .onUserInteraction, // පාවිච්චි කරන වෙලාවේදීම චෙක් වෙන්න
                  child: Column(
                    children: [
                      // --- ඡායාරූපය තෝරා ගැනීම ---
                      GestureDetector(
                        onTap: _pickImage,
                        child: _buildPhotoBoxUI(),
                      ),
                      const SizedBox(height: 25),

                      // Title
                      _buildFBStyleInput(
                        label: "Title",
                        controller: _titleController,
                        validator: (v) => (v == null || v.isEmpty)
                            ? "Enter a title to continue."
                            : null,
                      ),
                      const SizedBox(height: 15),

                      // Price
                      _buildFBStyleInput(
                        label: "Price",
                        controller: _priceController,
                        validator: (v) => (v == null || v.isEmpty)
                            ? "Enter a price to continue."
                            : null,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 15),

                      // Category
                      _buildFBStyleDropdown(
                        label: "Category",
                        items: ["Books", "Tech", "Stationary", "Fashion"],
                        value: _selectedCategory,
                        onChanged: (val) =>
                            setState(() => _selectedCategory = val),
                        error: "Select a category to finish your post.",
                      ),
                      const SizedBox(height: 15),

                      // Condition
                      _buildFBStyleDropdown(
                        label: "Condition",
                        items: [
                          "New",
                          "Used - Like New",
                          "Used - Good",
                          "Used - Fair",
                        ],
                        value: _selectedCondition,
                        onChanged: (val) =>
                            setState(() => _selectedCondition = val),
                        error: "Enter a condition to continue.",
                      ),
                      const SizedBox(height: 15),

                      // Description (Optional)
                      _buildFBStyleInput(
                        label: "Description",
                        controller: _descriptionController,
                        maxLines: 4,
                        hint: "Optional",
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // --- Photo Picker පෙනුම ---
  Widget _buildPhotoBoxUI() {
    return Container(
      width: double.infinity,
      height: 180,
      decoration: BoxDecoration(
        color: Colors.white12,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white30, width: 2),
      ),
      child: _selectedImage != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.file(_selectedImage!, fit: BoxFit.cover),
            )
          : const Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_a_photo, color: Colors.white, size: 40),
                SizedBox(height: 10),
                Text(
                  "Add photos",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
    );
  }

  // --- පින්තූරයේ ආකාරයට සකස් කළ Input එක ---
  Widget _buildFBStyleInput({
    required String label,
    required TextEditingController controller,
    String? Function(String?)? validator,
    int maxLines = 1,
    String? hint,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 15,
        ),

        // සාමාන්‍ය බෝඩරය
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blueAccent, width: 2),
        ),

        // ඔයා ඉල්ලපු ආකාරයට දෝෂ පවතින විට එන බෝඩරය (Thick Red)
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2.5),
        ),

        // දකුණු පස ඇති රතු ලක්ෂය (!)
        suffixIcon:
            validator != null &&
                controller.text.isEmpty &&
                _formKey.currentState?.validate() == false
            ? const Icon(Icons.error_rounded, color: Colors.red)
            : null,

        errorStyle: const TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  // --- Dropdown වල දෝෂ පෙන්වීම ---
  Widget _buildFBStyleDropdown({
    required String label,
    required List<String> items,
    String? value,
    required Function(String?) onChanged,
    required String error,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items
          .map((e) => DropdownMenuItem(value: e, child: Text(e)))
          .toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? error : null,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        errorStyle: const TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.bold,
        ),
        suffixIcon: value == null && _formKey.currentState?.validate() == false
            ? const Icon(Icons.error_rounded, color: Colors.red)
            : null,
      ),
    );
  }
}
