import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// පද්ධතියේ අනෙක් ගොනු
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

  // SafePulse Brand Colors
  static const Color primaryRed = Color(0xFFD32F2F);
  static const Color intenseRed = Color(0xFFFF1744); 
  static const Color darkBg = Color(0xFF101010); 

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _searchText = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCFCFC), // පිරිසිදු සුදු පසුබිම
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // --- 1. COMPACT PREMIUM HEADER (උස අඩු කළ හෙඩර් කොටස) ---
            Container(
              padding: const EdgeInsets.only(top: 55, left: 20, right: 20, bottom: 25), // bottom padding adu kala
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [intenseRed, darkBg], 
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(50), 
                  bottomRight: Radius.circular(50),
                ),
              ),
              child: Column(
                children: [
                  // App Bar Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Marketplace",
                        style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          _buildHeaderIcon(Icons.notifications_none_rounded, const MarketNotificationsScreen()),
                          const SizedBox(width: 12),
                          _buildHeaderIcon(Icons.more_vert_rounded, const MainMenuScreen()),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20), // Spacing adu kala

                  // Campus Market Small Info Box
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12), // internal padding adu kala
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12), 
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.storefront_rounded, color: Colors.white, size: 28),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                "Campus Market", 
                                style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                "The trusted student network for campus trading.",
                                style: TextStyle(color: Colors.white70, fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 15),

            // --- 2. SEARCH BAR ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Container(
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: primaryRed.withOpacity(0.1)),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: "What are you searching for?",
                    hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
                    prefixIcon: const Icon(Icons.search, color: primaryRed, size: 22),
                    suffixIcon: _searchText.isNotEmpty 
                        ? IconButton(icon: const Icon(Icons.clear, size: 18, color: Colors.grey), onPressed: () => _searchController.clear())
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 25),

            // --- 3. CLEAN QUICK ACTIONS (ඔබ එවූ රූපය අනුව සකස් කළා) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildMarketAction(Icons.add_circle_outline_rounded, "Sell"),
                  _buildMarketAction(Icons.favorite_border_rounded, "Favourites"),
                  _buildMarketAction(Icons.bookmark_outline_rounded, "Saved"),
                  _buildMarketAction(Icons.assignment_ind_outlined, "My Ads"), 
                ],
              ),
            ),

            const SizedBox(height: 35),

            // --- 4. ITEM GRID HEADER ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("For You", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => const AllListingsScreen())),
                    child: const Text("See all", style: TextStyle(color: primaryRed, fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('listings').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: primaryRed));
                
                final docs = snapshot.data!.docs.where((doc) {
                  final name = (doc['name'] as String).toLowerCase();
                  return name.contains(_searchText);
                }).toList();

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    var data = docs[index].data() as Map<String, dynamic>;
                    return _buildSafePulseCard(docs[index].id, data);
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

  // --- UI Widget Helpers ---

  Widget _buildHeaderIcon(IconData icon, Widget target) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => target)),
      child: Container(
        padding: const EdgeInsets.all(10), 
        decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(12)), 
        child: Icon(icon, color: Colors.white, size: 22)
      ),
    );
  }

  // පින්තූරයේ ආකාරයට නිර්මාණය කළ පිරිසිදු බොත්තම් UI එක
  Widget _buildMarketAction(IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        if (label == "Sell") Navigator.push(context, MaterialPageRoute(builder: (c) => const CreateListing()));
        if (label == "Favourites") Navigator.push(context, MaterialPageRoute(builder: (c) => const FavoriteSavedScreen(title: "Favourites", collectionName: "user_favourites")));
        if (label == "Saved") Navigator.push(context, MaterialPageRoute(builder: (c) => const FavoriteSavedScreen(title: "Saved Items", collectionName: "user_saved")));
        if (label == "My Ads") Navigator.push(context, MaterialPageRoute(builder: (c) => const ManageListingsScreen()));
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16), 
            decoration: BoxDecoration(
              color: Colors.white, // No color background (Pure White)
              borderRadius: BorderRadius.circular(18), // Rounded corner boxes
              boxShadow: [
                BoxShadow(color: Colors.red.withOpacity(0.04), blurRadius: 15, spreadRadius: 1)
              ],
              border: Border.all(color: Colors.grey.shade50), // Subtle light border
            ), 
            child: Icon(icon, color: primaryRed, size: 30), 
          ),
          const SizedBox(height: 10), 
          Text(label, style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildSafePulseCard(String docId, Map data) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (c) => ItemDetails(docId: docId, itemName: data['name'], itemPrice: data['price'], itemImage: data['image']))),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(25),
          gradient: const LinearGradient(colors: [primaryRed, darkBg], begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8, offset: const Offset(0, 4))],
        ),
        child: Column(children: [
          Expanded(child: Padding(padding: const EdgeInsets.all(5), child: ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.network(data['image'] ?? "", fit: BoxFit.cover, width: double.infinity, errorBuilder: (c,e,s) => const Icon(Icons.image, color: Colors.white))))),
          Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(data['name'] ?? "", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(data['price'] ?? "", style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ])),
        ]),
      ),
    );
  }
}