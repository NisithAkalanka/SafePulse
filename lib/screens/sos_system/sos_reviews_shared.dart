import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../theme/guardian_ui.dart';

const String kSosServiceReviewsCollection = 'sos_service_reviews';

/// Puts the signed-in user's review(s) first; preserves Firestore order within each group.
List<QueryDocumentSnapshot<Map<String, dynamic>>> sortSosReviewsMineFirst(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  String? uid,
) {
  if (uid == null || docs.isEmpty) return List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(docs);
  final mine = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
  final others = <QueryDocumentSnapshot<Map<String, dynamic>>>[];
  for (final d in docs) {
    if (d.data()['userId'] == uid) {
      mine.add(d);
    } else {
      others.add(d);
    }
  }
  return [...mine, ...others];
}

String formatSosReviewDate(dynamic createdAt) {
  if (createdAt is Timestamp) {
    return DateFormat('yyyy-MM-dd').format(createdAt.toDate());
  }
  return '';
}

({int count, double avgRating, double satisfaction01}) computeSosReviewStats(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
) {
  if (docs.isEmpty) {
    return (count: 0, avgRating: 0, satisfaction01: 0);
  }
  var sum = 0.0;
  for (final d in docs) {
    final r = (d.data()['rating'] as num?)?.toDouble() ?? 0;
    sum += r;
  }
  final avg = sum / docs.length;
  final sat = (avg / 5.0).clamp(0.0, 1.0);
  return (count: docs.length, avgRating: avg, satisfaction01: sat);
}

/// Single review card (Firestore document fields). Styled like Guardian Map cards.
class SosReviewCard extends StatelessWidget {
  const SosReviewCard({
    super.key,
    required this.data,
    this.highlightMine = false,
  });

  final Map<String, dynamic> data;
  final bool highlightMine;

  static const Color _amber = Color(0xFFFFC107);

  @override
  Widget build(BuildContext context) {
    final g = GuardianTheme.of(context);
    final name = (data['displayName'] as String?)?.trim().isNotEmpty == true
        ? data['displayName'] as String
        : 'Member';
    final rating = (data['rating'] as num?)?.clamp(1, 5).toInt() ?? 0;
    final text = (data['text'] as String?)?.trim() ?? '';
    final dateStr = formatSosReviewDate(data['createdAt']);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: g.panelBg,
        borderRadius: BorderRadius.circular(26),
        boxShadow: g.cardShadow,
        border: Border.all(
          color: highlightMine
              ? GuardianUi.redPrimary.withValues(alpha: 0.42)
              : g.chipBorder,
          width: highlightMine ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: GuardianUi.redTint,
                child: const Icon(
                  Icons.person_rounded,
                  color: GuardianUi.redPrimary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                          color: g.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (highlightMine) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: GuardianUi.redTint,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'You',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: GuardianUi.redPrimary,
                          ),
                        ),
                      ),
                    ] else ...[
                      const SizedBox(width: 6),
                      Icon(
                        Icons.verified_rounded,
                        size: 18,
                        color: Colors.green.shade600,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ...List.generate(
                5,
                (i) => Icon(
                  Icons.star_rounded,
                  size: 16,
                  color: i < rating ? _amber : g.starEmpty,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                dateStr.isEmpty ? '—' : dateStr,
                style: TextStyle(
                  fontSize: 12,
                  color: g.captionGrey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (text.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              text,
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: g.bodyTextMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
