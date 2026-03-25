import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'sos_system/home_screen.dart';
import 'sos_system/guardian_map_screen.dart';
import 'sos_system/admin_full_dashboard.dart';
import 'lost_found_system/lost_found_feed_screen.dart';
import 'marketPlace_system/market_home.dart';
import 'help_screen.dart';
import '../widgets/main_bottom_navigation_bar.dart';

class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1B1B22) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 1,
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
            const SizedBox(height: 6),
            Text(
              "Member's implementation coming soon...",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isDark ? const Color(0xFFB7BBC6) : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Unused legacy menu (Help tab uses [HelpScreen] from `help_screen.dart`).
class LegacyHelpHubMenuScreen extends StatelessWidget {
  const LegacyHelpHubMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text("Help & Support"),
        centerTitle: true,
        backgroundColor: isDark ? const Color(0xFF1B1B22) : null,
        foregroundColor: isDark ? Colors.white : null,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _helpTile(
            context,
            Icons.volunteer_activism,
            "Request Help",
            isDark: isDark,
          ),
          _helpTile(context, Icons.support_agent, "Offer Help", isDark: isDark),
          _helpTile(
            context,
            Icons.info_outline,
            "Help Guidelines",
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _helpTile(
    BuildContext context,
    IconData icon,
    String title, {
    bool isDark = false,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 15),
      color: isDark ? const Color(0xFF1B1B22) : Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: ListTile(
        leading: Icon(icon, color: Colors.redAccent),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1B1B22),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: isDark ? const Color(0xFFB7BBC6) : null,
        ),
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
  /// Optional tab to select after role is loaded (e.g. from embedded nav).
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
      _applyInitialTabIfNeeded();
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
      _applyInitialTabIfNeeded();
    } catch (e) {
      debugPrint('Role check failed: $e');
      if (!mounted) return;
      setState(() => _userRole = 'student');
      _applyInitialTabIfNeeded();
    }
  }

  void _applyInitialTabIfNeeded() {
    if (_initialTabApplied || widget.initialTabIndex == null || !mounted) {
      return;
    }
    final screens = _getScreens();
    if (screens.isEmpty) return;
    setState(() {
      _selectedIndex = widget.initialTabIndex!.clamp(0, screens.length - 1);
      _initialTabApplied = true;
    });
  }

  List<Widget> _getScreens() {
    if (_userRole == 'admin') {
      return [
        const HomeScreen(),
        const AdminFullDashboard(),
        const GuardianMapScreen(),
        const HelpScreen(),
        const LostFoundFeedScreen(),
        const MarketHome(),
      ];
    }

    return [
      const HomeScreen(),
      const GuardianMapScreen(),
      const HelpScreen(),
      const LostFoundFeedScreen(),
      const MarketHome(),
    ];
  }

  Future<void> _onItemTapped(int index) async {
    await handleMainNavBarTap(context, index, (resolved) async {
      if (!mounted) return;
      if (resolved != 0) {
        await _checkUserRole();
      }
      if (!mounted) return;
      setState(() => _selectedIndex = resolved);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screens = _getScreens();
    final navItems = buildMainNavBarItems(_userRole);
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    if (_selectedIndex >= screens.length) {
      _selectedIndex = 0;
    }

    return Scaffold(
      backgroundColor: isDark
          ? const Color(0xFF121217)
          : const Color(0xFFF6F7FB),
      extendBody: true,
      body: IndexedStack(index: _selectedIndex, children: screens),
      bottomNavigationBar: MainBottomNavigationBarView(
        currentIndex: _selectedIndex,
        items: navItems,
        onTap: _onItemTapped,
      ),
    );
  }
}
