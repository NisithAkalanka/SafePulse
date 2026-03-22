import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'sos_system/home_screen.dart';
import 'sos_system/login_screen.dart';
import 'sos_system/guardian_map_screen.dart';
import 'sos_system/admin_full_dashboard.dart';
import 'lost_found_system/lost_found_feed_screen.dart';
import 'marketPlace_system/market_home.dart';
import 'help_screen.dart';

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
            const SizedBox(height: 6),
            const Text(
              "Member's implementation coming soon...",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class HelpFeedScreen extends StatelessWidget {
  const HelpFeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Help & Support"), centerTitle: true),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _helpTile(context, Icons.volunteer_activism, "Request Help"),
          _helpTile(context, Icons.support_agent, "Offer Help"),
          _helpTile(context, Icons.info_outline, "Help Guidelines"),
        ],
      ),
    );
  }

  Widget _helpTile(BuildContext context, IconData icon, String title) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, color: Colors.redAccent),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("$title page coming soon...")));
        },
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
  String _userRole = 'student';

  @override
  void initState() {
    super.initState();
    _checkUserRole();

    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      if (user == null) {
        setState(() {
          _userRole = 'student';
          _selectedIndex = 0;
        });
      } else {
        _checkUserRole();
      }
    });
  }

  Future<void> _checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      if (!mounted) return;
      setState(() => _userRole = 'student');
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;
      setState(() {
        _userRole = (doc.data()?['role'] ?? 'student').toString();
      });
    } catch (e) {
      debugPrint('Role check failed: $e');
      if (!mounted) return;
      setState(() => _userRole = 'student');
    }
  }

  List<Widget> _getScreens() {
    if (_userRole == 'admin') {
      return [
        const HomeScreen(),
        const AdminFullDashboard(),
        const GuardianMapScreen(),
        const HelpScreen(),
        const LostFoundFeedScreen(),
        MarketHome(),
      ];
    }

    return [
      const HomeScreen(),
      const GuardianMapScreen(),
      const HelpScreen(),
      const LostFoundFeedScreen(),
      MarketHome(),
    ];
  }

  List<BottomNavigationBarItem> _getNavItems() {
    final items = <BottomNavigationBarItem>[
      const BottomNavigationBarItem(
        icon: Icon(Icons.security_outlined),
        activeIcon: Icon(Icons.security),
        label: 'SOS',
      ),
    ];

    if (_userRole == 'admin') {
      items.add(
        const BottomNavigationBarItem(
          icon: Icon(Icons.analytics_outlined),
          activeIcon: Icon(Icons.analytics),
          label: 'DASHBOARD',
        ),
      );
    }

    items.addAll(const [
      BottomNavigationBarItem(
        icon: Icon(Icons.map_outlined),
        activeIcon: Icon(Icons.map_rounded),
        label: 'MAP',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.handshake_outlined),
        activeIcon: Icon(Icons.handshake),
        label: 'HELP',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.search_outlined),
        activeIcon: Icon(Icons.search_rounded),
        label: 'LOST',
      ),
      BottomNavigationBarItem(
        icon: Icon(Icons.store_outlined),
        activeIcon: Icon(Icons.store),
        label: 'MARKET',
      ),
    ]);

    return items;
  }

  Future<void> _onItemTapped(int index) async {
    if (index == 0) {
      setState(() => _selectedIndex = index);
      return;
    }

    if (FirebaseAuth.instance.currentUser == null) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );

      if (FirebaseAuth.instance.currentUser != null) {
        await _checkUserRole();
        if (!mounted) return;
        setState(() => _selectedIndex = index);
      }
      return;
    }

    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final screens = _getScreens();
    final navItems = _getNavItems();

    if (_selectedIndex >= screens.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.96),
            borderRadius: BorderRadius.circular(34),
            border: Border.all(color: const Color(0xFFFFD9DD), width: 1.2),
            boxShadow: const [
              BoxShadow(
                color: Color(0x22000000),
                blurRadius: 24,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(34),
            child: Theme(
              data: Theme.of(context).copyWith(
                splashColor: Colors.transparent,
                highlightColor: Colors.transparent,
              ),
              child: BottomNavigationBar(
                currentIndex: _selectedIndex,
                backgroundColor: Colors.transparent,
                elevation: 0,
                type: BottomNavigationBarType.fixed,
                selectedItemColor: const Color(0xFFFF5A63),
                unselectedItemColor: const Color(0xFF90A0AC),
                onTap: _onItemTapped,
                selectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 0.3,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
                iconSize: 27,
                items: navItems,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
