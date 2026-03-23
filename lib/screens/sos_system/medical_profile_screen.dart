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

  final _formKey = GlobalKey<FormState>();
  final List<String> _bloodGroups = const [
    'O-',
    'O+',
    'A-',
    'A+',
    'B-',
    'B+',
    'AB-',
    'AB+',
  ];

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
    var doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();
    if (doc.exists) {
      var data = doc.data()!;
      setState(() {
        final rawBloodType = (data['blood_type'] ?? '')
            .toString()
            .trim()
            .toUpperCase();
        final normalizedBloodType = rawBloodType
            .replaceFirst(RegExp(r'^0'), 'O')
            .replaceAll(' ', '');
        _bloodTypeCtrl.text = _bloodGroups.contains(normalizedBloodType)
            ? normalizedBloodType
            : '';
        _allergiesCtrl.text = (data['allergies'] ?? '').toString();
        _diseasesCtrl.text = (data['personal_diseases'] ?? '').toString();
        _guardianNameCtrl.text = (data['ice_name'] ?? '').toString();
        _guardianPhoneCtrl.text = (data['ice_phone'] ?? '').toString();
      });
    }
    setState(() => _isLoading = false);
  }

  // දත්ත Firestore වලට සේව් කිරීම
  Future<void> _saveMedicalData() async {
    FocusScope.of(context).unfocus();
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter valid medical information."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance.collection('users').doc(user!.uid).set({
        'blood_type': _bloodTypeCtrl.text.trim(),
        'allergies': _allergiesCtrl.text.trim(),
        'personal_diseases': _diseasesCtrl.text.trim(),
        'ice_name': _guardianNameCtrl.text.trim(),
        'ice_phone': _guardianPhoneCtrl.text.trim(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Medical Record Updated!")));
      Navigator.pop(context);
    } catch (e) {
      debugPrint('Failed to save medical data: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Save failed. Please try again."),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color pageBg = isDark
        ? const Color(0xFF121217)
        : const Color(0xFFF6F7FB);
    final Color cardBg = isDark ? const Color(0xFF1B1B22) : Colors.white;
    final Color textPrimary = isDark ? Colors.white : const Color(0xFF1B1B22);
    final Color textSecondary = isDark
        ? const Color(0xFFB7BBC6)
        : const Color(0xFF747A86);
    final Color fieldFill = isDark ? const Color(0xFF23232B) : Colors.white;
    final Color fieldBorder = isDark
        ? const Color(0xFF34343F)
        : const Color(0xFFE2E5EC);
    return Scaffold(
      backgroundColor: pageBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Medical Information",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFB31217)),
            )
          : Stack(
              children: [
                Container(
                  height: 260,
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
                          ? const [0.0, 0.35, 0.72, 1.0]
                          : const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
                Positioned(
                  top: -80,
                  right: -30,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: (isDark ? Colors.white : Colors.white).withOpacity(
                        isDark ? 0.06 : 0.08,
                      ),
                    ),
                  ),
                ),
                SafeArea(
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 30),
                      child: Column(
                        children: [
                          const SizedBox(height: 8),
                          Container(
                            decoration: BoxDecoration(
                              color: pageBg,
                              borderRadius: BorderRadius.circular(30),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color(0x14000000),
                                  blurRadius: 18,
                                  offset: Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                22,
                                18,
                                24,
                              ),
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
                                        colors: [
                                          Color(0xFFFF4B4B),
                                          Color(0xFFB31217),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(24),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x22000000),
                                          blurRadius: 16,
                                          offset: Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: const Row(
                                      children: [
                                        CircleAvatar(
                                          radius: 24,
                                          backgroundColor: Color(0x33FFFFFF),
                                          child: Icon(
                                            Icons.medical_information,
                                            color: Colors.white,
                                            size: 26,
                                          ),
                                        ),
                                        SizedBox(width: 14),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Emergency Medical Record",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w900,
                                                ),
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                "Add health and emergency contact details for safer response.",
                                                style: TextStyle(
                                                  color: Colors.white70,
                                                  fontSize: 12.5,
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
                                  Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      color: cardBg,
                                      borderRadius: BorderRadius.circular(22),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x10000000),
                                          blurRadius: 14,
                                          offset: Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Health Details",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                            color: textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "These details help others respond quickly in an emergency.",
                                          style: TextStyle(
                                            color: textSecondary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        _buildBloodGroupDropdown(
                                          isDark: isDark,
                                          fieldFill: fieldFill,
                                          fieldBorder: fieldBorder,
                                          textPrimary: textPrimary,
                                        ),
                                        _buildField(
                                          _allergiesCtrl,
                                          "Known Allergies",
                                          Icons.warning_amber,
                                          validator: (value) {
                                            final v = (value ?? '').trim();
                                            if (v.isEmpty)
                                              return 'Allergies field is required';
                                            if (v.length > 30)
                                              return 'Max 30 characters allowed';
                                            if (!RegExp(
                                              r'^[A-Za-z ,]+$',
                                            ).hasMatch(v)) {
                                              return 'Letters only';
                                            }
                                            return null;
                                          },
                                          isDark: isDark,
                                          fieldFill: fieldFill,
                                          fieldBorder: fieldBorder,
                                        ),
                                        _buildField(
                                          _diseasesCtrl,
                                          "Ongoing Medical Conditions",
                                          Icons.history_edu,
                                          isDark: isDark,
                                          fieldFill: fieldFill,
                                          fieldBorder: fieldBorder,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Container(
                                    padding: const EdgeInsets.all(18),
                                    decoration: BoxDecoration(
                                      color: cardBg,
                                      borderRadius: BorderRadius.circular(22),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x10000000),
                                          blurRadius: 14,
                                          offset: Offset(0, 6),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Primary Emergency Contact",
                                          style: TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 16,
                                            color: textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "Add the main person who should be contacted immediately.",
                                          style: TextStyle(
                                            color: textSecondary,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(height: 16),
                                        _buildField(
                                          _guardianNameCtrl,
                                          "Guardian / ICE Name",
                                          Icons.person_add_alt_1,
                                          validator: (value) {
                                            final v = (value ?? '').trim();
                                            if (v.isEmpty)
                                              return 'Guardian name is required';
                                            if (!RegExp(
                                              r'^[A-Za-z ]{1,10}$',
                                            ).hasMatch(v)) {
                                              return 'Letters only, max 10 characters';
                                            }
                                            return null;
                                          },
                                          isDark: isDark,
                                          fieldFill: fieldFill,
                                          fieldBorder: fieldBorder,
                                        ),
                                        _buildField(
                                          _guardianPhoneCtrl,
                                          "Guardian Phone",
                                          Icons.phone,
                                          type: TextInputType.phone,
                                          validator: (value) {
                                            final v = (value ?? '').trim();
                                            if (v.isEmpty)
                                              return 'Guardian phone is required';
                                            if (!RegExp(
                                              r'^0\d{9}$',
                                            ).hasMatch(v)) {
                                              return 'Must be 10 digits, start with 0';
                                            }
                                            return null;
                                          },
                                          isDark: isDark,
                                          fieldFill: fieldFill,
                                          fieldBorder: fieldBorder,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 28),
                                  Container(
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Color(0xFFFF4B4B),
                                          Color(0xFFB31217),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(18),
                                      boxShadow: const [
                                        BoxShadow(
                                          color: Color(0x22000000),
                                          blurRadius: 16,
                                          offset: Offset(0, 8),
                                        ),
                                      ],
                                    ),
                                    child: ElevatedButton(
                                      onPressed: _saveMedicalData,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        minimumSize: const Size(
                                          double.infinity,
                                          58,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            18,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        "SAVE MEDICAL DATA",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildBloodGroupDropdown({
    required bool isDark,
    required Color fieldFill,
    required Color fieldBorder,
    required Color textPrimary,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: DropdownButtonFormField<String>(
        value: _bloodGroups.contains(_bloodTypeCtrl.text)
            ? _bloodTypeCtrl.text
            : null,
        items: _bloodGroups
            .map(
              (group) => DropdownMenuItem<String>(
                value: group,
                child: Text(group, style: TextStyle(color: textPrimary)),
              ),
            )
            .toList(),
        onChanged: (value) {
          setState(() {
            _bloodTypeCtrl.text = value ?? '';
          });
        },
        dropdownColor: fieldFill,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Blood group is required';
          }
          if (!_bloodGroups.contains(value)) {
            return 'Select a valid blood group';
          }
          return null;
        },
        decoration: InputDecoration(
          labelText: 'Blood Group',
          prefixIcon: const Icon(Icons.bloodtype, color: Color(0xFFB31217)),
          filled: true,
          fillColor: fieldFill,
          labelStyle: TextStyle(
            color: isDark ? const Color(0xFFB7BBC6) : const Color(0xFF666C78),
            fontWeight: FontWeight.w600,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: fieldBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: fieldBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFB31217), width: 1.4),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController c,
    String l,
    IconData i, {
    TextInputType type = TextInputType.text,
    String? Function(String?)? validator,
    bool isDark = false,
    Color fieldFill = Colors.white,
    Color fieldBorder = const Color(0xFFE2E5EC),
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        controller: c,
        keyboardType: type,
        validator: validator,
        style: TextStyle(
          color: isDark ? Colors.white : const Color(0xFF1B1B22),
        ),
        decoration: InputDecoration(
          labelText: l,
          prefixIcon: Icon(i, color: const Color(0xFFB31217)),
          filled: true,
          fillColor: fieldFill,
          labelStyle: TextStyle(
            color: isDark ? const Color(0xFFB7BBC6) : const Color(0xFF666C78),
            fontWeight: FontWeight.w600,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 18,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: fieldBorder),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: fieldBorder),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xFFB31217), width: 1.4),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Colors.redAccent, width: 1.4),
          ),
        ),
      ),
    );
  }
}
