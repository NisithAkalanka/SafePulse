import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home_screen.dart';        
import 'login_screen.dart';       
import 'guardian_map_screen.dart'; 

// --- 1. ඔයාගේ MARKETPLACE එක මෙතනට IMPORT කරන්න ---
import 'marketPlace_system/market_home.dart'; 

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
            const Icon(Icons.engineering_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 10),
            Text("$title Section", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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

  // --- 2. SCREEN ලැයිස්තුව වෙනස් කළා (MARKETPLACE එක ඇතුළත් කර ඇත) ---
  final List<Widget> _screens = [
    const HomeScreen(),            // 0. SOS 
    const GuardianMapScreen(),     // 1. MAP
    const PlaceholderScreen("Help Feed"),    // 2. HELP
    const PlaceholderScreen("Lost & Found"), // 3. LOST
    MarketHome(),                  // 4. ඔයා හදපු Marketplace එක දැන් මෙතනට එනවා
  ];

  void _onItemTapped(int index) async {
    // SOS ටැබ් එක (0) හැර අනිත් ටැබ් වලට යාමට පෙර Login එක චෙක් කරයි
    if (index != 0 && FirebaseAuth.instance.currentUser == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );

      if (FirebaseAuth.instance.currentUser != null) {
        setState(() {
          _selectedIndex = index;
        });
      }
    } else {
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
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed, 
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.grey[600],
        onTap: _onItemTapped, 
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
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
            icon: Icon(Icons.store_outlined), // Marketplace සඳහා Icon එක
            activeIcon: Icon(Icons.store),
            label: "MARKET",
          ),
        ],
      ),
    );
  }
}