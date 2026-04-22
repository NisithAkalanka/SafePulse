import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/notification_service.dart';
import '../help_private_chat_screen.dart';
import '../lost_found_system/lost_found_detail_screen.dart';
import '../lost_found_system/lost_found_notification_service.dart';
import '../lost_found_system/lost_found_service.dart';
import '../sos_system/sos_tracking_map.dart';

class AlertsHubScreen extends StatefulWidget {
  const AlertsHubScreen({super.key});

  @override
  State<AlertsHubScreen> createState() => _AlertsHubScreenState();
}

class _AlertsHubScreenState extends State<AlertsHubScreen> {
  final Set<String> _processedAlertIds = {};
  final DateTime _screenStartTime = DateTime.now();
  final LostFoundNotificationService _lostFoundNotificationService =
      LostFoundNotificationService();
  final LostFoundService _lostFoundService = LostFoundService();

  String _formatHelperBadge(String? rawBadge) {
    switch ((rawBadge ?? '').trim().toLowerCase()) {
      case 'gold':
        return 'Gold';
      case 'silver':
        return 'Silver';
      default:
        return 'Bronze';
    }
  }

  Color _helperBadgeColor(String badge) {
    switch (badge.toLowerCase()) {
      case 'gold':
        return const Color(0xFFD4A017);
      case 'silver':
        return const Color(0xFF8A94A6);
      default:
        return const Color(0xFFB86A2E);
    }
  }

  void _showHelpAcceptedDialog({
    required String notificationDocId,
    required String requestId,
    required String category,
    required String requestTitle,
    required String requestLocation,
    required String helperBadge,
  }) {
    if (!mounted) return;

    final badge = _formatHelperBadge(helperBadge);
    final badgeColor = _helperBadgeColor(badge);
    final subtitle = requestTitle.trim().isNotEmpty
        ? 'Your help offer for $requestTitle has been accepted.'
        : 'Your help offer has been accepted.';

    showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 28,
                  offset: Offset(0, 14),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                        color: Color(0xFFE8F6EC),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF2EAD4B),
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Help Accepted',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1A1D24),
                              height: 1.05,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 15,
                              color: Color(0xFF4C5563),
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F9FC),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE5EAF1)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.3,
                          color: Color(0xFF6B7280),
                        ),
                      ),
                      if (requestTitle.trim().isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          requestTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1D24),
                          ),
                        ),
                      ],
                      if (requestLocation.trim().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(
                              Icons.place_rounded,
                              size: 16,
                              color: Color(0xFF6B7280),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                requestLocation,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF4C5563),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: badgeColor.withOpacity(0.28),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.workspace_premium_rounded,
                              color: badgeColor,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Your helper has a $badge badge.',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: badgeColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: const Text(
                        'CLOSE',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(dialogContext);
                        try {
                          await FirebaseFirestore.instance
                              .collection('help_offer_notifications')
                              .doc(notificationDocId)
                              .set(<String, dynamic>{
                                'helperAcceptedDialogOpened': true,
                                'helperAcceptedDialogOpenedAt':
                                    FieldValue.serverTimestamp(),
                              }, SetOptions(merge: true));
                        } catch (e) {
                          debugPrint(
                            'Failed to persist helper accepted dialog state: $e',
                          );
                        }
                        if (requestId.isEmpty) return;
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => HelpPrivateChatScreen(
                              requestId: requestId,
                              title: category,
                              subtitle: requestTitle,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2EAD4B),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      icon: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 18,
                      ),
                      label: const Text(
                        'CONTACT',
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  IconData _lostFoundIcon(String? actionType) {
    switch (actionType) {
      case 'new_post':
        return Icons.campaign_outlined;
      case 'claim_request':
        return Icons.person_search_outlined;
      case 'request_chat':
        return Icons.chat_outlined;
      case 'chat_accepted':
        return Icons.mark_chat_read_outlined;
      case 'chat_rejected':
        return Icons.cancel_outlined;
      case 'retry_message':
        return Icons.sms_outlined;
      case 'verification_answer':
        return Icons.verified_outlined;
      case 'returned':
        return Icons.assignment_turned_in_outlined;
      case 'received':
        return Icons.inventory_2_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  DateTime _toDateTime(Object? raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is DateTime) return raw;
    return DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> _openLostFoundFromNotification(
    BuildContext context,
    String docId,
    Map<String, dynamic> row,
  ) async {
    final itemId = (row['itemId'] ?? '').toString();

    if (row['isRead'] != true) {
      await _lostFoundNotificationService.markAsRead(docId);
    }

    if (itemId.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Related Lost & Found post not found.')),
      );
      return;
    }

    final item = await _lostFoundService.getItemById(itemId);

    if (!mounted) return;

    if (item == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This Lost & Found post is no longer available.'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => LostFoundDetailScreen(item: item)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color pageBg = isDark
        ? const Color(0xFF121217)
        : const Color(0xFFF6F7FB);
    final Color cardBg = isDark ? const Color(0xFF1B1B22) : Colors.white;
    final Color textPrimary = isDark ? Colors.white : const Color(0xFF1B1B22);
    final Color textSecondary = isDark
        ? const Color(0xFFB7BBC6)
        : const Color(0xFF747A86);
    final Color softBg = isDark
        ? const Color(0xFF23232B)
        : const Color(0xFFF9FAFC);

    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: pageBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Active Safety Alerts",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          if (uid != null)
            IconButton(
              tooltip: 'Mark Lost & Found as read',
              onPressed: () async {
                await _lostFoundNotificationService.markAllAsRead(uid);
              },
              icon: const Icon(Icons.done_all, color: Colors.white),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 100, 18, 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? const [
                            Color(0xFFFF3B3B),
                            Color(0xFFE10613),
                            Color(0xFFB30012),
                            Color(0xFF140910),
                          ]
                        : const [
                            Color(0xFFFF4B4B),
                            Color(0xFFB31217),
                            Color(0xFF1B1B1B),
                          ],
                    stops: isDark
                        ? const [0.0, 0.35, 0.72, 1.0]
                        : const [0.0, 0.62, 1.0],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(34),
                    bottomRight: Radius.circular(34),
                  ),
                ),
                child: Column(
                  children: const [
                    Text(
                      "Emergency Alerts",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "Real-time SOS alerts, help updates, and lost & found notifications",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('alerts')
                    .orderBy('time', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFB31217),
                        ),
                      ),
                    );
                  }

                  final alerts = snapshot.data!.docs;

                  for (final doc in alerts) {
                    final data = doc.data() as Map<String, dynamic>;
                    final source = (data['source'] ?? '').toString();
                    final status = (data['status'] ?? '').toString();
                    if (source == 'help_offer' || status == 'HelpOffer') {
                      continue;
                    }
                    final alertId = doc.id;
                    if (_processedAlertIds.contains(alertId)) continue;

                    final time = data['time'];
                    if (time is Timestamp) {
                      final dt = time.toDate();
                      if (dt.isAfter(_screenStartTime)) {
                        final type = (data['type'] ?? 'N/A').toString();
                        final address = (data['address'] ?? 'No location')
                            .toString();
                        NotificationService.showSOSNotification(type, address);
                      }
                    }
                    _processedAlertIds.add(alertId);
                  }

                  return StreamBuilder<QuerySnapshot>(
                    stream: uid == null
                        ? null
                        : FirebaseFirestore.instance
                              .collection('help_offer_notifications')
                              .where(
                                Filter.or(
                                  Filter('recipientUid', isEqualTo: uid),
                                  Filter('helperUid', isEqualTo: uid),
                                ),
                              )
                              .snapshots(),
                    builder: (context, offerSnap) {
                      return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                        stream: uid == null
                            ? null
                            : _lostFoundNotificationService
                                  .getNotificationsStream(uid),
                        builder: (context, lfSnap) {
                          final rows = <Map<String, dynamic>>[];

                          for (final d in alerts) {
                            final data = d.data() as Map<String, dynamic>;
                            final source = (data['source'] ?? '').toString();
                            final status = (data['status'] ?? '').toString();
                            if (source == 'help_offer' ||
                                status == 'HelpOffer') {
                              continue;
                            }
                            rows.add({
                              'id': d.id,
                              'rowType': 'sos',
                              'title': (data['user_email'] ?? "Unknown User")
                                  .toString(),
                              'type': (data['type'] ?? 'N/A').toString(),
                              'address': (data['address'] ?? 'No location')
                                  .toString(),
                              'time': data['time'],
                            });
                          }

                          if (offerSnap.hasData) {
                            final uid = FirebaseAuth.instance.currentUser?.uid;

                            for (final d in offerSnap.data!.docs) {
                              final data = d.data() as Map<String, dynamic>;
                              final String docId = d.id;
                              final bool isRecipient =
                                  data['recipientUid'] == uid;
                              final bool isHelper = data['helperUid'] == uid;
                              final bool isAccepted = data['accepted'] == true;
                              final bool helperAcceptedDialogOpened =
                                  data['helperAcceptedDialogOpened'] == true;

                              if (isHelper &&
                                  isAccepted &&
                                  !helperAcceptedDialogOpened &&
                                  !_processedAlertIds.contains(
                                    'offer_accepted_$docId',
                                  )) {
                                WidgetsBinding.instance.addPostFrameCallback((
                                  _,
                                ) {
                                  if (!mounted) return;

                                  final requestCategory =
                                      (data['requestCategory'] ??
                                              'Help request')
                                          .toString();
                                  final requestTitle =
                                      (data['requestTitle'] ?? '').toString();
                                  final helperBadge = data['helperBadge']
                                      ?.toString();
                                  final requestLocation =
                                      (data['requestLocationName'] ?? 'Nearby')
                                          .toString();
                                  _showHelpAcceptedDialog(
                                    notificationDocId: docId,
                                    requestId: (data['requestId'] ?? '')
                                        .toString(),
                                    category: requestCategory,
                                    requestTitle: requestTitle,
                                    requestLocation: requestLocation,
                                    helperBadge: helperBadge ?? '',
                                  );
                                });

                                _processedAlertIds.add('offer_accepted_$docId');
                              }

                              final String helperBadge =
                                  (data['helperBadge'] ?? '')
                                      .toString()
                                      .trim()
                                      .toLowerCase();
                              final String requestTitle =
                                  (data['requestTitle'] ?? '').toString();
                              final String acceptedBody =
                                  requestTitle.isNotEmpty
                                  ? 'The requester accepted your help offer for $requestTitle.'
                                  : 'The requester accepted your help offer.';
                              final String badgeBody = helperBadge.isNotEmpty
                                  ? ' Your helper badge is $helperBadge.'
                                  : '';

                              if (isRecipient || isHelper) {
                                rows.add({
                                  'id': d.id,
                                  'rowType': 'offer',
                                  'requestId': data['requestId'],
                                  'requestTitle': requestTitle,
                                  'title': isHelper && isAccepted
                                      ? 'Offer Accepted'
                                      : isHelper
                                      ? "You offered help to ${data['requestCategory'] ?? 'someone'}"
                                      : (data['helperName'] ?? "A helper")
                                            .toString(),
                                  'body': isHelper && isAccepted
                                      ? '$acceptedBody$badgeBody'
                                      : '',
                                  'type':
                                      (data['requestCategory'] ?? 'Help offer')
                                          .toString(),
                                  'address':
                                      (data['requestLocationName'] ?? 'Nearby')
                                          .toString(),
                                  'time': data['createdAt'],
                                });
                              }
                            }
                          }

                          if (lfSnap.hasData) {
                            for (final d in lfSnap.data!.docs) {
                              final data = d.data();

                              rows.add({
                                'id': d.id,
                                'rowType': 'lost_found',
                                'title': (data['title'] ?? 'Notification')
                                    .toString(),
                                'body': (data['body'] ?? '').toString(),
                                'actionType': data['actionType']?.toString(),
                                'itemId': data['itemId']?.toString(),
                                'itemType': data['itemType']?.toString(),
                                'isRead': data['isRead'] == true,
                                'time': data['createdAt'],
                              });
                            }
                          }

                          rows.sort(
                            (a, b) => _toDateTime(
                              b['time'],
                            ).compareTo(_toDateTime(a['time'])),
                          );

                          if (rows.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.fromLTRB(
                                24,
                                32,
                                24,
                                24,
                              ),
                              child: Center(
                                child: Text(
                                  "No alerts or notifications at the moment.",
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            );
                          }

                          return ListView.builder(
                            itemCount: rows.length,
                            padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              final row = rows[index];
                              final String rowType = (row['rowType'] ?? '')
                                  .toString();
                              final String docId = row['id'] as String;

                              final bool isOffer = rowType == 'offer';
                              final bool isSOS = rowType == 'sos';
                              final bool isLostFound = rowType == 'lost_found';
                              final bool isUnreadLf =
                                  isLostFound && row['isRead'] != true;

                              IconData leadingIcon;
                              Color leadingIconColor;
                              Color leadingBg;

                              if (isSOS) {
                                leadingIcon = Icons.warning_amber_rounded;
                                leadingIconColor = const Color(0xFFB31217);
                                leadingBg = const Color(0xFFFFE3E3);
                              } else if (isOffer) {
                                leadingIcon =
                                    Icons.check_circle_outline_rounded;
                                leadingIconColor = const Color(0xFF1E9E5A);
                                leadingBg = const Color(0xFFE5F7EE);
                              } else {
                                leadingIcon = _lostFoundIcon(
                                  row['actionType']?.toString(),
                                );
                                leadingIconColor = const Color(0xFFE53935);
                                leadingBg = isUnreadLf
                                    ? const Color(0xFFFFE3E3)
                                    : softBg;
                              }

                              return Container(
                                margin: const EdgeInsets.only(bottom: 14),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isUnreadLf
                                        ? const Color(
                                            0xFFE53935,
                                          ).withOpacity(0.30)
                                        : Colors.transparent,
                                    width: isUnreadLf ? 1.2 : 0,
                                  ),
                                  boxShadow: const [
                                    BoxShadow(
                                      color: Color(0x12000000),
                                      blurRadius: 14,
                                      offset: Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: leadingBg,
                                    ),
                                    child: Icon(
                                      leadingIcon,
                                      color: leadingIconColor,
                                      size: 26,
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          row['title'] as String,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            color: textPrimary,
                                          ),
                                        ),
                                      ),
                                      if (isUnreadLf)
                                        Container(
                                          width: 9,
                                          height: 9,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFE53935),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        if (isSOS) ...[
                                          Text(
                                            "Type: ${row['type']}",
                                            style: TextStyle(
                                              color: textSecondary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "📍 ${row['address']}",
                                            style: TextStyle(
                                              color: textSecondary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ] else if (isOffer) ...[
                                          if ((row['body'] ?? '')
                                              .toString()
                                              .trim()
                                              .isNotEmpty) ...[
                                            Text(
                                              row['body'].toString(),
                                              style: TextStyle(
                                                color: textSecondary,
                                                fontWeight: FontWeight.w600,
                                                height: 1.35,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                          ],
                                          Text(
                                            "Type: ${row['type']}",
                                            style: TextStyle(
                                              color: textSecondary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            "📍 ${row['address']}",
                                            style: TextStyle(
                                              color: textSecondary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ] else ...[
                                          Text(
                                            (row['body'] ?? '').toString(),
                                            style: TextStyle(
                                              color: textSecondary,
                                              fontWeight: FontWeight.w600,
                                              height: 1.35,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 6),
                                        Text(
                                          _lostFoundNotificationService
                                              .formatTime(row['time']),
                                          style: TextStyle(
                                            color: textSecondary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  trailing: isOffer
                                      ? FilledButton.icon(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: const Color(
                                              0xFF1E9E5A,
                                            ),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 8,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                            ),
                                          ),
                                          onPressed: () {
                                            final requestId =
                                                (row['requestId'] ?? '')
                                                    .toString();
                                            if (requestId.isEmpty) {
                                              ScaffoldMessenger.of(
                                                context,
                                              ).showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Request reference is missing.',
                                                  ),
                                                ),
                                              );
                                              return;
                                            }
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (context) =>
                                                    HelpPrivateChatScreen(
                                                      requestId: requestId,
                                                      title:
                                                          row['type'] as String,
                                                      subtitle:
                                                          (row['requestTitle']
                                                                  ?.toString()
                                                                  .isNotEmpty ==
                                                              true)
                                                          ? row['requestTitle']
                                                                as String
                                                          : row['address']
                                                                as String,
                                                    ),
                                              ),
                                            );
                                          },
                                          icon: const Icon(
                                            Icons.chat_bubble_outline_rounded,
                                            size: 16,
                                          ),
                                          label: const Text(
                                            'Contact',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                        )
                                      : Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: softBg,
                                          ),
                                          child: Icon(
                                            isSOS
                                                ? Icons.map_outlined
                                                : Icons.notifications_outlined,
                                            color: const Color(0xFFB31217),
                                          ),
                                        ),
                                  onTap: () async {
                                    if (isLostFound) {
                                      await _openLostFoundFromNotification(
                                        context,
                                        docId,
                                        row,
                                      );
                                      return;
                                    }

                                    if (isOffer) {
                                      final requestId = (row['requestId'] ?? '')
                                          .toString();
                                      if (requestId.isEmpty) return;

                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              HelpPrivateChatScreen(
                                                requestId: requestId,
                                                title: row['type'] as String,
                                                subtitle:
                                                    (row['requestTitle']
                                                            ?.toString()
                                                            .isNotEmpty ==
                                                        true)
                                                    ? row['requestTitle']
                                                          as String
                                                    : row['address'] as String,
                                              ),
                                        ),
                                      );
                                    } else if (isSOS) {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SOSTrackingMap(
                                            victimEmail: row['title'] as String,
                                            alertId: docId,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
