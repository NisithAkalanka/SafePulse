import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sos_tracking_map.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  // SOS එකක් විසඳුවා (Handled) කියලා සලකුණු කරන්න
  Future<void> _resolveAlert(String docId) async {
    await FirebaseFirestore.instance.collection('alerts').doc(docId).update({
      'status': 'Resolved',
      'resolved_at': FieldValue.serverTimestamp(),
    });
    if(!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Alert Resolved Successfully!")));
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Guardian Security Admin", style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.emergency), text: "Active Alerts"),
              Tab(icon: Icon(Icons.history), text: "History"),
            ],
            indicatorColor: Colors.redAccent,
          ),
        ),
        body: TabBarView(
          children: [
            _alertsList(true), // දැනට දුවන ඇලර්ට්
            _alertsList(false), // විසඳා අවසන් වූ ඒවා
          ],
        ),
      ),
    );
  }

  Widget _alertsList(bool activeOnly) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('alerts')
          .where('status', isEqualTo: activeOnly ? 'Active SOS' : 'Resolved') // 'New Alert' හෝ 'Active SOS' පරීක්ෂා කරන්න
          .orderBy('time', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error: ${snapshot.error}"));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        var alerts = snapshot.data!.docs;
        if (alerts.isEmpty) return Center(child: Text(activeOnly ? "No Active Alerts Found" : "No Past Records"));

        return ListView.builder(
          itemCount: alerts.length,
          padding: const EdgeInsets.all(12),
          itemBuilder: (context, index) {
            var data = alerts[index].data() as Map<String, dynamic>;
            String id = alerts[index].id;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
              child: ExpansionTile(
                leading: CircleAvatar(
                  backgroundColor: activeOnly ? Colors.red : Colors.green,
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                title: Text(data['user_email'] ?? "Unknown", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("🚨 ${data['type'] ?? 'Emergency'}"),
                children: [
                  Padding(
                    padding: const EdgeInsets.all(15.0),
                    child: Column(
                      children: [
                        ListTile(dense: true, leading: const Icon(Icons.location_on), title: Text(data['address'] ?? "No address")),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            ElevatedButton.icon(
                              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SOSTrackingMap(victimEmail: data['user_email'], alertId: id))),
                              icon: const Icon(Icons.map, size: 18), label: const Text("VIEW MAP"),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                            ),
                            if (activeOnly)
                            ElevatedButton.icon(
                              onPressed: () => _resolveAlert(id),
                              icon: const Icon(Icons.check, size: 18), label: const Text("RESOLVE"),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                            ),
                          ],
                        )
                      ],
                    ),
                  )
                ],
              ),
            );
          },
        );
      },
    );
  }
}