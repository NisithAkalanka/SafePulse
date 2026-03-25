import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../help/help_request.dart';
import '../theme/guardian_ui.dart';

/// Visual style aligned with **Help Nearby** feed cards (offer-help page) for the requester’s own list.
class HelpRequestNearbyStyle {
  HelpRequestNearbyStyle._();

  static const Color redPrimary = Color(0xFFD32F2F);

  static ({Color tagColor, Color markerColor, String? statusLabel}) styleFor(
    HelpRequest r, {
    bool isDark = false,
  }) {
    final lower = r.category.toLowerCase();
    final Color tagColor;
    final Color markerColor;
    String? statusLabel;

    if (isDark) {
      if (lower.contains('study')) {
        tagColor = const Color(0xFF1E3A5F);
        markerColor = Colors.redAccent;
      } else if (lower.contains('transport')) {
        tagColor = const Color(0xFF1A3D2E);
        markerColor = Colors.green;
        if (r.isUrgent) statusLabel = 'SOS';
      } else if (lower.contains('tech')) {
        tagColor = const Color(0xFF4A3728);
        markerColor = Colors.green;
      } else if (lower.contains('cash')) {
        tagColor = const Color(0xFF4A3D1A);
        markerColor = Colors.orangeAccent;
      } else {
        tagColor = const Color(0xFF3F3F46);
        markerColor = Colors.redAccent;
      }
    } else {
      if (lower.contains('study')) {
        tagColor = const Color(0xFFE3F2FD);
        markerColor = Colors.redAccent;
      } else if (lower.contains('transport')) {
        tagColor = const Color(0xFFE8F5E9);
        markerColor = Colors.green;
        if (r.isUrgent) statusLabel = 'SOS';
      } else if (lower.contains('tech')) {
        tagColor = const Color(0xFFFFF3E0);
        markerColor = Colors.green;
      } else if (lower.contains('cash')) {
        tagColor = const Color(0xFFFFF8E1);
        markerColor = Colors.orangeAccent;
      } else {
        tagColor = const Color(0xFFF5F5F7);
        markerColor = Colors.redAccent;
      }
    }

    return (tagColor: tagColor, markerColor: markerColor, statusLabel: statusLabel);
  }

  static String timeAgoLabel(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return 'Posted ${diff.inMinutes} mins ago';
    if (diff.inHours < 24) return 'Posted ${diff.inHours}h ago';
    return 'Posted ${diff.inDays}d ago';
  }
}

/// A **Help Nearby**–style featured card for **your** requests (edit/delete, no offer button).
class YourRequestNearbyFeaturedCard extends StatelessWidget {
  const YourRequestNearbyFeaturedCard({
    super.key,
    required this.request,
    required this.onEdit,
    required this.onDelete,
  });

  final HelpRequest request;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    const redPrimary = HelpRequestNearbyStyle.redPrimary;
    final g = GuardianTheme.of(context);
    final s = HelpRequestNearbyStyle.styleFor(request, isDark: g.isDark);
    final desc = request.description.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: g.panelBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: g.chipBorder),
        boxShadow: g.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 4,
                  height: 52,
                  margin: const EdgeInsets.only(right: 10, top: 2),
                  decoration: BoxDecoration(
                    color: s.tagColor,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                CircleAvatar(
                  radius: 18,
                  backgroundColor: redPrimary.withValues(
                    alpha: g.isDark ? 0.22 : 0.12,
                  ),
                  child: Icon(
                    Icons.person_rounded,
                    color: redPrimary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        request.category,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: g.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        request.requesterName.isNotEmpty
                            ? request.requesterName
                            : 'Requester',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: g.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              request.title,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: g.textPrimary,
                              ),
                            ),
                          ),
                          if (s.statusLabel != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: g.isDark
                                    ? const Color(0xFF14532D)
                                    : Colors.green.shade50,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                s.statusLabel!,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: g.isDark
                                      ? const Color(0xFF86EFAC)
                                      : Colors.green.shade700,
                                ),
                              ),
                            ),
                        ],
                      ),
                      if (desc.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          desc,
                          maxLines: 6,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: g.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.place_rounded,
                            size: 16,
                            color: redPrimary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              request.locationName,
                              style: TextStyle(
                                fontSize: 13,
                                color: g.captionGrey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'My request',
                            style: TextStyle(
                              fontSize: 12,
                              color: g.captionGrey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.send_rounded,
                            size: 14,
                            color: g.captionGrey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            HelpRequestNearbyStyle.timeAgoLabel(
                              request.createdAt,
                            ),
                            style: TextStyle(
                              fontSize: 12,
                              color: g.captionGrey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.event_available_rounded,
                            size: 14,
                            color: redPrimary.withValues(alpha: 0.75),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'Needed ${DateFormat.yMMMd().add_jm().format(request.neededAt)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: g.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (request.isUrgent)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: redPrimary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: redPrimary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Text(
                      'Urgent',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: redPrimary,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onEdit,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: redPrimary,
                      backgroundColor:
                          g.isDark ? Colors.transparent : null,
                      side: BorderSide(
                        color: redPrimary.withValues(alpha: g.isDark ? 0.75 : 0.5),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    label: const Text(
                      'Edit',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.redAccent,
                      backgroundColor:
                          g.isDark ? Colors.transparent : null,
                      side: const BorderSide(color: Colors.redAccent),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.delete_outline, size: 18),
                    label: const Text(
                      'Delete',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
