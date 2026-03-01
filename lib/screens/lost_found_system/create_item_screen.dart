import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Ensure this is in pubspec.yaml
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

  static const Color spRed = Color(0xFFD32F2F);

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
      Navigator.pop(context); // Go back after success
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
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
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.96),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Image Upload UI
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 180,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[400]!),
                      ),
                      child: _selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(
                                _selectedImage!,
                                fit: BoxFit.cover,
                              ),
                            )
                          : const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.camera_alt,
                                  size: 50,
                                  color: Colors.grey,
                                ),
                                Text("Tap to upload photo (Recommended)"),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _titleController,
                    decoration: const InputDecoration(
                      labelText: "What is it?",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.shopping_bag),
                    ),
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),

                  // ✅ Category dropdown with icons
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    decoration: const InputDecoration(
                      labelText: "Category",
                      border: OutlineInputBorder(),
                    ),
                    items: categories.map((c) {
                      return DropdownMenuItem<String>(
                        value: c,
                        child: Row(
                          children: [
                            Icon(_iconForCategory(c), color: spRed),
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
                    decoration: const InputDecoration(
                      labelText: "Where? (Location)",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    validator: (val) => val!.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),

                  TextFormField(
                    controller: _descController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: "Description (Color, distinctive marks...)",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.description),
                    ),
                  ),
                  const SizedBox(height: 18),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: spRed,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "SUBMIT REPORT",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
