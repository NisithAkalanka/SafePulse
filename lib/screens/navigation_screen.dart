import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// ඔබේ ප්‍රොජෙක්ට් පෝල්ඩරයට අනුව මෙම Imports නිවැරදි බවට වග බලා ගන්න
import 'sos_system/home_screen.dart';
import 'sos_system/guardian_map_screen.dart';
import 'sos_system/admin_full_dashboard.dart';
import 'sos_system/login_screen.dart'; // 💡 අත්‍යවශ්‍යයි
import 'lost_found_system/lost_found_feed_screen.dart';
import 'marketPlace_system/market_home.dart';
import 'help_screen.dart';

// Placeholder (සාමාජිකයින්ගේ ඉතිරි වැඩ සඳහා)
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1B1B22) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.engineering_outlined,
              size: 80,
              color: isDark ? const Color(0xFFB7BBC6) : Colors.grey,
            ),
            const SizedBox(height: 10),
            Text(
              "$title Section",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1B1B22),
              ),
            ),
            const Text(
              "SafePulse: Feature coming soon!",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  final int? initialTabIndex;
  const MainNavigationScreen({super.key, this.initialTabIndex});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;
  String _userRole = 'student';
  bool _initialTabApplied = false;

  @override
  void initState() {
    super.initState();
    _checkUserRole();

    // Login/logout තත්ත්වය සජීවීව බලාගන්න Listener එක
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      if (user == null) {
        setState(() {
          _userRole = 'student';
          _selectedIndex = 0; // Logout වූ විට මුලටම හරවයි
        });
      } else {
        _checkUserRole();
      }
    });
  }

  Future<void> _checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _userRole = 'student');
      _applyInitialTabIfNeeded();
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (mounted && doc.exists) {
        setState(() {
          _userRole = (doc.data()?['role'] ?? 'student').toString();
        });
        _applyInitialTabIfNeeded();
      }
    } catch (e) {
      if (mounted) setState(() => _userRole = 'student');
      _applyInitialTabIfNeeded();
    }
  }

  void _applyInitialTabIfNeeded() {
    if (_initialTabApplied || widget.initialTabIndex == null || !mounted)
      return;
    setState(() {
      _selectedIndex = widget.initialTabIndex!;
      _initialTabApplied = true;
    });
  }

  // --- පද්ධතියේ පිටු ව්‍යුහය (Order must match items) ---
  List<Widget> _getScreens() {
    if (_userRole == 'admin') {
      return [
        const HomeScreen(), // 0
        const AdminFullDashboard(), // 1
        const GuardianMapScreen(), // 2
        const HelpScreen(), // 3
        const LostFoundFeedScreen(), // 4
        MarketHome(), // 5
      ];
    }
    return [
      const HomeScreen(), // 0
      const GuardianMapScreen(), // 1
      const HelpScreen(), // 2
      const LostFoundFeedScreen(), // 3
      MarketHome(), // 4
    ];
  }

  // --- 🎯 මෙන්න ඔයාගේ ප්‍රශ්නය විසඳූ වැදගත්ම Logic එක ---
  void _onItemTapped(int index) async {
    // SOS ටැබ් එක (0) සෑමවිටම විවෘතය
    if (index == 0) {
      setState(() => _selectedIndex = index);
      return;
    }

    // වෙනත් ඕනෑම ටැබ් එකක් එබීමට පෙර Login චෙක් කිරීම
    if (FirebaseAuth.instance.currentUser == null) {
      // ලොග් වී නැති නිසා බලහත්කාරයෙන් Login Screen පෙන්වීම
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );

      // Login පිටුවේ සිට ආපසු පැමිණි පසු (යූසර් ලොග් වූවාදැයි පරීක්ෂාව)
      if (FirebaseAuth.instance.currentUser != null) {
        // ලොග් වී ඇත්නම් භූමිකාව පරීක්ෂා කර ඔහු එබූ පිටුවට ගෙන යන්න
        await _checkUserRole();
        setState(() => _selectedIndex = index);
      } else {
        // ලොග් නොවී හිතාමතාම පස්සට (Back) ආවේ නම් ඔහුව ආපහු මුලට (SOS) හරවා යවයි
        setState(() => _selectedIndex = 0);
      }
    } else {
      // දැනටමත් ලොග් වී සිටී නම් සාමාන්‍ය පරිදි යෑම
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = _getScreens();
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    // Safety: භූමිකාව වෙනස් වූ විට දත්ත වැරදීම පාලනය කරයි
    if (_selectedIndex >= screens.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF0F0F13)
          : const Color(0xFFF6F7FB),
      body: IndexedStack(index: _selectedIndex, children: screens),

      // ලස්සන floating navigation bar එක
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1B1B22) : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                ),
              ],
            ),
            child: SafeArea(
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                onTap: _onItemTapped,
                type: BottomNavigationBarType.fixed,
                backgroundColor: Colors.transparent,
                selectedItemColor: const Color(0xFFFF4B4B),
                unselectedItemColor: isDark
                    ? Colors.grey[500]
                    : Colors.blueGrey[300],
                elevation: 0,
                showSelectedLabels: true,
                showUnselectedLabels: true,
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 10,
                ),
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.security_outlined),
                    activeIcon: Icon(Icons.security),
                    label: "SOS",
                  ),
                  if (_userRole == 'admin')
                    const BottomNavigationBarItem(
                      icon: Icon(Icons.analytics_outlined),
                      activeIcon: Icon(Icons.analytics),
                      label: "ADMIN",
                    ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.map_outlined),
                    activeIcon: Icon(Icons.map_rounded),
                    label: "MAP",
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.handshake_outlined),
                    activeIcon: Icon(Icons.handshake),
                    label: "HELP",
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.search_outlined),
                    activeIcon: Icon(Icons.search_rounded),
                    label: "LOST",
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.storefront_outlined),
                    activeIcon: Icon(Icons.store),
                    label: "MARKET",
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
