import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class RatingScreen extends StatefulWidget {
  final String docId;
  final String sellerId;
  final String itemName;
  final String itemImage;

  const RatingScreen({
    super.key,
    required this.docId,
    required this.sellerId,
    required this.itemName,
    required this.itemImage,
  });

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  static const Color gRedStart = Color(0xFFFF4B4B);
  static const Color gRedMid = Color(0xFFB31217);
  static const Color gDarkEnd = Color(0xFF1B1B1B);

  final TextEditingController _reviewController = TextEditingController();

  int _userRating = 0;
  bool _isSubmitting = false;

  String _getRatingLabel(int rating) {
    switch (rating) {
      case 1:
        return "Very Bad";
      case 2:
        return "Bad";
      case 3:
        return "Good";
      case 4:
        return "Very Good";
      case 5:
        return "Excellent";
      default:
        return "Tap to rate";
    }
  }

  Future<String> _getBuyerName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return "Buyer";

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        return data['name'] ??
            data['fullName'] ??
            data['username'] ??
            user.displayName ??
            user.email?.split('@').first ??
            "Buyer";
      }
    } catch (_) {}

    return user.displayName ?? user.email?.split('@').first ?? "Buyer";
  }

  Future<void> submitReview() async {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      _showSnack("Please login first");
      return;
    }

    if (_userRating == 0) {
      _showSnack("Please select a star rating");
      return;
    }

    if (_reviewController.text.trim().isEmpty) {
      _showSnack("Please enter your review");
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final buyerId = currentUser.uid;

      final listingDoc = await FirebaseFirestore.instance
          .collection('listings')
          .doc(widget.docId)
          .get();

      if (!listingDoc.exists) {
        _showSnack("Listing not found");
        setState(() => _isSubmitting = false);
        return;
      }

      final listingData = listingDoc.data() as Map<String, dynamic>;

      if ((listingData['status'] ?? '') != 'Sold') {
        _showSnack("This item is not marked as sold yet");
        setState(() => _isSubmitting = false);
        return;
      }

      if ((listingData['buyerId'] ?? '') != buyerId) {
        _showSnack("Only the buyer can rate this seller");
        setState(() => _isSubmitting = false);
        return;
      }

      final reviewDocId = "${widget.docId}_$buyerId";

      final existingReview = await FirebaseFirestore.instance
          .collection('marketplace_reviews')
          .doc(reviewDocId)
          .get();

      if (existingReview.exists) {
        _showSnack("You have already reviewed this item");
        setState(() => _isSubmitting = false);
        return;
      }

      final buyerName = await _getBuyerName();

      await FirebaseFirestore.instance
          .collection('marketplace_reviews')
          .doc(reviewDocId)
          .set({
        'buyerId': buyerId,
        'sellerId': widget.sellerId,
        'itemId': widget.docId,
        'itemName': widget.itemName,
        'itemImage': widget.itemImage,
        'buyerName': buyerName,
        'rating': _userRating,
        'reviewText': _reviewController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('listings')
          .doc(widget.docId)
          .update({
        'isRated': true,
      });

      _showSnack("Review submitted successfully");

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showSnack("Failed to submit review: $e");
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  Widget _buildStar(int index) {
    return IconButton(
      onPressed: () {
        setState(() {
          _userRating = index;
        });
      },
      icon: Icon(
        index <= _userRating ? Icons.star_rounded : Icons.star_border_rounded,
        color: Colors.amber,
        size: 38,
      ),
    );
  }

  @override
  void dispose() {
    _reviewController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final Color pageBg =
        isDark ? const Color(0xFF0F0F13) : const Color(0xFFF6F7FB);
    final Color cardBg = isDark ? const Color(0xFF1B1B22) : Colors.white;
    final Color textPrimary = isDark ? Colors.white : Colors.black87;
    final Color textSecondary = isDark ? Colors.white70 : Colors.black54;
    final Color borderColor =
        isDark ? const Color(0xFF34343F) : const Color(0xFFE8EAF0);

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
                const Expanded(
                  child: Text(
                    "Rate Your Experience",
                    style: TextStyle(
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
              padding: const EdgeInsets.all(18),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: cardBg,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: borderColor),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(18),
                          child: widget.itemImage.isNotEmpty &&
                                  widget.itemImage.length > 100
                              ? Image.memory(
                                  base64Decode(widget.itemImage),
                                  height: 150,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  height: 150,
                                  color: Colors.grey.shade300,
                                  child: const Center(
                                    child: Icon(Icons.image, size: 50),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          widget.itemName,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          "How was your experience with the seller?",
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            5,
                            (index) => _buildStar(index + 1),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _getRatingLabel(_userRating),
                          style: TextStyle(
                            color: gRedMid,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 20),
                        Container(
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF111117)
                                : const Color(0xFFF5F6FA),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: borderColor),
                          ),
                          child: TextField(
                            controller: _reviewController,
                            maxLines: 5,
                            style: TextStyle(color: textPrimary),
                            decoration: InputDecoration(
                              hintText: "Write your review here...",
                              hintStyle: TextStyle(color: textSecondary),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.all(16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 22),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : submitReview,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: gRedMid,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.4,
                                    ),
                                  )
                                : const Text(
                                    "Complete Deal",
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}