import 'package:flutter/material.dart';

class CreateListing extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add New Item"), 
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              height: 180, width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(15)),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, 
              children: [Icon(Icons.camera_alt, size: 40, color: Colors.grey), Text("Add Photos", style: TextStyle(color: Colors.grey))]),
            ),
            SizedBox(height: 20),
            TextField(decoration: InputDecoration(labelText: "What are you selling?", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
            SizedBox(height: 15),
            TextField(keyboardType: TextInputType.number, decoration: InputDecoration(labelText: "Price (\$)", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
            SizedBox(height: 15),
            TextField(maxLines: 4, decoration: InputDecoration(labelText: "Description", border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)))),
            SizedBox(height: 30),
            
            SizedBox(
              width: double.infinity, 
              height: 50, 
              child: ElevatedButton(
                onPressed: () {
                  // Post Listing එක එබුවම හෝම් පේජ් එකට ආපහු යනවා
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Listing Posted Successfully!")));
                  Navigator.pop(context); 
                }, 
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFFF85D5B)), 
                child: Text("Post Listing", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
              ),
            ),
          ],
        ),
      ),
    );
  }
}