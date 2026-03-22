import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';        
import 'login_screen.dart';       
import 'guardian_map_screen.dart'; 
import 'admin_full_dashboard.dart'; // Admin පේජ් එක

<<<<<<< Updated upstream
// අනෙකුත් සාමාජිකයින්ගේ වැඩ සඳහා Placeholder පිටු
=======
import 'sos_system/home_screen.dart';
import 'sos_system/login_screen.dart';
import 'sos_system/guardian_map_screen.dart';
import 'sos_system/admin_full_dashboard.dart';
import 'lost_found_system/lost_found_feed_screen.dart';
import 'marketPlace_system/market_home.dart';
import 'help_screen.dart';

// Placeholder (අවශ්‍යතාවය අනුව පාවිච්චි කිරීමට)
>>>>>>> Stashed changes
class PlaceholderScreen extends StatelessWidget {
  final String title;
  const PlaceholderScreen(this.title, {super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), centerTitle: true),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.engineering_outlined, size: 80, color: Colors.grey),
            const SizedBox(height: 10),
<<<<<<< Updated upstream
            Text("$title Section", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
=======
            Text(
              "$title Section",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
>>>>>>> Stashed changes
            const Text("This module is under development."),
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
<<<<<<< Updated upstream
    _checkUserRole(); // පද්ධතිය පටන් ගන්න කොටම Role එක බලමු
  }

  // Firestore එකෙන් User Role (admin/student) ලබා ගැනීම
  void _checkUserRole() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        var doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            _userRole = doc.data()?['role'] ?? "student";
          });
        }
      } catch (e) {
        debugPrint("Role check failed: $e");
      }
    } else {
      setState(() { _userRole = "student"; });
    }
  }

  // --- පේජ් ලිස්ට් එක Role එක අනුව වෙනස් වේ ---
  List<Widget> _getScreens() {
    if (_userRole == 'admin') {
      return [
        const HomeScreen(),              // 0
        const AdminFullDashboard(),      // 1. (Admin ට පමනක් පෙනේ)
        const GuardianMapScreen(),       // 2
        const PlaceholderScreen("Help"),  // 3
        const PlaceholderScreen("Lost"),  // 4
        const PlaceholderScreen("Market"),// 5
      ];
    } else {
      return [
        const HomeScreen(),               // 0. SOS
        const GuardianMapScreen(),        // 1. MAP
        const PlaceholderScreen("Help"),   // 2
        const PlaceholderScreen("Lost"),   // 3
        const PlaceholderScreen("Market"), // 4
=======
    _checkUserRole();

    // යූසර්ගේ Login status එක වෙනස් වූ සැණින් භූමිකාව (Role) නැවත පරීක්ෂා කරමු
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (!mounted) return;
      if (user == null) {
        setState(() {
          _userRole = 'student';
          _selectedIndex = 0; // Logout වූ පසු SOS වෙත යවමු
        });
      } else {
        _checkUserRole();
      }
    });
  }

  Future<void> _checkUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;
      if (doc.exists) {
        setState(() {
          _userRole = (doc.data()?['role'] ?? 'student').toString();
        });
      }
    } catch (e) {
      debugPrint('Role Fetching Failed: $e');
    }
  }

  // --- පේජ් ලැයිස්තුව: Role එක අනුව Dynamic ලෙස වෙනස් වේ ---
  List<Widget> _getScreens() {
    if (_userRole == 'admin') {
      return [
        const HomeScreen(), // 0. SOS (Member 1)
        const AdminFullDashboard(), // 1. DASHBOARD (Admin Only)
        const GuardianMapScreen(), // 2. MAP (Member 1 - Snap Map)
        const HelpScreen(), // 3. HELP (Member 2)
        const LostFoundFeedScreen(), // 4. LOST (Member 3)
        MarketHome(), // 5. MARKET (Member 4)
      ];
    } else {
      return [
        const HomeScreen(), // 0. SOS
        const GuardianMapScreen(), // 1. MAP
        const HelpScreen(), // 2. HELP
        const LostFoundFeedScreen(), // 3. LOST
        MarketHome(), // 4. MARKET
>>>>>>> Stashed changes
      ];
    }
  }

<<<<<<< Updated upstream
  // ටැබ් එක මාරු කිරීමේදී සිදුවන ආරක්ෂණ ලොජික් එක (Navigation Guard)
  void _onItemTapped(int index) async {
    // 0 යනු SOS (Public access - ලොගින් නොවී එබිය හැක)
=======
  // --- ටැබ් ලැයිස්තුව: Bottom Nav Items ---
  List<BottomNavigationBarItem> _getNavItems() {
    return [
      const BottomNavigationBarItem(
        icon: Icon(Icons.security_outlined),
        activeIcon: Icon(Icons.security),
        label: 'SOS',
      ),
      if (_userRole == 'admin')
        const BottomNavigationBarItem(
          icon: Icon(Icons.analytics_outlined),
          activeIcon: Icon(Icons.analytics),
          label: 'ADMIN',
        ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.map_outlined),
        activeIcon: Icon(Icons.map_rounded),
        label: 'MAP',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.handshake_outlined),
        activeIcon: Icon(Icons.handshake),
        label: 'HELP',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.search_outlined),
        activeIcon: Icon(Icons.search_rounded),
        label: 'LOST',
      ),
      const BottomNavigationBarItem(
        icon: Icon(Icons.store_outlined),
        activeIcon: Icon(Icons.store),
        label: 'MARKET',
      ),
    ];
  }

  Future<void> _onItemTapped(int index) async {
    // SOS ටැබ් එක (0) සැමවිටම විවෘතව පවතී
>>>>>>> Stashed changes
    if (index == 0) {
      setState(() { _selectedIndex = index; });
      return;
    }

<<<<<<< Updated upstream
    // වෙනත් ඕනෑම ටැබ් එකක් එබීමට පෙර ලොගින් පරීක්ෂා කරමු
=======
    // වෙනත් ඕනෑම ටැබ් එකකට යාමට පෙර ලොගින් පරීක්ෂා කරමු
>>>>>>> Stashed changes
    if (FirebaseAuth.instance.currentUser == null) {
      // 1. කෙලින්ම ලොගින් පේජ් එකට යවමු
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
<<<<<<< Updated upstream
      
      // 2. ලොගින් පේජ් එකේ සිට ආපසු පැමිණි පසු (Success නම්)
      if (FirebaseAuth.instance.currentUser != null) {
        _checkUserRole(); // Role එක update කරමු
        setState(() { _selectedIndex = index; }); // යූසර්ට අවශ්‍ය වූ පේජ් එකටම යවමු
      }
    } else {
      // ලොග් වී ඇත්නම් සාමාන්‍ය ලෙස පේජ් එක මාරු කරන්න
      setState(() {
        _selectedIndex = index;
      });
=======

      // ලොගින් එකෙන් ආපසු පැමිණි පසු:
      if (FirebaseAuth.instance.currentUser != null) {
        await _checkUserRole();
        if (!mounted) return;
        setState(() => _selectedIndex = index);
      }
      return;
>>>>>>> Stashed changes
    }
  }

  @override
  Widget build(BuildContext context) {
<<<<<<< Updated upstream
    var screens = _getScreens();

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        type: BottomNavigationBarType.fixed, // Icon 5කට වඩා හොඳින් ගැලපේ
        selectedItemColor: Colors.redAccent,
        unselectedItemColor: Colors.grey[600],
        onTap: _onItemTapped, 
        selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: const TextStyle(fontSize: 10),
        items: [
          const BottomNavigationBarItem(
            icon: Icon(Icons.security_outlined),
            activeIcon: Icon(Icons.security),
            label: "SOS",
          ),
          
          // --- Admin ලොග් වී ඇත්නම් පමණක් Dashboard බටන් එක දාමු ---
          if (_userRole == 'admin')
            const BottomNavigationBarItem(
              icon: Icon(Icons.analytics_outlined),
              label: "DASHBOARD",
            ),

          const BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map_rounded),
            label: "MAP",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.handshake_outlined),
            label: "HELP",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            label: "LOST",
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.storefront_outlined),
            label: "MARKET",
          ),
        ],
      ),
    );
  }
}
=======
    final screens = _getScreens();
    final navItems = _getNavItems();

    // Role මාරු වෙද්දී ඇතිවන Index බිඳවැටීම් (Out of range) වැළැක්වීම
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
>>>>>>> Stashed changes
