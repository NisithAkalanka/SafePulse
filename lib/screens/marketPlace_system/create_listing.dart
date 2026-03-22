import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class CreateListing extends StatefulWidget {
  const CreateListing({super.key});

  @override
  State<CreateListing> createState() => CreateListingState();
}

class CreateListingState extends State<CreateListing> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  String? _selectedCategory;
  bool _isLoading = false;

  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  static const Color primaryRed = Color(0xFFD32F2F);
  static const Color intenseRed = Color(0xFFFF1744);
  static const Color darkBg = Color(0xFF121212);

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _publishListing() async {
    if (_titleController.text.isEmpty ||
        _priceController.text.isEmpty ||
        _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Missing information!')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('listings').add({
        'name': _titleController.text,
        'price': 'Rs ${_priceController.text}',
        'description': _descriptionController.text,
        'category': _selectedCategory,
        'condition': 'Good',
        'image':
            'https://images.unsplash.com/photo-1517336714731-489689fd1ca8?q=80&w=400',
        'createdAt': Timestamp.now(),
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Listing Published!')),
      );
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: darkBg,
      appBar: AppBar(
        title: const Text('Add New Item'),
        centerTitle: true,
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _isLoading ? null : _pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(15),
                  image: _selectedImage != null
                      ? DecorationImage(
                          image: FileImage(_selectedImage!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: _selectedImage == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                          Text('Tap to add photo', style: TextStyle(color: Colors.grey)),
                        ],
                      )
                    : null,
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'What are you selling?',
                labelStyle: const TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _priceController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Price (Rs)',
                labelStyle: const TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 15),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Description',
                labelStyle: const TextStyle(color: Colors.white70),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              dropdownColor: darkBg,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Category',
                labelStyle: TextStyle(color: Colors.white70),
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Electronics', child: Text('Electronics')),
                DropdownMenuItem(value: 'Books', child: Text('Books')),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: _isLoading
                  ? null
                  : (v) => setState(() => _selectedCategory = v),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _publishListing,
                style: ElevatedButton.styleFrom(
                  backgroundColor: intenseRed,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text(
                        'Post Listing',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
