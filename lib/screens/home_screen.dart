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

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _currentAddress = "Detecting location...";
  Position? _currentPosition;
  bool _receiveNotifications = true;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _globalAlertsSub;
  Timer? _locationSyncTimer; // සජීවීව ලොකේෂන් යාවත්කාලීන කරන ටයිමරය

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
    _loadUserSOSSettings();
    _startLiveLocationSync(); // Snapchat style tracking එක මෙතනින් පටන් ගන්නවා
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkProfileStatus();
    });
  }

  // --- SNAP-STYLE MAP SYNC ---
  // සෑම තත්පර 30කට වරක් යූසර්ගේ ලොකේෂන් එක Firestore එකට යවනවා (යාළුවන්ට පේන්න)
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
          debugPrint("Location synced for Guardians");
        } catch (e) {
          debugPrint("Sync Error: $e");
        }
      }
    });
  }

  Future<void> _loadUserSOSSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      var doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      if (doc.exists && doc.data()?['sos_categories'] != null) {
        setState(() {
          _sosCategories = Map<String, bool>.from(doc.data()?['sos_categories']);
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
      setState(() { _currentAddress = "GPS Signal Found (Updating address...)"; });
    }
  }

  Future<void> _getAddressFromLatLng(Position position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        setState(() {
          _currentAddress = "${place.name}, ${place.locality}";
        });
      }
    } catch (e) {
      debugPrint("Address lookup error: $e");
    }
  }

  Future<void> _sendToFirebase(String type) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (_currentPosition == null) await _getCurrentLocation();

      await FirebaseFirestore.instance.collection('alerts').add({
        'type': type,
        'user_email': user?.email ?? "Guest/Public",
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
          content: Text("🆘 $type Alert Dispatched Successfully!"),
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          margin: const EdgeInsets.all(20),
          action: SnackBarAction(label: "OK", textColor: Colors.redAccent, onPressed: () {}),
        ),
      );
    } catch (e) {
      debugPrint("Alert send failed: $e");
    }
  }

  void _showSOSOptions() async {
    await _loadUserSOSSettings();
    List<String> activeTypes = _sosCategories.entries.where((e) => e.value == true).map((e) => e.key).toList();

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 45, height: 5, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(10))),
            const SizedBox(height: 25),
            const Text("Emergency Situation Context", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 15),
            if (activeTypes.isEmpty)
              const Text("No types enabled in SOS settings.", style: TextStyle(color: Colors.grey)),
            ...activeTypes.map((type) => ListTile(
              leading: const Icon(Icons.flash_on, color: Colors.red),
              title: Text(type, style: const TextStyle(fontWeight: FontWeight.w600)),
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
        if (!_receiveNotifications) return;
        for (final change in snapshot.docChanges) {
          if (change.type == DocumentChangeType.added) {
            final alertData = change.doc.data();
            if (alertData?['uid'] != FirebaseAuth.instance.currentUser?.uid) {
              _showGlobalEmergencyPopUp(
                (alertData?['type'] ?? 'General Alert').toString(),
                (alertData?['address'] ?? 'Detecting Location...').toString(),
              );
            }
          }
        }
      });
  }

  void _showGlobalEmergencyPopUp(String type, String location) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [Icon(Icons.warning, color: Colors.red), Text(" HELP REQUESTED")],
        ),
        content: Text("A $type has been reported at:\n📍 $location"),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("DISMISS"))],
      ),
    );
  }

  Future<void> _checkProfileStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!doc.exists || doc.data()?['sliit_id'] == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("⚠️ Incomplete Profile. Security setup needed!"),
          backgroundColor: Colors.black87,
          action: SnackBarAction(label: "SETUP", textColor: Colors.redAccent, onPressed: () {
            Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
          }),
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
        title: const Text("SafePulse", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24, letterSpacing: 1.5)),
        actions: [
          Stack(
            alignment: Alignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 30),
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AlertsHubScreen())),
              ),
              Positioned(
                right: 12, top: 12,
                child: Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.yellowAccent, shape: BoxShape.circle)),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_rounded, color: Colors.white, size: 34),
            onPressed: () {
              if (FirebaseAuth.instance.currentUser == null) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
              }
            },
          ),
          const SizedBox(width: 15),
        ],
      ),
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF5252), Color(0xFFB71C1C)],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 140),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Text(_currentAddress, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16)),
            ),
            const Text("Guardian Cloud Connected", style: TextStyle(color: Colors.white54, fontSize: 12)),
            const Spacer(),

            // MAIN SOS TRIGGER BUTTON
            Center(
              child: GestureDetector(
                onLongPress: _showSOSOptions,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _ripple(320, 0.05),
                    _ripple(270, 0.1),
                    _ripple(220, 0.15),
                    Container(
                      width: 180, height: 180,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, spreadRadius: 4, offset: const Offset(0, 8))],
                        gradient: const RadialGradient(colors: [Color(0xFFFA6A6A), Color(0xFFD32F2F)]),
                        border: Border.all(color: Colors.white24, width: 2),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("SOS", style: TextStyle(color: Colors.white, fontSize: 52, fontWeight: FontWeight.bold)),
                          Text("HOLD TO TRIGGER", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const Spacer(),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 50),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SafetyTimerScreen())),
                    child: _btmBtn(Icons.radar_rounded, "Safe Walk"),
                  ),
                  GestureDetector(
                    // අලුතින් යාවත්කාලීන කළ ගාර්ඩියන් මෝඩ් එක මෙතනින් යන්න
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GuardianModeScreen())),
                    child: _btmBtn(Icons.verified_user_rounded, "Guardians"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _ripple(double s, double o) => Container(width: s, height: s, decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withOpacity(o)));

  Widget _btmBtn(IconData i, String l) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.95), borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: Row(
        children: [
          Icon(i, color: Colors.redAccent, size: 22),
          const SizedBox(width: 8),
          Text(l, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _locationSyncTimer?.cancel(); // ටයිමරය අයින් කිරීම
    _globalAlertsSub?.cancel();
    super.dispose();
  }
}