import 'package:flutter/material.dart';

class RatingScreen extends StatefulWidget {
  final String itemName;
  final String itemImage;

  const RatingScreen({super.key, required this.itemName, required this.itemImage});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _userRating = 0; 
  final TextEditingController _reviewController = TextEditingController();

  // Teammate Style Colors
  static const Color gRedStart = Color(0xFFFF4B4B);
  static const Color gRedMid = Color(0xFFB31217);
  static const Color gDarkEnd = Color(0xFF1B1B1B);

  @override
  Widget build(BuildContext context) {
    // --- Dark mode පරීක්ෂාව සහ Teammate's Palette එකට වර්ණ ලැබීම ---
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color pageBg = isDark ? const Color(0xFF0F0F13) : const Color(0xFFF6F7FB);
    final Color cardBg = isDark ? const Color(0xFF1B1B22) : Colors.white;
    final Color textPrimary = isDark ? Colors.white : const Color(0xFF1B1B22);
    final Color textSecondary = isDark ? const Color(0xFFB7BBC6) : const Color(0xFF747A86);
    final Color inputFill = isDark ? const Color(0xFF23232B) : Colors.grey.shade100;

    return Scaffold(
      backgroundColor: pageBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text("Success Rate", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 17)),
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- 1. PREMIUM HEADER (Teammate's Curved Design) ---
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 110, 20, 40),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [gRedStart, gRedMid, gDarkEnd],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.62, 1.0],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(34), 
                  bottomRight: Radius.circular(34),
                ),
              ),
              child: Column(
                children: [
                  const Icon(Icons.verified_user_rounded, color: Colors.white, size: 70),
                  const SizedBox(height: 15),
                  const Text(
                    "Deal Completed!", 
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)
                  ),
                  const SizedBox(height: 5),
                  Text(
                    "You just successfully finished your campus transaction.",
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

            // --- 2. RATING & FEEDBACK FORM ---
            Padding(
              padding: const EdgeInsets.all(25),
              child: Column(
                children: [
                  // Product Preview Box
                  Container(
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(25),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10)],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(15),
                          child: Image.network(widget.itemImage, width: 65, height: 65, fit: BoxFit.cover,
                            errorBuilder: (ctx, e, s) => Container(color: Colors.grey[200], child: const Icon(Icons.image)),
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Purchased Item", style: TextStyle(color: textSecondary, fontSize: 11, fontWeight: FontWeight.bold)),
                              Text(widget.itemName, style: TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.w800)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                  Text("Rate the Seller", style: TextStyle(color: textPrimary, fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text("How was your experience during the meetup?", style: TextStyle(color: textSecondary, fontSize: 13)),
                  const SizedBox(height: 20),

                  // Star Rating Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      return IconButton(
                        iconSize: 45,
                        onPressed: () => setState(() => _userRating = index + 1),
                        icon: Icon(
                          index < _userRating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: index < _userRating ? Colors.amber : Colors.grey.shade400,
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 30),

                  // Review Text Field
                  Container(
                    decoration: BoxDecoration(
                      color: inputFill,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: TextFormField(
                      controller: _reviewController,
                      maxLines: 3,
                      style: TextStyle(color: textPrimary),
                      decoration: const InputDecoration(
                        hintText: "Add a comment about the product or seller...",
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.all(20),
                      ),
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Finish Button (Vibrant Red)
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: gRedMid,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                        elevation: 10,
                        shadowColor: gRedMid.withOpacity(0.4),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Rating updated! Seller reputation increased.")),
                        );
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "SUBMIT & COMPLETE", 
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}