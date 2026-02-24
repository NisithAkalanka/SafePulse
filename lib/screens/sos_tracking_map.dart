import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SOSTrackingMap extends StatefulWidget {
  final String victimEmail; 
  final String alertId;     

  const SOSTrackingMap({super.key, required this.victimEmail, required this.alertId});

  @override
  State<SOSTrackingMap> createState() => _SOSTrackingMapState();
}

class _SOSTrackingMapState extends State<SOSTrackingMap> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.red[50],
      appBar: AppBar(
        title: Text("Live Track: ${widget.victimEmail.split('@')[0]}"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('alerts').doc(widget.alertId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          var data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null) return const Center(child: Text("Alert no longer active."));

          double lat = double.tryParse(data['lat']?.toString() ?? "0") ?? 0;
          double lng = double.tryParse(data['lng']?.toString() ?? "0") ?? 0;
          String type = data['type'] ?? "General Emergency";

          return Column(
            children: [
              // තාවකාලිකව සැබෑ සිතියම වෙනුවට ලස්සන Visualizer එකක් පෙන්වමු
              Expanded(
                child: Container(
                  width: double.infinity,
                  color: Colors.blue[50],
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.location_on, color: Colors.red, size: 80),
                        const SizedBox(height: 10),
                        const Text("MAP VISUALIZATION ACTIVE", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                        const Text("Real-time GPS Tracking on Signal", style: TextStyle(fontSize: 12, color: Colors.grey)),
                        const SizedBox(height: 20),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                          child: Text("LAT: $lat \nLNG: $lng", textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w600)),
                        )
                      ],
                    ),
                  ),
                ),
              ),
              // අනතුරේ ඉන්න කෙනාගේ තොරතුරු පහළින්
              Container(
                padding: const EdgeInsets.all(30),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(35)),
                ),
                child: Column(
                  children: [
                    Text(type, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.red)),
                    const SizedBox(height: 10),
                    Text("📍 Address: ${data['address'] ?? 'Updating location...'}", textAlign: TextAlign.center),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _callBtn(Icons.phone, "CALL", Colors.green),
                        _callBtn(Icons.directions, "NAVIGATE", Colors.blue),
                      ],
                    )
                  ],
                ),
              )
            ],
          );
        },
      ),
    );
  }

  Widget _callBtn(IconData i, String l, Color c) => ElevatedButton.icon(
    onPressed: () {},
    icon: Icon(i, color: Colors.white),
    label: Text(l, style: const TextStyle(color: Colors.white)),
    style: ElevatedButton.styleFrom(backgroundColor: c, minimumSize: const Size(140, 50)),
  );
}