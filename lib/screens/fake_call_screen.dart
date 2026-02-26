import 'dart:async';
import 'package:flutter/material.dart';

class FakeCallScreen extends StatefulWidget {
  final String callerName;
  const FakeCallScreen({super.key, this.callerName = "Home (Dad)"});

  @override
  State<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen> {
  bool _isRinging = false;
  int _timerValue = 10; // තත්පර 10කින් call එක එනවා
  Timer? _startTimer;

  @override
  void initState() {
    super.initState();
    _initiateCountdown();
  }

  void _initiateCountdown() {
    _startTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerValue > 0) {
        setState(() {
          _timerValue--;
        });
      } else {
        setState(() {
          _isRinging = true;
        });
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isRinging) {
      return _buildIncomingCallUI();
    } else {
      return _buildCountdownUI();
    }
  }

  // 1. Call එක එන්න කලින් පෙන්වන Countdown Screen එක
  Widget _buildCountdownUI() {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.ring_volume, size: 80, color: Colors.greenAccent),
            const SizedBox(height: 20),
            const Text(
              "Fake Call will trigger in...",
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
            const SizedBox(height: 20),
            Text(
              "$_timerValue",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 80,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                _startTimer?.cancel();
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text(
                "CANCEL",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 2. සැබෑ iPhone Call එකක් වගේ පේන Screen එක
  Widget _buildIncomingCallUI() {
    return Scaffold(
      backgroundColor: const Color(0xFF1B1B1B),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          const CircleAvatar(
            radius: 50,
            backgroundColor: Colors.grey,
            child: Icon(Icons.person, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text(
            widget.callerName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 35,
              fontWeight: FontWeight.w400,
            ),
          ),
          const Text(
            "SafePulse Guard Service",
            style: TextStyle(color: Colors.white60, fontSize: 16),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(50.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _callActionButton(
                  Icons.close,
                  "Decline",
                  Colors.red,
                  () => Navigator.pop(context),
                ),
                _callActionButton(
                  Icons.check,
                  "Accept",
                  Colors.green,
                  () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _callActionButton(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap,
  ) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: CircleAvatar(
            radius: 35,
            backgroundColor: color,
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 13)),
      ],
    );
  }

  @override
  void dispose() {
    _startTimer?.cancel();
    super.dispose();
  }
}
