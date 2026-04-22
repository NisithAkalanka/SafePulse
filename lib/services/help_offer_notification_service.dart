import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../help/help_request.dart';
import 'notification_service.dart';

/// Persists help-offer events and shows local requester notifications in realtime.
class HelpOfferNotificationService {
  HelpOfferNotificationService._();
  static final HelpOfferNotificationService instance =
      HelpOfferNotificationService._();

  static const String _collection = 'help_offer_notifications';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _incomingSub;
  final Set<String> _processedIds = <String>{};
  bool _hasPrimedInitialSnapshot = false;

  /// Starts auth-aware listener once.
  void start() {
    _authSub ??= _auth.authStateChanges().listen(_handleAuthChanged);
    _handleAuthChanged(_auth.currentUser);
  }

  void _handleAuthChanged(User? user) {
    _incomingSub?.cancel();
    _incomingSub = null;
    _processedIds.clear();
    _hasPrimedInitialSnapshot = false;
    if (user == null) {
      return;
    }

    _incomingSub = _firestore
        .collection(_collection)
        .where('recipientUid', isEqualTo: user.uid)
        .snapshots()
        .listen(
      _onIncomingSnapshot,
      onError: (Object e, StackTrace st) {
        debugPrint('HelpOfferNotificationService.listen error: $e');
        debugPrint('$st');
      },
    );
  }

  Future<void> _onIncomingSnapshot(
    QuerySnapshot<Map<String, dynamic>> snapshot,
  ) async {
    if (!_hasPrimedInitialSnapshot) {
      _hasPrimedInitialSnapshot = true;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        _processedIds.add(doc.id);

        if (data['delivered'] == true) {
          continue;
        }

        unawaited(
          doc.reference.update(<String, dynamic>{
            'delivered': true,
            'deliveredAt': FieldValue.serverTimestamp(),
          }),
        );
      }
      return;
    }

    for (final change in snapshot.docChanges) {
      if (change.type != DocumentChangeType.added) {
        continue;
      }

      final doc = change.doc;
      if (_processedIds.contains(doc.id)) {
        continue;
      }
      final data = doc.data();
      if (data == null) {
        _processedIds.add(doc.id);
        continue;
      }
      if (data['delivered'] == true) {
        _processedIds.add(doc.id);
        continue;
      }

      final helperName = (data['helperName'] as String?)?.trim();
      final category = (data['requestCategory'] as String?)?.trim();
      final title = (data['requestTitle'] as String?)?.trim();
      final notifId = DateTime.now().millisecondsSinceEpoch % 2147483647;

      await NotificationService.showHelpOfferNotification(
        id: notifId,
        helperName: helperName?.isNotEmpty == true ? helperName! : 'A helper',
        category: category?.isNotEmpty == true ? category! : 'your request',
        title: title?.isNotEmpty == true ? title! : 'Help request',
      );

      _processedIds.add(doc.id);
      unawaited(
        doc.reference.update(<String, dynamic>{
          'delivered': true,
          'deliveredAt': FieldValue.serverTimestamp(),
        }),
      );
    }
  }

  /// Called when helper taps OFFER HELP.
  Future<bool> notifyRequesterAboutOffer(HelpRequest request) async {
    final helper = _auth.currentUser;
    final requesterUid = request.creatorUid;
    debugPrint('SafePulse: Offering help for Request[${request.id}] from Creator[$requesterUid]');

    if (helper == null) {
      debugPrint('SafePulse: Offer failed - No helper logged in');
      return false;
    }
    if (requesterUid.isEmpty) {
      debugPrint('SafePulse: Offer failed - request.creatorUid is empty');
      return false;
    }
    if (helper.uid == requesterUid) {
      debugPrint('SafePulse: Offer failed - cannot help yourself');
      return false;
    }

    try {
      final helperName = _bestEffortHelperName(helper);
      final helperBadge = await _resolveHelperBadge(helper.uid);
      debugPrint('SafePulse: Sending help_offer from ${helper.uid} to $requesterUid');

      // 1. Create the offer notification record
      await _firestore.collection(_collection).add(<String, dynamic>{
        'type': 'help_offer',
        'recipientUid': requesterUid,
        'helperUid': helper.uid,
        'helperName': helperName,
        'helperBadge': helperBadge,
        'requestId': request.id,
        'requestCategory': request.category,
        'requestTitle': request.title,
        'requestLocationName': request.locationName,
        'createdAt': FieldValue.serverTimestamp(),
        'delivered': false,
        'read': false,
        'accepted': false,
      });

      // 2. Mark the original request as having an active offer (updates local & remote state)
      try {
        await _firestore.collection('help_requests').doc(request.id).update({
          'hasActiveOffer': true,
          'helperUid': helper.uid,
          'helperName': helperName,
        });
      } catch (e) {
        debugPrint('SafePulse: Failed to update request status (non-blocking): $e');
      }

      // 3. Best-effort mirror to `alerts` (do not fail the core notification write).
      try {
        String requesterEmail = 'Unknown User';
        final requesterDoc =
            await _firestore.collection('users').doc(requesterUid).get();
        final data = requesterDoc.data();
        final e1 = data?['student_email']?.toString().trim();
        final e2 = data?['email']?.toString().trim();
        requesterEmail = (e1 != null && e1.isNotEmpty)
            ? e1
            : ((e2 != null && e2.isNotEmpty) ? e2 : requesterEmail);

        await _firestore.collection('alerts').add(<String, dynamic>{
          'type': request.category,
          'user_email': requesterEmail,
          'uid': requesterUid,
          'lat': request.lat,
          'lng': request.lng,
          'address': request.locationName,
          'time': FieldValue.serverTimestamp(),
          'status': 'HelpOffer',
          'helper_uid': helper.uid,
          'helper_name': helperName,
          'acceptedBy': helperName,
          'requestId': request.id,
          'requestTitle': request.title,
          'source': 'help_offer',
        });
      } catch (e) {
        debugPrint('alerts mirror failed (non-blocking): $e');
      }
      return true;
    } catch (e, st) {
      debugPrint('notifyRequesterAboutOffer failed: $e');
      debugPrint('$st');
      return false;
    }
  }

  String _bestEffortHelperName(User helper) {
    final display = helper.displayName?.trim();
    if (display != null && display.isNotEmpty) {
      return display;
    }
    final email = helper.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email;
    }
    return 'A helper';
  }

  Future<String> _resolveHelperBadge(String helperUid) async {
    try {
      final doc = await _firestore.collection('users').doc(helperUid).get();
      final data = doc.data();
      if (data == null) return 'Bronze';

      final rawBadge = data['helper_badge']?.toString().trim();
      if (rawBadge != null && rawBadge.isNotEmpty) {
        return _normalizeBadge(rawBadge);
      }

      final avg = (data['helper_rating_avg'] as num?)?.toDouble() ?? 0.0;
      final count = (data['helper_rating_count'] as num?)?.toInt() ?? 0;
      return _badgeFromRating(avg, count);
    } catch (e) {
      debugPrint('SafePulse: Could not resolve helper badge: $e');
      return 'Bronze';
    }
  }

  String _badgeFromRating(double avg, int count) {
    if (avg >= 4.5 && count >= 15) return 'Gold';
    if (avg >= 4.0 && count >= 8) return 'Silver';
    return 'Bronze';
  }

  String _normalizeBadge(String badge) {
    switch (badge.toLowerCase()) {
      case 'gold':
        return 'Gold';
      case 'silver':
        return 'Silver';
      default:
        return 'Bronze';
    }
  }
}
