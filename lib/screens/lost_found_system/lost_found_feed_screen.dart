import 'dart:ui';
import 'package:flutter/material.dart';

import 'create_item_screen.dart';
import 'lost_found_items_section.dart';
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

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _pageBg => _isDark ? const Color(0xFF121217) : lfBg;
  Color get _cardBg => _isDark ? const Color(0xFF171822) : Colors.white;
  Color get _textPrimary => _isDark ? Colors.white : lfTextPrimary;
  Color get _textSecondary =>
      _isDark ? const Color(0xFFE1E4EC) : lfTextSecondary;
  Color get _textMuted => _isDark ? const Color(0xFFBEC4D2) : lfTextMuted;
  Color get _borderColor =>
      _isDark ? const Color(0xFF34384A) : const Color(0xFFE5E7EE);

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

  InputDecoration _dialogInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: _isDark ? const Color(0xFFC7CCD7) : _textMuted,
        fontWeight: FontWeight.w500,
      ),
      filled: true,
      fillColor: _isDark ? const Color(0xFF202332) : const Color(0xFFF7F7F8),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: _borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: BorderSide(color: _borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: lfRed, width: 1.4),
      ),
    );
  }

  Widget _outlinedGlowCancelButton(VoidCallback onTap) {
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isDark
              ? const Color(0xFFFF7A7A).withOpacity(0.45)
              : lfRed.withOpacity(0.28),
          width: 1.15,
        ),
        boxShadow: [
          BoxShadow(
            color: _isDark
                ? const Color(0xFFFF6A6A).withOpacity(0.16)
                : lfRed.withOpacity(0.10),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          foregroundColor: _textSecondary,
        ),
        child: Text(
          "Cancel",
          style: TextStyle(
            color: _isDark ? Colors.white : _textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Future<void> _openLocationFilterDialog() async {
    final TextEditingController c = TextEditingController(
      text: _locationFilter,
    );

    await showGeneralDialog(
      context: context,
      barrierLabel: 'Location Filter',
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.22),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(color: Colors.transparent),
              ),
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxWidth: 420),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.14),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: lfRed.withOpacity(0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 48,
                            height: 5,
                            decoration: BoxDecoration(
                              color: _isDark
                                  ? const Color(0xFF5A6072)
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF6B6B),
                                      Color(0xFFE53935),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: const Icon(
                                  Icons.place_outlined,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Filter by location",
                                  style: TextStyle(
                                    color: _textPrimary,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Enter a place to filter your posts quickly.",
                              style: TextStyle(
                                color: _isDark
                                    ? const Color(0xFFD6DBE6)
                                    : _textMuted,
                                fontSize: 12.8,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: c,
                            style: TextStyle(
                              color: _textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                            decoration: _dialogInputDecoration(
                              "e.g. Main Gate, Library, Canteen...",
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: _outlinedGlowCancelButton(
                                  () => Navigator.pop(context),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  height: 52,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFFFF5A5A),
                                        Color(0xFFE53935),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: lfRed.withOpacity(0.28),
                                        blurRadius: 16,
                                        offset: const Offset(0, 6),
                                      ),
                                    ],
                                  ),
                                  child: ElevatedButton(
                                    onPressed: () {
                                      setState(() {
                                        _locationFilter = c.text.trim();
                                      });
                                      Navigator.pop(context);
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      elevation: 0,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                    ),
                                    child: const Text(
                                      "Apply",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
              CurvedAnimation(parent: animation, curve: Curves.easeOut),
            ),
            child: child,
          ),
        );
      },
    );
  }

  Future<void> _openCategoryPicker() async {
    await showGeneralDialog(
      context: context,
      barrierLabel: "Category Picker",
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.20),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(color: Colors.transparent),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  top: false,
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.74,
                    ),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.16),
                          blurRadius: 24,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      child: Column(
                        children: [
                          Container(
                            width: 46,
                            height: 5,
                            decoration: BoxDecoration(
                              color: _isDark
                                  ? const Color(0xFF5A6072)
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF6B6B),
                                      Color(0xFFE53935),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.filter_alt_outlined,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Choose category",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: _textPrimary,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: _textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Select one category to filter the items.",
                              style: TextStyle(
                                color: _textMuted,
                                fontSize: 12.8,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Expanded(
                            child: ListView.builder(
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                final category = _categories[index];
                                final selected = _selectedCategory == category;

                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? (_isDark
                                              ? const Color(0xFF1F2130)
                                              : const Color(0xFFFFF7F7))
                                        : (_isDark
                                              ? const Color(0xFF1B1D2A)
                                              : Colors.white),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: selected ? lfRed : _borderColor,
                                      width: selected ? 1.4 : 1,
                                    ),
                                    boxShadow: selected
                                        ? [
                                            BoxShadow(
                                              color: lfRed.withOpacity(0.12),
                                              blurRadius: 14,
                                              offset: const Offset(0, 5),
                                            ),
                                          ]
                                        : [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                _isDark ? 0.10 : 0.04,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(18),
                                      onTap: () {
                                        setState(() {
                                          _selectedCategory = category;
                                        });
                                        Navigator.pop(context);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 14,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 42,
                                              height: 42,
                                              decoration: BoxDecoration(
                                                color: selected
                                                    ? lfRed.withOpacity(0.10)
                                                    : (_isDark
                                                          ? const Color(
                                                              0xFF252838,
                                                            )
                                                          : const Color(
                                                              0xFFF8F8F9,
                                                            )),
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              child: Icon(
                                                category == "All"
                                                    ? Icons.grid_view_rounded
                                                    : _iconForCategory(
                                                        category,
                                                      ),
                                                color: lfRed,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                category,
                                                style: TextStyle(
                                                  color: _textPrimary,
                                                  fontSize: 15.5,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            AnimatedOpacity(
                                              duration: const Duration(
                                                milliseconds: 180,
                                              ),
                                              opacity: selected ? 1 : 0,
                                              child: const Icon(
                                                Icons.check_rounded,
                                                color: lfRed,
                                                size: 22,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
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
                color: active
                    ? lfRed.withOpacity(_isDark ? 0.18 : 0.08)
                    : _cardBg,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: active
                      ? lfRed.withOpacity(0.45)
                      : (_isDark
                            ? const Color(0xFF34343F)
                            : Colors.grey.shade200),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(_isDark ? 0.12 : 0.04),
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
                color: active ? lfRed : _textPrimary,
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
          color: active
              ? activeBg
              : (_isDark
                    ? Colors.white.withOpacity(0.10)
                    : Colors.white.withOpacity(0.08)),
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
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark ? 0.10 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          icon: const Icon(Icons.search, color: lfRed),
          hintText: "Search by title, category, location...",
          hintStyle: TextStyle(
            color: _isDark ? const Color(0xFFB8BFCD) : lfHint,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
        ),
        onChanged: (val) => setState(() => _searchQuery = val.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentType = _tabController.index == 0 ? "Lost" : "Found";
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _pageBg,
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
      body: SafeArea(
        top: false,
        bottom: true,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: bottomInset + 24),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 108, 18, 20),
                decoration: BoxDecoration(
                  gradient: _isDark
                      ? const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFFF3B3B),
                            Color(0xFFE10613),
                            Color(0xFFB30012),
                            Color(0xFF140910),
                          ],
                          stops: [0.0, 0.35, 0.72, 1.0],
                        )
                      : const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFFF4B4B),
                            Color(0xFFB31217),
                            Color(0xFF1B1B1B),
                          ],
                          stops: [0.0, 0.62, 1.0],
                        ),
                  borderRadius: const BorderRadius.only(
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
                child: LostFoundItemsSection(
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

  bool get _isDark => Theme.of(context).brightness == Brightness.dark;
  Color get _pageBg => _isDark ? const Color(0xFF121217) : lfBg;
  Color get _cardBg => _isDark ? const Color(0xFF171822) : Colors.white;
  Color get _textPrimary => _isDark ? Colors.white : lfTextPrimary;
  Color get _textSecondary =>
      _isDark ? const Color(0xFFE1E4EC) : lfTextSecondary;
  Color get _textMuted => _isDark ? const Color(0xFFBEC4D2) : lfHint;
  Color get _borderColor =>
      _isDark ? const Color(0xFF34384A) : const Color(0xFFE5E7EE);

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

  Future<void> _openCategoryPicker() async {
    await showGeneralDialog(
      context: context,
      barrierLabel: "Category Picker",
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.20),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Material(
          color: Colors.transparent,
          child: Stack(
            children: [
              BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
                child: Container(color: Colors.transparent),
              ),
              Align(
                alignment: Alignment.bottomCenter,
                child: SafeArea(
                  top: false,
                  child: Container(
                    width: double.infinity,
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.74,
                    ),
                    decoration: BoxDecoration(
                      color: _cardBg,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(30),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.16),
                          blurRadius: 24,
                          offset: const Offset(0, -4),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                      child: Column(
                        children: [
                          Container(
                            width: 46,
                            height: 5,
                            decoration: BoxDecoration(
                              color: _isDark
                                  ? const Color(0xFF5A6072)
                                  : Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFFF6B6B),
                                      Color(0xFFE53935),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(
                                  Icons.filter_alt_outlined,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Choose category",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w800,
                                    color: _textPrimary,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: Icon(
                                  Icons.close_rounded,
                                  color: _textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "Select one category to filter your posts.",
                              style: TextStyle(
                                color: _textMuted,
                                fontSize: 12.8,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),
                          Expanded(
                            child: ListView.builder(
                              itemCount: widget.categories.length,
                              itemBuilder: (context, index) {
                                final category = widget.categories[index];
                                final selected = _selectedCategory == category;

                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 180),
                                  margin: const EdgeInsets.only(bottom: 10),
                                  decoration: BoxDecoration(
                                    color: selected
                                        ? (_isDark
                                              ? const Color(0xFF1F2130)
                                              : const Color(0xFFFFF7F7))
                                        : (_isDark
                                              ? const Color(0xFF1B1D2A)
                                              : Colors.white),
                                    borderRadius: BorderRadius.circular(18),
                                    border: Border.all(
                                      color: selected ? lfRed : _borderColor,
                                      width: selected ? 1.4 : 1,
                                    ),
                                    boxShadow: selected
                                        ? [
                                            BoxShadow(
                                              color: lfRed.withOpacity(0.12),
                                              blurRadius: 14,
                                              offset: const Offset(0, 5),
                                            ),
                                          ]
                                        : [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(
                                                _isDark ? 0.10 : 0.04,
                                              ),
                                              blurRadius: 8,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                  ),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(18),
                                      onTap: () {
                                        setState(() {
                                          _selectedCategory = category;
                                        });
                                        Navigator.pop(context);
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 14,
                                          vertical: 14,
                                        ),
                                        child: Row(
                                          children: [
                                            Container(
                                              width: 42,
                                              height: 42,
                                              decoration: BoxDecoration(
                                                color: selected
                                                    ? lfRed.withOpacity(0.10)
                                                    : (_isDark
                                                          ? const Color(
                                                              0xFF252838,
                                                            )
                                                          : const Color(
                                                              0xFFF8F8F9,
                                                            )),
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              child: Icon(
                                                category == "All"
                                                    ? Icons.grid_view_rounded
                                                    : _iconForCategory(
                                                        category,
                                                      ),
                                                color: lfRed,
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                category,
                                                style: TextStyle(
                                                  color: _textPrimary,
                                                  fontSize: 15.5,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ),
                                            AnimatedOpacity(
                                              duration: const Duration(
                                                milliseconds: 180,
                                              ),
                                              opacity: selected ? 1 : 0,
                                              child: const Icon(
                                                Icons.check_rounded,
                                                color: lfRed,
                                                size: 22,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(
            position:
                Tween<Offset>(
                  begin: const Offset(0, 0.08),
                  end: Offset.zero,
                ).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ),
                ),
            child: child,
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
        color: _cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(_isDark ? 0.10 : 0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        style: TextStyle(color: _textPrimary, fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          icon: const Icon(Icons.search, color: lfRed),
          hintText: "Search your posts...",
          hintStyle: TextStyle(
            color: _isDark ? const Color(0xFFB8BFCD) : lfHint,
            fontWeight: FontWeight.w500,
          ),
          border: InputBorder.none,
        ),
        onChanged: (val) => setState(() => _searchQuery = val.trim()),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: _pageBg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          widget.type == 'Lost' ? 'My Lost Posts' : 'My Found Posts',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        top: false,
        bottom: true,
        child: SingleChildScrollView(
          padding: EdgeInsets.only(bottom: bottomInset + 24),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 108, 18, 20),
                decoration: BoxDecoration(
                  gradient: _isDark
                      ? const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFFF3B3B),
                            Color(0xFFE10613),
                            Color(0xFFB30012),
                            Color(0xFF140910),
                          ],
                          stops: [0.0, 0.35, 0.72, 1.0],
                        )
                      : const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFFFF4B4B),
                            Color(0xFFB31217),
                            Color(0xFF1B1B1B),
                          ],
                          stops: [0.0, 0.62, 1.0],
                        ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(34),
                    bottomRight: Radius.circular(34),
                  ),
                ),
                child: _myPostsHeaderCard(),
              ),
              const SizedBox(height: 24),
              _searchBar(),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: LostFoundItemsSection(
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
      ),
    );
  }
}
