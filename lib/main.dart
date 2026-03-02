import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

import 'screens/navigation_screen.dart';
import 'services/notification_service.dart';
import 'services/help_request_service.dart';

// Marketplace Screens
import 'screens/marketPlace_system/market_home.dart';
import 'screens/marketPlace_system/create_listing.dart';
import 'screens/marketPlace_system/item_details.dart';
import 'screens/marketPlace_system/negotiation_chat.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    await NotificationService.initNotification();
    HelpRequestService.instance.startListening();

    debugPrint("SafePulse: Services Initialized Successfully");
  } catch (e) {
    debugPrint("Initialization Error: $e");
  }

  runApp(const SafePulseApp());
}

class SafePulseApp extends StatelessWidget {
  const SafePulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SafePulse',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF4B4B),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
        ),
      ),
      home: const MainNavigationScreen(),
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
