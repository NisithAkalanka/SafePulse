import 'package:flutter/material.dart';
// නිවැරදි පෑත් එක: පෝල්ඩරයෙන් එකක් පස්සට (..) ගොස් සෙවිය යුතුය
import '../navigation_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F13),
      body: Stack(
        children: [
          // 1. Page Content
          PageView(
            controller: _controller,
            onPageChanged: (index) => setState(() => _currentPage = index),
            children: [
              _buildPage(
                title: "SafePulse Shield",
                description:
                    "Experience advanced campus-wide emergency monitoring and response.",
                icon: Icons.shield_moon_rounded,
              ),
              _buildPage(
                title: "Live Circle Tracking",
                description:
                    "Instantly alert your trusted circle and see their live nodes on map.",
                icon: Icons.radar_rounded,
              ),
            ],
          ),

          // 2. Dots & Button Navigation
          Positioned(
            bottom: 65,
            left: 20,
            right: 20,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(2, (index) => _buildDot(index)),
                ),
                const SizedBox(height: 35),
                ElevatedButton(
                  onPressed: () {
                    if (_currentPage == 1) {
                      // සාර්ථකව මීළඟ පිටුවට යෑම
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MainNavigationScreen(),
                        ),
                      );
                    } else {
                      // තිරය ලිස්සා යෑමේ logic එක නිවැරදි කරන ලදී
                      _controller.nextPage(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF8A0B0B),
                    minimumSize: const Size(double.infinity, 58),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 10,
                  ),
                  child: Text(
                    _currentPage == 1 ? "ACTIVATE SYSTEM" : "NEXT STEP",
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage({
    required String title,
    required String description,
    required IconData icon,
  }) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFA3A3A), Color(0xFF8A0B0B), Color(0xFF0F0F13)],
          stops: [0.0, 0.45, 1.0],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.05),
              border: Border.all(color: Colors.white.withOpacity(0.12)),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20),
              ],
            ),
            child: Icon(icon, size: 85, color: Colors.white),
          ),
          const SizedBox(height: 50),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 45),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 15,
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: 8,
      width: _currentPage == index ? 24 : 8,
      margin: const EdgeInsets.only(right: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        color: _currentPage == index ? Colors.white : Colors.white24,
      ),
    );
  }
}
