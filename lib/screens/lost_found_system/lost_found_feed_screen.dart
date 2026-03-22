import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'create_item_screen.dart';
import 'lost_item_model.dart';
import 'lost_found_service.dart';
import 'mock_chat_screen.dart';
import '../sos_system/main_menu_screen.dart';

class LostFoundFeedScreen extends StatefulWidget {
  const LostFoundFeedScreen({super.key});

  @override
  State<LostFoundFeedScreen> createState() => _LostFoundFeedScreenState();
}

class _LostFoundFeedScreenState extends State<LostFoundFeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String _searchQuery = "";
  String _selectedCategory = "All";
  String _locationFilter = "";

  static const Color spRed = Color(0xFFE53935);
  static const Color spDark = Color(0xFFB71C1C);

  final List<String> _categories = const [
    "All",
    "Electronics",
    "ID/Documents",
    "Student ID Card",
    "Watch",
    "Keys",
    "Books",
    "Others",
  ];

  @override
  void initState() {
    _tabController = TabController(length: 2, vsync: this);
    super.initState();
  }

  IconData _iconForCategory(String c) {
    switch (c) {
      case 'Electronics':
        return Icons.devices;
      case 'ID/Documents':
        return Icons.description;
      case 'Student ID Card':
        return Icons.badge;
      case 'Watch':
        return Icons.watch;
      case 'Keys':
        return Icons.key;
      case 'Books':
        return Icons.menu_book;
      default:
        return Icons.category;
    }
  }

  void _openLocationFilterDialog() {
    final c = TextEditingController(text: _locationFilter);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Filter by location"),
        content: TextField(
          controller: c,
          decoration: const InputDecoration(
            hintText: "e.g. Main Gate, Library, Canteen...",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: spRed),
            onPressed: () {
              setState(() => _locationFilter = c.text.trim());
              Navigator.pop(context);
            },
            child: const Text("Apply", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openMainMenu() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MainMenuScreen()),
    );
  }

  Widget _glassCard({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [spRed, spDark],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text(
            "Lost & Found",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              tooltip: "More",
              icon: const Icon(
                Icons.more_vert_rounded,
                color: Colors.white,
                size: 28,
              ),
              onPressed: _openMainMenu,
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            tabs: const [
              Tab(text: "LOST ITEMS"),
              Tab(text: "FOUND ITEMS"),
            ],
          ),
        ),
        body: Column(
          children: [
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: _glassCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: TextField(
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: "Search by title, category, location...",
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.75)),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.white.withOpacity(0.9),
                    ),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.08),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: _glassCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          dropdownColor: const Color(0xFF7A0F0F),
                          value: _selectedCategory,
                          isExpanded: true,
                          iconEnabledColor: Colors.white,
                          style: const TextStyle(color: Colors.white),
                          items: _categories.map((c) {
                            return DropdownMenuItem(
                              value: c,
                              child: Row(
                                children: [
                                  Icon(
                                    c == "All"
                                        ? Icons.filter_alt
                                        : _iconForCategory(c),
                                    color: Colors.white.withOpacity(0.95),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      c,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              setState(() => _selectedCategory = val);
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.85)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                    ),
                    onPressed: _openLocationFilterDialog,
                    icon: const Icon(Icons.place),
                    label: Text(
                      _locationFilter.isEmpty ? "Location" : "Location ✓",
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _ItemsList(
                    type: "Lost",
                    query: _searchQuery,
                    category: _selectedCategory,
                    locationFilter: _locationFilter,
                  ),
                  _ItemsList(
                    type: "Found",
                    query: _searchQuery,
                    category: _selectedCategory,
                    locationFilter: _locationFilter,
                  ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          backgroundColor: Colors.white,
          onPressed: () {
            String type = _tabController.index == 0 ? "Lost" : "Found";
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreateItemScreen(postType: type),
              ),
            );
          },
          label: const Text(
            "Post Item",
            style: TextStyle(color: spDark, fontWeight: FontWeight.bold),
          ),
          icon: const Icon(Icons.add, color: spDark),
        ),
      ),
    );
  }
}

class _ItemsList extends StatelessWidget {
  final String type;
  final String query;
  final String category;
  final String locationFilter;

  const _ItemsList({
    required this.type,
    required this.query,
    required this.category,
    required this.locationFilter,
  });

  bool _matchFilters(LostItem i) {
    final q = query.toLowerCase();
    final loc = locationFilter.toLowerCase();

    final matchCategory = category == "All" || i.category == category;

    final matchSearch =
        q.isEmpty ||
        i.title.toLowerCase().contains(q) ||
        i.category.toLowerCase().contains(q) ||
        i.location.toLowerCase().contains(q);

    final matchLoc = loc.isEmpty || i.location.toLowerCase().contains(loc);

    return matchCategory && matchSearch && matchLoc;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<LostItem>>(
      stream: LostFoundService().getItemsStream(type),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text(
              "Loading error. Please reopen Lost & Found.",
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }

        final all = snapshot.data!;
        if (all.isEmpty) {
          return const Center(
            child: Text(
              "No items reported.",
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final items = all.where(_matchFilters).toList();

        if (items.isEmpty) {
          return const Center(
            child: Text(
              "No results for your filters.",
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final currentUid = FirebaseAuth.instance.currentUser?.uid;

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            final isMyPost = currentUid != null && currentUid == item.userId;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.10),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: Colors.white.withOpacity(0.14)),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(12),
                leading: Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: item.imageUrl.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(14),
                          child: Image.network(
                            item.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => Icon(
                              Icons.image_not_supported,
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        )
                      : Icon(
                          Icons.image,
                          color: Colors.white.withOpacity(0.85),
                        ),
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isMyPost) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.16),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.18),
                          ),
                        ),
                        child: const Text(
                          "You posted",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    "${item.category} • ${item.location}",
                    style: TextStyle(color: Colors.white.withOpacity(0.78)),
                  ),
                ),
                trailing: _buildBadge(item.status),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => _DetailScreen(item: item)),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildBadge(String status) {
    Color bg = Colors.white.withOpacity(0.14);
    Color text = Colors.white;

    if (status == 'Verification Pending' || status == 'Claim Pending') {
      bg = Colors.orange.withOpacity(0.20);
      text = Colors.orangeAccent;
    } else if (status == 'Answer Submitted' || status == 'Chat Enabled') {
      bg = Colors.blue.withOpacity(0.20);
      text = Colors.lightBlueAccent;
    } else if (status == 'Returned') {
      bg = Colors.green.withOpacity(0.18);
      text = Colors.greenAccent;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: text,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _DetailScreen extends StatefulWidget {
  final LostItem item;
  const _DetailScreen({required this.item});

  @override
  State<_DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<_DetailScreen> {
  bool get isOwner =>
      FirebaseAuth.instance.currentUser?.uid != null &&
      FirebaseAuth.instance.currentUser!.uid == widget.item.userId;

  bool get isRequester =>
      FirebaseAuth.instance.currentUser?.uid != null &&
      FirebaseAuth.instance.currentUser!.uid == widget.item.requesterId;

  String get currentUid => FirebaseAuth.instance.currentUser?.uid ?? 'unknown';
  String get currentName =>
      FirebaseAuth.instance.currentUser?.email?.split('@')[0] ?? 'Student';

  static const Color spRed = Color(0xFFE53935);
  static const Color spDark = Color(0xFFB71C1C);

  Widget _glass({required Widget child, EdgeInsets? padding}) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: child,
    );
  }

  Future<void> _showFoundQuestionDialog() async {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Ask verification question"),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: "e.g. Any special marks on the item?",
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: spRed),
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              await LostFoundService().submitFoundReport(
                itemId: widget.item.id,
                requesterId: currentUid,
                requesterName: currentName,
                question: controller.text.trim(),
              );
              if (!mounted) return;
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Found report sent.")),
              );
            },
            child: const Text("Submit", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showOwnerAnswerDialog() async {
    final controller = TextEditingController();
    final question = await LostFoundService().getVerificationQuestion(
      widget.item.id,
    );

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Answer verification question"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(question),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "Type your answer",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: spRed),
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              await LostFoundService().submitOwnerAnswer(
                itemId: widget.item.id,
                answer: controller.text.trim(),
              );
              if (!mounted) return;
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Answer sent to finder.")),
              );
            },
            child: const Text("Submit", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showClaimDialog() async {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Verification Required"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Describe any special marks or unique details."),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "Type proof here",
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: spRed),
            onPressed: () async {
              if (controller.text.trim().isEmpty) return;
              await LostFoundService().submitClaimRequest(
                itemId: widget.item.id,
                requesterId: currentUid,
                requesterName: currentName,
                proofAnswer: controller.text.trim(),
              );
              if (!mounted) return;
              Navigator.pop(ctx);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Claim request sent.")),
              );
            },
            child: const Text("Submit", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MockChatScreen(
          itemId: widget.item.id,
          otherUserName: widget.item.requesterName ?? widget.item.userName,
          itemName: widget.item.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [spRed, spDark],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text("Details"),
          backgroundColor: Colors.transparent,
          elevation: 0,
          foregroundColor: Colors.white,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _glass(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 210,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.14),
                        ),
                      ),
                      child: item.imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.network(
                                item.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => Center(
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 46,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.image,
                                    size: 46,
                                    color: Colors.white.withOpacity(0.9),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    "No Image",
                                    style: TextStyle(
                                      color: Colors.white.withOpacity(0.85),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (isOwner)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.16),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.18),
                              ),
                            ),
                            child: const Text(
                              "You posted",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          Icons.location_pin,
                          color: Colors.white.withOpacity(0.9),
                          size: 18,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.location,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.category,
                      style: TextStyle(color: Colors.white.withOpacity(0.75)),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Description",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white.withOpacity(0.92),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.description.isEmpty
                          ? "No description provided."
                          : item.description,
                      style: TextStyle(color: Colors.white.withOpacity(0.85)),
                    ),
                    if (item.requesterName != null) ...[
                      const SizedBox(height: 14),
                      Text(
                        "Requested by: ${item.requesterName}",
                        style: TextStyle(color: Colors.white.withOpacity(0.8)),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),

              if (item.status == 'Returned') ...[
                _buildSuccessMessage("Item Returned Successfully"),
              ] else if (item.chatEnabled && (isOwner || isRequester)) ...[
                _chatEnabledActions(),
              ] else if (item.type == 'Lost' &&
                  !isOwner &&
                  item.status == 'Active') ...[
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _showFoundQuestionDialog,
                    child: const Text(
                      "I FOUND THIS",
                      style: TextStyle(
                        color: spDark,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ] else if (item.type == 'Lost' &&
                  isOwner &&
                  item.status == 'Verification Pending') ...[
                _ownerLostVerificationCard(),
              ] else if (item.type == 'Lost' &&
                  isRequester &&
                  item.status == 'Answer Submitted') ...[
                _finderApprovalCard(),
              ] else if (item.type == 'Found' &&
                  !isOwner &&
                  item.status == 'Active') ...[
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _showClaimDialog,
                    child: const Text(
                      "THIS IS MINE",
                      style: TextStyle(
                        color: spDark,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ] else if (item.type == 'Found' &&
                  isOwner &&
                  item.status == 'Claim Pending') ...[
                _foundOwnerApprovalCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _ownerLostVerificationCard() {
    return _glass(
      child: FutureBuilder<String>(
        future: LostFoundService().getVerificationQuestion(widget.item.id),
        builder: (context, snap) {
          final question = snap.data ?? "Loading question...";
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Finder verification request",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orangeAccent.withOpacity(0.95),
                ),
              ),
              const SizedBox(height: 8),
              Text(question, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: _showOwnerAnswerDialog,
                  child: const Text(
                    "ANSWER QUESTION",
                    style: TextStyle(
                      color: spDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _finderApprovalCard() {
    return _glass(
      child: FutureBuilder<String>(
        future: LostFoundService().getVerificationAnswer(widget.item.id),
        builder: (context, snap) {
          final answer = snap.data ?? "Loading answer...";
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Owner's verification answer",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.lightBlueAccent.withOpacity(0.95),
                ),
              ),
              const SizedBox(height: 8),
              Text(answer, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withOpacity(0.85)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        await LostFoundService().rejectRequest(widget.item.id);
                        if (!mounted) return;
                        Navigator.pop(context);
                      },
                      child: const Text("Reject"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        await LostFoundService().enablePrivateChat(
                          widget.item.id,
                        );
                        if (!mounted) return;
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "ALLOW CHAT",
                        style: TextStyle(
                          color: spDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _foundOwnerApprovalCard() {
    return _glass(
      child: FutureBuilder<String>(
        future: LostFoundService().getVerificationAnswer(widget.item.id),
        builder: (context, snap) {
          final proof = snap.data ?? "Loading proof...";
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Claim verification",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.orangeAccent.withOpacity(0.95),
                ),
              ),
              const SizedBox(height: 8),
              Text(proof, style: const TextStyle(color: Colors.white)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: BorderSide(color: Colors.white.withOpacity(0.85)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        await LostFoundService().rejectRequest(widget.item.id);
                        if (!mounted) return;
                        Navigator.pop(context);
                      },
                      child: const Text("Reject"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        await LostFoundService().enablePrivateChat(
                          widget.item.id,
                        );
                        if (!mounted) return;
                        Navigator.pop(context);
                      },
                      child: const Text(
                        "ALLOW CHAT",
                        style: TextStyle(
                          color: spDark,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _chatEnabledActions() {
    return _glass(
      child: Column(
        children: [
          Text(
            "Verification completed. Private chat is enabled.",
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Colors.white.withOpacity(0.85)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text("Open Chat"),
                  onPressed: _openChat,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.greenAccent.withOpacity(0.25),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text(
                    "Returned",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  onPressed: () async {
                    await LostFoundService().markAsReturned(widget.item.id);
                    if (!mounted) return;
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.14)),
      ),
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: Colors.greenAccent, size: 58),
          const SizedBox(height: 8),
          Text(
            msg,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "This item will be removed automatically after 1 hour.",
            style: TextStyle(color: Colors.white.withOpacity(0.78)),
          ),
        ],
      ),
    );
  }
}
//lost