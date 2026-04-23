// Student ID: IT23721128
// Evidence for Testing Tool Usage - SafePulse Help Module

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Helper Badge Logic Tests', () {
    test('Should return no badge when review count is below 3', () {
      final result = helperBadgeLabel(4.9, 2);
      expect(result, '');
    });

    test('Should return Bronze when average is 3.5 or above and count is at least 3', () {
      final result = helperBadgeLabel(3.7, 3);
      expect(result, 'Bronze');
    });

    test('Should return Silver when average is 4.0 or above and count is at least 8', () {
      final result = helperBadgeLabel(4.2, 8);
      expect(result, 'Silver');
    });

    test('Should return Gold when average is 4.5 or above and count is at least 15', () {
      final result = helperBadgeLabel(4.8, 15);
      expect(result, 'Gold');
    });

    test('Should stay Bronze if average is good but count is not enough for Silver', () {
      final result = helperBadgeLabel(4.3, 5);
      expect(result, 'Bronze');
    });

    test('Should stay Silver if average is high but count is not enough for Gold', () {
      final result = helperBadgeLabel(4.7, 10);
      expect(result, 'Silver');
    });
  });

  group('Helper Badge Color Tests', () {
    test('Should return correct color for Bronze badge', () {
      final result = helperBadgeColor('Bronze');
      expect(result, 0xFFCD7F32);
    });

    test('Should return correct color for Silver badge', () {
      final result = helperBadgeColor('Silver');
      expect(result, 0xFFC0C0C0);
    });

    test('Should return correct color for Gold badge', () {
      final result = helperBadgeColor('Gold');
      expect(result, 0xFFFFD700);
    });

    test('Should return default color for no badge', () {
      final result = helperBadgeColor('');
      expect(result, 0xFF9E9E9E);
    });
  });

  group('Helper Badge Normalization Tests', () {
    test('Should normalize gold badge text correctly', () {
      final result = normalizeBadge('gold');
      expect(result, 'Gold');
    });

    test('Should normalize silver badge text correctly', () {
      final result = normalizeBadge('SILVER');
      expect(result, 'Silver');
    });

    test('Should normalize bronze badge text correctly', () {
      final result = normalizeBadge('bronze');
      expect(result, 'Bronze');
    });

    test('Should fallback to Bronze for unknown text', () {
      final result = normalizeBadge('unknown');
      expect(result, 'Bronze');
    });
  });

  group('Requester Name Validation Tests', () {
    test('Should reject empty requester name', () {
      final result = validateRequesterName('');
      expect(result, 'Please enter your name');
    });

    test('Should reject very short requester name', () {
      final result = validateRequesterName('A');
      expect(result, 'Name must be at least 2 characters');
    });

    test('Should reject requester name with numbers', () {
      final result = validateRequesterName('Nisith123');
      expect(result, 'Name can only contain letters');
    });

    test('Should accept valid requester name', () {
      final result = validateRequesterName('Nisith Akalanka');
      expect(result, null);
    });
  });

  group('Tip Validation Tests', () {
    test('Should allow empty tip', () {
      final result = validateTip('');
      expect(result, null);
    });

    test('Should reject tip without amount', () {
      final result = validateTip('Will pay later');
      expect(result, 'Include an amount (e.g. LKR 100)');
    });

    test('Should reject negative or zero amount', () {
      final result = validateTip('LKR 0');
      expect(result, 'Enter a valid positive amount');
    });

    test('Should accept valid tip text', () {
      final result = validateTip('LKR 200');
      expect(result, null);
    });
  });

  group('Physical Requirement Validation Tests', () {
    test('Should allow empty physical requirement', () {
      final result = validatePhysical('');
      expect(result, null);
    });

    test('Should reject too short physical requirement', () {
      final result = validatePhysical('1234');
      expect(result, 'Add a bit more detail (at least 5 characters)');
    });

    test('Should accept valid physical requirement', () {
      final result = validatePhysical('Need help carrying books');
      expect(result, null);
    });
  });

  group('Chat Mode Logic Tests', () {
    test('Should return study mode when title contains study', () {
      final result = resolveChatMode('Study Support Session');
      expect(result, 'study');
    });

    test('Should return general mode for non-study title', () {
      final result = resolveChatMode('Transport Help');
      expect(result, 'general');
    });
  });

  group('Help Feed Filtering Tests', () {
    test('Should hide my own requests from helper feed', () {
      final requests = [
        FakeHelpRequest(isMine: true, helperUid: null),
        FakeHelpRequest(isMine: false, helperUid: null),
      ];

      final result = visibleRequestsForHelper(requests, 'helper_1');
      expect(result.length, 1);
    });

    test('Should allow requests with no helper assigned', () {
      final requests = [
        FakeHelpRequest(isMine: false, helperUid: null),
      ];

      final result = visibleRequestsForHelper(requests, 'helper_1');
      expect(result.length, 1);
    });

    test('Should allow requests assigned to current helper', () {
      final requests = [
        FakeHelpRequest(isMine: false, helperUid: 'helper_1'),
      ];

      final result = visibleRequestsForHelper(requests, 'helper_1');
      expect(result.length, 1);
    });

    test('Should hide requests assigned to another helper', () {
      final requests = [
        FakeHelpRequest(isMine: false, helperUid: 'helper_2'),
      ];

      final result = visibleRequestsForHelper(requests, 'helper_1');
      expect(result.isEmpty, true);
    });
  });
}

String helperBadgeLabel(double averageRating, int totalReviews) {
  if (averageRating >= 4.5 && totalReviews >= 15) {
    return 'Gold';
  } else if (averageRating >= 4.0 && totalReviews >= 8) {
    return 'Silver';
  } else if (averageRating >= 3.5 && totalReviews >= 3) {
    return 'Bronze';
  }
  return '';
}

int helperBadgeColor(String badge) {
  switch (badge) {
    case 'Gold':
      return 0xFFFFD700;
    case 'Silver':
      return 0xFFC0C0C0;
    case 'Bronze':
      return 0xFFCD7F32;
    default:
      return 0xFF9E9E9E;
  }
}

String normalizeBadge(String badge) {
  switch (badge.toLowerCase()) {
    case 'gold':
      return 'Gold';
    case 'silver':
      return 'Silver';
    case 'bronze':
      return 'Bronze';
    default:
      return 'Bronze';
  }
}

String? validateRequesterName(String? v) {
  final t = v?.trim() ?? '';
  if (t.isEmpty) {
    return 'Please enter your name';
  }
  if (t.length < 2) {
    return 'Name must be at least 2 characters';
  }
  if (t.length > 80) {
    return 'Name is too long';
  }
  final lettersOnly = RegExp(r'^[A-Za-z ]+$');
  if (!lettersOnly.hasMatch(t)) {
    return 'Name can only contain letters';
  }
  return null;
}

String? validateTip(String? v) {
  final t = v?.trim() ?? '';
  if (t.isEmpty) return null;
  if (t.length > 80) return 'Keep tip text under 80 characters';

  final digits = RegExp(r'\d+').firstMatch(t.replaceAll(',', ''));
  if (digits == null) return 'Include an amount (e.g. LKR 100)';

  final n = int.tryParse(digits.group(0)!);
  if (n == null || n <= 0) return 'Enter a valid positive amount';

  return null;
}

String? validatePhysical(String? v) {
  final t = v?.trim() ?? '';
  if (t.isEmpty) return null;
  if (t.length < 5) return 'Add a bit more detail (at least 5 characters)';
  if (t.length > 500) return 'Maximum 500 characters';
  return null;
}

String resolveChatMode(String title) {
  return title.toLowerCase().contains('study') ? 'study' : 'general';
}

List<FakeHelpRequest> visibleRequestsForHelper(
  List<FakeHelpRequest> requests,
  String currentUid,
) {
  return requests.where((r) {
    return !r.isMine && (r.helperUid == null || r.helperUid == currentUid);
  }).toList();
}

class FakeHelpRequest {
  final bool isMine;
  final String? helperUid;

  FakeHelpRequest({
    required this.isMine,
    required this.helperUid,
  });
}