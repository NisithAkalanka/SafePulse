import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CreateListing extends StatefulWidget {
  const CreateListing({super.key});

  @override
  State<CreateListing> createState() => _CreateListingState();
}

class _CreateListingState extends State<CreateListing> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleCtrl = TextEditingController();
  final TextEditingController _priceCtrl = TextEditingController();
  final TextEditingController _descCtrl = TextEditingController();

  String? _selectedCategory;
  String? _selectedCondition;

  final List<File> _selectedImages = [];
  bool _isLoading = false;

  static const Color gRedStart = Color(0xFFFF4B4B);
  static const Color gRedMid = Color(0xFFB31217);
  static const Color gDarkEnd = Color(0xFF1B1B1B);

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedImages.length >= 3) {
      _showSnack("Maximum 3 photos allowed");
      return;
    }

    final XFile? res = await ImagePicker().pickImage(
      source: source,
      imageQuality: 10,
      maxWidth: 500,
      maxHeight: 500,
    );

    if (res != null) {
      setState(() => _selectedImages.add(File(res.path)));
    }
  }

  Future<void> _handlePublish() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final List<String> base64Images = [];

      if (_selectedImages.isNotEmpty) {
        for (final imgFile in _selectedImages) {
          final List<int> imageBytes = await imgFile.readAsBytes();
          final String base64Image = base64Encode(imageBytes);

          if (base64Image.length > 1000000) {
            throw Exception(
              'Selected image is too large. Please choose a smaller image.',
            );
          }

          base64Images.add(base64Image);
        }
      } else {
        base64Images.add('');
      }

      await FirebaseFirestore.instance.collection('listings').add({
        'sellerId': FirebaseAuth.instance.currentUser?.uid,
        'name': _titleCtrl.text.trim(),
        'price': _priceCtrl.text.trim(),
        'category': _selectedCategory,
        'condition': _selectedCondition,
        'description': _descCtrl.text.trim(),
        'image': base64Images.first,
        'images': base64Images,
        'status': 'Available',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      Navigator.pop(context);
      _showSnack("Listing Published Successfully!");
    } catch (e) {
      debugPrint(e.toString());
      _showSnack("Something went wrong!");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _priceCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color pageBg = isDark
        ? const Color(0xFF0F0F13)
        : const Color(0xFFF6F7FB);
    final Color cardBg = isDark ? const Color(0xFF1B1B22) : Colors.white;
    final Color inputBoxColor = isDark
        ? const Color(0xFF25252D)
        : const Color(0xFFF2F3F7);
    final Color textPrimary = isDark ? Colors.white : Colors.black;

    final double topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: pageBg,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: gRedMid))
          : Stack(
              children: [
                // --- 1. SCROLLABLE CONTENT ---
                Positioned.fill(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      children: [
                        // රතු පාට Premium Banner කොටස (Header එකට පිටුපසින් පටන් ගනී)
                        Container(
                          width: double.infinity,
                          padding: EdgeInsets.fromLTRB(
                            20,
                            topPadding + 85,
                            20,
                            35,
                          ),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              colors: [gRedStart, gRedMid, gDarkEnd],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              stops: [0.0, 0.62, 1.0],
                            ),
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(40),
                              bottomRight: Radius.circular(40),
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 20,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white10,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      "Publish item details clearly.",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Form Fields Section
                        Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                          child: Form(
                            key: _formKey,
                            child: Container(
                              padding: const EdgeInsets.all(22),
                              decoration: BoxDecoration(
                                color: cardBg,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 15,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Product Details",
                                    style: TextStyle(
                                      color: textPrimary,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  _buildInternalPhotoUploader(
                                    inputBoxColor,
                                    textPrimary,
                                  ),
                                  const SizedBox(height: 18),
                                  _buildInputBox(
                                    label: "Item Title",
                                    ctrl: _titleCtrl,
                                    icon: Icons.title_rounded,
                                    cb: inputBoxColor,
                                    tp: textPrimary,
                                    validator: (v) {
                                      if (v == null || v.isEmpty)
                                        return "Title is required";
                                      if (v.length < 5)
                                        return "Minimum 5 characters required";
                                      if (!RegExp(
                                        r'^[a-zA-Z0-9\s.,!?\-\(\)]+$',
                                      ).hasMatch(v))
                                        return "Symbols not allowed";
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInputBox(
                                    label: "Price (LKR)",
                                    ctrl: _priceCtrl,
                                    icon: Icons.payments_rounded,
                                    cb: inputBoxColor,
                                    tp: textPrimary,
                                    k: TextInputType.number,
                                    validator: (v) {
                                      if (v == null || v.isEmpty)
                                        return "Price is required";
                                      final p = double.tryParse(v);
                                      if (p == null || p <= 0)
                                        return "Enter a valid positive price";
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  _buildDrop(
                                    "Select Category",
                                    Icons.grid_view_rounded,
                                    const [
                                      "Tech",
                                      "Stationary",
                                      "Fashion",
                                      "Books",
                                      "Other",
                                    ],
                                    _selectedCategory,
                                    (val) =>
                                        setState(() => _selectedCategory = val),
                                    inputBoxColor,
                                    validator: (v) => v == null
                                        ? "Please select a category"
                                        : null,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildDrop(
                                    "Select Condition",
                                    Icons.info_outline,
                                    const ["New", "Used - Good", "Used - Fair"],
                                    _selectedCondition,
                                    (val) => setState(
                                      () => _selectedCondition = val,
                                    ),
                                    inputBoxColor,
                                    validator: (v) => v == null
                                        ? "Please select condition"
                                        : null,
                                  ),
                                  const SizedBox(height: 16),
                                  _buildInputBox(
                                    label: "Brief Description",
                                    ctrl: _descCtrl,
                                    icon: Icons.description_outlined,
                                    cb: inputBoxColor,
                                    tp: textPrimary,
                                    maxL: 3,
                                    validator: (v) {
                                      if (v == null || v.isEmpty)
                                        return "Description is required";
                                      if (v.length < 5)
                                        return "Minimum 5 characters";
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 35),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 58,
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: gRedMid,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            16,
                                          ),
                                        ),
                                        elevation: 6,
                                        shadowColor: gRedMid.withOpacity(0.3),
                                      ),
                                      onPressed: _handlePublish,
                                      child: const Text(
                                        "PUBLISH TO MARKET",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
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
                  ),
                ),

                // --- 2. FIXED STICKY HEADER (සැමවිටම ඉහළ රැඳී පවතී) ---
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.fromLTRB(15, topPadding + 10, 15, 12),
                    decoration: const BoxDecoration(
                      color: Colors.transparent, // Transparent Card effect
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new,
                            color: Colors.white,
                            size: 22,
                          ),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Center(
                            child: Text(
                              "New Listing",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 48,
                        ), // Balancing space for the center title
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildInternalPhotoUploader(Color cb, Color tp) {
    return Column(
      children: [
        GestureDetector(
          onTap: () => _showPickerMenu(context, cb, tp),
          child: Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: cb,
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.black12),
            ),
            child: _selectedImages.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.add_a_photo_outlined,
                        color: gRedMid,
                        size: 40,
                      ),
                      SizedBox(height: 12),
                      Text(
                        "Tap to upload photo",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        "Up to 3 photos",
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                  )
                : Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: Image.file(
                          _selectedImages.first,
                          width: double.infinity,
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                      ),
                      if (_selectedImages.length > 1)
                        Positioned(
                          right: 15,
                          bottom: 15,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "+${_selectedImages.length - 1} more",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedImages.clear()),
                          child: const CircleAvatar(
                            radius: 14,
                            backgroundColor: Colors.white70,
                            child: Icon(
                              Icons.refresh,
                              color: Colors.black,
                              size: 18,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
        if (_selectedImages.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: List.generate(
                _selectedImages.length,
                (i) => Container(
                  margin: const EdgeInsets.only(right: 10),
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                      image: FileImage(_selectedImages[i]),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInputBox({
    required String label,
    required TextEditingController ctrl,
    required IconData icon,
    required Color cb,
    required Color tp,
    int maxL = 1,
    TextInputType k = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cb,
        borderRadius: BorderRadius.circular(15),
      ),
      child: TextFormField(
        controller: ctrl,
        maxLines: maxL,
        keyboardType: k,
        validator: validator,
        style: TextStyle(color: tp, fontSize: 14, fontWeight: FontWeight.w600),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 12, color: Colors.grey),
          prefixIcon: Icon(icon, color: gRedMid, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(15),
        ),
      ),
    );
  }

  Widget _buildDrop(
    String label,
    IconData i,
    List<String> items,
    String? val,
    Function(String?) onChanged,
    Color cb, {
    String? Function(String?)? validator,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(
        color: cb,
        borderRadius: BorderRadius.circular(15),
      ),
      child: DropdownButtonFormField<String>(
        value: val,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 11, color: Colors.grey),
          prefixIcon: Icon(i, color: gRedMid, size: 20),
          border: InputBorder.none,
        ),
        items: items
            .map(
              (e) => DropdownMenuItem<String>(
                value: e,
                child: Text(
                  e,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
            .toList(),
        onChanged: onChanged,
        dropdownColor: cb,
        iconEnabledColor: gRedMid,
      ),
    );
  }

  void _showPickerMenu(BuildContext context, Color cb, Color tp) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cb,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text("Pick from Gallery"),
            onTap: () {
              Navigator.pop(ctx);
              _pickImage(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera),
            title: const Text("Take a Photo"),
            onTap: () {
              Navigator.pop(ctx);
              _pickImage(ImageSource.camera);
            },
          ),
        ],
      ),
    );
  }
}
