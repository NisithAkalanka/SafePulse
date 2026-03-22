import 'package:flutter/material.dart';

/// Placeholder main menu used from SOS [HomeScreen] when the full SOS menu
/// module is not present in the project.
class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main menu'),
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Main menu options can be wired here (SOS hub).',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
