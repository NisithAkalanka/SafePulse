import 'package:flutter/material.dart';

class MarketNotificationsScreen extends StatefulWidget {
  const MarketNotificationsScreen({super.key});

  @override
  State<MarketNotificationsScreen> createState() => _MarketNotificationsScreenState();
}

class _MarketNotificationsScreenState extends State<MarketNotificationsScreen> {
  // SafePulse Brand Colors
  static const Color primaryRed = Color(0xFFD32F2F);
  static const Color darkBg = Color(0xFF121212);

  // නිදර්ශන Notifications කිහිපයක් (Mock Data)
  final List<Map<String, dynamic>> _notifications = [
    {
      "title": "New Offer Received!",
      "desc": "Kamal offered Rs. 15,000 for your iPhone 14 Case.",
      "time": "2 mins ago",
      "icon": Icons.local_offer_rounded,
      "isRead": false,
      "category": "Selling"
    },
    {
      "title": "Price Dropped!",
      "desc": "An item in your saved list 'Scientific Calculator' is now cheaper.",
      "time": "1 hour ago",
      "icon": Icons.trending_down_rounded,
      "isRead": false,
      "category": "Buying"
    },
    {
      "title": "Safety Reminder",
      "desc": "Remember to meet near the Campus Library for safe transactions.",
      "time": "3 hours ago",
      "icon": Icons.gpp_good_rounded,
      "isRead": true,
      "category": "All"
    },
    {
      "title": "New Message",
      "desc": "Nuwan sent you a message: 'Is it still available?'",
      "time": "Yesterday",
      "icon": Icons.chat_bubble_rounded,
      "isRead": true,
      "category": "Buying"
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(colors: [primaryRed, darkBg]),
          ),
        ),
        title: const Text("Notifications", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.done_all_rounded))
        ],
      ),
      body: Column(
        children: [
          // --- 1. FILTERING TABS (All, Buying, Selling) ---
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 15),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildCategoryTab("All", true),
                _buildCategoryTab("Buying", false),
                _buildCategoryTab("Selling", false),
              ],
            ),
          ),
          
          const Divider(height: 1, thickness: 0.5),

          // --- 2. NOTIFICATIONS LIST ---
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: _notifications.length,
              itemBuilder: (context, index) {
                final item = _notifications[index];
                return _buildNotificationTile(item);
              },
            ),
          ),
        ],
      ),
    );
  }

  // Category තේරීම සඳහා වන බටන්
  Widget _buildCategoryTab(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? primaryRed : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
        boxShadow: isSelected ? [BoxShadow(color: primaryRed.withOpacity(0.3), blurRadius: 8)] : [],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : Colors.black54,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }

  // එක් notification එකක පෙනුම
  Widget _buildNotificationTile(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: item['isRead'] ? Colors.white : primaryRed.withOpacity(0.03),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: item['isRead'] ? Colors.grey.shade100 : primaryRed.withOpacity(0.1)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: item['isRead'] ? Colors.grey.shade100 : primaryRed.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(item['icon'], color: item['isRead'] ? Colors.grey : primaryRed, size: 24),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(item['title'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            if (!item['isRead']) 
              const CircleAvatar(radius: 4, backgroundColor: primaryRed),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 5),
            Text(item['desc'], style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
            const SizedBox(height: 8),
            Text(item['time'], style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ],
        ),
        onTap: () {
          // මෙතැනදී අදාළ Chat හෝ Item වෙත Navigate කළ හැක
        },
      ),
    );
  }
}