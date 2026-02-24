import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // SOS Alert එකක් Firebase වලට යවන හැටි
  Future<void> _sendSOSAlert(BuildContext context) async {
    try {
      // 1. දැනට ලොගින් වෙලා ඉන්න යූසර්ව ගමු
      final user = FirebaseAuth.instance.currentUser;
      
      // 2. යූසර්ගේ ලොකේෂන් (Latitude/Longitude) එක ගමු
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      // 3. Firestore එකේ 'alerts' කියන තැනට data දාමු
      await FirebaseFirestore.instance.collection('alerts').add({
        'email': user?.email,
        'uid': user?.uid,
        'lat': position.latitude,
        'lng': position.longitude,
        'time': FieldValue.serverTimestamp(),
        'type': 'Emergency SOS',
        'status': 'Pending',
      });

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("SOS Alert Sent Successfully!")));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("SafePulse Home")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("Emergency Assistance Needed?", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 30),
            // ලොකු රතු SOS බටන් එක
            GestureDetector(
              onTap: () => _sendSOSAlert(context),
              child: Container(
                width: 200, height: 200,
                decoration: const BoxDecoration(
                  color: Colors.red, shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
                child: const Center(
                  child: Text("SOS", style: TextStyle(color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}