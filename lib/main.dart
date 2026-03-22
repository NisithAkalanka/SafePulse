import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
<<<<<<< Updated upstream
import 'screens/navigation_screen.dart';
import 'services/notification_service.dart'; // මෙය අනිවාර්යයෙන්ම තිබිය යුතුය
=======

// --- Screens (ඔයාගේ නව ෆෝල්ඩර් පද්ධතියට අනුව) ---
import 'screens/navigation_screen.dart';
import 'screens/sos_system/onboarding_screen.dart';
import 'screens/sos_system/login_screen.dart';

// --- Services ---
import 'services/notification_service.dart';
import 'services/help_request_service.dart';

// --- Marketplace Screens (Member 4) ---
import 'screens/marketPlace_system/market_home.dart';
import 'screens/marketPlace_system/create_listing.dart';
import 'screens/marketPlace_system/item_details.dart';
import 'screens/marketPlace_system/negotiation_chat.dart';
>>>>>>> Stashed changes

void main() async {
  // 1. Flutter Engine එක සජීවීව පණගැන්වීම
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Firebase සහ Notification සේවා පණගැන්වීම
  // වැදගත්: මෙම සේවා දෙකම සම්පූර්ණ වන තෙක් ඇප් එක දියත් නොවේ
  try {
<<<<<<< Updated upstream
    // Firebase initialization
=======
    // 1. Firebase Initialize කිරීම
>>>>>>> Stashed changes
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

<<<<<<< Updated upstream
    // Notification initialization (යූසර්ට alert එවීමට සූදානම් කිරීම)
=======
    // 2. දැනුම්දීම් පද්ධතිය සහ Help Listener එක සූදානම් කිරීම
>>>>>>> Stashed changes
    await NotificationService.initNotification();

    debugPrint("SafePulse: All Core Services Online.");
  } catch (e) {
    debugPrint("SafePulse Error During Start: $e");
  }

  // 3. දැන් පමණක් ප්‍රධාන ඇප් එක පණගන්වමු
  runApp(const SafePulseApp());
}

class SafePulseApp extends StatelessWidget {
  const SafePulseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'SafePulse',
<<<<<<< Updated upstream
      // ඇප් එකේ මුළු තේමාවම රතු වර්ණයෙන් හැඩගැස්වීම (Design Guideline අනුව)
=======

      // ඇප් එකේ ප්‍රධාන වර්ණය සහ පෙනුම
>>>>>>> Stashed changes
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF4B4B), // SafePulse Red
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        // සරල අකුරු විලාසයක් භාවිත කිරීම
        fontFamily: 'Roboto',
      ),
<<<<<<< Updated upstream
      // සෘජුවම අපගේ ප්‍රධාන පාලක පද්ධතියට (DASHBOARD/MAP/SOS) යොමු කරයි
      home: const MainNavigationScreen(),
=======

      // --- ලොගින් පාලන කොටස (ලෝඩින් ස්පින්නර් එක විසඳන තැන) ---
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance
            .authStateChanges(), // යූසර්ගේ Login/Logout වෙනස් වීම බලමු
        builder: (context, snapshot) {
          // ඩේටා ඇත්තටම ලැබෙන තෙක් පමණක් ලෝඩින් එක පෙන්වමු (එය තප්පරයකටත් අඩු කාලයකි)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(color: Color(0xFFFF4B4B)),
              ),
            );
          }

          // 💡 ලොජික් එක: දත්ත තිබේ නම් ඇප් එක ඇතුළට, නැතිනම් Onboarding එකට
          if (snapshot.hasData && snapshot.data != null) {
            return const MainNavigationScreen();
          }

          // ලොග් අවුට් වූ පසු හෝ අමුත්තන් සඳහා
          return const OnboardingScreen();
        },
      ),

      // අනෙක් පිටුවලට යාම පහසු කිරීමට පාවිච්චි කරන Routes
      routes: {
        '/login': (context) => const LoginScreen(),
        '/navigation': (context) => const MainNavigationScreen(),
        '/market-home': (context) => MarketHome(),
        '/create-listing': (context) => CreateListing(),
        '/item-details': (context) => ItemDetails(),
        '/chat': (context) => NegotiationChat(),
      },
>>>>>>> Stashed changes
    );
  }
}
