import 'package:flutter/foundation.dart';
import 'help_request.dart';

class HelpRequestsStore {
  HelpRequestsStore._();

  static final HelpRequestsStore instance = HelpRequestsStore._();

  /// Filled from Firestore via [HelpRequestService]; starts empty (no demo data).
  final ValueNotifier<List<HelpRequest>> requests =
      ValueNotifier<List<HelpRequest>>(<HelpRequest>[]);

  void add(HelpRequest request) {
    requests.value = [request, ...requests.value];
  }

  /// Replace or insert by id (after local edit / offline).
  void upsert(HelpRequest request) {
    final list = List<HelpRequest>.from(requests.value);
    final i = list.indexWhere((r) => r.id == request.id);
    if (i >= 0) {
      list[i] = request;
    } else {
      list.insert(0, request);
    }
    requests.value = list;
  }

  void removeById(String id) {
    requests.value = requests.value.where((r) => r.id != id).toList();
  }

  /// Replace list with Firestore data (used by HelpRequestService).
  void setFromFirestore(List<HelpRequest> list) {
    requests.value = list;
  }
}

