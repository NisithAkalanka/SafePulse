import 'dart:async';
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

class _SafetyTimerScreenState extends State<SafetyTimerScreen> {
  int _secondsRemaining = 0;
  Timer? _timer;
  bool _isTimerRunning = false;
  int _selectedMinutes = 10; // Default තෝරාගත් විනාඩි ගණන

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
        title: const Text("⚠️ EMERGENCY ACTIVE", style: TextStyle(color: Colors.white)),
        content: const Text(
          "Your check-in timer has expired. Your location and alert have been sent to the SafePulse Network.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("UNDERSTOOD"),
          )
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
                    TextButton(onPressed: () => Navigator.pop(context), child: const Text("Cancel")),
                    const Text("Set Custom Duration", style: TextStyle(fontWeight: FontWeight.bold)),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Done", style: TextStyle(fontWeight: FontWeight.bold)),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Safe Arrival Timer"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        padding: const EdgeInsets.all(30),
        width: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!_isTimerRunning) ...[
              const Icon(Icons.directions_walk_rounded, size: 80, color: Colors.blueGrey),
              const SizedBox(height: 20),
              const Text(
                "Set Your Expected Arrival Time",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                  padding: const EdgeInsets.symmetric(horizontal: 25, vertical: 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.redAccent.withOpacity(0.5)),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.timer_outlined, color: Colors.redAccent, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        "Selected: $_selectedMinutes Minutes", 
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: () => _startTimer(_selectedMinutes),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  minimumSize: const Size(double.infinity, 55),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                  elevation: 2,
                ),
                child: const Text("START MONITORING ME", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              ),

              const SizedBox(height: 20),

              // --- FIXED OVERFLOW SECTION ---
              // Row එක වෙනුවට Wrap භාවිතා කර ඇති නිසා දැන් බොත්තම් ඉඩකඩ අනුව සැකසෙයි
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8.0, // බොත්තම් අතර තිරස් පරතරය
                runSpacing: 8.0, // බොත්තම් අතර සිරස් පරතරය (ඊළඟ පේළියට ගියහොත්)
                children: [
                  _quickSelect(1, "1min (Test)"),
                  _quickSelect(10, "10min"),
                  _quickSelect(30, "30min"),
                ],
              ),
            ] else ...[
              // --- Timer Running UI ---
              const Icon(Icons.security, size: 100, color: Colors.red),
              const SizedBox(height: 20),
              Text(
                "${(_secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}",
                style: const TextStyle(fontSize: 80, fontWeight: FontWeight.bold, color: Colors.black87),
              ),
              const SizedBox(height: 10),
              const Text(
                "SAFETY MONITORING ACTIVE", 
                style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, letterSpacing: 1.2)
              ),
              
              const SizedBox(height: 60),

              ElevatedButton(
                onPressed: _stopTimer,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  minimumSize: const Size(double.infinity, 65),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                ),
                child: const Text("I AM SAFE - CHECK IN ✅", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 20),
              const Text("Check-in to cancel the automatic SOS alert.", style: TextStyle(color: Colors.grey)),
            ]
          ],
        ),
      ),
    );
  }

  Widget _quickSelect(int min, String label) {
    bool isSelected = _selectedMinutes == min;
    return OutlinedButton(
      onPressed: () => setState(() => _selectedMinutes = min),
      style: OutlinedButton.styleFrom(
        foregroundColor: isSelected ? Colors.redAccent : Colors.black87,
        side: BorderSide(color: isSelected ? Colors.redAccent : Colors.grey.shade300),
        backgroundColor: isSelected ? Colors.red[50] : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      child: Text(label),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}