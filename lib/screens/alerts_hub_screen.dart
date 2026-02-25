import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'sos_tracking_map.dart'; // කලින් අපි හදපු map පේජ් එක

class AlertsHubScreen extends StatelessWidget {
  const AlertsHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Active Safety Alerts", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      // Firestore එකේ තියෙන alerts සජීවීව ලෝඩ් කරනවා
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('alerts')
            .orderBy('time', descending: true) // අලුත්ම ඒවා උඩට ගමු
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          var alerts = snapshot.data!.docs;

          if (alerts.isEmpty) {
            return const Center(child: Text("No emergency alerts at the moment."));
          }

          return ListView.builder(
            itemCount: alerts.length,
            padding: const EdgeInsets.all(10),
            itemBuilder: (context, index) {
              var data = alerts[index].data() as Map<String, dynamic>;
              String docId = alerts[index].id;

              return Card(
                color: Colors.red[50],
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                child: ListTile(
                  leading: const CircleAvatar(backgroundColor: Colors.red, child: Icon(Icons.warning, color: Colors.white)),
                  title: Text(data['user_email'] ?? "Unknown User", style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text("Type: ${data['type']} \n📍 ${data['address']}"),
                  isThreeLine: true,
                  trailing: const Icon(Icons.map_outlined, color: Colors.redAccent),
                  onTap: () {
                    // අන්න දැන් මේක Click කළාම තමයි Map එකට යන්නේ!
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SOSTrackingMap(
                          victimEmail: data['user_email'] ?? "Victim",
                          alertId: docId,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}