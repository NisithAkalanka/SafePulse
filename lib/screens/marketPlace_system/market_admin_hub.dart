import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MarketAdminHub extends StatefulWidget {
  const MarketAdminHub({super.key});

  @override
  State<MarketAdminHub> createState() => _MarketAdminHubState();
}

class _MarketAdminHubState extends State<MarketAdminHub> {
  // Teammate's Official Gradient Colors
  static const Color gRedStart = Color(0xFFFF4B4B);
  static const Color gRedMid = Color(0xFFB31217);
  static const Color gDarkEnd = Color(0xFF1B1B1B);

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color pageBg = isDark ? const Color(0xFF0F0F13) : const Color(0xFFF6F7FB);
    final Color cardBg = isDark ? const Color(0xFF1B1B22) : Colors.white;
    final Color textPrimary = isDark ? Colors.white : const Color(0xFF1B1B22);
    final Color borderColor = isDark ? const Color(0xFF34343F) : const Color(0xFFE8EAF0);

    return Scaffold(
      backgroundColor: pageBg,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // --- 1. PREMIUM HEADER AREA ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 70, 18, 30),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [gRedStart, gRedMid, gDarkEnd], stops: [0.0, 0.62, 1.0],
                ),
                borderRadius: BorderRadius.only(bottomLeft: Radius.circular(34), bottomRight: Radius.circular(34)),
              ),
              child: Column(children: [
                Row(children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Center(
                      child: Text("System Administration", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
                    ),
                  ),
                  const SizedBox(width: 45), // Alignment
                ]),
                const SizedBox(height: 25),
                _buildAuditBox(),
              ]),
            ),

            // --- 2. LIVE MARKET ANALYTICS (STAT TILES) ---
            Padding(
              padding: const EdgeInsets.all(22),
              child: _buildMarketAnalytics(cardBg, textPrimary, borderColor),
            ),

            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 22, vertical: 5),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("Live Inventory Logs", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900)),
              ),
            ),

            // --- 3. LIVE DATABASE STREAM WITH DELETE BUTTONS ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('listings').orderBy('createdAt', descending: true).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: gRedMid));
                final docs = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    var data = docs[i].data() as Map<String, dynamic>;
                    return _adminProductCard(context, docs[i].id, data, cardBg, textPrimary, borderColor);
                  },
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  // --- පියවර: සංඛ්‍යාලේඛන ගණනය කරන කොටස ---
  Widget _buildMarketAnalytics(Color cardBg, Color tp, Color bc) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('listings').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox();
        final docs = snapshot.data!.docs;
        
        int total = docs.length;
        int active = docs.where((d) => d['status'] == 'Available').length;
        int sold = docs.where((d) => d['status'] == 'Sold').length;
        int flagged = docs.where((d) => (d.data() as Map).containsKey('reported') && d['reported'] == true).length;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          childAspectRatio: 1.5,
          children: [
            _statTile("TOTAL POSTS", total.toString(), Colors.blue, cardBg, tp, bc),
            _statTile("ACTIVE LISTINGS", active.toString(), Colors.greenAccent, cardBg, tp, bc),
            _statTile("SOLD ITEMS", sold.toString(), Colors.purpleAccent, cardBg, tp, bc),
            _statTile("FLAGGED ADS", flagged.toString(), Colors.orange, cardBg, tp, bc),
          ],
        );
      },
    );
  }

  Widget _statTile(String label, String value, Color color, Color cb, Color tp, Color bc) {
    return Container(
      decoration: BoxDecoration(color: cb, borderRadius: BorderRadius.circular(22), border: Border.all(color: bc, width: 1.2)),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(value, style: TextStyle(color: color, fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 3),
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  // --- පියවර: Delete Icon වෙනුවට Delete Button සහිත අලංකාර Card එක ---
  Widget _adminProductCard(BuildContext c, String id, Map data, Color cb, Color tp, Color bc) {
    bool isReported = data.containsKey('reported') && data['reported'] == true;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: cb,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: isReported ? Colors.redAccent.withOpacity(0.4) : bc),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: (data['image'] != null && data['image'].toString().length > 100)
                    ? Image.memory(base64Decode(data['image']), width: 65, height: 65, fit: BoxFit.cover)
                    : Container(width: 65, height: 65, color: Colors.grey.withOpacity(0.1), child: const Icon(Icons.image_outlined, color: Colors.grey)),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(data['name'] ?? "Untitled", style: TextStyle(color: tp, fontWeight: FontWeight.w800, fontSize: 16)),
                  Text(data['price'] ?? "", style: const TextStyle(color: gRedMid, fontWeight: FontWeight.bold, fontSize: 14)),
                ]),
              ),
              if (isReported) const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            ],
          ),
          const SizedBox(height: 15),
          // --- මෙන්න ඔබ ඉල්ලූ Delete බොත්තම (Global Removal) ---
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFEECEE),
                foregroundColor: gRedMid,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                side: BorderSide(color: gRedMid.withOpacity(0.2)),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => _confirmAdminDelete(c, id, cb, tp),
              icon: const Icon(Icons.delete_sweep_rounded, size: 18),
              label: const Text("DELETE LISTING FROM MARKET", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
            ),
          )
        ],
      ),
    );
  }

  void _confirmAdminDelete(BuildContext c, String id, Color cb, Color tp) {
    showDialog(context: c, builder: (ctx) => AlertDialog(
      backgroundColor: cb, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      title: Text("Admin Force Delete", style: TextStyle(color: tp, fontWeight: FontWeight.bold)),
      content: const Text("As a system administrator, are you sure you want to permanently delete this listing? This action cannot be undone."),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("BACK", style: TextStyle(color: Colors.grey))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: gRedMid, shape: StadiumBorder()),
          onPressed: () async {
            await FirebaseFirestore.instance.collection('listings').doc(id).delete();
            Navigator.pop(ctx);
            ScaffoldMessenger.of(c).showSnackBar(const SnackBar(content: Text("Listing Removed Globally.")));
          }, 
          child: const Text("YES, DELETE", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
        ),
      ],
    ));
  }

  Widget _buildAuditBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(28), border: Border.all(color: Colors.white.withOpacity(0.15))),
      child: Row(children: [
        const Icon(Icons.gpp_maybe_rounded, color: Colors.white, size: 30),
        const SizedBox(width: 15),
        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("Market Quality Audit", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900)),
          Text("Review items to maintain campus trade safety.", style: TextStyle(color: Colors.white70, fontSize: 11)),
        ]))
      ]),
    );
  }
}