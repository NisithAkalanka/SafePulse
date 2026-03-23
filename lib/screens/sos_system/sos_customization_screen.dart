import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SOSCustomizationScreen extends StatefulWidget {
  const SOSCustomizationScreen({super.key});

  @override
  State<SOSCustomizationScreen> createState() => _SOSCustomizationScreenState();
}

class _SOSCustomizationScreenState extends State<SOSCustomizationScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final TextEditingController _customTypeController = TextEditingController();

  // පද්ධතියේ මූලික සෙටින්ග්ස්
  double triggerTime = 3.0;
  bool vibrateOnTrigger = true;

  // Emergency Types මැනේජ් කරන Map එක
  // Key = නම, Value = දර්ශනය විය යුතුද නැද්ද (bool)
  Map<String, bool> sosTypes = {
    "🚨 Medical Emergency": true,
    "⚠️ Threat / Hazard": true,
    "💥 Accident / Crash": true,
  };

  @override
  void initState() {
    super.initState();
    _loadUserSettings();
  }

  // 1. Firebase එකෙන් සෙටින්ග්ස් ලෝඩ් කිරීම
  Future<void> _loadUserSettings() async {
    if (user != null) {
      var doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();
      if (doc.exists) {
        setState(() {
          triggerTime = (doc.data()?['trigger_time'] ?? 3.0).toDouble();
          vibrateOnTrigger = doc.data()?['vibrate_enabled'] ?? true;
          if (doc.data()?['sos_categories'] != null) {
            sosTypes = Map<String, bool>.from(doc.data()?['sos_categories']);
          }
        });
      }
    }
  }

  // 2. අලුත් Type එකක් ලිස්ට් එකට එකතු කිරීම
  void _addNewType() {
    String newType = _customTypeController.text.trim();
    if (newType.isNotEmpty) {
      setState(() {
        sosTypes[newType] = true; // Default එකට active කරලා ඇඩ් කරනවා
        _customTypeController.clear();
      });
      // පල්ලෙහා Keyboard එක වහන්න
      FocusScope.of(context).unfocus();
    }
  }

  // 3. ලිස්ට් එකෙන් සම්පූර්ණයෙන්ම ඉවත් කිරීම (Firestore sync + confirmation)
  Future<void> _deleteCategory(String key) async {
    if (user == null) return;

    try {
      final updated = Map<String, bool>.from(sosTypes);
      updated.remove(key);

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'sos_categories': updated});
      await _loadUserSettings();
      if (!mounted) return;
      setState(() {
        sosTypes = updated;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Category deleted successfully')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Delete failed: $e')));
    }
  }

  // 4. සියලුම දත්ත එකවර Firestore වල සේව් කිරීම
  Future<void> _saveAllSettings() async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'trigger_time': triggerTime,
        'vibrate_enabled': vibrateOnTrigger,
      }, SetOptions(merge: true));

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({'sos_categories': Map<String, bool>.from(sosTypes)});
      await _loadUserSettings();
      if (!mounted) return;
      setState(() {
        sosTypes = Map<String, bool>.from(sosTypes);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ SOS Preferences Synced with Server"),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint("Save error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color pageBg = isDark
        ? const Color(0xFF121217)
        : const Color(0xFFF6F7FB);
    final Color cardBg = isDark
        ? const Color(0xFF1B1B22)
        : Colors.white;
    final Color textPrimary = isDark
        ? Colors.white
        : const Color(0xFF1B1B22);
    final Color textSecondary = isDark
        ? const Color(0xFFB7BBC6)
        : const Color(0xFF747A86);
    final Color softBg = isDark
        ? const Color(0xFF23232B)
        : const Color(0xFFF9FAFC);
    final Color borderColor = isDark
        ? const Color(0xFF34343F)
        : const Color(0xFFE8EAF0);
    return Scaffold(
      backgroundColor: pageBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Customize Emergency",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Container(
            height: 260,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: isDark
                    ? const [
                        Color(0xFFFF3B3B),
                        Color(0xFFE10613),
                        Color(0xFFB30012),
                        Color(0xFF140910),
                      ]
                    : const [
                        Color(0xFFFF4B4B),
                        Color(0xFFB31217),
                        Color(0xFF1B1B1B),
                      ],
                stops: isDark
                    ? const [0.0, 0.35, 0.72, 1.0]
                    : const [0.0, 0.6, 1.0],
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -30,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(isDark ? 0.06 : 0.08),
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
              children: [
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: pageBg,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x14000000),
                        blurRadius: 18,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 22, 18, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFFF4B4B), Color(0xFFB31217)],
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x22000000),
                                blurRadius: 16,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: const Row(
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Color(0x33FFFFFF),
                                child: Icon(
                                  Icons.tune_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                              SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "SOS Preferences",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Manage trigger timing, vibration, and emergency categories.",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x10000000),
                                blurRadius: 14,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Hold Duration",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Adjust how long the SOS button must be pressed.",
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              SliderTheme(
                                data: SliderTheme.of(context).copyWith(
                                  activeTrackColor: const Color(0xFFB31217),
                                  inactiveTrackColor: const Color(0xFFFFD6D6),
                                  thumbColor: const Color(0xFFFF4B4B),
                                  overlayColor: const Color(0x33FF4B4B),
                                ),
                                child: Slider(
                                  value: triggerTime,
                                  min: 1,
                                  max: 5,
                                  divisions: 4,
                                  onChanged: (val) =>
                                      setState(() => triggerTime = val),
                                ),
                              ),
                              Center(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? const Color(0xFF3A2024)
                                        : const Color(0xFFFFE3E3),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    "${triggerTime.toStringAsFixed(1)} Seconds",
                                    style: const TextStyle(
                                      color: Color(0xFFB31217),
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Container(
                                decoration: BoxDecoration(
                                  color: softBg,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: borderColor,
                                  ),
                                ),
                                child: SwitchListTile(
                                  title: Text(
                                    "Haptic (Vibration) feedback",
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                    ),
                                  ),
                                  subtitle: Text(
                                    "Enable vibration when SOS is triggered.",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: textSecondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  value: vibrateOnTrigger,
                                  activeThumbColor: const Color(0xFFB31217),
                                  onChanged: (val) =>
                                      setState(() => vibrateOnTrigger = val),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: cardBg,
                            borderRadius: BorderRadius.circular(22),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x10000000),
                                blurRadius: 14,
                                offset: Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Active Emergency Types",
                                style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 16,
                                  color: textPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Select visible categories or add new ones.",
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  color: softBg,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: borderColor,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _customTypeController,
                                        decoration: InputDecoration(
                                          hintText: "Add e.g. Police, Fire",
                                          hintStyle: TextStyle(
                                            color: textSecondary,
                                          ),
                                          border: InputBorder.none,
                                        ),
                                        style: TextStyle(color: textPrimary),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.add_circle,
                                        color: Color(0xFFB31217),
                                      ),
                                      onPressed: _addNewType,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(
                                decoration: BoxDecoration(
                                  color: softBg,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(
                                    color: borderColor,
                                  ),
                                ),
                                child: Column(
                                  children: sosTypes.keys.map((String key) {
                                    return ListTile(
                                      leading: Checkbox(
                                        value: sosTypes[key],
                                        activeColor: const Color(0xFFB31217),
                                        onChanged: (val) {
                                          setState(() {
                                            sosTypes[key] = val!;
                                          });
                                        },
                                      ),
                                      title: Text(
                                        key,
                                        style: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w700,
                                          color: textPrimary,
                                        ),
                                      ),
                                      trailing: IconButton(
                                        icon: Icon(
                                          Icons.delete_outline,
                                          color: textSecondary,
                                          size: 20,
                                        ),
                                        onPressed: () async {
                                          final bool?
                                          confirm = await showDialog<bool>(
                                            context: context,
                                            builder: (context) => AlertDialog(
                                              title: const Text(
                                                'Delete Category',
                                              ),
                                              content: Text(
                                                'Are you sure you want to delete "$key"?',
                                              ),
                                              actions: [
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        false,
                                                      ),
                                                  child: const Text('Cancel'),
                                                ),
                                                TextButton(
                                                  onPressed: () =>
                                                      Navigator.pop(
                                                        context,
                                                        true,
                                                      ),
                                                  child: const Text('Delete'),
                                                ),
                                              ],
                                            ),
                                          );

                                          if (confirm == true) {
                                            await _deleteCategory(key);
                                          }
                                        },
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [Color(0xFFFF4B4B), Color(0xFFB31217)],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x22000000),
                                blurRadius: 16,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _saveAllSettings,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              minimumSize: const Size(double.infinity, 58),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                              ),
                            ),
                            child: const Text(
                              "SAVE CUSTOM SETTINGS",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _customTypeController.dispose();
    super.dispose();
  }
}
