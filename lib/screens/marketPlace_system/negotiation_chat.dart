import 'package:flutter/material.dart';

class NegotiationChat extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Seller: Kasun"), iconTheme: IconThemeData(color: Colors.black)),
      body: Column(
        children: [
          Container(
            color: Color(0xFFF85D5B).withOpacity(0.1),
            padding: EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Status: Agreement & Meetup", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
                ElevatedButton(
                  onPressed: () {
                     ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Item marked as SOLD")));
                  }, 
                  child: Text("Mark as Sold"), 
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.black, visualDensity: VisualDensity.compact)
                ),
              ],
            ),
          ),
          Expanded(child: Center(child: Text("Start negotiating the price with the seller.", style: TextStyle(color: Colors.grey)))),
          Container(
            padding: EdgeInsets.all(10), 
            child: Row(
              children: [
                Expanded(child: TextField(decoration: InputDecoration(hintText: "Ask about price...", filled: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none)))),
                SizedBox(width: 5),
                IconButton(onPressed: () {}, icon: Icon(Icons.send, color: Color(0xFFF85D5B))),
              ]
            )
          ),
        ],
      ),
    );
  }
}