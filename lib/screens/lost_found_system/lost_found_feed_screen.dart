import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'create_item_screen.dart';
import 'lost_item_model.dart';
import 'lost_found_service.dart';
import 'mock_chat_screen.dart';
import '../sos_system/main_menu_screen.dart';

const Color lfRed = Color(0xFFE53935);
const Color lfDark = Color(0xFFB71C1C);
const Color lfBg = Color(0xFFF6F6F7);

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
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  IconData _iconForCategory(String c) {
    switch (c) {
      case 'Electronics':
        return Icons.devices_outlined;
      case 'ID/Documents':
        return Icons.description_outlined;
      case 'Student ID Card':
        return Icons.badge_outlined;
      case 'Watch':
        return Icons.watch_outlined;
      case 'Keys':
        return Icons.key_outlined;
      case 'Books':
        return Icons.menu_book_outlined;
      default:
        return Icons.category_outlined;
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
            style: ElevatedButton.styleFrom(backgroundColor: lfRed),
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

  void _openCategoryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.68,
            minChildSize: 0.40,
            maxChildSize: 0.90,
            builder: (context, scrollController) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Choose category",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: _categories.length,
                        itemBuilder: (context, index) {
                          final category = _categories[index];
                          return ListTile(
                            leading: Icon(
                              category == "All"
                                  ? Icons.grid_view_rounded
                                  : _iconForCategory(category),
                              color: lfRed,
                            ),
                            title: Text(
                              category,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: _selectedCategory == category
                                ? const Icon(Icons.check, color: lfRed)
                                : null,
                            onTap: () {
                              setState(() => _selectedCategory = category);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const MainMenuScreen()),
    );
  }

  void _openNotifications() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Notifications feature coming soon.")),
    );
  }

  void _openPostForCurrentTab() {
    final type = _tabController.index == 0 ? "Lost" : "Found";
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateItemScreen(postType: type)),
    );
  }

  void _openMyPostsPage() {
    final type = _tabController.index == 0 ? "Lost" : "Found";
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MyPostsScreen(
          type: type,
          selectedCategory: _selectedCategory,
          locationFilter: _locationFilter,
          categories: _categories,
        ),
      ),
    );
  }

  Widget _quickAction({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool active = false,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Column(
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(
                color: active ? lfRed.withOpacity(0.08) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: active
                      ? lfRed.withOpacity(0.35)
                      : Colors.grey.shade200,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(icon, color: lfRed, size: 28),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: active ? lfRed : Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lfBg,
      appBar: AppBar(
        backgroundColor: lfRed,
        elevation: 0,
        automaticallyImplyLeading: false,
        foregroundColor: Colors.white,
        title: const Text(
          "Lost & Found",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: "Notifications",
            icon: const Icon(Icons.notifications_none_outlined),
            onPressed: _openNotifications,
          ),
          IconButton(
            tooltip: "Profile",
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: _openProfile,
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [lfRed, lfDark],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: TextField(
                    decoration: const InputDecoration(
                      icon: Icon(Icons.search, color: lfRed),
                      hintText: "Search by title, category, location...",
                      border: InputBorder.none,
                    ),
                    onChanged: (val) =>
                        setState(() => _searchQuery = val.trim()),
                  ),
                ),
                const SizedBox(height: 14),
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white70,
                  tabs: const [
                    Tab(text: "LOST ITEMS"),
                    Tab(text: "FOUND ITEMS"),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _quickAction(
                  icon: Icons.add_circle_outline,
                  title: "Add Post",
                  onTap: _openPostForCurrentTab,
                ),
                const SizedBox(width: 10),
                _quickAction(
                  icon: Icons.bookmark_border,
                  title: "My Posts",
                  onTap: _openMyPostsPage,
                ),
                const SizedBox(width: 10),
                _quickAction(
                  icon: Icons.filter_alt_outlined,
                  title: "Category",
                  active: _selectedCategory != "All",
                  onTap: _openCategoryPicker,
                ),
                const SizedBox(width: 10),
                _quickAction(
                  icon: Icons.place_outlined,
                  title: "Location",
                  active: _locationFilter.isNotEmpty,
                  onTap: _openLocationFilterDialog,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _ItemsSection(
                  type: "Lost",
                  query: _searchQuery,
                  category: _selectedCategory,
                  locationFilter: _locationFilter,
                  showOnlyMyPosts: false,
                ),
                _ItemsSection(
                  type: "Found",
                  query: _searchQuery,
                  category: _selectedCategory,
                  locationFilter: _locationFilter,
                  showOnlyMyPosts: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MyPostsScreen extends StatefulWidget {
  final String type;
  final String selectedCategory;
  final String locationFilter;
  final List<String> categories;

  const MyPostsScreen({
    Key? key,
    required this.type,
    required this.selectedCategory,
    required this.locationFilter,
    required this.categories,
  }) : super(key: key);

  @override
  State<MyPostsScreen> createState() => _MyPostsScreenState();
}

class _MyPostsScreenState extends State<MyPostsScreen> {
  late String _searchQuery;
  late String _selectedCategory;
  late String _locationFilter;

  @override
  void initState() {
    super.initState();
    _searchQuery = "";
    _selectedCategory = widget.selectedCategory;
    _locationFilter = widget.locationFilter;
  }

  IconData _iconForCategory(String c) {
    switch (c) {
      case 'Electronics':
        return Icons.devices_outlined;
      case 'ID/Documents':
        return Icons.description_outlined;
      case 'Student ID Card':
        return Icons.badge_outlined;
      case 'Watch':
        return Icons.watch_outlined;
      case 'Keys':
        return Icons.key_outlined;
      case 'Books':
        return Icons.menu_book_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  void _openCategoryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (_) {
        return SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.68,
            minChildSize: 0.40,
            maxChildSize: 0.90,
            builder: (context, scrollController) {
              return Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "Choose category",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: widget.categories.length,
                        itemBuilder: (context, index) {
                          final category = widget.categories[index];
                          return ListTile(
                            leading: Icon(
                              category == "All"
                                  ? Icons.grid_view_rounded
                                  : _iconForCategory(category),
                              color: lfRed,
                            ),
                            title: Text(
                              category,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: _selectedCategory == category
                                ? const Icon(Icons.check, color: lfRed)
                                : null,
                            onTap: () {
                              setState(() => _selectedCategory = category);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lfBg,
      appBar: AppBar(
        backgroundColor: lfRed,
        foregroundColor: Colors.white,
        title: const Text("My Posts"),
      ),
      body: Column(
        children: [
          Container(
            color: lfRed,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: TextField(
                decoration: const InputDecoration(
                  icon: Icon(Icons.search, color: lfRed),
                  hintText: "Search by title, category, location...",
                  border: InputBorder.none,
                ),
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
              ),
            ),
          ),
          Expanded(
            child: _ItemsSection(
              type: widget.type,
              query: _searchQuery,
              category: _selectedCategory,
              locationFilter: _locationFilter,
              showOnlyMyPosts: true,
              categoryChipOnTap: _openCategoryPicker,
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemsSection extends StatelessWidget {
  final String type;
  final String query;
  final String category;
  final String locationFilter;
  final bool showOnlyMyPosts;
  final VoidCallback? categoryChipOnTap;

  const _ItemsSection({
    required this.type,
    required this.query,
    required this.category,
    required this.locationFilter,
    required this.showOnlyMyPosts,
    this.categoryChipOnTap,
  });

  bool _matchFilters(LostItem i, String? currentUid) {
    final q = query.toLowerCase();
    final loc = locationFilter.toLowerCase();

    final matchCategory = category == "All" || i.category == category;
    final matchSearch =
        q.isEmpty ||
        i.title.toLowerCase().contains(q) ||
        i.category.toLowerCase().contains(q) ||
        i.location.toLowerCase().contains(q);
    final matchLoc = loc.isEmpty || i.location.toLowerCase().contains(loc);
    final matchMine =
        !showOnlyMyPosts || (currentUid != null && i.userId == currentUid);

    return matchCategory && matchSearch && matchLoc && matchMine;
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return now.year == date.year &&
        now.month == date.month &&
        now.day == date.day;
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<List<LostItem>>(
      stream: LostFoundService().getItemsStream(type),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(
            child: Text("Loading error. Please reopen Lost & Found."),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final filtered = snapshot.data!
            .where((i) => _matchFilters(i, currentUid))
            .toList();

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showOnlyMyPosts) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: lfRed.withOpacity(0.18)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.bookmark_border, color: lfRed),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Showing only your posts",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: lfRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      showOnlyMyPosts ? "My Posts" : "Recent Posts",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: categoryChipOnTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.grid_view_rounded,
                            color: lfRed,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            category,
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          if (categoryChipOnTap != null) ...[
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: lfRed,
                              size: 18,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                "Today",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              Builder(
                builder: (_) {
                  final todayItems = filtered
                      .where((i) => _isToday(i.timestamp))
                      .toList();

                  if (todayItems.isEmpty) {
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      alignment: Alignment.center,
                      child: Text(
                        category == "All"
                            ? "No items posted today."
                            : "No items posted today in $category.",
                      ),
                    );
                  }

                  return SizedBox(
                    height: 250,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: todayItems.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 12),
                      itemBuilder: (context, index) {
                        final item = todayItems[index];
                        return SizedBox(
                          width: 170,
                          child: _ItemCard(item: item),
                        );
                      },
                    ),
                  );
                },
              ),
              const SizedBox(height: 18),
              Text(
                category == "All" ? "All Posts" : "$category Posts",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              if (filtered.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  alignment: Alignment.center,
                  child: Text(
                    category == "All"
                        ? "No items found."
                        : "No items found in $category.",
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filtered.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 14,
                    mainAxisSpacing: 14,
                    childAspectRatio: 0.78,
                  ),
                  itemBuilder: (context, index) {
                    final item = filtered[index];
                    return _ItemCard(item: item);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ItemCard extends StatelessWidget {
  final LostItem item;

  const _ItemCard({required this.item});

  Widget _buildBadge(String status) {
    Color bg = Colors.grey.shade100;
    Color text = Colors.black87;

    if (status == 'Verification Pending' || status == 'Claim Pending') {
      bg = Colors.orange.shade50;
      text = Colors.orange.shade800;
    } else if (status == 'Answer Submitted' || status == 'Chat Enabled') {
      bg = Colors.blue.shade50;
      text = Colors.blue.shade800;
    } else if (status == 'Returned') {
      bg = Colors.green.shade50;
      text = Colors.green.shade800;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        status,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: text, fontSize: 9, fontWeight: FontWeight.bold),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => _DetailScreen(item: item)),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.grey.shade300, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 120,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Color(0xFFF2F2F2),
                borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: item.imageUrl.isNotEmpty
                  ? ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      child: Image.network(
                        item.imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (ctx, err, stack) =>
                            const Icon(Icons.image_not_supported_outlined),
                      ),
                    )
                  : const Icon(
                      Icons.inventory_2_outlined,
                      size: 40,
                      color: lfRed,
                    ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.category,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(
                          Icons.place_outlined,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            item.location,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    _buildBadge(item.status),
                  ],
                ),
              ),
            ),
          ],
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

  Widget _panel({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  String? _validateQuestion(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Question is required';
    if (v.length < 5) return 'Question must be at least 5 characters';
    if (v.length > 120) return 'Question must be 120 characters or less';
    final reg = RegExp(r"^[a-zA-Z0-9\s&(),.\-'/?!]+$");
    if (!reg.hasMatch(v)) return 'Question contains invalid characters';
    return null;
  }

  String? _validateAnswer(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Answer is required';
    if (v.length < 2) return 'Answer must be at least 2 characters';
    if (v.length > 150) return 'Answer must be 150 characters or less';
    return null;
  }

  String? _validateProof(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Proof is required';
    if (v.length < 3) return 'Proof must be at least 3 characters';
    if (v.length > 150) return 'Proof must be 150 characters or less';
    return null;
  }

  Future<void> _showFoundQuestionDialog() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Ask verification question"),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            validator: _validateQuestion,
            decoration: const InputDecoration(
              hintText: "e.g. Any special marks on the item?",
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: lfRed),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await LostFoundService().submitFoundReport(
                itemId: widget.item.id,
                requesterId: currentUid,
                requesterName: currentName,
                question: controller.text.trim(),
              );
              if (!mounted) return;
              Navigator.pop(context);
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
    final formKey = GlobalKey<FormState>();
    final question = await LostFoundService().getVerificationQuestion(
      widget.item.id,
    );

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Answer verification question"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(question),
              const SizedBox(height: 10),
              TextFormField(
                controller: controller,
                validator: _validateAnswer,
                decoration: const InputDecoration(
                  hintText: "Type your answer",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: lfRed),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await LostFoundService().submitOwnerAnswer(
                itemId: widget.item.id,
                answer: controller.text.trim(),
              );
              if (!mounted) return;
              Navigator.pop(context);
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
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Verification Required"),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Describe any special marks or unique details."),
              const SizedBox(height: 10),
              TextFormField(
                controller: controller,
                validator: _validateProof,
                decoration: const InputDecoration(
                  hintText: "Type proof here",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: lfRed),
            onPressed: () async {
              if (!formKey.currentState!.validate()) return;
              await LostFoundService().submitClaimRequest(
                itemId: widget.item.id,
                requesterId: currentUid,
                requesterName: currentName,
                proofAnswer: controller.text.trim(),
              );
              if (!mounted) return;
              Navigator.pop(context);
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

    return Scaffold(
      backgroundColor: lfBg,
      appBar: AppBar(
        backgroundColor: lfRed,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text("Details"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 230,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F3F3),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: item.imageUrl.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(22),
                            child: Image.network(
                              item.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (c, e, s) => const Center(
                                child: Icon(
                                  Icons.image_not_supported_outlined,
                                  size: 40,
                                ),
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(
                              Icons.inventory_2_outlined,
                              size: 42,
                              color: lfRed,
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
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
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
                            color: lfRed.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            "You posted",
                            style: TextStyle(
                              color: lfRed,
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
                      const Icon(
                        Icons.place_outlined,
                        size: 18,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.location,
                          style: TextStyle(color: Colors.grey.shade700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.category,
                    style: TextStyle(color: Colors.grey.shade700),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Description",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.description.isEmpty
                        ? "No description provided."
                        : item.description,
                    style: TextStyle(color: Colors.grey.shade800),
                  ),
                  if (item.requesterName != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      "Requested by: ${item.requesterName}",
                      style: TextStyle(color: Colors.grey.shade700),
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
              _primaryButton("I FOUND THIS", _showFoundQuestionDialog),
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
              _primaryButton("THIS IS MINE", _showClaimDialog),
            ] else if (item.type == 'Found' &&
                isOwner &&
                item.status == 'Claim Pending') ...[
              _foundOwnerApprovalCard(),
            ],
          ],
        ),
      ),
    );
  }

  Widget _primaryButton(String text, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: lfRed,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 0,
        ),
        onPressed: onTap,
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _ownerLostVerificationCard() {
    return _panel(
      child: FutureBuilder<String>(
        future: LostFoundService().getVerificationQuestion(widget.item.id),
        builder: (context, snap) {
          final question = snap.data ?? "Loading question...";
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Finder verification request",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Text(question),
              const SizedBox(height: 14),
              _primaryButton("ANSWER QUESTION", _showOwnerAnswerDialog),
            ],
          );
        },
      ),
    );
  }

  Widget _finderApprovalCard() {
    return _panel(
      child: FutureBuilder<String>(
        future: LostFoundService().getVerificationAnswer(widget.item.id),
        builder: (context, snap) {
          final answer = snap.data ?? "Loading answer...";
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Owner's verification answer",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Text(answer),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await LostFoundService().rejectRequest(widget.item.id);
                        if (!mounted) return;
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(color: Colors.grey.shade400),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("Reject"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await LostFoundService().enablePrivateChat(
                          widget.item.id,
                        );
                        if (!mounted) return;
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: lfRed,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        "ALLOW CHAT",
                        style: TextStyle(color: Colors.white),
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
    return _panel(
      child: FutureBuilder<String>(
        future: LostFoundService().getVerificationAnswer(widget.item.id),
        builder: (context, snap) {
          final proof = snap.data ?? "Loading proof...";
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Claim verification",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 8),
              Text(proof),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await LostFoundService().rejectRequest(widget.item.id);
                        if (!mounted) return;
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(color: Colors.grey.shade400),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text("Reject"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        await LostFoundService().enablePrivateChat(
                          widget.item.id,
                        );
                        if (!mounted) return;
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: lfRed,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: const Text(
                        "ALLOW CHAT",
                        style: TextStyle(color: Colors.white),
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
    return _panel(
      child: Column(
        children: [
          const Text(
            "Verification completed. Private chat is enabled.",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _openChat,
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text("Open Chat"),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    side: BorderSide(color: Colors.grey.shade400),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await LostFoundService().markAsReturned(widget.item.id);
                    if (!mounted) return;
                    Navigator.pop(context);
                  },
                  icon: const Icon(Icons.check, color: Colors.white),
                  label: const Text(
                    "Returned",
                    style: TextStyle(color: Colors.white),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessMessage(String msg) {
    return _panel(
      child: Column(
        children: [
          const Icon(Icons.check_circle, color: Colors.green, size: 56),
          const SizedBox(height: 8),
          Text(
            msg,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
          ),
          const SizedBox(height: 4),
          Text(
            "This item will be removed automatically after 1 hour.",
            style: TextStyle(color: Colors.grey.shade700),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
//lost