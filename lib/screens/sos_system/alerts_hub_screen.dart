import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/notification_service.dart'; // Import NotificationService
import 'sos_tracking_map.dart'; // කලින් අපි හදපු map පේජ් එක

class AlertsHubScreen extends StatefulWidget {
  const AlertsHubScreen({super.key});

  @override
  State<AlertsHubScreen> createState() => _AlertsHubScreenState();
}

class _AlertsHubScreenState extends State<AlertsHubScreen> {
  final Set<String> _processedAlertIds = {};
  final DateTime _screenStartTime = DateTime.now();

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
                      "Real-time SOS alerts from users",
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
                  final uid = FirebaseAuth.instance.currentUser?.uid;

                  // Trigger local notifications for new emergency alerts
                  for (final doc in alerts) {
                    final data = doc.data() as Map<String, dynamic>;
                    final alertId = doc.id;
                    if (_processedAlertIds.contains(alertId)) continue;

                    final time = data['time'];
                    if (time is Timestamp) {
                      final dt = time.toDate();
                      if (dt.isAfter(_screenStartTime)) {
                        final type = (data['type'] ?? 'N/A').toString();
                        final address = (data['address'] ?? 'No location').toString();
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
                            .where(Filter.or(
                              Filter('recipientUid', isEqualTo: uid),
                              Filter('helperUid', isEqualTo: uid),
                            ))
                            .snapshots(),
                    builder: (context, offerSnap) {
                      final rows = <Map<String, dynamic>>[];

                      for (final d in alerts) {
                        final data = d.data() as Map<String, dynamic>;
                        rows.add({
                          'id': d.id,
                          'isOffer': false,
                          'title': (data['user_email'] ?? "Unknown User").toString(),
                          'type': (data['type'] ?? 'N/A').toString(),
                          'address': (data['address'] ?? 'No location').toString(),
                          'time': data['time'],
                        });
                      }

                      if (offerSnap.hasData) {
                        final uid = FirebaseAuth.instance.currentUser?.uid;
                        for (final d in offerSnap.data!.docs) {
                          final data = d.data() as Map<String, dynamic>;
                          // Show as notification if I'm the recipient (normal behavior)
                          // OR if I am the helper (so I can see my sent offer here)
                          final bool isRecipient = data['recipientUid'] == uid;
                          final bool isHelper = data['helperUid'] == uid;

                          if (isRecipient || isHelper) {
                            rows.add({
                              'id': d.id,
                              'isOffer': true,
                              'isSentOffer': isHelper,
                              'title': isHelper
                                  ? "You offered help to ${data['requestCategory'] ?? 'someone'}"
                                  : (data['helperName'] ?? "A helper").toString(),
                              'type': (data['requestCategory'] ?? 'Help offer').toString(),
                              'address': (data['requestLocationName'] ?? 'Nearby').toString(),
                              'time': data['createdAt'],
                            });
                          }
                        }
                      }

                      DateTime toDt(Object? raw) {
                        if (raw is Timestamp) return raw.toDate();
                        if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
                        return DateTime.fromMillisecondsSinceEpoch(0);
                      }

                      rows.sort((a, b) => toDt(b['time']).compareTo(toDt(a['time'])));

                      if (rows.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                          child: Center(
                            child: Text(
                              "No emergency alerts at the moment.",
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
                          final isOffer = row['isOffer'] == true;
                          final String docId = row['id'] as String;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(20),
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
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFFFFE3E3),
                                ),
                                child: Icon(
                                  isOffer
                                      ? Icons.check_circle_outline_rounded
                                      : Icons.warning_amber_rounded,
                                  color: isOffer
                                      ? const Color(0xFF1E9E5A)
                                      : const Color(0xFFB31217),
                                  size: 26,
                                ),
                              ),
                              title: Text(
                                row['title'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: textPrimary,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
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
                                  ],
                                ),
                              ),
                              trailing: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: softBg,
                                ),
                                child: Icon(
                                  isOffer ? Icons.notifications_active_rounded : Icons.map_outlined,
                                  color: isOffer
                                      ? const Color(0xFF1E9E5A)
                                      : const Color(0xFFB31217),
                                ),
                              ),
                              onTap: isOffer
                                  ? null
                                  : () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SOSTrackingMap(
                                            victimEmail: row['title'] as String,
                                            alertId: docId,
                                          ),
                                        ),
                                      );
                                    },
                            ),
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
