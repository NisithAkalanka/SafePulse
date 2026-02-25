import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'home_screen.dart';        
import 'login_screen.dart';       
import 'guardian_map_screen.dart'; 
import 'admin_full_dashboard.dart'; // Admin පේජ් එක

// අනෙකුත් සාමාජිකයින්ගේ වැඩ සඳහා Placeholder පිටු
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
            Text("$title Section", style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
      ];
    }
  }

  // ටැබ් එක මාරු කිරීමේදී සිදුවන ආරක්ෂණ ලොජික් එක (Navigation Guard)
  void _onItemTapped(int index) async {
    // 0 යනු SOS (Public access - ලොගින් නොවී එබිය හැක)
    if (index == 0) {
      setState(() { _selectedIndex = index; });
      return;
    }

    // වෙනත් ඕනෑම ටැබ් එකක් එබීමට පෙර ලොගින් පරීක්ෂා කරමු
    if (FirebaseAuth.instance.currentUser == null) {
      // 1. කෙලින්ම ලොගින් පේජ් එකට යවමු
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const LoginScreen()),
      );
      
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
    }
  }

  @override
  Widget build(BuildContext context) {
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