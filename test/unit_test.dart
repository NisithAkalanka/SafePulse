//Student ID: IT23601888
// Evidence for Testing Tool Usage - SafePulse Project

import 'package:flutter_test/flutter_test.dart';

// අපි චැට් එකේ නම කෙටි කරන්න පාවිච්චි කරපු function එකම මෙතන ටෙස්ට් කරමු
String getShortName(String fullName) {
  if (fullName.trim().isEmpty) return 'User';
  return fullName.trim().split(' ').first;
}

void main() {
  group('SafePulse Logic Unit Tests', () {
    // 1 වෙනි ටෙස්ට් එක: සම්පූර්ණ නම දුන්නම මුල් නම විතරක් එනවද?
    test('Should return only the first name from a full name', () {
      final result = getShortName("Nisith Akalanka");
      expect(result, "Nisith");
    });

    // 2 වෙනි ටෙස්ට් එක: නම හිස්ව දුන්නම 'User' කියලා එනවද?
    test('Should return "User" if the input name is empty', () {
      final result = getShortName("");
      expect(result, "User");
    });

    // 3 වෙනි ටෙස්ට් එක: හිස්තැන් (Spaces) සහිතව නම දුන්නම ඒක හරියට හදනවද?
    test('Should handle names with leading or trailing spaces', () {
      final result = getShortName("  Amal Perera  ");
      expect(result, "Amal");
    });
  });
}
