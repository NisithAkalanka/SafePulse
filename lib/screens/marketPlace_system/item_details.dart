import 'package:flutter/material.dart';
import 'negotiation_chat.dart';

class ItemDetails extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Item Details"), iconTheme: IconThemeData(color: Colors.black)),
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: Colors.grey[100], 
              width: double.infinity, 
              child: Center(child: Icon(Icons.image, size: 100, color: Colors.grey))
            )
          ),
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("\$50.00", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: Color(0xFFF85D5B))),
                Text("Scientific Calculator TI-84", style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600)),
                SizedBox(height: 10),
                Text("Item is in good condition, used for only 2 semesters at university.", style: TextStyle(color: Colors.grey[600])),
                SizedBox(height: 30),
                Row(
                  children: [
                    Expanded(child: ElevatedButton(onPressed: () {}, child: Text("Buy Now"))),
                    SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => NegotiationChat()));
                        }, 
                        child: Text("Negotiate/Chat")
                      )
                    ),
                  ],
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}