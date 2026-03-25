import 'dart:io';
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Maximum 3 photos allowed")));
      return;
    }
    final res = await ImagePicker().pickImage(source: source, imageQuality: 70);
    if (res != null) setState(() => _selectedImages.add(File(res.path)));
  }

  Future<void> _handlePublish() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        List<String> uploadedUrls = [];
        if (_selectedImages.isNotEmpty) {
          for (int i = 0; i < _selectedImages.length; i++) {
            String path =
                'listings/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
            await FirebaseStorage.instance
                .ref(path)
                .putFile(_selectedImages[i]);
            String url = await FirebaseStorage.instance
                .ref(path)
                .getDownloadURL();
            uploadedUrls.add(url);
          }
        } else {
          uploadedUrls.add(
            "https://firebasestorage.googleapis.com/v0/b/safeplus-77610.appspot.com/o/no_image.png?alt=media",
          );
        }

        await FirebaseFirestore.instance.collection('listings').add({
          'sellerId': FirebaseAuth.instance.currentUser?.uid,
          'name': _titleCtrl.text.trim(),
          'price': _priceCtrl.text.trim(),
          'category': _selectedCategory,
          'condition': _selectedCondition,
          'description': _descCtrl.text.trim(),
          'image': uploadedUrls.first,
          'images': uploadedUrls,
          'status': 'Available',
          'timestamp': FieldValue.serverTimestamp(),
        });

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Ad published successfully!"),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        debugPrint(e.toString());
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color pageBg = isDark
        ? const Color(0xFF0F0F13)
        : const Color(0xFFF6F7FB);
    final Color cardBg = isDark ? const Color(0xFF1B1B22) : Colors.white;
    final Color inputBoxColor = isDark
        ? const Color(0xFF25252D)
        : const Color(0xFFF2F3F7);
    final Color textPrimary = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: pageBg,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: gRedMid))
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // --- 1. Custom Header (දැන් මෙය සියල්ල සමඟ Scroll වේ) ---
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.only(
                      top: MediaQuery.of(context).padding.top + 10,
                      bottom: 35,
                      left: 20,
                      right: 20,
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
                        // --- Custom App Bar Row (Scrollable) ---
                        Row(
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
                            const SizedBox(width: 40),
                          ],
                        ),
                        const SizedBox(height: 30),
                        // Photo Area
                        _buildPhotoAreaCentered(cardBg, textPrimary),
                      ],
                    ),
                  ),

                  // --- 2. Form Card ---
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 15, 20, 40),
                    child: Form(
                      key: _formKey,
                      child: Container(
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: cardBg,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 15,
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Item Details",
                              style: TextStyle(
                                color: textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Item Title
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

                            // Price
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

                            // Category
                            _buildDrop(
                              "Select Category",
                              Icons.grid_view_rounded,
                              [
                                "Tech",
                                "Stationary",
                                "Fashion",
                                "Books",
                                "Other",
                              ],
                              _selectedCategory,
                              (val) => setState(() => _selectedCategory = val),
                              inputBoxColor,
                              validator: (v) =>
                                  v == null ? "Please select a category" : null,
                            ),
                            const SizedBox(height: 16),

                            // Condition
                            _buildDrop(
                              "Select Condition",
                              Icons.info_outline,
                              ["New", "Used - Good", "Used - Fair"],
                              _selectedCondition,
                              (val) => setState(() => _selectedCondition = val),
                              inputBoxColor,
                              validator: (v) =>
                                  v == null ? "Please select condition" : null,
                            ),
                            const SizedBox(height: 16),

                            // Description
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
                                  return "Please provide at least 5 characters";
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
                                    borderRadius: BorderRadius.circular(16),
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
    );
  }

  // --- Photo Slider Widget ---
  Widget _buildPhotoAreaCentered(Color cardBg, Color textPrimary) {
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...List.generate(
                _selectedImages.length,
                (index) => Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        image: DecorationImage(
                          image: FileImage(_selectedImages[index]),
                          fit: BoxFit.cover,
                        ),
                        border: Border.all(color: Colors.white30),
                      ),
                    ),
                    Positioned(
                      top: 0,
                      right: 5,
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => _selectedImages.removeAt(index)),
                        child: const CircleAvatar(
                          radius: 11,
                          backgroundColor: Colors.black54,
                          child: Icon(
                            Icons.close,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_selectedImages.length < 3)
                GestureDetector(
                  onTap: () => _showPickerMenu(context, cardBg, textPrimary),
                  child: Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white24,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: const Icon(
                      Icons.add_a_photo_outlined,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          "Add photos (Max 3)",
          style: TextStyle(color: Colors.white70, fontSize: 11),
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
        style: TextStyle(color: tp, fontSize: 14, fontWeight: FontWeight.w600),
        validator: validator,
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
    List<String> opt,
    String? val,
    Function(String?) ch,
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
        isExpanded: true,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(fontSize: 11, color: Colors.grey),
          prefixIcon: Icon(i, color: gRedMid, size: 20),
          border: InputBorder.none,
        ),
        items: opt
            .map(
              (e) => DropdownMenuItem(
                value: e,
                child: Text(e, style: const TextStyle(fontSize: 13)),
              ),
            )
            .toList(),
        onChanged: ch,
        dropdownColor: cb,
        iconEnabledColor: gRedMid,
      ),
    );
  }

  void _showPickerMenu(BuildContext context, Color cardBg, Color textPrimary) {
    showModalBottomSheet(
      context: context,
      backgroundColor: cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) => Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library, color: gRedMid),
            title: const Text("Pick from Gallery"),
            onTap: () {
              Navigator.pop(ctx);
              _pickImage(ImageSource.gallery);
            },
          ),
          ListTile(
            leading: const Icon(Icons.photo_camera, color: gRedMid),
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
