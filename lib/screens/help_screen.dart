import 'package:flutter/material.dart';
import 'help_feed_screen.dart';
import 'help_request_detail_screen.dart';

class HelpScreen extends StatefulWidget {
  final String? initialCategory;

  const HelpScreen({super.key, this.initialCategory});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final TextEditingController _helpController = TextEditingController();
  int _selectedIndex = 0;

  final List<_HelpCategory> _categories = const [
    _HelpCategory(
      icon: Icons.menu_book_rounded,
      title: 'Resource Sharing',
    ),
    _HelpCategory(
      icon: Icons.school_rounded,
      title: 'Study Support',
    ),
    _HelpCategory(
      icon: Icons.directions_car_rounded,
      title: 'Safety Transport',
    ),
    _HelpCategory(
      icon: Icons.settings_input_component_rounded,
      title: 'Tech Support',
    ),
    _HelpCategory(
      icon: Icons.restaurant_rounded,
      title: 'Canteen Runner',
    ),
    _HelpCategory(
      icon: Icons.local_shipping_rounded,
      title: 'Campus Logistics & Moving',
      subtitle: 'Rs 4,500',
    ),
    _HelpCategory(
      icon: Icons.currency_exchange_rounded,
      title: 'Cash Exchange',
      subtitle: 'Rs 4,500',
    ),
    _HelpCategory(
      icon: Icons.more_horiz_rounded,
      title: 'Other',
    ),
  ];

  @override
  void initState() {
    super.initState();
    if (widget.initialCategory != null) {
      final idx = _categories.indexWhere(
        (c) => c.title.toLowerCase() == widget.initialCategory!.toLowerCase(),
      );
      if (idx != -1) {
        _selectedIndex = idx;
      }
    }
  }

  @override
  void dispose() {
    _helpController.dispose();
    super.dispose();
  }

  void _onPostRequest() {
    final selectedCategory = _categories[_selectedIndex].title;
    final description = _helpController.text.trim();

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => HelpRequestDetailScreen(
          category: selectedCategory,
          initialNote: description,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF9F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Post Help Request',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.forum_outlined, color: Colors.black87),
            tooltip: 'View Help Feed',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const HelpFeedScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final bool isSelected = index == _selectedIndex;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedIndex = index;
                    });
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected 
                              ? Colors.red.withOpacity(0.15) 
                              : Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: isSelected ? Colors.redAccent : const Color(0xFFF0F0F0),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      leading: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFEBEE),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          category.icon,
                          color: const Color(0xFFEF5350),
                          size: 24,
                        ),
                      ),
                      title: Text(
                        category.title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                          color: isSelected ? Colors.redAccent : const Color(0xFF333333),
                        ),
                      ),
                      subtitle: category.subtitle != null
                          ? Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.payments_outlined, size: 14, color: Colors.grey),
                                  const SizedBox(width: 4),
                                  Text(
                                    category.subtitle!,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          : null,
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: isSelected ? Colors.redAccent : const Color(0xFFCCCCCC),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _helpController,
                    minLines: 1,
                    maxLines: 2,
                    style: const TextStyle(fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'Need help carrying medical bag.',
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      border: InputBorder.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFD32F2F),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: Colors.redAccent.withOpacity(0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _onPostRequest,
                    child: const Text(
                      'POST REQUEST',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
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

class _HelpCategory {
  final IconData icon;
  final String title;
  final String? subtitle;

  const _HelpCategory({
    required this.icon,
    required this.title,
    this.subtitle,
  });
}

