import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageListingsScreen extends StatelessWidget {
  const ManageListingsScreen({super.key});

  static const Color gRedStart = Color(0xFFFF4B4B);
  static const Color gRedMid = Color(0xFFB31217);
  static const Color gDarkEnd = Color(0xFF1B1B1B);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color pageBg = isDark ? const Color(0xFF0F0F13) : const Color(0xFFF6F7FB);
    final Color cardBg = isDark ? const Color(0xFF1B1B22) : Colors.white;
    final Color textPrimary = isDark ? Colors.white : const Color(0xFF1B1B22);
    final Color textSecondary = isDark ? const Color(0xFFB7BBC6) : const Color(0xFF747A86);
    final Color borderColor = isDark ? const Color(0xFF34343F) : const Color(0xFFE8EAF0);

    final String? currentUserId = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: pageBg,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(10, 60, 20, 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [gRedStart, gRedMid, gDarkEnd], stops: [0.0, 0.62, 1.0],
                ),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(34), bottomRight: Radius.circular(34)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("Manage My Ads", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800)),
                        Text("Edit or remove your campus items", style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('listings')
                  .where('sellerId', isEqualTo: currentUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: gRedMid));
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Padding(padding: const EdgeInsets.only(top: 100), child: Center(child: Text("No items listed.", style: TextStyle(color: textSecondary))));
                }

                final docs = snapshot.data!.docs;
                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var doc = docs[index];
                    var data = doc.data() as Map<String, dynamic>;
                    return _buildModernManageCard(context, doc.id, data, cardBg, textPrimary, textSecondary, borderColor);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernManageCard(BuildContext context, String docId, Map<String, dynamic> data, Color cb, Color tp, Color ts, Color bc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cb, borderRadius: BorderRadius.circular(25), border: Border.all(color: bc, width: 1.2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: (data['image'] != null && data['image'].toString().length > 100)
                    ? Image.memory(base64Decode(data['image']), width: 80, height: 80, fit: BoxFit.cover)
                    : Container(width: 80, height: 80, color: Colors.grey[100], child: const Icon(Icons.image)),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(data['name'] ?? "Item", style: TextStyle(color: tp, fontWeight: FontWeight.w800, fontSize: 17), maxLines: 1),
                  Text("Rs. ${data['price']}", style: const TextStyle(color: gRedMid, fontWeight: FontWeight.w900, fontSize: 15)),
                ]),
              ),
            ],
          ),
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(thickness: 0.5)),
          Row(
            children: [
              Expanded(child: ElevatedButton(onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (c) => EditListingScreen(docId: docId, data: data))), style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent), child: const Text("UPDATE", style: TextStyle(color: Colors.white)))),
              const SizedBox(width: 10),
              Expanded(child: ElevatedButton(onPressed: () => _confirmDelete(context, docId), style: ElevatedButton.styleFrom(backgroundColor: gRedMid), child: const Text("DELETE", style: TextStyle(color: Colors.white)))),
            ],
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      title: const Text("Permanent Removal?"),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Cancel")),
        TextButton(onPressed: () async { await FirebaseFirestore.instance.collection('listings').doc(id).delete(); Navigator.pop(ctx); }, child: const Text("Delete")),
      ],
    ));
  }
}

// --- ඔබ ඉල්ලූ EDIT AD (Create Listing Form Style) SCREEN ---
class EditListingScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  const EditListingScreen({super.key, required this.docId, required this.data});

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleCtrl, _priceCtrl, _descCtrl;
  String? _cat, _cond;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.data['name']);
    _priceCtrl = TextEditingController(text: widget.data['price'].toString().replaceAll("Rs. ", ""));
    _descCtrl = TextEditingController(text: widget.data['description']);
    _cat = widget.data['category'];
    _cond = widget.data['condition'];
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBg = isDark ? const Color(0xFF1B1B22) : Colors.white;
    final Color tp = isDark ? Colors.white : Colors.black87;
    final Color bc = isDark ? const Color(0xFF34343F) : const Color(0xFFE8EAF0);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F13) : const Color(0xFFF6F7FB),
      extendBodyBehindAppBar: true,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, title: const Text("Edit Ad", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
      body: _isLoading 
          ? const Center(child: CircularProgressIndicator()) 
          : SingleChildScrollView(
              child: Column(children: [
                // ඔබගේ Header පෙනුම
                Container(
                  width: double.infinity, padding: const EdgeInsets.fromLTRB(20, 110, 20, 30),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(colors: [ManageListingsScreen.gRedStart, ManageListingsScreen.gRedMid, ManageListingsScreen.gDarkEnd], stops: [0.0, 0.62, 1.0], begin: Alignment.topCenter, end: Alignment.bottomCenter),
                    borderRadius: BorderRadius.only(bottomLeft: Radius.circular(34), bottomRight: Radius.circular(34)),
                  ),
                  child: Center(child: ClipRRect(borderRadius: BorderRadius.circular(15), child: (widget.data['image'] != null) ? Image.memory(base64Decode(widget.data['image']), height: 100, width: 100, fit: BoxFit.cover) : const Icon(Icons.image, color: Colors.white))),
                ),
                // --- ඔබ ඉල්ලූ VALIDATED FORM කොටස ---
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Form(
                    key: _formKey,
                    child: Column(children: [
                      // මාතෘකාවට දත්ත ඇතුළත් කළ යුතු බව (Regex ඇතුළුව)
                      _buildUpdateInput("Item Title", _titleCtrl, Icons.edit, cardBg, tp, bc, 
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return "Title is required";
                          if (v.length < 5 || v.length > 100) return "Min 5 - Max 100 characters";
                          if (!RegExp(r'^[a-zA-Z0-9\s]+$').hasMatch(v)) return "No special symbols allowed";
                          return null;
                        }
                      ),
                      const SizedBox(height: 15),

                      // මිලට අංක පමණක් සහ 0ට වැඩි වීම (Price Check)
                      _buildUpdateInput("Price (LKR)", _priceCtrl, Icons.payments, cardBg, tp, bc, 
                        kType: TextInputType.number,
                        validator: (v) {
                          if (v == null || v.isEmpty) return "Price required";
                          final price = double.tryParse(v);
                          if (price == null || price <= 0) return "Enter valid number above 0";
                          if (price > 1000000) return "Price is too high";
                          return null;
                        }
                      ),
                      const SizedBox(height: 15),

                      _buildDropdown("Category", widget.data['category'], ["Tech", "Fashion", "Stationary", "Books"], (val) => setState(() => _cat = val), cardBg, bc),
                      const SizedBox(height: 15),
                      
                      _buildDropdown("Condition", widget.data['condition'], ["New", "Used - Good", "Used - Fair"], (val) => setState(() => _cond = val), cardBg, bc),
                      const SizedBox(height: 15),

                      _buildUpdateInput("Full Description", _descCtrl, Icons.description, cardBg, tp, bc, maxL: 3, 
                        validator: (v) => (v == null || v.length < 5) ? "Please write at least 5 characters" : null
                      ),
                      const SizedBox(height: 40),

                      SizedBox(
                        width: double.infinity, height: 60,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: ManageListingsScreen.gRedMid, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
                          onPressed: _saveChanges,
                          child: const Text("UPDATE NOW", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
                      ),
                    ]),
                  ),
                ),
              ]),
            ),
    );
  }

  void _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      await FirebaseFirestore.instance.collection('listings').doc(widget.docId).update({
        'name': _titleCtrl.text.trim(),
        'price': "Rs. ${_priceCtrl.text.trim()}",
        'category': _cat,
        'condition': _cond,
        'description': _descCtrl.text.trim(),
      });
      Navigator.pop(context);
    }
  }

  Widget _buildUpdateInput(String label, TextEditingController ctrl, IconData icon, Color cb, Color tp, Color bc, {int maxL = 1, TextInputType kType = TextInputType.text, String? Function(String?)? validator}) {
    return Container(
      decoration: BoxDecoration(color: cb, borderRadius: BorderRadius.circular(15), border: Border.all(color: bc)),
      child: TextFormField(
        controller: ctrl, validator: validator, keyboardType: kType, maxLines: maxL, style: TextStyle(color: tp),
        decoration: InputDecoration(labelText: label, prefixIcon: const Icon(Icons.edit, size: 18), border: InputBorder.none, contentPadding: const EdgeInsets.all(15)),
      ),
    );
  }

  Widget _buildDropdown(String hint, String? val, List<String> opt, Function(String?) ch, Color cb, Color bc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: cb, borderRadius: BorderRadius.circular(15), border: Border.all(color: bc)),
      child: DropdownButtonFormField<String>(
        value: opt.contains(val) ? val : null, decoration: const InputDecoration(border: InputBorder.none), iconEnabledColor: ManageListingsScreen.gRedMid,
        items: opt.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(), onChanged: ch, dropdownColor: cb,
      ),
    );
  }
}