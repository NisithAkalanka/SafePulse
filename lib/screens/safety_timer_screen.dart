import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart'; // iOS style picker එක සඳහා
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class SafetyTimerScreen extends StatefulWidget {
  const SafetyTimerScreen({super.key});

  @override
  State<SafetyTimerScreen> createState() => _SafetyTimerScreenState();
}

class _SafetyTimerScreenState extends State<SafetyTimerScreen>
    with SingleTickerProviderStateMixin {
  int _secondsRemaining = 0;
  Timer? _timer;
  bool _isTimerRunning = false;
  int _selectedMinutes = 10; // Default තෝරාගත් විනාඩි ගණන

  late final AnimationController _walkCtrl;
  late final Animation<double> _walkX;
  late final Animation<double> _walkBob;

  @override
  void initState() {
    super.initState();

    _walkCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _walkX = CurvedAnimation(parent: _walkCtrl, curve: Curves.easeInOut);
    _walkBob = Tween<double>(
      begin: 0,
      end: -6,
    ).animate(CurvedAnimation(parent: _walkCtrl, curve: Curves.easeInOut));
  }

  void _startTimer(int minutes) {
    setState(() {
      _secondsRemaining = minutes * 60;
      _isTimerRunning = true;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _triggerAutomaticAlert(); // ටයිමර් එක අවසන් වුණාම Alert එක යයි
        _stopTimer();
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _secondsRemaining = 0;
    });
  }

  // සැබෑ Automatic SOS ලොජික් එක
  Future<void> _triggerAutomaticAlert() async {
    final user = FirebaseAuth.instance.currentUser;
    Position pos = await Geolocator.getCurrentPosition();

    await FirebaseFirestore.instance.collection('alerts').add({
      'type': '🔴 AUTO SOS - Safe Arrival Missed',
      'user_email': user?.email ?? "User",
      'status': 'Safety check-in missed',
      'lat': pos.latitude,
      'lng': pos.longitude,
      'time': FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.red[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "⚠️ EMERGENCY ACTIVE",
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          "Your check-in timer has expired. Your location and alert have been sent to the SafePulse Network.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("UNDERSTOOD"),
          ),
        ],
      ),
    );
  }

  // කැමති වෙලාවක් තෝරන්න එන Scroll Wheel එක
  void _showTimePicker() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 300,
          color: Colors.white,
          child: Column(
            children: [
              Container(
                color: Colors.grey[200],
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                    const Text(
                      "Set Custom Duration",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        "Done",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: CupertinoPicker(
                  itemExtent: 40,
                  onSelectedItemChanged: (index) {
                    setState(() {
                      _selectedMinutes = index + 1; // 1 සිට 60 දක්වා
                    });
                  },
                  children: List<Widget>.generate(60, (index) {
                    return Center(child: Text("${index + 1} Minutes"));
                  }),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF0F0F13),
      appBar: AppBar(
        title: const Text("Safe Arrival Timer"),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFF4B4B),
                  Color(0xFF8A0B0B),
                  Color(0xFF0F0F13),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
          ),
          Positioned(
            top: -140,
            left: -120,
            child: Container(
              width: 360,
              height: 360,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -160,
            right: -120,
            child: Container(
              width: 420,
              height: 420,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.yellowAccent.withOpacity(0.06),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.05),
                      Colors.transparent,
                      Colors.black.withOpacity(0.30),
                    ],
                    stops: const [0.0, 0.4, 1.0],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
              child: Column(
                children: [
                  _walkingHeader(),
                  const SizedBox(height: 14),
                  if (!_isTimerRunning) _walkingAnimation(),
                  if (!_isTimerRunning) const SizedBox(height: 14),

                  Expanded(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: _glassCard(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!_isTimerRunning) ...[
                                const Icon(
                                  Icons.directions_walk_rounded,
                                  size: 80,
                                  color: Colors.blueGrey,
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  "Set Your Expected Arrival Time",
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  "Auto SOS will trigger if you don't check in.",
                                  style: TextStyle(color: Colors.grey),
                                  textAlign: TextAlign.center,
                                ),

                                const SizedBox(height: 40),

                                // Custom Time Picker Button
                                GestureDetector(
                                  onTap: _showTimePicker,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 25,
                                      vertical: 15,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      border: Border.all(
                                        color: Colors.redAccent.withOpacity(
                                          0.5,
                                        ),
                                      ),
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.timer_outlined,
                                          color: Colors.redAccent,
                                          size: 20,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          "Selected: $_selectedMinutes Minutes",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 40),

                                ElevatedButton(
                                  onPressed: () =>
                                      _startTimer(_selectedMinutes),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.redAccent,
                                    minimumSize: const Size(
                                      double.infinity,
                                      55,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                    elevation: 2,
                                  ),
                                  child: const Text(
                                    "START MONITORING ME",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 20),

                                // --- FIXED OVERFLOW SECTION ---
                                // Row එක වෙනුවට Wrap භාවිතා කර ඇති නිසා දැන් බොත්තම් ඉඩකඩ අනුව සැකසෙයි
                                Wrap(
                                  alignment: WrapAlignment.center,
                                  spacing: 8.0, // බොත්තම් අතර තිරස් පරතරය
                                  runSpacing:
                                      8.0, // බොත්තම් අතර සිරස් පරතරය (ඊළඟ පේළියට ගියහොත්)
                                  children: [
                                    _quickSelect(1, "1min (Test)"),
                                    _quickSelect(10, "10min"),
                                    _quickSelect(30, "30min"),
                                  ],
                                ),
                              ] else ...[
                                // --- Timer Running UI ---
                                const Icon(
                                  Icons.security,
                                  size: 100,
                                  color: Colors.red,
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  "${(_secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}",
                                  style: const TextStyle(
                                    fontSize: 80,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                const Text(
                                  "SAFETY MONITORING ACTIVE",
                                  style: TextStyle(
                                    color: Colors.red,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),

                                const SizedBox(height: 60),

                                ElevatedButton(
                                  onPressed: _stopTimer,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green[600],
                                    minimumSize: const Size(
                                      double.infinity,
                                      65,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: const Text(
                                    "I AM SAFE - CHECK IN ✅",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  "Check-in to cancel the automatic SOS alert.",
                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
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
        ],
      ),
    );
  }

  Widget _quickSelect(int min, String label) {
    bool isSelected = _selectedMinutes == min;
    return OutlinedButton(
      onPressed: () => setState(() => _selectedMinutes = min),
      style: OutlinedButton.styleFrom(
        foregroundColor: isSelected ? Colors.redAccent : Colors.black87,
        side: BorderSide(
          color: isSelected ? Colors.redAccent : Colors.grey.shade300,
        ),
        backgroundColor: isSelected ? Colors.red[50] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label),
    );
  }

  Widget _walkingHeader() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                  color: Colors.white.withOpacity(0.12),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: const Icon(
                  Icons.directions_walk_rounded,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Safe Arrival Timer",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      "We’ll auto-alert if you don’t check in.",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: Colors.white.withOpacity(0.14)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.shield_rounded, color: Colors.white, size: 14),
                    SizedBox(width: 6),
                    Text(
                      "Protected",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _walkingAnimation() {
    return SizedBox(
      height: 64,
      child: AnimatedBuilder(
        animation: _walkCtrl,
        builder: (context, child) {
          return Stack(
            children: [
              // Track line
              Align(
                alignment: Alignment.center,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: Colors.white.withOpacity(0.12)),
                  ),
                ),
              ),

              // Moving walker
              Align(
                alignment: Alignment.centerLeft,
                child: Transform.translate(
                  offset: Offset(
                    (MediaQuery.of(context).size.width - 120) * _walkX.value,
                    _walkBob.value,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.18),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.14),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.directions_walk,
                              color: Colors.white,
                              size: 18,
                            ),
                            SizedBox(width: 8),
                            Text(
                              "Walking…",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _glassCard({required Widget child}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.10),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: Colors.white.withOpacity(0.16),
              width: 1.1,
            ),
          ),
          child: child,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _walkCtrl.dispose();
    super.dispose();
  }
}
