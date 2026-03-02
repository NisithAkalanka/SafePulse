import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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

  /// Start listening to help_requests; updates HelpRequestsStore on changes.
  void startListening() {
    _subscription?.cancel();
    _subscription = _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .listen((snapshot) {
      final currentUid = _auth.currentUser?.uid;
      final requests = snapshot.docs.map((doc) {
        return HelpRequest.fromMap(doc.id, doc.data(), currentUid);
      }).toList();
      HelpRequestsStore.instance.setFromFirestore(requests);
    });
  }

  void stopListening() {
    _subscription?.cancel();
    _subscription = null;
  }

  /// Save a new help request to Firestore.
  Future<String?> addRequest(HelpRequest request) async {
    try {
      final ref = await _firestore.collection(_collection).add(request.toMap());
      return ref.id;
    } catch (e) {
      return null;
    }
  }
}
