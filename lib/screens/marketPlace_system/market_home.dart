import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:ui';

// ඔබේ අනෙක් ගොනු
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

  // Teammate Style Colors
  static const Color gRedMid = Color(0xFFB31217);
  static const Color gRedStart = Color(0xFFFF4B4B);
  static const Color gDarkEnd = Color(0xFF1B1B1B);

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

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: pageBg,
      body: SafeArea(
        top: false, 
        bottom: true, 
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(bottom: bottomPadding + 80), 
          child: Column(
            children: [
              // --- 1. HEADER AREA (Updated for Visibility in Light/Dark Mode) ---
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 55, 18, 25), 
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
                        // Light Mode සඳහා වර්ණ රටාව තවත් තහවුරු කළා
                        : const [
                            Color(0xFFFF4B4B),
                            Color(0xFFB31217),
                            Color(0xFF1B1B1B), 
                          ],
                    stops: isDark ? const [0.0, 0.35, 0.72, 1.0] : const [0.0, 0.65, 1.0],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(34), 
                    bottomRight: Radius.circular(34),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                      children: [
                        if (_isSearching) 
                          IconButton(
                            icon: const Icon(Icons.arrow_back, color: Colors.white, size: 22), 
                            onPressed: () => setState(() => _isSearching = false)
                          )
                        else const SizedBox(width: 85), 

                        const Expanded(
                          child: Center(
                            child: Text(
                              "Marketplace", 
                              style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, letterSpacing: 0.2)
                            ),
                          ),
                        ),
                        Row(children: [
                            _buildHeaderIcon(icon: Icons.notifications_none_rounded, onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const MarketNotificationsScreen()))),
                            const SizedBox(width: 10),
                            _buildHeaderIcon(icon: Icons.more_vert_rounded, onTap: _openProfileMenu),
                        ]),
                      ],
                    ),
                    const SizedBox(height: 12), 
                    _buildCampusMarketCard(),
                  ],
                ),
              ),

              const SizedBox(height: 15),

              // --- 2. SEARCH BAR ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Container(
                  height: 52, 
                  decoration: BoxDecoration(
                    color: cardBg, 
                    borderRadius: BorderRadius.circular(16), 
                    border: Border.all(color: gRedMid.withOpacity(0.4)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                        blurRadius: 10,
                      )
                    ]
                  ),
                  child: TextField(
                    controller: _searchController, 
                    onTap: () => setState(() => _isSearching = true),
                    style: TextStyle(color: textPrimary),
                    decoration: const InputDecoration(
                      hintText: "What do you want to buy?", 
                      prefixIcon: Icon(Icons.search, color: gRedMid), 
                      border: InputBorder.none, 
                      contentPadding: EdgeInsets.symmetric(vertical: 14)
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 25),

              // --- 3. ACTION BUTTONS ---
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

              const SizedBox(height: 20),

              // --- 4. CATEGORY HORIZONTAL LIST ---
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal, 
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    bool selected = _selectedCategory == _categories[index];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = _categories[index]),
                      child: Container(
                        margin: const EdgeInsets.only(right: 10), 
                        padding: const EdgeInsets.symmetric(horizontal: 22),
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

              // --- 5. GRID HEADER ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween, 
                  children: [
                    const Text("Recently Posted", style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AllListingsScreen())), 
                      child: const Text("See all", style: TextStyle(color: gRedMid, fontWeight: FontWeight.bold, fontSize: 13))
                    ),
                  ],
                ),
              ),

              // --- 6. REAL-TIME DATA GRID ---
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
                  if (docs.isEmpty) return const Padding(padding: EdgeInsets.symmetric(vertical: 60), child: Text("No items found."));
                  return GridView.builder(
                    shrinkWrap: true, 
                    physics: const NeverScrollableScrollPhysics(), 
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 14, childAspectRatio: 0.82),
                    itemCount: docs.length,
                    itemBuilder: (ctx, i) => _itemTile(context, docs[i].id, docs[i].data() as Map<String, dynamic>),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- UI Helpers ---

  Widget _buildCampusMarketCard() => Container(
    width: double.infinity, 
    padding: const EdgeInsets.all(16), 
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(22), border: Border.all(color: Colors.white.withOpacity(0.18))),
    child: Row(children: [
      const Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
      const SizedBox(width: 14),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: const [
        Text("Campus Marketplace", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text("Verified university trading network.", style: TextStyle(color: Colors.white70, fontSize: 12)),
      ])),
    ]),
  );

  Widget _itemTile(BuildContext c, String id, Map data) => GestureDetector(
    onTap: () => Navigator.push(c, MaterialPageRoute(builder: (ctx) => ItemDetails(docId: id, itemName: data['name'], itemPrice: data['price'], itemImage: data['image'], sellerId: data['sellerId'], itemCondition: data['condition'], itemDescription: data['description']))),
    child: Container(
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(22), gradient: const LinearGradient(colors: [gRedMid, Color(0xFF101010)])),
      child: Column(children: [
          Expanded(child: Padding(padding: const EdgeInsets.all(6), child: ClipRRect(borderRadius: BorderRadius.circular(18), child: (data['image'] != null && data['image'].length > 100) ? Image.memory(base64Decode(data['image']), fit: BoxFit.cover, width: double.infinity) : const Icon(Icons.image, color: Colors.white24, size: 40)))),
          Padding(padding: const EdgeInsets.fromLTRB(12, 4, 12, 12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(data['name'] ?? "", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis), Text("Rs. ${data['price'] ?? "0"}", style: const TextStyle(color: Colors.white70, fontSize: 11))])),
      ]),
    ),
  );

  Widget _buildHeaderIcon({required IconData icon, required VoidCallback onTap}) => GestureDetector(
    onTap: onTap,
    child: Container(padding: const EdgeInsets.all(9), decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: Colors.white.withOpacity(0.12))), child: Icon(icon, color: Colors.white, size: 20)),
  );

  Widget _act(BuildContext c, IconData i, String l, Color cb, Color bc) => GestureDetector(
    onTap: () {
      if(l=="Sell") Navigator.push(c, MaterialPageRoute(builder: (x)=> const CreateListing()));
      if(l=="My Ads") Navigator.push(c, MaterialPageRoute(builder: (x)=> const ManageListingsScreen()));
      if(l=="Favs") Navigator.push(c, MaterialPageRoute(builder: (x) => const FavoriteSavedScreen(title: "My Favourites", collectionName: "user_favourites")));
      if(l=="Saved") Navigator.push(c, MaterialPageRoute(builder: (x) => const FavoriteSavedScreen(title: "My Saved Items", collectionName: "user_saved")));
    },
    child: Column(children: [Container(padding: const EdgeInsets.all(15), decoration: BoxDecoration(color: cb, borderRadius: BorderRadius.circular(18), border: Border.all(color: bc)), child: Icon(i, color: gRedMid, size: 28)), const SizedBox(height: 8), Text(l, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold))]),
  );
}