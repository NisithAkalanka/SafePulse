import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart'; // ශබ්දය සඳහා මෙය අවශ්‍යයි

class FakeCallScreen extends StatefulWidget {
  final String callerName;
  const FakeCallScreen({super.key, this.callerName = "Home (Dad)"});

  @override
  State<FakeCallScreen> createState() => _FakeCallScreenState();
}

class _FakeCallScreenState extends State<FakeCallScreen> {
  bool _isRinging = false;
  int _timerValue =
      5; // තප්පර 5කින් Call එක ලැබෙන සේ සැකසුවා (ටෙස්ට් කිරීමට ලේසියි)
  Timer? _startTimer;
  final AudioPlayer _audioPlayer =
      AudioPlayer(); // Audio Player එක සූදානම් කරමු

  @override
  void initState() {
    super.initState();
    _initiateCountdown();
  }

  // 1. කාලය ගණනය කිරීම පටන් ගමු
  void _initiateCountdown() {
    _startTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timerValue > 0) {
        if (mounted)
          setState(() {
            _timerValue--;
          });
      } else {
        if (mounted) {
          setState(() {
            _isRinging = true;
          });
          _playRingtone(); // ටයිමරය ඉවර වූ සැණින් සද්දය ප්ලේ වේ
        }
        timer.cancel();
      }
    });
  }

  // 2. රින්ග්ටෝනය වාදනය කිරීම (Looping)
  Future<void> _playRingtone() async {
    try {
      await _audioPlayer.setReleaseMode(
        ReleaseMode.loop,
      ); // Call එක ගන්නකම් සද්දය ඇසෙන්න සලස්වමු
      await _audioPlayer.play(
        AssetSource('sounds/iphone_ringtone.mp3'),
      ); // ඔයාගේ MP3 නම මෙහි දාන්න
    } catch (e) {
      debugPrint("Audio Error: $e");
    }
  }

  // 3. ශබ්දය නවතා පේජ් එකෙන් පිටවී යෑම
  void _stopAndDismiss() {
    _audioPlayer.stop(); // ශබ්දය වහාම නවත්වමු
    _startTimer?.cancel();
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13), // Premium Dark background
      body: _isRinging ? _buildIncomingCallUI() : _buildCountdownUI(),
    );
  }

  // --- කවුන්ටවුන් එක පෙන්වන Screen එක (Glass Effect) ---
  Widget _buildCountdownUI() {
    return Stack(
      children: [
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.ring_volume,
                size: 80,
                color: Colors.greenAccent,
              ),
              const SizedBox(height: 24),
              const Text(
                "Triggering Protective Fake Call",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Starting in $_timerValue...",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 60),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  minimumSize: const Size(200, 55),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text(
                  "CANCEL",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- සැබෑ iPhone එකක් මෙන් පෙනෙන Call Screen එක ---
  Widget _buildIncomingCallUI() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF2C3E50),
            Color(0xFF000000),
          ], // Real iOS dark caller style
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 100),
          const CircleAvatar(
            radius: 45,
            backgroundColor: Colors.white12,
            child: Icon(Icons.person, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 20),
          Text(
            widget.callerName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "SafePulse SafeConnect Active",
            style: TextStyle(
              color: Colors.blueAccent,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 50, vertical: 80),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _callActionButton(
                  Icons.call_end,
                  "Decline",
                  Colors.red,
                  _stopAndDismiss,
                ),
                _callActionButton(
                  Icons.call,
                  "Accept",
                  Colors.green,
                  _stopAndDismiss,
                ),
              ],
            ),
          ),
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
          child: Container(
            width: 75,
            height: 75,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color),
            child: Icon(icon, color: Colors.white, size: 35),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); // මතකය පිරිසිදු කර ශබ්දය නවත්වයි
    _startTimer?.cancel();
    super.dispose();
  }
}
