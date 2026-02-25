import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

// Navigation සදහා අවශ්‍ය පිටු
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
  String _userRole = "student"; // Default role එක ශිෂ්‍යයෙක් ලෙස
  bool _receiveNotifications = true;
  
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _globalAlertsSub;
  Timer? _locationSyncTimer;

  // Firestore එකෙන් ලෝඩ් වන දත්ත (Settings වලින් වෙනස් කළ හැක)
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
    _loadUserStatus();     // යූසර්ගේ Role සහ Categories පරීක්ෂා කරයි
    _startLiveLocationSync(); // සජීවීව ලොකේෂන් එක සේව් කරයි (Snapchat style)
    
    // UI එක හැදුණු පසු Profile status බලමු
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkProfileStatus();
    });
  }

  // --- SNAP-STYLE LIVE LOCATION SYNC ---
  // සෑම තත්පර 30කට වරක් පද්ධතියේ ඉන්න යූසර්ගේ ලොකේෂන් එක Update කරයි
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
          debugPrint("SafePulse: Background location updated for guardians");
        } catch (e) {
          debugPrint("Location Sync Failed: $e");
        }
      }
    });
  }

  // Firestore එකෙන් Role (Admin/Student) සහ SOS preferences කියවීම
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

  // වත්මන් ස්ථානය ලබා ගැනීම
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
      setState(() { _currentAddress = "GPS Found (Updating address...)"; });
    }
  }

  // අක්ෂාංශ/දේශාංශ ලිපිනයකට හැරවීම
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

  // Firebase Firestore වෙත Alert එකක් යැවීම
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
          content: Text("🆘 $type Alert Dispatched!"),
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          action: SnackBarAction(label: "OK", textColor: Colors.redAccent, onPressed: () {}),
        ),
      );
    } catch (e) { debugPrint(e.toString()); }
  }

  // SOS බටන් එක Long-press කළ විට එන මෙනුව
  void _showSOSOptions() async {
    await _loadUserStatus();
    List<String> activeTypes = _sosCategories.entries
        .where((e) => e.value == true)
        .map((e) => e.key).toList();

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
            const SizedBox(height: 20),
            const Text("What is your emergency?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            if (activeTypes.isEmpty) const Text("Please enable types in settings first."),
            ...activeTypes.map((type) => ListTile(
              leading: const Icon(Icons.emergency_outlined, color: Colors.redAccent),
              title: Text(type, style: const TextStyle(fontWeight: FontWeight.w600)),
              onTap: () { Navigator.pop(context); _sendToFirebase(type); },
            )).toList(),
            const SizedBox(height: 15),
          ],
        ),
      ),
    );
  }

  // පද්ධතියේ වෙනත් අය දමන Alerts සජීවීව නිරීක්ෂණය කිරීම
  void _listenForGlobalAlerts() {
    _globalAlertsSub = FirebaseFirestore.instance.collection('alerts')
        .where('time', isGreaterThan: DateTime.now().subtract(const Duration(minutes: 1)))
        .snapshots().listen((snapshot) {
      if (!_receiveNotifications) return;
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
      title: const Row(children: [Icon(Icons.warning, color: Colors.red), SizedBox(width: 10), Text(" HELP NEEDED")]),
      content: Text("A $type has been reported at:\n📍 $location"),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("CLOSE"))]));
  }

  // Profile incomplete නම් Snack bar එකකින් SETUP මතක් කරයි
  Future<void> _checkProfileStatus() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!doc.exists || doc.data()?['sliit_id'] == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text("Security low! Setup your SLIIT profile details."),
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
          // Notification Hub බටන් එක
          IconButton(icon: const Icon(Icons.notifications_none_rounded, color: Colors.white, size: 30), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AlertsHubScreen()))),
          // Profile/Login බටන් එක
          IconButton(
            icon: const Icon(Icons.account_circle_rounded, color: Colors.white, size: 34), 
            onPressed: () {
              if (FirebaseAuth.instance.currentUser == null) {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginScreen()));
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ProfileScreen()));
              }
            }
          ),
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25),
              child: Text(_currentAddress, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16)),
            ),
            const Text("Guardian Cloud Monitoring Connected", style: TextStyle(color: Colors.white54, fontSize: 11)),
            const Spacer(),

            // PREMIUM RIPPLE SOS BUTTON UI
            Center(
              child: GestureDetector(
                onLongPress: _showSOSOptions,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _ripple(320, 0.06),
                    _ripple(270, 0.12),
                    _ripple(220, 0.18),
                    Container(
                      width: 185, height: 185,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 20, spreadRadius: 4, offset: const Offset(0, 10))],
                        gradient: const RadialGradient(colors: [Color(0xFFFA6A6A), Color(0xFFD32F2F)]),
                        border: Border.all(color: Colors.white24, width: 2.5),
                      ),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("SOS", style: TextStyle(color: Colors.white, fontSize: 56, fontWeight: FontWeight.bold)),
                          Text("HOLD TO TRIGGER", style: TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const Spacer(),

            // ACTION BUTTONS SECTION
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const SafetyTimerScreen())), child: _btmBtn(Icons.directions_walk_rounded, "Safe Walk")),
                      GestureDetector(onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const GuardianModeScreen())), child: _btmBtn(Icons.verified_user_rounded, "Guardians")),
                    ],
                  ),
                  
                  const SizedBox(height: 25),

                  // ADMIN SPECIAL BUTTON (මෙය පෙනෙන්නේ ඇඩ්මින් ලොග් වුණොත් පමණි)
                  if (_userRole == 'admin') 
                    GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const AdminFullDashboard())),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        width: double.infinity,
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.8),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.redAccent, width: 1.5),
                          boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10)],
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.admin_panel_settings_rounded, color: Colors.white, size: 26),
                            SizedBox(width: 12),
                            Text("ADMIN COMMAND CENTER", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                      ),
                    ),
                  
                  const SizedBox(height: 40),
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
          Text(l, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _locationSyncTimer?.cancel();
    _globalAlertsSub?.cancel();
    super.dispose();
  }
}