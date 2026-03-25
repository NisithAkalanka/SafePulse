import 'dart:convert'; // --- පියවර 1: Base64 decode කිරීමට මෙය අත්‍යවශ්‍යයි ---
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ManageListingsScreen extends StatelessWidget {
  const ManageListingsScreen({super.key});

  // Teammate's Brand Colors
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
            // --- 1. PREMIUM HEADER ---
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

            // --- 2. LISTINGS SECTION ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('listings')
                  .where('sellerId', isEqualTo: currentUserId)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: gRedMid));

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 100),
                    child: Column(
                      children: [
                        Icon(Icons.inventory_2_outlined, size: 80, color: textSecondary.withOpacity(0.3)),
                        const SizedBox(height: 10),
                        Text("No items found", style: TextStyle(color: textSecondary, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(20),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var doc = snapshot.data!.docs[index];
                    var data = doc.data() as Map<String, dynamic>;

                    return _buildModernManageCard(context, doc.id, data, cardBg, textPrimary, textSecondary, borderColor);
                  },
                );
              },
            ),
            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  // --- පියවර 2: රූපය පෙන්වන කොටස (BASE64 Logic) සමඟ නිවැරදි කිරීම ---
  Widget _buildModernManageCard(BuildContext context, String docId, Map<String, dynamic> data, Color cb, Color tp, Color ts, Color bc) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cb,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: bc, width: 1.2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- පියවර: මෙතනින් තමයි පින්තූරය පෙන්වන්නේ ---
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  width: 85, height: 85,
                  decoration: BoxDecoration(color: Colors.grey[100]),
                  // මෙතනින් අකුරු වැලක් පින්තූරයකට හරවා පෙන්වයි
                  child: (data['image'] != null && data['image'].toString().length > 100)
                    ? Image.memory(
                        base64Decode(data['image']), // Base64 Decoding
                        width: 85, height: 85, fit: BoxFit.cover,
                        errorBuilder: (c, e, s) => const Icon(Icons.broken_image),
                      )
                    : const Icon(Icons.shopping_bag_outlined, color: Colors.grey, size: 30),
                ),
              ),
              const SizedBox(width: 15),
              // Title & Price
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['name'] ?? "No Title", style: TextStyle(color: tp, fontWeight: FontWeight.w800, fontSize: 17), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(data['price'] ?? "0", style: const TextStyle(color: gRedMid, fontWeight: FontWeight.w900, fontSize: 16)),
                    const SizedBox(height: 6),
                    // Condition Label
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: gRedMid.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                      child: Text(data['condition'] ?? "Used", style: const TextStyle(color: gRedMid, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(thickness: 0.5)),

          Text("Brief Summary", style: TextStyle(color: tp, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 5),
          Text(data['description'] ?? "No details.", style: TextStyle(color: ts, fontSize: 13, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),

          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (ctx) => EditListingScreen(docId: docId, data: data))),
                  icon: const Icon(Icons.edit_rounded, size: 18, color: Colors.white),
                  label: const Text("UPDATE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blueAccent, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _confirmRemoval(context, docId, cb, tp, ts),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.white),
                  label: const Text("DELETE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                  style: ElevatedButton.styleFrom(backgroundColor: gRedMid, padding: const EdgeInsets.symmetric(vertical: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _confirmRemoval(BuildContext context, String id, Color cb, Color tp, Color ts) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: cb, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      title: Text("Confirm Delete?", style: TextStyle(color: tp, fontWeight: FontWeight.w900)),
      content: Text("Do you really want to remove this ad? It's permanent.", style: TextStyle(color: ts, fontSize: 14)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Go Back", style: TextStyle(color: ts))),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: gDarkEnd), onPressed: () async {
          await FirebaseFirestore.instance.collection('listings').doc(id).delete();
          Navigator.pop(ctx);
        }, child: const Text("Yes, Delete", style: TextStyle(color: Colors.white))),
      ],
    ));
  }
}

// --- FULL FORM EDIT SCREEN ---
class EditListingScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> data;
  const EditListingScreen({super.key, required this.docId, required this.data});
  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameCtrl, _priceCtrl, _descCtrl;
  String? _cat, _cond;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.data['name']);
    _priceCtrl = TextEditingController(text: widget.data['price'].toString().replaceAll("Rs. ", ""));
    _descCtrl = TextEditingController(text: widget.data['description']);
    _cat = widget.data['category'];
    _cond = widget.data['condition'];
  }

  @override
  Widget build(BuildContext context) {
    final isD = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isD ? const Color(0xFF0F0F13) : const Color(0xFFF6F7FB),
      appBar: AppBar(title: const Text("Edit Ad"), backgroundColor: ManageListingsScreen.gRedMid, foregroundColor: Colors.white),
      body: _isLoading ? const Center(child: CircularProgressIndicator()) : SingleChildScrollView(padding: const EdgeInsets.all(22), child: Form(key: _formKey, child: Column(children: [
          _field("Product Name", _nameCtrl, Icons.title, isD),
          const SizedBox(height: 18),
          _field("Price (LKR)", _priceCtrl, Icons.payments, isD, k: TextInputType.number),
          const SizedBox(height: 18),
          DropdownButtonFormField<String>(value: _cat, decoration: const InputDecoration(labelText: "Category"), items: ["Tech", "Books", "Fashion", "Other"].map((s)=>DropdownMenuItem(value:s, child: Text(s))).toList(), onChanged: (v)=>setState(()=>_cat=v)),
          const SizedBox(height: 40),
          SizedBox(width: double.infinity, height: 60, child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: ManageListingsScreen.gRedMid), onPressed: _save, child: const Text("SAVE CHANGES", style: TextStyle(color: Colors.white))))
      ]))),
    );
  }

  void _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      await FirebaseFirestore.instance.collection('listings').doc(widget.docId).update({
        'name': _nameCtrl.text.trim(), 'price': "Rs. ${_priceCtrl.text.trim()}",
        'category': _cat, 'condition': _cond, 'description': _descCtrl.text.trim(),
      });
      Navigator.pop(context);
    }
  }

  Widget _field(String l, TextEditingController c, IconData i, bool d, {TextInputType k = TextInputType.text}) => TextFormField(controller: c, keyboardType: k, style: TextStyle(color: d ? Colors.white : Colors.black), decoration: InputDecoration(labelText: l, prefixIcon: Icon(i, color: ManageListingsScreen.gRedMid)));
}