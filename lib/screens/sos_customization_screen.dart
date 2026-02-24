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
      var doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
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

  // 3. ලිස්ට් එකෙන් සම්පූර්ණයෙන්ම ඉවත් කිරීම
  void _removeType(String key) {
    setState(() {
      sosTypes.remove(key);
    });
  }

  // 4. සියලුම දත්ත එකවර Firestore වල සේව් කිරීම
  Future<void> _saveAllSettings() async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'trigger_time': triggerTime,
        'vibrate_enabled': vibrateOnTrigger,
        'sos_categories': sosTypes,
      }, SetOptions(merge: true));

      if (!mounted) return;
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text("Customize Emergency"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // --- PART 1: Trigger Timing ---
          const Text("Hold Duration", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Slider(
            value: triggerTime,
            min: 1, max: 5, divisions: 4,
            activeColor: Colors.redAccent,
            onChanged: (val) => setState(() => triggerTime = val),
          ),
          Center(child: Text("${triggerTime.toStringAsFixed(1)} Seconds", style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
          
          const SizedBox(height: 15),
          SwitchListTile(
            title: const Text("Haptic (Vibration) feedback"),
            value: vibrateOnTrigger,
            onChanged: (val) => setState(() => vibrateOnTrigger = val),
          ),
          
          const Divider(height: 40),
          
          // --- PART 2: Dynamic Category List ---
          const Text("Active Emergency Types", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const Text("Select visible categories or add new ones", style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 15),

          // Add New Type Input Field
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customTypeController,
                    decoration: const InputDecoration(hintText: "Add e.g. Police, Fire", border: InputBorder.none),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: _addNewType,
                ),
              ],
            ),
          ),

          const SizedBox(height: 15),

          // List of Items with Edit/Delete
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
            child: Column(
              children: sosTypes.keys.map((String key) {
                return ListTile(
                  leading: Checkbox(
                    value: sosTypes[key],
                    activeColor: Colors.redAccent,
                    onChanged: (val) {
                      setState(() { sosTypes[key] = val!; });
                    },
                  ),
                  title: Text(key, style: const TextStyle(fontSize: 14)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.grey, size: 20),
                    onPressed: () => _removeType(key),
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 40),
          
          // --- Save Button ---
          ElevatedButton(
            onPressed: _saveAllSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
            ),
            child: const Text("SAVE CUSTOM SETTINGS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 30),
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