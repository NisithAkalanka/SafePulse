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

const Color lfTextPrimary = Color(0xFF1E1E1E);
const Color lfTextSecondary = Color(0xFF4B4B4B);
const Color lfTextMuted = Color(0xFF707070);
const Color lfHint = Color(0xFFB58E8E);

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
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        title: const Text(
          "Filter by location",
          style: TextStyle(color: lfTextPrimary, fontWeight: FontWeight.w700),
        ),
        content: TextField(
          controller: c,
          style: const TextStyle(
            color: lfTextPrimary,
            fontWeight: FontWeight.w500,
          ),
          decoration: const InputDecoration(
            hintText: "e.g. Main Gate, Library, Canteen...",
            hintStyle: TextStyle(color: lfTextMuted),
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(
                color: lfTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
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
                          color: lfTextPrimary,
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
                              style: const TextStyle(
                                color: lfTextPrimary,
                                fontWeight: FontWeight.w600,
                              ),
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

  void _openMainMenu() {
    Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierDismissible: true,
        barrierColor: Colors.transparent,
        pageBuilder: (context, animation, secondaryAnimation) =>
            const MainMenuScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.12, 0),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      ),
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
                fontWeight: FontWeight.w700,
                color: active ? lfRed : lfTextPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _headerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.14),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Lost & Found",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Report, track, and recover lost and found items inside the campus system.",
                  style: TextStyle(
                    color: Color(0xFFF7EAEA),
                    fontSize: 12.5,
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

  Widget _topMiniChip({
    required IconData icon,
    required String label,
    required bool active,
    required VoidCallback onTap,
  }) {
    final Color activeBg = const Color(0xFFFFF2F2);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: active ? activeBg : Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: active ? activeBg : Colors.white.withOpacity(0.16),
            width: active ? 1.4 : 1,
          ),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.10),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 16, color: active ? lfRed : Colors.white),
            const SizedBox(width: 7),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: active ? lfRed : Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topInfoStrip() {
    final isLost = _tabController.index == 0;
    return Row(
      children: [
        Expanded(
          child: _topMiniChip(
            icon: Icons.search_off_outlined,
            label: "Lost Items",
            active: isLost,
            onTap: () => _tabController.animateTo(0),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _topMiniChip(
            icon: Icons.check_circle_outline,
            label: "Found Items",
            active: !isLost,
            onTap: () => _tabController.animateTo(1),
          ),
        ),
      ],
    );
  }

  Widget _headerSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        style: const TextStyle(
          color: lfTextPrimary,
          fontWeight: FontWeight.w500,
        ),
        decoration: const InputDecoration(
          icon: Icon(Icons.search, color: lfRed),
          hintText: "Search by title, category, location...",
          hintStyle: TextStyle(color: lfHint, fontWeight: FontWeight.w500),
          border: InputBorder.none,
        ),
        onChanged: (val) => setState(() => _searchQuery = val.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentType = _tabController.index == 0 ? "Lost" : "Found";

    return Scaffold(
      backgroundColor: lfBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "Lost & Found",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: "Main Menu",
            onPressed: _openMainMenu,
            icon: const Icon(Icons.more_vert),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 108, 18, 20),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFF4B4B),
                    Color(0xFFB31217),
                    Color(0xFF1B1B1B),
                  ],
                  stops: [0.0, 0.62, 1.0],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(34),
                  bottomRight: Radius.circular(34),
                ),
              ),
              child: Column(
                children: [
                  _headerCard(),
                  const SizedBox(height: 12),
                  _topInfoStrip(),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _headerSearchBar(),
            const SizedBox(height: 10),
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
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _ItemsSection(
                type: currentType,
                query: _searchQuery,
                category: _selectedCategory,
                locationFilter: _locationFilter,
                showOnlyMyPosts: false,
              ),
            ),
          ],
        ),
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
    super.key,
    required this.type,
    required this.selectedCategory,
    required this.locationFilter,
    required this.categories,
  });

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
                          color: lfTextPrimary,
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
                              style: const TextStyle(
                                color: lfTextPrimary,
                                fontWeight: FontWeight.w600,
                              ),
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

  Widget _myPostsHeaderCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.14),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: const Icon(
              Icons.bookmark_border,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "My Posts",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Manage and review your lost and found posts.",
                  style: TextStyle(
                    color: Color(0xFFF7EAEA),
                    fontSize: 12.5,
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

  Widget _searchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        style: const TextStyle(
          color: lfTextPrimary,
          fontWeight: FontWeight.w500,
        ),
        decoration: const InputDecoration(
          icon: Icon(Icons.search, color: lfRed),
          hintText: "Search by title, category, location...",
          hintStyle: TextStyle(color: lfHint, fontWeight: FontWeight.w500),
          border: InputBorder.none,
        ),
        onChanged: (val) => setState(() => _searchQuery = val.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: lfBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          "My Posts",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(18, 100, 18, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFFF4B4B),
                    Color(0xFFB31217),
                    Color(0xFF1B1B1B),
                  ],
                  stops: [0.0, 0.62, 1.0],
                ),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(34),
                  bottomRight: Radius.circular(34),
                ),
              ),
              child: _myPostsHeaderCard(),
            ),
            const SizedBox(height: 18),
            _searchBar(),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
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
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                "Loading error. Please reopen Lost & Found.",
                style: TextStyle(
                  color: lfTextPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(30),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final filtered = snapshot.data!
            .where((i) => _matchFilters(i, currentUid))
            .toList();

        final todayPosts = filtered
            .where((i) => _isToday(i.timestamp))
            .toList();

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
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
                const SizedBox(height: 12),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      showOnlyMyPosts ? "My Posts" : "All Posts",
                      style: const TextStyle(
                        fontSize: 21,
                        fontWeight: FontWeight.bold,
                        color: lfTextPrimary,
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.grid_view_rounded,
                            color: lfRed,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 82),
                            child: Text(
                              category,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                color: lfTextPrimary,
                              ),
                            ),
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
              const SizedBox(height: 12),
              const Text(
                "Today",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: lfTextPrimary,
                ),
              ),
              const SizedBox(height: 10),
              if (todayPosts.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  alignment: Alignment.center,
                  child: const Text(
                    "No posts added today.",
                    style: TextStyle(
                      color: lfTextMuted,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              else
                SizedBox(
                  height: 210,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: todayPosts.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      return SizedBox(
                        width: 162,
                        child: _ItemCard(
                          item: todayPosts[index],
                          compact: true,
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 14),
              const Text(
                "All Posts",
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: lfTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              if (filtered.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  alignment: Alignment.center,
                  child: Text(
                    category == "All"
                        ? "No items found."
                        : "No items found in $category.",
                    style: const TextStyle(
                      color: lfTextMuted,
                      fontWeight: FontWeight.w600,
                    ),
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
                    childAspectRatio: 0.84,
                  ),
                  itemBuilder: (context, index) {
                    return _ItemCard(item: filtered[index]);
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ItemCard extends StatefulWidget {
  final LostItem item;
  final bool compact;

  const _ItemCard({required this.item, this.compact = false});

  @override
  State<_ItemCard> createState() => _ItemCardState();
}

class _ItemCardState extends State<_ItemCard> {
  bool _pressed = false;

  bool get _isOwner {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return uid != null && uid == widget.item.userId;
  }

  ({Color bg, Color text}) _statusColors(String status) {
    switch (status) {
      case 'Active':
        return (bg: const Color(0xFFB71C1C), text: Colors.white);
      case 'Chat Enabled':
      case 'Answer Submitted':
        return (bg: const Color(0xFFEAF2FF), text: const Color(0xFF1565C0));
      case 'Claim Pending':
      case 'Verification Pending':
        return (bg: const Color(0xFFFFF4DB), text: const Color(0xFFB26A00));
      case 'Returned':
        return (bg: const Color(0xFFE8F6EA), text: const Color(0xFF2E7D32));
      default:
        return (bg: Colors.white.withOpacity(0.92), text: Colors.black87);
    }
  }

  String _remainingDeleteTime() {
    final returnedAt = widget.item.returnedAt;
    if (returnedAt == null) return "Deletes in 1h 0m";

    final expiry = returnedAt.add(const Duration(hours: 1));
    final remaining = expiry.difference(DateTime.now());

    if (remaining.isNegative) return "Deleting soon";

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);

    if (hours > 0) {
      return "Deletes in ${hours}h ${minutes}m";
    }
    return "Deletes in ${minutes}m";
  }

  Widget _buildStatusOverlay() {
    final colors = _statusColors(widget.item.status);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: colors.bg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            widget.item.status,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: colors.text,
              fontSize: 9.0,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        if (widget.item.status == 'Returned') ...[
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.68),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _remainingDeleteTime(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 8.4,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _openDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => _DetailScreen(item: widget.item)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final double imageHeight = widget.compact ? 84 : 94;

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      onTap: _openDetails,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFE53935), Color(0xFF842121), Color(0xFF2B1616)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.10),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Container(
          margin: EdgeInsets.all(_pressed ? 2.0 : 3.0),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFB52B2B), Color(0xFF521E1E)],
            ),
            borderRadius: BorderRadius.circular(21),
          ),
          child: Container(
            margin: EdgeInsets.all(_pressed ? 1.6 : 2.2),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(19),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    Container(
                      height: imageHeight,
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF2F2F2),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(19),
                        ),
                      ),
                      child: item.imageUrl.isNotEmpty
                          ? ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(19),
                              ),
                              child: Image.network(
                                item.imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => const Center(
                                  child: Icon(
                                    Icons.image_not_supported_outlined,
                                    color: lfRed,
                                    size: 30,
                                  ),
                                ),
                              ),
                            )
                          : const Center(
                              child: Icon(
                                Icons.inventory_2_outlined,
                                size: 34,
                                color: lfRed,
                              ),
                            ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 92),
                        child: _buildStatusOverlay(),
                      ),
                    ),
                    if (_isOwner)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          width: 26,
                          height: 26,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.95),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.bookmark_border,
                            color: lfRed,
                            size: 17,
                          ),
                        ),
                      ),
                  ],
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(11, 9, 11, 9),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: widget.compact ? 13.2 : 14,
                            height: 1.18,
                            color: lfTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.only(top: 1),
                              child: Icon(
                                Icons.place_outlined,
                                size: 14,
                                color: lfTextMuted,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                item.location.isEmpty
                                    ? "Location not added"
                                    : item.location,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: lfTextSecondary,
                                  fontSize: 11.5,
                                  height: 1.18,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
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

  bool get isActiveStatus => widget.item.status == 'Active';

  static const List<String> _editCategories = [
    'Electronics',
    'ID/Documents',
    'Student ID Card',
    'Watch',
    'Keys',
    'Books',
    'Others',
  ];

  Widget _panel({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: lfRed.withOpacity(0.18), width: 1.4),
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

  String? _requiredField(String? value, String label) {
    if ((value ?? '').trim().isEmpty) {
      return '$label is required';
    }
    return null;
  }

  Future<void> _showEditDialog() async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController(text: widget.item.title);
    final locationController = TextEditingController(
      text: widget.item.location,
    );
    final descriptionController = TextEditingController(
      text: widget.item.description,
    );
    String selectedCategory = widget.item.category.isNotEmpty
        ? widget.item.category
        : _editCategories.first;

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setLocalState) => AlertDialog(
          title: const Text(
            'Edit item',
            style: TextStyle(color: lfTextPrimary, fontWeight: FontWeight.w700),
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: titleController,
                    validator: (v) => _requiredField(v, 'Title'),
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: _editCategories.contains(selectedCategory)
                        ? selectedCategory
                        : _editCategories.first,
                    items: _editCategories
                        .map(
                          (c) => DropdownMenuItem<String>(
                            value: c,
                            child: Text(c),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setLocalState(() => selectedCategory = value);
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: locationController,
                    validator: (v) => _requiredField(v, 'Location'),
                    decoration: const InputDecoration(
                      labelText: 'Location',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: descriptionController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: lfTextSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: lfRed),
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                await LostFoundService().updatePostBasic(
                  itemId: widget.item.id,
                  title: titleController.text.trim(),
                  category: selectedCategory,
                  description: descriptionController.text.trim(),
                  location: locationController.text.trim(),
                );
                if (!mounted) return;
                Navigator.pop(context);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Item updated successfully.')),
                );
              },
              child: const Text('Save', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          'Delete item',
          style: TextStyle(color: lfTextPrimary, fontWeight: FontWeight.w700),
        ),
        content: const Text(
          'Are u sure you want to delete?',
          style: TextStyle(color: lfTextSecondary, fontWeight: FontWeight.w500),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: lfTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: lfRed),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldDelete != true) return;

    await LostFoundService().deletePost(widget.item.id);
    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Item deleted successfully.')));
  }

  Future<void> _showFoundQuestionDialog() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text(
          "Ask verification question",
          style: TextStyle(color: lfTextPrimary, fontWeight: FontWeight.w700),
        ),
        content: Form(
          key: formKey,
          child: TextFormField(
            controller: controller,
            style: const TextStyle(
              color: lfTextPrimary,
              fontWeight: FontWeight.w500,
            ),
            validator: _validateQuestion,
            decoration: const InputDecoration(
              hintText: "e.g. Any special marks on the item?",
              hintStyle: TextStyle(color: lfTextMuted),
              border: OutlineInputBorder(),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(
                color: lfTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
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
        title: const Text(
          "Answer verification question",
          style: TextStyle(color: lfTextPrimary, fontWeight: FontWeight.w700),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                question,
                style: const TextStyle(
                  color: lfTextPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: controller,
                style: const TextStyle(
                  color: lfTextPrimary,
                  fontWeight: FontWeight.w500,
                ),
                validator: _validateAnswer,
                decoration: const InputDecoration(
                  hintText: "Type your answer",
                  hintStyle: TextStyle(color: lfTextMuted),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(
                color: lfTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
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
        title: const Text(
          "Verification Required",
          style: TextStyle(color: lfTextPrimary, fontWeight: FontWeight.w700),
        ),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Describe any special marks or unique details.",
                style: TextStyle(
                  color: lfTextPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: controller,
                style: const TextStyle(
                  color: lfTextPrimary,
                  fontWeight: FontWeight.w500,
                ),
                validator: _validateProof,
                decoration: const InputDecoration(
                  hintText: "Type proof here",
                  hintStyle: TextStyle(color: lfTextMuted),
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              "Cancel",
              style: TextStyle(
                color: lfTextSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
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

  String _detailDeleteTime() {
    final returnedAt = widget.item.returnedAt;
    if (returnedAt == null) return "Deletes in 1h 0m";

    final expiry = returnedAt.add(const Duration(hours: 1));
    final remaining = expiry.difference(DateTime.now());

    if (remaining.isNegative) return "Deleting soon";

    final hours = remaining.inHours;
    final minutes = remaining.inMinutes.remainder(60);

    if (hours > 0) {
      return "Deletes in ${hours}h ${minutes}m";
    }
    return "Deletes in ${minutes}m";
  }

  Widget _buildHeader() {
    final bool isLost = widget.item.type == 'Lost';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 100, 18, 18),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFFF4B4B), Color(0xFFB31217), Color(0xFF1B1B1B)],
          stops: [0.0, 0.62, 1.0],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
      ),
      child: Text(
        isLost
            ? 'Review the lost item details carefully.'
            : 'Review the found item details carefully.',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w500,
          height: 1.35,
        ),
      ),
    );
  }

  Widget _statusBadge() {
    Color bg;
    Color fg;

    switch (widget.item.status) {
      case 'Returned':
        bg = const Color(0xFFE8F6EA);
        fg = const Color(0xFF2E7D32);
        break;
      case 'Claim Pending':
      case 'Verification Pending':
        bg = const Color(0xFFFFF4DB);
        fg = const Color(0xFFB26A00);
        break;
      case 'Chat Enabled':
      case 'Answer Submitted':
        bg = const Color(0xFFEAF2FF);
        fg = const Color(0xFF1565C0);
        break;
      default:
        bg = lfRed.withOpacity(0.08);
        fg = lfRed;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        widget.item.status,
        style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: 12),
      ),
    );
  }

  Widget _ownerActionButtons() {
    if (!isOwner || !isActiveStatus) return const SizedBox.shrink();

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _showEditDialog,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Edit'),
            style: OutlinedButton.styleFrom(
              foregroundColor: lfRed,
              side: BorderSide(color: lfRed.withOpacity(0.55)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _confirmDelete,
            icon: const Icon(Icons.delete_outline, color: Colors.white),
            label: const Text('Delete', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: lfRed,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
        ),
      ],
    );
  }

  Widget _detailsTopCard() {
    final item = widget.item;

    return _panel(
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
                          color: lfRed,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: lfTextPrimary,
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
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.place_outlined, size: 18, color: lfTextMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  item.location,
                  style: const TextStyle(
                    color: lfTextSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.category,
            style: const TextStyle(
              color: lfTextSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                "Status:",
                style: TextStyle(
                  color: lfTextPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 8),
              _statusBadge(),
            ],
          ),
          if (item.status == 'Returned' && item.returnedAt != null) ...[
            const SizedBox(height: 8),
            Text(
              _detailDeleteTime(),
              style: TextStyle(
                color: Colors.green.shade700,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            "Description",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
              color: lfTextPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            item.description.isEmpty
                ? "No description provided."
                : item.description,
            style: const TextStyle(
              color: lfTextSecondary,
              fontWeight: FontWeight.w500,
              height: 1.4,
            ),
          ),
          if (item.requesterName != null) ...[
            const SizedBox(height: 12),
            Text(
              "Requested by: ${item.requesterName}",
              style: const TextStyle(
                color: lfTextSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          if (isOwner && isActiveStatus) ...[
            const SizedBox(height: 16),
            _ownerActionButtons(),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return Scaffold(
      backgroundColor: lfBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
        title: const Text(
          "Details",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.2,
          ),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
              child: Column(
                children: [
                  _detailsTopCard(),
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
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: lfTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                question,
                style: const TextStyle(
                  color: lfTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: lfTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                answer,
                style: const TextStyle(
                  color: lfTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
                      child: const Text(
                        "Reject",
                        style: TextStyle(
                          color: lfTextPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: lfTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                proof,
                style: const TextStyle(
                  color: lfTextSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
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
                      child: const Text(
                        "Reject",
                        style: TextStyle(
                          color: lfTextPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
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
            style: TextStyle(fontWeight: FontWeight.w600, color: lfTextPrimary),
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
                    foregroundColor: lfTextPrimary,
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
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 17,
              color: lfTextPrimary,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "This item will be removed automatically after 1 hour.",
            style: TextStyle(
              color: lfTextSecondary,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
