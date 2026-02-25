
import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool receiveAlerts = true;
  bool silentMode = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Settings")),
      body: Column(
        children: [
          SwitchListTile(
            title: const Text("Community Notifications"),
            value: receiveAlerts,
            onChanged: (val) => setState(() => receiveAlerts = val),
          ),
          SwitchListTile(
            title: const Text("Silent SOS Trigger"),
            value: silentMode,
            onChanged: (val) => setState(() => silentMode = val),
          ),
        ],
      ),
    );
  }
}