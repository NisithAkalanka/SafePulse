import 'package:flutter/material.dart';
import '../services/help_role_mode_service.dart';
import '../widgets/main_bottom_navigation_bar.dart';
import 'help_feed_screen.dart';
import 'help_request_detail_screen.dart';
import '../theme/guardian_ui.dart';
import 'sos_system/main_menu_screen.dart';
import 'your_requests_page.dart';
import 'your_requests_screen.dart';

/// Category grid for the **Request help** category list.
const List<_HelpCategory> _kHelpCategories = [
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

  void _focusMyRequestsTab() {
    if (!mounted) return;
    if (_requesterTabController.index == 1) return;
    // Instant switch so “Your requests” is already selected when the form pops.
    _requesterTabController.animateTo(
      1,
      duration: Duration.zero,
      curve: Curves.linear,
    );
  }

  /// Success dialog only — switch tab before the form pops (push happens in [.then]).
  void _onViewYourRequestsAfterSubmit() {
    if (!mounted) return;
    _focusMyRequestsTab();
  }

  void _openYourRequestsPageAfterSubmit() {
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => const YourRequestsPage(),
      ),
    );
  }

  /// Deep link / initial category — only in **Requester** mode.
  void _maybeOpenInitialCategory() {
    if (_openedInitialCategory || widget.initialCategory == null) return;
    if (HelpRoleModeService.instance.isHelperMode.value) return;

    final idx = _kHelpCategories.indexWhere(
      (c) => c.title.toLowerCase() == widget.initialCategory!.toLowerCase(),
    );
    if (idx == -1) return;

    _openedInitialCategory = true;
    _selectedCategoryIndex = idx;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      final result = await Navigator.of(context, rootNavigator: true).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => HelpRequestDetailScreen(
            category: _kHelpCategories[idx].title,
            initialNote: '',
            onViewYourRequests: _onViewYourRequestsAfterSubmit,
          ),
        ),
      );
      if (!mounted) return;
      if (result == true) {
        _focusMyRequestsTab();
        _openYourRequestsPageAfterSubmit();
      }
    });
  }

  Future<void> _openRequestDetail(int index) async {
    setState(() => _selectedCategoryIndex = index);
    final result = await Navigator.of(context, rootNavigator: true).push<bool>(
      MaterialPageRoute<bool>(
        builder: (_) => HelpRequestDetailScreen(
          category: _kHelpCategories[index].title,
          initialNote: '',
          onViewYourRequests: _onViewYourRequestsAfterSubmit,
        ),
      ),
    );
    if (!mounted) return;
    if (result == true) {
      _focusMyRequestsTab();
      _openYourRequestsPageAfterSubmit();
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

        final g = GuardianTheme.of(context);
        return Scaffold(
          backgroundColor: g.scaffoldBg,
          extendBodyBehindAppBar: true,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            foregroundColor: Colors.white,
            title: const Text(
              'Request help',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            centerTitle: true,
            automaticallyImplyLeading: false,
            actions: [
              IconButton(
<<<<<<< Updated upstream
                tooltip: 'Switch to Helper mode',
                icon: const Icon(Icons.swap_horiz_rounded),
                onPressed: () {
                  HelpRoleModeService.instance.toggle();
=======
                tooltip: 'Switch to Helper Mode',
                icon: const Icon(Icons.published_with_changes_rounded),
                onPressed: () {
                  HelpRoleModeService.instance.setHelperMode(true);
>>>>>>> Stashed changes
                },
              ),
              IconButton(
                tooltip: 'More',
                icon: const Icon(Icons.more_vert_rounded),
                onPressed: () {
                  MainMenuScreen.showOverlay(context);
                },
              ),
            ],
          ),
          body: Column(
            children: [
              Container(
                width: double.infinity,
                height: 248,
                decoration: BoxDecoration(
                  gradient: g.headerGradient,
                  borderRadius: const BorderRadius.only(
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
                    const Positioned(
                      left: 18,
                      right: 18,
                      bottom: 62,
                      child: _HelpHeroCard(),
                    ),
                    Positioned(
                      left: 18,
                      right: 18,
                      bottom: 16,
                      child: _HeaderTabSwitch(controller: _requesterTabController),
                    ),
                  ],
                ),
              ),
              Expanded(
                // Small gap above nav; lists use [mainFloatingNavScrollPadding] for tail inset.
                child: Padding(
                  padding: EdgeInsets.only(
                    bottom: mainFloatingNavPanelBottomInset(context),
                  ),
                  child: Transform.translate(
                    offset: const Offset(0, -10),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(18, 0, 18, 0),
                      child: Container(
                        decoration: BoxDecoration(
                          color: g.panelBg,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: g.cardShadow,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: TabBarView(
                          controller: _requesterTabController,
                          children: [
                            _RequestTabContent(
                              categories: _kHelpCategories,
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
    final g = GuardianTheme.of(context);
    return ColoredBox(
      color: g.panelListBg,
      child: CustomScrollView(
        slivers: [
          SliverPadding(
            // Extra top gap so the first card (Resource Sharing) sits lower under the tabs.
            padding: const EdgeInsets.fromLTRB(14, 32, 14, 8),
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
            child: SizedBox(height: mainFloatingNavScrollPadding(context)),
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
    final g = GuardianTheme.of(context);
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? g.panelBg : g.listItemBg,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: isSelected ? GuardianUi.redPrimary : g.divider,
              width: isSelected ? 1.4 : 1,
            ),
            boxShadow: g.cardShadow,
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: isSelected
                      ? GuardianUi.redTint
                      : g.chipUnselectedFill,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? GuardianUi.redPrimary.withValues(alpha: 0.24)
                        : g.chipBorder,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    asset,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.handshake_rounded,
                      color: GuardianUi.redPrimary,
                      size: 24,
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
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: isSelected
                            ? g.textPrimary
                            : g.textPrimary,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: TextStyle(
                          fontSize: 13,
                          color: g.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                isSelected
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                color: isSelected
                    ? GuardianUi.redPrimary
                    : g.captionGrey,
                size: isSelected ? 22 : 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpHeroCard extends StatelessWidget {
  const _HelpHeroCard();

  @override
  Widget build(BuildContext context) {
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
              color: Colors.white.withValues(alpha: 0.14),
              border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
            ),
            child: const Icon(
              Icons.volunteer_activism_rounded,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Request categories',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Choose the best fit and post your request quickly.',
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
}

class _HeaderTabSwitch extends StatelessWidget {
  const _HeaderTabSwitch({required this.controller});

  final TabController controller;

  @override
  Widget build(BuildContext context) {
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
        controller: controller,
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
        labelColor: GuardianUi.redPrimary,
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
          Tab(text: 'New request'),
          Tab(text: 'Your requests'),
        ],
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
