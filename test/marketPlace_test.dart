// Student ID: IT23668386
// Evidence for Testing Tool Usage - SafePulse Marketplace

import 'package:flutter_test/flutter_test.dart';

// Function to validate chat message (should not be empty)
bool isValidMessage(String message) {
  return message.trim().isNotEmpty;
}

// Function to check if a review can be submitted
// Rating must be greater than 0 and review text must not be empty
bool canSubmitReview(int rating, String reviewText) {
  return rating > 0 && reviewText.trim().isNotEmpty;
}

void main() {
  group('Marketplace Logic Unit Tests', () {

    // Test 1: Check if a valid message returns true
    test('Should return true for valid message', () {
      final result = isValidMessage("Hello seller");
      expect(result, true);
    });

    // Test 2: Check if an empty message returns false
    test('Should return false for empty message', () {
      final result = isValidMessage("   ");
      expect(result, false);
    });

    // Test 3: Check if a valid rating and review text is accepted
    test('Should allow review with rating and text', () {
      final result = canSubmitReview(4, "Good seller");
      expect(result, true);
    });

    // Test 4: Check if zero rating is rejected
    test('Should not allow review with zero rating', () {
      final result = canSubmitReview(0, "Bad");
      expect(result, false);
    });

    // Test 5: Check if empty review text is rejected
    test('Should not allow review with empty text', () {
      final result = canSubmitReview(5, "");
      expect(result, false);
    });

  });
}