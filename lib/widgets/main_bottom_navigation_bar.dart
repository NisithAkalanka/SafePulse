import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../screens/sos_system/login_screen.dart';
import '../theme/guardian_ui.dart';

/// Extra bottom space for scrollable tab bodies when the shell uses
/// [Scaffold.extendBody] + [MainBottomNavigationBarView] (content must not sit under the pill).
double mainFloatingNavScrollPadding(BuildContext context) {
  final safe = MediaQuery.paddingOf(context).bottom;
  // Keep in sync with [MainBottomNavigationBarView] outer margin bottom + bar height.
  return safe + 6 + 50;
}

/// Panel-to-nav strip on [HelpRequestDetailScreen] — same value for Request help tab
/// ([mainFloatingNavPanelBottomInset]) so both screens match.
const double kHelpPanelBottomGutter = 18;

/// Visible gap above the floating nav for tab bodies under [Scaffold.extendBody].
/// Uses [kHelpPanelBottomGutter] (same as help request form panel bottom padding) + nav margin.
double mainFloatingNavPanelBottomInset(BuildContext context) {
  final safe = MediaQuery.paddingOf(context).bottom;
  return safe + 6 + kHelpPanelBottomGutter;
}

/// Bottom nav items — must stay in sync with [MainNavigationScreen] tab order.
List<BottomNavigationBarItem> buildMainNavBarItems(String userRole) {
  final items = <BottomNavigationBarItem>[
    const BottomNavigationBarItem(
      icon: Icon(Icons.security_outlined),
      activeIcon: Icon(Icons.security),
      label: 'SOS',
    ),
  ];

  if (userRole == 'admin') {
    items.add(
      const BottomNavigationBarItem(
        icon: Icon(Icons.analytics_outlined),
        activeIcon: Icon(Icons.analytics),
        label: 'DASHBOARD',
      ),
    );
  }

  items.addAll(const [
    BottomNavigationBarItem(
      icon: Icon(Icons.map_outlined),
      activeIcon: Icon(Icons.map_rounded),
      label: 'MAP',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.handshake_outlined),
      activeIcon: Icon(Icons.handshake),
      label: 'HELP',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.search_outlined),
      activeIcon: Icon(Icons.search_rounded),
      label: 'LOST',
    ),
    BottomNavigationBarItem(
      icon: Icon(Icons.store_outlined),
      activeIcon: Icon(Icons.store),
      label: 'MARKET',
    ),
  ]);

  return items;
}

/// Index of the Help tab for the given role (matches [_getScreens] order).
int mainNavHelpTabIndexForRole(String userRole) {
  return userRole == 'admin' ? 3 : 2;
}

/// Same login gate as main shell: SOS is open; other tabs require sign-in.
Future<void> handleMainNavBarTap(
  BuildContext context,
  int index,
  Future<void> Function(int indexAfterAuth) onAuthenticatedTap,
) async {
  if (index == 0) {
    await onAuthenticatedTap(0);
    return;
  }

  if (FirebaseAuth.instance.currentUser == null) {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (context) => const LoginScreen()),
    );

    if (FirebaseAuth.instance.currentUser != null) {
      await onAuthenticatedTap(index);
    }
    return;
  }

  await onAuthenticatedTap(index);
}

/// Visual clone of the home [BottomNavigationBar] (floating pill + colors).
class MainBottomNavigationBarView extends StatelessWidget {
  const MainBottomNavigationBarView({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  final int currentIndex;
  final List<BottomNavigationBarItem> items;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    final idx = currentIndex.clamp(0, items.length - 1);
    final g = GuardianTheme.of(context);
    // Fully opaque so list/content never shows through the floating pill.
    final pillBg = g.panelBg;
    final pillBorder = g.isDark
        ? const Color(0xFF34343F)
        : const Color(0xFFFFD9DD);
    final unselectedTint = g.isDark ? g.captionGrey : const Color(0xFF90A0AC);

    return SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 0, 14, 6),
        decoration: BoxDecoration(
          color: pillBg,
          borderRadius: BorderRadius.circular(34),
          border: Border.all(color: pillBorder, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: g.isDark ? 0.45 : 0.13),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(34),
          child: Theme(
            data: Theme.of(context).copyWith(
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: BottomNavigationBar(
              currentIndex: idx,
              backgroundColor: pillBg,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              showSelectedLabels: false,
              showUnselectedLabels: false,
              selectedItemColor: const Color(0xFFFF5A63),
              unselectedItemColor: unselectedTint,
              onTap: onTap,
              selectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 11,
                letterSpacing: 0.3,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
              iconSize: 28,
              items: items,
            ),
          ),
        ),
      ),
    );
  }
}
