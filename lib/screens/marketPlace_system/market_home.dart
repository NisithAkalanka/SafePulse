import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ඔබේ පද්ධතියේ ගොනු (Paths ඔබේ VS Code එකට අනුව නිවැරදි දැයි බලන්න)
import 'create_listing.dart';
import 'item_details.dart';
import 'all_listings.dart'; 
import 'favourite_saved_list.dart'; 
import 'notifications_screen.dart'; // Notification පේජ් එක
import '../profile_screen.dart';   // Leader ගේ Profile පිටුව

class MarketHome extends StatelessWidget {
  const MarketHome({super.key});

  // SafePulse Branding Colors
  static const Color primaryRed = Color(0xFFD32F2F); 
  static const Color intenseRed = Color(0xFFFF1744); 
  static const Color darkBg = Color(0xFF121212);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // --- 1. PREMIUM HEADER SECTION (Profile සහ Notifications සහිතව) ---
            Container(
              padding: const EdgeInsets.only(top: 60, left: 20, right: 20, bottom: 25),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [intenseRed, darkBg],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(35),
                  bottomRight: Radius.circular(35),
                ),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Marketplace", 
                        style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)
                      ),
                      Row(
                        children: [
                          // --- පියවර: Notifications Icon එක ---
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context, 
                                MaterialPageRoute(builder: (context) => const MarketNotificationsScreen())
                              );
                            },
                            child: _buildHeaderAction(Icons.notifications_none_rounded),
                          ),
                          const SizedBox(width: 12),
                          
                          // --- පියවර: Profile Icon එක ---
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context, 
                                MaterialPageRoute(builder: (context) => const ProfileScreen())
                              );
                            },
                            child: _buildProfileIcon(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 25),
                  
                  // --- SEARCH BAR (Modern UI) ---
                  Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10)],
                    ),
                    child: const TextField(
                      decoration: InputDecoration(
                        hintText: "What are you searching for?",
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: primaryRed),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // --- 2. QUICK ACTIONS (Sell, Favourites, Saved, Category) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildQuickAction(context, Icons.add_circle_outline_rounded, "Sell"),
                  _buildQuickAction(context, Icons.favorite_outline_rounded, "Favourites"),
                  _buildQuickAction(context, Icons.bookmark_outline_rounded, "Saved"),
                  _buildQuickAction(context, Icons.grid_view_rounded, "Category"),
                ],
              ),
            ),

            const SizedBox(height: 35),

            // --- 3. RECENT POSTS SECTION ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Recommended For You", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
                  
                  // --- "See all" මගින් සියලු අයිතම පෙන්වයි ---
                  GestureDetector(
                    onTap: () {
                      Navigator.push(context, MaterialPageRoute(builder: (context) => const AllListingsScreen()));
                    },
                    child: const Text(
                      "See all", 
                      style: TextStyle(color: primaryRed, fontWeight: FontWeight.bold)
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),

            // --- 4. REAL-TIME DATA STREAM FROM FIRESTORE ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('listings').orderBy('createdAt', descending: true).limit(8).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: Padding(
                    padding: EdgeInsets.all(30.0),
                    child: CircularProgressIndicator(color: primaryRed),
                  ));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("No items posted yet.", style: TextStyle(color: Colors.grey)));
                }

                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, childAspectRatio: 0.78),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    var item = snapshot.data!.docs[index];
                    return _buildSafePulseProductCard(context, item);
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

  // --- Helper UI Widgets ---

  Widget _buildHeaderAction(IconData icon) {
    return Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: Colors.white, size: 24),
    );
  }

  Widget _buildProfileIcon() {
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: const BoxDecoration(color: Colors.white54, shape: BoxShape.circle),
      child: const CircleAvatar(
        radius: 17,
        backgroundColor: Colors.white,
        child: Icon(Icons.person_outline_rounded, color: primaryRed, size: 22),
      ),
    );
  }

  Widget _buildQuickAction(BuildContext context, IconData icon, String label) {
    return GestureDetector(
      onTap: () {
        if (label == "Sell") {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const CreateListing()));
        } else if (label == "Favourites") {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoriteSavedScreen(title: "My Favourites", collectionName: "user_favourites")));
        } else if (label == "Saved") {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const FavoriteSavedScreen(title: "My Saved Items", collectionName: "user_saved")));
        }
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: primaryRed.withOpacity(0.08), blurRadius: 10, offset: const Offset(0, 4))],
              border: Border.all(color: Colors.red.shade50),
            ),
            child: Icon(icon, color: primaryRed, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildSafePulseProductCard(BuildContext context, DocumentSnapshot doc) {
    var data = doc.data() as Map<String, dynamic>;
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ItemDetails(
          itemName: data['name'], itemPrice: data['price'], itemImage: data['image']
        )));
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(colors: [primaryRed, Color(0xFF1A1A1A)], begin: Alignment.topLeft, end: Alignment.bottomRight),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 12, offset: const Offset(0, 5))],
        ),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(5),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Image.network(data['image'], fit: BoxFit.cover, width: double.infinity, errorBuilder: (c,e,s) => const Icon(Icons.broken_image, color: Colors.white)),
                ),
              ),
            ),
            Expanded(
              flex: 1,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['name'], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    Text(data['price'], style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}