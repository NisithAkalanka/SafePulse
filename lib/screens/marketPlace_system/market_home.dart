import 'package:flutter/material.dart';
import 'create_listing.dart';
import 'item_details.dart';

class MarketHome extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          "Marketplace",
          style: TextStyle(
            color: Colors.black, 
            fontSize: 28, 
            fontWeight: FontWeight.bold
          ),
        ),
        actions: [
          // ඔයා ඉල්ලපු විදියට කෙළවරක තියෙන Profile Icon එක
          IconButton(
            icon: const Icon(Icons.person_pin, color: Colors.black, size: 32),
            onPressed: () {
              // Profile screen එකක් තිබේ නම් මෙතනින් Navigate කරන්න
            },
          ),
          IconButton(
            icon: const Icon(Icons.search, color: Colors.black, size: 28),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Tab Buttons (Sell, For you, Categories) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  _buildFilterTab(context, "Sell", false, Icons.edit_note),
                  _buildFilterTab(context, "For you", true, null),
                  _buildFilterTab(context, "Categories", false, Icons.menu_open),
                ],
              ),
            ),

            const Divider(thickness: 0.5),

            // --- Location Section ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Today's picks",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: const [
                      Icon(Icons.location_on, color: Colors.blue, size: 18),
                      Text(
                        " Matara",
                        style: TextStyle(color: Colors.blue, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // --- Product Grid ---
            GridView.builder(
              shrinkWrap: true, 
              physics: const NeverScrollableScrollPhysics(), // පිටත Scroll එක පාවිච්චි කිරීමට
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.82,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
              ),
              itemCount: 4, // අයිතම සංඛ්‍යාව
              itemBuilder: (context, index) {
                return _buildFBProductCard(context, index);
              },
            ),
          ],
        ),
      ),
      // Leader'ගේ Theme එකට ගැලපෙන Red FAB එක
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFFF85D5B),
        child: const Icon(Icons.add_a_photo, color: Colors.white),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => CreateListing()));
        },
      ),
    );
  }

  // ප්ලේස්බුක් මාදිලියේ Filter Tab එක
  Widget _buildFilterTab(BuildContext context, String label, bool isSelected, IconData? icon) {
    return GestureDetector(
      onTap: () {
        if (label == "Sell") {
          Navigator.push(context, MaterialPageRoute(builder: (context) => CreateListing()));
        }
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withOpacity(0.1) : Colors.grey[200],
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            if (icon != null) Icon(icon, size: 18, color: isSelected ? Colors.blue : Colors.black),
            if (icon != null) const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.blue : Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // නිෂ්පාදන පෙන්වන කාඩ් එක
  Widget _buildFBProductCard(BuildContext context, int index) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ItemDetails()));
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                "https://picsum.photos/400/400?random=$index", // Placeholder images
                fit: BoxFit.cover,
                width: double.infinity,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 4.0),
            child: Text(
              "Rs 45.00 · Calculator TI-84",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}