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

<<<<<<< Updated upstream
  // SafePulse Branding - Intense Red
  static const Color primaryRed = Color(0xFFD32F2F);
  static const Color darkBlack = Color(0xFF1A0101);

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) setState(() => _selectedImage = File(pickedFile.path));
=======
  static const Color gRedStart = Color(0xFFFF4B4B);
  static const Color gRedMid = Color(0xFFB31217);
  static const Color gDarkEnd = Color(0xFF1B1B1B);

  Future<void> _pickImage(ImageSource source) async {
    if (_selectedImages.length >= 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Maximum 3 photos allowed")),
      );
      return;
    }
    final res = await ImagePicker().pickImage(source: source, imageQuality: 70);
    if (res != null) setState(() => _selectedImages.add(File(res.path)));
>>>>>>> Stashed changes
  }

  Future<void> _handlePublish() async {
<<<<<<< Updated upstream
    // Form එක Validate කිරීම
    bool isValid = _formKey.currentState!.validate();
    
    // UI එක Update කිරීමට අවශ්‍ය නිසා (Red border පෙන්වීමට)
    setState(() {}); 

    if (isValid) {
      setState(() => _isLoading = true);
      String imageUrl = "https://via.placeholder.com/400"; // පින්තූරයක් නැතිවිට default එක
=======
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

>>>>>>> Stashed changes
      try {
        List<String> uploadedUrls = [];
        if (_selectedImages.isNotEmpty) {
          for (int i = 0; i < _selectedImages.length; i++) {
            String path = 'listings/${DateTime.now().millisecondsSinceEpoch}_$i.jpg';
            await FirebaseStorage.instance.ref(path).putFile(_selectedImages[i]);
            String url = await FirebaseStorage.instance.ref(path).getDownloadURL();
            uploadedUrls.add(url);
          }
        } else {
          uploadedUrls.add("https://firebasestorage.googleapis.com/v0/b/safeplus-77610.appspot.com/o/no_image.png?alt=media");
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

<<<<<<< Updated upstream
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Listing Published!"), backgroundColor: Colors.green));
=======
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Ad published successfully!"), backgroundColor: Colors.green),
          );
        }
>>>>>>> Stashed changes
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
    final Color pageBg = isDark ? const Color(0xFF0F0F13) : const Color(0xFFF6F7FB);
    final Color cardBg = isDark ? const Color(0xFF1B1B22) : Colors.white;
    final Color inputBoxColor = isDark ? const Color(0xFF25252D) : const Color(0xFFF2F3F7);
    final Color textPrimary = isDark ? Colors.white : Colors.black;

    return Scaffold(
<<<<<<< Updated upstream
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text("New listing", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20), onPressed: () => Navigator.pop(context)),
        actions: [
          TextButton(onPressed: _handlePublish, child: const Text("Publish", style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold))),
        ],
      ),
      body: Container(
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(colors: [primaryRed, darkBlack], begin: Alignment.topCenter, end: Alignment.bottomCenter),
        ),
        child: _isLoading 
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 100, 20, 30),
                child: Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction, // පාවිච්චි කරන වෙලාවේදීම චෙක් වෙන්න
                  child: Column(children: [
                    // --- ඡායාරූපය තෝරා ගැනීම ---
                    GestureDetector(onTap: _pickImage, child: _buildPhotoBoxUI()),
                    const SizedBox(height: 25),

                    // Title
                    _buildFBStyleInput(
                      label: "Title",
                      controller: _titleController,
                      validator: (v) => (v == null || v.isEmpty) ? "Enter a title to continue." : null,
                    ),
                    const SizedBox(height: 15),

                    // Price
                    _buildFBStyleInput(
                      label: "Price",
                      controller: _priceController,
                      validator: (v) => (v == null || v.isEmpty) ? "Enter a price to continue." : null,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 15),

                    // Category
                    _buildFBStyleDropdown(
                      label: "Category",
                      items: ["Books", "Tech", "Stationary", "Fashion"],
                      value: _selectedCategory,
                      onChanged: (val) => setState(() => _selectedCategory = val),
                      error: "Select a category to finish your post.",
                    ),
                    const SizedBox(height: 15),

                    // Condition
                    _buildFBStyleDropdown(
                      label: "Condition",
                      items: ["New", "Used - Like New", "Used - Good", "Used - Fair"],
                      value: _selectedCondition,
                      onChanged: (val) => setState(() => _selectedCondition = val),
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
                  ]),
                ),
              ),
      ),
=======
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
                      right: 20
                    ),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [gRedStart, gRedMid, gDarkEnd], 
                        begin: Alignment.topCenter, 
                        end: Alignment.bottomCenter,
                        stops: [0.0, 0.62, 1.0]
                      ),
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(40), 
                        bottomRight: Radius.circular(40)
                      ),
                    ),
                    child: Column(
                      children: [
                        // --- Custom App Bar Row (Scrollable) ---
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
                              onPressed: () => Navigator.pop(context),
                            ),
                            const Expanded(
                              child: Center(
                                child: Text(
                                  "New Listing", 
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)
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
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Item Details", style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w900)),
                            const SizedBox(height: 20),

                            // Item Title
                            _buildInputBox(
                              label: "Item Title", ctrl: _titleCtrl, icon: Icons.title_rounded, cb: inputBoxColor, tp: textPrimary,
                              validator: (v) {
                                if (v == null || v.isEmpty) return "Title is required";
                                if (v.length < 5) return "Minimum 5 characters required";
                                if (!RegExp(r'^[a-zA-Z0-9\s.,!?\-\(\)]+$').hasMatch(v)) return "Symbols not allowed";
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Price
                            _buildInputBox(
                              label: "Price (LKR)", ctrl: _priceCtrl, icon: Icons.payments_rounded, cb: inputBoxColor, tp: textPrimary, k: TextInputType.number,
                              validator: (v) {
                                if (v == null || v.isEmpty) return "Price is required";
                                final p = double.tryParse(v);
                                if (p == null || p <= 0) return "Enter a valid positive price";
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),

                            // Category
                            _buildDrop(
                              "Select Category", Icons.grid_view_rounded, ["Tech", "Stationary" ,"Fashion","Books", "Other"], 
                              _selectedCategory, (val) => setState(() => _selectedCategory = val), inputBoxColor,
                              validator: (v) => v == null ? "Please select a category" : null,
                            ),
                            const SizedBox(height: 16),

                            // Condition
                            _buildDrop(
                              "Select Condition", Icons.info_outline, ["New", "Used - Good", "Used - Fair"], 
                              _selectedCondition, (val) => setState(() => _selectedCondition = val), inputBoxColor,
                              validator: (v) => v == null ? "Please select condition" : null,
                            ),
                            const SizedBox(height: 16),

                            // Description
                            _buildInputBox(
                              label: "Brief Description", ctrl: _descCtrl, icon: Icons.description_outlined, cb: inputBoxColor, tp: textPrimary, maxL: 3,
                              validator: (v) {
                                if (v == null || v.isEmpty) return "Description is required";
                                if (v.length < 5) return "Please provide at least 5 characters";
                                return null;
                              },
                            ),
                            
                            const SizedBox(height: 35),

                            SizedBox(
                              width: double.infinity, height: 58,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: gRedMid, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  elevation: 6, shadowColor: gRedMid.withOpacity(0.3),
                                ),
                                onPressed: _handlePublish, 
                                child: const Text("PUBLISH TO MARKET", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
>>>>>>> Stashed changes
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
              ...List.generate(_selectedImages.length, (index) => Stack(
                children: [
                  Container(
                    width: 100, height: 100, margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18), image: DecorationImage(image: FileImage(_selectedImages[index]), fit: BoxFit.cover),
                      border: Border.all(color: Colors.white30),
                    ),
                  ),
                  Positioned(top: 0, right: 5, child: GestureDetector(onTap: () => setState(() => _selectedImages.removeAt(index)), child: const CircleAvatar(radius: 11, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 14, color: Colors.white)))),
                ],
              )),
              if (_selectedImages.length < 3)
                GestureDetector(
                  onTap: () => _showPickerMenu(context, cardBg, textPrimary),
                  child: Container(
                    width: 100, height: 100, margin: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.white24, style: BorderStyle.solid)),
                    child: const Icon(Icons.add_a_photo_outlined, color: Colors.white, size: 30),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        const Text("Add photos (Max 3)", style: TextStyle(color: Colors.white70, fontSize: 11)),
      ],
    );
  }

  Widget _buildInputBox({required String label, required TextEditingController ctrl, required IconData icon, required Color cb, required Color tp, int maxL = 1, TextInputType k = TextInputType.text, String? Function(String?)? validator}) {
    return Container(
<<<<<<< Updated upstream
      width: double.infinity, height: 180,
      decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.white30, width: 2)),
      child: _selectedImage != null
          ? ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.file(_selectedImage!, fit: BoxFit.cover))
          : const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_a_photo, color: Colors.white, size: 40), SizedBox(height: 10), Text("Add photos", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
    );
  }

  // --- පින්තූරයේ ආකාරයට සකස් කළ Input එක ---
  Widget _buildFBStyleInput({required String label, required TextEditingController controller, String? Function(String?)? validator, int maxLines = 1, String? hint, TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      controller: controller,
      validator: validator,
      maxLines: maxLines,
      keyboardType: keyboardType,
      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        
        // සාමාන්‍ය බෝඩරය
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.blueAccent, width: 2)),

        // ඔයා ඉල්ලපු ආකාරයට දෝෂ පවතින විට එන බෝඩරය (Thick Red)
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2.5)),

        // දකුණු පස ඇති රතු ලක්ෂය (!)
        suffixIcon: validator != null && controller.text.isEmpty && _formKey.currentState?.validate() == false
            ? const Icon(Icons.error_rounded, color: Colors.red) 
            : null,
        
        errorStyle: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 13),
=======
      decoration: BoxDecoration(color: cb, borderRadius: BorderRadius.circular(15)),
      child: TextFormField(
        controller: ctrl, maxLines: maxL, keyboardType: k, style: TextStyle(color: tp, fontSize: 14, fontWeight: FontWeight.w600),
        validator: validator,
        decoration: InputDecoration(
          labelText: label, labelStyle: const TextStyle(fontSize: 12, color: Colors.grey),
          prefixIcon: Icon(icon, color: gRedMid, size: 20), border: InputBorder.none, contentPadding: const EdgeInsets.all(15)
        ),
>>>>>>> Stashed changes
      ),
    );
  }

<<<<<<< Updated upstream
  // --- Dropdown වල දෝෂ පෙන්වීම ---
  Widget _buildFBStyleDropdown({required String label, required List<String> items, String? value, required Function(String?) onChanged, required String error}) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
      onChanged: onChanged,
      validator: (v) => v == null ? error : null,
      decoration: InputDecoration(
        labelText: label, filled: true, fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.red, width: 2)),
        errorStyle: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        suffixIcon: value == null && _formKey.currentState?.validate() == false ? const Icon(Icons.error_rounded, color: Colors.red) : null,
      ),
    );
  }
=======
  Widget _buildDrop(String label, IconData i, List<String> opt, String? val, Function(String?) ch, Color cb, {String? Function(String?)? validator}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(color: cb, borderRadius: BorderRadius.circular(15)),
      child: DropdownButtonFormField<String>(
        value: val, isExpanded: true, validator: validator,
        decoration: InputDecoration(
          labelText: label, labelStyle: const TextStyle(fontSize: 11, color: Colors.grey),
          prefixIcon: Icon(i, color: gRedMid, size: 20), border: InputBorder.none
        ),
        items: opt.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: ch, dropdownColor: cb, iconEnabledColor: gRedMid,
      ),
    );
  }

  void _showPickerMenu(BuildContext context, Color cardBg, Color textPrimary) {
    showModalBottomSheet(context: context, backgroundColor: cardBg, shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
        builder: (ctx) => Wrap(children: [
              ListTile(leading: const Icon(Icons.photo_library, color: gRedMid), title: const Text("Pick from Gallery"), onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.gallery); }),
              ListTile(leading: const Icon(Icons.photo_camera, color: gRedMid), title: const Text("Take a Photo"), onTap: () { Navigator.pop(ctx); _pickImage(ImageSource.camera); }),
            ]));
  }
>>>>>>> Stashed changes
}