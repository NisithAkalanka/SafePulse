import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shake/shake.dart'; // ✅ SHAKE import

import 'main_menu_screen.dart';
import 'profile_screen.dart';
import 'login_screen.dart';
import 'safety_timer_screen.dart';
import 'guardian_mode_screen.dart';
import 'alerts_hub_screen.dart';
import 'admin_full_dashboard.dart';
import 'fake_call_screen.dart';
import '../help_private_chat_screen.dart';
import '../../services/notification_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  String _currentAddress = "Detecting location...";
  Position? _currentPosition;
  String _userRole = "student";
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _globalAlertsSub;
  Timer? _locationSyncTimer;
  StreamSubscription<User?>? _authSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _myAlertSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _userDocSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _helpOfferSub;
  final Set<String> _seenHelpOfferNotifications = <String>{};

  late final AnimationController _sosFlashController;
  late final Animation<double> _sosFlashOpacity;

  // --- SHAKE TRIGGER VARIABLES ---
  ShakeDetector? _shakeDetector;
  bool _shakeEnabled = true; // Firestore field: shake_enabled

  Map<String, bool> _sosCategories = {
    "🚨 Medical Emergency": true,
    "⚠️ Threat / Hazard": true,
    "💥 Accident / Crash": true,
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _sosFlashController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 380),
    );
    _sosFlashOpacity = Tween<double>(begin: 0.0, end: 0.20).animate(
      CurvedAnimation(parent: _sosFlashController, curve: Curves.easeOut),
    );

    _getCurrentLocation();
    _listenForGlobalAlerts();
    _listenForHelpOfferNotifications();
    _loadUserStatus();
    _listenToUserSettings();
    _startLiveLocationSync();

    _initShakeDetection(); // ✅ start shake detection

    // When user logs in/out, reload role so admin button shows correctly
    _authSub = FirebaseAuth.instance.authStateChanges().listen((u) {
      if (!mounted) return;
      if (u == null) {
        _userDocSub?.cancel();
        _helpOfferSub?.cancel();
        _helpOfferSub = null;
        _seenHelpOfferNotifications.clear();
        setState(() {
          _userRole = 'student';
          _shakeEnabled = true;
          _sosCategories = {
            "🚨 Medical Emergency": true,
            "⚠️ Threat / Hazard": true,
            "💥 Accident / Crash": true,
          };
        });
      } else {
        _listenForHelpOfferNotifications();
        _loadUserStatus();
        _listenToUserSettings();
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkProfileStatus();
    });
  }

  void _listenToUserSettings() {
    _userDocSub?.cancel();

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    _userDocSub = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .snapshots()
        .listen((doc) {
          if (!mounted || !doc.exists) return;
          final data = doc.data();
          if (data == null) return;

          setState(() {
            _userRole = (data['role'] ?? 'student').toString();
            _shakeEnabled = data['shake_enabled'] ?? true;
            if (data['sos_categories'] != null) {
              _sosCategories = Map<String, bool>.from(data['sos_categories']);
            }
          });
        });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _loadUserStatus();
      _listenToUserSettings();
    }
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

  // --- 🎯 SHAKE DETECTION LOGIC ---
  // the detector callback used to be `void Function()`; newer
  // versions supply a value, so accept an optional parameter and
  // ignore it.
  void _onShakeAction([dynamic _]) {
    if (_shakeEnabled) {
      _showShakeConfirmationDialog();
    }
  }

  // 2. ShakeDetector එක හදන හැටි (මෙතනයි Error එක තිබුණේ)
  void _initShakeDetection() {
    _shakeDetector = ShakeDetector.autoStart(
      // the callback now takes an argument; our handler accepts
      // an optional one, so we can pass it directly.
      onPhoneShake: _onShakeAction,
      shakeThresholdGravity: 2.7,
    );
  }

  void _showShakeConfirmationDialog() {
    if (!mounted) return;

    int countdown = 3;
    Timer? countdownTimer;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            countdownTimer ??= Timer.periodic(const Duration(seconds: 1), (
              timer,
            ) {
              if (countdown > 1) {
                setDialogState(() {
                  countdown--;
                });
              } else {
                timer.cancel();
                Navigator.pop(context);
                _sendToFirebase("🆘 SHAKE DETECTED (EMERGENCY)");
              }
            });

            return AlertDialog(
              backgroundColor: Colors.red[900],
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                "SHAKE DETECTED!",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "An emergency alert is being dispatched automatically.",
                    style: TextStyle(color: Colors.white70),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "$countdown",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 50,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    countdownTimer?.cancel();
                    Navigator.pop(context);
                  },
                  child: const Text(
                    "CANCEL",
                    style: TextStyle(
                      color: Colors.yellow,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      countdownTimer?.cancel();
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
          _shakeEnabled =
              doc.data()?['shake_enabled'] ?? true; // ✅ load shake setting
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

      // Cancel previous personal alert listener before creating a new one
      await _myAlertSub?.cancel();
      _myAlertSub = null;

      final DocumentReference<Map<String, dynamic>> alertRef =
          await FirebaseFirestore.instance.collection('alerts').add({
            'type': type,
            'user_email': user?.email ?? "Guest Mode",
            'uid': user?.uid ?? "anonymous",
            'lat': _currentPosition?.latitude,
            'lng': _currentPosition?.longitude,
            'address': _currentAddress,
            'time': FieldValue.serverTimestamp(),
            'status': 'New',
            'acceptedBy': null,
            'helper_uid': null,
            'helper_name': null,
          });

      NotificationService.showSOSNotification(type, _currentAddress);

      // Victim listens in real time for this exact alert document
      _myAlertSub = alertRef.snapshots().listen((snapshot) {
        if (!snapshot.exists) return;
        final data = snapshot.data();
        if (data == null) return;

        // When someone accepts the help request
        if (data['status'] == 'Accepted' && data['helper_name'] != null) {
          final String helperName = data['helper_name'].toString();

          // 1. Show system notification
          NotificationService.showSOSNotification(
            "HELP IS ON THE WAY!",
            "$helperName has accepted your request and is coming now.",
          );

          // 2. Show in-app dialog
          _showHelperComingDialog(helperName);
        }
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "🆘 $type Dispatching Help!",
            style: const TextStyle(color: Colors.black),
          ),
          backgroundColor: Colors.white,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
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
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.55,
            minChildSize: 0.35,
            maxChildSize: 0.9,
            builder: (context, scrollController) {
              return Container(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
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
                    const SizedBox(height: 14),
                    const Text(
                      "Emergency Type",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: ListView(
                        controller: scrollController,
                        padding: EdgeInsets.zero,
                        children: [
                          ...activeTypes.map(
                            (type) => ListTile(
                              leading: const Icon(
                                Icons.flash_on,
                                color: Colors.redAccent,
                              ),
                              title: Text(type),
                              onTap: () {
                                Navigator.pop(context);
                                _sendToFirebase(type);
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
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
              final isMine =
                  alertData?['uid'] == FirebaseAuth.instance.currentUser?.uid;
              final isNew = (alertData?['status'] ?? 'New') == 'New';
              if (!isMine && isNew) {
                _showEmergencyAlert(
                  alertData?['type'] ?? 'Emergency',
                  alertData?['address'] ?? 'Nearby',
                );
              }
            }
          }
        });
  }

  void _listenForHelpOfferNotifications() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    _helpOfferSub?.cancel();
    _helpOfferSub = FirebaseFirestore.instance
        .collection('help_offer_notifications')
        .where('recipientUid', isEqualTo: uid)
        .snapshots()
        .listen((snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type != DocumentChangeType.added) continue;
        final data = change.doc.data();
        if (data == null) continue;
        if (data['accepted'] == true) continue;
        if (_seenHelpOfferNotifications.contains(change.doc.id)) continue;
        _seenHelpOfferNotifications.add(change.doc.id);
        _showHelperOfferDialog(change.doc.id, data);
      }
    });
  }

  void _showHelperOfferDialog(String notificationId, Map<String, dynamic> data) {
    if (!mounted) return;
    final helperName = (data['helperName'] ?? 'A helper').toString();
    final category = (data['requestCategory'] ?? 'Help request').toString();
    final requestTitle = (data['requestTitle'] ?? '').toString();
    final location = (data['requestLocationName'] ?? 'Nearby').toString();
    final requestId = (data['requestId'] ?? '').toString();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.green[50],
        title: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.green),
            SizedBox(width: 10),
            Text("Helper Ready"),
          ],
        ),
        content: Text(
          "$helperName is ready to help.\n\n$category\n$requestTitle\n📍 $location",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Later"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              if (requestId.isNotEmpty) {
                await FirebaseFirestore.instance
                    .collection('alerts')
                    .doc(requestId)
                    .set({
                  'status': 'Accepted',
                  'acceptedBy': helperName,
                  'helper_uid': data['helperUid'],
                  'helper_name': helperName,
                  'accepted_at': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
              }
              await FirebaseFirestore.instance
                  .collection('help_offer_notifications')
                  .doc(notificationId)
                  .set({
                'accepted': true,
                'acceptedAt': FieldValue.serverTimestamp(),
                'read': true,
                'readAt': FieldValue.serverTimestamp(),
              }, SetOptions(merge: true));
              if (!mounted) return;
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      HelpPrivateChatScreen(title: category, subtitle: requestTitle),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Accept"),
          ),
        ],
      ),
    );
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

  void _showHelperComingDialog(String helperName) {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: Colors.green[50],
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: Colors.green),
            SizedBox(width: 10),
            Text("HELP IS COMING!"),
          ],
        ),
        content: Text(
          "$helperName has accepted your emergency request and is on the way. Keep calm!",
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
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

  Future<void> _triggerSOSPressEffect() async {
    try {
      await _sosFlashController.forward(from: 0);
      await _sosFlashController.reverse();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF1C2230)
          : const Color(0xFFF6C9D1),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "SafePulse",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
              Icons.more_vert_rounded,
              color: Colors.white,
              size: 30,
            ),
            onPressed: () {
              Navigator.of(context).push(
                PageRouteBuilder(
                  opaque: false,
                  barrierDismissible: true,
                  barrierColor: Colors.transparent,
                  pageBuilder: (context, animation, secondaryAnimation) =>
                      const MainMenuScreen(),
                  transitionsBuilder:
                      (context, animation, secondaryAnimation, child) {
                        final curved = CurvedAnimation(
                          parent: animation,
                          curve: Curves.easeOutCubic,
                        );
                        return FadeTransition(
                          opacity: curved,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.12, 0),
                              end: Offset.zero,
                            ).animate(curved),
                            child: child,
                          ),
                        );
                      },
                ),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? const [
                        Color(0xFFFF3B3B),
                        Color(0xFFE10613),
                        Color(0xFFB30012),
                        Color(0xFF7A000D),
                        Color(0xFF1A0005),
                      ]
                    : const [
                        Color(0xFFFF5968),
                        Color(0xFFF29AA8),
                        Color(0xFFF4C2CB),
                      ],
                stops: isDark
                    ? const [0.0, 0.25, 0.55, 0.80, 1.0]
                    : const [0.0, 0.42, 1.0],
              ),
            ),
          ),
          Positioned(
            top: -120,
            right: -60,
            child: IgnorePointer(
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      (isDark
                              ? const Color(0xFFFF8A80)
                              : const Color(0xFFFFE3E8))
                          .withOpacity(isDark ? 0.07 : 0.18),
                ),
              ),
            ),
          ),
          Positioned(
            top: 180,
            left: -90,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      (isDark
                              ? const Color(0xFF3D0008)
                              : const Color(0xFFD96A78))
                          .withOpacity(isDark ? 0.24 : 0.14),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Container(
                height: 170,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.elliptical(260, 58),
                    topRight: Radius.elliptical(260, 58),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: isDark
                        ? const [
                            Color(0xFFFF5A5F),
                            Color(0xFFE10613),
                            Color(0xFF7A000D),
                            Color(0x001A0005),
                          ]
                        : const [
                            Color(0xFFFF5463),
                            Color(0xFFFF8D99),
                            Color(0x00FFFFFF),
                          ],
                    stops: isDark
                        ? const [0.0, 0.22, 0.65, 1.0]
                        : const [0.0, 0.24, 1.0],
                  ),
                ),
              ),
            ),
          ),
          IgnorePointer(
            child: AnimatedBuilder(
              animation: _sosFlashOpacity,
              builder: (context, child) {
                return Container(
                  color:
                      (isDark
                              ? const Color(0xFFFF2D3D)
                              : const Color(0xFFFF6678))
                          .withOpacity(
                            isDark
                                ? _sosFlashOpacity.value * 1.15
                                : _sosFlashOpacity.value,
                          ),
                );
              },
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                        children: [
                          const SizedBox(height: 60),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 18),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(26),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.16),
                                width: 1.1,
                              ),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: Colors.white.withOpacity(0.10),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.16),
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
                                          fontWeight: FontWeight.w700,
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
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 7,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.10),
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.16),
                                    ),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.cloud_done,
                                        color: Colors.white,
                                        size: 13,
                                      ),
                                      SizedBox(width: 5),
                                      Text(
                                        "Cloud Sync",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Padding(
                            padding: EdgeInsets.fromLTRB(28, 0, 28, 0),
                            child: Text(
                              "Shake your phone or hold SOS for instant help — your guardians will be notified.",
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                height: 1.35,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: GestureDetector(
                              onLongPressStart: (_) {
                                HapticFeedback.heavyImpact();
                                _triggerSOSPressEffect();
                              },
                              onLongPress: () {
                                HapticFeedback.vibrate();
                                _showSOSOptions();
                              },
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  _ripple(300, 0.05),
                                  _ripple(255, 0.085),
                                  _ripple(215, 0.12),
                                  Container(
                                    width: 176,
                                    height: 176,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white.withOpacity(0.22),
                                        width: 2.2,
                                      ),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x33D3192A),
                                          blurRadius: 28,
                                          spreadRadius: 6,
                                          offset: Offset(0, 12),
                                        ),
                                      ],
                                      gradient: const RadialGradient(
                                        colors: [
                                          Color(0xFFFF6B74),
                                          Color(0xFFE11928),
                                          Color(0xFF95000E),
                                        ],
                                        stops: [0.0, 0.60, 1.0],
                                      ),
                                    ),
                                    child: Container(
                                      margin: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.04),
                                      ),
                                      child: const Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text(
                                            "SOS",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 50,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                          SizedBox(height: 3),
                                          Text(
                                            "PRESS & HOLD",
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Padding(
                            padding: EdgeInsets.fromLTRB(
                              16,
                              0,
                              16,
                              MediaQuery.of(context).padding.bottom > 0
                                  ? 10
                                  : 8,
                            ),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(
                                14,
                                10,
                                14,
                                10,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(26),
                                border: Border.all(
                                  color: Colors.white.withOpacity(0.16),
                                  width: 1.1,
                                ),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Color(0x16000000),
                                    blurRadius: 18,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Container(
                                    width: 40,
                                    height: 4,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.24),
                                      borderRadius: BorderRadius.circular(99),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  StreamBuilder<User?>(
                                    stream: FirebaseAuth.instance
                                        .authStateChanges(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        return Column(
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: GestureDetector(
                                                    onTap: () => Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            const SafetyTimerScreen(),
                                                      ),
                                                    ),
                                                    child: _quickActionBtn(
                                                      Icons
                                                          .directions_walk_rounded,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: GestureDetector(
                                                    onTap: () {
                                                      TextEditingController
                                                      pinController =
                                                          TextEditingController();
                                                      showDialog(
                                                        context: context,
                                                        barrierDismissible:
                                                            false,
                                                        builder: (dialogContext) => AlertDialog(
                                                          title: const Text(
                                                            "Enter App PIN",
                                                          ),
                                                          content: TextField(
                                                            controller:
                                                                pinController,
                                                            keyboardType:
                                                                TextInputType
                                                                    .number,
                                                            obscureText: true,
                                                            textAlign: TextAlign
                                                                .center,
                                                            maxLength: 4,
                                                            decoration:
                                                                const InputDecoration(
                                                                  hintText:
                                                                      "****",
                                                                  border:
                                                                      OutlineInputBorder(),
                                                                ),
                                                          ),
                                                          actions: [
                                                            TextButton(
                                                              onPressed: () =>
                                                                  Navigator.pop(
                                                                    dialogContext,
                                                                  ),
                                                              child: const Text(
                                                                "CANCEL",
                                                              ),
                                                            ),
                                                            ElevatedButton(
                                                              onPressed: () async {
                                                                final user =
                                                                    FirebaseAuth
                                                                        .instance
                                                                        .currentUser;
                                                                if (user ==
                                                                    null) {
                                                                  Navigator.pop(
                                                                    dialogContext,
                                                                  );
                                                                  Navigator.push(
                                                                    context,
                                                                    MaterialPageRoute(
                                                                      builder:
                                                                          (
                                                                            context,
                                                                          ) =>
                                                                              const LoginScreen(),
                                                                    ),
                                                                  );
                                                                  return;
                                                                }

                                                                final doc = await FirebaseFirestore
                                                                    .instance
                                                                    .collection(
                                                                      'users',
                                                                    )
                                                                    .doc(
                                                                      user.uid,
                                                                    )
                                                                    .get();

                                                                if (pinController
                                                                        .text ==
                                                                    doc.data()?['app_pin']) {
                                                                  Navigator.pop(
                                                                    dialogContext,
                                                                  );
                                                                  Future.delayed(
                                                                    const Duration(
                                                                      milliseconds:
                                                                          100,
                                                                    ),
                                                                    () {
                                                                      if (!mounted) {
                                                                        return;
                                                                      }
                                                                      Navigator.push(
                                                                        context,
                                                                        MaterialPageRoute(
                                                                          builder:
                                                                              (
                                                                                context,
                                                                              ) => const GuardianModeScreen(),
                                                                        ),
                                                                      );
                                                                    },
                                                                  );
                                                                } else {
                                                                  if (!mounted) {
                                                                    return;
                                                                  }
                                                                  ScaffoldMessenger.of(
                                                                    context,
                                                                  ).showSnackBar(
                                                                    const SnackBar(
                                                                      content: Text(
                                                                        "Wrong PIN!",
                                                                      ),
                                                                      backgroundColor:
                                                                          Colors
                                                                              .red,
                                                                    ),
                                                                  );
                                                                }
                                                              },
                                                              child: const Text(
                                                                "UNLOCK",
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      );
                                                    },
                                                    child: _quickActionBtn(
                                                      Icons
                                                          .verified_user_rounded,
                                                    ),
                                                  ),
                                                ),
                                                const SizedBox(width: 8),
                                                Expanded(
                                                  child: GestureDetector(
                                                    onTap: () => Navigator.push(
                                                      context,
                                                      MaterialPageRoute(
                                                        builder: (context) =>
                                                            const FakeCallScreen(
                                                              callerName:
                                                                  "Home (Mom)",
                                                            ),
                                                      ),
                                                    ),
                                                    child: _quickActionBtn(
                                                      Icons
                                                          .phone_in_talk_rounded,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            if (_userRole == 'admin') ...[
                                              const SizedBox(height: 12),
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
                                                        vertical: 13,
                                                      ),
                                                  width: double.infinity,
                                                  decoration: BoxDecoration(
                                                    gradient:
                                                        const LinearGradient(
                                                          begin: Alignment
                                                              .topCenter,
                                                          end: Alignment
                                                              .bottomCenter,
                                                          colors: [
                                                            Color(0xFFFF4E5B),
                                                            Color(0xFFD3192A),
                                                          ],
                                                        ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          18,
                                                        ),
                                                    boxShadow: const [
                                                      BoxShadow(
                                                        color: Color(
                                                          0x22D3192A,
                                                        ),
                                                        blurRadius: 14,
                                                        offset: Offset(0, 6),
                                                      ),
                                                    ],
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
                                                      const SizedBox(width: 10),
                                                      Flexible(
                                                        child: FittedBox(
                                                          fit: BoxFit.scaleDown,
                                                          child: const Text(
                                                            "ADMIN COMMAND CENTER",
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: TextStyle(
                                                              color:
                                                                  Colors.white,
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

                                      return const Padding(
                                        padding: EdgeInsets.symmetric(
                                          vertical: 10,
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.lock_outline,
                                              color: Colors.white70,
                                              size: 16,
                                            ),
                                            SizedBox(width: 8),
                                            Flexible(
                                              child: Text(
                                                "Login to enable Safe Walk & Guardians",
                                                textAlign: TextAlign.center,
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w600,
                                                ),
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

  Widget _quickActionBtn(IconData icon) => Container(
    height: 72,
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.96),
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x12000000),
          blurRadius: 10,
          offset: Offset(0, 4),
        ),
      ],
    ),
    child: Center(child: Icon(icon, color: const Color(0xFFD3192A), size: 28)),
  );

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _userDocSub?.cancel();
    _shakeDetector?.stopListening(); // ✅ stop shake
    _globalAlertsSub?.cancel();
    _helpOfferSub?.cancel();
    _locationSyncTimer?.cancel();
    _authSub?.cancel();
    _myAlertSub?.cancel();
    _sosFlashController.dispose();
    super.dispose();
  }
}

// ===============================
// Phase 3: App Security Lock (PIN)
// NOTE: You can move this block into `lib/services/security_check.dart` later.
// ===============================

class SecurityCheck {
  static Future<void> validateAccess(
    BuildContext context,
    VoidCallback onSuccess,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    // If user has set an app PIN, force the PIN dialog before allowing access
    final appPin = doc.data()?['app_pin'];
    if (doc.exists && appPin != null && appPin.toString().isNotEmpty) {
      if (!context.mounted) return;

      final bool? isValid = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => const SecurityLockDialog(),
      );

      if (isValid == true) {
        onSuccess();
      }
    } else {
      // If no PIN set, allow directly
      onSuccess();
    }
  }
}

class SecurityLockDialog extends StatefulWidget {
  const SecurityLockDialog({super.key});

  @override
  State<SecurityLockDialog> createState() => _SecurityLockDialogState();
}

class _SecurityLockDialogState extends State<SecurityLockDialog> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      title: const Text("Enter App PIN", textAlign: TextAlign.center),
      content: TextField(
        controller: _ctrl,
        keyboardType: TextInputType.number,
        obscureText: true,
        textAlign: TextAlign.center,
        maxLength: 4,
        decoration: const InputDecoration(
          hintText: "••••",
          border: OutlineInputBorder(),
          counterText: "",
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("CANCEL"),
        ),
        ElevatedButton(
          onPressed: () async {
            final user = FirebaseAuth.instance.currentUser;
            if (user == null) return;

            final doc = await FirebaseFirestore.instance
                .collection('users')
                .doc(user.uid)
                .get();

            final savedPin = (doc.data()?['app_pin'] ?? '').toString();
            if (_ctrl.text == savedPin) {
              if (!context.mounted) return;
              Navigator.pop(context, true);
            } else {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Wrong PIN! Try again.")),
              );
            }
          },
          child: const Text("UNLOCK"),
        ),
      ],
    );
  }
} //ori
