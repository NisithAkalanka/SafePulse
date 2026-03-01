import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'home_screen.dart';
import 'login_screen.dart';
import 'guardian_map_screen.dart';
import 'admin_full_dashboard.dart';
import 'lost_found_system/lost_found_feed_screen.dart';

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
  String _userRole = "student";

  @override
  void initState() {
    super.initState();
    _checkUserRole(); // පද්ධතිය පටන් ගන්න කොටම Role එක බලමු
  }

  // Firestore එකෙන් User Role (admin/student) ලබා ගැනීම
  void _checkUserRole() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        var doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        if (doc.exists) {
          setState(() {
            _userRole = doc.data()?['role'] ?? "student";
          });
        }
      } catch (e) {
        debugPrint("Role check failed: $e");
      }
    } else {
      setState(() {
        _userRole = "student";
      });
    }
  }

  List<Widget> _getScreens() {
    if (_userRole == 'admin') {
      return const [
        HomeScreen(),
        AdminFullDashboard(),
        GuardianMapScreen(),
        PlaceholderScreen("Help Feed"),
        LostFoundFeedScreen(),
        PlaceholderScreen("Marketplace"),
      ];
    } else {
      return const [
        HomeScreen(),
        GuardianMapScreen(),
        PlaceholderScreen("Help Feed"),
        LostFoundFeedScreen(),
        PlaceholderScreen("Marketplace"),
      ];
    }
  }

  void _onItemTapped(int index) async {
    if (index == 0) {
      setState(() {
        _selectedIndex = index;
      });
      return;
    }

    if (FirebaseAuth.instance.currentUser == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );

      if (FirebaseAuth.instance.currentUser != null) {
        _checkUserRole();
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
    var screens = _getScreens();

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed, // Icon 5කට වඩා හොඳින් ගැලපේ
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.grey[600],
        onTap: _onItemTapped,
        selectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
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
              label: "DASHBOARD",
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
            icon: Icon(Icons.store_outlined),
            activeIcon: Icon(Icons.store),
            label: "MARKET",
          ),
        ],
      ),
    );
  }
}
