import 'package:flutter/material.dart';
import '../../services/community_requests_admin_service.dart';

class CommunityRequestsAdminScreen extends StatefulWidget {
  const CommunityRequestsAdminScreen({super.key});

  @override
  State<CommunityRequestsAdminScreen> createState() =>
      _CommunityRequestsAdminScreenState();
}

class _CommunityRequestsAdminScreenState
    extends State<CommunityRequestsAdminScreen> {
  final CommunityRequestsAdminService _service =
      CommunityRequestsAdminService.instance;

  @override
  void initState() {
    super.initState();
    _service.ensureDefaultCategories();
  }

  Future<void> _openAddCategoryDialog() async {
    final ctrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Request Type'),
          content: TextField(
            controller: ctrl,
            decoration: const InputDecoration(
              labelText: 'Type name',
              hintText: 'Moving Help, Tech Support, Delivery',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );

    if (ok != true) return;
    await _service.addCategory(ctrl.text);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Category added.')),
    );
  }

  Future<void> _openEditCategoryDialog(CommunityRequestCategory item) async {
    final ctrl = TextEditingController(text: item.name);
    bool isActive = item.isActive;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Request Type'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: ctrl,
                    decoration: const InputDecoration(labelText: 'Type name'),
                  ),
                  const SizedBox(height: 10),
                  SwitchListTile(
                    value: isActive,
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Active'),
                    onChanged: (v) => setDialogState(() => isActive = v),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok != true) return;
    await _service.updateCategory(id: item.id, name: ctrl.text, isActive: isActive);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Category updated.')),
    );
  }

  Future<void> _flagRequest(String id) async {
    final reasonCtrl = TextEditingController();
    final reasonFocus = FocusNode();

    final reason = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF151720),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (reasonFocus.canRequestFocus) {
            reasonFocus.requestFocus();
          }
        });

        return Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Flag Request',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: reasonCtrl,
                focusNode: reasonFocus,
                autofocus: true,
                minLines: 3,
                maxLines: 5,
                style: const TextStyle(color: Colors.white),
                cursorColor: Colors.white,
                decoration: InputDecoration(
                  labelText: 'Reason',
                  labelStyle: const TextStyle(color: Colors.white70),
                  hintText: 'Spam, illegal content, abuse, etc.',
                  hintStyle: const TextStyle(color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.06),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(sheetContext),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final text = reasonCtrl.text.trim();
                        if (text.isEmpty) {
                          ScaffoldMessenger.of(sheetContext).showSnackBar(
                            const SnackBar(content: Text('Please enter a reason.')),
                          );
                          return;
                        }
                        Navigator.pop(sheetContext, text);
                      },
                      child: const Text('Flag'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );

    reasonCtrl.dispose();
    reasonFocus.dispose();

    if (reason == null || reason.trim().isEmpty) return;
    await _service.flagRequest(requestId: id, reason: reason);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Request flagged for moderation.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color pageBg = isDark
        ? const Color(0xFF121217)
        : const Color(0xFFF6F7FB);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: pageBg,
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
          title: const Text(
            'COMMUNITY REQUESTS',
            style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 0.4),
          ),
          centerTitle: true,
        ),
        body: Stack(
          children: [
            Container(
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
                      ? const [0.0, 0.30, 0.68, 1.0]
                      : const [0.0, 0.58, 1.0],
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
                  color: Colors.white.withValues(alpha: isDark ? 0.06 : 0.08),
                ),
              ),
            ),
            Positioned(
              top: 140,
              left: -70,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: isDark ? 0.14 : 0.06),
                ),
              ),
            ),
            Column(
              children: [
                const SizedBox(height: 110),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: _buildHeroCard(),
                ),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: _buildHeaderTabs(),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: pageBg,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(34),
                        topRight: Radius.circular(34),
                      ),
                    ),
                    child: TabBarView(
                      children: [
                        _buildCategoriesTab(),
                        _buildModerationTab(),
                        _buildAnalyticsTab(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.16),
              border: Border.all(color: Colors.white.withValues(alpha: 0.20)),
            ),
            child: const Icon(
              Icons.handshake_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Community Requests Admin',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Control request types and moderate live posts quickly.',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12.3,
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

  Widget _buildHeaderTabs() {
    return Container(
      height: 48,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withValues(alpha: 0.18),
            Colors.black.withValues(alpha: 0.16),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: TabBar(
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        indicator: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        labelColor: const Color(0xFFB31217),
        unselectedLabelColor: Colors.white,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w900,
          fontSize: 13,
          letterSpacing: 0.2,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w800,
          fontSize: 13,
          letterSpacing: 0.2,
        ),
        tabs: const [
          Tab(text: 'Types'),
          Tab(text: 'Moderation'),
          Tab(text: 'Analytics'),
        ],
      ),
    );
  }

  Widget _buildCategoriesTab() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Text(
                  'Add, rename, activate or remove request types without changing code.',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15.5),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: _openAddCategoryDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add Type'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<CommunityRequestCategory>>(
            stream: _service.watchAllCategories(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final categories = snapshot.data ?? const [];
              if (categories.isEmpty) {
                return const Center(
                  child: Text('No types found. Add your first category.'),
                );
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 20),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final c = categories[index];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B1B22),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (c.isActive ? Colors.green : Colors.orange)
                                .withValues(alpha: 0.18),
                          ),
                          child: Icon(
                            c.isActive
                                ? Icons.check_circle
                                : Icons.pause_circle,
                            color: c.isActive ? Colors.green : Colors.orange,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                c.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                c.isActive ? 'Active' : 'Inactive',
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Edit',
                          onPressed: () => _openEditCategoryDialog(c),
                          icon: const Icon(Icons.edit, color: Colors.white),
                        ),
                        IconButton(
                          tooltip: 'Delete',
                          onPressed: () => _service.deleteCategory(c.id),
                          icon: const Icon(
                            Icons.delete_outline,
                            color: Colors.redAccent,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildModerationTab() {
    return StreamBuilder<List<ModerationRequestItem>>(
      stream: _service.watchRequestsForModeration(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final items = snapshot.data ?? const [];
        if (items.isEmpty) {
          return const Center(child: Text('No requests to moderate.'));
        }
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 18, 12, 20),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final r = items[index];
            final isFlagged = r.moderationStatus == 'flagged';
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1B1B22),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          r.title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${r.category} • by ${r.requesterName}',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    r.description,
                    style: const TextStyle(
                      color: Colors.white,
                    ),
                  ),
                  if ((r.flagReason ?? '').isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Reason: ${r.flagReason}',
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: isFlagged
                            ? OutlinedButton.icon(
                                onPressed: () => _service.unflagRequest(r.id),
                                icon: const Icon(Icons.check_circle_outline),
                                label: const Text('Unflag'),
                              )
                            : OutlinedButton.icon(
                                onPressed: () => _flagRequest(r.id),
                                icon: const Icon(Icons.flag_outlined),
                                label: const Text('Flag'),
                              ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: () => _service.deleteRequest(r.id),
                          icon: const Icon(Icons.delete_forever),
                          label: const Text('Delete'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildAnalyticsTab() {
    return StreamBuilder<List<ModerationRequestItem>>(
      stream: _service.watchRequestsForModeration(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final items = snapshot.data ?? const [];
        final total = items.length;
        final active =
            items.where((r) => r.moderationStatus.toLowerCase() != 'flagged').length;
        final flagged = total - active;

        final Map<String, int> byCategory = <String, int>{};
        for (final r in items) {
          final key = r.category.trim().isEmpty ? 'Uncategorized' : r.category.trim();
          byCategory[key] = (byCategory[key] ?? 0) + 1;
        }

        final sortedCategories = byCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 22),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'System Performance Summary',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _analyticsStatCard(
                      value: '$total',
                      label: 'TOTAL REQUESTS',
                      valueColor: const Color(0xFF4D8DFF),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _analyticsStatCard(
                      value: '$flagged',
                      label: 'FLAGGED',
                      valueColor: const Color(0xFFFF6464),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _analyticsStatCard(
                      value: '$active',
                      label: 'ACTIVE',
                      valueColor: const Color(0xFF25C27A),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF1B1B22),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Request Breakdown by Category',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (sortedCategories.isEmpty)
                      const Text(
                        'No request data available yet.',
                        style: TextStyle(color: Colors.white70),
                      ),
                    for (final entry in sortedCategories)
                      _categoryBarRow(
                        label: entry.key,
                        count: entry.value,
                        total: total,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _analyticsStatCard({
    required String value,
    required String label,
    required Color valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B22),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
              fontSize: 11.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryBarRow({
    required String label,
    required int count,
    required int total,
  }) {
    final ratio = total <= 0 ? 0.0 : count / total;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$count cases',
                style: const TextStyle(
                  color: Color(0xFFFF6464),
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 10,
              backgroundColor: const Color(0xFF20242F),
              color: const Color(0xFF2D66DD),
            ),
          ),
        ],
      ),
    );
  }
}
