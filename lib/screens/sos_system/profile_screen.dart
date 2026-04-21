import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile_screen.dart';
import 'sos_hits_ratings_screen.dart';
import '../../main.dart';
import '../../services/help_role_mode_service.dart';
import 'admin_dashboard.dart'; // Admin Dashboard එක සඳහා මෙය අනිවාර්යයෙන්ම තිබිය යුතුයි

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;

  String studentEmail = "Not Logged In";
  String studentName = "SafePulse Member";
  String sliitId = "---";
  String userRole = "student";
  String? _profilePhotoBase64;
  String degree = "N/A";
  String batch = "N/A";

  double completionPercentage = 0.0;
  bool isSetupComplete = false;

  double _lfRatingAvg = 0.0;
  int _lfRatingCount = 0;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSub;

  @override
  void initState() {
    super.initState();
    HelpRoleModeService.instance.load();
    if (user != null) {
      studentEmail = user?.email ?? "Guest";
      _loadUserData();
      _calculateCompletion();
      _listenToLostFoundRating();
    }
  }

  @override
  void dispose() {
    _userDocSub?.cancel();
    super.dispose();
  }

  Future<void> _loadUserData() async {
    if (user != null) {
      try {
        var ds = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();

        if (ds.exists) {
          final data = ds.data() ?? {};

          setState(() {
            String fname = data['first_name'] ?? "";
            String lname = data['last_name'] ?? "";
            sliitId = data['sliit_id'] ?? "No ID Found";
            studentName = (fname.isEmpty && lname.isEmpty)
                ? sliitId
                : "$fname $lname";

            studentEmail = data['student_email'] ?? user?.email ?? "";
            degree = data['degree'] ?? "N/A";
            batch = data['join_year'] ?? "N/A";
            userRole = data['role'] ?? "student";
            _profilePhotoBase64 = data['profile_photo_base64'];

            _lfRatingAvg = _safeDouble(data['lf_rating_avg']);
            _lfRatingCount = _safeInt(data['lf_rating_count']);

            _calculateCompletion();
          });
        }
      } catch (e) {
        debugPrint("Error loading profile: $e");
      }
    }
  }

  void _listenToLostFoundRating() {
    if (user == null) return;

    _userDocSub?.cancel();
    _userDocSub = FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .snapshots()
        .listen((doc) {
          if (!doc.exists) return;
          final data = doc.data() ?? {};
          if (!mounted) return;

          setState(() {
            _lfRatingAvg = _safeDouble(data['lf_rating_avg']);
            _lfRatingCount = _safeInt(data['lf_rating_count']);
          });
        });
  }

  int _safeInt(dynamic value) {
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  double _safeDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  String _lfBadgeLabel(double avg, int count) {
    if (count == 0) return 'Bronze';
    if (avg >= 4.5) return 'Gold';
    if (avg >= 3.0) return 'Silver';
    return 'Bronze';
  }

  Color _lfBadgeColor(String label) {
    switch (label) {
      case 'Gold':
        return const Color(0xFFFFD700);
      case 'Silver':
        return const Color(0xFFB0BEC5);
      case 'Bronze':
        return const Color(0xFFCD7F32);
      default:
        return const Color(0xFFB0BEC5);
    }
  }

  String _lfRatingDisplay() {
    if (_lfRatingCount <= 0) return '0.0★';
    return '${_lfRatingAvg.toStringAsFixed(1)}★';
  }

  String _lfRatingSubtitle() {
    final badge = _lfBadgeLabel(_lfRatingAvg, _lfRatingCount);
    if (_lfRatingCount <= 0) {
      return 'Lost & Found\n$badge badge';
    }
    return 'Lost & Found\n$badge • $_lfRatingCount rating${_lfRatingCount == 1 ? '' : 's'}';
  }

  Future<void> _calculateCompletion() async {
    if (user == null) return;

    var doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    if (doc.exists) {
      var data = doc.data()!;
      int filledFields = 0;

      List<String> requiredFields = [
        'first_name',
        'last_name',
        'sliit_id',
        'phone',
        'degree',
        'join_year',
        'blood_type',
        'allergies',
        'ice_name',
        'ice_phone',
      ];

      for (var field in requiredFields) {
        if (data[field] != null && data[field].toString().trim().isNotEmpty) {
          filledFields++;
        }
      }

      if (!mounted) return;

      setState(() {
        completionPercentage = filledFields / 10.0;
        isSetupComplete = completionPercentage == 1.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color pageBg = isDark
        ? const Color(0xFF121217)
        : const Color(0xFFF6F7FB);
    final Color cardBg = isDark
        ? const Color(0xFF1B1B22)
        : Colors.white;
    final Color textPrimary = isDark ? Colors.white : const Color(0xFF1B1B22);
    final Color textSecondary = isDark
        ? const Color(0xFFB7BBC6)
        : const Color(0xFF747A86);
    final Color appBarFg = Colors.white;

    final String lfBadge = _lfBadgeLabel(_lfRatingAvg, _lfRatingCount);
    final Color lfBadgeColor = _lfBadgeColor(lfBadge);

    return Scaffold(
      backgroundColor: pageBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Profile",
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.2),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: appBarFg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          Container(
            height: 300,
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
                    : const [0.0, 0.6, 1.0],
              ),
            ),
          ),
          Positioned(
            top: -90,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(isDark ? 0.06 : 0.08),
              ),
            ),
          ),
          Positioned(
            top: 110,
            left: -60,
            child: Container(
              width: 170,
              height: 170,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (isDark ? Colors.black : Colors.black).withOpacity(
                  isDark ? 0.14 : 0.06,
                ),
              ),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 118),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: pageBg,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(34),
                      topRight: Radius.circular(34),
                    ),
                  ),
                  child: RefreshIndicator(
                    onRefresh: () async {
                      await _loadUserData();
                      await _calculateCompletion();
                    },
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 34),
                      child: Column(
                        children: [
                          if (!isSetupComplete)
                            _buildProgressBarUI()
                          else
                            _buildCompletionSuccessMsg(),
                          const SizedBox(height: 14),
                          Container(
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFFFF4B4B), Color(0xFFB31217)],
                              ),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x22000000),
                                  blurRadius: 18,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.22),
                                  ),
                                  child: CircleAvatar(
                                    radius: 38,
                                    backgroundColor: const Color(0xFF24131A),
                                    backgroundImage: _profilePhotoBase64 != null
                                        ? MemoryImage(
                                            base64Decode(_profilePhotoBase64!),
                                          )
                                        : null,
                                    child: _profilePhotoBase64 == null
                                        ? const Icon(
                                            Icons.person,
                                            color: Colors.white,
                                            size: 42,
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        studentName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        studentEmail,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 8,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 7,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.12,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(
                                                  0.16,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              "ID: $sliitId",
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 7,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.white.withOpacity(
                                                0.12,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(999),
                                              border: Border.all(
                                                color: Colors.white.withOpacity(
                                                  0.16,
                                                ),
                                              ),
                                            ),
                                            child: Text(
                                              userRole.toUpperCase(),
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 0.6,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _statItem(
                                  "",
                                  "Request help reviews",
                                  const Color(0xFFFF5A5F),
                                  onTap: () {
                                    Navigator.of(context).push<void>(
                                      MaterialPageRoute<void>(
                                        builder: (_) =>
                                            const SosHitsRatingsScreen(),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _ratingStatItem(
                                  value: _lfRatingDisplay(),
                                  label: "Lost & Found",
                                  badge: lfBadge,
                                  badgeColor: lfBadgeColor,
                                  subtitle: _lfRatingCount <= 0
                                      ? "No ratings yet"
                                      : "$_lfRatingCount rating${_lfRatingCount == 1 ? '' : 's'}",
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _statItem(
                                  "Main",
                                  "Group",
                                  const Color(0xFF31B7FF),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: cardBg,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x10000000),
                                  blurRadius: 14,
                                  offset: Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Personal Details",
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w900,
                                    color: textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Keep your identity and campus information up to date.",
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    color: textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _infoMiniCard(
                                        "Degree",
                                        degree,
                                        Icons.school_outlined,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: _infoMiniCard(
                                        "Batch",
                                        batch,
                                        Icons.groups_outlined,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                _profileMenuItem(
                                  Icons.edit_outlined,
                                  "Edit Profile Details",
                                  "Years, degree, phone & photo",
                                  () async {
                                    bool? updated = await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            const EditProfileScreen(),
                                      ),
                                    );
                                    if (updated == true) _loadUserData();
                                  },
                                ),
                                if (userRole == "admin")
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: _profileMenuItem(
                                      Icons.admin_panel_settings,
                                      "Security Admin Dashboard",
                                      "Manage all university SOS alerts",
                                      () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const AdminDashboard(),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 6),
                          _buildHelpRoleModeCard(),
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    Color(0xFFFF4B4B),
                                    Color(0xFFB31217),
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.18),
                                    blurRadius: 16,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () async {
                                  await FirebaseAuth.instance.signOut();
                                  if (!mounted) return;
                                  Navigator.of(context).pushAndRemoveUntil(
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const SafePulseApp(),
                                    ),
                                    (route) => false,
                                  );
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  minimumSize: const Size(double.infinity, 58),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.logout_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    SizedBox(width: 10),
                                    Text(
                                      "Log Out",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHelpRoleModeCard() {
    const red = Color(0xFFB31217);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBg = isDark ? const Color(0xFF1B1B22) : Colors.white;
    final Color textPrimary = isDark ? Colors.white : const Color(0xFF1B1B22);
    final Color textSecondary = isDark
        ? const Color(0xFFB7BBC6)
        : const Color(0xFF747A86);

    return ValueListenableBuilder<bool>(
      valueListenable: HelpRoleModeService.instance.isHelperMode,
      builder: (context, isHelper, _) {
        final title = isHelper ? 'Helper mode' : 'Requester mode';
        final body = isHelper
            ? 'You’re browsing as a helper. Offer help on the Help feed.'
            : 'You’re browsing as a requester. Post help requests when you need support.';
        final switchLabel = isHelper
            ? 'Switch to Requester mode'
            : 'Switch to Helper mode';

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: const Color(0xFFFFE0E0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 14,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFE8E8),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      isHelper ? Icons.volunteer_activism : Icons.person_pin,
                      color: red,
                      size: 26,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          body,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: textSecondary,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await HelpRoleModeService.instance.toggle();
                    if (!context.mounted) return;
                    final nowHelper =
                        HelpRoleModeService.instance.isHelperMode.value;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          nowHelper
                              ? 'Switched to Helper mode'
                              : 'Switched to Requester mode',
                        ),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: red,
                    side: const BorderSide(color: Color(0xFFE8B4B4)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 22),
                  label: Text(
                    switchLabel,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProgressBarUI() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1B22) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Complete Your Safety Profile",
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF1B1B22),
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                ),
              ),
              Text(
                "${(completionPercentage * 100).toInt()}%",
                style: const TextStyle(
                  color: Color(0xFFFF5A5F),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: completionPercentage,
              minHeight: 8,
              backgroundColor: isDark
                  ? const Color(0xFF2A2A33)
                  : const Color(0xFFE9ECF1),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF64F0C8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletionSuccessMsg() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2B24) : const Color(0xFFEAFBF4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF335B47) : const Color(0xFFBDEFD7),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_user, color: Color(0xFF21A366)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              "Your Safety Profile is fully connected! ✅",
              style: TextStyle(
                color: isDark ? Colors.white : const Color(0xFF1B1B22),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statItem(
    String value,
    String label,
    Color color, {
    VoidCallback? onTap,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    final inner = Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1B22) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          if (value.trim().isNotEmpty)
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          if (value.trim().isNotEmpty) const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFFB7BBC6) : const Color(0xFF747A86),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (onTap == null) {
      return inner;
    }

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: inner,
      ),
    );
  }

  Widget _ratingStatItem({
    required String value,
    required String label,
    required String badge,
    required Color badgeColor,
    required String subtitle,
  }) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1B22) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: badgeColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFFB7BBC6) : const Color(0xFF747A86),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 7),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: badgeColor.withOpacity(0.14),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: badgeColor.withOpacity(0.40)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.workspace_premium_rounded,
                  size: 14,
                  color: badgeColor,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    badge,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: badgeColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              color: isDark ? const Color(0xFFB7BBC6) : const Color(0xFF747A86),
              fontWeight: FontWeight.w600,
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoMiniCard(String title, String value, IconData icon) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF23232B) : const Color(0xFFF9FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF34343F) : const Color(0xFFE8EAF0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFE3E3),
            ),
            child: Icon(icon, color: const Color(0xFFB31217), size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? const Color(0xFFB7BBC6) : const Color(0xFF747A86),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value.isEmpty ? "N/A" : value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : const Color(0xFF1B1B22),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileMenuItem(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1B22) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFF5A63), Color(0xFFB31217)],
                    ),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1B1B22),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark
                              ? const Color(0xFFB7BBC6)
                              : const Color(0xFF747A86),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? const Color(0xFF23232B)
                        : const Color(0xFFF4F5F7),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF34343F)
                          : const Color(0xFFE8EAF0),
                    ),
                  ),
                  child: Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: isDark ? Colors.white : const Color(0xFF1B1B22),
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
