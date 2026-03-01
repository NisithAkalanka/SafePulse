import 'package:flutter/material.dart';

// REUSABLE ITEM CARD
Widget buildMarketItemCard(BuildContext context, String title, String price, String category) {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Center(child: Icon(Icons.shopping_bag_outlined, color: Color(0xFFF85D5B), size: 40)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(category.toUpperCase(), style: TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold)),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
              SizedBox(height: 4),
              Text("\$$price", style: TextStyle(color: Color(0xFFF85D5B), fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    ),
  );
}