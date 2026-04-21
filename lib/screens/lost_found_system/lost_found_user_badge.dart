import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'lost_found_rating_service.dart';

class LostFoundUserBadge extends StatelessWidget {
  final String userId;
  final double fontSize;
  final double iconSize;
  final EdgeInsetsGeometry padding;

  const LostFoundUserBadge({
    super.key,
    required this.userId,
    this.fontSize = 10.5,
    this.iconSize = 13,
    this.padding = const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    if (userId.trim().isEmpty) return const SizedBox.shrink();

    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .snapshots(),
      builder: (context, snapshot) {
        final data = snapshot.data?.data() ?? <String, dynamic>{};
        final int count = _safeInt(data['lf_rating_count']);
        final double avg = _safeDouble(data['lf_rating_avg']);

        if (count <= 0) return const SizedBox.shrink();

        final String label = LostFoundRatingService.badgeLabel(avg, count);
        final Color badgeColor = Color(
          LostFoundRatingService.badgeColor(label),
        );
        final Color bgColor = badgeColor.withOpacity(isDark ? 0.18 : 0.14);
        final Color borderColor = badgeColor.withOpacity(isDark ? 0.50 : 0.38);

        return Container(
          padding: padding,
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.workspace_premium_rounded,
                size: iconSize,
                color: badgeColor,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: badgeColor,
                  fontSize: fontSize,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  int _safeInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  double _safeDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }
}
