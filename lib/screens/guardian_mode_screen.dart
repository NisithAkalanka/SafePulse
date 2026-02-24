import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GuardianModeScreen extends StatefulWidget {
  const GuardianModeScreen({super.key});

  @override
  State<GuardianModeScreen> createState() => _GuardianModeScreenState();
}

class _GuardianModeScreenState extends State<GuardianModeScreen> {
  final user = FirebaseAuth.instance.currentUser;
  final _emailController = TextEditingController();
  bool _isLoading = false;

  // 1. යාළුවෙක්ව සෙවීම සහ ඇඩ් කිරීම
  Future<void> _addGuardian() async {
    String email = _emailController.text.trim().toLowerCase();
    if (email.isEmpty) return;
    if (email == user?.email) {
      _showMsg("You cannot add yourself as a guardian!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Firebase එකේ මේ Email එකෙන් කවුරුහරි රෙජිස්ටර් වෙලා ඉන්නවද බලමු
      var query = await FirebaseFirestore.instance
          .collection('users')
          .where('student_email', isEqualTo: email)
          .get();

      if (query.docs.isEmpty) {
        _showMsg("This user is not registered on SafePulse.");
      } else {
        // ඔයාගේ 'guardians' array එකට මේ email එක ඇතුළත් කරමු
        await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
          'guardians': FieldValue.arrayUnion([email])
        });
        _showMsg("✅ Guardian added successfully!");
        _emailController.clear();
      }
    } catch (e) {
      _showMsg("Error: $e");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // 2. ගාර්ඩියන් කෙනෙක් ඉවත් කිරීම
  Future<void> _removeGuardian(String email) async {
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'guardians': FieldValue.arrayRemove([email])
    });
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Guardian Circle", style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Top Instruction Box
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.red[50],
            child: const Row(
              children: [
                Icon(Icons.shield, color: Colors.redAccent, size: 30),
                SizedBox(width: 15),
                Expanded(
                  child: Text(
                    "Your Guardians will receive high-priority alerts and live location during your SOS emergencies.",
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      hintText: "Add via Student Email...",
                      prefixIcon: const Icon(Icons.email_outlined),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
                      filled: true,
                      fillColor: Colors.grey[100],
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _isLoading ? null : _addGuardian,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.redAccent, borderRadius: BorderRadius.circular(15)),
                    child: _isLoading 
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.add, color: Colors.white, size: 30),
                  ),
                ),
              ],
            ),
          ),

          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Divider(),
          ),

          const Text("MY CURRENT GUARDIANS", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 12)),

          // ලයිස්තුව පෙන්වීම (StreamBuilder එකෙන් කරන්නේ dynamic refresh වෙන එක)
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                
                var userData = snapshot.data!.data() as Map<String, dynamic>?;
                List guardians = userData?['guardians'] ?? [];

                if (guardians.isEmpty) {
                  return const Center(
                    child: Text("You haven't added any guardians yet.", style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  itemCount: guardians.length,
                  padding: const EdgeInsets.all(10),
                  itemBuilder: (context, index) {
                    return Card(
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                        side: BorderSide(color: Colors.grey.shade200),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.blueAccent,
                          child: Icon(Icons.person, color: Colors.white),
                        ),
                        title: Text(guardians[index], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        subtitle: const Text("Trusted Contact", style: TextStyle(fontSize: 12)),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                          onPressed: () => _removeGuardian(guardians[index]),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}