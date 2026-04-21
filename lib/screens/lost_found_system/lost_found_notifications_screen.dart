import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'lost_found_notification_service.dart';

const Color lfRed = Color(0xFFE53935);
const Color lfBg = Color(0xFFF6F6F7);
const Color lfTextPrimary = Color(0xFF1E1E1E);
const Color lfTextSecondary = Color(0xFF4B4B4B);
const Color lfTextMuted = Color(0xFF707070);

class LostFoundNotificationsScreen extends StatelessWidget {
  const LostFoundNotificationsScreen({super.key});

  bool _isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  IconData _iconForAction(String? actionType) {
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
        return Icons.chat_bubble_outline;
      case 'retry_message':
        return Icons.sms_outlined;
      case 'verification_answer':
        return Icons.verified_outlined;
      case 'returned':
        return Icons.assignment_turned_in_outlined;
      case 'received':
        return Icons.inventory_2_outlined;
      case 'lf_rating_received':
        return Icons.star_rounded;
      case 'lf_rating_sent':
        return Icons.star_outline_rounded;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  Color _cardBg(BuildContext context) =>
      _isDark(context) ? const Color(0xFF1B1B22) : Colors.white;

  Color _pageBg(BuildContext context) =>
      _isDark(context) ? const Color(0xFF121217) : lfBg;

  Color _textPrimary(BuildContext context) =>
      _isDark(context) ? Colors.white : lfTextPrimary;

  Color _textSecondary(BuildContext context) =>
      _isDark(context) ? const Color(0xFFB7BBC6) : lfTextSecondary;

  Color _textMuted(BuildContext context) =>
      _isDark(context) ? const Color(0xFF9EA4B0) : lfTextMuted;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    final service = LostFoundNotificationService();

    return Scaffold(
      backgroundColor: _pageBg(context),
      appBar: AppBar(
        title: const Text(
          'Notifications',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        backgroundColor: lfRed,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Mark all as read',
            onPressed: uid.isEmpty
                ? null
                : () async {
                    await service.markAllAsRead(uid);
                  },
            icon: const Icon(Icons.done_all),
          ),
        ],
      ),
      body: uid.isEmpty
          ? const Center(
              child: Text(
                'Please sign in to view notifications.',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            )
          : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: service.getNotificationsStream(uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Failed to load notifications.',
                      style: TextStyle(
                        color: _textPrimary(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;

                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No notifications yet.',
                      style: TextStyle(
                        color: _textSecondary(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(14),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data();
                    final title = (data['title'] ?? '').toString();
                    final body = (data['body'] ?? '').toString();
                    final actionType = data['actionType']?.toString();
                    final isRead = data['isRead'] == true;
                    final createdAt = data['createdAt'];

                    // Choose icon colour — gold for rating notifications
                    final bool isRatingNotif =
                        actionType == 'lf_rating_received' ||
                        actionType == 'lf_rating_sent';
                    final Color iconColor = isRatingNotif
                        ? const Color(0xFFFFD700)
                        : lfRed;
                    final Color iconBg = isRatingNotif
                        ? (isRead
                              ? const Color(0xFFFFF8DC).withOpacity(0.6)
                              : const Color(0xFFFFF8DC))
                        : (isRead
                              ? Colors.grey.withOpacity(0.12)
                              : lfRed.withOpacity(0.12));

                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () async {
                        if (!isRead) {
                          await service.markAsRead(doc.id);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _cardBg(context),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isRead
                                ? Colors.grey.withOpacity(0.18)
                                : (isRatingNotif
                                      ? const Color(
                                          0xFFFFD700,
                                        ).withOpacity(0.45)
                                      : lfRed.withOpacity(0.35)),
                            width: isRead ? 1 : 1.3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: BoxDecoration(
                                color: iconBg,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                _iconForAction(actionType),
                                color: iconColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title.isEmpty
                                              ? 'Notification'
                                              : title,
                                          style: TextStyle(
                                            color: _textPrimary(context),
                                            fontWeight: FontWeight.w800,
                                            fontSize: 14.5,
                                          ),
                                        ),
                                      ),
                                      if (!isRead)
                                        Container(
                                          width: 9,
                                          height: 9,
                                          decoration: BoxDecoration(
                                            color: isRatingNotif
                                                ? const Color(0xFFFFD700)
                                                : lfRed,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    body,
                                    style: TextStyle(
                                      color: _textSecondary(context),
                                      fontWeight: FontWeight.w500,
                                      height: 1.35,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    service.formatTime(createdAt),
                                    style: TextStyle(
                                      color: _textMuted(context),
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
