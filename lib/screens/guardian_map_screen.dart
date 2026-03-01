import 'dart:convert';
import 'dart:ui';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:url_launcher/url_launcher.dart';

class GuardianMapScreen extends StatefulWidget {
  const GuardianMapScreen({super.key});
  @override
  State<GuardianMapScreen> createState() => _GuardianMapScreenState();
}

class _GuardianMapScreenState extends State<GuardianMapScreen> {
  // තෝරාගත් යාළුවාගේ තොරතුරු තාවකාලිකව රඳවා ගැනීමට
  Map<String, dynamic>? _selectedFriend;
  bool _isFullMap = false; // Full map view toggle
  final TransformationController _mapTransform = TransformationController();
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        final currentUser = authSnapshot.data;

        if (currentUser == null) return _blockedUI();

        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(currentUser.uid)
              .snapshots(),
          builder: (context, userDocSnapshot) {
            if (!userDocSnapshot.hasData || !userDocSnapshot.data!.exists) {
              return const Scaffold(
                backgroundColor: Color(0xFF0F0F13),
                body: Center(child: CircularProgressIndicator()),
              );
            }

            var userData =
                userDocSnapshot.data!.data() as Map<String, dynamic>?;
            String role = userData?['role'] ?? "student";
            List guardians = userData?['guardians'] ?? [];

            return Scaffold(
              backgroundColor: const Color(0xFF0F0F13),
              extendBodyBehindAppBar: true,
              appBar: AppBar(
                title: Text(
                  role == "admin" ? "🛡️ Global Tracking" : "Circle Map",
                ),
                centerTitle: true,
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.white,
                elevation: 0,
                actions: [
                  IconButton(
                    tooltip: _isFullMap ? "Exit full view" : "Full view",
                    icon: Icon(
                      _isFullMap ? Icons.fullscreen_exit : Icons.fullscreen,
                      color: Colors.white,
                    ),
                    onPressed: () {
                      setState(() {
                        _isFullMap = !_isFullMap;
                        // when entering full view, close popup for cleaner map
                        if (_isFullMap) {
                          _selectedFriend = null;
                          _resetZoom();
                        }
                      });
                    },
                  ),
                  const SizedBox(width: 6),
                ],
              ),
              body: _bgDecor(
                child: role == "admin"
                    ? _buildAdminStream()
                    : _buildStudentStream(guardians),
              ),
            );
          },
        );
      },
    );
  }

  // --- දත්ත ලබා ගන්නා Streams ---
  Widget _buildAdminStream() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('users').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        return _buildMainMapUI(snapshot.data!.docs);
      },
    );
  }

  Widget _buildStudentStream(List guardians) {
    if (guardians.isEmpty) return _emptyState("No Connections Added.");
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('student_email', whereIn: guardians)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return const Center(child: CircularProgressIndicator());
        return _buildMainMapUI(snapshot.data!.docs);
      },
    );
  }

  // --- සජීවී සිතියම් Layout එක (Map + Overlays) ---
  Widget _buildMainMapUI(List<QueryDocumentSnapshot> docs) {
    // visible count (only those with coords)
    int visibleCount = 0;
    for (final d in docs) {
      final data = d.data() as Map<String, dynamic>;
      final lat = _toDouble(data['last_lat']);
      final lng = _toDouble(data['last_lng']);
      if (lat != null && lng != null) visibleCount++;
    }

    return Stack(
      children: [
        // tap outside to close popup (only when popup can appear)
        if (!_isFullMap)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTap: () {
                if (_selectedFriend != null) {
                  setState(() => _selectedFriend = null);
                }
              },
              child: const SizedBox.expand(),
            ),
          ),

        // 1. Main map (Campus Image)
        Positioned.fill(
          child: Container(
            margin: _isFullMap
                ? EdgeInsets.zero
                : const EdgeInsets.fromLTRB(10, 80, 10, 100),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(35),
              border: Border.all(color: Colors.white10),
            ),
            child: GestureDetector(
              onDoubleTap: () {
                setState(() {
                  _isFullMap = !_isFullMap;
                  if (_isFullMap) {
                    _selectedFriend = null;
                    _resetZoom();
                  }
                });
              },
              child: ClipRRect(
                borderRadius: BorderRadius.circular(35),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final w = constraints.maxWidth;
                    final h = constraints.maxHeight;

                    return InteractiveViewer(
                      transformationController: _mapTransform,
                      panEnabled: true,
                      scaleEnabled: true,
                      minScale: 1.0,
                      maxScale: 4.0,
                      boundaryMargin: const EdgeInsets.all(120),
                      child: Stack(
                        children: [
                          Image.asset(
                            "assets/images/sliit_map.png",
                            width: w,
                            height: h,
                            fit: BoxFit.cover,
                          ),

                          // subtle overlay for readability
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.18),
                                    Colors.black.withOpacity(0.05),
                                    Colors.black.withOpacity(0.22),
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // floating avatars (responsive positioning)
                          ...docs.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final lat = _toDouble(data['last_lat']);
                            final lng = _toDouble(data['last_lng']);
                            if (lat == null || lng == null)
                              return const SizedBox();

                            // Mock positioning (stable but responsive)
                            final seed =
                                (lat * 100000).abs() + (lng * 100000).abs();
                            final xN = (seed % 1000) / 1000; // 0..1
                            final yN =
                                ((seed / 1000).floor() % 1000) / 1000; // 0..1

                            // keep inside safe bounds
                            final padX = math.max(18.0, w * 0.05);
                            final padY = math.max(18.0, h * 0.06);

                            final x = padX + xN * math.max(1.0, (w - padX * 2));
                            final y = padY + yN * math.max(1.0, (h - padY * 2));

                            return Positioned(
                              left: x,
                              top: y,
                              child: _buildFloatingAvatar(data),
                            );
                          }).toList(),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),

        // 1.1 Legend glass chip (top)
        if (!_isFullMap)
          Positioned(
            top: 92,
            left: 18,
            right: 18,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.16),
                          ),
                        ),
                        child: const Icon(
                          Icons.group,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "$visibleCount Guardians Online",
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              "Tap an avatar to open quick actions",
                              style: TextStyle(
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.wifi_tethering,
                        color: Colors.greenAccent,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // 1.2 Guardians list opener (bottom-left)
        if (!_isFullMap)
          Positioned(
            left: 18,
            bottom: 190,
            child: GestureDetector(
              onTap: () => _openGuardiansSheet(docs),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.30),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withOpacity(0.12)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.view_list_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "Guardians ($visibleCount)",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                            fontSize: 12,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.keyboard_arrow_up_rounded,
                          color: Colors.white70,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

        // 2. Navigate popup (animated)
        if (!_isFullMap)
          Positioned(
            left: 0,
            right: 0,
            bottom: 120,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: _selectedFriend == null
                  ? const SizedBox.shrink()
                  : _buildNavigatePopup(),
            ),
          ),

        // 3. Full-map mini HUD (only in full view)
        if (_isFullMap)
          Positioned(
            right: 14,
            bottom: 14,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.35),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: Colors.white.withOpacity(0.10)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _hudBtn(
                        icon: Icons.add,
                        tooltip: "Zoom in",
                        onTap: () => _bumpZoom(1.20),
                      ),
                      const SizedBox(height: 8),
                      _hudBtn(
                        icon: Icons.remove,
                        tooltip: "Zoom out",
                        onTap: () => _bumpZoom(0.84),
                      ),
                      const SizedBox(height: 8),
                      _hudBtn(
                        icon: Icons.center_focus_strong,
                        tooltip: "Reset",
                        onTap: _resetZoom,
                      ),
                      const SizedBox(height: 8),
                      _hudBtn(
                        icon: Icons.fullscreen_exit,
                        tooltip: "Exit full view",
                        onTap: () {
                          setState(() {
                            _isFullMap = false;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // --- සිතියම උඩ ඇති පාවෙන යාළුවාගේ Avatar එක ---
  Widget _buildFloatingAvatar(Map<String, dynamic> data) {
    String? photo = data['profile_photo_base64'];
    String name = data['first_name'] ?? "User";

    final bool isSelected =
        _selectedFriend != null &&
        _selectedFriend!['student_email'] == data['student_email'];

    return GestureDetector(
      onTap: () => setState(() => _selectedFriend = data),
      child: Column(
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.85, end: 1.15),
            duration: const Duration(milliseconds: 1100),
            curve: Curves.easeInOut,
            builder: (context, v, child) {
              return Container(
                width: 54,
                height: 54,
                alignment: Alignment.center,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // pulsing ring
                    Transform.scale(
                      scale: v,
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (isSelected ? Colors.amber : Colors.white)
                              .withOpacity(0.10),
                          border: Border.all(
                            color: (isSelected ? Colors.amber : Colors.white)
                                .withOpacity(0.28),
                            width: 1.2,
                          ),
                        ),
                      ),
                    ),

                    // avatar
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: Colors.redAccent,
                        backgroundImage: photo != null
                            ? MemoryImage(base64Decode(photo))
                            : null,
                        child: photo == null
                            ? const Icon(
                                Icons.person,
                                color: Colors.white,
                                size: 18,
                              )
                            : null,
                      ),
                    ),
                  ],
                ),
              );
            },
            onEnd: () {
              // loop pulse without controllers
              if (mounted) setState(() {});
            },
          ),

          const SizedBox(height: 4),

          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.68),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.08)),
            ),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // --- "NAVIGATE TO GOOGLE MAPS" Popup පුවරුව ---
  Widget _buildNavigatePopup() {
    String name = _selectedFriend!['first_name'] ?? "Guardian";
    final lat = _toDouble(_selectedFriend!['last_lat']);
    final lng = _toDouble(_selectedFriend!['last_lng']);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(25),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.45),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                const Icon(Icons.gps_fixed, color: Colors.greenAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Track $name's Position?",
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: "Close",
                  onPressed: () => setState(() => _selectedFriend = null),
                  icon: const Icon(
                    Icons.close,
                    color: Colors.white70,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 6),
                ElevatedButton.icon(
                  onPressed: (lat == null || lng == null)
                      ? null
                      : () => _openExternalMaps(lat, lng),
                  icon: const Icon(
                    Icons.map_outlined,
                    color: Colors.white,
                    size: 16,
                  ),
                  label: const Text(
                    "NAVIGATE",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    disabledBackgroundColor: Colors.blueGrey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // බාහිර Maps ඇප් එක විවෘත කරන ලොජික් එක
  Future<void> _openExternalMaps(double lat, double lng) async {
    final googleUrl = Uri.parse(
      "https://www.google.com/maps/search/?api=1&query=$lat,$lng",
    );
    final appleUrl = Uri.parse("https://maps.apple.com/?q=$lat,$lng");

    if (await canLaunchUrl(googleUrl)) {
      await launchUrl(googleUrl, mode: LaunchMode.externalApplication);
      return;
    }
    if (await canLaunchUrl(appleUrl)) {
      await launchUrl(appleUrl, mode: LaunchMode.externalApplication);
      return;
    }

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Could not launch maps")));
  }

  // --- Bottom Sheet: Guardians list + search ---
  void _openGuardiansSheet(List<QueryDocumentSnapshot> docs) {
    // build a simple list of maps so we can filter easily
    final items = docs
        .map((d) => d.data() as Map<String, dynamic>)
        .where((m) => m['student_email'] != null) // keep consistent key
        .toList();

    // reset search on open for clarity
    _searchCtrl.text = "";

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.92,
          builder: (context, scrollCtrl) {
            return ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(26),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F0F13).withOpacity(0.92),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                    border: Border(
                      top: BorderSide(color: Colors.white.withOpacity(0.10)),
                    ),
                  ),
                  child: StatefulBuilder(
                    builder: (context, setSheetState) {
                      final q = _searchCtrl.text.trim().toLowerCase();

                      final filtered = items.where((m) {
                        final name = (m['first_name'] ?? "User")
                            .toString()
                            .toLowerCase();
                        final email = (m['student_email'] ?? "")
                            .toString()
                            .toLowerCase();
                        return q.isEmpty ||
                            name.contains(q) ||
                            email.contains(q);
                      }).toList();

                      return Column(
                        children: [
                          const SizedBox(height: 10),
                          Container(
                            width: 44,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.18),
                              borderRadius: BorderRadius.circular(999),
                            ),
                          ),
                          const SizedBox(height: 12),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.group,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    "Guardians",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.06),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.10),
                                    ),
                                  ),
                                  child: Text(
                                    "${filtered.length} found",
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: "Close",
                                  onPressed: () => Navigator.pop(context),
                                  icon: const Icon(
                                    Icons.close,
                                    color: Colors.white70,
                                    size: 18,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 2, 16, 12),
                            child: TextField(
                              controller: _searchCtrl,
                              onChanged: (_) => setSheetState(() {}),
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                prefixIcon: const Icon(
                                  Icons.search,
                                  color: Colors.white70,
                                ),
                                hintText: "Search by name or email...",
                                hintStyle: const TextStyle(
                                  color: Colors.white54,
                                  fontWeight: FontWeight.w600,
                                ),
                                filled: true,
                                fillColor: Colors.white.withOpacity(0.06),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 12,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.10),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Colors.white.withOpacity(0.10),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  borderSide: BorderSide(
                                    color: Colors.redAccent.withOpacity(0.55),
                                  ),
                                ),
                                suffixIcon: q.isEmpty
                                    ? null
                                    : IconButton(
                                        tooltip: "Clear",
                                        onPressed: () {
                                          _searchCtrl.clear();
                                          setSheetState(() {});
                                        },
                                        icon: const Icon(
                                          Icons.close_rounded,
                                          color: Colors.white70,
                                          size: 18,
                                        ),
                                      ),
                              ),
                            ),
                          ),

                          Expanded(
                            child: filtered.isEmpty
                                ? Center(
                                    child: Text(
                                      "No results.",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.55),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  )
                                : ListView.separated(
                                    controller: scrollCtrl,
                                    itemCount: filtered.length,
                                    separatorBuilder: (_, __) => Divider(
                                      height: 1,
                                      color: Colors.white.withOpacity(0.06),
                                    ),
                                    itemBuilder: (context, i) {
                                      final m = filtered[i];
                                      final name = (m['first_name'] ?? "User")
                                          .toString();
                                      final email = (m['student_email'] ?? "")
                                          .toString();
                                      final photo = m['profile_photo_base64'];

                                      final bool online = _isOnline(m);
                                      final Color dotColor = online
                                          ? Colors.greenAccent
                                          : Colors.white38;

                                      return ListTile(
                                        onTap: () {
                                          // keep same selection logic
                                          setState(() {
                                            _selectedFriend = m;
                                          });
                                          Navigator.pop(context);
                                        },
                                        leading: Stack(
                                          alignment: Alignment.bottomRight,
                                          children: [
                                            CircleAvatar(
                                              radius: 22,
                                              backgroundColor: Colors.redAccent,
                                              backgroundImage: photo != null
                                                  ? MemoryImage(
                                                      base64Decode(photo),
                                                    )
                                                  : null,
                                              child: photo == null
                                                  ? const Icon(
                                                      Icons.person,
                                                      color: Colors.white,
                                                    )
                                                  : null,
                                            ),
                                            Container(
                                              width: 12,
                                              height: 12,
                                              decoration: BoxDecoration(
                                                color: dotColor,
                                                shape: BoxShape.circle,
                                                border: Border.all(
                                                  color: const Color(
                                                    0xFF0F0F13,
                                                  ),
                                                  width: 2,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        title: Text(
                                          name,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w900,
                                          ),
                                        ),
                                        subtitle: Text(
                                          email,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                            color: Colors.white70,
                                            fontWeight: FontWeight.w600,
                                            fontSize: 12,
                                          ),
                                        ),
                                        trailing: const Icon(
                                          Icons.chevron_right,
                                          color: Colors.white54,
                                        ),
                                      );
                                    },
                                  ),
                          ),

                          const SizedBox(height: 10),
                        ],
                      );
                    },
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _isOnline(Map<String, dynamic> m) {
    // purely UI-based "online" heuristic based on last_seen
    final v = m['last_seen'];
    DateTime? t;
    if (v is Timestamp) t = v.toDate();
    if (v is DateTime) t = v;
    if (t == null) return false;
    return DateTime.now().difference(t).inMinutes <= 5;
  }

  Widget _hudBtn({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Tooltip(
          message: tooltip,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.white.withOpacity(0.10)),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  void _resetZoom() {
    _mapTransform.value = Matrix4.identity();
  }

  void _bumpZoom(double factor) {
    final m = _mapTransform.value.clone();
    final current = m.getMaxScaleOnAxis();
    double next = current * factor;
    if (next < 1.0) next = 1.0;
    if (next > 4.0) next = 4.0;

    // scale around center
    final scaleBy = next / current;
    _mapTransform.value = m..scale(scaleBy);
  }

  double? _toDouble(dynamic v) {
    if (v == null) return null;
    if (v is double) return v;
    if (v is int) return v.toDouble();
    return double.tryParse(v.toString());
  }

  // --- Decorations & Shared Helpers ---
  Widget _bgDecor({required Widget child}) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFA3A3A), Color(0xFF0F0F13)],
        ),
      ),
      child: child,
    );
  }

  Widget _blockedUI() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      body: _bgDecor(
        child: Center(
          child: Text("Locked Area", style: TextStyle(color: Colors.white38)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _mapTransform.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Widget _emptyState(String msg) {
    return Center(
      child: Text(msg, style: const TextStyle(color: Colors.white38)),
    );
  }
}
