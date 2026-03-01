import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; 
import 'screens/navigation_screen.dart'; 

// 1. මේ විදිහට ඔයාගේ Marketplace Home එක Import කරගන්න. 
// පෝල්ඩර් එකේ නම marketplace_system (all simple) ද කියලා චෙක් කරගන්න.
import 'screens/marketPlace_system/market_home.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 'const' එක මෙතනින් ඉවත් කරන්න (MarketHome එක const එකක් නෙවෙයි නම්)
  runApp(SafePulseApp()); 
}

class SafePulseApp extends StatelessWidget {
  const SafePulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SafePulse',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      
      // 2. මෙතන 'home' එකට ඔයා හදපු MarketHome() එක දෙන්න.
      // කෙලින්ම Marketplace එක Load වෙන්නේ මෙතනින්.
      home: MarketHome(), 

      // 3. Navigation එක පහසු වෙන්න routes මෙතනට දාන්න.
      routes: {
        '/navigation': (context) => const MainNavigationScreen(),
        '/market': (context) => MarketHome(),
      },
    );
  }
}