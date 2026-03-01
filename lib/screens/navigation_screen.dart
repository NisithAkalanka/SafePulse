import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'home_screen.dart'; // SOS පිටුව
import 'login_screen.dart'; // ලොගින් පිටුව
import 'guardian_map_screen.dart'; // Snapchat style Map එක

// ✅ LOST & FOUND (Your screen)
import 'lost_found_system/lost_found_feed_screen.dart';

// අනෙකුත් සාමාජිකයින්ගේ වැඩ අවසන් වනතුරු පෙන්වන Placeholder පිටු
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.engineering_outlined,
              size: 80,
              color: Colors.grey,
            ),
            const SizedBox(height: 10),
            Text(
              "$title Section",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text("Under development for Student Safety System."),
          ],
        ),
      ),
    );
  }
}

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});
  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // --- Screen ලැයිස්තුව (මුළු ටැබ් 5 ක් ඇත) ---
  final List<Widget> _screens = [
    const HomeScreen(), // 0. SOS
    const GuardianMapScreen(), // 1. MAP
    const PlaceholderScreen("Help Feed"), // 2. HELP (placeholder)
    const LostFoundFeedScreen(), // ✅ 3. LOST & FOUND (your real screen)
    const PlaceholderScreen("Marketplace"), // 4. MARKET (placeholder)
  ];

  // ටැබ් එකක් එබූ විට සිදුවන ආරක්ෂණ පරීක්ෂාව (Login Guard)
  void _onItemTapped(int index) async {
    // SOS ටැබ් එක (0) ඕනෑම කෙනෙකුට පාවිච්චි කළ හැක.
    // නමුත් Map එක සහ අනිත් ටැබ් වලට යාමට පෙර ලොගින් පරීක්ෂා කරමු.
    if (index != 0 && FirebaseAuth.instance.currentUser == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );

      // ලොගින් සාර්ථක නම් පමණක් එම පිටුව පෙන්වමු
      if (FirebaseAuth.instance.currentUser != null) {
        setState(() {
          _selectedIndex = index;
        });
      }
    } else {
      // දැනටමත් ලොග් වී ඇත්නම් හෝ SOS ටැබ් එක නම් කෙලින්ම යමු
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed, // Icon 5 ක් ඇති නිසා අත්‍යවශ්‍යයි
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.grey[600],
        onTap: _onItemTapped,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.security_outlined),
            activeIcon: Icon(Icons.security),
            label: "SOS",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map_rounded),
            label: "MAP",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.handshake_outlined),
            activeIcon: Icon(Icons.handshake),
            label: "HELP",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search_rounded),
            label: "LOST",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.store_outlined),
            activeIcon: Icon(Icons.store),
            label: "MARKET",
          ),
        ],
      ),
    );
  }
}
