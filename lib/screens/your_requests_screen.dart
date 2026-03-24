import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../help/help_request.dart';
import '../help/help_requests_store.dart';
import '../services/help_request_service.dart';
import '../theme/guardian_ui.dart';
import '../widgets/help_request_nearby_style.dart';
import '../widgets/main_bottom_navigation_bar.dart';
import 'help_request_detail_screen.dart';

/// Shared list for [YourRequestsScreen] (Help tab) and [YourRequestsPage] (standalone).
class YourRequestsListContent extends StatelessWidget {
  const YourRequestsListContent({
    super.key,
    this.embedInMainShell = true,
  });

  /// When `true`, pad for [MainBottomNavigationBarView]. When `false`, pad for safe area only.
  final bool embedInMainShell;

  double _bottomScrollPadding(BuildContext context) {
    if (embedInMainShell) return mainFloatingNavScrollPadding(context);
    return MediaQuery.paddingOf(context).bottom + 24;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return const _SignedOutPlaceholder();
    }

    return ValueListenableBuilder<List<HelpRequest>>(
      valueListenable: HelpRequestsStore.instance.requests,
      builder: (context, all, _) {
        final mine = all
            .where((r) => r.creatorUid == uid)
            .toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

        if (mine.isEmpty) {
          return const _EmptyPlaceholder();
        }

        final g = GuardianTheme.of(context);
        return ColoredBox(
          color: g.panelListBg,
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + _bottomScrollPadding(context),
            ),
            itemCount: mine.length,
            itemBuilder: (context, index) {
              return YourRequestNearbyFeaturedCard(
                request: mine[index],
                onEdit: () => _openYourRequestEdit(context, mine[index]),
                onDelete: () => _confirmYourRequestDelete(context, mine[index]),
              );
            },
          ),
        );
      },
    );
  }
}

Future<void> _openYourRequestEdit(BuildContext context, HelpRequest r) async {
  await Navigator.of(context, rootNavigator: true).push<bool>(
    MaterialPageRoute<bool>(
      builder: (_) => HelpRequestDetailScreen(
        category: r.category,
        existingRequest: r,
      ),
    ),
  );
}

Future<void> _confirmYourRequestDelete(BuildContext context, HelpRequest r) async {
  final go = await showDialog<bool>(
    context: context,
    builder: (ctx) {
      final dg = GuardianTheme.of(ctx);
      return AlertDialog(
        backgroundColor: dg.panelBg,
        title: Text(
          'Delete request?',
          style: TextStyle(color: dg.textPrimary, fontWeight: FontWeight.w800),
        ),
        content: Text(
          'Remove this help request? This cannot be undone.',
          style: TextStyle(color: dg.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancel', style: TextStyle(color: dg.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            child: const Text('Delete'),
          ),
        ],
      );
    },
  );
  if (go != true || !context.mounted) return;

  await HelpRequestService.instance.deleteRequest(r.id);
  HelpRequestsStore.instance.removeById(r.id);
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Request deleted')),
  );
}

/// Lists **only** the current user's help requests (by `creatorUid` / `isMine`).
/// Edit & delete are available here — other users never see this list.
class YourRequestsScreen extends StatelessWidget {
  const YourRequestsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const YourRequestsListContent(embedInMainShell: true);
  }
}

class _SignedOutPlaceholder extends StatelessWidget {
  const _SignedOutPlaceholder();

  @override
  Widget build(BuildContext context) {
    final g = GuardianTheme.of(context);
    return ColoredBox(
      color: g.panelListBg,
      child: Center(
        child: Icon(
          Icons.lock_outline_rounded,
          size: 48,
          color: GuardianUi.redPrimary,
        ),
      ),
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  const _EmptyPlaceholder();

  @override
  Widget build(BuildContext context) {
    final g = GuardianTheme.of(context);
    return ColoredBox(
      color: g.panelListBg,
      child: Center(
        child: Icon(
          Icons.inbox_outlined,
          size: 56,
          color: GuardianUi.redPrimary,
        ),
      ),
    );
  }
}
