import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:ui';

// ඔබගේ Imports නිවැරදි දැයි බලන්න
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
  bool _isSearching = false; 

  final List<String> _categories = ["All", "Tech", "Stationary", "Fashion", "Books"];

  static const Color gRedMid = Color(0xFFB31217);
  static const Color gRedStart = Color(0xFFFF4B4B);

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

    final double topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: pageBg,
      // Stack භාවිතා කර ස්ථාවර Header එක Content එකට උඩින් තබා ඇත
      body: Stack(
        children: [
          // --- 1. මුළු Content එක (Scroll Area) ---
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  // Banner එක රතු පැහැයෙන් ආරම්භ වන ලෙස පියවර (Header එක පිටුපස පෙනේ)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.fromLTRB(18, topPadding + 85, 18, 30), 
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter, 
                        end: Alignment.bottomCenter,
                        colors: isDark 
                            ? const [Color(0xFFFF3B3B), Color(0xFFB30012), Color(0xFF140910)]
                            : const [Color(0xFFFF4B4B), Color(0xFFB31217), Color(0xFF1B1B1B)],
                        stops: const [0.0, 0.62, 1.0],
                      ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(34), 
                        bottomRight: Radius.circular(34)
                      ),
                    ),
                    child: _buildCampusMarketCard(),
                  ),

                  const SizedBox(height: 18),

                  // සෙවුම් තීරුව සහ අනෙකුත් කොටස්
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Container(
                      height: 52, 
                      decoration: BoxDecoration(
                        color: cardBg, 
                        borderRadius: BorderRadius.circular(16), 
                        border: Border.all(color: gRedMid.withOpacity(0.4)),
                      ),
                      child: TextField(
                        controller: _searchController, 
                        onTap: () => setState(() => _isSearching = true),
                        style: TextStyle(color: textPrimary),
                        decoration: const InputDecoration(
                          hintText: "What do you need today?", 
                          prefixIcon: Icon(Icons.search_rounded, color: gRedMid), 
                          border: InputBorder.none, 
                          contentPadding: EdgeInsets.symmetric(vertical: 14)
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                      children: [
                        _act(context, Icons.add_circle_outline, "Sell", cardBg, borderColor),
                        _act(context, Icons.favorite_border, "Favs", cardBg, borderColor),
                        _act(context, Icons.bookmark_border, "Saved", cardBg, borderColor),
                        _act(context, Icons.assignment_ind_outlined, "My Ads", cardBg, borderColor),
                      ],
                    ),
                  ),

                  const SizedBox(height: 25),

                  SizedBox(
                    height: 42,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal, 
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        bool selected = _selectedCategory == _categories[index];
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = _categories[index]),
                          child: Container(
                            margin: const EdgeInsets.only(right: 12), 
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            decoration: BoxDecoration(
                              color: selected ? gRedMid : cardBg, 
                              borderRadius: BorderRadius.circular(20), 
                              border: Border.all(color: selected ? gRedMid : borderColor)
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              _categories[index], 
                              style: TextStyle(color: selected ? Colors.white : textPrimary, fontWeight: FontWeight.bold, fontSize: 13)
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 35),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 22),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                      children: [
                        Text(
                          _searchText.isEmpty && _selectedCategory == "All" ? "Recently Posted" : "Search Results", 
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: textPrimary)
                        ),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AllListingsScreen())), 
                          child: const Text("See all", style: TextStyle(color: gRedMid, fontWeight: FontWeight.bold, fontSize: 13))
                        ),
                      ],
                    ),
                  ),

                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection('listings').snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) return const Center(child: Padding(padding: EdgeInsets.all(50), child: CircularProgressIndicator(color: gRedMid)));
                      var docs = snapshot.data!.docs.where((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        return (data['name'] ?? "").toString().toLowerCase().contains(_searchText) && (_selectedCategory == "All" || data['category'] == _selectedCategory);
                      }).toList();
                      docs.sort((a, b) {
                        var dataA = a.data() as Map<String, dynamic>;
                        var dataB = b.data() as Map<String, dynamic>;
                        Timestamp? tA = dataA['timestamp']; Timestamp? tB = dataB['timestamp'];
                        if (tA == null && tB == null) return 0; if (tA == null) return 1; if (tB == null) return -1;
                        return tB.compareTo(tA);
                      });
                      if (docs.isEmpty) return const Padding(padding: EdgeInsets.all(60), child: Text("No items match your search."));
                      return GridView.builder(
                        shrinkWrap: true, 
                        physics: const NeverScrollableScrollPhysics(), 
                        padding: const EdgeInsets.all(18),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 0.82),
                        itemCount: docs.length,
                        itemBuilder: (ctx, i) => _itemTile(context, docs[i].id, docs[i].data() as Map<String, dynamic>),
                      );
                    },
                  ),
                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),

          // --- 2. FIXED STICKY HEADER (සැමවිටම ඉහළින් පවතී) ---
          Positioned(
            top: 0, left: 0, right: 0,
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.fromLTRB(15, topPadding + 10, 15, 12),
              // විනිවිද පෙනෙන නිසා යටින් පවතින Content එක මෙතැනින් පෙනේ
              decoration: const BoxDecoration(
                color: Colors.transparent, 
              ),
              child: Row(
                children: [
                  if (_isSearching) 
                    IconButton(
                      icon: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 22), 
                      onPressed: () => setState(() => _isSearching = false)
                    )
                  else const SizedBox(width: 48), 

                  Expanded(
                    child: Center(
                      child: Text(
                        "Marketplace", 
                        style: TextStyle(
                          color: Colors.white, 
                          fontSize: 22, 
                          fontWeight: FontWeight.w900, 
                          letterSpacing: 0.5
                        )
                      ),
                    ),
                  ),

                  Row(children: [
                      _buildHeaderIcon(icon: Icons.notifications_none_rounded, color: Colors.white, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const MarketNotificationsScreen()))),
                      const SizedBox(width: 10),
                      _buildHeaderIcon(icon: Icons.more_vert_rounded, color: Colors.white, onTap: _openProfileMenu),
                  ]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- Reusable UI Widgets ---

  Widget _buildCampusMarketCard() => Container(
    margin: const EdgeInsets.only(top: 10),
    width: double.infinity, 
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24), 
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.08), 
      borderRadius: BorderRadius.circular(26), 
      border: Border.all(color: Colors.white.withOpacity(0.12))
    ),
    child: Row(children: [
      const Icon(Icons.storefront_rounded, color: Colors.white, size: 34),
      const SizedBox(width: 15),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        Text("Campus MarketPlace", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        SizedBox(height: 8), 
        Text("Trusted network for student trading.", style: TextStyle(color: Colors.white70, fontSize: 13)),
      ])),
    ]),
  );

  Widget _itemTile(BuildContext c, String id, Map data) => GestureDetector(
    onTap: () => Navigator.push(c, MaterialPageRoute(builder: (ctx) => ItemDetails(docId: id, itemName: data['name'], itemPrice: data['price'], itemImage: data['image'], sellerId: data['sellerId'], itemCondition: data['condition'], itemDescription: data['description']))),
    child: Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [gRedMid, Color(0xFF101010)])),
      child: Column(children: [
          Expanded(child: Padding(padding: const EdgeInsets.all(7), child: ClipRRect(borderRadius: BorderRadius.circular(20), child: (data['image'] != null && data['image'].length > 100) ? Image.memory(base64Decode(data['image']), fit: BoxFit.cover, width: double.infinity) : const Icon(Icons.image, color: Colors.white24, size: 40)))),
          Padding(padding: const EdgeInsets.fromLTRB(14, 4, 14, 15), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(data['name'] ?? "", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis), 
            const SizedBox(height: 3),
            Text("Rs. ${data['price'] ?? "0"}", style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600))
          ])),
      ]),
    ),
  );

  Widget _buildHeaderIcon({required IconData icon, required Color color, required VoidCallback onTap}) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(10), 
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(12)), 
      child: Icon(icon, color: Colors.white, size: 22)
    ),
  );

  Widget _act(BuildContext c, IconData i, String l, Color cb, Color bc) => GestureDetector(
    onTap: () {
      if(l=="Sell") Navigator.push(c, MaterialPageRoute(builder: (x)=> const CreateListing()));
      if(l=="My Ads") Navigator.push(c, MaterialPageRoute(builder: (x)=> const ManageListingsScreen()));
      if(l=="Favs") Navigator.push(c, MaterialPageRoute(builder: (x) => const FavoriteSavedScreen(title: "Favourites", collectionName: "user_favourites")));
      if(l=="Saved") Navigator.push(c, MaterialPageRoute(builder: (x) => const FavoriteSavedScreen(title: "Saved Items", collectionName: "user_saved")));
    },
    child: Column(children: [Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(color: cb, borderRadius: BorderRadius.circular(20), border: Border.all(color: bc)), child: Icon(i, color: gRedMid, size: 30)), const SizedBox(height: 10), Text(l, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold))]),
  );
}