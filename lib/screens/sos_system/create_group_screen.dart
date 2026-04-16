import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class _GuardianOption {
  final String uid;
  final String email;
  final String displayName;
  final String shortName;

  const _GuardianOption({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.shortName,
  });
}

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final TextEditingController _nameController = TextEditingController();
  final List<String> _selectedUids = [];
  final List<String> _selectedEmails = [];
  final user = FirebaseAuth.instance.currentUser;
  late Future<List<_GuardianOption>> _guardiansFuture;

  @override
  void initState() {
    super.initState();
    _guardiansFuture = _loadGuardians();
  }

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _pageBg =>
      _isDark ? const Color(0xFF0B141A) : const Color(0xFFF6F7FB);
  Color get _surfaceColor => _isDark ? const Color(0xFF111B21) : Colors.white;
  Color get _surfaceSoft =>
      _isDark ? const Color(0xFF17212B) : const Color(0xFFFDF2F2);
  Color get _borderColor =>
      _isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFFFD6D6);
  Color get _primaryRed => const Color(0xFFB31217);
  Color get _secondaryRed => const Color(0xFFE53935);
  Color get _textPrimary => _isDark ? Colors.white : const Color(0xFF1F2937);
  Color get _textSecondary =>
      _isDark ? const Color(0xFF9FB3C8) : const Color(0xFF6B7280);
  Color get _hintColor =>
      _isDark ? const Color(0xFF6B7C93) : const Color(0xFF9CA3AF);

  String _getShortName(String fullName) {
    final trimmed = fullName.trim();
    if (trimmed.isEmpty) return 'User';
    return trimmed.split(' ').first;
  }

  Future<List<_GuardianOption>> _loadGuardians() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();

    final userData = userDoc.data() as Map<String, dynamic>?;
    final List guardians = userData?['guardians'] ?? [];

    final List<_GuardianOption> items = [];

    for (final guardian in guardians) {
      final email = guardian.toString().trim().toLowerCase();
      final userSnap = await FirebaseFirestore.instance
          .collection('users')
          .where('student_email', isEqualTo: email)
          .limit(1)
          .get();

      if (userSnap.docs.isEmpty) continue;

      final data = userSnap.docs.first.data();
      final fullName = (data['full_name'] ?? data['name'] ?? email)
          .toString()
          .trim();

      items.add(
        _GuardianOption(
          uid: userSnap.docs.first.id,
          email: email,
          displayName: fullName,
          shortName: _getShortName(fullName),
        ),
      );
    }

    return items;
  }

  void _createGroup() async {
    if (_nameController.text.trim().isEmpty || _selectedUids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a name and select members")),
      );
      return;
    }

    try {
      List<String> allMembers = List.from(_selectedUids);
      allMembers.add(user!.uid);

      List<String> allEmails = List.from(_selectedEmails);
      allEmails.add(user!.email!);

      final adminDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      final adminData = adminDoc.data() as Map<String, dynamic>?;
      final String adminFullName =
          (adminData?['full_name'] ??
                  adminData?['name'] ??
                  user!.email!.split('@').first)
              .toString();
      final String adminShortName = adminFullName.trim().isEmpty
          ? user!.email!.split('@').first
          : adminFullName.trim().split(' ').first;

      DocumentReference newGroup = await FirebaseFirestore.instance
          .collection('groups')
          .add({
            'groupName': _nameController.text.trim(),
            'adminId': user!.uid,
            'adminEmail': user!.email,
            'members': allMembers,
            'memberEmails': allEmails,
            'createdAt': FieldValue.serverTimestamp(),
          });

      await newGroup.collection('messages').add({
        'text':
            '$adminShortName created the group "${_nameController.text.trim()}"',
        'type': 'system',
        'timestamp': FieldValue.serverTimestamp(),
      });

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        backgroundColor: _primaryRed,
        foregroundColor: Colors.white,
        title: const Text(
          "New Safety Group",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
              decoration: BoxDecoration(
                color: _primaryRed,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(28),
                ),
              ),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(_isDark ? 0.08 : 0.18),
                      Colors.white.withOpacity(_isDark ? 0.03 : 0.08),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(_isDark ? 0.08 : 0.18),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      height: 58,
                      width: 58,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.14),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.groups_rounded,
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
                            'Create a new circle',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Name your group and choose trusted guardians.',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: FutureBuilder<List<_GuardianOption>>(
                future: _guardiansFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(
                        color: _primaryRed,
                        strokeWidth: 3,
                      ),
                    );
                  }

                  final guardians = snapshot.data ?? const <_GuardianOption>[];

                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
                          decoration: BoxDecoration(
                            color: _surfaceColor,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: _borderColor),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(
                                  _isDark ? 0.18 : 0.05,
                                ),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _nameController,
                            style: TextStyle(
                              color: _textPrimary,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: InputDecoration(
                              border: InputBorder.none,
                              hintText: 'Enter Group Name',
                              hintStyle: TextStyle(
                                color: _hintColor,
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                              prefixIcon: Icon(
                                Icons.edit_rounded,
                                color: _primaryRed,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: _surfaceColor,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: _borderColor),
                          ),
                          child: Row(
                            children: [
                              Container(
                                height: 46,
                                width: 46,
                                decoration: BoxDecoration(
                                  color: _surfaceSoft,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.people_alt_rounded,
                                  color: _primaryRed,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Select members',
                                      style: TextStyle(
                                        color: _textPrimary,
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      '${_selectedUids.length} selected',
                                      style: TextStyle(
                                        color: _textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                        if (guardians.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              color: _surfaceColor,
                              borderRadius: BorderRadius.circular(22),
                              border: Border.all(color: _borderColor),
                            ),
                            child: Text(
                              'No guardians available yet.',
                              style: TextStyle(
                                color: _textSecondary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        else
                          ...guardians.map((guardian) {
                            final selected = _selectedUids.contains(
                              guardian.uid,
                            );

                            return Container(
                              margin: const EdgeInsets.only(bottom: 12),
                              decoration: BoxDecoration(
                                color: _surfaceColor,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: selected ? _primaryRed : _borderColor,
                                  width: selected ? 1.4 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(
                                      _isDark ? 0.14 : 0.04,
                                    ),
                                    blurRadius: 14,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: CheckboxListTile(
                                value: selected,
                                activeColor: _primaryRed,
                                checkColor: Colors.white,
                                side: BorderSide(
                                  color: selected
                                      ? _primaryRed
                                      : _textSecondary,
                                  width: 1.6,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 6,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                                secondary: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: _surfaceSoft,
                                  child: Text(
                                    guardian.shortName.isNotEmpty
                                        ? guardian.shortName[0].toUpperCase()
                                        : 'U',
                                    style: TextStyle(
                                      color: _primaryRed,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  guardian.displayName,
                                  style: TextStyle(
                                    color: _textPrimary,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                subtitle: Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    guardian.email,
                                    style: TextStyle(
                                      color: _textSecondary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                onChanged: (val) {
                                  setState(() {
                                    if (val ?? false) {
                                      if (!_selectedUids.contains(
                                        guardian.uid,
                                      )) {
                                        _selectedUids.add(guardian.uid);
                                      }
                                      if (!_selectedEmails.contains(
                                        guardian.email,
                                      )) {
                                        _selectedEmails.add(guardian.email);
                                      }
                                    } else {
                                      _selectedUids.remove(guardian.uid);
                                      _selectedEmails.remove(guardian.email);
                                    }
                                  });
                                },
                              ),
                            );
                          }),
                      ],
                    ),
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryRed,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    onPressed: _createGroup,
                    child: const Text(
                      "Create Group",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }
}
