import 'package:cloud_firestore/cloud_firestore.dart';

class LostFoundRatingService {
  static const String _ratingsCol = 'lost_found_ratings';
  static const String _usersCol = 'users';

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Submit a rating from [raterId] to [ratedUserId] for [itemId].
  /// [stars] must be 1–5.
  Future<void> submitRating({
    required String itemId,
    required String raterId,
    required String raterName,
    required String ratedUserId,
    required int stars,
  }) async {
    if (stars < 1 || stars > 5) return;
    if (raterId.trim().isEmpty || ratedUserId.trim().isEmpty) return;

    // Prevent duplicate ratings for the same item by the same rater
    final existing = await _db
        .collection(_ratingsCol)
        .where('itemId', isEqualTo: itemId)
        .where('raterId', isEqualTo: raterId)
        .limit(1)
        .get();

    if (existing.docs.isNotEmpty) return; // already rated

    await _db.collection(_ratingsCol).add({
      'itemId': itemId,
      'raterId': raterId,
      'raterName': raterName,
      'ratedUserId': ratedUserId,
      'stars': stars,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Recompute aggregate on the rated user doc
    await _recomputeUserRating(ratedUserId);
  }

  Future<void> _recomputeUserRating(String userId) async {
    final snap = await _db
        .collection(_ratingsCol)
        .where('ratedUserId', isEqualTo: userId)
        .get();

    if (snap.docs.isEmpty) return;

    int total = 0;
    for (final doc in snap.docs) {
      total += (doc.data()['stars'] as int? ?? 0);
    }

    final double avg = total / snap.docs.length;

    await _db.collection(_usersCol).doc(userId).set({
      'lf_rating_avg': avg,
      'lf_rating_count': snap.docs.length,
    }, SetOptions(merge: true));
  }

  /// Returns true if [raterId] has already rated [itemId].
  Future<bool> hasRated({
    required String itemId,
    required String raterId,
  }) async {
    final snap = await _db
        .collection(_ratingsCol)
        .where('itemId', isEqualTo: itemId)
        .where('raterId', isEqualTo: raterId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Stream of aggregated rating data for a user.
  Stream<Map<String, dynamic>> userRatingStream(String userId) {
    return _db
        .collection(_usersCol)
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data() ?? {});
  }

  /// Badge label based on average stars.
  static String badgeLabel(double avg, int count) {
    if (count == 0) return '';
    if (avg >= 4.5) return 'Gold';
    if (avg >= 3.0) return 'Silver';
    return 'Bronze';
  }

  /// Badge colour based on label.
  static int badgeColor(String label) {
    switch (label) {
      case 'Gold':
        return 0xFFFFD700;
      case 'Silver':
        return 0xFFB0BEC5;
      case 'Bronze':
        return 0xFFCD7F32;
      default:
        return 0xFFB0BEC5;
    }
  }
}
