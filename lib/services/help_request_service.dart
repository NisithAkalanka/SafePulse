import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../help/help_request.dart';
import '../help/help_requests_store.dart';

/// Backend service for help requests: Firestore persistence and real-time sync.
class HelpRequestService {
  HelpRequestService._();
  static final HelpRequestService instance = HelpRequestService._();

  static const String _collection = 'help_requests';
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  Timer? _cacheRefreshDebounce;

  void _applySnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    final currentUid = _auth.currentUser?.uid;
    final requests = snapshot.docs.map((doc) {
      return HelpRequest.fromMap(doc.id, doc.data(), currentUid);
    }).toList();
    HelpRequestsStore.instance.setFromFirestore(requests);
  }

  /// If the stream emitted **cached** data first, briefly re-fetch from server so
  /// new posts show without waiting for the next network push.
  void _scheduleServerRefreshIfStale(QuerySnapshot<Map<String, dynamic>> snap) {
    if (!snap.metadata.isFromCache) {
      return;
    }
    _cacheRefreshDebounce?.cancel();
    _cacheRefreshDebounce = Timer(const Duration(milliseconds: 450), () {
      refreshOnce();
    });
  }

  void _onSnapshot(QuerySnapshot<Map<String, dynamic>> snap) {
    _applySnapshot(snap);
    _scheduleServerRefreshIfStale(snap);
  }

  /// Real-time sync. Safe to call many times — only one listener is kept.
  void startListening() {
    if (_subscription != null) {
      return;
    }
    _subscription = _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen(
      _onSnapshot,
      onError: (Object e, StackTrace st) {
        debugPrint('HelpRequestService: Firestore listen error: $e');
        debugPrint('$st');
      },
      cancelOnError: false,
    );
  }

  /// One-shot fetch from **server** (skips local persistence cache).
  Future<void> refreshOnce() async {
    try {
      final snap = await _firestore
          .collection(_collection)
          .orderBy('createdAt', descending: true)
          .get(const GetOptions(source: Source.server));
      _applySnapshot(snap);
    } catch (e, st) {
      debugPrint('HelpRequestService.refreshOnce: $e');
      debugPrint('$st');
    }
  }

  void stopListening() {
    _cacheRefreshDebounce?.cancel();
    _cacheRefreshDebounce = null;
    _subscription?.cancel();
    _subscription = null;
  }

  /// Save a new help request to Firestore.
  Future<String?> addRequest(HelpRequest request) async {
    try {
      final ref = await _firestore.collection(_collection).add(request.toMap());
      return ref.id;
    } catch (e, st) {
      debugPrint('HelpRequestService.addRequest failed: $e');
      debugPrint('$st');
      return null;
    }
  }

  /// Update an existing document (same [id] as Firestore doc id).
  Future<bool> updateRequest(String id, HelpRequest request) async {
    try {
      await _firestore.collection(_collection).doc(id).update(request.toMap());
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<bool> deleteRequest(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
      return true;
    } catch (e) {
      return false;
    }
  }
}
