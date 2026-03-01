import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// Leader ගේ Navigation Screen එක
import 'screens/navigation_screen.dart';

// ඔබේ Marketplace පද්ධතියේ Screens (Folders සහ Path නිවැරදිදැයි චෙක් කරගන්න)
import 'screens/marketPlace_system/market_home.dart';
import 'screens/marketPlace_system/create_listing.dart';
import 'screens/marketPlace_system/item_details.dart';
import 'screens/marketPlace_system/negotiation_chat.dart';

void main() async {
  // Flutter binding සහ Firebase පණගැන්වීම
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SafePulseApp());
}

class SafePulseApp extends StatelessWidget {
  const SafePulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SafePulse',
      
      // Leader ගේ රතු වර්ණ තේමාව (Theme)
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
      ),

      // ඇප් එක පටන් ගන්නා විට කෙලින්ම මෙනු එක (Bottom Nav) සහිත පේජ් එකට යයි
      home: const MainNavigationScreen(),

      // ඔබේ පේජ් අතර මාරු වීමට ලේසි වන පරිදි Routes මෙහි අර්ථ දක්වා ඇත
      routes: {
        '/navigation': (context) => const MainNavigationScreen(),
        '/market-home': (context) => MarketHome(),
        '/create-listing': (context) => CreateListing(),
        '/item-details': (context) => ItemDetails(),
        '/chat': (context) => NegotiationChat(),
      },
    );
  }
}