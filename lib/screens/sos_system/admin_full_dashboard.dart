import 'package:flutter/material.dart';
<<<<<<< Updated upstream
import 'package:cloud_firestore/cloud_firestore.dart';
=======
import 'sos_management_page.dart';
import '../marketPlace_system/market_admin_hub.dart';
import 'community_requests_admin_screen.dart';

// --- පියවර: ඔබේ Marketplace Admin පිටුව මෙතැනට Import කළා ---
>>>>>>> Stashed changes

class AdminFullDashboard extends StatefulWidget {
  const AdminFullDashboard({super.key});
  @override
  State<AdminFullDashboard> createState() => _AdminFullDashboardState();
}

class _AdminFullDashboardState extends State<AdminFullDashboard> {
  final TextEditingController _broadcastController = TextEditingController();

  // 📣 පද්ධතියේ සිටින හැමෝටම හදිසි දැනුම්දීමක් (Emergency Broadcast) යැවීම
  Future<void> _sendBroadcastAlert() async {
    if (_broadcastController.text.isEmpty) return;
    
    await FirebaseFirestore.instance.collection('broadcasts').add({
      'message': _broadcastController.text,
      'time': FieldValue.serverTimestamp(),
      'sender': 'SafePulse HQ',
    });

    _broadcastController.clear();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Emergency Alert Broadcasted to All!")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< Updated upstream
      appBar: AppBar(title: const Text("HQ Command Center"), backgroundColor: Colors.black),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
=======
      backgroundColor: pageBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "ADMIN DASHBOARD",
          style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_active, color: Colors.white70),
            onPressed: () {},
          ),
        ],
      ),
      body: Stack(
        children: [
          Container(
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
                    ? const [0.0, 0.30, 0.68, 1.0]
                    : const [0.0, 0.58, 1.0],
              ),
            ),
          ),
          Positioned(
            top: -90,
            right: -40,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(isDark ? 0.06 : 0.08),
              ),
            ),
          ),
          Positioned(
            top: 140,
            left: -70,
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withOpacity(isDark ? 0.14 : 0.06),
              ),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 118),
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: pageBg,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(34),
                      topRight: Radius.circular(34),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 34),
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
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x22000000),
                                blurRadius: 18,
                                offset: Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white.withOpacity(0.18),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.18),
                                  ),
                                ),
                                child: const Icon(
                                  Icons.admin_panel_settings_rounded,
                                  color: Colors.white,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Admin Control Center",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      "Manage all SafePulse modules from one dashboard.",
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 13,
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
                        Text(
                          "Module Overview",
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1B1B22),
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          crossAxisSpacing: 15,
                          mainAxisSpacing: 15,
                          childAspectRatio: 1.06,
                          children: [
                            _moduleCard(
                              context,
                              "SOS\nManagement",
                              Icons.emergency_share,
                              const Color(0xFFFF4B4B),
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (c) => const SOSManagementPage(),
                                ),
                              ),
                            ),
                            _moduleCard(
                              context,
                              "Community\nRequests",
                              Icons.handshake_rounded,
                              const Color(0xFF3B82F6),
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (c) =>
                                      const CommunityRequestsAdminScreen(),
                                ),
                              ),
                            ),
                            _moduleCard(
                              context,
                              "Lost & Found\nHub",
                              Icons.search_off_rounded,
                              const Color(0xFFF59E0B),
                              () {
                                /* Member 3 Page */
                              },
                            ),
                            _moduleCard(
                              context,
                              "Market\nAnalytics",
                              Icons.shopping_bag_rounded,
                              const Color(0xFF22C55E),
                              () {
                                // --- පියවර: ඔබගේ Marketplace Admin පිටුව මෙතැනින් Navigate වේ ---
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (c) => const MarketAdminHub(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 22),
                        Text(
                          "Broadcast Center",
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1B1B22),
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildBroadcastCard(),
                        const SizedBox(height: 22),
                        Text(
                          "Safety Analytics",
                          style: TextStyle(
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF1B1B22),
                            fontWeight: FontWeight.w900,
                            fontSize: 17,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildSmallAnalytics(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _moduleCard(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    VoidCallback tap,
  ) {
    return GestureDetector(
      onTap: tap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.96), color.withOpacity(0.72)],
          ),
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.20),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
>>>>>>> Stashed changes
        child: Column(
          children: [
            // --- දත්ත සාරාංශය (Real-time Stats) ---
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('users').snapshots(),
              builder: (context, userSnap) {
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('alerts').snapshots(),
                  builder: (context, alertSnap) {
                    int totalUsers = userSnap.data?.docs.length ?? 0;
                    int activeAlerts = alertSnap.data?.docs.where((d) => d['status'] != 'Resolved').length ?? 0;

                    return GridView.count(
                      shrinkWrap: true, crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.5,
                      children: [
                        _statCard("Registered Users", "$totalUsers", Icons.people, Colors.blue),
                        _statCard("Active Emergencies", "$activeAlerts", Icons.warning_amber, Colors.red),
                      ],
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 20),

            // --- EMERGENCY BROADCAST SECTION ---
            Card(
              elevation: 4, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    const Text("⚠️ GLOBAL EMERGENCY BROADCAST", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    const SizedBox(height: 10),
                    TextField(
                      controller: _broadcastController,
                      maxLines: 2,
                      decoration: const InputDecoration(hintText: "Enter urgent notice (e.g. Building C evacuation!)", border: OutlineInputBorder()),
                    ),
                    const SizedBox(height: 15),
                    ElevatedButton(
                      onPressed: _sendBroadcastAlert,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red, minimumSize: const Size(double.infinity, 50)),
                      child: const Text("DISPATCH TO ALL USERS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- MOST COMMON CATEGORY CHART (Placeholder) ---
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(15)),
              child: Column(
                children: [
                  const Text("Safety Metrics Summary", style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  const Text("Highest Threat: Medical 🚑 (45%)", style: TextStyle(color: Colors.blueGrey)),
                  const LinearProgressIndicator(value: 0.45, backgroundColor: Colors.white),
                  const SizedBox(height: 10),
                  const Text("Accident / Crash 💥 (30%)", style: TextStyle(color: Colors.blueGrey)),
                  const LinearProgressIndicator(value: 0.3, backgroundColor: Colors.white),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(15), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
          Text(label, style: const TextStyle(fontSize: 10)),
        ],
      ),
    );
  }
}