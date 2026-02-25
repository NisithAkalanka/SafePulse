import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MedicalProfileScreen extends StatefulWidget {
  const MedicalProfileScreen({super.key});

  @override
  State<MedicalProfileScreen> createState() => _MedicalProfileScreenState();
}

class _MedicalProfileScreenState extends State<MedicalProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  bool _isLoading = false;

  // මෙඩිකල් විස්තර සඳහා Controllers
  final _bloodTypeCtrl = TextEditingController();
  final _allergiesCtrl = TextEditingController();
  final _diseasesCtrl = TextEditingController();
  final _guardianNameCtrl = TextEditingController();
  final _guardianPhoneCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadMedicalData();
  }

  // කලින් දත්ත තියේනම් ලෝඩ් කරමු
  _loadMedicalData() async {
    setState(() => _isLoading = true);
    var doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    if (doc.exists) {
      var data = doc.data()!;
      setState(() {
        _bloodTypeCtrl.text = data['blood_type'] ?? "";
        _allergiesCtrl.text = data['allergies'] ?? "";
        _diseasesCtrl.text = data['personal_diseases'] ?? "";
        _guardianNameCtrl.text = data['ice_name'] ?? "";
        _guardianPhoneCtrl.text = data['ice_phone'] ?? "";
      });
    }
    setState(() => _isLoading = false);
  }

  // දත්ත Firestore වලට සේව් කිරීම
  _saveMedicalData() async {
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
      'blood_type': _bloodTypeCtrl.text.trim(),
      'allergies': _allergiesCtrl.text.trim(),
      'personal_diseases': _diseasesCtrl.text.trim(),
      'ice_name': _guardianNameCtrl.text.trim(),
      'ice_phone': _guardianPhoneCtrl.text.trim(),
    }, SetOptions(merge: true));

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Medical Record Updated!")));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Medical Information"),
        backgroundColor: Colors.redAccent,
        foregroundColor: Colors.white,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Icon(Icons.medical_information, size: 60, color: Colors.redAccent),
                const SizedBox(height: 20),
                _buildField(_bloodTypeCtrl, "Blood Group (e.g., O+)", Icons.bloodtype),
                _buildField(_allergiesCtrl, "Known Allergies", Icons.warning_amber),
                _buildField(_diseasesCtrl, "Ongoing Medical Conditions", Icons.history_edu),
                const Divider(height: 40),
                const Text("Primary Emergency Contact", style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 15),
                _buildField(_guardianNameCtrl, "Guardian / ICE Name", Icons.person_add_alt_1),
                _buildField(_guardianPhoneCtrl, "Guardian Phone", Icons.phone, type: TextInputType.phone),
                const SizedBox(height: 30),
                ElevatedButton(
                  onPressed: _saveMedicalData,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent, minimumSize: const Size(double.infinity, 55)),
                  child: const Text("SAVE MEDICAL DATA", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                )
              ],
            ),
          ),
    );
  }

  Widget _buildField(TextEditingController c, String l, IconData i, {TextInputType type = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextField(
        controller: c,
        keyboardType: type,
        decoration: InputDecoration(labelText: l, prefixIcon: Icon(i, color: Colors.redAccent), border: const OutlineInputBorder()),
      ),
    );
  }
}