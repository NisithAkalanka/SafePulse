import 'package:flutter/material.dart';
import '../services/help_role_mode_service.dart';
import 'help_feed_screen.dart';
import 'help_request_detail_screen.dart';
import 'your_requests_screen.dart';

class HelpScreen extends StatefulWidget {
  final String? initialCategory;

  const HelpScreen({super.key, this.initialCategory});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen>
    with SingleTickerProviderStateMixin {
  int _selectedCategoryIndex = 0;
  bool _openedInitialCategory = false;
  late TabController _requesterTabController;

  static const List<_HelpCategory> _categories = [
    _HelpCategory(
      asset: 'assets/images/resource_sharing.png',
      title: 'Resource Sharing',
    ),
    _HelpCategory(
      asset: 'assets/images/study_support.png',
      title: 'Study Support',
    ),
    _HelpCategory(
      asset: 'assets/images/safety_transport.png',
      title: 'Safety Transport',
    ),
    _HelpCategory(
      asset: 'assets/images/tech_support.png',
      title: 'Tech Support',
    ),
    _HelpCategory(
      asset: 'assets/images/canteen_runner.png',
      title: 'Canteen Runner',
    ),
    _HelpCategory(
      asset: 'assets/images/campus_logistics.png',
      title: 'Campus Logistics & Moving',
      subtitle: '👥 Rs 4,500',
    ),
    _HelpCategory(
      asset: 'assets/images/cash_exchange.png',
      title: 'Cash Exchange',
      subtitle: '👥 Rs 4,500',
    ),
    _HelpCategory(asset: 'assets/images/other.png', title: 'Other'),
  ];

  @override
  void initState() {
    super.initState();
    _requesterTabController = TabController(length: 2, vsync: this);
    HelpRoleModeService.instance.load().then((_) {
      if (!mounted) return;
      _maybeOpenInitialCategory();
    });
  }

  @override
  void dispose() {
    _requesterTabController.dispose();
    super.dispose();
  }

  /// Deep link / initial category — only in **Requester** mode.
  void _maybeOpenInitialCategory() {
    if (_openedInitialCategory || widget.initialCategory == null) return;
    if (HelpRoleModeService.instance.isHelperMode.value) return;

    final idx = _categories.indexWhere(
      (c) => c.title.toLowerCase() == widget.initialCategory!.toLowerCase(),
    );
    if (idx == -1) return;

    _openedInitialCategory = true;
    _selectedCategoryIndex = idx;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final result = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => HelpRequestDetailScreen(
            category: _categories[idx].title,
            initialNote: '',
          ),
        ),
      );
      if (!mounted) return;
      if (result == true) {
        _requesterTabController.animateTo(1);
      }
    });
  }

  Future<void> _openRequestDetail(int index) async {
    setState(() => _selectedCategoryIndex = index);
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => HelpRequestDetailScreen(
          category: _categories[index].title,
          initialNote: '',
        ),
      ),
    );
    if (!mounted) return;
    if (result == true) {
      _requesterTabController.animateTo(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: HelpRoleModeService.instance.isHelperMode,
      builder: (context, isHelper, _) {
        // Full-screen layout matches Guardian Map (gradient header + white panel).
        if (isHelper) {
          return const HelpFeedScreen();
        }

        return Scaffold(
          backgroundColor: const Color(0xFFF6F7FB),
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.white,
            title: const Text(
              'Request help',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            centerTitle: true,
            bottom: TabBar(
              controller: _requesterTabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.2,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              tabs: const [
                Tab(text: 'New request'),
                Tab(text: 'Your requests'),
              ],
            ),
          ),
          body: Column(
            children: [
              Container(
                width: double.infinity,
                height: 168,
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
                clipBehavior: Clip.antiAlias,
                child: Stack(
                  children: [
                    Positioned(
                      top: -40,
                      right: -28,
                      child: Container(
                        width: 130,
                        height: 130,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withValues(alpha: 0.08),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -16,
                      left: -20,
                      child: Container(
                        width: 96,
                        height: 96,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.06),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Transform.translate(
                  offset: const Offset(0, -18),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 18),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x12000000),
                            blurRadius: 18,
                            offset: Offset(0, 8),
                          ),
                        ],
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: TabBarView(
                        controller: _requesterTabController,
                        children: [
                          _RequestTabContent(
                            categories: _categories,
                            selectedIndex: _selectedCategoryIndex,
                            onCategorySelected: _openRequestDetail,
                          ),
                          const YourRequestsScreen(),
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
    );
  }
}

class _RequestTabContent extends StatelessWidget {
  const _RequestTabContent({
    required this.categories,
    required this.selectedIndex,
    required this.onCategorySelected,
  });

  final List<_HelpCategory> categories;
  final int selectedIndex;
  final ValueChanged<int> onCategorySelected;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFF6F7FB),
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 8),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate((context, index) {
                final category = categories[index];
                final isSelected = index == selectedIndex;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _CategoryCard(
                    asset: category.asset,
                    title: category.title,
                    subtitle: category.subtitle,
                    isSelected: isSelected,
                    onTap: () => onCategorySelected(index),
                  ),
                );
              }, childCount: categories.length),
            ),
          ),
          SliverToBoxAdapter(
            child: SizedBox(height: MediaQuery.of(context).padding.bottom + 16),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.asset,
    required this.title,
    this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  final String asset;
  final String title;
  final String? subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFB31217)
                : const Color(0xFFE8EAEF),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                asset,
                width: 52,
                height: 52,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.handshake_rounded,
                    color: Color(0xFF424242),
                    size: 26,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isSelected
                          ? FontWeight.w800
                          : FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF424242),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HelpCategory {
  final String asset;
  final String title;
  final String? subtitle;

  const _HelpCategory({
    required this.asset,
    required this.title,
    this.subtitle,
  });
}
