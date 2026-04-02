import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'lost_item_model.dart';
import 'lost_found_service.dart';
import 'lost_found_notification_service.dart';

class LostFoundAdminHub extends StatefulWidget {
  const LostFoundAdminHub({super.key});

  @override
  State<LostFoundAdminHub> createState() => _LostFoundAdminHubState();
}

class _LostFoundAdminHubState extends State<LostFoundAdminHub>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const Color lfRed = Color(0xFFE53935);
  static const Color cardDark = Color(0xFF1B1B22);
  static const Color pageDark = Color(0xFF121217);

  final LostFoundService _service = LostFoundService();
  final LostFoundNotificationService _notificationService =
      LostFoundNotificationService();

  String _selectedFilter = 'all'; // all | active | returned | pending

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {
          _selectedFilter = 'all';
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;

  Color get _pageBg => _isDark ? pageDark : const Color(0xFFF6F7FB);
  Color get _cardBg => _isDark ? cardDark : const Color(0xFF171822);
  Color get _softCardBg => _isDark ? const Color(0xFF20202A) : Colors.white;
  Color get _textPrimary => _isDark ? Colors.white : const Color(0xFF111111);
  Color get _textSecondary =>
      _isDark ? const Color(0xFFB7BBC6) : const Color(0xFF666666);
  Color get _borderColor =>
      _isDark ? const Color(0xFF32323D) : const Color(0xFFE8E8EE);

  bool _isPendingOrRejected(String status) {
    final s = status.trim().toLowerCase();
    return s.contains('pending') || s.contains('rejected');
  }

  bool _matchesFilter(LostItem item) {
    final status = item.status.trim().toLowerCase();

    switch (_selectedFilter) {
      case 'active':
        return status == 'active';
      case 'returned':
        return status == 'returned';
      case 'pending':
        return _isPendingOrRejected(item.status);
      case 'all':
      default:
        return true;
    }
  }

  Future<void> _confirmDelete(LostItem item, {bool isArchived = false}) async {
    final bool? ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          backgroundColor: _isDark ? const Color(0xFF1C1C25) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: Text(
            'Delete listing',
            style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w800),
          ),
          content: Text(
            'Are you sure you want to delete "${item.title}" from Lost & Found?',
            style: TextStyle(
              color: _textSecondary,
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: _textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: lfRed,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                'Delete',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (ok != true) return;

    try {
      if (!isArchived) {
        await _notificationService.notifyAdminDeletedPost(
          userId: item.userId,
          itemId: item.id,
          itemType: item.type,
          itemTitle: item.title,
          reason: 'because it may be unsuitable or due to some other reason',
        );
      }

      if (isArchived) {
        await FirebaseFirestore.instance
            .collection('lost_found_returned_archive')
            .doc(item.id)
            .delete();
      } else {
        await _service.deletePost(item.id);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('"${item.title}" deleted successfully'),
          backgroundColor: lfRed,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Delete failed: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Widget _buildImage(LostItem item) {
    if (item.imageData != null && item.imageData!.trim().isNotEmpty) {
      try {
        return ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.memory(
            base64Decode(item.imageData!),
            width: 72,
            height: 72,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _fallbackImage(),
          ),
        );
      } catch (_) {
        return _fallbackImage();
      }
    }

    if (item.imageUrl.trim().isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          item.imageUrl,
          width: 72,
          height: 72,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _fallbackImage(),
        ),
      );
    }

    return _fallbackImage();
  }

  Widget _fallbackImage() {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: const Color(0xFF262631),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(
        Icons.inventory_2_outlined,
        color: Colors.white70,
        size: 30,
      ),
    );
  }

  Widget _topActionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFEF5350),
            const Color(0xFFB71C1C).withOpacity(0.88),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
        boxShadow: [
          BoxShadow(
            color: lfRed.withOpacity(0.22),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.14),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: const Icon(
              Icons.admin_panel_settings_outlined,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lost & Found Quality Audit',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Review lost and found posts and maintain campus item safety.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.8,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabChip(String text, int index, IconData icon) {
    final bool active = _tabController.index == index;

    return Expanded(
      child: GestureDetector(
        onTap: () => _tabController.animateTo(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: active ? lfRed : _softCardBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: active ? lfRed : _borderColor),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: active ? Colors.white : _textSecondary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                text,
                style: TextStyle(
                  color: active ? Colors.white : _textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        color: _isDark ? Colors.white : const Color(0xFF1B1B22),
        fontWeight: FontWeight.w900,
        fontSize: 18,
      ),
    );
  }

  Widget _smallInfoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text.trim().isEmpty ? '-' : text,
        style: const TextStyle(
          color: Colors.white70,
          fontWeight: FontWeight.w700,
          fontSize: 11,
        ),
      ),
    );
  }

  Widget _statCard({
    required String keyName,
    required String count,
    required String label,
    required Color countColor,
  }) {
    final bool selected = _selectedFilter == keyName;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = keyName;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 96,
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF242433) : _cardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected
                ? lfRed.withOpacity(0.65)
                : Colors.white.withOpacity(0.08),
            width: selected ? 1.4 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? lfRed.withOpacity(0.16)
                  : Colors.black.withOpacity(0.18),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                count,
                style: TextStyle(
                  color: countColor,
                  fontSize: 34,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                label.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _postCard(LostItem item, {bool isArchived = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.07)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.16),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildImage(item),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title.trim().isEmpty
                            ? 'Untitled Item'
                            : item.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.category.trim().isEmpty
                            ? item.type
                            : item.category,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.red.shade300,
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _smallInfoChip(item.type),
                          _smallInfoChip(item.status),
                          _smallInfoChip(item.location),
                          if (isArchived) _smallInfoChip('Archived'),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: () => _confirmDelete(item, isArchived: isArchived),
              icon: const Icon(Icons.delete_outline, color: Color(0xFFB71C1C)),
              label: const Text(
                'DELETE LISTING FROM LOST & FOUND',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFFB71C1C),
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF4E3E5),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListSection(
    List<LostItem> items, {
    required String emptyText,
    bool isArchived = false,
  }) {
    if (items.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 16),
        decoration: BoxDecoration(
          color: _softCardBg,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: _borderColor),
        ),
        child: Text(
          emptyText,
          textAlign: TextAlign.center,
          style: TextStyle(color: _textSecondary, fontWeight: FontWeight.w700),
        ),
      );
    }

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _postCard(item, isArchived: isArchived),
            ),
          )
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String selectedType = _tabController.index == 0 ? 'Lost' : 'Found';

    return Scaffold(
      backgroundColor: _pageBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'System Administration',
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.2),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('lost_found_posts')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, liveSnapshot) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('lost_found_returned_archive')
                .orderBy('timestamp', descending: true)
                .snapshots(),
            builder: (context, archiveSnapshot) {
              final liveDocs = liveSnapshot.data?.docs ?? [];
              final archiveDocs = archiveSnapshot.data?.docs ?? [];

              final List<LostItem> liveItems = liveDocs
                  .map((d) => LostItem.fromMap(d.data(), d.id))
                  .toList();

              final List<LostItem> archivedReturnedItems = archiveDocs
                  .map((d) => LostItem.fromMap(d.data(), d.id))
                  .toList();

              final List<LostItem> liveTyped = liveItems
                  .where(
                    (e) => e.type.toLowerCase() == selectedType.toLowerCase(),
                  )
                  .toList();

              final List<LostItem> archivedTyped = archivedReturnedItems
                  .where(
                    (e) => e.type.toLowerCase() == selectedType.toLowerCase(),
                  )
                  .toList();

              final int activeCount = liveTyped
                  .where((e) => e.status.trim().toLowerCase() == 'active')
                  .length;

              final int pendingCount = liveTyped
                  .where((e) => _isPendingOrRejected(e.status))
                  .length;

              final int liveReturnedCount = liveTyped
                  .where((e) => e.status.trim().toLowerCase() == 'returned')
                  .length;

              final int archivedReturnedCount = archivedTyped.length;

              final int returnedCount =
                  liveReturnedCount + archivedReturnedCount;
              final int totalCount = liveTyped.length + archivedTyped.length;

              List<LostItem> visibleLive = liveTyped
                  .where(_matchesFilter)
                  .toList();
              List<LostItem> visibleArchived = archivedTyped
                  .where(_matchesFilter)
                  .toList();

              if (_selectedFilter != 'returned') {
                visibleArchived = [];
              }

              return Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 108, 18, 26),
                    decoration: BoxDecoration(
                      gradient: _isDark
                          ? const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFFFF3B3B),
                                Color(0xFFE10613),
                                Color(0xFFB30012),
                                Color(0xFF140910),
                              ],
                              stops: [0.0, 0.35, 0.72, 1.0],
                            )
                          : const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFFFF4B4B),
                                Color(0xFFB31217),
                                Color(0xFF1B1B1B),
                              ],
                              stops: [0.0, 0.62, 1.0],
                            ),
                      borderRadius: const BorderRadius.only(
                        bottomLeft: Radius.circular(34),
                        bottomRight: Radius.circular(34),
                      ),
                    ),
                    child: _topActionCard(),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: _statCard(
                                  keyName: 'all',
                                  count: '$totalCount',
                                  label: 'Total Posts',
                                  countColor: const Color(0xFF3B82F6),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _statCard(
                                  keyName: 'active',
                                  count: '$activeCount',
                                  label: 'Active Listings',
                                  countColor: const Color(0xFF69F0AE),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _statCard(
                                  keyName: 'returned',
                                  count: '$returnedCount',
                                  label: 'Returned Items',
                                  countColor: const Color(0xFFE040FB),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: _statCard(
                                  keyName: 'pending',
                                  count: '$pendingCount',
                                  label: 'Pending / Rejected',
                                  countColor: const Color(0xFFFFA000),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          _sectionTitle('Live Lost & Found Logs'),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              _tabChip(
                                'Lost Items',
                                0,
                                Icons.search_off_outlined,
                              ),
                              const SizedBox(width: 10),
                              _tabChip(
                                'Found Items',
                                1,
                                Icons.check_circle_outline,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (liveSnapshot.connectionState ==
                                  ConnectionState.waiting &&
                              archiveSnapshot.connectionState ==
                                  ConnectionState.waiting &&
                              liveDocs.isEmpty &&
                              archiveDocs.isEmpty)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.symmetric(vertical: 30),
                                child: CircularProgressIndicator(),
                              ),
                            )
                          else ...[
                            _buildListSection(
                              visibleLive,
                              emptyText: _selectedFilter == 'returned'
                                  ? 'No live returned items available.'
                                  : 'No items available for this filter.',
                            ),
                            if (_selectedFilter == 'returned' &&
                                visibleArchived.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                'Archived Returned Items',
                                style: TextStyle(
                                  color: _isDark
                                      ? Colors.white
                                      : const Color(0xFF1B1B22),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _buildListSection(
                                visibleArchived,
                                emptyText: 'No archived returned items.',
                                isArchived: true,
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}
