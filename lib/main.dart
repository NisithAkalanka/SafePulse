import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/navigation_screen.dart';
import 'services/notification_service.dart'; // මෙය අනිවාර්යයෙන්ම තිබිය යුතුය

void main() async {
  // 1. Flutter Engine එක සජීවීව පණගැන්වීම
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // Firebase initialization
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Notification initialization
    await NotificationService.initNotification();

    debugPrint("SafePulse: Services Initialized Successfully");
  } catch (e) {
    debugPrint("Initialization Error: $e");
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
      // ඇප් එකේ මුළු තේමාවම රතු වර්ණයෙන් හැඩගැස්වීම (Design Guideline අනුව)
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF4B4B),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
        // සරල අකුරු විලාසයක් භාවිත කිරීම
        fontFamily: 'Roboto',
      ),
      // සෘජුවම අපගේ ප්‍රධාන පාලක පද්ධතියට (DASHBOARD/MAP/SOS) යොමු කරයි
      home: const MainNavigationScreen(),
    );
  }
}
