import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
      appBar: AppBar(title: const Text("HQ Command Center"), backgroundColor: Colors.black),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15),
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