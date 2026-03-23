import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme_provider.dart';

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
    // Theme එක වෙනස් කරන එක පාලනය කරන කෙනා ගමු
    final themeProvider = Provider.of<ThemeProvider>(context);
    final bool isDark = themeProvider.themeMode == ThemeMode.dark;

    // Dark/Light අනුව මාරු වන වර්ණ ටික මෙතැන සෙට් කරමු
    final Color bgColor = isDark
        ? const Color(0xFF0F0F13)
        : const Color(0xFFF5F6FA);
    final Color cardColor = isDark ? const Color(0xFF1B1B22) : Colors.white;
    final Color textColor = isDark ? Colors.white : const Color(0xFF1B1B22);
    final Color subTextColor = isDark
        ? Colors.white70
        : const Color(0xFF747A86);
    final Color tileInnerColor = isDark
        ? Colors.white.withOpacity(0.05)
        : const Color(0xFFF9FAFC);

    return Scaffold(
      backgroundColor: bgColor, // Dynamic Background
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: Colors.transparent, // පසුබිමට කැපී පෙනෙන්න
        foregroundColor: textColor,
        title: const Text(
          "Settings",
          style: TextStyle(fontWeight: FontWeight.w800, letterSpacing: 0.2),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          // --- App Preferences Header (SafePulse Gradient) ---
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF4B4B), Color(0xFFB31217)],
              ),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: const Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: Color(0x33FFFFFF),
                  child: Icon(
                    Icons.settings_rounded,
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
                        "App Preferences",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        "Control alerts and emergency behavior for your SafePulse app.",
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // --- Dark Mode Toggle Button Area ---
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.transparent,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: SwitchListTile(
              title: Text(
                "Dark Appearance",
                style: TextStyle(fontWeight: FontWeight.w800, color: textColor),
              ),
              subtitle: Text(
                isDark ? "Dark mode is active" : "Light mode is active",
                style: TextStyle(color: subTextColor),
              ),
              secondary: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? Colors.amber.withOpacity(0.1)
                      : const Color(0xFFB31217).withOpacity(0.1),
                ),
                child: Icon(
                  isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                  color: isDark ? Colors.amber : const Color(0xFFB31217),
                ),
              ),
              activeColor: const Color(0xFFB31217),
              value: isDark,
              onChanged: (bool value) {
                themeProvider.toggleTheme(
                  value,
                ); // මෙන්න මෙතනින් තමයි මාරු කරන්නේ
              },
            ),
          ),

          const SizedBox(height: 20),

          // --- Notifications Section ---
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.transparent,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Notifications",
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Choose how the app communicates updates.",
                  style: TextStyle(color: subTextColor, fontSize: 12),
                ),
                const SizedBox(height: 16),
                _settingTile(
                  isDark: isDark,
                  tileColor: tileInnerColor,
                  icon: Icons.notifications_active_outlined,
                  title: "Community Notifications",
                  subtitle: "Receive community alerts.",
                  value: receiveAlerts,
                  onChanged: (val) => setState(() => receiveAlerts = val),
                  textColor: textColor,
                  subTextColor: subTextColor,
                ),
                const SizedBox(height: 12),
                _settingTile(
                  isDark: isDark,
                  tileColor: tileInnerColor,
                  icon: Icons.volume_off_outlined,
                  title: "Silent SOS Trigger",
                  subtitle: "Send SOS without siren sound.",
                  value: silentMode,
                  onChanged: (val) => setState(() => silentMode = val),
                  textColor: textColor,
                  subTextColor: subTextColor,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // --- Bottom Tip Card ---
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFFF7B7B), Color(0xFFD32F2F)],
                    ),
                  ),
                  child: const Icon(
                    Icons.info_outline_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Safety Tip",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: textColor,
                        ),
                      ),
                      Text(
                        "Keep alerts enabled for 24/7 security.",
                        style: TextStyle(fontSize: 12, color: subTextColor),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // පුංචි මෙනු ඇතුළු කරන Function එක Update කලා
  Widget _settingTile({
    required bool isDark,
    required Color tileColor,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color textColor,
    required Color subTextColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: tileColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: SwitchListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
        secondary: CircleAvatar(
          backgroundColor: isDark ? Colors.white12 : const Color(0xFFFFE3E3),
          child: Icon(icon, color: const Color(0xFFB31217), size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14,
            color: textColor,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(fontSize: 11, color: subTextColor),
        ),
        activeColor: const Color(0xFFB31217),
        value: value,
        onChanged: onChanged,
      ),
    );
  }
}
