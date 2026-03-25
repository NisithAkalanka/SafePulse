import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'lost_item_model.dart';
import 'lost_found_service.dart';
import 'lost_found_detail_screen.dart';

const Color lfRed = Color(0xFFE53935);
const Color lfTextPrimary = Color(0xFF1E1E1E);
const Color lfTextSecondary = Color(0xFF4B4B4B);
const Color lfTextMuted = Color(0xFF707070);

class LostFoundItemsSection extends StatelessWidget {
  final String type;
  final String query;
  final String category;
  final String locationFilter;
  final bool showOnlyMyPosts;
  final VoidCallback? categoryChipOnTap;

  const LostFoundItemsSection({
    super.key,
    required this.type,
    required this.query,
    required this.category,
    required this.locationFilter,
    required this.showOnlyMyPosts,
    this.categoryChipOnTap,
  });

  bool _matchFilters(LostItem i, String? currentUid) {
    final q = query.toLowerCase();
    final loc = locationFilter.toLowerCase();

    final matchCategory = category == "All" || i.category == category;
    final matchSearch =
        q.isEmpty ||
        i.title.toLowerCase().contains(q) ||
        i.category.toLowerCase().contains(q) ||
        i.location.toLowerCase().contains(q);
    final matchLoc = loc.isEmpty || i.location.toLowerCase().contains(loc);
    final matchMine =
        !showOnlyMyPosts || (currentUid != null && i.userId == currentUid);

    return matchCategory && matchSearch && matchLoc && matchMine;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return now.year == date.year &&
        now.month == date.month &&
        now.day == date.day;
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBg = isDark ? const Color(0xFF1B1B22) : Colors.white;
    final Color textPrimary = isDark ? Colors.white : lfTextPrimary;
    final Color textMuted = isDark ? const Color(0xFF9EA4B0) : lfTextMuted;
    final Color borderColor = isDark
        ? const Color(0xFF34343F)
        : const Color(0xFFE5E7EE);

    return StreamBuilder<List<LostItem>>(
      stream: LostFoundService().getItemsStream(type),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text(
                "Loading error. Please reopen Lost & Found.",
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(30),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final filtered = snapshot.data!
            .where((i) => _matchFilters(i, currentUid))
            .toList();

        final todayPosts = filtered
            .where((i) => _isToday(i.timestamp))
            .toList();

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showOnlyMyPosts) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: lfRed.withOpacity(0.20)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.bookmark_border, color: lfRed),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Showing only your posts",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : lfRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  const Spacer(),
                  GestureDetector(
                    onTap: categoryChipOnTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderColor),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.grid_view_rounded,
                            color: lfRed,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 82),
                            child: Text(
                              category,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: textPrimary,
                              ),
                            ),
                          ),
                          if (categoryChipOnTap != null) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: lfRed,
                              size: 18,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                "Today",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 10),
              if (todayPosts.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  alignment: Alignment.center,
                  child: Text(
                    "No posts added today.",
                    style: TextStyle(
                      color: textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 220,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: todayPosts.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return SizedBox(
                        width: 162,
                        child: _ItemCard(
                          item: todayPosts[index],
                          compact: true,
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 14),
              Text(
                "All Posts",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              if (filtered.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  alignment: Alignment.center,
                  child: Text(
                    category == "All"
                        ? "No items found."
                        : "No items found in $category.",
                    style: TextStyle(
                      color: textMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.84,
                  ),
                  itemBuilder: (context, index) {
                    return _ItemCard(item: filtered[index]);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ItemCard extends StatefulWidget {
  final LostItem item;
  final bool compact;

  const _ItemCard({required this.item, this.compact = false});

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> {
  bool _pressed = false;

  bool get _isOwner {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid != null && uid == widget.item.userId;
  }

  ({Color bg, Color text}) _statusColors(String status) {
    switch (status) {
      case 'Active':
        return (bg: const Color(0xFFB71C1C), text: Colors.white);
      case 'Chat Enabled':
      case 'Answer Submitted':
        return (bg: const Color(0xFFEAF2FF), text: const Color(0xFF1565C0));
      case 'Claim Pending':
      case 'Verification Pending':
        return (bg: const Color(0xFFFFF4DB), text: const Color(0xFFB26A00));
      case 'Returned':
        return (bg: const Color(0xFFE8F6EA), text: const Color(0xFF2E7D32));
      default:
        return (bg: Colors.white.withOpacity(0.92), text: Colors.black87);
    }
  }

  String _remainingDeleteTime() {
    final returnedAt = widget.item.returnedAt;
    if (returnedAt == null) return "Deletes in 1h 0m";

    final expiry = returnedAt.add(const Duration(hours: 1));
    final remaining = expiry.difference(DateTime.now());

    if (remaining.isNegative) return "Deleting soon";

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);

    if (hours > 0) {
      return "Deletes in ${hours}h ${minutes}m";
    }
    return "Deletes in ${minutes}m";
  }

  String _formatPostedDate(DateTime date) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[date.month]} ${date.day}, ${date.year}';
  }

  Widget _buildImage(String? base64String, double imageHeight) {
    if (base64String == null || base64String.isEmpty) {
      return Container(
        height: imageHeight,
        width: double.infinity,
        color: Colors.grey[200],
        child: const Icon(
          Icons.image_not_supported,
          color: Colors.grey,
          size: 50,
        ),
      );
    }

    try {
      return Image.memory(
        base64Decode(base64String),
        fit: BoxFit.cover,
        width: double.infinity,
        height: imageHeight,
        errorBuilder: (context, error, stackTrace) => Container(
          height: imageHeight,
          width: double.infinity,
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image),
        ),
      );
    } catch (e) {
      return Container(
        height: imageHeight,
        width: double.infinity,
        color: Colors.grey[200],
        child: const Icon(Icons.broken_image),
      );
    }
  }

  Widget _buildStatusOverlay() {
    final colors = _statusColors(widget.item.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colors.bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            widget.item.status,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.text,
              fontSize: 9.0,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (widget.item.status == 'Returned') ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.68),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _remainingDeleteTime(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _openDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LostFoundDetailScreen(item: widget.item),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color innerCardBg = isDark ? const Color(0xFF1B1B22) : Colors.white;
    final Color imageBg = isDark
        ? const Color(0xFF23232B)
        : const Color(0xFFF2F2F2);
    final Color textPrimary = isDark ? Colors.white : lfTextPrimary;
    final Color textSecondary = isDark
        ? const Color(0xFFB7BBC6)
        : lfTextSecondary;
    final Color textMuted = isDark ? const Color(0xFF9EA4B0) : lfTextMuted;

    final item = widget.item;
    final double imageHeight = widget.compact ? 84 : 94;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: _openDetails,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE53935), Color(0xFF842121), Color(0xFF2B1616)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Container(
          margin: EdgeInsets.all(_pressed ? 2.0 : 3.0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFB52B2B), Color(0xFF521E1E)],
            ),
            borderRadius: BorderRadius.circular(21),
          ),
          child: Container(
            margin: EdgeInsets.all(_pressed ? 1.6 : 2.2),
            decoration: BoxDecoration(
              color: innerCardBg,
              borderRadius: BorderRadius.circular(19),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      height: imageHeight,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: imageBg,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(19),
                        ),
                      ),
                      child:
                          item.imageData != null && item.imageData!.isNotEmpty
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(19),
                              ),
                              child: _buildImage(item.imageData, imageHeight),
                            )
                          : item.imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(19),
                              ),
                              child: Image.network(
                                item.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => const Center(
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    color: lfRed,
                                    size: 30,
                                  ),
                                ),
                              ),
                            )
                          : const Center(
                              child: Icon(
                                Icons.inventory_2_outlined,
                                size: 34,
                                color: lfRed,
                              ),
                            ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 92),
                        child: _buildStatusOverlay(),
                      ),
                    ),
                    if (_isOwner)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF23232B).withOpacity(0.95)
                                : Colors.white.withOpacity(0.95),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.bookmark_border,
                            color: lfRed,
                            size: 17,
                          ),
                        ),
                      ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(11, 9, 11, 9),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: widget.compact ? 13.2 : 14,
                            height: 1.18,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(top: 1),
                              child: Icon(
                                Icons.place_outlined,
                                size: 14,
                                color: textMuted,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.location.isEmpty
                                    ? "Location not added"
                                    : item.location,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 11.5,
                                  height: 1.18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Posted: ${_formatPostedDate(item.timestamp)}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: textMuted,
                            fontSize: 10.8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
