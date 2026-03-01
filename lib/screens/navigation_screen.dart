import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- පවතින Screens Import කිරීම ---
import 'home_screen.dart';
import 'login_screen.dart';
import 'guardian_map_screen.dart';

// --- 1. ඔබේ MARKETPLACE හෝම් පේජ් එක මෙතනට IMPORT කරන්න ---
// ෆයිල් එක තියෙන්නේ lib/screens/marketPlace_system ඇතුලේ නම් මෙසේ දමන්න
import 'marketPlace_system/market_home.dart'; 

// --- 2. ERROR එකක් නොවීමට PlaceholderScreen එක මෙතනම ලියමු ---
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true, backgroundColor: Colors.white, foregroundColor: Colors.black),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.engineering, size: 80, color: Colors.grey),
            Text("$title Screen", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const Text("Member's implementation coming soon..."),
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
  // පටන් ගන්නා විට SOS පිටුව පෙන්වීමට 0 දමමු
  int _selectedIndex = 0;

  // --- 3. ටැබ් මාරු වන විට පෙන්විය යුතු SCREENS ලැයිස්තුව ---
  final List<Widget> _screens = [
    const HomeScreen(),             // Index 0: SOS
    const GuardianMapScreen(),      // Index 1: MAP
    const PlaceholderScreen("Help Feed"),    // Index 2: HELP
    const PlaceholderScreen("Lost & Found"), // Index 3: LOST
    MarketHome(),                   // Index 4: MARKET (ඔබේ වැඩ කොටස)
  ];

  void _onItemTapped(int index) async {
    // SOS හැර අන් ටැබ් සඳහා Login චෙක් කිරීම
    if (index != 0 && FirebaseAuth.instance.currentUser == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      // ලොගින් වූ පසුව ටැබ් එක මාරු කරයි
      if (FirebaseAuth.instance.currentUser != null) {
        setState(() {
          _selectedIndex = index;
        });
      }
    } else {
      // ලොග් වී ඇත්නම් හෝ SOS නම් කෙලින්ම ටැබ් එක මාරු කරයි
      setState(() {
        _selectedIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens, // _screens[index] එක පෙන්වයි
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed, // Icon 5ක් ඇති බැවින් මෙය අනිවාර්යයි
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.grey[600],
        onTap: _onItemTapped, 
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.security_outlined), activeIcon: Icon(Icons.security), label: "SOS"),
          BottomNavigationBarItem(icon: Icon(Icons.map_outlined), activeIcon: Icon(Icons.map), label: "MAP"),
          BottomNavigationBarItem(icon: Icon(Icons.handshake_outlined), activeIcon: Icon(Icons.handshake), label: "HELP"),
          BottomNavigationBarItem(icon: Icon(Icons.search_outlined), activeIcon: Icon(Icons.search), label: "LOST"),
          BottomNavigationBarItem(icon: Icon(Icons.store_outlined), activeIcon: Icon(Icons.store), label: "MARKET"), // ඔබේ ටැබ් එක
        ],
      ),
    );
  }
}