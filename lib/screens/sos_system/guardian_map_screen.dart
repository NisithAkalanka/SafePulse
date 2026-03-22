import 'dart:convert';
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
              backgroundColor: const Color(0xFFF6F7FB),
              extendBodyBehindAppBar: true,
              appBar: AppBar(
                title: Text(
                  role == "admin" ? "Global Tracking" : "Guardian Map",
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.2,
                  ),
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
              body: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(18, 108, 18, 24),
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
                        _headerCard(role),
                        const SizedBox(height: 12),
                        _topInfoStrip(role),
                      ],
                    ),
                  ),
                  Expanded(
                    child: role == "admin"
                        ? _buildAdminStream()
                        : _buildStudentStream(guardians),
                  ),
                ],
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
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFB31217)),
          );
        }
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
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFB31217)),
          );
        }
        return _buildMainMapUI(snapshot.data!.docs);
      },
    );
  }

  // --- සජීවී සිතියම් Layout එක (Map + Overlays) ---
  Widget _buildMainMapUI(List<QueryDocumentSnapshot> docs) {
    int visibleCount = 0;
    for (final d in docs) {
      final data = d.data() as Map<String, dynamic>;
      final lat = _toDouble(data['last_lat']);
      final lng = _toDouble(data['last_lng']);
      if (lat != null && lng != null) visibleCount++;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 110),
      child: Stack(
        children: [
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

          Positioned.fill(
            child: Container(
              margin: _isFullMap
                  ? EdgeInsets.zero
                  : const EdgeInsets.only(bottom: 150),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x12000000),
                    blurRadius: 18,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(28),
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
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.black.withOpacity(0.08),
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.14),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            ...docs.map((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final lat = _toDouble(data['last_lat']);
                              final lng = _toDouble(data['last_lng']);
                              if (lat == null || lng == null) {
                                return const SizedBox();
                              }

                              final seed =
                                  (lat * 100000).abs() + (lng * 100000).abs();
                              final xN = (seed % 1000) / 1000;
                              final yN = ((seed / 1000).floor() % 1000) / 1000;

                              final padX = math.max(18.0, w * 0.05);
                              final padY = math.max(18.0, h * 0.06);

                              final x =
                                  padX + xN * math.max(1.0, (w - padX * 2));
                              final y =
                                  padY + yN * math.max(1.0, (h - padY * 2));

                              return Positioned(
                                left: x,
                                top: y,
                                child: _buildFloatingAvatar(data),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),

          if (!_isFullMap)
            Positioned(
              top: 14,
              left: 14,
              right: 14,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 14,
                      offset: Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFFFE3E3),
                      ),
                      child: const Icon(
                        Icons.group,
                        color: Color(0xFFB31217),
                        size: 20,
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
                              color: Color(0xFF1B1B22),
                              fontWeight: FontWeight.w900,
                              fontSize: 12.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            "Tap an avatar to open quick actions",
                            style: TextStyle(
                              color: Color(0xFF747A86),
                              fontWeight: FontWeight.w600,
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.wifi_tethering,
                      color: Color(0xFF1E9E5A),
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),

          if (!_isFullMap)
            Positioned(
              left: 0,
              right: 0,
              bottom: 10,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _openGuardiansSheet(docs),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFE8EAF0),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.view_list_rounded,
                                    color: Color(0xFFB31217),
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    "Guardians ($visibleCount)",
                                    style: const TextStyle(
                                      color: Color(0xFF1B1B22),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 12.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedFriend != null) ...[
                      const SizedBox(height: 12),
                      _buildNavigatePopup(),
                    ],
                  ],
                ),
              ),
            ),

          if (_isFullMap)
            Positioned(
              right: 14,
              bottom: 14,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
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
        ],
      ),
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
                width: 56,
                height: 56,
                alignment: Alignment.center,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Transform.scale(
                      scale: v,
                      child: Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              (isSelected
                                      ? const Color(0xFFFFD34D)
                                      : const Color(0xFFFF4B4B))
                                  .withOpacity(0.14),
                          border: Border.all(
                            color:
                                (isSelected
                                        ? const Color(0xFFFFD34D)
                                        : const Color(0xFFFF4B4B))
                                    .withOpacity(0.35),
                            width: 1.3,
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 10,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: CircleAvatar(
                        radius: 18,
                        backgroundColor: const Color(0xFFB31217),
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
              if (mounted) setState(() {});
            },
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x15000000),
                  blurRadius: 8,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF1B1B22),
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.2,
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

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EAF0)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFE3E3),
            ),
            child: const Icon(
              Icons.gps_fixed,
              color: Color(0xFF1E9E5A),
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Track $name's Position?",
                  style: const TextStyle(
                    color: Color(0xFF1B1B22),
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  "Open Google Maps for live navigation",
                  style: TextStyle(
                    color: Color(0xFF747A86),
                    fontWeight: FontWeight.w600,
                    fontSize: 11.5,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: "Close",
            onPressed: () => setState(() => _selectedFriend = null),
            icon: const Icon(Icons.close, color: Color(0xFF747A86), size: 18),
          ),
          const SizedBox(width: 4),
          ElevatedButton.icon(
            onPressed: (lat == null || lng == null)
                ? null
                : () => _openExternalMaps(lat, lng),
            icon: const Icon(Icons.map_outlined, color: Colors.white, size: 16),
            label: const Text(
              "NAVIGATE",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB31217),
              disabledBackgroundColor: const Color(0xFFB7BDC9),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
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
      backgroundColor: const Color(0xFFF6F7FB),
      isScrollControlled: true,
      barrierColor: Colors.black.withOpacity(0.55),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.92,
          builder: (context, scrollCtrl) {
            return Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF6F7FB),
                borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
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
                    return q.isEmpty || name.contains(q) || email.contains(q);
                  }).toList();

                  return Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: const Color(0xFFD1D5DE),
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
                              color: Color(0xFFB31217),
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            const Expanded(
                              child: Text(
                                "Guardians",
                                style: TextStyle(
                                  color: Color(0xFF1B1B22),
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
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(color: Color(0xFFE8EAF0)),
                              ),
                              child: Text(
                                "${filtered.length} found",
                                style: const TextStyle(
                                  color: Color(0xFF747A86),
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
                                color: Color(0xFF747A86),
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
                          style: const TextStyle(color: Color(0xFF1B1B22)),
                          decoration: InputDecoration(
                            prefixIcon: const Icon(
                              Icons.search,
                              color: Color(0xFF747A86),
                            ),
                            hintText: "Search by name or email...",
                            hintStyle: const TextStyle(
                              color: Color(0xFF9AA1AD),
                              fontWeight: FontWeight.w600,
                            ),
                            filled: true,
                            fillColor: Colors.white,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFE8EAF0),
                              ),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFE8EAF0),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: const BorderSide(
                                color: Color(0xFFB31217),
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
                                      color: Color(0xFF747A86),
                                      size: 18,
                                    ),
                                  ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: filtered.isEmpty
                            ? const Center(
                                child: Text(
                                  "No results.",
                                  style: TextStyle(
                                    color: Color(0xFF9AA1AD),
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              )
                            : ListView.separated(
                                controller: scrollCtrl,
                                itemCount: filtered.length,
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  8,
                                ),
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, i) {
                                  final m = filtered[i];
                                  final name = (m['first_name'] ?? "User")
                                      .toString();
                                  final email = (m['student_email'] ?? "")
                                      .toString();
                                  final photo = m['profile_photo_base64'];
                                  final bool online = _isOnline(m);
                                  final Color dotColor = online
                                      ? const Color(0xFF1E9E5A)
                                      : const Color(0xFFB7BDC9);

                                  return Container(
                                    padding: const EdgeInsets.all(14),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(18),
                                      border: Border.all(
                                        color: const Color(0xFFE8EAF0),
                                      ),
                                    ),
                                    child: ListTile(
                                      onTap: () {
                                        setState(() {
                                          _selectedFriend = m;
                                        });
                                        Navigator.pop(context);
                                      },
                                      contentPadding: EdgeInsets.zero,
                                      leading: Stack(
                                        alignment: Alignment.bottomRight,
                                        children: [
                                          CircleAvatar(
                                            radius: 22,
                                            backgroundColor: const Color(
                                              0xFFB31217,
                                            ),
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
                                                color: Colors.white,
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
                                          color: Color(0xFF1B1B22),
                                          fontWeight: FontWeight.w900,
                                        ),
                                      ),
                                      subtitle: Text(
                                        email,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: Color(0xFF747A86),
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                        ),
                                      ),
                                      trailing: const Icon(
                                        Icons.chevron_right,
                                        color: Color(0xFF9AA1AD),
                                      ),
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
              color: const Color(0xFFF9FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8EAF0)),
            ),
            child: Icon(icon, color: const Color(0xFFB31217), size: 20),
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
      color: const Color(0xFFF6F7FB),
      child: child,
    );
  }

  Widget _blockedUI() {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x12000000),
                blurRadius: 18,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor: Color(0xFFFFE3E3),
                child: Icon(
                  Icons.lock_outline_rounded,
                  color: Color(0xFFB31217),
                  size: 30,
                ),
              ),
              SizedBox(height: 14),
              Text(
                "Locked Area",
                style: TextStyle(
                  color: Color(0xFF1B1B22),
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: 6),
              Text(
                "Sign in to access guardian map tracking.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF747A86),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
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
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x12000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircleAvatar(
              radius: 30,
              backgroundColor: Color(0xFFFFE3E3),
              child: Icon(
                Icons.map_outlined,
                color: Color(0xFFB31217),
                size: 28,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF1B1B22),
                fontWeight: FontWeight.w900,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCard(String role) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.14),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: Icon(
              role == "admin" ? Icons.public_rounded : Icons.map_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  role == "admin" ? "Global Tracking" : "Guardian Map",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  role == "admin"
                      ? "Monitor all active user locations inside the SafePulse system."
                      : "Track trusted guardians and open quick navigation actions.",
                  style: const TextStyle(
                    color: Colors.white70,
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

  Widget _topInfoStrip(String role) {
    return Row(
      children: [
        Expanded(
          child: _topMiniChip(
            role == "admin" ? Icons.group_outlined : Icons.shield_outlined,
            role == "admin" ? "Live users" : "Trusted circle",
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _topMiniChip(Icons.location_on_outlined, "Map tracking"),
        ),
      ],
    );
  }

  Widget _topMiniChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 15, color: Colors.white),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
