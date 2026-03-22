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
  int _initialTimerSeconds = 0;

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

  // ✅ UPDATED: Firestore update + timer start
  Future<void> _startTimer(int minutes) async {
    final user = FirebaseAuth.instance.currentUser;

    // පද්ධතිය දැනුවත් කරනවා අපි මේ වෙලාවේ "Walk" එකක් පටන් ගත්තා කියලා
    DateTime expectedTime = DateTime.now().add(Duration(minutes: minutes));

    // User logged in නම් Firestore එකට write කරන්න
    if (user != null) {
      try {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'is_on_safe_walk': true,
          'expected_arrival': expectedTime, // සජීවී කාලය
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint("Safe Walk Firestore Update Failed: $e");
      }
    }

    // පෝන් එකේ ඇතුලේ ටයිමරයත් රන් කරනවා:
    setState(() {
      _secondsRemaining = minutes * 60;
      _initialTimerSeconds = minutes * 60;
      _isTimerRunning = true;
    });

    // ... ඉතුරු Timer.periodic logic එක දිගටම දුවන්න දෙන්න ...
    _timer?.cancel();
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

  String _formattedEtaPreview() {
    final eta = DateTime.now().add(Duration(minutes: _selectedMinutes));
    final hour = eta.hour % 12 == 0 ? 12 : eta.hour % 12;
    final minute = eta.minute.toString().padLeft(2, '0');
    final period = eta.hour >= 12 ? 'PM' : 'AM';
    return "$hour:$minute $period";
  }

  Future<void> _extendTimer(int extraMinutes) async {
    final user = FirebaseAuth.instance.currentUser;
    setState(() {
      _secondsRemaining += extraMinutes * 60;
      _initialTimerSeconds += extraMinutes * 60;
    });

    if (user != null) {
      try {
        final expectedTime = DateTime.now().add(
          Duration(seconds: _secondsRemaining),
        );
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'is_on_safe_walk': true,
          'expected_arrival': expectedTime,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint("Safe Walk Extend Failed: $e");
      }
    }

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Timer extended by 5 minutes."),
        backgroundColor: Color(0xFFB31217),
      ),
    );
  }

  void _stopTimer() {
    _timer?.cancel();
    setState(() {
      _isTimerRunning = false;
      _secondsRemaining = 0;
      _initialTimerSeconds = 0;
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
      backgroundColor: const Color(0xFFF6F7FB),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Safe Arrival Timer",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
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
                _walkingHeader(),
                if (!_isTimerRunning) ...[
                  const SizedBox(height: 12),
                  _walkingAnimation(),
                ],
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: !_isTimerRunning
                      ? _buildSetupContent()
                      : _buildActiveContent(),
                ),
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
        foregroundColor: isSelected
            ? const Color(0xFFB31217)
            : const Color(0xFF1B1B22),
        side: BorderSide(
          color: isSelected ? const Color(0xFFB31217) : const Color(0xFFE2E5EC),
        ),
        backgroundColor: isSelected ? const Color(0xFFFFE3E3) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
    );
  }

  Widget _walkingHeader() {
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
            child: const Icon(
              Icons.directions_walk_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Safe Arrival Timer",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Track your walk and auto-alert if you miss check-in.",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.18),
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
    );
  }

  Widget _walkingAnimation() {
    return SizedBox(
      height: 46,
      child: AnimatedBuilder(
        animation: _walkCtrl,
        builder: (context, child) {
          return Stack(
            children: [
              Align(
                alignment: Alignment.center,
                child: Container(
                  height: 6,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Transform.translate(
                  offset: Offset(
                    (MediaQuery.of(context).size.width - 240) * _walkX.value,
                    _walkBob.value,
                  ),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white.withOpacity(0.16)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.directions_walk,
                          color: Colors.white,
                          size: 16,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Walking...",
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
            ],
          );
        },
      ),
    );
  }

  Widget _buildSetupContent() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF4B4B), Color(0xFFB31217)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Color(0x33FFFFFF),
                child: Icon(
                  Icons.timer_outlined,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Arrival Monitoring",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Choose an arrival time and SafePulse will watch over your trip.",
                      style: TextStyle(
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
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
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
            children: [
              Container(
                width: 92,
                height: 92,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFE3E3), Color(0xFFFFF5F5)],
                  ),
                ),
                child: const Icon(
                  Icons.directions_walk_rounded,
                  size: 46,
                  color: Color(0xFFB31217),
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                "Set Your Expected Arrival Time",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1B1B22),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "If you do not check in on time, an automatic SOS alert will be sent.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF747A86),
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 22),
              GestureDetector(
                onTap: _showTimePicker,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFC),
                    border: Border.all(color: const Color(0xFFFFD6D6)),
                    borderRadius: BorderRadius.circular(18),
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
                          Icons.timer_outlined,
                          color: Color(0xFFB31217),
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Selected Duration",
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF747A86),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "$_selectedMinutes Minutes",
                              style: const TextStyle(
                                fontWeight: FontWeight.w900,
                                fontSize: 18,
                                color: Color(0xFF1B1B22),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.edit_calendar_rounded,
                        color: Color(0xFFB31217),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _infoStatCard(
                      Icons.schedule_rounded,
                      "Duration",
                      "$_selectedMinutes min",
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _infoStatCard(
                      Icons.access_time_rounded,
                      "ETA",
                      _formattedEtaPreview(),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _featurePill(
                      Icons.notifications_active_outlined,
                      "Auto SOS backup",
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _featurePill(
                      Icons.location_on_outlined,
                      "Live arrival check",
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFF4B4B), Color(0xFFB31217)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: () => _startTimer(_selectedMinutes),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
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
              ),
              const SizedBox(height: 18),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  _quickSelect(1, "1min (Test)"),
                  _quickSelect(10, "10min"),
                  _quickSelect(30, "30min"),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveContent() {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFFF4B4B), Color(0xFFB31217)],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: const [
              BoxShadow(
                color: Color(0x18000000),
                blurRadius: 16,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: const Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Color(0x33FFFFFF),
                child: Icon(
                  Icons.shield_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Safety Monitoring Active",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      "Check in before the timer ends to stop the automatic SOS.",
                      style: TextStyle(
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
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(22),
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
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFFFFE3E3), Color(0xFFFFF5F5)],
                  ),
                ),
                child: const Icon(
                  Icons.security,
                  size: 48,
                  color: Color(0xFFB31217),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                "${(_secondsRemaining ~/ 60).toString().padLeft(2, '0')}:${(_secondsRemaining % 60).toString().padLeft(2, '0')}",
                style: const TextStyle(
                  fontSize: 58,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF1B1B22),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "SAFETY MONITORING ACTIVE",
                style: TextStyle(
                  color: Color(0xFFB31217),
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.1,
                ),
              ),
              const SizedBox(height: 18),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: _initialTimerSeconds == 0
                      ? 0
                      : _secondsRemaining / _initialTimerSeconds,
                  minHeight: 10,
                  backgroundColor: const Color(0xFFFFE3E3),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFFB31217),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "${((_initialTimerSeconds - _secondsRemaining) / 60).clamp(0, _selectedMinutes).toStringAsFixed(1)} min completed",
                style: const TextStyle(
                  color: Color(0xFF747A86),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _extendTimer(5),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(double.infinity, 54),
                        side: const BorderSide(color: Color(0xFFFFD6D6)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        foregroundColor: const Color(0xFFB31217),
                        backgroundColor: const Color(0xFFFFF5F5),
                      ),
                      icon: const Icon(Icons.add_alarm_rounded, size: 18),
                      label: const Text(
                        "EXTEND 5 MIN",
                        style: TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF21A366), Color(0xFF15803D)],
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 16,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _stopTimer,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    minimumSize: const Size(double.infinity, 62),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    "I AM SAFE - CHECK IN ✅",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _stopTimer,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 52),
                  side: const BorderSide(color: Color(0xFFE2E5EC)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  foregroundColor: const Color(0xFF1B1B22),
                  backgroundColor: Colors.white,
                ),
                icon: const Icon(Icons.close_rounded, size: 18),
                label: const Text(
                  "CANCEL TIMER",
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Check in to cancel the automatic SOS alert.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF747A86),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _infoStatCard(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE8EAF0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFE3E3),
            ),
            child: Icon(icon, color: const Color(0xFFB31217), size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              color: Color(0xFF747A86),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF1B1B22),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _featurePill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFFD6D6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: const Color(0xFFB31217)),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              label,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFFB31217),
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
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

  @override
  void dispose() {
    _timer?.cancel();
    _walkCtrl.dispose();
    super.dispose();
  }
}
