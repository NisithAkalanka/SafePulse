import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../theme/guardian_ui.dart';
import 'sos_all_reviews_screen.dart';
import 'sos_reviews_shared.dart';

/// Shown from profile — help request reviews and ratings summary.
/// Layout matches **Guardian Map** (gradient hero, frosted header card, chips).
class SosHitsRatingsScreen extends StatelessWidget {
  const SosHitsRatingsScreen({super.key});

  /// Muted caption — same tone as Guardian Map strips.
  static const Color _caption = Color(0xFF747A86);
  static const Color _chipBorder = Color(0xFFE8EAF0);
  static const Color _chipBg = Color(0xFFF9FAFC);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final topPad = MediaQuery.paddingOf(context).top + kToolbarHeight + 12;

    return Scaffold(
      backgroundColor: GuardianUi.surface,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Help request reviews and ratings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(18, topPad, 18, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFFF4B4B),
                  Color(0xFFB31217),
                  Color(0xFF1B1B1B),
                ],
                stops: [0.0, 0.62, 1.0],
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(34),
                bottomRight: Radius.circular(34),
              ),
            ),
            child: Column(
              children: [
                _guardianHeroHeaderCard(),
                const SizedBox(height: 12),
                _guardianHeroInfoStrip(),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection(kSosServiceReviewsCollection)
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Could not load reviews.\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: _caption, fontWeight: FontWeight.w600),
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting &&
                    !snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFFB31217)),
                  );
                }

                final docs = snapshot.data?.docs ?? [];
                final stats = computeSosReviewStats(docs);
                final ordered = sortSosReviewsMineFirst(docs, uid);
                final preview = ordered.take(5).toList();

                return SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _overallStarsBlock(stats.avgRating, stats.count),
                      const SizedBox(height: 18),
                      _satisfactionBlock(stats.satisfaction01, stats.count),
                      const SizedBox(height: 18),
                      _metricsGrid(),
                      const SizedBox(height: 18),
                      _shareExperienceButton(context),
                      const SizedBox(height: 26),
                      _topReviewsHeader(context),
                      const SizedBox(height: 14),
                      if (preview.isEmpty)
                        _emptyReviewsPlaceholder()
                      else
                        ...preview.map(
                          (d) => Padding(
                            padding: const EdgeInsets.only(bottom: 14),
                            child: SosReviewCard(
                              data: d.data(),
                              highlightMine:
                                  uid != null && d.data()['userId'] == uid,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _guardianHeroHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: const Icon(
              Icons.star_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Help request reviews and ratings',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Community star scores and reviews for help requests & support.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _guardianHeroInfoStrip() {
    return Row(
      children: [
        Expanded(
          child: _guardianMiniChip(Icons.star_half_rounded),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _guardianMiniChip(Icons.forum_outlined),
        ),
      ],
    );
  }

  /// Icon-only chips (no labels) — matches Guardian Map strip style.
  Widget _guardianMiniChip(IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Center(
        child: Icon(icon, size: 18, color: Colors.white),
      ),
    );
  }

  Widget _overallStarsBlock(double avgRating, int count) {
    final filled =
        count == 0 ? 0 : avgRating.round().clamp(0, 5);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: GuardianUi.cardShadow,
        border: Border.all(color: _chipBorder),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (i) {
              final isFilled = i < filled;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Icon(
                  isFilled ? Icons.star_rounded : Icons.star_border_rounded,
                  size: 36,
                  color: isFilled
                      ? GuardianUi.redAccent
                      : Colors.grey.shade400,
                ),
              );
            }),
          ),
          const SizedBox(height: 10),
          Text(
            count == 0
                ? 'No reviews yet'
                : 'Based on $count review${count == 1 ? '' : 's'}',
            style: const TextStyle(
              fontSize: 13,
              color: _caption,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _satisfactionBlock(double satisfaction01, int count) {
    final pct = count == 0 ? 0 : (satisfaction01 * 100).round();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: GuardianUi.cardShadow,
        border: Border.all(color: _chipBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Satisfaction Rate',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: GuardianUi.textPrimary,
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Icons.trending_up_rounded,
                    color: GuardianUi.redPrimary,
                    size: 22,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$pct%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: GuardianUi.redPrimary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: count == 0 ? 0 : satisfaction01,
              minHeight: 10,
              backgroundColor: _chipBg,
              valueColor: const AlwaysStoppedAnimation<Color>(GuardianUi.redPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyReviewsPlaceholder() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: GuardianUi.cardShadow,
        border: Border.all(color: _chipBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: GuardianUi.redTint,
            ),
            child: const Icon(
              Icons.rate_review_outlined,
              color: GuardianUi.redPrimary,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'Reviews from the community will appear here. Tap Share Your Experience to add yours.',
              style: TextStyle(
                fontSize: 14,
                height: 1.4,
                color: Colors.grey.shade800,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metricsGrid() {
    const metrics = [
      (
        icon: Icons.schedule_rounded,
        color: Color(0xFF2196F3),
        label: 'Response',
      ),
      (
        icon: Icons.person_rounded,
        color: Color(0xFF43A047),
        label: 'Professional',
      ),
      (
        icon: Icons.verified_user_rounded,
        color: Color(0xFFE53935),
        label: 'Effective',
      ),
      (
        icon: Icons.chat_bubble_outline_rounded,
        color: Color(0xFFFF9800),
        label: 'Communication',
      ),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.35,
      children: metrics.map((m) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _chipBg,
            borderRadius: BorderRadius.circular(18),
            boxShadow: GuardianUi.cardShadow,
            border: Border.all(color: _chipBorder),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: m.color,
                ),
                child: Icon(m.icon, color: Colors.white, size: 22),
              ),
              const SizedBox(height: 12),
              Text(
                m.label,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: _caption,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _shareExperienceButton(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => ShareExperienceReviewSheet.show(context),
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          decoration: BoxDecoration(
            gradient: GuardianUi.ctaGradient,
            borderRadius: BorderRadius.circular(18),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: const SizedBox(
            width: double.infinity,
            height: 52,
            child: Center(
              child: Text(
                'Share Your Experience',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 15,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _topReviewsHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Top Reviews',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: GuardianUi.textPrimary,
          ),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).push<void>(
              MaterialPageRoute<void>(
                builder: (_) => const SosAllReviewsScreen(),
              ),
            );
          },
          child: const Text(
            'See All',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              color: GuardianUi.redPrimary,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

}

/// Bottom sheet: rate SOS service & write a review; saves to Firestore.
class ShareExperienceReviewSheet extends StatefulWidget {
  const ShareExperienceReviewSheet({super.key, required this.hostContext});

  /// Screen under the sheet — used for SnackBars after the sheet closes.
  final BuildContext hostContext;

  /// [context] must be from the screen under the sheet (for SnackBars after submit).
  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareExperienceReviewSheet(hostContext: context),
    );
  }

  @override
  State<ShareExperienceReviewSheet> createState() =>
      _ShareExperienceReviewSheetState();
}

class _ShareExperienceReviewSheetState extends State<ShareExperienceReviewSheet> {
  static const Color _accent = GuardianUi.redPrimary;
  /// Short reviews allowed; still blocks empty / single letter spam.
  static const int _minReviewChars = 5;

  int _rating = 0;
  final TextEditingController _textController = TextEditingController();
  bool _submitting = false;
  bool _ratingError = false;
  bool _textError = false;
  String? _authError;
  String? _firestoreError;

  @override
  void initState() {
    super.initState();
    _textController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    if (!_textError) return;
    if (_textController.text.trim().length >= _minReviewChars) {
      setState(() => _textError = false);
    }
  }

  @override
  void dispose() {
    _textController.removeListener(_onTextChanged);
    _textController.dispose();
    super.dispose();
  }

  Future<String?> _resolveDisplayName(User user) async {
    final dn = user.displayName?.trim();
    if (dn != null && dn.isNotEmpty) return dn;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        final d = doc.data();
        final fname = (d?['first_name'] as String?)?.trim() ?? '';
        final lname = (d?['last_name'] as String?)?.trim() ?? '';
        if (fname.isNotEmpty || lname.isNotEmpty) {
          return '$fname $lname'.trim();
        }
      }
    } catch (_) {}
    final email = user.email;
    if (email != null && email.contains('@')) {
      return email.split('@').first;
    }
    return 'SafePulse Member';
  }

  Future<void> _submit() async {
    setState(() {
      _authError = null;
      _firestoreError = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        _authError = 'Please sign in to share your experience.';
      });
      _toastHost(const SnackBar(
        content: Text('Please sign in to share your experience.'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }

    final text = _textController.text.trim();
    final ratingOk = _rating >= 1;
    final textOk = text.length >= _minReviewChars;

    if (!ratingOk || !textOk) {
      setState(() {
        _ratingError = !ratingOk;
        _textError = !textOk;
      });
      return;
    }

    setState(() {
      _ratingError = false;
      _textError = false;
      _submitting = true;
    });

    try {
      final name = await _resolveDisplayName(user);
      await FirebaseFirestore.instance.collection(kSosServiceReviewsCollection).add({
        'userId': user.uid,
        'displayName': name,
        'rating': _rating,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.of(context).pop();
      _toastHost(const SnackBar(
        content: Text('Thank you! Your review was submitted.'),
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (!mounted) return;
      final msg = _friendlyFirestoreMessage(e);
      setState(() {
        _firestoreError = msg;
        _submitting = false;
      });
      _toastHost(SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 5),
      ));
    }
  }

  void _toastHost(SnackBar snackBar) {
    final host = widget.hostContext;
    if (!host.mounted) return;
    ScaffoldMessenger.of(host).clearSnackBars();
    ScaffoldMessenger.of(host).showSnackBar(snackBar);
  }

  String _friendlyFirestoreMessage(Object e) {
    final s = e.toString();
    if (s.contains('permission-denied') || s.contains('PERMISSION_DENIED')) {
      return 'Could not save (permission denied). Ask the admin to allow writes to sos_service_reviews in Firestore rules.';
    }
    if (s.contains('failed-precondition') || s.contains('index')) {
      return 'Firestore needs an index for this query. Check the console link in the error log.';
    }
    return 'Could not submit. Check your connection and try again.';
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final radius = const Radius.circular(22);

    return Padding(
      padding: EdgeInsets.only(bottom: bottomInset),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(topLeft: radius, topRight: radius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const Text(
                'Share Your Experience',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: GuardianUi.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'How was the SOS response and support?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 22),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (index) {
                  final filled = index < _rating;
                  return IconButton(
                    onPressed: () => setState(() {
                      _rating = index + 1;
                      _ratingError = false;
                    }),
                    icon: Icon(
                      filled ? Icons.star_rounded : Icons.star_border_rounded,
                      color: filled
                          ? _accent
                          : (_ratingError ? _accent.withValues(alpha: 0.45) : Colors.grey.shade400),
                      size: 44,
                    ),
                  );
                }),
              ),
              if (_ratingError)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'Tap the stars to choose a rating (1–5).',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _accent,
                    ),
                  ),
                ),
              if (_rating > 0 && !_ratingError)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    '$_rating of 5 stars',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ),
              if (_authError != null) ...[
                const SizedBox(height: 4),
                Text(
                  _authError!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: _accent,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              TextField(
                controller: _textController,
                maxLines: 5,
                maxLength: 800,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText:
                      'Tell others about response time, professionalism, or anything that helped…',
                  filled: true,
                  fillColor: GuardianUi.surface,
                  counterStyle: TextStyle(color: Colors.grey.shade600),
                  errorText: _textError
                      ? 'Enter at least $_minReviewChars characters.'
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: GuardianUi.divider.withValues(alpha: 0.8),
                    ),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(
                      color: _textError ? _accent : GuardianUi.divider.withValues(alpha: 0.8),
                      width: _textError ? 1.5 : 1,
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(
                      color: _accent,
                      width: 1.5,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _accent, width: 1.5),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: const BorderSide(color: _accent, width: 1.5),
                  ),
                ),
              ),
              if (_firestoreError != null) ...[
                const SizedBox(height: 10),
                Text(
                  _firestoreError!,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: Colors.red.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                height: 52,
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: _submitting ? null : _submit,
                    borderRadius: BorderRadius.circular(16),
                    child: Ink(
                      decoration: BoxDecoration(
                        gradient: _submitting ? null : GuardianUi.ctaGradient,
                        color: _submitting ? Colors.grey.shade400 : null,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: _submitting
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Submit review',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: _submitting ? null : () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
