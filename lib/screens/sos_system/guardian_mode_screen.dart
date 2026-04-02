import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class GuardianModeScreen extends StatefulWidget {
  const GuardianModeScreen({super.key});

  @override
  State<GuardianModeScreen> createState() => _GuardianModeScreenState();
}

class _GuardianModeScreenState extends State<GuardianModeScreen>
    with SingleTickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;
  final _emailController = TextEditingController();
  bool _isLoading = false;
  late TabController _tabController;

  Color get _red => const Color(0xFFB31217);
  Color get _lightRed => const Color(0xFFFF5A5F);
  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _pageBg =>
      _isDark ? const Color(0xFF121217) : const Color(0xFFF6F7FB);
  Color get _cardBg => _isDark ? const Color(0xFF1B1B22) : Colors.white;
  Color get _softBg =>
      _isDark ? const Color(0xFF23232B) : const Color(0xFFF8F9FC);
  Color get _textPrimary => _isDark ? Colors.white : const Color(0xFF1B1B22);
  Color get _textSecondary =>
      _isDark ? const Color(0xFFB7BBC6) : const Color(0xFF747A86);
  Color get _border =>
      _isDark ? const Color(0xFF34343F) : const Color(0xFFE8EAF0);

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendGuardianRequest() async {
    String recipientEmail = _emailController.text.trim().toLowerCase();
    if (recipientEmail.isEmpty) return;
    if (recipientEmail == user?.email) {
      _showMsg("You cannot invite yourself!");
      return;
    }
    setState(() => _isLoading = true);
    try {
      var userQuery = await FirebaseFirestore.instance
          .collection('users')
          .where('student_email', isEqualTo: recipientEmail)
          .get();
      if (userQuery.docs.isEmpty) {
        _showMsg("This user is not registered on SafePulse.");
      } else {
        await FirebaseFirestore.instance.collection('guardian_requests').add({
          'senderUid': user!.uid,
          'senderEmail': user!.email,
          'recipientEmail': recipientEmail,
          'status': 'pending',
          'timestamp': FieldValue.serverTimestamp(),
        });
        _showMsg("Invite sent to $recipientEmail");
        _emailController.clear();
      }
    } catch (e) {
      _showMsg("Error: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptRequest(
    String requestId,
    String requesterUid,
    String requesterEmail,
  ) async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(requesterUid)
        .update({
          'guardians': FieldValue.arrayUnion([user!.email]),
        });
    await FirebaseFirestore.instance
        .collection('guardian_requests')
        .doc(requestId)
        .delete();
    _showMsg("Now guarding $requesterEmail");
  }

  Future<void> _removeGuardianFromMyList(String email) async {
    await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
      'guardians': FieldValue.arrayRemove([email]),
    });
    _showMsg("Removed $email from your circle");
  }

  Future<void> _confirmRemoveGuardian(String email) async {
    final bool? shouldRemove = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'Remove guardian?',
            style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w800),
          ),
          content: Text(
            '$email will no longer receive your guardian access.',
            style: TextStyle(color: _textSecondary),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: _textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Remove',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldRemove == true) {
      await _removeGuardianFromMyList(email);
    }
  }

  void _showMsg(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _isDark
            ? const Color(0xFF25252E)
            : const Color(0xFF1B1B22),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _pageBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Guardian Network",
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(62),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.12),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.14)),
              ),
              child: TabBar(
                controller: _tabController,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: Colors.white,
                ),
                labelColor: _red,
                unselectedLabelColor: Colors.white70,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(text: "My Circle"),
                  Tab(text: "Incoming Invites"),
                ],
              ),
            ),
          ),
        ),
      ),
      body: _buildPageBackground(
        child: TabBarView(
          controller: _tabController,
          children: [_buildMyGuardiansTab(), _buildInvitesTab()],
        ),
      ),
    );
  }

  Widget _buildMyGuardiansTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
      child: Column(
        children: [
          _buildHeroCard(),
          const SizedBox(height: 16),
          _addGuardianCard(),
          const SizedBox(height: 22),
          _sectionHeader(
            title: "YOUR GUARDIAN CIRCLE",
            subtitle: "People who can keep track of your SOS alerts.",
            icon: Icons.shield_outlined,
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
                  padding: EdgeInsets.all(24),
                  child: CircularProgressIndicator(),
                );
              }

              var userData = snapshot.data?.data() as Map<String, dynamic>?;
              List guardians =
                  (userData != null && userData.containsKey('guardians'))
                  ? userData['guardians']
                  : [];

              if (guardians.isEmpty) {
                return _emptyStatusUI(
                  "No guardians yet. Add trusted people to build your protection circle.",
                );
              }

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: guardians.length,
                itemBuilder: (context, i) =>
                    _guardianTile(guardians[i].toString()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInvitesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('guardian_requests')
          .where('recipientEmail', isEqualTo: user?.email)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        var docs = snapshot.data!.docs;
        if (docs.isEmpty) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
            child: Column(
              children: [
                _sectionHeader(
                  title: "PENDING INVITES",
                  subtitle: "Review the people asking to protect you.",
                  icon: Icons.mail_outline_rounded,
                ),
                const SizedBox(height: 14),
                _emptyStatusUI("No pending invitations right now."),
              ],
            ),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(18, 14, 18, 28),
          itemCount: docs.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: _sectionHeader(
                  title: "PENDING INVITES",
                  subtitle:
                      "Accept trusted people into your SafePulse protection layer.",
                  icon: Icons.mark_email_unread_outlined,
                ),
              );
            }
            var data = docs[i - 1].data() as Map<String, dynamic>;
            return _requestCard(
              docs[i - 1].id,
              (data['senderEmail'] ?? '').toString(),
              (data['senderUid'] ?? '').toString(),
            );
          },
        );
      },
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFFFF4B4B), Color(0xFFB31217)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 18,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.16),
                  border: Border.all(color: Colors.white.withOpacity(0.18)),
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Guardian Protection",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Invite trusted people to watch over your emergency alerts.",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.86),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _heroStatTile(
                  icon: Icons.people_alt_outlined,
                  title: _tabController.index == 0 ? 'My Circle' : 'Invites',
                  subtitle: _tabController.index == 0
                      ? 'Trusted guardians'
                      : 'Awaiting approval',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _heroStatTile(
                  icon: Icons.lock_person_outlined,
                  title: 'SafePulse',
                  subtitle: 'Private safety network',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStatTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.78),
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _addGuardianCard() {
    final Color fieldFill = _isDark ? const Color(0xFF23232B) : Colors.white;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFFE8E8),
                ),
                child: Icon(
                  Icons.person_add_alt_1_rounded,
                  color: _red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Add Guardian",
                      style: TextStyle(
                        color: _textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Send an invite to someone you trust.",
                      style: TextStyle(
                        color: _textSecondary,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              color: fieldFill,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _border),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              children: [
                Icon(
                  Icons.mail_outline_rounded,
                  color: _textSecondary,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(
                      color: _textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      hintText: "Enter Guardian Email",
                      hintStyle: TextStyle(color: _textSecondary),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 46,
                  height: 46,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _sendGuardianRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _red,
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.send_rounded, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _guardianTile(String email) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFFFF5A63), Color(0xFFB31217)],
              ),
            ),
            child: const Icon(
              Icons.person_rounded,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  email,
                  style: TextStyle(
                    fontWeight: FontWeight.w900,
                    color: _textPrimary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Guardian access active",
                  style: TextStyle(
                    color: _textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _softBg,
              border: Border.all(color: _border),
            ),
            child: IconButton(
              padding: EdgeInsets.zero,
              icon: const Icon(
                Icons.remove_circle_outline,
                color: Colors.redAccent,
                size: 22,
              ),
              onPressed: () => _confirmRemoveGuardian(email),
            ),
          ),
        ],
      ),
    );
  }

  Widget _requestCard(String docId, String email, String senderUid) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFE8E8),
                ),
                child: const Icon(
                  Icons.mark_email_read_outlined,
                  color: Color(0xFFB31217),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      email,
                      style: TextStyle(
                        color: _textPrimary,
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "wants to protect you in SafePulse.",
                      style: TextStyle(
                        color: _textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => FirebaseFirestore.instance
                      .collection('guardian_requests')
                      .doc(docId)
                      .delete(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _textPrimary,
                    side: BorderSide(color: _border),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    "Ignore",
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _acceptRequest(docId, senderUid, email),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    "Accept",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPageBackground({required Widget child}) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: _isDark
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
              stops: _isDark
                  ? const [0.0, 0.35, 0.72, 1.0]
                  : const [0.0, 0.62, 1.0],
            ),
          ),
        ),
        Positioned(
          top: -90,
          right: -40,
          child: Container(
            width: 220,
            height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(_isDark ? 0.06 : 0.08),
            ),
          ),
        ),
        Positioned(
          top: 110,
          left: -60,
          child: Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withOpacity(_isDark ? 0.14 : 0.06),
            ),
          ),
        ),
        SafeArea(
          child: Container(
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: _pageBg,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(34),
                topRight: Radius.circular(34),
              ),
            ),
            child: child,
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader({
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFE8E8),
            ),
            child: Icon(icon, color: Color(0xFFB31217)),
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
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: _textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyStatusUI(String m) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFFFFE8E8),
            ),
            child: Icon(Icons.shield_outlined, color: _lightRed, size: 34),
          ),
          const SizedBox(height: 16),
          Text(
            m,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _textSecondary,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
