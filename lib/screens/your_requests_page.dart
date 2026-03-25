import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/guardian_ui.dart';
import '../widgets/main_bottom_navigation_bar.dart';
import 'sos_system/main_menu_screen.dart';
import 'your_requests_screen.dart';

/// **Your requests** — opened after submitting a help request (“View Your requests”).
class YourRequestsPage extends StatefulWidget {
  const YourRequestsPage({super.key});

  @override
  State<YourRequestsPage> createState() => _YourRequestsPageState();
}

class _YourRequestsPageState extends State<YourRequestsPage> {
  String _navUserRole = 'student';

  @override
  void initState() {
    super.initState();
    _loadNavUserRole();
  }

  Future<void> _loadNavUserRole() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _navUserRole = 'student');
      return;
    }
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!mounted) return;
      setState(() {
        _navUserRole = (doc.data()?['role'] ?? 'student').toString();
      });
    } catch (_) {
      if (mounted) setState(() => _navUserRole = 'student');
    }
  }

  Future<void> _onMainNavTap(int index) async {
    final helpIdx = mainNavHelpTabIndexForRole(_navUserRole);
    await handleMainNavBarTap(context, index, (resolved) async {
      if (!mounted) return;
      if (resolved == helpIdx) {
        Navigator.of(context).maybePop();
        return;
      }
      if (resolved != 0) {
        await _loadNavUserRole();
      }
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/navigation',
        (_) => false,
        arguments: resolved,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final g = GuardianTheme.of(context);
    final navItems = buildMainNavBarItems(_navUserRole);
    final helpTabIndex = mainNavHelpTabIndexForRole(_navUserRole);

    return Scaffold(
      backgroundColor: g.scaffoldBg,
      extendBody: true,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          'Your requests',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'More',
            icon: const Icon(Icons.more_vert_rounded),
            onPressed: () => MainMenuScreen.showOverlay(context),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            height: 148,
            decoration: BoxDecoration(
              gradient: g.headerGradient,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(34),
                bottomRight: Radius.circular(34),
              ),
            ),
          ),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -24),
              child: Padding(
                padding: EdgeInsets.only(
                  bottom: mainFloatingNavPanelBottomInset(context),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: g.panelBg,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: g.cardShadow,
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: const YourRequestsListContent(
                      embedInMainShell: true,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: MainBottomNavigationBarView(
        currentIndex: helpTabIndex,
        items: navItems,
        onTap: _onMainNavTap,
      ),
    );
  }
}
