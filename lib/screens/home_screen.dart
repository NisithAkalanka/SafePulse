import 'dart:async';
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
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkProfileStatus();
    });
  }

  // --- SNAP-STYLE MAP SYNC (සෑම තත්පර 30කට වරක් ලොකේෂන් Update කරයි) ---
  void _startLiveLocationSync() {
    _locationSyncTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        try {
          Position pos = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
          await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
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
      var doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          _userRole = doc.data()?['role'] ?? "student";
          if (doc.data()?['sos_categories'] != null) {
            _sosCategories = Map<String, bool>.from(doc.data()?['sos_categories']);
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
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      setState(() { _currentPosition = position; });
      _getAddressFromLatLng(position);
    } catch (e) {
      setState(() { _currentAddress = "GPS Signal Found (Updating...)"; });
    }
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() { _currentAddress = "${place.name}, ${place.locality}"; });
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
          content: Text("🆘 $type Alert Sent!", style: const TextStyle(color: Colors.black)),
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          action: SnackBarAction(label: "OK", textColor: Colors.redAccent, onPressed: () {}),
        ),
      );
    } catch (e) { debugPrint(e.toString()); }
  }

  void _showSOSOptions() async {
    await _loadUserStatus();
    List<String> activeTypes = _sosCategories.entries
        .where((entry) => entry.value == true)
        .map((entry) => entry.key).toList();

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(35))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 45, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 25),
            const Text("Select Emergency Type", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ...activeTypes.map((type) => ListTile(
              leading: const Icon(Icons.flash_on, color: Colors.redAccent),
              title: Text(type, style: const TextStyle(fontWeight: FontWeight.bold)),
              onTap: () { Navigator.pop(context); _sendToFirebase(type); },
            )).toList(),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _listenForGlobalAlerts() {
    _globalAlertsSub = FirebaseFirestore.instance.collection('alerts')
        .where('time', isGreaterThan: DateTime.now().subtract(const Duration(minutes: 1)))
        .snapshots().listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.added) {
          final alertData = change.doc.data();
          if (alertData?['uid'] != FirebaseAuth.instance.currentUser?.uid) {
            _showEmergencyAlert(alertData?['type'] ?? 'Emergency', alertData?['address'] ?? 'Nearby');
          }
        }
      }
    });
  }

  void _showEmergencyAlert(String type, String location) {
    if (!mounted) return;
    showDialog(context: context, builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Row(children: [Icon(Icons.warning, color: Colors.red), Text(" HELP NEEDED")]),
      content: Text("A $type reported nearby:\n📍 $location"),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("CLOSE"))]));
  }

  Future<void> _checkProfileStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!doc.exists || doc.data()?['sliit_id'] == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text("Setup your SLIIT profile!"),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(label: "SETUP", textColor: Colors.redAccent, onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
          })));
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
        title: const Text("SafePulse", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24, letterSpacing: 1.5)),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 30), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AlertsHubScreen()))),
          IconButton(icon: const Icon(Icons.account_circle_rounded, color: Colors.white, size: 34), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => (FirebaseAuth.instance.currentUser == null) ? const LoginScreen() : const ProfileScreen()))),
          const SizedBox(width: 10),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFFFF4B4B), Color(0xFF900C0C)]),
        ),
        child: Column(
          children: [
            const SizedBox(height: 140),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 25), child: Text(_currentAddress, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16))),
            const Text("Guardian Cloud Monitoring Connected", style: TextStyle(color: Colors.white54, fontSize: 11)),
            const Spacer(),

            // SOS BUTTON AREA
            Center(child: GestureDetector(onLongPress: _showSOSOptions, child: Stack(alignment: Alignment.center, children: [
              _ripple(310, 0.06), _ripple(260, 0.12), _ripple(210, 0.18),
              Container(width: 185, height: 185, decoration: BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 20, spreadRadius: 4, offset: const Offset(0, 10))], gradient: const RadialGradient(colors: [Color(0xFFFA6A6A), Color(0xFFD32F2F)]), border: Border.all(color: Colors.white24, width: 2.5)),
                child: const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Text("SOS", style: TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.bold)), Text("HOLD TO TRIGGER", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold))]))]))),
            
            const Spacer(),

            // --- ලොග් වුණු යූසර්ට පමණක් පෙනෙන පහළ බටන් ටික (THE FIX) ---
            StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                // යූසර් ලොග් වී ඇත්නම් පමණක් මෙය පෙන්වයි
                if (snapshot.hasData) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 30),
                    child: Column(
                      children: [
                        Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                          GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SafetyTimerScreen())), child: _btmBtn(Icons.directions_walk_rounded, "Safe Walk")),
                          GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GuardianModeScreen())), child: _btmBtn(Icons.verified_user_rounded, "Guardians")),
                        ]),
                        if (_userRole == 'admin') ...[
                          const SizedBox(height: 25),
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminFullDashboard())),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              width: double.infinity,
                              decoration: BoxDecoration(color: Colors.black.withOpacity(0.85), borderRadius: BorderRadius.circular(18), border: Border.all(color: Colors.redAccent, width: 1.5)),
                              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.admin_panel_settings, color: Colors.white, size: 24), SizedBox(width: 12), Text("ADMIN COMMAND CENTER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15))]),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                } else {
                  // ලොග් වී නොමැති නම් ඉඩ ප්‍රමාණය සීමා කිරීමට මෙය භාවිතා කරයි
                  return const SizedBox(height: 120); 
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _ripple(double s, double o) => Container(width: s, height: s, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(o)));
  Widget _btmBtn(IconData i, String l) => Container(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)]), child: Row(children: [Icon(i, color: Colors.redAccent, size: 22), const SizedBox(width: 8), Text(l, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14))]));

  @override
  void dispose() { _globalAlertsSub?.cancel(); _locationSyncTimer?.cancel(); super.dispose(); }
}