import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

import 'profile_screen.dart';
import 'login_screen.dart';
import 'safety_timer_screen.dart';
import 'guardian_mode_screen.dart';
import 'alerts_hub_screen.dart';
import 'admin_full_dashboard.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _currentAddress = "Detecting location...";
  Position? _currentPosition;
  String _userRole = "student";
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _globalAlertsSub;
  Timer? _locationSyncTimer;
  StreamSubscription<User?>? _authSub;

  Map<String, bool> _sosCategories = {
    "🚨 Medical Emergency": true,
    "⚠️ Threat / Hazard": true,
    "💥 Accident / Crash": true,
  };

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _listenForGlobalAlerts();
    _loadUserStatus();
    _startLiveLocationSync();

    // When user logs in/out, reload role so admin button shows correctly
    _authSub = FirebaseAuth.instance.authStateChanges().listen((u) {
      if (!mounted) return;
      if (u == null) {
        setState(() {
          _userRole = 'student';
        });
      } else {
        _loadUserStatus();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkProfileStatus();
    });
  }

  // --- SNAP-STYLE MAP SYNC (සෑම තත්පර 30කට වරක් ලොකේෂන් Update කරයි) ---
  void _startLiveLocationSync() {
    _locationSyncTimer = Timer.periodic(const Duration(seconds: 30), (
      timer,
    ) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          Position pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high,
          );
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .set({
                'last_lat': pos.latitude,
                'last_lng': pos.longitude,
                'last_seen': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
        } catch (e) {
          debugPrint("Sync Error: $e");
        }
      }
    });
  }

  Future<void> _loadUserStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (doc.exists) {
        if (!mounted) return;
        setState(() {
          _userRole = doc.data()?['role'] ?? "student";
          if (doc.data()?['sos_categories'] != null) {
            _sosCategories = Map<String, bool>.from(
              doc.data()?['sos_categories'],
            );
          }
        });
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
      });
      _getAddressFromLatLng(position);
    } catch (e) {
      setState(() {
        _currentAddress = "GPS Signal Found (Updating...)";
      });
    }
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _currentAddress = "${place.name}, ${place.locality}";
        });
      }
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  Future<void> _sendToFirebase(String type) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (_currentPosition == null) await _getCurrentLocation();

      await FirebaseFirestore.instance.collection('alerts').add({
        'type': type,
        'user_email': user?.email ?? "Guest Mode",
        'uid': user?.uid ?? "anonymous",
        'lat': _currentPosition?.latitude,
        'lng': _currentPosition?.longitude,
        'address': _currentAddress,
        'time': FieldValue.serverTimestamp(),
        'status': 'New Alert',
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "🆘 $type Alert Sent!",
            style: const TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          action: SnackBarAction(
            label: "OK",
            textColor: Colors.redAccent,
            onPressed: () {},
          ),
        ),
      );
    } catch (e) {
      debugPrint(e.toString());
    }
  }

  void _showSOSOptions() async {
    await _loadUserStatus();
    List<String> activeTypes = _sosCategories.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key)
        .toList();

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 45,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 25),
            const Text(
              "Select Emergency Type",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            ...activeTypes
                .map(
                  (type) => ListTile(
                    leading: const Icon(
                      Icons.flash_on,
                      color: Colors.redAccent,
                    ),
                    title: Text(
                      type,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    onTap: () {
                      Navigator.pop(context);
                      _sendToFirebase(type);
                    },
                  ),
                )
                .toList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _listenForGlobalAlerts() {
    _globalAlertsSub = FirebaseFirestore.instance
        .collection('alerts')
        .where(
          'time',
          isGreaterThan: DateTime.now().subtract(const Duration(minutes: 1)),
        )
        .snapshots()
        .listen((snapshot) {
          for (final change in snapshot.docChanges) {
            if (change.type == DocumentChangeType.added) {
              final alertData = change.doc.data();
              if (alertData?['uid'] != FirebaseAuth.instance.currentUser?.uid) {
                _showEmergencyAlert(
                  alertData?['type'] ?? 'Emergency',
                  alertData?['address'] ?? 'Nearby',
                );
              }
            }
          }
        });
  }

  void _showEmergencyAlert(String type, String location) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.red),
            Text(" HELP NEEDED"),
          ],
        ),
        content: Text("A $type reported nearby:\n📍 $location"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("CLOSE"),
          ),
        ],
      ),
    );
  }

  Future<void> _checkProfileStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (!doc.exists || doc.data()?['sliit_id'] == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Setup your SLIIT profile!"),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: "SETUP",
            textColor: Colors.redAccent,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "SafePulse",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 24,
            letterSpacing: 1.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Colors.white,
              size: 30,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AlertsHubScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(
              Icons.account_circle_rounded,
              color: Colors.white,
              size: 34,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    (FirebaseAuth.instance.currentUser == null)
                    ? const LoginScreen()
                    : const ProfileScreen(),
              ),
            ),
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Stack(
        children: [
          // Background gradient
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFF4B4B),
                  Color(0xFFB31217),
                  Color(0xFF1B1B1B),
                ],
                stops: [0.0, 0.55, 1.0],
              ),
            ),
          ),

          // Soft blobs
          Positioned(
            top: -120,
            left: -90,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            top: 120,
            right: -120,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.yellowAccent.withOpacity(0.06),
              ),
            ),
          ),
          Positioned(
            bottom: -140,
            left: -80,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),

          // Foreground content (FIXED: scrollable so it won't overflow)
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        children: [
                          const SizedBox(height: 76),

                          // Glass Address Card
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(22),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 18,
                                  sigmaY: 18,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(22),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.18),
                                      width: 1.2,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 42,
                                        height: 42,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Colors.white.withOpacity(0.14),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.22,
                                            ),
                                          ),
                                        ),
                                        child: const Icon(
                                          Icons.my_location,
                                          color: Colors.white,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            const Text(
                                              "Current Location",
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              _currentAddress,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withOpacity(0.22),
                                          borderRadius: BorderRadius.circular(
                                            999,
                                          ),
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.16,
                                            ),
                                          ),
                                        ),
                                        child: const Row(
                                          children: [
                                            Icon(
                                              Icons.cloud_done,
                                              color: Colors.white,
                                              size: 14,
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              "Cloud Sync",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 26),

                          // Punchy tagline
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 22),
                            child: Text(
                              "Hold SOS for instant help — your guardians will be notified.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                height: 1.25,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const Spacer(),

                          // SOS BUTTON AREA (same logic, upgraded UI)
                          Center(
                            child: GestureDetector(
                              onLongPress: _showSOSOptions,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  _ripple(340, 0.05),
                                  _ripple(290, 0.09),
                                  _ripple(240, 0.14),
                                  _ripple(200, 0.18),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(999),
                                    child: BackdropFilter(
                                      filter: ImageFilter.blur(
                                        sigmaX: 10,
                                        sigmaY: 10,
                                      ),
                                      child: Container(
                                        width: 190,
                                        height: 190,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          border: Border.all(
                                            color: Colors.white.withOpacity(
                                              0.25,
                                            ),
                                            width: 2.2,
                                          ),
                                          boxShadow: const [
                                            BoxShadow(
                                              color: Colors.black54,
                                              blurRadius: 24,
                                              spreadRadius: 2,
                                              offset: Offset(0, 14),
                                            ),
                                          ],
                                          gradient: const RadialGradient(
                                            colors: [
                                              Color(0xFFFF7B7B),
                                              Color(0xFFD32F2F),
                                              Color(0xFF900C0C),
                                            ],
                                            stops: [0.0, 0.55, 1.0],
                                          ),
                                        ),
                                        child: const Column(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              "SOS",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 58,
                                                fontWeight: FontWeight.w900,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              "PRESS & HOLD",
                                              style: TextStyle(
                                                color: Colors.white70,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.2,
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

                          const Spacer(),

                          // Bottom Glass Panel (keeps the same StreamBuilder + admin logic)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(26),
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 20,
                                  sigmaY: 20,
                                ),
                                child: Container(
                                  padding: const EdgeInsets.fromLTRB(
                                    16,
                                    14,
                                    16,
                                    16,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(26),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.16),
                                      width: 1.1,
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      // little handle
                                      Container(
                                        width: 46,
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.22),
                                          borderRadius: BorderRadius.circular(
                                            99,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      StreamBuilder<User?>(
                                        stream: FirebaseAuth.instance
                                            .authStateChanges(),
                                        builder: (context, snapshot) {
                                          if (snapshot.hasData) {
                                            return Column(
                                              children: [
                                                Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceEvenly,
                                                  children: [
                                                    GestureDetector(
                                                      onTap: () => Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              const SafetyTimerScreen(),
                                                        ),
                                                      ),
                                                      child: _btmBtn(
                                                        Icons
                                                            .directions_walk_rounded,
                                                        "Safe Walk",
                                                      ),
                                                    ),
                                                    GestureDetector(
                                                      onTap: () => Navigator.push(
                                                        context,
                                                        MaterialPageRoute(
                                                          builder: (context) =>
                                                              const GuardianModeScreen(),
                                                        ),
                                                      ),
                                                      child: _btmBtn(
                                                        Icons
                                                            .verified_user_rounded,
                                                        "Guardians",
                                                      ),
                                                    ),
                                                  ],
                                                ),

                                                if (_userRole == 'admin') ...[
                                                  const SizedBox(height: 16),
                                                  GestureDetector(
                                                    onTap: () => Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            const AdminFullDashboard(),
                                                      ),
                                                    ),
                                                    child: Container(
                                                      padding:
                                                          const EdgeInsets.symmetric(
                                                            vertical: 16,
                                                          ),
                                                      width: double.infinity,
                                                      decoration: BoxDecoration(
                                                        color: Colors.black
                                                            .withOpacity(0.65),
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              18,
                                                            ),
                                                        border: Border.all(
                                                          color:
                                                              Colors.redAccent,
                                                          width: 1.4,
                                                        ),
                                                      ),
                                                      child: Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .center,
                                                        children: [
                                                          const Icon(
                                                            Icons
                                                                .admin_panel_settings,
                                                            color: Colors.white,
                                                            size: 22,
                                                          ),
                                                          const SizedBox(
                                                            width: 10,
                                                          ),
                                                          Flexible(
                                                            child: FittedBox(
                                                              fit: BoxFit
                                                                  .scaleDown,
                                                              child: const Text(
                                                                "ADMIN COMMAND CENTER",
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                style: TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                  fontSize: 14,
                                                                  letterSpacing:
                                                                      1.1,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            );
                                          }

                                          return Padding(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 10,
                                            ),
                                            child: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: const [
                                                Icon(
                                                  Icons.lock_outline,
                                                  color: Colors.white70,
                                                  size: 16,
                                                ),
                                                SizedBox(width: 8),
                                                Text(
                                                  "Login to enable Safe Walk & Guardians",
                                                  style: TextStyle(
                                                    color: Colors.white70,
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _ripple(double s, double o) => Container(
    width: s,
    height: s,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withOpacity(o),
    ),
  );

  Widget _btmBtn(IconData i, String l) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.95),
      borderRadius: BorderRadius.circular(30),
      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
    ),
    child: Row(
      children: [
        Icon(i, color: Colors.redAccent, size: 22),
        const SizedBox(width: 8),
        Text(
          l,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      ],
    ),
  );

  @override
  void dispose() {
    _globalAlertsSub?.cancel();
    _locationSyncTimer?.cancel();
    _authSub?.cancel();
    super.dispose();
  }
}
