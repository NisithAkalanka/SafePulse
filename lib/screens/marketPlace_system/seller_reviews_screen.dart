import 'package:flutter/material.dart';
import 'seller_rating_summary.dart';
import 'seller_reviews_list.dart';

class SellerReviewsScreen extends StatelessWidget {
  final String sellerId;
  final String sellerName;

  const SellerReviewsScreen({
    super.key,
    required this.sellerId,
    required this.sellerName,
  });

  static const Color gRedStart = Color(0xFFFF4B4B);
  static const Color gRedMid = Color(0xFFB31217);
  static const Color gDarkEnd = Color(0xFF1B1B1B);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pageBg = isDark ? const Color(0xFF0F0F13) : const Color(0xFFF6F7FB);

    return Scaffold(
      backgroundColor: pageBg,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 60, 16, 28),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [gRedStart, gRedMid, gDarkEnd],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.62, 1.0],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                ),
                Expanded(
                  child: Text(
                    "$sellerName Reviews",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  SellerRatingSummary(sellerId: sellerId),
                  const SizedBox(height: 16),
                  SellerReviewsList(sellerId: sellerId),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}