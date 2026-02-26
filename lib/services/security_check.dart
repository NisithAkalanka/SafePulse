import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/security_pin_screen.dart'; // මෙය කලින් හැදූ ෆයිල් එක

class SecurityCheck {
  static Future<void> validateAccess(
    BuildContext context,
    VoidCallback onSuccess,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    var doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    // යූසර් PIN එකක් සෙට් කරලා තිබේ නම් පමණක් බලහත්කාරයෙන් PIN screen එක පෙන්වමු
    if (doc.exists && doc.data()?['app_pin'] != null) {
      if (!context.mounted) return;

      // මෙය වෙනම Dialog එකක් හෝ PIN screen එකකට යැවීමක් කළ හැක
      bool? isValid = await showDialog<bool>(
        context: context,
        builder: (context) => const SecurityLockDialog(),
      );

      if (isValid == true) {
        onSuccess(); // PIN එක හරි නම් පමණක් අදාළ පේජ් එකට යාමට අවසර දෙනවා
      }
    } else {
      // PIN එකක් සෙට් කර නැතිනම් කෙලින්ම පේජ් එකට යවමු
      onSuccess();
    }
  }
}

// පොඩි Popup එකකින් PIN එක අහන Widget එකක්
class SecurityLockDialog extends StatefulWidget {
  const SecurityLockDialog({super.key});
  @override
  State<SecurityLockDialog> createState() => _SecurityLockDialogState();
}

class _SecurityLockDialogState extends State<SecurityLockDialog> {
  final TextEditingController _ctrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Enter App PIN", textAlign: TextAlign.center),
      content: TextField(
        controller: _ctrl,
        keyboardType: TextInputType.number,
        obscureText: true,
        textAlign: TextAlign.center,
        maxLength: 4,
        decoration: const InputDecoration(
          hintText: "••••",
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text("CANCEL"),
        ),
        ElevatedButton(
          onPressed: () async {
            final user = FirebaseAuth.instance.currentUser;
            var doc = await FirebaseFirestore.instance
                .collection('users')
                .doc(user!.uid)
                .get();
            if (_ctrl.text == doc.data()?['app_pin']) {
              Navigator.pop(context, true); // PIN එක ගැලපේ නම් true
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Wrong PIN! Try again.")),
              );
            }
          },
          child: const Text("UNLOCK"),
        ),
      ],
    );
  }
}
