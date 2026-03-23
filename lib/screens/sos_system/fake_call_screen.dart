import 'dart:async';
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
        if (mounted) {
          setState(() {
            _timerValue--;
          });
        }
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
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color pageBg = isDark
        ? const Color(0xFF121217)
        : const Color(0xFFF6F7FB);
    return Scaffold(
      backgroundColor: pageBg,
      body: _isRinging ? _buildIncomingCallUI() : _buildCountdownUI(),
    );
  }

  // --- Redesigned countdown UI with Dark Mode and scrolling header ---
  Widget _buildCountdownUI() {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color cardBg = isDark ? const Color(0xFF1B1B22) : Colors.white;
    final Color textPrimary = isDark ? Colors.white : const Color(0xFF1B1B22);
    final Color textSecondary = isDark
        ? const Color(0xFFB7BBC6)
        : const Color(0xFF747A86);
    final Color softBg = isDark
        ? const Color(0xFF23232B)
        : const Color(0xFFF9FAFC);

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 72, 18, 28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: isDark
                      ? const [
                          Color(0xFFFF3B3B),
                          Color(0xFFE10613),
                          Color(0xFFB30012),
                          Color(0xFF140910),
                        ]
                      : const [
                          Color(0xFFFF4B4B),
                          Color(0xFFB31217),
                          Color(0xFF1B1B1B),
                        ],
                  stops: isDark
                      ? const [0.0, 0.35, 0.72, 1.0]
                      : const [0.0, 0.62, 1.0],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(34),
                  bottomRight: Radius.circular(34),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.18),
                        width: 1.2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.white.withOpacity(0.14),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.18),
                            ),
                          ),
                          child: const Icon(
                            Icons.ring_volume_rounded,
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
                                "Protective Fake Call",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 17,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                "SafePulse will trigger a realistic incoming call in a few seconds.",
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
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: cardBg,
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
                      mainAxisSize: MainAxisSize.min,
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
                            Icons.phone_in_talk_rounded,
                            size: 46,
                            color: Color(0xFFB31217),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Text(
                          "Triggering Protective Fake Call",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Incoming call from ${widget.callerName} will start automatically.",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: textSecondary,
                            fontWeight: FontWeight.w600,
                            height: 1.35,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 18,
                          ),
                          decoration: BoxDecoration(
                            color: softBg,
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF4A2D31)
                                  : const Color(0xFFFFD6D6),
                            ),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Column(
                            children: [
                              Text(
                                "Starting In",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "$_timerValue",
                                style: const TextStyle(
                                  color: Color(0xFFB31217),
                                  fontSize: 54,
                                  height: 1,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "seconds",
                                style: TextStyle(
                                  fontSize: 13,
                                  color: textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth < 360) {
                              return Column(
                                children: [
                                  _infoMiniCard(
                                    Icons.person_outline,
                                    "Caller",
                                    widget.callerName,
                                  ),
                                  const SizedBox(height: 10),
                                  _infoMiniCard(
                                    Icons.security_rounded,
                                    "Mode",
                                    "SafeCall",
                                  ),
                                ],
                              );
                            }
                            return Row(
                              children: [
                                Expanded(
                                  child: _infoMiniCard(
                                    Icons.person_outline,
                                    "Caller",
                                    widget.callerName,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _infoMiniCard(
                                    Icons.security_rounded,
                                    "Mode",
                                    "SafeCall",
                                  ),
                                ),
                              ],
                            );
                          },
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
                            onPressed: _stopAndDismiss,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              minimumSize: const Size(double.infinity, 56),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text(
                              "CANCEL FAKE CALL",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _realCallActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.10),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _endCallButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color,
              boxShadow: const [
                BoxShadow(
                  color: Color(0x22000000),
                  blurRadius: 14,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 34),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // --- Redesigned full-screen incoming call UI ---
  Widget _buildIncomingCallUI() {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1F2733), Color(0xFF0E1218), Color(0xFF05070A)],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 34),
          child: Column(
            children: [
              const SizedBox(height: 8),
              const Text(
                "Incoming call",
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 34),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.10),
                    width: 1.5,
                  ),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x22000000),
                      blurRadius: 18,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: const Icon(Icons.person, size: 64, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Text(
                widget.callerName,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 34,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                "mobile",
                style: TextStyle(
                  color: Colors.white60,
                  fontSize: 18,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const Spacer(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _realCallActionButton(
                    icon: Icons.message_outlined,
                    label: "Message",
                    onTap: () {},
                  ),
                  _realCallActionButton(
                    icon: Icons.alarm,
                    label: "Remind Me",
                    onTap: () {},
                  ),
                ],
              ),
              const SizedBox(height: 42),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _endCallButton(
                    icon: Icons.call_end,
                    label: "Decline",
                    color: const Color(0xFFE53935),
                    onTap: _stopAndDismiss,
                  ),
                  _endCallButton(
                    icon: Icons.call,
                    label: "Accept",
                    color: const Color(0xFF34C759),
                    onTap: _stopAndDismiss,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoMiniCard(IconData icon, String label, String value) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF23232B) : const Color(0xFFF9FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF34343F) : const Color(0xFFE8EAF0),
        ),
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
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? const Color(0xFFB7BBC6) : const Color(0xFF747A86),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.white : const Color(0xFF1B1B22),
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose(); // මතකය පිරිසිදු කර ශබ්දය නවත්වයි
    _startTimer?.cancel();
    super.dispose();
  }
}
