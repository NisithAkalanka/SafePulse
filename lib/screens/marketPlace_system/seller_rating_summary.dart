import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SellerRatingSummary extends StatelessWidget {
  final String sellerId;

  const SellerRatingSummary({
    super.key,
    required this.sellerId,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final cardBg = isDark ? const Color(0xFF1B1B22) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF34343F) : const Color(0xFFE8EAF0);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('marketplace_reviews')
          .where('sellerId', isEqualTo: sellerId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;

        if (docs.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
            ),
            child: Text(
              "No reviews yet",
              style: TextStyle(color: textPrimary),
            ),
          );
        }

        double total = 0;
        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          total += (data['rating'] ?? 0).toDouble();
        }

        final average = total / docs.length;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              const Icon(Icons.star_rounded, color: Colors.amber, size: 30),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    average.toStringAsFixed(1),
                    style: TextStyle(
                      color: textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "${docs.length} reviews",
                    style: TextStyle(
                      color: textPrimary.withOpacity(0.65),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}