import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'group_chat_screen.dart';
import 'group_list_screen.dart';

// නම කෙටි කරගන්නා Helper Function එක
String getShortName(String fullName) {
  if (fullName.trim().isEmpty) return 'User';
  return fullName.trim().split(' ').first;
}

class GuardianModeScreen extends StatefulWidget {
  const GuardianModeScreen({super.key});

  @override
  State<GuardianModeScreen> createState() => _GuardianModeScreenState();
}

class _GuardianModeScreenState extends State<GuardianModeScreen>
    with SingleTickerProviderStateMixin {
  final User? user = FirebaseAuth.instance.currentUser;
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  late TabController _tabController;

  // Theme Colors
  Color get _red => const Color(0xFFB31217);
  Color get _lightRed => const Color(0xFFFF5A5F);
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _pageBg => const Color(0xFF12131D);
  Color get _cardBg => _isDark ? const Color(0xFF1A1B27) : Colors.white;
  Color get _cardBorder =>
      _isDark ? const Color(0xFF2A2C3A) : const Color(0xFFE7E9F0);
  Color get _textPrimary => _isDark ? Colors.white : const Color(0xFF171824);
  Color get _textSecondary =>
      _isDark ? const Color(0xFFB7BBC8) : const Color(0xFF717686);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  // --- 1. Guardian Request Logic (Mutual Connection) ---

  Future<void> _sendGuardianRequest() async {
    final String recipientEmail = _emailController.text.trim().toLowerCase();
    if (recipientEmail.isEmpty) return;
    if (recipientEmail == user?.email) {
      _showMsg('You cannot invite yourself!');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('student_email', isEqualTo: recipientEmail)
          .get();

      if (userQuery.docs.isEmpty) {
        _showMsg('This user is not registered on SafePulse.');
      } else {
        await FirebaseFirestore.instance.collection('guardian_requests').add({
          'senderUid': user!.uid,
          'senderEmail': user!.email,
          'recipientEmail': recipientEmail,
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
        });
        _showMsg('Invite sent to $recipientEmail');
        _emailController.clear();
      }
    } catch (e) {
      _showMsg('Error: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptGuardianRequest(
    String requestId,
    String requesterUid,
    String requesterEmail,
  ) async {
    // දෙන්නාගෙම ගාඩියන් ලිස්ට් එකට එකතු කරනවා (Mutual Connection)
    await FirebaseFirestore.instance
        .collection('users')
        .doc(requesterUid)
        .update({
          'guardians': FieldValue.arrayUnion([user!.email]),
        });
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'guardians': FieldValue.arrayUnion([requesterEmail]),
    });

    await FirebaseFirestore.instance
        .collection('guardian_requests')
        .doc(requestId)
        .delete();
    _showMsg('Now guarding each other!');
  }

  // --- 2. Chat Invite & System Message Logic ---

  Future<void> _sendChatInvite(String guardianEmail) async {
    try {
      final String cleanEmail = guardianEmail.trim().toLowerCase();
      final userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('student_email', isEqualTo: cleanEmail)
          .limit(1)
          .get();

      if (userQuery.docs.isEmpty) return;
      String recipientUid = userQuery.docs.first.id;

      await FirebaseFirestore.instance.collection('chat_requests').add({
        'senderUid': user!.uid,
        'senderEmail': user!.email,
        'recipientUid': recipientUid,
        'status': 'pending',
        'timestamp': FieldValue.serverTimestamp(),
      });
      _showMsg('Group chat invite sent to ${getShortName(cleanEmail)}!');
    } catch (e) {
      _showMsg('Error sending chat invite: $e');
    }
  }

  Future<void> _acceptChatInvite(String requestId, String adminUid) async {
    // 1. මගේ නම ගන්න
    final userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user!.uid)
        .get();
    String myName = (userDoc.data()?['full_name'] ?? "Someone")
        .toString()
        .split(' ')
        .first;

    final groupRef = FirebaseFirestore.instance
        .collection('groups')
        .doc(adminUid);

    // 2. Group එකට add කරනවා
    await groupRef.set({
      'members': FieldValue.arrayUnion([user!.uid]),
      'memberEmails': FieldValue.arrayUnion([
        (user!.email ?? '').trim().toLowerCase(),
      ]),
      'adminId': adminUid,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    // 3. System message එක (join message)
    await groupRef.collection('messages').add({
      'text': '$myName joined the protection circle',
      'type': 'system',
      'timestamp': FieldValue.serverTimestamp(),
    });

    // 4. request delete කරනවා
    await FirebaseFirestore.instance
        .collection('chat_requests')
        .doc(requestId)
        .delete();

    _showMsg('Joined the group chat!');

    // 5. chat screen එකට navigate වෙනවා
    if (mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => GroupChatScreen(groupId: adminUid)),
      );
    }
  }

  // --- UI Components ---

  void _showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Guardian Network',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w900,
            fontSize: 22,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const GroupListScreen()),
          );
        },
        backgroundColor: _red,
        icon: const Icon(Icons.forum_rounded, color: Colors.white),
        label: const Text(
          'Safety Chats',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFF525B),
              Color(0xFFFF1E2D),
              Color(0xFFB10814),
              Color(0xFF23030A),
            ],
            stops: [0.0, 0.24, 0.58, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [_buildMyGuardiansTab(), _buildInvitesTab()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMyGuardiansTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      child: Column(
        children: [
          _buildCompactHeaderCard(
            title: 'My Circle',
            subtitle: 'Manage trusted guardians.',
            icon: Icons.shield_outlined,
          ),
          const SizedBox(height: 16),
          _buildTopToggleRow(),
          const SizedBox(height: 20),
          _buildMainActionCard(),
          const SizedBox(height: 18),
          _sectionTitleCard(
            icon: Icons.shield_outlined,
            title: 'Your Guardian Circle',
            subtitle: 'Trusted people in your network.',
          ),
          const SizedBox(height: 12),
          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .doc(user!.uid)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.only(top: 18),
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }
              final List guardians =
                  (snapshot.data?.data() as Map?)?['guardians'] ?? [];
              if (guardians.isEmpty) {
                return _emptyStatusUI(
                  'No guardians added yet. Tap “Add New Guardian” to build your circle.',
                );
              }
              return Column(
                children: guardians
                    .map<Widget>((e) => _guardianTile(e.toString()))
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _guardianTile(String email) {
    final String cleanEmail = email.trim().toLowerCase();
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance
          .collection('users')
          .where('student_email', isEqualTo: cleanEmail)
          .limit(1)
          .get(),
      builder: (context, snapshot) {
        String name = getShortName(cleanEmail);
        String targetUid = "";

        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          final Map<String, dynamic> data =
              snapshot.data!.docs.first.data() as Map<String, dynamic>;
          targetUid = snapshot.data!.docs.first.id;
          final String fullName =
              data['full_name'] ?? data['name'] ?? cleanEmail;
          name = getShortName(fullName);
        }

        // බලනවා මේ ගාඩියන් දැනටමත් මගේ ගෲප් එකේ ඉන්නවද කියලා
        return StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('groups')
              .doc(user!.uid)
              .snapshots(),
          builder: (context, groupSnap) {
            bool alreadyInGroup = false;
            if (groupSnap.hasData && groupSnap.data!.exists) {
              List members = (groupSnap.data!.data() as Map)['members'] ?? [];
              alreadyInGroup = members.contains(targetUid);
            }

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _cardBorder),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: _red.withOpacity(0.1),
                    child: Icon(Icons.person, color: _red),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: TextStyle(
                            color: _textPrimary,
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          cleanEmail,
                          style: TextStyle(color: _textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(
                      Icons.remove_circle_outline_rounded,
                      color: Colors.redAccent,
                    ),
                    onPressed: () => _confirmRemoveGuardian(cleanEmail),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildInvitesTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
      child: Column(
        children: [
          _buildCompactHeaderCard(
            title: 'Invites',
            subtitle: 'Review guardian invitations quickly.',
            icon: Icons.mark_email_unread_outlined,
          ),
          const SizedBox(height: 16),
          _buildTopToggleRow(),
          const SizedBox(height: 20),
          _sectionTitleCard(
            icon: Icons.person_add_alt_1_rounded,
            title: 'Guardian Requests',
            subtitle: 'People who want to protect you.',
          ),
          const SizedBox(height: 12),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('guardian_requests')
                .where('recipientEmail', isEqualTo: user?.email)
                .where('status', isEqualTo: 'pending')
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.only(top: 18),
                  child: CircularProgressIndicator(color: Colors.white),
                );
              }
              final docs = snapshot.data!.docs;
              if (docs.isEmpty) {
                return _emptyStatusUI('No guardian requests right now.');
              }
              return Column(
                children: docs
                    .map(
                      (doc) => _requestCard(
                        doc.id,
                        doc['senderEmail'],
                        doc['senderUid'],
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _requestCard(String id, String email, String uid) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.security, color: _red, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "$email wants to protect you.",
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => FirebaseFirestore.instance
                      .collection('guardian_requests')
                      .doc(id)
                      .delete(),
                  child: const Text("Ignore"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  onPressed: () => _acceptGuardianRequest(id, uid, email),
                  child: const Text(
                    "Accept",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chatRequestCard(String id, String email, String adminUid) {
    return Container(
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.group_add, color: Colors.blue, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "$email invited you to a chat.",
                  style: TextStyle(
                    color: _textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => FirebaseFirestore.instance
                      .collection('chat_requests')
                      .doc(id)
                      .delete(),
                  child: const Text("Ignore"),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                  onPressed: () => _acceptChatInvite(id, adminUid),
                  child: const Text(
                    "Join Chat",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Utility UI Builders ---

  Widget _buildCompactHeaderCard({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF5A63), Color(0xFFD60B18)],
        ),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white24),
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopToggleRow() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          Expanded(
            child: _topPillButton(
              title: 'My Circle',
              isActive: _tabController.index == 0,
              onTap: () => _tabController.animateTo(0),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _topPillButton(
              title: 'Invites',
              isActive: _tabController.index == 1,
              onTap: () => _tabController.animateTo(1),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topPillButton({
    required String title,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isActive ? _red : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isActive
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.16),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ]
            : [],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Center(
              child: Text(
                title,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMainActionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.18),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _red.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_alt_rounded,
              size: 38,
              color: Color(0xFFB31217),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Guardian Network',
            style: TextStyle(
              color: _textPrimary,
              fontWeight: FontWeight.bold,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Invite trusted people and keep your protection circle ready.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _red,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: _showAddGuardianDialog,
              child: const Text(
                "Add New Guardian",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitleCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _red.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: _red),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _textPrimary,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyStatusUI(String msg) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white24),
      ),
      child: Column(
        children: [
          Icon(
            Icons.inbox_rounded,
            color: Colors.white.withOpacity(0.75),
            size: 34,
          ),
          const SizedBox(height: 10),
          Text(
            msg,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withOpacity(0.82),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRemoveGuardian(String email) async {
    bool? confirm = await showDialog(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text("Remove?"),
        content: Text("Remove $email from your circle?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text("Yes"),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .update({
            'guardians': FieldValue.arrayRemove([email]),
          });
      _showMsg('Removed $email');
    }
  }

  Future<void> _showAddGuardianDialog() async {
    _emailController.clear();
    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: _cardBg,
        title: Text("Add Guardian", style: TextStyle(color: _textPrimary)),
        content: TextField(
          controller: _emailController,
          decoration: const InputDecoration(hintText: "Enter email"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              _sendGuardianRequest();
              Navigator.pop(c);
            },
            child: const Text("Invite"),
          ),
        ],
      ),
    );
  }
}
