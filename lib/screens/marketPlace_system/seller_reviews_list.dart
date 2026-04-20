import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class SellerReviewsList extends StatelessWidget {
  final String sellerId;

  const SellerReviewsList({
    super.key,
    required this.sellerId,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF1B1B22) : Colors.white;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final borderColor =
        isDark ? const Color(0xFF34343F) : const Color(0xFFE8EAF0);

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('marketplace_reviews')
          .where('sellerId', isEqualTo: sellerId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Text(
              "Failed to load reviews",
              style: TextStyle(color: textPrimary),
              textAlign: TextAlign.center,
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final rawDocs = snapshot.data!.docs;
        final docs = [...rawDocs];

        docs.sort((a, b) {
          final aData = a.data() as Map<String, dynamic>;
          final bData = b.data() as Map<String, dynamic>;

          final aTime = aData['createdAt'];
          final bTime = bData['createdAt'];

          if (aTime is Timestamp && bTime is Timestamp) {
            return bTime.compareTo(aTime);
          }
          if (aTime is Timestamp) return -1;
          if (bTime is Timestamp) return 1;
          return 0;
        });

        if (docs.isEmpty) {
          return Center(
            child: Text(
              "No reviews available",
              style: TextStyle(color: textPrimary),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: docs.length,
          itemBuilder: (context, index) {
            final data = docs[index].data() as Map<String, dynamic>;

            DateTime? time;
            if (data['createdAt'] is Timestamp) {
              time = (data['createdAt'] as Timestamp).toDate();
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.red.withOpacity(0.12),
                        child: const Icon(Icons.person, color: Colors.red),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          data['buyerName'] ?? "Buyer",
                          style: TextStyle(
                            color: textPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Text(
                        time != null
                            ? DateFormat('dd MMM yyyy').format(time)
                            : "",
                        style: TextStyle(
                          color: textPrimary.withOpacity(0.5),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: List.generate(
                      5,
                      (i) => Icon(
                        i < (data['rating'] ?? 0)
                            ? Icons.star_rounded
                            : Icons.star_border_rounded,
                        color: Colors.amber,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    data['reviewText'] ?? "",
                    style: TextStyle(
                      color: textPrimary.withOpacity(0.85),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Item: ${data['itemName'] ?? ''}",
                    style: TextStyle(
                      color: textPrimary.withOpacity(0.55),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}