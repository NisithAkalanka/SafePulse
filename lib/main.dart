import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';

import 'screens/navigation_screen.dart';
import 'screens/sos_system/onboarding_screen.dart';
import 'screens/sos_system/login_screen.dart';
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

    debugPrint("SafePulse: All Core Services Online.");
  } catch (e) {
    debugPrint("SafePulse Error During Start: $e");
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
          seedColor: const Color(0xFFFF4B4B), // SafePulse Red
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
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFFFF4B4B)),
              ),
            );
          }

          if (snapshot.hasData && snapshot.data != null) {
            return const MainNavigationScreen();
          }

          return const OnboardingScreen();
        },
      ),
      routes: {
        '/login': (context) => const LoginScreen(),
        '/navigation': (context) => const MainNavigationScreen(),
        '/market-home': (context) => MarketHome(),
        '/create-listing': (context) => CreateListing(),
        '/item-details': (context) => ItemDetails(),
        '/chat': (context) => NegotiationChat(),
      },
    );
  }
}
