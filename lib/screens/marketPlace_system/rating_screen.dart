import 'package:flutter/material.dart';

class RatingScreen extends StatefulWidget {
  final String itemName;
  final String itemImage;

  const RatingScreen({super.key, required this.itemName, required this.itemImage});

  @override
  State<RatingScreen> createState() => _RatingScreenState();
}

class _RatingScreenState extends State<RatingScreen> {
  int _rating = 0; // පාරිභෝගිකයා ලබාදෙන තරු ගණන
  final TextEditingController _commentController = TextEditingController();

  static const Color safePulseRed = Color(0xFFD32F2F);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text("Rate Your Experience"), centerTitle: true, elevation: 0),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            const Icon(Icons.verified_rounded, color: Colors.green, size: 80),
            const SizedBox(height: 10),
            const Text("Transaction Completed!", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 5),
            Text("You purchased ${widget.itemName}", style: const TextStyle(color: Colors.grey)),
            
            const SizedBox(height: 40),
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(widget.itemImage, height: 120, width: 120, fit: BoxFit.cover),
            ),
            
            const SizedBox(height: 30),
            const Text("How was the seller's behavior?", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 15),

            // --- Star Rating UI ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () => setState(() => _rating = index + 1),
                  icon: Icon(
                    index < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                    color: index < _rating ? Colors.amber : Colors.grey.shade400,
                    size: 45,
                  ),
                );
              }),
            ),
            
            const SizedBox(height: 30),
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Write a small review (Optional)",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
              ),
            ),
            
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: safePulseRed,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                ),
                onPressed: () {
                  // Reputation Update logic එක මෙතනින් සිදු වේ (Success SnackBar)
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Rating & Reputation Updated!")));
                  Navigator.pop(context); // Chat එකට හෝ Home එකට ආපසු යෑම
                },
                child: const Text("Submit Review", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}