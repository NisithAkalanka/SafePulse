import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'lost_item_model.dart';
import 'lost_found_service.dart';

class CreateItemScreen extends StatefulWidget {
  final String postType; // 'Lost' or 'Found'
  const CreateItemScreen({Key? key, required this.postType}) : super(key: key);

  @override
  State<CreateItemScreen> createState() => _CreateItemScreenState();
}

class _CreateItemScreenState extends State<CreateItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _locationController = TextEditingController();

  String _selectedCategory = 'Electronics';
  File? _selectedImage;
  bool _isLoading = false;

  // SafePulse palette (matching leader style)
  static const Color spRed = Color(0xFFE53935);
  static const Color spDark = Color(0xFFB71C1C);

  // ✅ UPDATED categories (Removed Clothing, added Watch + Student ID Card)
  final List<String> categories = const [
    'Electronics',
    'ID/Documents',
    'Student ID Card',
    'Watch',
    'Keys',
    'Books',
    'Others',
  ];

  IconData _iconForCategory(String c) {
    switch (c) {
      case 'Electronics':
        return Icons.devices;
      case 'ID/Documents':
        return Icons.description;
      case 'Student ID Card':
        return Icons.badge;
      case 'Watch':
        return Icons.watch;
      case 'Keys':
        return Icons.key;
      case 'Books':
        return Icons.menu_book;
      default:
        return Icons.category;
    }
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _selectedImage = File(picked.path));
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;

      final newItem = LostItem(
        id: '',
        userId: user?.uid ?? 'unknown',
        userName: user?.email?.split('@')[0] ?? 'Student',
        type: widget.postType,
        title: _titleController.text,
        category: _selectedCategory,
        description: _descController.text,
        location: _locationController.text,
        imageUrl: '', // Handled in Service (mock/memory mode)
        status: 'Active',
        timestamp: DateTime.now(),
      );

      await LostFoundService().createPost(newItem, _selectedImage);
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  InputDecoration _fieldDeco({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.85)),
      prefixIcon: Icon(icon, color: Colors.white.withOpacity(0.9)),
      filled: true,
      fillColor: Colors.white.withOpacity(0.10),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.18)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.35)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.orangeAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Colors.orangeAccent),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [spRed, spDark],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text("Report ${widget.postType} Item"),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
          child: Column(
            children: [
              // Top info card (leader style)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.14)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.report, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        "Add details clearly so others can identify it fast.",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.92),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Main glass card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withOpacity(0.14)),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Image upload (more like leader)
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          height: 185,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(18),
                            border:
                                Border.all(color: Colors.white.withOpacity(0.14)),
                          ),
                          child: _selectedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(18),
                                  child: Image.file(
                                    _selectedImage!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.add_a_photo,
                                      size: 46,
                                      color: Colors.white.withOpacity(0.9),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      "Tap to upload photo",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.92),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Recommended for faster verification",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.75),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),

                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _titleController,
                        style: const TextStyle(color: Colors.white),
                        decoration:
                            _fieldDeco(label: "What is it?", icon: Icons.shopping_bag),
                        validator: (val) => val!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),

                      // Category dropdown with icons
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        dropdownColor: const Color(0xFF7A0F0F),
                        style: const TextStyle(color: Colors.white),
                        decoration: _fieldDeco(
                          label: "Category",
                          icon: Icons.category,
                        ),
                        items: categories.map((c) {
                          return DropdownMenuItem<String>(
                            value: c,
                            child: Row(
                              children: [
                                Icon(_iconForCategory(c),
                                    color: Colors.white.withOpacity(0.95)),
                                const SizedBox(width: 10),
                                Text(c),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (val) =>
                            setState(() => _selectedCategory = val.toString()),
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _locationController,
                        style: const TextStyle(color: Colors.white),
                        decoration: _fieldDeco(
                          label: "Where? (Location)",
                          icon: Icons.location_on,
                        ),
                        validator: (val) => val!.isEmpty ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _descController,
                        style: const TextStyle(color: Colors.white),
                        maxLines: 3,
                        decoration: _fieldDeco(
                          label: "Description (marks, color...)",
                          icon: Icons.description,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Primary CTA (leader style)
                      SizedBox(
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            disabledBackgroundColor:
                                Colors.white.withOpacity(0.55),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(
                                    color: spDark,
                                    strokeWidth: 2.4,
                                  ),
                                )
                              : const Text(
                                  "SUBMIT REPORT",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: spDark,
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
    );
  }
}