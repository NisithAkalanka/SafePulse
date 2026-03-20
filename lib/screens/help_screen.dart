import 'package:flutter/material.dart';
import 'help_feed_screen.dart';
import 'help_request_detail_screen.dart';

class HelpScreen extends StatefulWidget {
  final String? initialCategory;

  const HelpScreen({super.key, this.initialCategory});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> with TickerProviderStateMixin {
  late TabController _tabController;
  int _selectedCategoryIndex = 0;

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
    _HelpCategory(
      asset: 'assets/images/other.png',
      title: 'Other',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    if (widget.initialCategory != null) {
      final idx = _categories.indexWhere(
        (c) => c.title.toLowerCase() == widget.initialCategory!.toLowerCase(),
      );
      if (idx != -1) {
        _selectedCategoryIndex = idx;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => HelpRequestDetailScreen(
                category: _categories[idx].title,
                initialNote: '',
              ),
            ),
          );
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _openRequestDetail(int index) {
    setState(() => _selectedCategoryIndex = index);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => HelpRequestDetailScreen(
          category: _categories[index].title,
          initialNote: '',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Help',
          style: TextStyle(
            color: Color(0xFF1A1D2E),
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(0xFFE53935),
          unselectedLabelColor: const Color(0xFF6B7280),
          indicatorColor: const Color(0xFFE53935),
          indicatorWeight: 3,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            letterSpacing: 0.3,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          tabs: const [
            Tab(text: 'REQUEST'),
            Tab(text: 'FEED'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _RequestTabContent(
            categories: _categories,
            selectedIndex: _selectedCategoryIndex,
            onCategorySelected: _openRequestDetail,
          ),
          const HelpFeedScreen(),
        ],
      ),
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
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF8B1A1A),
            Color(0xFF671111),
          ],
        ),
      ),
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select your help type',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Pick a category below to open the request form.',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final category = categories[index];
                  final isSelected = index == selectedIndex;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _CategoryCard(
                      asset: category.asset,
                      title: category.title,
                      subtitle: category.subtitle,
                      isSelected: isSelected,
                      onTap: () => onCategorySelected(index),
                    ),
                  );
                },
                childCount: categories.length,
              ),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: MediaQuery.of(context).padding.bottom + 24)),
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
            color: isSelected ? const Color(0xFFD32F2F) : const Color(0xFFEEF0F3),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
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
                errorBuilder: (_, __, ___) => Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.handshake_rounded, color: Color(0xFF424242), size: 26),
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
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
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
