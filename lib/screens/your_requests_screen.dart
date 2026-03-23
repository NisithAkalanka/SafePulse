import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../help/help_request.dart';
import '../help/help_requests_store.dart';
import '../services/help_request_service.dart';
import '../widgets/help_request_nearby_style.dart';
import 'help_request_detail_screen.dart';

/// Lists **only** the current user's help requests (by `creatorUid` / `isMine`).
/// Edit & delete are available here — other users never see this list.
class YourRequestsScreen extends StatelessWidget {
  const YourRequestsScreen({super.key});

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

        return ColoredBox(
          color: const Color(0xFFF6F7FB),
          child: ListView.builder(
            padding: EdgeInsets.fromLTRB(
              16,
              16,
              16,
              16 + MediaQuery.of(context).padding.bottom,
            ),
            itemCount: mine.length,
            itemBuilder: (context, index) {
              return YourRequestNearbyFeaturedCard(
                request: mine[index],
                onEdit: () => _openEdit(context, mine[index]),
                onDelete: () => _confirmDelete(context, mine[index]),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _openEdit(BuildContext context, HelpRequest r) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => HelpRequestDetailScreen(
          category: r.category,
          existingRequest: r,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, HelpRequest r) async {
    final go = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete request?'),
        content: const Text(
          'Remove this help request? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (go != true || !context.mounted) return;

    await HelpRequestService.instance.deleteRequest(r.id);
    HelpRequestsStore.instance.removeById(r.id);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request deleted')),
    );
  }
}

class _SignedOutPlaceholder extends StatelessWidget {
  const _SignedOutPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFF6F7FB),
      child: Center(
        child: Icon(
          Icons.lock_outline_rounded,
          size: 48,
          color: Color(0xFFB31217),
        ),
      ),
    );
  }
}

class _EmptyPlaceholder extends StatelessWidget {
  const _EmptyPlaceholder();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: Color(0xFFF6F7FB),
      child: Center(
        child: Icon(
          Icons.inbox_outlined,
          size: 56,
          color: Color(0xFFB31217),
        ),
      ),
    );
  }
}
