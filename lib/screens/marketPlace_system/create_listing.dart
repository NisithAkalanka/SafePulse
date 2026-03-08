import 'dart:io'; // මෙක අනිවාර්යයෙන්ම ඕනේ
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart'; // package එක import කළා

class CreateListing extends StatefulWidget {
  const CreateListing({super.key});
  @override
  _CreateListingState createState() => _CreateListingState();
}

class _CreateListingState extends State<CreateListing> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  String? _selectedCategory;
  String? _selectedCondition;
  bool _isLoading = false;

  // පින්තූරය තබා ගන්නා variable එක
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  static const Color primaryRed = Color(0xFFD32F2F); 
  static const Color intenseRed = Color(0xFFFF1744); 
  static const Color darkBg = Color(0xFF121212);

  // --- ගැලරියෙන් පින්තූරයක් තෝරා ගැනීමේ function එක ---
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _publishListing() async {
    if (_titleController.text.isEmpty || _priceController.text.isEmpty || _selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Missing information!")));
      return;
    }

    setState(() => _isLoading = true);

    try {
      // මෙහිදී image එක Firebase Storage එකට upload කළ යුතුයි, දැනට අපි කලින් වගේ dummy URL එකක් යමු
      await FirebaseFirestore.instance.collection('listings').add({
        'name': _titleController.text,
        'price': "Rs ${_priceController.text}",
        'description': _descriptionController.text,
        'category': _selectedCategory,
        'condition': _selectedCondition ?? "Good",
        'image': "https://images.unsplash.com/photo-1517336714731-489689fd1ca8?q=80&w=400", 
        'createdAt': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Listing Published!")));
      Navigator.pop(context);
    } catch (e) {
      debugPrint("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("New Listing", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _publishListing,
            child: const Text("Publish", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
          )
        ],
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [intenseRed, darkBg], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: _isLoading 
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 110, 20, 30),
              child: Column(
                children: [
                  // --- Photo Picker Area ---
                  GestureDetector(
                    onTap: _pickImage, // මෙතැනදී ගැලරිය විවෘත වෙනවා
                    child: _buildPhotoPickerUI(),
                  ),
                  const SizedBox(height: 25),

                  _buildTextInput("Listing Title", _titleController, Icons.edit_note_rounded),
                  const SizedBox(height: 15),
                  _buildTextInput("Price", _priceController, Icons.sell_rounded, keyboardType: TextInputType.number),
                  const SizedBox(height: 15),
                  _buildDropdownField("Select Category", Icons.grid_view_rounded, ["Books", "Tech", "Dorm Items", "Clothing"]),
                  const SizedBox(height: 15),
                  _buildTextInput("Description", _descriptionController, Icons.description_rounded, maxLines: 4),
                  const SizedBox(height: 35),
                ],
              ),
            ),
      ),
    );
  }

  // --- Photo Picker එකේ UI එක (පින්තූරය තේරුවාම එය පෙන්වනවා) ---
  Widget _buildPhotoPickerUI() {
    return Container(
      width: double.infinity,
      height: 200, // ටිකක් උස කළා පින්තූරය පේන්න
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15), 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: Colors.white30, width: 2)
      ),
      child: _selectedImage != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Image.file(_selectedImage!, fit: BoxFit.cover), // තෝරාගත් පින්තූරය මෙහි පෙන්වයි
            )
          : const Column(
              mainAxisAlignment: MainAxisAlignment.center, 
              children: [
                Icon(Icons.camera_enhance_rounded, color: Colors.white, size: 45),
                SizedBox(height: 10),
                Text("Tap to add product photo", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
    );
  }

  // --- Reusable Input field Helpers ---
  Widget _buildTextInput(String hint, TextEditingController ctrl, IconData icon, {int maxLines = 1, TextInputType keyboardType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: TextField(
        controller: ctrl,
        maxLines: maxLines,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: primaryRed),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(18),
        ),
      ),
    );
  }

  Widget _buildDropdownField(String hint, IconData icon, List<String> items) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
      child: DropdownButtonFormField<String>(
        hint: Text(hint),
        decoration: InputDecoration(icon: Icon(icon, color: primaryRed), border: InputBorder.none),
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
        onChanged: (val) => setState(() => _selectedCategory = val),
      ),
    );
  }
}