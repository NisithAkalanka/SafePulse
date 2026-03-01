import 'package:flutter/material.dart';

import 'create_item_screen.dart';
import 'lost_item_model.dart';
import 'lost_found_service.dart';
import 'mock_chat_screen.dart';

// ✅ ADD: Profile screen import (adjust path if your folder is different)
import '../profile_screen.dart';

class LostFoundFeedScreen extends StatefulWidget {
  const LostFoundFeedScreen({Key? key}) : super(key: key);

  @override
  State<LostFoundFeedScreen> createState() => _LostFoundFeedScreenState();
}

class _LostFoundFeedScreenState extends State<LostFoundFeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  String _searchQuery = "";
  String _selectedCategory = "All";
  String _locationFilter = "";

  static const Color spRed = Color(0xFFD32F2F);

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

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFE53935), Color(0xFFB71C1C)],
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

          // ✅ NEW: Profile Icon (Top Right)
          actions: [
            IconButton(
              tooltip: "Profile",
              icon: const Icon(
                Icons.account_circle,
                color: Colors.white,
                size: 28,
              ),
              onPressed: _openProfile,
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
            // Search
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Search by title, category, location...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.95),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              ),
            ),

            // Filters
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          items: _categories.map((c) {
                            return DropdownMenuItem(
                              value: c,
                              child: Row(
                                children: [
                                  Icon(
                                    c == "All"
                                        ? Icons.filter_alt
                                        : _iconForCategory(c),
                                    color: spRed,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(c),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null)
                              setState(() => _selectedCategory = val);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white),
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

            const SizedBox(height: 8),

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
          backgroundColor: spRed,
          onPressed: () {
            String type = _tabController.index == 0 ? "Lost" : "Found";
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => CreateItemScreen(postType: type),
              ),
            );
          },
          label: const Text("Post Item", style: TextStyle(color: Colors.white)),
          icon: const Icon(Icons.add, color: Colors.white),
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
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: Colors.white),
          );
        }
        if (snapshot.data!.isEmpty) {
          return const Center(
            child: Text(
              "No items reported.",
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        final items = snapshot.data!.where(_matchFilters).toList();

        if (items.isEmpty) {
          return const Center(
            child: Text(
              "No results for your filters.",
              style: TextStyle(color: Colors.white),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.all(10),
                leading: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: item.imageUrl.isNotEmpty
                      ? Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => const Icon(
                            Icons.image_not_supported,
                            color: Colors.grey,
                          ),
                        )
                      : const Icon(Icons.image, color: Colors.grey),
                ),
                title: Text(
                  item.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text("${item.category} • ${item.location}"),
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
    Color bg = Colors.blue[100]!;
    Color text = Colors.blue[800]!;
    if (status == 'Claim Pending') {
      bg = Colors.orange[100]!;
      text = Colors.orange[800]!;
    }
    if (status == 'Returned') {
      bg = Colors.green[100]!;
      text = Colors.green[800]!;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
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
  // Fake User ID Check (keep as-is for mock testing)
  bool get isOwner => widget.item.userId == 'my_id';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Details"),
        backgroundColor: const Color(0xFFD32F2F),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: widget.item.imageUrl.isNotEmpty
                  ? Image.network(
                      widget.item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) =>
                          const Icon(Icons.image_not_supported, size: 50),
                    )
                  : const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.category, size: 50, color: Colors.grey),
                        Text("No Image"),
                      ],
                    ),
            ),
            const SizedBox(height: 15),
            Text(
              widget.item.title,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                const Icon(Icons.location_pin, color: Colors.grey),
                Text(" ${widget.item.location}"),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.item.category,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            const Text(
              "Description",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Text(widget.item.description),
            const SizedBox(height: 30),

            if (widget.item.status == 'Returned') ...[
              _buildSuccessMessage("Item Returned Successfully"),
            ] else if (isOwner && widget.item.status == 'Claim Pending') ...[
              _ownerActions(),
            ] else if (!isOwner && widget.item.status == 'Active') ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFD32F2F),
                    padding: const EdgeInsets.all(15),
                  ),
                  child: const Text(
                    "THIS IS MINE (CLAIM)",
                    style: TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  onPressed: () => _showVerificationDialog(context),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _ownerActions() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        border: Border.all(color: Colors.orange),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Action Required!",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
          ),
          const SizedBox(height: 5),
          const Text(
            "A student wants to claim this. Their verification proof:",
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 4),
          Text(
            "\"${LostFoundService().getVerificationAnswer(widget.item.id)}\"",
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text("Private Chat"),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MockChatScreen(
                          otherUserName: "Student Finder",
                          itemName: widget.item.title,
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                  ),
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text(
                    "Return It",
                    style: TextStyle(color: Colors.white),
                  ),
                  onPressed: () {
                    LostFoundService().markAsReturned(widget.item.id);
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

  void _showVerificationDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Verification Required"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "To prevent theft, the owner requests specific details.",
            ),
            const SizedBox(height: 10),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "E.g. What is the phone wallpaper?",
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
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
            ),
            child: const Text(
              "Submit Proof",
              style: TextStyle(color: Colors.white),
            ),
            onPressed: () {
              if (controller.text.isNotEmpty) {
                LostFoundService().submitClaimRequest(
                  widget.item.id,
                  controller.text,
                );
                Navigator.pop(ctx);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      "Proof Sent! You can chat if the owner responds.",
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage(String msg) {
    return Center(
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 60),
          Text(
            msg,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: Colors.green,
            ),
          ),
        ],
      ),
    );
  }
}
