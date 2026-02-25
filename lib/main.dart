import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // මෙතන වැරදි ඉරක් පෙන්වනවා නම් පියවර 2 බලන්න
import 'screens/navigation_screen.dart'; // Navigation screen එකට යාමට

void main() async {
  // Flutter binding එක පණගැන්වීම
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase Initialize කිරීම
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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.red),
        useMaterial3: true,
      ),
      // කෙලින්ම මෙනු එක සහිත පේජ් එකට යමු (නොබැඳි යූසර්ට SOS ඇලර්ට් යැවිය හැකි පරිදි)
      home: const MainNavigationScreen(),
    );
  }
}