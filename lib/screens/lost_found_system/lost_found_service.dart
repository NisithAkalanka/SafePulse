import 'dart:async';
import 'dart:io';
import 'lost_item_model.dart';

class LostFoundService {
  // --- MEMORY DATABASE ---
  static final List<LostItem> _memoryDb = [
    // ITEM 1: Posted by SOMEONE ELSE. (You can claim this)
    LostItem(
      id: 'item_1',
      userId: 'user_other',
      userName: 'John',
      type: 'Lost',
      title: 'Black Umbrella',
      category: 'Others',
      description: 'Left it near the main gate when raining.',
      location: 'Main Gate',
      imageUrl: '', // Empty string = Use default icon (No Red Line)
      status: 'Active',
      timestamp: DateTime.now().subtract(const Duration(hours: 5)),
    ),

    // ITEM 2: Posted by YOU. (Someone claimed this - Test Verification)
    LostItem(
      id: 'item_2',
      userId: 'my_id',
      userName: 'Me',
      type: 'Found',
      title: 'Silver Watch',
      category: 'Electronics',
      description: 'Found this watch on a bench.',
      location: 'Garden Area',
      imageUrl: '',
      status: 'Claim Pending', // This lets you test the "Owner View"
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
      claimerId: 'user_claimant',
    ),
  ];

  // Storage for "Verification Answers" (Simulating the database)
  static final Map<String, String> _verificationAnswers = {
    'item_2': 'The strap has a small tear.', // This is the "answer" for Item 2
  };

  static final StreamController<List<LostItem>> _controller =
      StreamController<List<LostItem>>.broadcast();

  // --- FUNCTIONS ---

  Stream<List<LostItem>> getItemsStream(String type) {
    Future(() => _controller.add(_memoryDb));
    return _controller.stream.map(
      (list) => list.where((i) => i.type == type).toList(),
    );
  }

  Future<void> createPost(LostItem item, File? imageFile) async {
    await Future.delayed(const Duration(milliseconds: 500));
    item.id = DateTime.now().millisecondsSinceEpoch.toString();
    // Use local placeholder if valid URL isn't possible
    item.imageUrl = '';
    _memoryDb.insert(0, item);
    _controller.add(_memoryDb);
  }

  // LOGIC: Claimer sends "Proof" (Process Map Step 2)
  Future<void> submitClaimRequest(String itemId, String proofAnswer) async {
    final index = _memoryDb.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      _memoryDb[index].status = 'Claim Pending';
      _verificationAnswers[itemId] = proofAnswer; // Save the answer
      _controller.add(_memoryDb);
    }
  }

  // LOGIC: Owner retrieves the "Proof" to check it
  String getVerificationAnswer(String itemId) {
    return _verificationAnswers[itemId] ?? "No details provided.";
  }

  // LOGIC: Mark as Returned (Process Map Step Final)
  Future<void> markAsReturned(String itemId) async {
    final index = _memoryDb.indexWhere((i) => i.id == itemId);
    if (index != -1) {
      _memoryDb[index].status = 'Returned';
      _controller.add(_memoryDb);
    }
  }
}
