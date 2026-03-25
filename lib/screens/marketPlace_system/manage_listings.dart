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
                if (!snapshot.hasData) return const Center(child: Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator(color: gRedMid)));

                if (snapshot.data!.docs.isEmpty) {
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
              // Image
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.network(
                  data['image'] ?? "", 
                  width: 85, height: 85, fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(width: 85, height: 85, color: Colors.grey[200], child: const Icon(Icons.image)),
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
                    Text("Rs. ${data['price']}", style: const TextStyle(color: gRedMid, fontWeight: FontWeight.w900, fontSize: 16)),
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
          
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(thickness: 0.5),
          ),

          // Description Section
          Text("Description", style: TextStyle(color: tp, fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 5),
          Text(
            data['description'] ?? "No description provided for this item.",
            style: TextStyle(color: ts, fontSize: 13, height: 1.4),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              // UPDATE BUTTON
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(
                    builder: (context) => EditListingScreen(docId: docId, data: data),
                  )),
                  icon: const Icon(Icons.edit_rounded, size: 18, color: Colors.white),
                  label: const Text("UPDATE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // DELETE BUTTON
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _confirmDelete(context, docId, cb, tp, ts),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18, color: Colors.white),
                  label: const Text("DELETE", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: gRedMid,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, String id, Color cb, Color tp, Color ts) {
    showDialog(context: context, builder: (ctx) => AlertDialog(
      backgroundColor: cb, 
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
      title: Text("Delete this Ad?", style: TextStyle(color: tp, fontWeight: FontWeight.w900)),
      content: Text("Are you sure? This item will be permanently removed from the market.", style: TextStyle(color: ts, fontSize: 14)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text("Cancel", style: TextStyle(color: ts))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: gDarkEnd, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: () async {
            await FirebaseFirestore.instance.collection('listings').doc(id).delete();
            Navigator.pop(ctx);
          },
          child: const Text("Yes, Delete", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        )
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
  late TextEditingController _nameCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _descCtrl;
  String? _selectedCategory;
  String? _selectedCondition;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.data['name']);
    _priceCtrl = TextEditingController(text: widget.data['price'].toString().replaceAll("Rs. ", ""));
    _descCtrl = TextEditingController(text: widget.data['description']);
    _selectedCategory = widget.data['category'];
    _selectedCondition = widget.data['condition'];
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBg = isDark ? const Color(0xFF1B1B22) : Colors.white;
    final Color textPrimary = isDark ? Colors.white : Colors.black;
    final Color borderColor = isDark ? const Color(0xFF34343F) : const Color(0xFFE8EAF0);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F13) : const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text("Edit Listing", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 18)),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [ManageListingsScreen.gRedStart, ManageListingsScreen.gRedMid])
          )
        ),
        leading: IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white), onPressed: () => Navigator.pop(context)),
        elevation: 0,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: ManageListingsScreen.gRedMid))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(22),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  _inputField("Item Title", _nameCtrl, Icons.title_rounded, cardBg, textPrimary, borderColor),
                  const SizedBox(height: 18),
                  _inputField("Price (LKR)", _priceCtrl, Icons.payments_rounded, cardBg, textPrimary, borderColor, kType: TextInputType.number),
                  const SizedBox(height: 18),
                  _dropdown("Category", Icons.category_rounded, ["Tech", "Stationary", "Fashion", "Books", "Other"], _selectedCategory, (v) => setState(() => _selectedCategory = v), cardBg, borderColor),
                  const SizedBox(height: 18),
                  _dropdown("Condition", Icons.info_outline_rounded, ["New", "Used - Good", "Used - Fair"], _selectedCondition, (v) => setState(() => _selectedCondition = v), cardBg, borderColor),
                  const SizedBox(height: 18),
                  _inputField("Full Description", _descCtrl, Icons.description_rounded, cardBg, textPrimary, borderColor, lines: 5),
                  const SizedBox(height: 40),
                  
                  SizedBox(
                    width: double.infinity, height: 60,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ManageListingsScreen.gRedMid, 
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 5,
                      ),
                      onPressed: _updateListing,
                      child: const Text("SAVE CHANGES", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
    );
  }

  void _updateListing() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance.collection('listings').doc(widget.docId).update({
          'name': _nameCtrl.text.trim(),
          'price': _priceCtrl.text.trim(),
          'category': _selectedCategory,
          'condition': _selectedCondition,
          'description': _descCtrl.text.trim(),
        });
        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Ad updated successfully!"), backgroundColor: Colors.green)
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Error updating ad.")));
      }
    }
  }

  Widget _inputField(String label, TextEditingController ctrl, IconData icon, Color cb, Color tp, Color bc, {int lines = 1, TextInputType kType = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(color: cb, borderRadius: BorderRadius.circular(16), border: Border.all(color: bc)),
      child: TextFormField(
        controller: ctrl, maxLines: lines, keyboardType: kType, style: TextStyle(color: tp),
        validator: (v) => (v == null || v.isEmpty) ? "This field is required" : null,
        decoration: InputDecoration(
          labelText: label, 
          labelStyle: const TextStyle(fontSize: 13, color: Colors.grey),
          prefixIcon: Icon(icon, color: ManageListingsScreen.gRedMid), 
          border: InputBorder.none, 
          contentPadding: const EdgeInsets.all(18)
        ),
      ),
    );
  }

  Widget _dropdown(String h, IconData i, List<String> opt, String? val, Function(String?) ch, Color cb, Color bc) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(color: cb, borderRadius: BorderRadius.circular(16), border: Border.all(color: bc)),
      child: DropdownButtonFormField<String>(
        value: val, 
        hint: Text(h, style: const TextStyle(fontSize: 14)), 
        validator: (v) => v == null ? "Select one" : null,
        decoration: InputDecoration(border: InputBorder.none, prefixIcon: Icon(i, color: ManageListingsScreen.gRedMid)),
        items: opt.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 14)))).toList(),
        onChanged: ch, 
        dropdownColor: cb,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }
}