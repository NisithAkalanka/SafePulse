import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';

import 'create_listing.dart';
import 'item_details.dart';
import 'all_listings.dart'; 
import 'favourite_saved_list.dart'; 
import 'manage_listings.dart';
import 'notifications_screen.dart'; 
import '../sos_system/main_menu_screen.dart';

class MarketHome extends StatefulWidget {
  const MarketHome({super.key});

  @override
  State<MarketHome> createState() => _MarketHomeState();
}

class _MarketHomeState extends State<MarketHome> {
  final TextEditingController _searchController = TextEditingController();
  String _searchText = "";
  String _selectedCategory = "All"; 

  final List<String> _categories = ["All", "Tech", "Stationary", "Fashion", "Books"];

  static const Color gRedMid = Color(0xFFB31217);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() => _searchText = _searchController.text.toLowerCase());
    });
  }

  void _openProfileMenu() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.black.withOpacity(0.1), 
        pageBuilder: (context, animation, secondaryAnimation) => const MainMenuScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0.12, 0), end: Offset.zero).animate(curved),
              child: child,
            ),
          );
        },
      ),
    );
  }

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
            // --- 1. HEADER AREA (ඉහළට ගෙන යාම සඳහා යාවත්කාලීන කරන ලදී) ---
            Container(
              width: double.infinity,
              // Top padding එක 60 ලෙස අඩු කළා (Marketplace වචනය උඩට ගැනීමට)
              padding: const EdgeInsets.fromLTRB(18, 60, 18, 22), 
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? const [
                          Color(0xFFFF3B3B),
                          Color(0xFFE10613),
                          Color(0xFFB30012),
                          Color(0xFF140910),
                        ]
                      : const [
                          Color(0xFFFF4B4B),
                          Color(0xFFB31217),
                          Color(0xFF1B1B1B),
                        ],
                  stops: isDark
                      ? const [0.0, 0.35, 0.72, 1.0]
                      : const [0.0, 0.62, 1.0],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(34),
                  bottomRight: Radius.circular(34),
                ),
              ),
              child: Column(children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                    children: [
                      const SizedBox(width: 50), 
                      const Expanded(
                        child: Center(
                          child: Text(
                            "Marketplace", 
                            style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w800)
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          _buildHeaderIcon(
                            icon: Icons.notifications_none_rounded, 
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const MarketNotificationsScreen()))
                          ),
                          const SizedBox(width: 10),
                          _buildHeaderIcon(icon: Icons.more_vert_rounded, onTap: _openProfileMenu),
                        ],
                      ),
                  ]),
                  // Card එක මාතෘකාවට ළං කිරීම සඳහා පරතරය (SizedBox) 12 දක්වා අඩු කළා
                  const SizedBox(height: 15), 
                  _buildCampusMarketCard(),
              ]),
            ),

            const SizedBox(height: 15),

            // --- 2. SEARCH BAR ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Container(
                height: 52, 
                decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16), border: Border.all(color: gRedMid.withOpacity(0.4))),
                child: TextField(
                  controller: _searchController, style: TextStyle(color: textPrimary),
                  decoration: const InputDecoration(hintText: "Search items...", prefixIcon: Icon(Icons.search, color: gRedMid), border: InputBorder.none, contentPadding: EdgeInsets.symmetric(vertical: 14)),
                ),
              ),
            ),
            
            const SizedBox(height: 15),

            // --- 3. CATEGORY LIST ---
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 18),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  bool selected = _selectedCategory == _categories[index];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = _categories[index]),
                    child: Container(
                      margin: const EdgeInsets.only(right: 10), padding: const EdgeInsets.symmetric(horizontal: 22),
                      decoration: BoxDecoration(color: selected ? gRedMid : cardBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: selected ? gRedMid : borderColor)),
                      alignment: Alignment.center,
                      child: Text(_categories[index], style: TextStyle(color: selected ? Colors.white : textPrimary, fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 25),

            // --- 4. ACTION BUTTONS ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  _act(context, Icons.add_circle_outline, "Sell", cardBg, borderColor),
                  _act(context, Icons.favorite_border, "Favs", cardBg, borderColor),
                  _act(context, Icons.bookmark_border, "Saved", cardBg, borderColor),
                  _act(context, Icons.assignment_ind_outlined, "My Ads", cardBg, borderColor),
              ]),
            ),

            const SizedBox(height: 35),

            // --- 5. GRID HEADER ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(_searchText.isEmpty && _selectedCategory == "All" ? "Recently Posted" : "Search Results", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: textPrimary)),
                  GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AllListingsScreen())), child: const Text("See all", style: TextStyle(color: gRedMid, fontWeight: FontWeight.bold, fontSize: 13))),
              ]),
            ),

            // --- 6. DATA STREAM & GRID ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('listings').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator(color: gRedMid)));

                var docs = snapshot.data!.docs.where((doc) {
                  var data = doc.data() as Map<String, dynamic>;
                  String name = (data['name'] ?? "").toString().toLowerCase();
                  String cat = (data['category'] ?? "").toString();
                  return name.contains(_searchText) && (_selectedCategory == "All" || cat == _selectedCategory);
                }).toList();

                docs.sort((a, b) {
                  var dataA = a.data() as Map<String, dynamic>;
                  var dataB = b.data() as Map<String, dynamic>;
                  Timestamp? tA = dataA['timestamp'];
                  Timestamp? tB = dataB['timestamp'];
                  if (tA == null && tB == null) return 0;
                  if (tA == null) return 1;
                  if (tB == null) return -1;
                  return tB.compareTo(tA);
                });

                if (docs.isEmpty) return const Padding(padding: EdgeInsets.symmetric(vertical: 60), child: Text("No items found!"));

                return GridView.builder(
                  shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(18),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 0.82),
                  itemCount: docs.length,
                  itemBuilder: (ctx, i) {
                    var data = docs[i].data() as Map<String, dynamic>;
                    return _itemTile(context, docs[i].id, data);
                  },
                );
              },
            ),
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  Widget _buildCampusMarketCard() => Container(
    width: double.infinity, 
    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18), // Padding මඳක් අඩු කළා
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.10), 
      borderRadius: BorderRadius.circular(22), 
      border: Border.all(color: Colors.white.withOpacity(0.18))
    ),
    child: Row(children: [
      const Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
      const SizedBox(width: 14),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, 
          children: [
            const Text(
              "Campus MarketPlace", 
              style: TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)
            ),
            const SizedBox(height: 6), // මඳක් අඩු කළා (වෙනස හඳුනා ගැනීමට)
            const Text(
              "The student network for trading.", 
              style: TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)
            ),
          ]
        ),
      ),
    ]),
  );

  Widget _itemTile(BuildContext c, String id, Map data) => GestureDetector(
    onTap: () => Navigator.push(c, MaterialPageRoute(builder: (ctx) => ItemDetails(
      docId: id, itemName: data['name'], itemPrice: data['price'], itemImage: data['image'],
      itemDescription: data['description'], itemCondition: data['condition'], sellerId: data['sellerId'],
    ))),
    child: Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22), 
        gradient: const LinearGradient(colors: [gRedMid, Color(0xFF101010)])
      ),
      child: Column(children: [
          Expanded(child: Padding(padding: const EdgeInsets.all(6), child: ClipRRect(borderRadius: BorderRadius.circular(18), child: Image.network(data['image'] ?? "", fit: BoxFit.cover, width: double.infinity, errorBuilder: (ctx, e, s) => const Icon(Icons.image, color: Colors.white))))),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12), 
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(data['name'] ?? "No Title", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text("Rs. ${data['price'] ?? "0"}", style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            )
          ),
      ]),
    ),
  );

  Widget _buildHeaderIcon({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.12))),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _act(BuildContext context, IconData i, String l, Color cb, Color bc) => GestureDetector(
    onTap: () {
      if(l=="Sell") Navigator.push(context, MaterialPageRoute(builder: (c)=> const CreateListing()));
      if(l=="Favs") Navigator.push(context, MaterialPageRoute(builder: (c)=> const FavoriteSavedScreen(title: "Favourites", collectionName: "user_favourites")));
      if(l=="Saved") Navigator.push(context, MaterialPageRoute(builder: (c)=> const FavoriteSavedScreen(title: "Saved Items", collectionName: "user_saved")));
      if(l=="My Ads") Navigator.push(context, MaterialPageRoute(builder: (c)=> const ManageListingsScreen()));
    },
    child: Column(children: [
        Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: cb, borderRadius: BorderRadius.circular(18), border: Border.all(color: bc)), child: Icon(i, color: gRedMid, size: 28)),
        const SizedBox(height: 8), Text(l, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))
    ]),
  );
}