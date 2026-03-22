import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart'; // ඇමතුම් සහ සිතියම් සඳහා අත්‍යවශ්‍යයි

class SOSTrackingMap extends StatefulWidget {
  final String victimEmail;
  final String alertId;

  const SOSTrackingMap({
    super.key,
    required this.victimEmail,
    required this.alertId,
  });

  @override
  State<SOSTrackingMap> createState() => _SOSTrackingMapState();
}

class _SOSTrackingMapState extends State<SOSTrackingMap> {
  // --- සැබෑ සිතියම් යෙදුම (Google/Apple Maps) විවෘත කරන Logic එක ---
  Future<void> _openMapNavigation(double lat, double lng) async {
    // Google Maps URL (Android/iOS දෙකටම)
    final String googleMapsUrl =
        "https://www.google.com/maps/search/?api=1&query=$lat,$lng";
    // Apple Maps URL (iPhone සඳහා විශේෂිතයි)
    final String appleMapsUrl = "http://maps.apple.com/?q=$lat,$lng";

    if (await canLaunchUrl(Uri.parse(googleMapsUrl))) {
      await launchUrl(
        Uri.parse(googleMapsUrl),
        mode: LaunchMode.externalApplication,
      );
    } else if (await canLaunchUrl(Uri.parse(appleMapsUrl))) {
      await launchUrl(
        Uri.parse(appleMapsUrl),
        mode: LaunchMode.externalApplication,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Could not launch Maps app")),
      );
    }
  }

  // --- දුරකථන ඇමතුමක් ලබා ගැනීමේ Logic එක ---
  Future<void> _makeEmergencyCall(String? number) async {
    if (number == null || number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Phone number not available!")),
      );
      return;
    }
    final Uri telUri = Uri.parse("tel:$number");
    if (await canLaunchUrl(telUri)) {
      await launchUrl(telUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDECEA), // ඉතා ලා රතු පැහැති පසුබිමක්
      appBar: AppBar(
        title: Text(
          "Live Track: ${widget.victimEmail.split('@')[0]}",
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('alerts')
            .doc(widget.alertId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(
              child: Text("This alert has been resolved or removed."),
            );
          }

          var data = snapshot.data!.data() as Map<String, dynamic>?;
          if (data == null) return const Center(child: Text("No data found."));

          double lat = double.tryParse(data['lat']?.toString() ?? "0.0") ?? 0.0;
          double lng = double.tryParse(data['lng']?.toString() ?? "0.0") ?? 0.0;
          String type = data['type'] ?? "General Emergency";
          String victimPhone =
              data['user_phone'] ?? ""; // Alert එකේ Phone එක තියෙනවා නම්

          return Column(
            children: [
              // ඉහළ කොටස: GPS තොරතුරු සහ Simulated Map පෙනුම
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.location_on,
                          color: Colors.red,
                          size: 80,
                        ),
                        const SizedBox(height: 10),
                        const Text(
                          "MAP VISUALIZATION ACTIVE",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blueAccent,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const Text(
                          "Receiving live GPS pulses...",
                          style: TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        const SizedBox(height: 25),
                        // Coordinates Display Card
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 25,
                            vertical: 15,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: Text(
                            "LAT: $lat\nLNG: $lng",
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // පහළ කොටස: විස්තර සහ ක්‍රියාකාරී බොත්තම්
              Container(
                padding: const EdgeInsets.fromLTRB(30, 40, 30, 40),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                ),
                child: Column(
                  children: [
                    // Emergency Type Label
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 15,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        type.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      "📍 Location Address:",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      data['address'] ?? 'Tracking location...',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 35),

                    // Buttons Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _callBtn(
                          Icons.phone,
                          "CALL",
                          Colors.green,
                          () => _makeEmergencyCall(victimPhone),
                        ),
                        _callBtn(
                          Icons.directions,
                          "NAVIGATE",
                          Colors.blueAccent,
                          () => _openMapNavigation(lat, lng),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // බොත්තම් නිර්මාණය කරන Helper Widget එක
  Widget _callBtn(
    IconData icon,
    String label,
    Color color,
    VoidCallback onPressed,
  ) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 20),
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        minimumSize: const Size(145, 55),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        elevation: 3,
      ),
    );
  }
}
