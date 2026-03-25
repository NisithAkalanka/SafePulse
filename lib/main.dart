import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';
import 'screens/navigation_screen.dart';
import 'screens/sos_system/onboarding_screen.dart';
import 'screens/sos_system/login_screen.dart';
import 'theme_provider.dart';
import 'services/notification_service.dart';
import 'services/help_request_service.dart';
import 'services/help_offer_notification_service.dart';

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
    HelpOfferNotificationService.instance.start();

    debugPrint("SafePulse: All Core Services Online.");
  } catch (e) {
    debugPrint("SafePulse Error During Start: $e");
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const SafePulseApp(),
    ),
  );
}

class SafePulseApp extends StatelessWidget {
  const SafePulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SafePulse',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: Colors.redAccent,
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Colors.redAccent,
        scaffoldBackgroundColor: const Color(0xFF0F0F13),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.red,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        fontFamily: 'Roboto',
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1B1B22),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        cardColor: const Color(0xFF1B1B22),
      ),
      themeMode: themeProvider.themeMode,
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
        '/navigation': (context) {
          final args = ModalRoute.of(context)?.settings.arguments;
          final tab = args is int ? args : null;
          return MainNavigationScreen(initialTabIndex: tab);
        },
        '/market-home': (context) => const MarketHome(),
        '/create-listing': (context) => const CreateListing(),
        '/item-details': (context) => const ItemDetails(),
        '/chat': (context) => const NegotiationChat(),
      },
    );
  }
}
